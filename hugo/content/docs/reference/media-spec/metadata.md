---
title: Metadata
---

This document specifies the metadata associated with video fragments, where it is stored, and how it is synchronized.

See [Terminology](../terminology) for the distinction between fragments and join fragments.

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

### Media Fragment

In this spec, this refers to a media **fragment** (`moof` + `mdat`).

| Field | Location | Description |
|-------|----------|-------------|
| Base decode time | `moof` → `tfdt` | Timestamp of first frame in fragment |
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

### Per-Fragment Metadata

This spec uses the term **fragment** for the live-delivery unit.

| Field | Type | Description |
|-------|------|-------------|
| `sequence` | integer | Fragment sequence number |
| `startTime` | timestamp | Wall-clock time of first frame |
| `duration` | integer | Duration in milliseconds |
| `framerate` | number | Frames per second during this fragment |
| `filePath` | string | Path to fragment file on disk |
| `isJoin` | boolean | True if this fragment starts with an IDR keyframe |

Example:

```json
{
  "sequence": 142,
  "startTime": "2026-02-05T14:35:42.000Z",
  "duration": 4800,
  "framerate": 5,
  "filePath": "/var/franklyn/video/sentinel-a1b2c3/2026-02-05T14-30-00Z/000142.m4s",
  "isJoin": false
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
│       └── Fragment Buffer
│           ├── Fragment 140: { metadata, bytes }
│           ├── Fragment 141: { metadata, bytes }
│           ├── Fragment 142: { metadata, bytes }
│           └── ...
```

### Access Patterns

| Operation | Data Source |
|-----------|-------------|
| Proctor joins stream | Memory (initialization segment + buffered fragments) |
| New fragment arrives | Memory (add to buffer, update metadata) |
| Proctor requests historical fragment | Disk (metadata points to file path) |

## Database Persistence

Application metadata is periodically synced to the database for durability.

### Sync Strategy

| Aspect | Behavior |
|--------|----------|
| Trigger | Periodic (e.g., every 5-10 seconds) |
| Scope | All new/updated fragment metadata since last sync |
| Blocking | Non-blocking (sync happens asynchronously) |
| Failure handling | Retry on next sync interval |

{{< callout type="warning" >}}
The sync interval is an implementation detail. The key requirement is that real-time operations (live streaming) never block on database writes.
{{< /callout >}}

### What is Persisted

| Data | Persisted |
|------|-----------|
| Session metadata | Yes |
| Fragment metadata | Yes |
| Fragment bytes | No (stored as files on disk) |
| Init segment bytes | No (stored as file on disk) |

### Recovery

On Server restart:
1. Load session and fragment metadata from database
2. Locate fragment files on disk using stored paths
3. Resume streaming for any Sentinels that reconnect

## Metadata for Historical Access

When a Proctor requests historical fragments (via HTTP), the Server uses the persisted metadata to:

1. Identify which fragments exist for a Sentinel/session
2. Locate the fragment files on disk
3. Serve the requested fragment bytes

The Proctor needs to know:
- `sentinelId` and `sessionId` to identify the stream
- `sequence` to request specific fragments

The exact API for querying available fragments is implementation-defined. The metadata structure above provides the necessary information.
