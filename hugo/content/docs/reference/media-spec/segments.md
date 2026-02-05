---
title: Segments
---

This document specifies when segments are created, how they are named, and their structure.

## Segment Definition

A **segment** is a single fMP4 media segment containing one or more video frames. Each segment:

- Starts with a keyframe (IDR frame)
- Has a fixed framerate throughout
- Has variable duration
- Is independently decodable (with the initialization segment)

## Segment Creation Triggers

A new segment is created when any of the following occur:

| Trigger | Description |
|---------|-------------|
| **Keyframe generated** | Any keyframe (scheduled or on-demand) starts a new segment |
| **FPS change** | Framerate change request forces a keyframe and new segment |
| **Maximum interval reached** | If no keyframe has occurred in 20-30 seconds, one is forced |

```
Timeline:
├── Segment 1 ──────────┼── Segment 2 ────┼── Segment 3 ──────────────┤
│   [KF]...[F]...[F]    │   [KF]...[F]    │   [KF]...[F]...[F]...[F]  │
│                       │                 │                           │
└─ Scheduled keyframe   └─ On-demand      └─ FPS change triggered
                           keyframe          keyframe
```

*KF = Keyframe, F = Frame*

## Sequence Numbers

Each Sentinel maintains a **sequence counter** for its segments.

| Property | Value |
|----------|-------|
| Start value | 0 |
| Increment | 1 per segment |
| Scope | Per Sentinel, per session |
| Controller | Sentinel (not Server) |

The sequence number is assigned by the Sentinel when the segment is created and included in the segment metadata sent to the Server.

## Naming Convention

Segments are identified by the combination of Sentinel ID and sequence number.

### Format

```
{sentinelId}-{sequence}.m4s
```

| Component | Description | Example |
|-----------|-------------|---------|
| `sentinelId` | Unique identifier for the Sentinel | `sentinel-a1b2c3` |
| `sequence` | Zero-padded sequence number | `000142` |
| Extension | `.m4s` for media segments | |

### Examples

```
sentinel-a1b2c3-000000.m4s   # First segment
sentinel-a1b2c3-000001.m4s   # Second segment
sentinel-a1b2c3-000142.m4s   # 143rd segment
```

### Initialization Segment Naming

The initialization segment uses a distinct name:

```
{sentinelId}-init.mp4
```

Example:
```
sentinel-a1b2c3-init.mp4
```

## Segment Duration

Segment duration is **variable** and depends on when keyframes occur.

| Scenario | Typical Duration |
|----------|------------------|
| Normal operation (no on-demand keyframes) | 20-30 seconds |
| Frequent Proctor joins | Shorter segments due to on-demand keyframes |
| FPS changes | Segment ends immediately, new segment begins |

{{< callout type="warning" >}}
There is no guaranteed minimum or maximum segment duration. Implementations should handle segments of any duration.
{{< /callout >}}

## Segment Contents

Each media segment contains:

| Content | Location | Description |
|---------|----------|-------------|
| Decode timestamp | `moof` → `tfdt` | Absolute timestamp of first frame |
| Frame durations | `moof` → `trun` | Duration of each frame in segment |
| Frame data | `mdat` | Encoded H.264 NAL units |

### Frame Timestamps

Every frame within a segment has a precise timestamp derived from:

1. The segment's base decode time (`tfdt`)
2. The cumulative duration of preceding frames (`trun` sample durations)

This allows accurate playback timing regardless of variable framerate across segments.

## Relationship to Sessions

A **session** is the period from when a Sentinel connects to when it disconnects.

| Session Event | Segment Behavior |
|---------------|------------------|
| Session start | Sequence resets to 0, new initialization segment created |
| Session continues | Sequence increments with each segment |
| Session ends | Final segment may be shorter than normal |

{{< callout type="info" >}}
If a Sentinel reconnects (new session), it generates a new initialization segment and restarts sequence numbering at 0. The Server treats this as a new stream.
{{< /callout >}}
