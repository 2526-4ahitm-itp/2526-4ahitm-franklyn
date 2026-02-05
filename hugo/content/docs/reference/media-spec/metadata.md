---
title: Metadata
---

This document specifies the metadata associated with video segments, where it is stored, and how it is synchronized.

## Metadata Locations

Metadata exists in two locations:

| Location | Contents | Purpose |
|----------|----------|---------|
| **In-stream** | Timestamps, duration | Required for browser playback |
| **Application** | Sentinel ID, sequence, framerate, file paths | Server/Proctor coordination |

## In-Stream Metadata

This metadata is embedded in the fMP4 container by the Sentinel encoder. The Server does not modify it.

### Initialization Segment

| Field | Location | Description |
|-------|----------|-------------|
| Timescale | `moov` → `mdhd` | Time units per second (e.g., 90000) |
| Resolution | `moov` → `tkhd` | Width and height in pixels |
| Codec info | `moov` → `stsd` | H.264 SPS/PPS |

### Media Segment

| Field | Location | Description |
|-------|----------|-------------|
| Base decode time | `moof` → `tfdt` | Timestamp of first frame in segment |
| Sample durations | `moof` → `trun` | Duration of each frame |
| Sample sizes | `moof` → `trun` | Byte size of each frame |

{{< callout type="info" >}}
The in-stream metadata is sufficient for a browser to decode and display the video at correct timing. The application metadata provides additional context for stream management.
{{< /callout >}}

## Application Metadata

This metadata is managed by the Server and stored in memory, with periodic persistence to the database.

### Per-Session Metadata

| Field | Type | Description |
|-------|------|-------------|
| `sentinelId` | string | Unique identifier for the Sentinel |
| `sessionId` | string | Unique identifier for this session |
| `startTime` | timestamp | When the session started |
| `resolution` | object | Width and height |
| `initSegmentPath` | string | Path to initialization segment on disk |

Example:

```json
{
  "sentinelId": "sentinel-a1b2c3",
  "sessionId": "2026-02-05T14-30-00Z",
  "startTime": "2026-02-05T14:30:00.000Z",
  "resolution": {
    "width": 1920,
    "height": 1080
  },
  "initSegmentPath": "/var/franklyn/video/sentinel-a1b2c3/2026-02-05T14-30-00Z/init.mp4"
}
```

### Per-Segment Metadata

| Field | Type | Description |
|-------|------|-------------|
| `sequence` | integer | Segment sequence number |
| `startTime` | timestamp | Wall-clock time of first frame |
| `duration` | integer | Duration in milliseconds |
| `framerate` | number | Frames per second for this segment |
| `filePath` | string | Path to segment file on disk |

Example:

```json
{
  "sequence": 142,
  "startTime": "2026-02-05T14:35:42.000Z",
  "duration": 4800,
  "framerate": 5,
  "filePath": "/var/franklyn/video/sentinel-a1b2c3/2026-02-05T14-30-00Z/000142.m4s"
}
```

## Memory Storage

During active streaming, all application metadata is held in memory for fast access.

### Data Structure (Conceptual)

```
Server Memory
├── Active Sessions
│   └── {sentinelId}
│       ├── Session Metadata
│       ├── Init Segment (bytes)
│       └── Segment Buffer
│           ├── Segment 140: { metadata, bytes }
│           ├── Segment 141: { metadata, bytes }
│           ├── Segment 142: { metadata, bytes }
│           └── ...
```

### Access Patterns

| Operation | Data Source |
|-----------|-------------|
| Proctor joins stream | Memory (init segment + buffered segments) |
| New segment arrives | Memory (add to buffer, update metadata) |
| Proctor requests historical segment | Disk (metadata points to file path) |

## Database Persistence

Application metadata is periodically synced to the database for durability.

### Sync Strategy

| Aspect | Behavior |
|--------|----------|
| Trigger | Periodic (e.g., every 5-10 seconds) |
| Scope | All new/updated segment metadata since last sync |
| Blocking | Non-blocking (sync happens asynchronously) |
| Failure handling | Retry on next sync interval |

{{< callout type="warning" >}}
The sync interval is an implementation detail. The key requirement is that real-time operations (live streaming) never block on database writes.
{{< /callout >}}

### What is Persisted

| Data | Persisted |
|------|-----------|
| Session metadata | Yes |
| Segment metadata | Yes |
| Segment bytes | No (stored as files on disk) |
| Init segment bytes | No (stored as file on disk) |

### Recovery

On Server restart:
1. Load session and segment metadata from database
2. Locate segment files on disk using stored paths
3. Resume streaming for any Sentinels that reconnect

## Metadata for Historical Access

When a Proctor requests historical segments (via HTTP), the Server uses the persisted metadata to:

1. Identify which segments exist for a Sentinel/session
2. Locate the segment files on disk
3. Serve the requested segment bytes

The Proctor needs to know:
- `sentinelId` and `sessionId` to identify the stream
- `sequence` to request specific segments

The exact API for querying available segments is implementation-defined. The metadata structure above provides the necessary information.
