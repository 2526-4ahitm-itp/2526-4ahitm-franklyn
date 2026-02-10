---
title: Fragments
---

This document specifies how **fragments** are created, how they are named, and how **join fragments** (keyframe entry points) work.

See [Terminology](../terminology) for definitions.

## Fragment Definition

A **fragment** is a single fMP4 media unit (`moof` + `mdat`) containing one or more encoded samples. Fragments are the unit of live delivery and MSE appends.

Fragments:

- Are produced continuously during streaming
- Are appended to MSE in order

{{< callout type="warning" >}}
Keyframes control **join/switch latency**, not live latency.

Live latency is determined by how often fragments are finalized and pushed.
{{< /callout >}}

## Join Fragments

A **join fragment** is a fragment whose first sample is an IDR keyframe. Join fragments are random access points for Proctors.

## Join Fragment Triggers

A new join fragment is produced when any of the following occur:

| Trigger | Description |
|---------|-------------|
 | **On-demand keyframe** | Server initiates; next capture becomes IDR |
 | **FPS change** | Server requests new FPS; next capture becomes IDR |
 | **Maximum interval reached** | If no keyframe has occurred in 20-30 seconds, one is forced |

```
Timeline (conceptual):
Fragments are produced continuously, while join fragments occur on keyframes.

├─ fragment ─ fragment ─ join fragment ─ fragment ─ ... ─ join fragment ─ fragment ─┤
                  [IDR]                            [IDR]
```

*IDR = keyframe*

## Sequence Numbers

Each Sentinel maintains a **sequence counter** for its fragments.

| Property | Value |
|----------|-------|
| Start value | 0 |
 | Increment | 1 per fragment |
| Scope | Per Sentinel, per session |
| Controller | Sentinel (not Server) |

The sequence number is assigned by the Sentinel when the fragment is created and included in the metadata sent to the Server.

## Naming Convention

Fragments are identified by the combination of Sentinel ID and sequence number.

### Format

```
{sentinelId}-{sequence}.m4s
```

| Component | Description | Example |
|-----------|-------------|---------|
| `sentinelId` | Unique identifier for the Sentinel | `sentinel-a1b2c3` |
| `sequence` | Zero-padded sequence number | `000142` |
| Extension | `.m4s` for fMP4 media fragments | |

### Examples

```
sentinel-a1b2c3-000000.m4s   # First fragment
sentinel-a1b2c3-000001.m4s   # Second fragment
sentinel-a1b2c3-000142.m4s   # 143rd fragment
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

## Fragment Duration

Fragment duration is **variable** and chosen by the Sentinel implementation to balance latency and overhead.

The spec intentionally does not mandate an exact fragment duration, but fragments MUST be produced frequently enough to satisfy the real-time requirement.

| Scenario | Typical Duration |
|----------|------------------|
| Typical real-time operation | ~0.25s to ~2s (implementation choice) |
| Very low FPS mode (0.2 fps) | One fragment per capture (up to 5s) |
| Joins / FPS changes | A join fragment is produced on the next capture |

{{< callout type="warning" >}}
Do not design around the assumption that fragments are 20-30 seconds long.

20-30 seconds is the **maximum keyframe interval** (join fragment spacing), not the fragment duration.
{{< /callout >}}

## Fragment Contents

Each media fragment contains:

| Content | Location | Description |
|---------|----------|-------------|
| Decode timestamp | `moof` → `tfdt` | Absolute timestamp of first frame |
| Frame durations | `moof` → `trun` | Duration of each frame in fragment |
| Frame data | `mdat` | Encoded H.264 NAL units |

### Frame Timestamps

Every sample within a fragment has a precise timestamp derived from:

1. The fragment's base decode time (`tfdt`)
2. The cumulative duration of preceding samples (`trun` sample durations)

This allows accurate playback timing regardless of FPS changes over time.

## Relationship to Sessions

A **session** is the period from when a Sentinel connects to when it disconnects.

| Session Event | Fragment Behavior |
|---------------|------------------|
| Session start | Sequence resets to 0, new initialization segment created |
| Session continues | Sequence increments with each fragment |
| Session ends | Final fragment may be shorter than normal |

{{< callout type="info" >}}
If a Sentinel reconnects (new session), it generates a new initialization segment and restarts sequence numbering at 0. The Server treats this as a new stream.
{{< /callout >}}
