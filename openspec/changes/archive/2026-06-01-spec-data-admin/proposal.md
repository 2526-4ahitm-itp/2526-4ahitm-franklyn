## Why

The FSD defines data governance and admin duties spanning retention, deletion, export, data access, encryption, and admin-managed rules: a uniform 30-day retention from exam end for all data types (§12.1), a manual "delete exam" that immediately hard-deletes all related data — video, diffs, events/alarms, metadata, backups (§12.2, US-07), no mandatory export format in v1 but raw video available (§12.3), role-based data access (teacher = own exams, admin = full access, §13.2), TLS in transit with deliberately unencrypted at-rest storage as an accepted risk (§13.3), no formal audit obligation in v1 (§13.4), and admin management of the forbidden-AI-service list (§10.3). Today only a fragment exists: `ExamDao.delete` removes the `fr_exam` row scoped to the owning teacher, but there is no retention scheduler, no delete cascade (the video/diff/alarm/backup tables it would cascade into do not exist), and no admin management of the forbidden-AI list. This change captures the data-admin capability as a spec so the gaps are documented and tracked.

## What Changes

- Introduce the `data-admin` capability spec covering 30-day retention with scheduled cleanup (§12.1), immediate hard-delete cascade on exam deletion (§12.2, US-07), the v1 export stance — no mandatory export, raw video available (§12.3), role-based data access (teacher own / admin full, §13.2), the encryption stance — TLS in transit, at-rest unencrypted by accepted risk (§13.3), the v1 no-audit stance (§13.4), and admin management of the forbidden-AI-service list (§10.3).
- Document current status: exam-row delete is **partial** (teacher-scoped row delete exists, cascade targets do not); retention, scheduled cleanup, and admin blocklist management are **not implemented**; the encryption/audit items are stated stances rather than build work.
- Record implementation status per requirement; the unbuilt FSD requirements become `[GAP]` tasks.

## Capabilities

### New Capabilities
- `data-admin`: 30-day retention from exam end for all data types with scheduled cleanup (§12.1), immediate hard-delete cascade of all exam-related data on manual deletion (§12.2, US-07), the v1 export stance (§12.3), role-based data access — teacher own exams, admin full access (§13.2), the encryption stance — TLS in transit, at-rest unencrypted accepted (§13.3), the v1 no-formal-audit stance (§13.4), and admin management of the forbidden-AI-service list (§10.3).

### Modified Capabilities
<!-- None as durable spec edits. Hard-delete and retention act on data owned by other capabilities (recording-playback video Thread 4, file-tracking diffs Thread 5, violation-alarms records Thread 6, exam metadata exam-lifecycle Thread 2); the forbidden-AI list is consumed by violation-alarms (Thread 6, §10.3); role gating builds on auth-identity (Thread 1, Admin role). This change states the governance requirements; the data it governs is defined in those capabilities. -->

## Impact

- **Backend (Java/Quarkus)**: a retention scheduler (`@Scheduled` cleanup at exam-end + 30 days), a hard-delete cascade that removes all exam-related rows/files, and an admin CRUD surface for the forbidden-AI list. Today `ExamDao.delete` removes only the `fr_exam` row (teacher-scoped); the cascade targets (video/diff/alarm/backup stores) do not exist yet, and there is no retention or blocklist code.
- **Access control**: teacher-own-exam scoping is partial — `ExamDao.delete` is teacher-scoped, but the `examId` read query is not (known cross-cutting finding); admin full access (§13.2) builds on the Admin role from auth-identity (Thread 1) and needs enforcement.
- **Deployment/security**: TLS in transit is a deployment concern; at-rest encryption is a deliberately accepted non-goal (§13.3); no formal audit in v1 (§13.4).
- **Cross-references**: the data hard-deleted/retained is video (`spec-recording-playback`, Thread 4), diffs (`spec-file-tracking`, Thread 5), alarms (`spec-violation-alarms`, Thread 6), and exam metadata (`exam-lifecycle`, Thread 2, which owns the exam delete entry point); the forbidden-AI list is consumed by `spec-violation-alarms` (Thread 6, §10.3); role gating builds on `auth-identity` (Thread 1).
