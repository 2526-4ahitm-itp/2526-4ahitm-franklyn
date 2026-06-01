## Context

Live monitoring is a push pipeline: the Rust sentinel captures the screen with GStreamer, JPEG-encodes frames, and sends them over WebSocket (`sentinel.frame`). The server `Cache` keeps only the latest frame per sentinel and fans it out to subscribed proctors via `FrameListener`. The Vue `WebsocketStore` subscribes to the 6 sentinels on the current page and renders them in `ProctoringView`; clicking one opens a zoom overlay and raises its profile to `HIGH`. The FSD (§7, §15) is the target; this design records how the unmet parameters would be closed.

Verified current state:
- `recorder.rs`: `fps = 2.0` hardcoded; `fps_to_fraction` clamps to `[0.2, 5.0]` FPS; `Recorder::set_quality(&self, _q: u32)` is an empty no-op.
- Server `Profiles`: HIGH=1920, MEDIUM=1280, LOW=640 px max side; `proctor.set-profile` → `server.set-resolution{maxSidePx}` to the sentinel.
- `WebsocketStore`: `pageSize = 6`, auto subscribe/revoke on page change; subscribe defaults a sentinel to `LOW`, zoom sets `HIGH`.
- `Cache`: single latest frame per sentinel (`frameMap.put` overwrites) — correct for a live view, not a recording.

## Goals / Non-Goals

**Goals:**
- Capture live-monitoring requirements at FSD target state with accurate per-requirement status.
- Make the FPS, adaptive-downscale, and connection-status gaps explicit and individually trackable.

**Non-Goals:**
- Implementing the gaps (spec thread; code lands later).
- Connection-loss **alarm** semantics (§6.3/§11) — owned by `spec-violation-alarms` (Thread 6). This spec only covers status *visibility*.
- Persisted recording and playback (§8) — owned by `spec-recording-playback` (Thread 4). The `Cache` here is live-only.

## Decisions

- **Adaptive control stays server-driven via `set-profile`.** The protocol already carries `server.set-resolution{maxSidePx}`; the fix is client-side (`set_quality` must actually re-cap the pipeline) plus extending profiles to also carry an FPS target. Alternative (sentinel self-adapts on bandwidth) rejected: the proctor UI already owns the quality decision (LOW on grid, HIGH on zoom), which matches FSD intent.
- **Default FPS = 10 at capture; live stream may be downscaled below it.** FSD §7.2 sets default 10 FPS as the primary rate; adaptive downscale lowers it for grid tiles. The current ≤5 FPS clamp must be raised. Keep capture and live-send rates conceptually separate (capture feeds both live and, later, recording in Thread 4).
- **Connection status derived from the sentinel list, not a new channel.** The server already broadcasts `server.update-sentinels` on connect/disconnect; the frontend should render a present/absent sentinel as connected/disconnected rather than silently dropping it. No new server state required.

## Risks / Trade-offs

- [Raising FPS to 10 increases CPU/bandwidth on student devices] → FSD §14 wants "no noticeable impact"; adaptive downscale on grid tiles (LOW) mitigates; HIGH only on the single zoomed student.
- [`set_quality` no-op means today's adaptive profile silently does nothing] → Functional gap, not a crash; documented as not-implemented so it is not mistaken for working.
- [Latency ≤10s is unmeasured] → No instrumentation exists; marking it not-implemented avoids a false "verified" claim. Needs a measurement spike before it can be asserted.

## Open Questions

- Exact profile→FPS mapping (e.g. LOW=2, MEDIUM=5, HIGH=10?) — FSD fixes only the 10 FPS default, not the tiers.
- Should a disconnected student remain visible (greyed, "disconnected") until exam end, or drop after a timeout? FSD §15 only requires the status be visible.
