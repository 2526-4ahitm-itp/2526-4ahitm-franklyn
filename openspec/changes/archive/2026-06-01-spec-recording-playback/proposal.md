## Why

The FSD requires that each student's exam be recorded as MP4/H.265 video without audio, stored, and replayable afterwards with play/pause, frame-by-frame, jump-to-alarm, and a timeline that synchronises screen events, file diffs, and alarm markers (§8, US-06). This is also a v1 acceptance criterion (§17: "Videos der Schülerprüfungen werden gespeichert und abspielbar gemacht"). The current system captures only live JPEG frames held in an in-memory cache — nothing is encoded to video, persisted, or replayable. This change captures the recording-playback capability as a spec so the (large) gap is documented and tracked.

## What Changes

- Introduce the `recording-playback` capability spec covering video encoding (MP4/H.265, no audio), per-session persistence, playback controls (play/pause, frame-by-frame), jump-to-alarm/marker, and the synchronised playback timeline.
- Document that recording is **not implemented**: the sentinel pipeline encodes JPEG frames (`jpegenc`) only — no `mp4mux`/H.265, no file persistence.
- Document that playback, markers, and the timeline are **not implemented**: no playback code exists in proctor or server.
- Record implementation status per requirement; the unbuilt FSD requirements become `[GAP]` tasks.

## Capabilities

### New Capabilities
- `recording-playback`: video recording in MP4/H.265 without audio (§8.1), per-student/exam video persistence and retrieval (US-06, §17), playback controls play/pause and frame-by-frame (§8.2), jump-to-alarm/marker navigation (§8.2), and a synchronised playback timeline of screen events, file diffs, and alarm markers (§8.3).

### Modified Capabilities
<!-- None. This capability will consume file-tracking diffs (Thread 5) and violation-alarms markers (Thread 6) on the timeline, and retention/deletion from data-admin (Thread 7), but changes no existing requirements. -->

## Impact

- **Sentinel (Rust)**: `recorder.rs` would gain an H.265 encode + MP4 mux + file/stream sink path alongside (or instead of) the live JPEG path; the `protobuf/ws/v2` stream scaffolding (`OpenStream`/`StreamMeta`) is currently unwired and would carry recording streams.
- **Backend (Java/Quarkus)**: new video storage (filesystem + DB metadata), a retrieval endpoint, and event/marker association — none exist today (`Cache` is live-only, no video tables).
- **Frontend (Vue)**: a new playback view with transport controls, frame stepping, marker navigation, and a synchronised timeline — none exists.
- **Cross-references**: timeline file-diff events come from `spec-file-tracking` (Thread 5); alarm markers from `spec-violation-alarms` (Thread 6); video retention/hard-delete from `spec-data-admin` (Thread 7) and `exam-lifecycle` (Thread 2, delete cascade). The live stream itself is `spec-live-monitoring` (Thread 3).
