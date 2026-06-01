# data-admin

## Purpose

Govern exam data lifecycle and admin duties: uniform 30-day retention, immediate hard-delete cascade, role-based access (teacher own / admin full), the v1 export/encryption/audit stances, and admin management of the forbidden-AI-service list (FSD §12, §13, §10.3, US-07).

## Requirements

### Requirement: Uniform 30-day retention

The system SHALL retain all exam data types for 30 days from exam end, applying one uniform retention window, and SHALL remove the data when the window elapses (§12.1).

`status: not-implemented`

#### Scenario: Data removed after retention window
- **WHEN** 30 days have elapsed since an exam ended
- **THEN** all of that exam's data (video, diffs, events/alarms, metadata) is removed

### Requirement: Immediate hard-delete cascade

A teacher SHALL be able to delete an own exam, and the deletion SHALL immediately and totally hard-delete all related data — video, diffs, events/alarms, metadata, and backups (§12.2, US-07).

`status: partial`

#### Scenario: Exam deletion purges all related data
- **WHEN** a teacher deletes an own exam
- **THEN** the exam's video, diffs, events/alarms, metadata, and backups are immediately hard-deleted

#### Scenario: Exam row deletion is teacher-scoped
- **WHEN** a teacher requests deletion of an exam they do not own
- **THEN** no exam data is deleted

### Requirement: v1 export stance

The system SHALL NOT be required to provide a reporting export format in v1, and SHALL make the raw video material available (§12.3).

`status: partial`

#### Scenario: Raw video available, no mandatory export format
- **WHEN** exam data is accessed in v1
- **THEN** raw video is available and no specific reporting export format is required

### Requirement: Role-based data access

The system SHALL restrict teachers to their own exams' data and SHALL grant admins full access to all data (§13.2).

`status: partial`

#### Scenario: Teacher limited to own exams
- **WHEN** a teacher accesses exam data
- **THEN** only their own exams' data is accessible

#### Scenario: Admin has full access
- **WHEN** an admin accesses exam data
- **THEN** all exams' data is accessible

### Requirement: Encryption stance

The system SHALL encrypt data in transit using TLS, and at-rest server data SHALL be intentionally unencrypted as an accepted risk (§13.3).

`status: partial`

#### Scenario: In-transit encryption
- **WHEN** data is transmitted between components
- **THEN** it is protected by TLS

#### Scenario: At-rest unencrypted by decision
- **WHEN** data is stored at rest on the server
- **THEN** it is intentionally unencrypted as an accepted risk

### Requirement: No formal audit in v1

The system SHALL NOT be required to provide a formal audit or revision facility in v1 (§13.4).

`status: not-implemented`

#### Scenario: No audit obligation
- **WHEN** v1 operates
- **THEN** no formal audit/revision facility is required

### Requirement: Admin-managed forbidden-AI list

An admin SHALL manage the forbidden-AI-service list (domains and processes) stored in the database (§10.3).

`status: not-implemented`

#### Scenario: Admin edits the list
- **WHEN** an admin adds or removes a domain or process on the forbidden-AI-service list
- **THEN** the change is persisted and applies uniformly to all exams
