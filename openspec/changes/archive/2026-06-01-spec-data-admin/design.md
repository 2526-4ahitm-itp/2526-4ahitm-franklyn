## Context

Data-admin is the governance layer over the data the other capabilities produce. The FSD (§12, §13, §10.3) wants 30-day retention with cleanup, an immediate hard-delete cascade, role-based access, an encryption stance, and admin management of the forbidden-AI list. It is the last speccing thread. Because the data stores it governs (video, diffs, alarms) are themselves unbuilt (Threads 4–6 all not-implemented), much of this capability cannot be fully realised until those exist; the cascade and retention have few targets today. This design records the target governance architecture and its strong dependencies on the other threads.

Verified current state:
- `ExamDao.delete` = `delete from fr_exam where id = :id and teacher_id = :teacherId` — removes only the exam row, scoped to the owning teacher. No cascade.
- No retention/30-day/scheduled-cleanup code in `server/src/main/java` (the only `@Scheduled`-style "Cleanup" is WebSocket connection cleanup in `FranklynWebSocketServer`, unrelated to data retention).
- No forbidden-AI / blocklist table or admin CRUD anywhere.
- Tables present: `fr_user/teacher/student/exam/notice` only — no video/diff/alarm/backup tables for a cascade to target.
- Admin role exists (auth-identity Thread 1: ADMIN role + OU=Admins). `examId` read query is not teacher-scoped (known cross-cutting finding); `ExamDao.delete` is teacher-scoped.

## Goals / Non-Goals

**Goals:**
- Capture data-admin requirements at FSD target state with accurate status (partial for exam-row delete and access scoping; not-implemented for retention, cascade completeness, and admin blocklist; stance-only for encryption/audit).
- Make explicit that hard-delete and retention depend on the data stores defined in Threads 2 and 4–6.

**Non-Goals:**
- Implementing the retention scheduler, cascade, or admin CRUD (spec thread).
- Defining the video/diff/alarm stores themselves (Threads 4–6) — this spec states they are deleted/retained, not how they are stored.
- Building TLS/encryption (deployment) or any audit facility (out of scope for v1, §13.4).

## Decisions

- **Uniform 30-day retention from exam end, all data types (§12.1).** One retention window applies to video, diffs, events/alarms, and metadata alike — no per-type policy. Recorded as the target; no scheduler exists.
- **Hard-delete is immediate and total (§12.2, US-07).** Manual "delete exam" must synchronously remove video, diffs, events/alarms, metadata, and backups — not a soft-delete or deferred job. The current teacher-scoped row delete is the entry point but is incomplete until cascade targets exist.
- **At-rest encryption is a deliberately accepted non-goal (§13.3).** TLS protects data in transit; server-at-rest data is intentionally unencrypted as an accepted risk. The spec records this as a decision so it is not later mistaken for a gap.
- **No formal audit in v1 (§13.4).** Stated as an explicit non-requirement.
- **Forbidden-AI list is admin-managed and DB-backed (§10.3).** Ownership of the list (CRUD, admin-gated) lives here; consumption (rule evaluation) lives in violation-alarms (Thread 6).
- **Access scope: teacher own exams, admin full (§13.2).** Builds on the auth-identity Admin role (Thread 1). Teacher scoping must be enforced uniformly — the non-teacher-scoped `examId` read is a known gap to close.

## Risks / Trade-offs

- [Cascade has no targets yet] → Until Threads 4–6 define video/diff/alarm stores, the hard-delete cascade and retention cleanup cannot be fully built; designing them now without those schemas risks rework. The schemas in Threads 4–6 must be designed with this delete/retention contract in mind.
- [Backups in scope of hard-delete (§12.2)] → "Backups" must also be purged on delete; if backups live outside the primary DB (filesystem/object store), the cascade must reach them, which constrains the backup design.
- [Non-teacher-scoped `examId` read] → A teacher can currently read any exam by id; admin-full / teacher-own access (§13.2) is only partially enforced and is a real authorization gap.
- [At-rest unencrypted is accepted but sensitive] → Exam recordings and diffs are personal data under GDPR (§13.1); the accepted-risk stance is an organisational decision recorded here, not a technical safeguard.

## Open Questions

- What triggers retention cleanup — a scheduled job keyed off exam end + 30 days — and how does it enumerate all data types for an exam?
- Where do "backups" live, and how does the hard-delete cascade reach them (§12.2)?
- Is admin full access (§13.2) read-only oversight or full CRUD including delete-any-exam (vs the current teacher-scoped delete)?
- What is the forbidden-AI list schema (domains vs processes) and the admin CRUD surface, and how is it gated to the Admin role (Thread 1)?
- Should retention deletion reuse the same cascade as manual hard-delete, or a separate path?
