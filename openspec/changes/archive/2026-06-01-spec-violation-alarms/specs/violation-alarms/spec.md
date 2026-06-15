## ADDED Requirements

### Requirement: Automatic detect-and-report monitoring

The system SHALL start violation monitoring automatically as soon as a student is connected, and SHALL only detect and report — it SHALL NOT block actions or perform remote control (§10.1).

`status: not-implemented`

#### Scenario: Monitoring starts on connect
- **WHEN** a student connects to an exam session
- **THEN** violation monitoring begins automatically without blocking the student

### Requirement: GDPR-cleared signal set

The system SHALL base detection only on active window/process names, the active tab's browser URL, continuous OCR on screen images, and device-wide network destination domains, and SHALL NOT capture clipboard content or keystrokes (§10.2).

`status: not-implemented`

#### Scenario: Only allowed signals captured
- **WHEN** the system collects detection signals
- **THEN** it uses only window/process names, active-tab URL, screen OCR, and network destination domains

#### Scenario: Forbidden signals never captured
- **WHEN** detection is active
- **THEN** clipboard content and keystrokes are never captured

### Requirement: Forbidden-AI-service rule

The system SHALL raise an alarm when a student's active process or accessed domain matches the admin-managed forbidden-AI-service list stored in the database (§10.3).

`status: not-implemented`

#### Scenario: Forbidden AI service detected
- **WHEN** an active process or accessed domain matches the forbidden-AI-service list
- **THEN** an AI-suspicion alarm is raised

### Requirement: Mass-paste rule

The system SHALL raise an alarm when at least 10 lines are inserted within at most 1 second (§10.3).

`status: not-implemented`

#### Scenario: Mass paste detected
- **WHEN** 10 or more lines are inserted within 1 second
- **THEN** an exam-rule-violation alarm is raised

### Requirement: Uniform rule set across exams

The system SHALL apply one uniform rule set to all exams, with no per-exam rule configuration in v1 (§10.3).

`status: not-implemented`

#### Scenario: Same rules for every exam
- **WHEN** any exam is monitored
- **THEN** the same rule set applies, with no exam-specific configuration

### Requirement: Alarm pipeline on detection

On a rule hit the system SHALL produce a live teacher popup, an entry in the event list, a database-persisted alarm record, and a timeline marker (§10.4, US-04).

`status: not-implemented`

#### Scenario: Alarm produces all outputs
- **WHEN** a violation is detected
- **THEN** a live popup, an event-list entry, a persisted DB record, and a timeline marker are created

### Requirement: Repeat suppression

The system SHALL emit at most one alarm per minute for a single ongoing violation (§10.4, US-04).

`status: not-implemented`

#### Scenario: Ongoing violation throttled
- **WHEN** a single violation persists across multiple detection cycles
- **THEN** at most one alarm per minute is emitted for it

### Requirement: Mandatory alarm types

The system SHALL support the alarm types connection lost, exam-rule violation, AI suspicion, and monitored file access / file source unavailable (§11).

`status: not-implemented`

#### Scenario: All mandatory types available
- **WHEN** any of the four conditions occurs
- **THEN** an alarm of the corresponding type is raised

### Requirement: Alarm properties and latency

Alarms SHALL be acknowledgeable, SHALL have no escalation levels, SHALL NOT send email in v1, and SHALL be displayed within 10 seconds of the triggering condition (§11, US-04).

`status: not-implemented`

#### Scenario: Alarm acknowledged within latency target
- **WHEN** an alarm is raised
- **THEN** it appears to the teacher within 10 seconds and can be acknowledged, with no escalation level and no email
