# Franklyn Sentinel -- Screen Capture Rewrite Specification

| Field       | Value                              |
|-------------|------------------------------------|
| Status      | Draft v2                           |
| Authors     | Jakob Huemer-Fistelberger          |
| Created     | 2026-03-16                         |
| Updated     | 2026-03-17                         |
| Component   | `sentinel/src/recorder/mod.rs`     |
| License     | MIT (see `/LICENSE`)               |

## 1. Motivation

The current sentinel screen capture implementation uses `xcap 0.9.1`, which has
several architectural problems:

1. **Busy-waiting on X11.** The xcap `VideoRecorder` spawns a thread that calls
   `monitor.capture_image()` (XCB `GetImage`) in a tight loop with only a 1ms
   sleep between captures. There is no framerate concept -- it captures as fast
   as XCB can serve requests.

2. **Blocking a tokio runtime thread.** The `std::sync::mpsc::Receiver::recv()`
   call from xcap is blocking, but the current code calls it inside
   `tokio::spawn`, which blocks one of the tokio worker threads.

3. **No framerate control.** Framerate is emulated by a 500ms timer in `ws.rs`
   that sends `GetFrame` commands. The capture thread runs at maximum speed
   regardless, wasting CPU.

4. **Global mutable state.** A `OnceLock<RwLock<xcap::Frame>>` is used to pass
   the latest frame between threads. This is fragile and prevents multiple
   capture sessions.

5. **Monolithic function.** `start_screen_recording` is a 183-line function
   that mixes platform detection, capture setup, frame processing (RGBA->RGB
   stripping, resizing, JPEG encoding, base64 encoding), and control message
   handling.

6. **No Wayland support via portal.** xcap handles Wayland internally via
   PipeWire/portal, but exposes no control over the portal dialog, session
   persistence, or framerate negotiation.

7. **JPEG+base64 encoding per frame.** The current design sends individual
   JPEG-encoded frames. The project's media spec requires H.264 in fMP4
   fragments for MSE-based browser playback.

The rewrite replaces xcap with a unified GStreamer pipeline that handles screen
capture, H.264 encoding, and fMP4 muxing. ashpd (XDG Desktop Portal wrapper)
is used on Wayland for the screen picker dialog. The sentinel outputs
ready-to-send fMP4 fragment bytes -- no separate encoding step needed.

## 2. Goals

- Replace `xcap` with a single GStreamer pipeline: capture -> encode -> mux.
- Output fMP4 data: one initialization segment + continuous media fragments.
- Use H.264 Main profile via `x264enc` (configurable fallback to Constrained
  Baseline).
- Deliver fMP4 bytes via `tokio::sync::mpsc::Receiver` -- ready to send over
  the wire with no further processing.
- Support configurable FPS (default: 5, range: 0.2 to 5) and runtime changes.
- Support on-demand IDR keyframes (for Proctor joins) and forced keyframes on
  FPS changes, matching the media spec.
- Enforce max 20-30s keyframe interval.
- Downscale to max 1080p inside the GStreamer pipeline (not in Rust).
- Detect X11 vs Wayland at runtime and use the appropriate capture backend.
- On Wayland, handle the XDG Desktop Portal dialog transparently via ashpd.
- Remove the request/response ping-pong pattern between `ws.rs` and capture.
- Remove global mutable state (`GLOBAL_FRAME`).
- Remove JPEG+base64 encoding entirely.
- Delete `image_generator.rs` (fake frame generator). No dev/macOS fallback --
  GStreamer is required to run the sentinel.

## 3. Non-Goals

- Backend-agnostic trait abstraction (we commit to GStreamer).
- Recording to disk in the sentinel (the server handles storage).
- Audio capture.
- Multi-monitor selection UI (captures primary/portal-selected monitor).
- Protobuf framing (handled by the transport layer, not the capture module).

## 4. Architecture Overview

```
                    +------------------+
                    |    lib.rs        |
                    |  (orchestrator)  |
                    +--------+---------+
                             |
              +--------------+--------------+
              |                             |
   +----------v----------+      +-----------v-----------+
    | recorder/mod.rs     |      |     ws.rs             |
    | (Recorder)          |      | (WebSocket client)    |
   |                     |      |                       |
   | GStreamer pipeline:  |      | Receives:             |
   |  capture             |      |  - InitSegment (once) |
   |  -> videoscale       |      |  - Fragment (stream)  |
   |  -> x264enc         | ---> | Wraps in protobuf     |
   |  -> isofmp4mux      |  rx  | Sends over WebSocket  |
   |  -> appsink         |      |                       |
   |                     |      | Handles server msgs:  |
   | Outputs:            |      |  - keyframe.request   |
   |  InitSegment        |      |  - fps.change         |
   |  Fragment            |      |                       |
   +----------------------+      +-----------------------+
```

If GStreamer is not available or the pipeline fails to start, the sentinel
exits with an error. There is no fake frame fallback.

## 5. Detailed Design

### 5.1 New Dependencies

Add to `sentinel/Cargo.toml`:

```toml
gstreamer = "0.25"
gstreamer-app = "0.25"
gstreamer-video = "0.25"
ashpd = { version = "0.13", default-features = false, features = ["screencast", "tokio"] }
thiserror = "2"
```

Remove from `sentinel/Cargo.toml`:

```toml
xcap = "0.8.2"
```

Remove (no longer needed -- GStreamer handles encoding and scaling, and
`image_generator.rs` is being deleted):

```toml
image = "0.25.9"
base64 = "0.22.1"
```

### 5.2 Public Types (`recorder/mod.rs`)

```rust
/// fMP4 initialization segment (ftyp + moov).
/// Sent once per session. Contains codec config (SPS/PPS), resolution,
/// timescale. No video frames.
pub struct InitSegment {
    pub data: Vec<u8>,
}

/// A single fMP4 media fragment (moof + mdat).
/// Contains one or more H.264 encoded samples.
pub struct Fragment {
    /// The raw fMP4 bytes, ready to send over the wire.
    pub data: Vec<u8>,
    /// Monotonically increasing sequence number (0-based, per session).
    pub sequence: u64,
    /// Whether the first sample in this fragment is an IDR keyframe.
    /// If true, this is a "join fragment" -- a valid entry point for new
    /// viewers when combined with the InitSegment.
    pub is_keyframe: bool,
}

/// What the Recorder delivers to the consumer.
pub enum CaptureOutput {
    /// Emitted once at the start. Must be sent/cached before any fragments.
    Init(InitSegment),
    /// Emitted continuously during capture.
    Media(Fragment),
}

/// Configuration for the recorder.
pub struct CaptureConfig {
    /// Target frames per second. Default: 5. Range: 0.2 to 5.
    pub fps: f32,
    /// Maximum dimension (width or height) in pixels.
    /// Source frames exceeding this are downscaled in the GStreamer pipeline.
    /// Default: 1920.
    pub max_dimension: u32,
    /// H.264 profile. Default: "main".
    /// Use "constrained-baseline" for maximum compatibility.
    pub h264_profile: String,
    /// Maximum keyframe interval in seconds. Default: 30.
    /// At least one IDR is forced every this many seconds.
    pub max_keyframe_interval_secs: u32,
}

/// Errors that can occur during capture setup or runtime.
#[derive(Debug, thiserror::Error)]
pub enum CaptureError {
    #[error("GStreamer initialization failed: {0}")]
    GstreamerInit(String),

    #[error("XDG portal dialog was cancelled by the user")]
    PortalCancelled,

    #[error("XDG portal session failed: {0}")]
    PortalFailed(String),

    #[error("GStreamer pipeline creation failed: {0}")]
    PipelineFailed(String),

    #[error("No display server detected (need X11 or Wayland)")]
    NoDisplayServer,
}

/// Handle to a running screen capture session.
/// Dropping this stops the GStreamer pipeline.
///
/// Public API is exposed from the `recorder` module.
pub struct Recorder { /* ... */ }
```

### 5.3 `Recorder` API

```rust
impl Recorder {
    /// Start capturing the screen and encoding to fMP4.
    ///
    /// 1. Initializes GStreamer.
    /// 2. Detects X11 vs Wayland from environment variables.
    /// 3. On Wayland: opens XDG Desktop Portal ScreenCast dialog via ashpd.
    /// 4. Builds a GStreamer pipeline: capture -> scale -> encode -> mux.
    /// 5. Spawns a background task that pulls fMP4 data from appsink.
    ///
    /// The receiver first yields `CaptureOutput::Init` (the initialization
    /// segment), then yields `CaptureOutput::Media` for each fragment.
    ///
    /// When the capturer is dropped or `stop()` is called, the receiver
    /// yields `None`.
    pub async fn start(
        config: CaptureConfig,
    ) -> Result<(Self, tokio::sync::mpsc::Receiver<CaptureOutput>), CaptureError>;

    /// Change the target FPS at runtime.
    ///
    /// This forces a keyframe (IDR) on the next frame, matching the media
    /// spec requirement that FPS changes produce a new join fragment.
    ///
    /// The FPS value is clamped to [0.2, 5.0].
    pub fn set_fps(&self, fps: f32);

    /// Request an on-demand IDR keyframe.
    ///
    /// The next captured frame will be encoded as an IDR frame, producing
    /// a join fragment. Used when the server needs a fresh entry point
    /// (e.g., a Proctor is joining the stream).
    pub fn force_keyframe(&self);

    /// Stop capturing. The receiver will yield `None` after this.
    /// Also called automatically on `Drop`.
    pub fn stop(&self);
}
```

Note: `set_max_dimension()` is removed. Resolution is fixed for the session
because changing resolution mid-stream would require a new initialization
segment (new SPS/PPS). If resolution changes are needed in the future, the
approach is to stop and restart the pipeline (new session).

### 5.4 Internal: Display Server Detection

Detection logic (runtime, not compile-time):

```
if env::var("WAYLAND_DISPLAY").is_ok()
   || env::var("XDG_SESSION_TYPE").as_deref() == Ok("wayland")
{
    Backend::Wayland
} else if env::var("DISPLAY").is_ok() {
    Backend::X11
} else {
    return Err(CaptureError::NoDisplayServer)
}
```

### 5.5 Internal: Wayland Capture Flow

1. Create ashpd `Screencast` proxy:
   ```rust
   let proxy = Screencast::new().await?;
   ```
2. Create session, select sources, start (triggers user-facing dialog):
   ```rust
   let session = proxy.create_session(Default::default()).await?;
   proxy.select_sources(&session,
       SelectSourcesOptions::default()
           .set_cursor_mode(CursorMode::Embedded)
           .set_sources(SourceType::Monitor)
           .set_multiple(false)
           .set_persist_mode(PersistMode::DoNot)
   ).await?;
   let response = proxy.start(&session, None, Default::default())
       .await?.response()?;
   ```
3. Get PipeWire fd and node ID:
   ```rust
   let fd = proxy.open_pipe_wire_remote(&session, Default::default()).await?;
   let node_id = response.streams()[0].pipe_wire_node_id();
   ```
4. These values are passed to the GStreamer pipeline builder (see section 5.8).

### 5.6 Internal: X11 Capture Flow

No portal dialog needed. The `ximagesrc` element is used directly in the
GStreamer pipeline (see section 5.8).

### 5.7 Internal: Downscaling

Downscaling is done inside the GStreamer pipeline using `videoscale` +
caps filter. This is more efficient than doing it in Rust because GStreamer
can optimize the scaling with SIMD and avoid an extra pixel buffer copy.

The caps filter constrains the maximum dimension while preserving aspect ratio.
GStreamer's `videoscale` element handles this when given caps with a max
width/height and `pixel-aspect-ratio=1/1`.

Implementation detail: We set output caps with the target max resolution.
GStreamer negotiates the actual output resolution by downscaling to fit.

### 5.8 GStreamer Pipeline

#### X11

```
ximagesrc use-damage=false
  ! videorate
  ! video/x-raw,framerate={fps_n}/{fps_d}
  ! videoscale
  ! video/x-raw,width=[1,{max_w}],height=[1,{max_h}]
  ! videoconvert
  ! video/x-raw,format=I420
  ! x264enc
      profile={profile}
      key-int-max={max_keyframe_frames}
      tune=zerolatency
      speed-preset=superfast
      option-string="scenecut=0"
  ! video/x-h264,stream-format=avc,alignment=au
  ! isofmp4mux name=mux fragment-duration={fragment_duration_ns}
  ! appsink name=sink emit-signals=true sync=false
```

#### Wayland

```
pipewiresrc fd={fd} path={node_id}
  ! videorate
  ! video/x-raw,framerate={fps_n}/{fps_d}
  ! videoscale
  ! video/x-raw,width=[1,{max_w}],height=[1,{max_h}]
  ! videoconvert
  ! video/x-raw,format=I420
  ! x264enc
      profile={profile}
      key-int-max={max_keyframe_frames}
      tune=zerolatency
      speed-preset=superfast
      option-string="scenecut=0"
  ! video/x-h264,stream-format=avc,alignment=au
  ! isofmp4mux name=mux fragment-duration={fragment_duration_ns}
  ! appsink name=sink emit-signals=true sync=false
```

Note: On Wayland, PipeWire delivers frames at the compositor's chosen rate.
`videorate` normalizes this to the target FPS before encoding, so the encoder
receives a consistent framerate.

#### Pipeline element notes

| Element | Purpose |
|---------|---------|
| `ximagesrc` / `pipewiresrc` | Screen capture source |
| `videorate` | Normalizes framerate to target FPS |
| `videoscale` | Downscales to max dimension if source exceeds it |
| `videoconvert` | Converts to I420 (what x264 expects) |
| `x264enc` | H.264 encoding |
| `isofmp4mux` | Produces fMP4 (init segment + fragments) |
| `appsink` | Exposes fMP4 bytes to the Rust application |

#### x264enc settings explained

| Setting | Value | Rationale |
|---------|-------|-----------|
| `profile` | `main` (default) | ~20-30% better compression than baseline. All modern browsers decode it. Configurable to `constrained-baseline` via `CaptureConfig`. |
| `key-int-max` | `fps * max_keyframe_interval_secs` | e.g., 5 * 30 = 150 frames = 30s max IDR interval |
| `tune=zerolatency` | Disables frame reordering, reduces latency | No lookahead, no B-frame delay |
| `speed-preset=superfast` | Fast encoding at acceptable quality | Good balance for 1080p@5fps on modest hardware |
| `option-string="scenecut=0"` | Disables automatic scene-change keyframes | We control keyframes explicitly via force-keyframe events |

#### isofmp4mux notes

`isofmp4mux` (from `gst-plugins-rs`, available in GStreamer 1.22+) produces:

1. **First buffer**: The initialization segment (`ftyp` + `moov`) with the
   `HEADER` buffer flag set. This is the `InitSegment`.
2. **Subsequent buffers**: Media fragments (`moof` + `mdat`). Each buffer is
   one `Fragment`.

The `fragment-duration` property controls how many frames are grouped per
fragment. For real-time delivery, a short duration is preferred (e.g., 1
second = 1000000000 ns). At 5 FPS, this means ~5 frames per fragment. At
lower FPS, fragments may contain fewer frames.

### 5.9 Internal: Fragment Pulling Loop

After the pipeline is set to `Playing`, spawn a background task:

```rust
tokio::task::spawn_blocking(move || {
    let appsink: AppSink = /* retrieved from pipeline by name */;
    let mut sequence: u64 = 0;

    loop {
        if stop_flag.load(Ordering::Relaxed) { break; }

        // Pull the next buffer (blocking, with timeout)
        let Some(sample) = appsink.try_pull_sample(
            gst::ClockTime::from_mseconds(500)
        ) else {
            continue; // timeout, retry
        };

        let buffer = sample.buffer().unwrap();
        let map = buffer.map_readable().unwrap();
        let bytes = map.as_slice().to_vec();

        let flags = buffer.flags();

        // isofmp4mux sets HEADER flag on the initialization segment
        if flags.contains(gst::BufferFlags::HEADER) {
            let _ = output_tx.send(CaptureOutput::Init(InitSegment {
                data: bytes,
            }));
            continue;
        }

        // Check if this fragment starts with a keyframe.
        // isofmp4mux sets DELTA_UNIT on non-keyframe fragments.
        let is_keyframe = !flags.contains(gst::BufferFlags::DELTA_UNIT);

        let fragment = Fragment {
            data: bytes,
            sequence,
            is_keyframe,
        };

        let _ = output_tx.try_send(CaptureOutput::Media(fragment));
        sequence += 1;
    }
});
```

**Channel details:**

- Type: `tokio::sync::mpsc` with capacity 4 (small buffer for fragments).
- The `InitSegment` is sent with `send()` (blocking/await, must not be dropped).
- Fragments are sent with `try_send()` -- if consumer is behind, the oldest
  unsent fragment is effectively skipped. At 5 FPS with 1s fragments, this
  means the consumer has ~4s of buffer before drops occur.

### 5.10 Runtime Configuration via Shared State

```rust
pub struct Recorder {
    pipeline: gst::Pipeline,
    encoder: gst::Element,        // x264enc element reference
    fps: Arc<AtomicU32>,          // stored as fps * 1000 for f32 precision
    stop_flag: Arc<AtomicBool>,
    backend: Backend,
}

impl Recorder {
    pub fn set_fps(&self, fps: f32) {
        let fps = fps.clamp(0.2, 5.0);
        // Store as milliFPS for atomic u32 (e.g., 5.0 -> 5000)
        self.fps.store((fps * 1000.0) as u32, Ordering::Relaxed);

        // Force keyframe on FPS change (media spec requirement)
        self.force_keyframe();

        // Note: Changing videorate caps at runtime requires pipeline
        // reconfiguration. The pulling loop reads the current fps and
        // adjusts the sleep interval for Wayland, or sends a reconfigure
        // event for X11's videorate element.
    }

    pub fn force_keyframe(&self) {
        // Send a GstForceKeyUnit event upstream to x264enc
        let event = gstreamer_video::UpstreamForceKeyUnitEvent::builder()
            .all_headers(true)
            .build();
        self.encoder.send_event(event);
    }

    pub fn stop(&self) {
        self.stop_flag.store(true, Ordering::Relaxed);
        let _ = self.pipeline.set_state(gst::State::Null);
    }
}

impl Drop for Recorder {
    fn drop(&mut self) {
        self.stop();
    }
}
```

### 5.11 FPS Change Implementation Detail

Changing FPS at runtime is more involved than the old spec because the
GStreamer pipeline has a `videorate` element with negotiated caps.

**Approach:** On FPS change, send a reconfigure event to `videorate` and update
the caps filter downstream. The `videorate` element will adjust its output
rate. Since `set_fps()` also calls `force_keyframe()`, the next fragment will
be a join fragment, matching the media spec.

For Wayland specifically, where `pipewiresrc` delivers at compositor rate,
`videorate` is always present and handles the rate conversion. Changing the
caps on the capsfilter after `videorate` adjusts the output FPS.

This is a runtime caps renegotiation, which GStreamer supports natively.

## 6. WebSocket Client Changes (`ws.rs`)

### 6.1 Removed

- `RecordControlMessage` enum -- replaced by direct method calls on `Recorder`.
- `FrameResponse` enum -- replaced by `CaptureOutput`.
- `IMAGE_FRAME_RATE_MILLIS` constant -- FPS is configured in `CaptureConfig`.
- `frame_interval` timer -- fragments arrive when the muxer finalizes them.
- `pending_frame_request` flag -- no request/response pattern.
- `frame_encoding.rs` -- no longer needed. GStreamer produces ready-to-send bytes.
- JPEG+base64 encoding -- replaced by H.264 in fMP4.

### 6.2 New Signature

```rust
pub(crate) async fn connect_to_server_async(
    recorder: Recorder,
    mut capture_rx: Receiver<CaptureOutput>,
    jwt: String,
)
```

### 6.3 New `select!` Loop

```rust
let mut init_segment: Option<InitSegment> = None;

loop {
    select! {
        Some(output) = capture_rx.recv() => {
            match output {
                CaptureOutput::Init(init) => {
                    // Cache the init segment. Sent to server on registration.
                    init_segment = Some(init);
                }
                CaptureOutput::Media(fragment) => {
                    if sentinel_id.is_some() {
                        // Wrap fragment in protobuf and send as binary WS message.
                        // fragment.data is the raw fMP4 bytes.
                        // fragment.sequence is the sequence number.
                        // fragment.is_keyframe indicates join point.
                        let msg = /* build protobuf message */;
                        ws_write.send(Message::Binary(msg)).await.unwrap();
                    }
                }
            }
        }

        Some(msg) = ws_read.next() => {
            match /* parse ServerMessage */ {
                ServerPayload::RegistrationAck { sentinel_id: id } => {
                    sentinel_id = Some(id);
                    // Send cached init segment to server
                    if let Some(ref init) = init_segment {
                        let msg = /* build protobuf with init.data */;
                        ws_write.send(Message::Binary(msg)).await.unwrap();
                    }
                }
                ServerPayload::KeyframeRequest => {
                    recorder.force_keyframe();
                }
                ServerPayload::FpsChange { framerate } => {
                    recorder.set_fps(framerate);
                }
                ServerPayload::RegistrationReject { reason } => { break; }
            }
        }
    }
}

// Cleanup
recorder.stop();
```

## 7. Orchestrator Changes (`lib.rs`)

```rust
pub async fn start(args: Args) {
    let token = oidc::authenticate(Some(Duration::from_mins(1))).unwrap();

    let config = CaptureConfig {
        fps: 5.0,
        max_dimension: 1920,
        h264_profile: "main".to_string(),
        max_keyframe_interval_secs: 30,
    };

    let (recorder, capture_rx) = match Recorder::start(config).await {
        Ok((recorder, rx)) => (recorder, rx),
        Err(e) => {
            error!("Screen capture failed: {e}");
            std::process::exit(1);
        }
    };

    ws::connect_to_server_async(recorder, capture_rx, token.access_token).await;
}
```

## 8. File Inventory

| File                        | Action          | Description                                              |
|-----------------------------|-----------------|----------------------------------------------------------|
| `Cargo.toml`               | Edit            | Add gstreamer/ashpd/thiserror deps, remove xcap/image/base64. |
| `src/recorder/mod.rs`      | Full rewrite    | ~250 lines. Recorder public API, CaptureOutput, GStreamer pipeline. |
| `src/screen_capture.rs`    | Delete          | Replaced by `recorder` module (no legacy capture API).   |
| `src/frame_encoding.rs`    | Delete          | No longer needed. GStreamer handles encoding + muxing.   |
| `src/ws.rs`                | Simplify        | Receives `CaptureOutput`, sends binary WS. Handles keyframe/fps messages. ~60 lines cut. |
| `src/lib.rs`               | Update wiring   | New Recorder API, no fallback. ~20 lines changed.        |
| `src/image_generator.rs`   | Delete          | No fake frame fallback. GStreamer is required.            |

## 9. GStreamer Pipeline Reference

### Full X11 Pipeline

```
ximagesrc use-damage=false
  ! videorate
  ! video/x-raw,framerate={fps_n}/{fps_d}
  ! videoscale
  ! video/x-raw,width=[1,{max_w}],height=[1,{max_h}]
  ! videoconvert
  ! video/x-raw,format=I420
  ! x264enc
      profile={profile}
      key-int-max={max_keyframe_frames}
      tune=zerolatency
      speed-preset=superfast
      option-string="scenecut=0"
  ! video/x-h264,stream-format=avc,alignment=au
  ! isofmp4mux name=mux fragment-duration={fragment_duration_ns}
  ! appsink name=sink emit-signals=true sync=false
```

### Full Wayland Pipeline

```
pipewiresrc fd={fd} path={node_id}
  ! videorate
  ! video/x-raw,framerate={fps_n}/{fps_d}
  ! videoscale
  ! video/x-raw,width=[1,{max_w}],height=[1,{max_h}]
  ! videoconvert
  ! video/x-raw,format=I420
  ! x264enc
      profile={profile}
      key-int-max={max_keyframe_frames}
      tune=zerolatency
      speed-preset=superfast
      option-string="scenecut=0"
  ! video/x-h264,stream-format=avc,alignment=au
  ! isofmp4mux name=mux fragment-duration={fragment_duration_ns}
  ! appsink name=sink emit-signals=true sync=false
```

### Element Reference

| Element | Plugin Package | Purpose |
|---------|----------------|---------|
| `ximagesrc` | `gstreamer1.0-plugins-good` | X11 screen capture via XGetImage/SHM |
| `pipewiresrc` | `gstreamer1.0-plugins-bad` | PipeWire screen capture (Wayland) |
| `videorate` | `gstreamer1.0-plugins-base` | Framerate normalization/limiting |
| `videoscale` | `gstreamer1.0-plugins-base` | Resolution scaling |
| `videoconvert` | `gstreamer1.0-plugins-base` | Pixel format conversion (to I420) |
| `x264enc` | `gstreamer1.0-plugins-ugly` | H.264 encoding via libx264 |
| `isofmp4mux` | `gstreamer1.0-plugins-rs` (or `gst-plugins-rs`) | fMP4 muxing (init segment + fragments) |
| `appsink` | `gstreamer1.0-plugins-base` | Exposes buffers to application code |

## 10. Runtime System Dependencies

The machine running sentinel must have these installed. When packaging as a
`.deb`, these should be declared as package dependencies (`Depends:`).

| Package (Debian/Ubuntu)               | Purpose                              |
|---------------------------------------|--------------------------------------|
| `libgstreamer1.0-0`                   | GStreamer core runtime               |
| `gstreamer1.0-plugins-base`           | `videoconvert`, `videorate`, `videoscale`, `appsink` |
| `gstreamer1.0-plugins-good`           | `ximagesrc` (X11 capture)            |
| `gstreamer1.0-plugins-ugly`           | `x264enc` (H.264 encoding)          |
| `gstreamer1.0-plugins-bad` (Wayland)  | `pipewiresrc` (Wayland capture)      |
| `gst-plugins-rs` or equivalent        | `isofmp4mux` (fMP4 muxing)          |
| `libx264-dev`                         | libx264 runtime (used by x264enc)   |
| `libpipewire-0.3-0` (Wayland only)   | PipeWire runtime library             |
| `xdg-desktop-portal` (Wayland only)   | Portal service for screen picker     |

Note: `gst-plugins-rs` may not be in all distro repos. On Ubuntu 24.04+,
`isofmp4mux` is available in `gstreamer1.0-plugins-rs`. On older distros, it
may need to be installed from the GStreamer PPA or built from source. An
alternative is `mp4mux` from `-good` with `fragment-duration` support (check
GStreamer version).

On a typical modern Linux desktop (GNOME, KDE, etc.), most of these are
already installed. The `.deb` should declare them as dependencies so `apt`
resolves them automatically.

## 11. Error Handling Strategy

| Scenario                          | Behavior                                                   |
|-----------------------------------|------------------------------------------------------------|
| GStreamer not installed           | `CaptureError::GstreamerInit` -- `error!()` + exit(1)      |
| No DISPLAY or WAYLAND_DISPLAY     | `CaptureError::NoDisplayServer` -- `error!()` + exit(1)    |
| User cancels portal dialog        | `CaptureError::PortalCancelled` -- `error!()` + exit(1)    |
| Portal service not running        | `CaptureError::PortalFailed` -- `error!()` + exit(1)       |
| GStreamer pipeline fails to start | `CaptureError::PipelineFailed` -- `error!()` + exit(1)     |
| x264enc not available             | `CaptureError::PipelineFailed` -- check `-ugly` is installed |
| isofmp4mux not available          | `CaptureError::PipelineFailed` -- check `gst-plugins-rs` is installed |
| Fragment channel full             | Fragment silently dropped via `try_send` (logged as debug) |
| WebSocket disconnects             | Capture continues; ws.rs reconnect logic handles it        |

All capture errors are fatal. The sentinel requires a working GStreamer
installation and a display server. There is no fallback mode.

## 12. Licensing

GStreamer core and most plugins are LGPL-2.1+. `x264enc` is in
`gstreamer1.0-plugins-ugly` and links to libx264 (GPL-2.0). However:

- The sentinel binary dynamically links to GStreamer shared libraries.
- GStreamer dynamically loads plugins (including `x264enc`) at runtime.
- The sentinel code itself remains MIT.

**For `.deb` packaging:** The sentinel `.deb` contains only the MIT-licensed
binary. GStreamer packages are declared as dependencies and installed
separately by `apt`. No LGPL or GPL code is shipped in the sentinel package.

**For tarball distribution:** If bundling `.so` files, include LGPL-2.1 and
GPL-2.0 license texts, a `THIRD-PARTY-NOTICES` file, and a link to upstream
source. See the licensing discussion in the project notes for details.

**libx264 GPL note:** libx264 is GPL-2.0. Since it's loaded as a GStreamer
plugin (separate shared library, loaded at runtime), and the sentinel binary
does not link to it directly, this is generally considered compatible with
the sentinel's MIT license. The plugin is a separate program in the GPL
sense. However, this is a gray area -- consult legal advice if distributing
commercially. For a school project, this is a non-issue.

## 13. Migration Checklist

For implementors: a step-by-step order of operations.

1. [ ] Add new dependencies to `Cargo.toml` (`gstreamer`, `gstreamer-app`,
       `gstreamer-video`, `ashpd`, `thiserror`), remove `xcap`, `image`,
       `base64`.
2. [ ] Verify GStreamer + plugins are installed on the dev machine:
       `gst-inspect-1.0 x264enc`, `gst-inspect-1.0 isofmp4mux`.
3. [ ] Create `src/recorder/mod.rs` with new types (`InitSegment`, `Fragment`,
       `CaptureOutput`, `CaptureConfig`, `CaptureError`, `Recorder`). Start
       with X11 backend only.
4. [ ] Build the X11 GStreamer pipeline (capture -> encode -> mux -> appsink).
5. [ ] Implement the fragment pulling loop that produces `CaptureOutput`.
6. [ ] Test standalone: verify init segment + fragments come out of the
       pipeline. Optionally write to disk and play back with `ffplay`.
7. [ ] Implement `force_keyframe()` and `set_fps()`.
8. [ ] Update `src/ws.rs` to consume `CaptureOutput` and send binary messages.
       Remove old JPEG+base64 encoding, control enums, timer.
9. [ ] Update `src/lib.rs` to wire new `Recorder` API and expose it publicly
       (e.g., `pub mod recorder;` and/or `pub use recorder::{Recorder, CaptureConfig, CaptureOutput};`).
10. [ ] Delete `src/screen_capture.rs`.
11. [ ] Delete `src/frame_encoding.rs` (if it exists).
12. [ ] Delete `src/image_generator.rs`.
13. [ ] Build and fix compilation errors.
14. [ ] Test on X11: verify fragments arrive at server, playback works in
        browser via MSE.
15. [ ] Add Wayland backend (ashpd portal flow + pipewiresrc pipeline).
16. [ ] Test on Wayland: verify portal dialog appears, fragments arrive.
17. [ ] Test FPS changes at runtime via `set_fps()`.
18. [ ] Test on-demand keyframe via `force_keyframe()`.
19. [ ] Update `.deb` packaging to declare GStreamer + x264 dependencies.

## 14. Appendix: Current Code Reference

For orientation, here is what the current files look like and what gets replaced.

### `screen_capture.rs` (current -- 183 lines, will be removed)

- `RecordControlMessage` enum: `GetFrame`, `SetResolution(u32)`, `StartRecording`, `StopRecording`
- `FrameResponse` enum: `Frame(String)`, `NoFrame`
- `GLOBAL_FRAME: OnceLock<RwLock<xcap::Frame>>` -- global mutable state
- `start_screen_recording()`: monolithic async function that:
  - Creates xcap `VideoRecorder`
  - Spawns blocking recv loop into `tokio::spawn` (bug)
  - Handles control messages in a loop
  - Does RGBA->RGB, resize, JPEG encode, base64 encode per frame

### `ws.rs` (current -- 259 lines, will be simplified)

- `IMAGE_FRAME_RATE_MILLIS = 500` (2 FPS effective)
- `select!` loop with three branches:
  - `frame_rx.recv()`: receives `FrameResponse::Frame(String)`, sends over WS
  - `ws_read.next()`: handles server messages
  - `frame_interval.tick()`: sends `GetFrame` command every 500ms
- `pending_frame_request` flag to avoid piling up requests
- `send_large_string()`: manual WebSocket frame fragmentation (unused in practice)

### `lib.rs` (current -- 86 lines)

- Creates `mpsc::channel<RecordControlMessage>` and `mpsc::channel<FrameResponse>`
- Spawns `screen_capture::start_screen_recording(ctrl_rx, frame_tx)`
- Calls `ws::connect_to_server_async(ctrl_tx, frame_rx, jwt)`

### `image_generator.rs` (current -- 298 lines, will be deleted)

- `generate_random_image(width) -> (usize, usize, Vec<u8>)` -- returns tuple
- Generates 16:9 RGBA image with moving colored bars and 7-segment clock
- Used when xcap fails in dev mode or on macOS
- No longer needed: GStreamer is required, no fake frame fallback

## 15. Appendix: Media Spec Alignment

This table maps the media spec requirements to the implementation in this
design.

| Media Spec Requirement | Implementation |
|------------------------|----------------|
| H.264 codec | `x264enc` element in GStreamer pipeline |
| Main profile (default), Constrained Baseline (fallback) | `CaptureConfig.h264_profile` -> `x264enc profile=` property |
| Level 3.1 | Set via caps: `video/x-h264,level=(string)3.1` |
| fMP4 container | `isofmp4mux` element produces `ftyp+moov` + `moof+mdat` |
| Init segment (ftyp+moov) | `CaptureOutput::Init(InitSegment)` -- first buffer from appsink |
| Media fragments (moof+mdat) | `CaptureOutput::Media(Fragment)` -- subsequent buffers |
| Fragment sequence numbers | `Fragment.sequence` -- assigned by pulling loop, 0-based |
| Join fragments (IDR entry points) | `Fragment.is_keyframe` flag, detected via buffer flags |
| On-demand keyframe | `Recorder::force_keyframe()` -> `GstForceKeyUnit` event |
| Keyframe on FPS change | `set_fps()` calls `force_keyframe()` internally |
| Max 20-30s keyframe interval | `x264enc key-int-max=fps*30` |
| Variable FPS (0.2 to 5) | `videorate` + caps filter, adjustable at runtime |
| Max 1080p resolution | `videoscale` + caps filter in pipeline |
| Fragment duration (variable, short) | `isofmp4mux fragment-duration=1000000000` (1s default) |
| Timestamps in fragments (tfdt, trun) | Handled by `isofmp4mux` automatically |
| MSE-compatible output | `isofmp4mux` produces MSE-appendable fMP4 |
