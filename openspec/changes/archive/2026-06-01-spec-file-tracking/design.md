## Context

File tracking is, like recording-playback, an essentially unbuilt FSD capability. The FSD (§9, US-05) wants per-minute incremental text-file diffs bound to a student session, stored diff-only. The sentinel today captures the screen (`recorder.rs`, GStreamer JPEG pipeline) and streams it; it never touches the filesystem for monitoring. This design records the target architecture and its dependencies on neighbouring threads.

Verified current state:
- `sentinel/src/proto.rs` is a 3-line stub — no diff/file message type.
- No file-watch / diff code anywhere in `sentinel/src/` (no `notify`, `fswatch`, diffing, or text-file reads for monitoring).
- No diff/file-event code in `server/src/main/java`; no diff table among the Flyway migrations (`fr_user/teacher/student/exam/notice` only).
- No file-diff UI in `proctor/`.

## Goals / Non-Goals

**Goals:**
- Capture file-tracking requirements at FSD target state with accurate status (entirely not-implemented).
- Make the cross-thread dependencies explicit (timeline consumer, alarm type, delete cascade, session binding).

**Non-Goals:**
- Implementing file watching, diffing, storage, or UI (spec thread).
- Defining the playback timeline that renders diffs (Thread 4) or the file-source-unavailable alarm (Thread 6) — this spec only states that diffs are produced and bound to a session.
- Retention/deletion mechanics for stored diffs (Thread 7 / Thread 2 delete cascade).

## Decisions

- **Diff-only storage, forced every minute (FSD-mandated, not yet built).** Per §9.2 only incremental diffs are stored — no full snapshot as the primary model — and a diff run is forced each minute regardless of whether a save occurred. Incremental baseline is the last saved state of each observed file. This is recorded as the target; no storage exists yet.
- **Best-effort source detection, not full FS monitoring.** Per §9.1 the observed set is derived best-effort from the active-window app and the last-saved file, and the 1-minute run covers all currently observed files. The spec states this as best-effort, not a guaranteed-complete capture, matching the FSD wording.
- **Diffs are a timeline source, not a timeline owner.** File diffs are produced and bound to a session here; the synchronised playback timeline that renders them is `recording-playback` (Thread 4, §8.3). Keep the producer (this capability) and the consumer (timeline) separate.

## Risks / Trade-offs

- [Best-effort source detection] → Active-window/last-saved heuristics can miss files the student edits without saving or in unfocused windows; the FSD accepts "best effort", but coverage gaps must be expected and not mistaken for "no changes".
- [No storage layer exists] → Diff storage must be designed with Thread 7 retention (§12.1, 30 days) and Thread 2 delete cascade (§12.2) in mind, or deletion/retention cannot be honoured later — same constraint as recording-playback video.
- [Text-vs-binary classification] → §9.3 excludes binary files; a misclassification either leaks binary noise as "diffs" or drops a real text file. The classifier is a correctness risk for the implementation, out of scope for the spec.
- [`proto.rs` is a stub] → The wire path for diffs is undefined; whether diffs reuse the live WS JSON path or a future protobuf v2 channel is an implementation-time decision (shared open question with Thread 3/4).

## Open Questions

- How are "observed files" enumerated from the active-window app — by app-specific introspection, recent-files heuristics, or OS file-access events?
- What diff format is stored (unified text diff, structured hunks) and how is the per-file last-saved baseline persisted between minute runs?
- Where are diffs stored and how are they keyed to exam + student + session, consistent with the (still-undesigned) video store of Thread 4?
- When the monitored file source becomes unavailable, this must raise the §11 alarm (Thread 6) — what signal does file-tracking emit to drive that?
