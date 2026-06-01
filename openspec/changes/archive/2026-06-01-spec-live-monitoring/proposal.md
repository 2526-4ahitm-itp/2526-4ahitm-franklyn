## Why

The FSD requires teachers to watch student screens live: a 6-up grid with pagination, zoom into one student, view-only (no remote control), capture at 1080p / default 10 FPS with adaptive downscaling, and a target latency ≤10s (§7, §15, US-03). The live spine exists (proctor subscribes to sentinel frames via WebSocket), but several FSD parameters are unmet — notably the frame rate and adaptive quality. This change captures the live-monitoring capability as a spec with accurate per-requirement status before the next implementation pass.

## What Changes

- Introduce the `live-monitoring` capability spec covering the live grid, pagination, per-student detail/zoom, view-only constraint, capture quality/FPS, adaptive downscaling, no-audio / no-multi-monitor scope, connection status visibility, and latency target.
- Document that default capture is **10 FPS** (§7.2) — current sentinel hardcodes `fps = 2.0` and caps at ≤5 FPS.
- Document **adaptive quality/FPS downscaling** (§7.2) — current `Recorder::set_quality` is a no-op, so the server's `set-profile` resolution changes are ignored client-side.
- Document **connected/disconnected student status** visibility (§15) — students currently just vanish from the grid on disconnect with no explicit status.
- Record implementation status per requirement; unmet FSD requirements become `[GAP]` tasks.

## Capabilities

### New Capabilities
- `live-monitoring`: live screen grid of 6 with pagination (§7.1, US-03), per-student detail/zoom (§7.1), view-only constraint (§7.1), primary capture 1080p / default 10 FPS (§7.2), adaptive quality/FPS downscale (§7.2), latency target ≤10s (§7.2), no audio + no multi-monitor (§7.3), and student connection-status visibility (§15).

### Modified Capabilities
<!-- None. Consumes exam-lifecycle (PIN/session) and auth-identity but changes no existing requirements. -->

## Impact

- **Sentinel (Rust)**: `recorder.rs` frame-rate default (10 FPS) and a working `set_quality` to honour server `server.set-resolution`; profile→FPS mapping for adaptive downscale.
- **Backend (Java/Quarkus)**: `FranklynWebSocketServer` set-profile path + `Profiles` (resolution tiers already HIGH/MEDIUM/LOW); frame fan-out via `Cache` (latest-frame-per-sentinel).
- **Frontend (Vue)**: `WebsocketStore` (6-up paging, subscribe/revoke) and `ProctoringView` (grid + zoom overlay) exist; add explicit connected/disconnected status indicator.
- **Cross-references**: connection-loss **alarm** (§6.3, §11) is owned by `spec-violation-alarms` (Thread 6); this spec covers only the *status visibility* aspect. Persisted video/playback is `spec-recording-playback` (Thread 4) — this spec covers only the live stream.
