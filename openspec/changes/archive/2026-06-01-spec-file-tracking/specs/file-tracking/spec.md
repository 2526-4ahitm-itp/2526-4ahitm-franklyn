## ADDED Requirements

### Requirement: Text-file-only monitoring scope

The system SHALL monitor only text files for change tracking and SHALL NOT process binary files (§9.1, §9.3).

`status: not-implemented`

#### Scenario: Binary file ignored
- **WHEN** a monitored source includes a binary file
- **THEN** the system does not produce a diff for it

#### Scenario: Text file in scope
- **WHEN** an observed file is a text file
- **THEN** it is eligible for diff capture

### Requirement: Best-effort file-source detection

The system SHALL determine the set of observed files best-effort from the active-window application and the most recently saved file (§9.1).

`status: not-implemented`

#### Scenario: Active file observed
- **WHEN** a student edits and saves a text file in the active-window application
- **THEN** that file is included in the observed set

### Requirement: Forced one-minute incremental diff run

The system SHALL produce a diff run every minute that considers all currently observed files, forced regardless of whether a save occurred, with each diff incremental against that file's last saved state (§9.1, §9.2).

`status: not-implemented`

#### Scenario: Diff forced each minute
- **WHEN** one minute elapses during an active session
- **THEN** a diff run executes over all observed files, producing incremental diffs against each file's last saved state

### Requirement: Diff-only storage model

The system SHALL store only diffs and SHALL NOT store a full file snapshot as the primary storage model (§9.2).

`status: not-implemented`

#### Scenario: Only diffs persisted
- **WHEN** a diff run completes
- **THEN** only the incremental diffs are persisted, not full file snapshots

### Requirement: Diffs bound to student session

The system SHALL associate every captured diff with the correct student exam session (US-05, §9.2).

`status: not-implemented`

#### Scenario: Diff attributed to session
- **WHEN** a diff is captured for a student
- **THEN** it is stored bound to that student's exam session

### Requirement: Deleted-file reconstruction excluded

The system SHALL NOT reconstruct deleted files (§9.3).

`status: not-implemented`

#### Scenario: Deletion not reconstructed
- **WHEN** a monitored file is deleted
- **THEN** the system does not attempt to reconstruct its contents
