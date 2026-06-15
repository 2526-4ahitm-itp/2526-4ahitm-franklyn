## ADDED Requirements

### Requirement: Exam creation with mandatory fields

A Lehrer SHALL create an exam by providing the mandatory fields title, class, room, start time, and end time (§4.2, US-01). The end time MUST NOT be before the start time. The created exam SHALL appear in the creating teacher's dashboard.

`status: partial`

#### Scenario: Exam created with all mandatory fields
- **WHEN** a Lehrer submits title, class, room, start time, and end time with end after start
- **THEN** the exam is persisted and returned, and appears in the teacher's exam list

#### Scenario: End before start rejected
- **WHEN** a Lehrer submits an exam whose end time is before its start time
- **THEN** the request is rejected with a `StartCannotBeBeforeEnd` error

#### Scenario: Missing class or room rejected
- **WHEN** a Lehrer submits an exam without a class or without a room
- **THEN** the request is rejected with a validation error

### Requirement: Unique PIN issuance

The system SHALL generate a PIN for each exam that is unique across all exams and within the configured `[pin.min, pin.max]` range (§4.2, US-01). PIN generation MUST retry until a globally unused value is found.

`status: partial`

#### Scenario: Unique PIN assigned on creation
- **WHEN** an exam is created
- **THEN** it receives a PIN within the configured range that no other exam currently holds

#### Scenario: Collision retried
- **WHEN** a generated PIN already belongs to another exam
- **THEN** the system generates a new PIN until a globally unused value is found

### Requirement: PIN valid only within exam time window

The system SHALL accept an exam PIN for student registration only while the current time is within the exam window `[startTime, endTime]` (§4.2, US-02). Registration with a PIN outside its exam window SHALL be rejected.

`status: not-implemented`

#### Scenario: PIN accepted inside window
- **WHEN** a student registers with a valid PIN and the current time is within `[startTime, endTime]`
- **THEN** registration proceeds

#### Scenario: PIN rejected before window
- **WHEN** a student registers with a valid PIN before the exam start time
- **THEN** registration is rejected with a registration-reject reason

#### Scenario: PIN rejected after window
- **WHEN** a student registers with a valid PIN after the exam end time
- **THEN** registration is rejected with a registration-reject reason

### Requirement: Student join via Keycloak and PIN with class assignment

A Schüler SHALL join an exam by authenticating via Keycloak and supplying the exam PIN; the system SHALL assign the student to the exam automatically using their Keycloak class (§5.1, US-02). The student's class (from `distinguishedName`, see auth-identity) SHALL match the exam's class.

`status: partial`

#### Scenario: Authenticated student joins matching exam
- **WHEN** an authenticated Schüler registers with a PIN whose exam class matches the student's Keycloak class
- **THEN** the student is registered to that exam

#### Scenario: Unauthenticated join rejected
- **WHEN** a registration omits or carries an invalid auth token
- **THEN** registration is rejected

### Requirement: Single global active session per student

The system SHALL allow each Schüler at most one active session globally, not merely one per exam (§4.3). A second concurrent registration for the same Keycloak subject SHALL be prevented.

`status: not-implemented`

#### Scenario: First session accepted
- **WHEN** a student with no active session registers
- **THEN** the session is accepted and acknowledged

#### Scenario: Concurrent second session rejected
- **WHEN** a student who already has an active session registers a second time
- **THEN** the second registration is rejected and the first session remains active

### Requirement: Recording starts only within the recording window

The system SHALL start monitoring and recording for a student only when the login time falls within `[startTime − 60 minutes, endTime]` (§6.1). A login earlier than 60 minutes before start SHALL NOT begin recording.

`status: not-implemented`

#### Scenario: Login within window starts recording
- **WHEN** a student logs in at a time within `[startTime − 60 minutes, endTime]`
- **THEN** monitoring and recording begin

#### Scenario: Login too early does not record
- **WHEN** a student logs in more than 60 minutes before the exam start time
- **THEN** no recording is started

### Requirement: Recording ends on manual student logout

The system SHALL continue recording until the student manually logs out; reaching the exam end time alone SHALL NOT stop an active recording (§6.2).

`status: partial`

#### Scenario: Recording continues past end time
- **WHEN** the exam end time passes while a student session is still active
- **THEN** recording continues

#### Scenario: Manual logout stops recording
- **WHEN** the student manually logs out
- **THEN** recording stops for that session

### Requirement: Exam start and end transitions

A Lehrer SHALL start and end their own exam via explicit transitions that stamp `startedAt` and `endedAt` (§6). Starting an already-started exam, or ending an exam that has not started or has already ended, SHALL be rejected.

`status: implemented`

#### Scenario: Start stamps startedAt
- **WHEN** a Lehrer starts their own exam that has not yet started
- **THEN** `startedAt` is set to the current time

#### Scenario: Double start rejected
- **WHEN** a Lehrer starts an exam that already has a `startedAt`
- **THEN** the request is rejected with an `ExamAlreadyStarted` error

#### Scenario: End before start rejected
- **WHEN** a Lehrer ends an exam that has no `startedAt`
- **THEN** the request is rejected with an `ExamNotStartedYet` error

### Requirement: Exam deletion hard-deletes all associated data

A Lehrer SHALL delete their own exam, and deletion SHALL immediately and permanently remove all associated data — video, diffs, events/alarms, metadata, and backups (§12.2, US-07). A deleted exam SHALL no longer be visible or retrievable.

`status: partial`

#### Scenario: Teacher deletes own exam
- **WHEN** a Lehrer deletes an exam they created
- **THEN** the exam row and all associated data are removed and the exam is no longer listed

#### Scenario: Deleting another teacher's exam has no effect
- **WHEN** a Lehrer attempts to delete an exam they did not create
- **THEN** no data is removed
