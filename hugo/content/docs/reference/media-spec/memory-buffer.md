---
title: Memory Buffer
---

This document specifies how the Server buffers segments in memory for live streaming.

## Purpose

The memory buffer serves two purposes:

1. **Fast Proctor joins**: Proctors can immediately receive recent segments without disk I/O
2. **Network resilience**: Proctors with slower connections can catch up from buffered segments

## Buffer Requirements

| Parameter | Value | Notes |
|-----------|-------|-------|
| Buffer window | 15-20 seconds | Configurable |
| Contents | All segments with start time within the window | |
| Scope | Per Sentinel | Each Sentinel has its own buffer |
| Storage | Memory only | No disk I/O for live streaming |

## What is Buffered

For each active Sentinel, the Server maintains in memory:

| Item | Description |
|------|-------------|
| **Initialization segment** | The codec/resolution configuration for the session |
| **Recent media segments** | All segments whose start timestamp falls within the buffer window |
| **Segment metadata** | See [Metadata](../metadata) for details |

```
Buffer Window (15-20 seconds)
◄──────────────────────────────────────────────►

┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌───
│ Seg N-3│ │ Seg N-2│ │ Seg N-1│ │ Seg N  │ │ ...
└────────┘ └────────┘ └────────┘ └────────┘ └───
     │          │          │          │
     └──────────┴──────────┴──────────┴── All in memory

                                         ▲
                                         │
                                    Most recent
```

## Eviction

Segments are evicted from the buffer when they fall outside the buffer window.

| Behavior | Description |
|----------|-------------|
| Trigger | Segment's start timestamp is older than `now - buffer_window` |
| Action | Remove from memory buffer |
| Disk impact | None (segment was already written to disk when received) |
| Method | Garbage collection or explicit removal (implementation choice) |

{{< callout type="info" >}}
The spec does not mandate a specific eviction strategy. Implementations may use lazy garbage collection, periodic cleanup, or immediate removal. The only requirement is that segments older than the buffer window are not required to remain in memory.
{{< /callout >}}

## Join Points

Every segment in the buffer is a valid **join point** because every segment starts with a keyframe.

When a Proctor joins a stream:

1. Server sends the initialization segment
2. Server selects a segment from the buffer (typically the oldest to maximize catch-up time, or newest for lowest latency)
3. Server sends that segment and all subsequent segments

### Buffer Depth and Network Quality

The buffer window (15-20 seconds) accommodates Proctors with varying network conditions:

| Network Quality | Behavior |
|-----------------|----------|
| Good | Proctor plays near-realtime, buffer provides redundancy |
| Moderate | Proctor buffers a few seconds, catches up during low-activity periods |
| Poor | Proctor buffers more aggressively, may be 10-15 seconds behind live |

If a Proctor falls further behind than the buffer window, they must either:
- Skip forward to live (losing some video)
- Request historical segments via HTTP (see [Transport](../transport))

## Initialization Segment Caching

The initialization segment for each active Sentinel is cached separately from the media segment buffer.

| Property | Value |
|----------|-------|
| Lifetime | Entire session |
| Eviction | When Sentinel disconnects |
| Access | Served on every Proctor join request |

Since the initialization segment is small (typically a few KB) and required for every new Proctor, it remains in memory for the duration of the Sentinel's session.

## Memory Considerations

The memory footprint per Sentinel depends on:

- **Buffer window duration**: Longer window = more segments
- **Framerate**: Higher FPS = more data per second
- **Resolution**: Higher resolution = larger frames
- **Keyframe frequency**: More keyframes = more segments (each starting with a keyframe)

### Rough Estimates

At 1080p, 5 FPS, with H.264 compression:

| Buffer Window | Approximate Memory per Sentinel |
|---------------|--------------------------------|
| 15 seconds | 2-5 MB |
| 20 seconds | 3-7 MB |

These are rough estimates. Actual usage depends on screen content complexity and encoder settings.
