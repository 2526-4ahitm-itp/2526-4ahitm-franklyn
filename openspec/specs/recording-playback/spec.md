## Purpose

Recording and playback of student exams for franklyn: encoding each session as MP4/H.265 video without audio, persisting it for later retrieval, and replaying it with play/pause, frame-by-frame, jump-to-alarm, and a timeline that synchronises screen events, file diffs, and alarm markers (FSD §8, US-06, §17).

## Requirements

### Requirement: Video recording in MP4 / H.265 without audio

The system SHALL record each student's exam screen as a video file in MP4 container with H.265 codec and no audio track (§8.1).

`status: not-implemented`

#### Scenario: Recording produced in required format
- **WHEN** a student session is recorded
- **THEN** the output is an MP4 file encoded with H.265 and containing no audio track

### Requirement: Per-student video persistence and retrieval

The system SHALL persist each student's exam recording and make the raw video available for later retrieval by an authorised teacher or admin (§8, US-06, §17, §12.3).

`status: not-implemented`

#### Scenario: Recording stored and retrievable
- **WHEN** a recorded student session ends
- **THEN** its video is persisted and can be retrieved for playback by an authorised teacher or admin

### Requirement: Playback transport controls

An authorised teacher or admin SHALL replay a recorded exam with play, pause, and frame-by-frame stepping (§8.2, US-06).

`status: not-implemented`

#### Scenario: Play and pause
- **WHEN** the user plays then pauses a recording
- **THEN** playback starts and halts at the current frame

#### Scenario: Frame-by-frame stepping
- **WHEN** the user steps forward or backward by one frame
- **THEN** playback advances or rewinds exactly one frame

### Requirement: Jump to alarm markers

During playback the user SHALL jump directly to alarm or event markers on the recording (§8.2, US-06).

`status: not-implemented`

#### Scenario: Jump to an alarm
- **WHEN** the user selects an alarm marker
- **THEN** playback seeks to the recording position of that alarm

### Requirement: Synchronised playback timeline

The playback timeline SHALL display screen events, file diff events, and alarm markers synchronised to the video position (§8.3, US-06).

`status: not-implemented`

#### Scenario: Timeline shows synchronised events
- **WHEN** a recording is replayed
- **THEN** the timeline shows screen events, file diffs, and alarm markers aligned to the current video time

#### Scenario: Selecting a timeline event seeks the video
- **WHEN** the user selects a file diff or alarm event on the timeline
- **THEN** the video seeks to that event's position
