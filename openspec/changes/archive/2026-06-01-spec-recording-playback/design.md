## Context

Recording-playback is the largest gap in the FSD-to-code delta: it is a v1 acceptance criterion (§17) but is essentially unbuilt. The sentinel's GStreamer pipeline ends in `jpegenc`, producing standalone JPEG frames that travel over the live WebSocket as base64 JSON and land in the server's in-memory `Cache` (latest frame per sentinel, overwritten each push). There is no encoder for H.265, no MP4 muxer, no file sink, no video table, and no playback UI. This design records the target architecture and the dependencies on neighbouring threads.

Verified current state:
- `recorder.rs` pipeline: `... ! jpegenc quality={q} ! appsink` — JPEG only, no `x265enc`/`mp4mux`/`filesink`.
- No filesystem writes for media (`std::fs` used only for logs and the OIDC redirect).
- `Cache` holds one live frame per sentinel; no persistence.
- `protobuf/ws/v2/` defines `Envelope`, `OpenStream`, `StreamMeta { something }`, auth messages — a future "v2" stream protocol, currently unwired (live frames still use the v1 JSON path).
- No `playback|mp4|h265|video|timeline` references anywhere in `server/` or `proctor/`.

## Goals / Non-Goals

**Goals:**
- Capture recording-playback requirements at FSD target state with accurate status (predominantly not-implemented).
- Make the timeline's cross-thread dependencies explicit so sequencing is clear.

**Non-Goals:**
- Implementing recording, storage, or playback (spec thread).
- Defining file-diff capture (Thread 5) or alarm generation (Thread 6) — this spec only states that their events appear on the playback timeline.
- Retention/deletion mechanics for stored video (Thread 7 / Thread 2 delete cascade).

## Decisions

- **Record on the server side from the existing stream, not a second client encoder (preferred direction, not yet built).** The sentinel already ships frames to the server; encoding/persisting there avoids trusting student devices with storage and matches the on-prem model (§3.3). Alternative (sentinel writes MP4 locally then uploads) rejected: storage on student devices, upload reliability, and tamper surface. This is a design lean recorded for the future implementation, not a committed build.
- **Timeline is a join, not a new data source.** The synchronised timeline (§8.3) overlays three already-owned streams: screen events (this capability), file diffs (Thread 5), alarm markers (Thread 6). The spec states the synchronisation requirement; each source is defined in its own capability.
- **Keep live and recording paths conceptually separate.** Live monitoring (Thread 3) optimises for latency and may downscale; recording targets fidelity (1080p/H.265). One capture can feed both, but their requirements differ and live downscaling must not degrade the stored recording.

## Risks / Trade-offs

- [Server-side H.265 encode for up to 50 students/exam, 19 exams] → Significant CPU; may require hardware encode or per-node sharding. Flagged for the implementation spike; out of scope for the spec.
- [No storage layer exists] → Recording depends on a video store + metadata schema that must be designed with Thread 7 retention (§12.1, 30 days) and Thread 2 delete cascade (§12.2) in mind, or deletion/retention will be impossible to honour later.
- [protobuf v2 scaffolding is incomplete and unwired] → Building recording on it risks churn; decide at implementation time whether to finish v2 or extend the v1 JSON path.

## Open Questions

- Where is video stored (filesystem path layout vs object store) and how is it keyed to exam + student + session?
- Is recording a separate higher-fidelity capture, or is the stored video reconstructed from the same frames sent live?
- Marker model: are alarm markers timestamps resolved at playback time, or materialised onto the recording when written?
