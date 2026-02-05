---
title: Disk Storage
---

This document specifies how segments are persisted to disk.

## Storage Principle

The Server writes segments to disk **as-is** with no processing, transcoding, or modification. The bytes received from the Sentinel are the exact bytes written to disk.

## What is Stored

| Item | Stored | Format |
|------|--------|--------|
| Initialization segment | Yes | Raw fMP4 bytes |
| Media segments | Yes | Raw fMP4 bytes |
| Metadata | Yes (separately) | See [Metadata](../metadata) |

## File Organization

Segments are organized on disk by Sentinel and session.

### Directory Structure

```
{storage_root}/
└── {sentinelId}/
    └── {sessionId}/
        ├── init.mp4
        ├── 000000.m4s
        ├── 000001.m4s
        ├── 000002.m4s
        └── ...
```

| Component | Description |
|-----------|-------------|
| `storage_root` | Base directory for all video storage |
| `sentinelId` | Unique identifier for the Sentinel |
| `sessionId` | Unique identifier for the session (e.g., timestamp or UUID) |

### Example

```
/var/franklyn/video/
└── sentinel-a1b2c3/
    └── 2026-02-05T14-30-00Z/
        ├── init.mp4
        ├── 000000.m4s
        ├── 000001.m4s
        ├── 000002.m4s
        └── ...
```

## Write Timing

Segments are written to disk immediately upon receipt from the Sentinel.

| Event | Action |
|-------|--------|
| Initialization segment received | Write to `init.mp4` |
| Media segment received | Write to `{sequence}.m4s` |

{{< callout type="info" >}}
Writing happens in parallel with adding the segment to the memory buffer. The live streaming path (memory) and archival path (disk) are independent.
{{< /callout >}}

## No Server Processing

The Server performs **no video processing**:

| Operation | Performed by Server |
|-----------|---------------------|
| Decoding | No |
| Encoding | No |
| Transcoding | No |
| Re-muxing | No |
| Frame extraction | No |
| Concatenation | No |

The Server's role is purely:
- Receive bytes from Sentinel
- Write bytes to disk
- Read bytes from disk
- Send bytes to Proctor

## File Integrity

Each segment file is a complete, valid fMP4 media segment. Combined with the initialization segment, any media segment can be decoded independently.

### Playback from Disk

To play back stored video:

{{% steps %}}

### Load Initialization Segment

Read `init.mp4` for the session.

### Load Media Segments in Order

Read segment files in sequence order: `000000.m4s`, `000001.m4s`, etc.

### Concatenate and Play

Provide initialization segment + media segments to an fMP4-compatible player or MSE.

{{% /steps %}}

## Retention

The spec does not mandate a retention policy. Implementations may:

- Keep all segments indefinitely
- Delete segments after a configured period
- Delete entire sessions based on policy
- Provide manual or automated cleanup

## Later Viewing

Stored segments can be retrieved via HTTP for later viewing. See [Transport](../transport) for details on historical segment access.

### Transcoding for Export

For exporting video to a standard format (e.g., a single MP4 file), a separate **transcoding client** can:

1. Fetch the initialization segment
2. Fetch all media segments for a session
3. Concatenate into a single playable file

This transcoding happens outside the Server (in the Proctor browser or a dedicated tool), maintaining the principle that the Server does no video processing.

{{< callout type="warning" >}}
The transcoding/export workflow is out of scope for this spec. The stored segments are sufficient for playback via MSE or external tools.
{{< /callout >}}
