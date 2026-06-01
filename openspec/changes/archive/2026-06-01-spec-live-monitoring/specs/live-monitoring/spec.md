## ADDED Requirements

### Requirement: Live screen grid of six with pagination

The proctor UI SHALL display up to six student screens simultaneously in a live grid, with pagination to reach further students (§7.1, US-03). The system SHALL subscribe to the live frames of the sentinels on the current page and unsubscribe from those leaving it.

`status: implemented`

#### Scenario: Six tiles shown
- **WHEN** an exam has more than six connected students
- **THEN** the grid shows six live tiles for the current page

#### Scenario: Pagination navigates students
- **WHEN** the proctor advances to the next page
- **THEN** the grid subscribes to the next set of sentinels and renders their frames

#### Scenario: Off-page sentinels unsubscribed
- **WHEN** a sentinel leaves the visible page
- **THEN** the proctor revokes its subscription

### Requirement: Per-student detail view

The proctor SHALL open a detail/zoom view of a single student's screen (§7.1, US-03). Opening the detail view SHALL request the highest quality profile for that student; closing it SHALL return that student to the grid quality profile.

`status: implemented`

#### Scenario: Zoom opens detail
- **WHEN** the proctor selects a student tile
- **THEN** an enlarged view of that student's screen is shown at the high quality profile

#### Scenario: Closing detail restores grid quality
- **WHEN** the proctor closes the detail view
- **THEN** that student's profile returns to the grid (low) quality

### Requirement: View-only monitoring

The system SHALL provide screen viewing only and SHALL NOT offer any remote control of student devices (§7.1, US-03).

`status: implemented`

#### Scenario: No control channel
- **WHEN** a proctor views a student screen
- **THEN** no input, command, or control can be sent to the student device

### Requirement: Primary capture quality and frame rate

The system SHALL capture student screens at a primary quality of 1080p and a default rate of 10 FPS (§7.2).

`status: partial`

#### Scenario: Capture at 1080p
- **WHEN** a student session records
- **THEN** the primary capture resolution is 1080p

#### Scenario: Default frame rate
- **WHEN** no adaptive downscale is applied
- **THEN** the capture rate defaults to 10 FPS

### Requirement: Adaptive live-stream downscaling

The system SHALL allow the live stream quality and frame rate to be adaptively reduced below the primary capture parameters (§7.2). A proctor-selected quality profile SHALL be honoured by the sentinel.

`status: not-implemented`

#### Scenario: Grid tile downscaled
- **WHEN** a student is shown in the six-up grid
- **THEN** the live stream for that student is downscaled in quality and/or frame rate

#### Scenario: Profile change applied at client
- **WHEN** the server sends a resolution/quality profile change to a sentinel
- **THEN** the sentinel re-encodes subsequent frames at the requested profile

### Requirement: Live and alarm latency target

The system SHALL target an end-to-end latency of at most 10 seconds for live view and alarm display (§7.2, §11).

`status: not-implemented`

#### Scenario: Frame latency within target
- **WHEN** a frame is captured on a student device
- **THEN** it is displayed to the proctor within 10 seconds

### Requirement: No audio and no multi-monitor capture

The system SHALL capture only the standard display and SHALL NOT capture audio or additional monitors (§7.3).

`status: implemented`

#### Scenario: No audio captured
- **WHEN** a student session records
- **THEN** no audio is captured

#### Scenario: Single display captured
- **WHEN** a student device has multiple monitors
- **THEN** only the standard display is captured

### Requirement: Student connection status visible

The proctor UI SHALL show each student's connection status as connected or disconnected (§15). A student whose sentinel disconnects SHALL be reflected as disconnected rather than silently removed.

`status: partial`

#### Scenario: Connected student shown
- **WHEN** a student's sentinel is registered and streaming
- **THEN** the proctor sees that student as connected

#### Scenario: Disconnected student reflected
- **WHEN** a student's sentinel disconnects
- **THEN** the proctor sees that student's status change to disconnected
