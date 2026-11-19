---
title: Exam Lifecycle
date: 2026-11-02
---

{{< badge content="v1.0.0" color="green" >}}

An exam and a student's session are two independent state machines.

## Exam

```mermaid
stateDiagram-v2
    [*] --> SCHEDULED
    SCHEDULED --> OPEN: join window opens, 15 min before scheduled start by default
    SCHEDULED --> OPEN: teacher opens the exam early
    OPEN --> ENDED: teacher or admin ends the exam
    OPEN --> ENDED: scheduled end plus grace, automatic and flagged as such
    ENDED --> ARCHIVED: every session terminal
    ARCHIVED --> [*]
```

## Session

One session per student per exam, continuing across reconnects from any machine.

```mermaid
stateDiagram-v2
    [*] --> CONNECTED: student joins with PIN while the exam is OPEN
    CONNECTED --> RECORDING
    RECORDING --> RECORDING: reconnect, contact lost or restored
    RECORDING --> RELEASED: teacher marks the student as done
    RECORDING --> RELEASED: student leaves
    RECORDING --> RELEASED: exam ended
    RELEASED --> UPLOADING
    UPLOADING --> CLOSED: upload drained, sentinel exits 0
    UPLOADING --> ABANDONED: server gives up on the upload
    CLOSED --> [*]
    ABANDONED --> [*]
```

During `UPLOADING` sentinel stays alive and shows progress. The criteria for `ABANDONED` are
decided by the server.

A teacher can release a student while the exam is `OPEN`. A student
who leaves before being marked as released will trigger a signal to the teacher.

Joining after the teacher went live is flagged as a late join.

## Signals

Sentinel reports to proctor over one channel, independent of both state machines:

- results of the preflight checks, which are advisory
- student says they are ready
- student left before being marked
- contact lost and restored

A failed check shows up on the teacher's screen and gets fixed in the room.
