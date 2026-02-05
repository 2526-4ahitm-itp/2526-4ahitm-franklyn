---
title: Join Flow
---

This document specifies how a Proctor joins a Sentinel's video stream.

## Overview

When a Proctor wants to view a Sentinel's screen, it must:

1. Request to join the stream
2. Receive the initialization segment
3. Receive a keyframe segment (join point)
4. Continue receiving live segments

## Join Flow Diagram

```plantuml
@startuml
skinparam sequenceMessageAlign center

participant "Proctor" as P
participant "Server" as Srv
participant "Sentinel" as S

== Join Request ==

P -> Srv : request join stream\n(sentinelId)
activate Srv

Srv -> Srv : validate request
Srv -> Srv : lookup Sentinel\nin memory buffer

== Initial Data ==

Srv -> P : init segment

Srv -> P : keyframe segment\n(oldest in buffer or latest)

== Live Streaming ==

loop as segments arrive
  S -> Srv : new segment
  Srv -> P : new segment
end

deactivate Srv

@enduml
```

## Step-by-Step

{{% steps %}}

### Proctor Sends Join Request

The Proctor sends a message over WebSocket requesting to join a specific Sentinel's stream.

**Required fields:**

| Field | Type | Description |
|-------|------|-------------|
| `sentinelId` | string | The Sentinel to subscribe to |

**Optional fields:**

| Field | Type | Description |
|-------|------|-------------|
| `startFrom` | string | `"oldest"` (default) or `"latest"` |

### Server Validates and Looks Up

The Server:
- Validates the Proctor is authorized to view the Sentinel
- Checks if the Sentinel is currently streaming
- Locates the session data in memory

If the Sentinel is not streaming, the Server responds with an error.

### Server Sends Initialization Segment

The Server sends the cached initialization segment for the Sentinel's current session.

**Required fields:**

| Field | Type | Description |
|-------|------|-------------|
| `sentinelId` | string | Identifies the stream |
| `sessionId` | string | Current session identifier |
| `data` | bytes | Raw fMP4 init segment |

### Server Sends Keyframe Segment

The Server selects a segment from the memory buffer and sends it.

**Selection strategy:**

| `startFrom` | Segment Selected |
|-------------|------------------|
| `"oldest"` | Oldest segment in buffer (maximum catch-up time) |
| `"latest"` | Most recent segment (lowest latency) |

The selected segment is guaranteed to start with a keyframe (all segments do).

**Required fields:**

| Field | Type | Description |
|-------|------|-------------|
| `sentinelId` | string | Identifies the stream |
| `sequence` | integer | Segment sequence number |
| `data` | bytes | Raw fMP4 media segment |

### Server Continues Pushing Segments

From this point, the Server pushes new segments to the Proctor as they arrive from the Sentinel.

{{% /steps %}}

## On-Demand Keyframe for Fast Join

If the Proctor wants to minimize join latency (not wait for the next segment), it can request an on-demand keyframe before or during the join.

See [Control Messages](../control-messages) for the keyframe request flow.

With on-demand keyframes:

```plantuml
@startuml
skinparam sequenceMessageAlign center

participant "Proctor" as P
participant "Server" as Srv
participant "Sentinel" as S

== Pre-Join Keyframe Request ==

P -> Srv : request keyframe\n(sentinelId)
Srv -> S : request keyframe

S -> S : generate keyframe\non next capture

S -> Srv : new segment\n(starts with keyframe)

== Join Request ==

P -> Srv : request join stream\n(sentinelId)

Srv -> P : init segment
Srv -> P : keyframe segment\n(the just-created one)

== Live Streaming ==

loop as segments arrive
  S -> Srv : new segment
  Srv -> P : new segment
end

@enduml
```

## Predictive Pre-Fetching

Proctors may predict which Sentinel they will view next (e.g., based on UI layout or user behavior) and pre-fetch:

1. Request a keyframe for the predicted Sentinel
2. When ready to switch, join is near-instant

This is optional behavior implemented in the Proctor application.

## Switching Streams

When a Proctor switches from one Sentinel to another:

{{% steps %}}

### Unsubscribe from Current Stream

Proctor notifies Server to stop sending segments for the current Sentinel.

### Join New Stream

Follow the standard join flow for the new Sentinel.

### Reset MSE Buffer

In the browser, the Proctor must:
- Clear the existing `SourceBuffer`
- Append the new initialization segment
- Begin appending segments from the new stream

{{% /steps %}}

## Error Handling

| Condition | Server Response |
|-----------|-----------------|
| Sentinel not found | Error: unknown Sentinel |
| Sentinel not streaming | Error: Sentinel offline |
| Authorization failure | Error: not authorized |
| No segments in buffer | Send init segment, wait for first segment |

## Latency Considerations

| Factor | Impact on Join Latency |
|--------|------------------------|
| Buffer has segments | Immediate join (send from buffer) |
| On-demand keyframe requested | Wait for next capture cycle |
| No keyframe, must wait | Up to max keyframe interval (20-30s) |

For lowest latency joins:
1. Use on-demand keyframe requests
2. Use `startFrom: "latest"` 
3. Pre-fetch keyframes for likely next streams
