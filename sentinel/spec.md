# Franklyn Sentinel -- Screen Capture Rewrite Specification

| Field       | Value                              |
|-------------|------------------------------------|
| Status      | Draft                              |
| Authors     | Jakob Huemer-Fistelberger          |
| Created     | 2026-03-16                         |
| Component   | `sentinel/src/screen_capture.rs`   |
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

The rewrite replaces xcap with GStreamer (via Rust bindings) and ashpd (XDG
Desktop Portal wrapper) to get proper framerate control, event-driven frame
delivery, and clean separation of concerns.

## 2. Goals

- Replace `xcap` with `gstreamer` + `ashpd` for screen capture.
- Deliver raw RGBA pixel frames via a `tokio::sync::mpsc::Receiver`.
- Support configurable FPS (default: 5) and runtime FPS changes.
- Support configurable max dimension with runtime changes (downscaling in Rust).
- Detect X11 vs Wayland at runtime and use the appropriate capture backend.
- On Wayland, handle the XDG Desktop Portal dialog (screen picker) transparently.
- Separate frame encoding (JPEG + base64) from capture.
- Remove the request/response ping-pong pattern between `ws.rs` and capture.
- Remove global mutable state (`GLOBAL_FRAME`).
- Keep the fake frame generator for dev/macOS environments as a separate
  fallback, not mixed into the capture module.

## 3. Non-Goals

- Backend-agnostic trait abstraction (we commit to GStreamer).
- Recording to disk (this is a live streaming use case).
- Audio capture.
- Multi-monitor selection UI (captures primary/portal-selected monitor).

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
   | screen_capture.rs   |      |     ws.rs             |
   | (ScreenCapturer)    |      | (WebSocket client)    |
   |                     |      |                       |
   | GStreamer pipeline   |      | Receives RawFrame     |
   | -> appsink          | ---> | Encodes JPEG+base64   |
   | -> RawFrame          |  rx  | Sends over WebSocket  |
   | -> mpsc::Sender      |      |                       |
   +----------------------+      | Uses frame_encoding   |
                                 +-----------+-----------+
                                             |
                                  +----------v----------+
                                  | frame_encoding.rs   |
                                  | (JPEG + base64)     |
                                  +---------------------+
```

On capture failure in dev/macOS environments, `lib.rs` falls back to
`image_generator.rs` which produces fake `RawFrame` data.

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
xcap = "0.9.1"
```

Keep `image` (needed for downscaling in Rust), `base64` (needed for encoding).

### 5.2 Public Types (`screen_capture.rs`)

```rust
/// Raw frame data delivered to the consumer.
/// Pixels are in RGBA format, 4 bytes per pixel.
/// `data.len() == width * height * 4`
pub struct RawFrame {
    pub width: u32,
    pub height: u32,
    pub data: Vec<u8>,
}

/// Configuration for the screen capturer.
pub struct CaptureConfig {
    /// Target frames per second. Default: 5.
    pub fps: u32,
    /// Maximum dimension (width or height) in pixels.
    /// Frames exceeding this are downscaled preserving aspect ratio.
    /// Default: Some(1920).
    pub max_dimension: Option<u32>,
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
pub struct ScreenCapturer { /* ... */ }
```

### 5.3 `ScreenCapturer` API

```rust
impl ScreenCapturer {
    /// Start capturing the screen.
    ///
    /// 1. Initializes GStreamer.
    /// 2. Detects X11 vs Wayland from environment variables.
    /// 3. On Wayland: opens XDG Desktop Portal ScreenCast dialog via ashpd.
    /// 4. Builds a GStreamer pipeline with an appsink.
    /// 5. Spawns a background task that pulls frames and sends them.
    ///
    /// Returns a handle and a receiver that yields `RawFrame` at ~`config.fps`.
    /// When the capturer is dropped or `stop()` is called, the receiver
    /// yields `None`.
    pub async fn start(
        config: CaptureConfig,
    ) -> Result<(Self, tokio::sync::mpsc::Receiver<RawFrame>), CaptureError>;

    /// Change the target FPS at runtime.
    /// On X11: modifies the sleep interval in the pulling loop.
    /// On Wayland: modifies the sleep interval in the pulling loop.
    pub fn set_fps(&self, fps: u32);

    /// Change the max dimension for post-capture downscaling.
    /// Takes effect on the next frame.
    pub fn set_max_dimension(&self, max_dimension: Option<u32>);

    /// Stop capturing. The receiver will yield `None` after this.
    /// Also called automatically on `Drop`.
    pub fn stop(&self);
}
```

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
4. Build GStreamer pipeline:
   ```
   pipewiresrc fd={fd} path={node_id}
     ! videoconvert
     ! video/x-raw,format=RGBA
     ! appsink name=sink emit-signals=true sync=false max-buffers=1 drop=true
   ```

Note: On Wayland, PipeWire delivers frames at the compositor's chosen rate
(typically 30-60fps). FPS limiting is done in the pulling loop via sleep, not
in the GStreamer pipeline.

### 5.6 Internal: X11 Capture Flow

No portal dialog needed. Build GStreamer pipeline directly:

```
ximagesrc use-damage=false
  ! videorate
  ! video/x-raw,framerate={fps}/1
  ! videoconvert
  ! video/x-raw,format=RGBA
  ! appsink name=sink emit-signals=true sync=false max-buffers=1 drop=true
```

On X11, `videorate` + caps control the capture framerate at the GStreamer level,
which is more efficient than capturing at full speed and dropping frames.

### 5.7 Internal: Frame Pulling Loop

After pipeline is set to `Playing`, spawn a background task:

```rust
tokio::task::spawn_blocking(move || {
    let appsink: AppSink = /* retrieved from pipeline by name */;
    loop {
        // Check if stopped
        if stop_flag.load(Ordering::Relaxed) { break; }

        // Pull a frame (blocking, with timeout)
        let Some(sample) = appsink.try_pull_sample(gst::ClockTime::from_mseconds(500)) else {
            continue; // timeout, retry
        };

        // Extract buffer, map to readable bytes
        let buffer = sample.buffer().unwrap();
        let map = buffer.map_readable().unwrap();
        let raw_bytes = map.as_slice();

        // Get dimensions from caps
        let caps = sample.caps().unwrap();
        let structure = caps.structure(0).unwrap();
        let width = structure.get::<i32>("width").unwrap() as u32;
        let height = structure.get::<i32>("height").unwrap() as u32;

        // Read current max_dimension setting
        let max_dim = max_dimension.load();

        // Downscale if needed (using `image` crate)
        let frame = downscale_if_needed(raw_bytes, width, height, max_dim);

        // Send to channel (non-blocking, drop if consumer is behind)
        let _ = frame_tx.try_send(frame);

        // FPS limiting (for Wayland; on X11 videorate handles this)
        if is_wayland {
            let target_interval = Duration::from_millis(1000 / fps.load() as u64);
            std::thread::sleep(target_interval);
        }
    }
});
```

**Channel capacity:** 2 frames. Uses `try_send` so that if the consumer (ws.rs)
is behind, old frames are silently dropped. This prevents memory buildup.

### 5.8 Downscaling

Downscaling is done in Rust after receiving the raw frame, using the `image`
crate's `imageops::resize` with `FilterType::Lanczos3` (matching current
behavior).

```rust
fn downscale_if_needed(
    rgba: &[u8], width: u32, height: u32, max_dim: Option<u32>
) -> RawFrame {
    let Some(max) = max_dim else {
        return RawFrame { width, height, data: rgba.to_vec() };
    };
    let max_current = width.max(height);
    if max_current <= max {
        return RawFrame { width, height, data: rgba.to_vec() };
    }
    let scale = max as f32 / max_current as f32;
    let new_w = (width as f32 * scale) as u32;
    let new_h = (height as f32 * scale) as u32;

    let img: ImageBuffer<Rgba<u8>, _> =
        ImageBuffer::from_raw(width, height, rgba.to_vec()).unwrap();
    let resized = imageops::resize(&img, new_w, new_h, imageops::FilterType::Lanczos3);

    RawFrame {
        width: new_w,
        height: new_h,
        data: resized.into_raw(),
    }
}
```

### 5.9 Runtime Configuration via Shared State

FPS and max_dimension are stored in shared atomic/mutex state inside
`ScreenCapturer`, readable from the pulling loop:

```rust
pub struct ScreenCapturer {
    pipeline: gst::Pipeline,
    fps: Arc<AtomicU32>,
    max_dimension: Arc<Mutex<Option<u32>>>,
    stop_flag: Arc<AtomicBool>,
}

impl ScreenCapturer {
    pub fn set_fps(&self, fps: u32) {
        self.fps.store(fps, Ordering::Relaxed);
    }
    pub fn set_max_dimension(&self, max_dimension: Option<u32>) {
        *self.max_dimension.lock().unwrap() = max_dimension;
    }
    pub fn stop(&self) {
        self.stop_flag.store(true, Ordering::Relaxed);
        let _ = self.pipeline.set_state(gst::State::Null);
    }
}

impl Drop for ScreenCapturer {
    fn drop(&mut self) {
        self.stop();
    }
}
```

## 6. Frame Encoding (`frame_encoding.rs`)

New file. Extracted from current `screen_capture.rs`:

```rust
use base64::Engine;
use image::{ImageBuffer, Rgba, codecs::jpeg::JpegEncoder, ImageEncoder, ExtendedColorType, ColorType};

use crate::screen_capture::RawFrame;

/// Encode a RawFrame (RGBA) to a base64-encoded JPEG string.
pub fn encode_frame_jpeg_base64(frame: &RawFrame, quality: u8) -> String {
    // Strip alpha: RGBA -> RGB
    let rgb: Vec<u8> = frame.data
        .chunks_exact(4)
        .flat_map(|px| [px[0], px[1], px[2]])
        .collect();

    let mut buf = Vec::new();
    JpegEncoder::new_with_quality(&mut buf, quality)
        .write_image(&rgb, frame.width, frame.height, ExtendedColorType::from(ColorType::Rgb8))
        .expect("JPEG encoding failed");

    base64::engine::general_purpose::STANDARD.encode(buf)
}
```

## 7. WebSocket Client Changes (`ws.rs`)

### 7.1 Removed

- `RecordControlMessage` enum -- no longer needed; direct method calls replace it.
- `FrameResponse` enum -- replaced by `RawFrame`.
- `IMAGE_FRAME_RATE_MILLIS` constant -- FPS is now in `CaptureConfig`.
- `frame_interval` timer -- frames arrive via the receiver at the capture FPS.
- `pending_frame_request` flag -- no request/response pattern.

### 7.2 New Signature

```rust
pub(crate) async fn connect_to_server_async(
    capturer: Option<ScreenCapturer>,  // None when using fake frames
    mut frame_rx: Receiver<RawFrame>,
    jwt: String,
)
```

### 7.3 New `select!` Loop

```rust
loop {
    select! {
        // Frames arrive at capture FPS -- no timer needed
        Some(frame) = frame_rx.recv() => {
            if let Some(sentinel_id) = sentinel_id {
                let base64 = frame_encoding::encode_frame_jpeg_base64(&frame, 70);
                let msg = /* build SentinelMessage::Frame with base64 */;
                ws_write.send(Message::Text(msg.into())).await.unwrap();
                frame_index += 1;
            }
        }

        Some(msg) = ws_read.next() => {
            match /* parse ServerMessage */ {
                ServerPayload::RegistrationAck { sentinel_id: id } => {
                    sentinel_id = Some(id);
                    // No StartRecording command needed -- capture is already running
                }
                ServerPayload::Resolution { max_side_px } => {
                    if let Some(ref c) = capturer {
                        c.set_max_dimension(Some(max_side_px));
                    }
                }
                ServerPayload::RegistrationReject { reason } => { break; }
            }
        }
    }
}

// Cleanup
if let Some(c) = capturer {
    c.stop();
}
```

## 8. Orchestrator Changes (`lib.rs`)

```rust
pub async fn start(args: Args) {
    let token = oidc::authenticate(Some(Duration::from_mins(1))).unwrap();

    let config = CaptureConfig { fps: 5, max_dimension: Some(1920) };

    let (capturer, frame_rx): (Option<ScreenCapturer>, Receiver<RawFrame>) =
        match ScreenCapturer::start(config).await {
            Ok((capturer, rx)) => (Some(capturer), rx),
            Err(e) => {
                #[cfg(any(env = "dev", target_os = "macos"))]
                {
                    warn!("Screen capture failed ({e}), using fake frames");
                    let (tx, rx) = tokio::sync::mpsc::channel(2);
                    tokio::spawn(fake_frame_loop(tx, 5, 1920));
                    (None, rx)
                }
                #[cfg(all(env = "prod", not(target_os = "macos")))]
                {
                    error!("Screen capture failed: {e}");
                    std::process::exit(1);
                }
            }
        };

    ws::connect_to_server_async(capturer, frame_rx, token.access_token).await;
}

#[cfg(any(env = "dev", target_os = "macos"))]
async fn fake_frame_loop(
    tx: tokio::sync::mpsc::Sender<RawFrame>,
    fps: u32,
    width: usize,
) {
    let interval = Duration::from_millis(1000 / fps as u64);
    loop {
        let frame = image_generator::generate_random_image(width);
        if tx.try_send(frame).is_err() {
            // Consumer behind, skip frame
        }
        tokio::time::sleep(interval).await;
    }
}
```

## 9. `image_generator.rs` Changes

Change the return type of `generate_random_image`:

```rust
// Before:
pub fn generate_random_image(width: usize) -> (usize, usize, Vec<u8>)

// After:
pub fn generate_random_image(width: usize) -> RawFrame
```

The internal logic stays the same. The function constructs a `RawFrame` instead
of returning a tuple.

## 10. File Inventory

| File                        | Action          | Description                                              |
|-----------------------------|-----------------|----------------------------------------------------------|
| `Cargo.toml`               | Edit            | Add gstreamer/ashpd/thiserror deps, remove xcap          |
| `src/screen_capture.rs`    | Full rewrite    | ~200 lines. ScreenCapturer, RawFrame, GStreamer pipeline  |
| `src/frame_encoding.rs`    | New file        | ~30 lines. JPEG + base64 encoding helper                 |
| `src/ws.rs`                | Simplify        | Remove control enums, timer, pending flag. ~50 lines cut  |
| `src/lib.rs`               | Update wiring   | New ScreenCapturer API, fake frame fallback. ~20 lines    |
| `src/image_generator.rs`   | Minor change    | Return `RawFrame` instead of tuple. ~5 lines              |

## 11. GStreamer Pipeline Reference

### X11

```
ximagesrc use-damage=false
  ! videorate
  ! video/x-raw,framerate={fps}/1
  ! videoconvert
  ! video/x-raw,format=RGBA
  ! appsink name=sink emit-signals=true sync=false max-buffers=1 drop=true
```

- `ximagesrc`: Captures the X11 root window using XGetImage/SHM.
- `use-damage=false`: Capture full frame every time (not just changed regions).
- `videorate` + caps: Limits capture to exactly `{fps}` frames per second.
- `videoconvert` + caps: Converts to RGBA pixel format.
- `appsink`: Exposes frames to the application. `max-buffers=1 drop=true` means
  only the latest frame is kept; older frames are dropped if not consumed.

### Wayland

```
pipewiresrc fd={fd} path={node_id}
  ! videoconvert
  ! video/x-raw,format=RGBA
  ! appsink name=sink emit-signals=true sync=false max-buffers=1 drop=true
```

- `pipewiresrc`: Receives screen data from PipeWire.
  - `fd`: File descriptor from `open_pipe_wire_remote()`.
  - `path`: PipeWire node ID from portal response.
- No `videorate` here -- PipeWire delivers at compositor rate. FPS limiting is
  done in the pulling loop via `thread::sleep`.

## 12. Runtime System Dependencies

The machine running sentinel must have these installed. When packaging as a
`.deb`, these should be declared as package dependencies (`Depends:`).

| Package (Debian/Ubuntu)               | Purpose                              |
|---------------------------------------|--------------------------------------|
| `libgstreamer1.0-0`                   | GStreamer core runtime               |
| `gstreamer1.0-plugins-base`           | `videoconvert`, `videorate`, `appsink` |
| `gstreamer1.0-plugins-good`           | `ximagesrc` (X11 capture)            |
| `gstreamer1.0-plugins-bad` (optional) | `pipewiresrc` (Wayland capture)      |
| `libpipewire-0.3-0` (Wayland only)   | PipeWire runtime library             |
| `xdg-desktop-portal` (Wayland only)   | Portal service for screen picker     |

On a typical modern Linux desktop (GNOME, KDE, etc.), all of these are already
installed. The `.deb` should declare them as dependencies so `apt` resolves them
automatically.

## 13. Error Handling Strategy

| Scenario                          | Behavior                                                   |
|-----------------------------------|------------------------------------------------------------|
| GStreamer not installed           | `CaptureError::GstreamerInit` -- fatal in prod, fake frames in dev |
| No DISPLAY or WAYLAND_DISPLAY     | `CaptureError::NoDisplayServer` -- fatal in prod, fake frames in dev |
| User cancels portal dialog        | `CaptureError::PortalCancelled` -- fatal in prod, fake frames in dev |
| Portal service not running        | `CaptureError::PortalFailed` -- fatal in prod, fake frames in dev |
| GStreamer pipeline fails to start | `CaptureError::PipelineFailed` -- fatal in prod, fake frames in dev |
| Frame channel full (consumer slow)| Frame silently dropped via `try_send` (logged as debug)    |
| WebSocket disconnects             | Capture continues; ws.rs reconnect logic handles it        |

"Fatal in prod" means `error!()` + `std::process::exit(1)`.
"Fake frames in dev" means `warn!()` + spawn fake frame generator.

## 14. Migration Checklist

For implementors: a step-by-step order of operations.

1. [ ] Add new dependencies to `Cargo.toml`, remove `xcap`.
2. [ ] Create `src/screen_capture.rs` with the new API (types + `ScreenCapturer`).
       Start with X11 backend only for easier testing.
3. [ ] Create `src/frame_encoding.rs` with the JPEG+base64 helper.
4. [ ] Update `src/image_generator.rs` to return `RawFrame`.
5. [ ] Update `src/lib.rs` to wire new `ScreenCapturer` + fallback.
6. [ ] Update `src/ws.rs` to consume `RawFrame` and use `frame_encoding`.
7. [ ] Build and fix compilation errors.
8. [ ] Test on X11: verify frames arrive, JPEG encoding works, WebSocket sends.
9. [ ] Add Wayland backend (ashpd portal flow + pipewiresrc pipeline).
10. [ ] Test on Wayland: verify portal dialog appears, frames arrive.
11. [ ] Test FPS changes at runtime via `set_fps()`.
12. [ ] Test resolution changes via `set_max_dimension()` (triggered by server).
13. [ ] Test dev fallback: run without GStreamer installed, verify fake frames.
14. [ ] Update `.deb` packaging to declare GStreamer dependencies.

## 15. Appendix: Current Code Reference

For orientation, here is what the current files look like and what gets replaced.

### `screen_capture.rs` (current -- 183 lines, will be fully rewritten)

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

### `image_generator.rs` (current -- 298 lines)

- `generate_random_image(width) -> (usize, usize, Vec<u8>)` -- returns tuple
- Generates 16:9 RGBA image with moving colored bars and 7-segment clock
- Used when xcap fails in dev mode or on macOS
