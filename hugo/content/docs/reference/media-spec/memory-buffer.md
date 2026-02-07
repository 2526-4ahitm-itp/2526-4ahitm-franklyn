---
title: Memory Buffer
---

This document specifies how the Server buffers **fragments** in memory for live streaming.

See [Terminology](../terminology) for definitions.

## Purpose

The memory buffer serves two purposes:

1. **Fast Proctor joins**: Proctors can immediately receive recent fragments without disk I/O
2. **Network resilience**: Proctors with slower connections can catch up from buffered fragments

## Buffer Requirements

| Parameter | Value | Notes |
|-----------|-------|-------|
| Buffer window | 15-20 seconds | Configurable |
| Contents | All fragments with start time within the window | |
| Scope | Per Sentinel | Each Sentinel has its own buffer |
| Storage | Memory only | No disk I/O for live streaming |

## What is Buffered

For each active Sentinel, the Server maintains in memory:

| Item | Description |
|------|-------------|
| **Initialization segment** | The codec/resolution configuration for the session |
| **Recent fragments** | All fragments whose start timestamp falls within the buffer window |
| **Fragment metadata** | See [Metadata](../metadata) for details |
| **Join fragment index** | Fast lookup of the most recent join fragment(s) in the buffer |

```
Buffer Window (15-20 seconds)
◄──────────────────────────────────────────────►

┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌───
│ Frag N-3│ │ Frag N-2│ │ Frag N-1│ │ Frag N  │ │ ...
└────────┘ └────────┘ └────────┘ └────────┘ └───
     │          │          │          │
     └──────────┴──────────┴──────────┴── All in memory

                                         ▲
                                         │
                                    Most recent
```

## Eviction

Fragments are evicted from the buffer when they fall outside the buffer window.

| Behavior | Description |
|----------|-------------|
 | Trigger | Fragment's start timestamp is older than `now - buffer_window` |
 | Action | Remove from memory buffer |
 | Disk impact | None (fragment was already written to disk when received) |
 | Method | Garbage collection or explicit removal (implementation choice) |

{{< callout type="info" >}}
 The spec does not mandate a specific eviction strategy. Implementations may use lazy garbage collection, periodic cleanup, or immediate removal. The only requirement is that fragments older than the buffer window are not required to remain in memory.
{{< /callout >}}

## Join Points

Not every fragment is a safe join point.

- A **join fragment** starts with an IDR keyframe.
- A Proctor SHOULD begin playback from a join fragment.

When a Proctor joins a stream:

1. Server sends the initialization segment
2. Server selects a join fragment from the buffer (typically the most recent for lowest latency)
3. Server sends that join fragment and all subsequent fragments

### Buffer Depth and Network Quality

The buffer window (15-20 seconds) accommodates Proctors with varying network conditions:

| Network Quality | Behavior |
|-----------------|----------|
| Good | Proctor plays near-realtime, buffer provides redundancy |
| Moderate | Proctor buffers a few seconds, catches up during low-activity periods |
| Poor | Proctor buffers more aggressively, may be 10-15 seconds behind live |

If a Proctor falls further behind than the buffer window, they must either:
- Skip forward to live (losing some video)
- Request historical fragments via HTTP (see [Transport](../transport))

## Initialization Segment Caching

The initialization segment for each active Sentinel is cached separately from the media fragment buffer.

| Property | Value |
|----------|-------|
| Lifetime | Entire session |
| Eviction | When Sentinel disconnects |
| Access | Served on every Proctor join request |

Since the initialization segment is small (typically a few KB) and required for every new Proctor, it remains in memory for the duration of the Sentinel's session.

## Memory Considerations

The memory footprint per Sentinel depends on:

 - **Buffer window duration**: Longer window = more fragments
- **Framerate**: Higher FPS = more data per second
- **Resolution**: Higher resolution = larger frames
 - **Keyframe frequency**: More keyframes = more join fragments

### Rough Estimates

At 1080p, 5 FPS, with H.264 compression:

| Buffer Window | Approximate Memory per Sentinel |
|---------------|--------------------------------|
| 15 seconds | 2-5 MB |
| 20 seconds | 3-7 MB |

These are rough estimates. Actual usage depends on screen content complexity and encoder settings.
