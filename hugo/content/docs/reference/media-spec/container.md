---
title: Container
---

This document specifies the container format for video segments.

## Format: Fragmented MP4 (fMP4)

All video data is packaged in **Fragmented MP4** format. This is a variant of the standard MP4 container optimized for streaming.

### Why fMP4

- Native support in browser Media Source Extensions (MSE)
- No transcoding needed on Server or Proctor
- Segments can be played independently (with initialization data)
- Industry standard for adaptive streaming (DASH, HLS)

## Structure Overview

An fMP4 stream consists of two types of data:

| Type | Purpose | When Sent |
|------|---------|-----------|
| **Initialization Segment** | Contains codec configuration, resolution, timescale | Once per session, on Proctor join |
| **Media Segment** | Contains actual video frames and timing | Continuously during streaming |

```
┌─────────────────────────┐
│  Initialization Segment │  ← Sent once per session
│  (ftyp + moov boxes)    │
└─────────────────────────┘
           │
           ▼
┌─────────────────────────┐
│    Media Segment 1      │  ← Starts with keyframe
│  (moof + mdat boxes)    │
└─────────────────────────┘
           │
           ▼
┌─────────────────────────┐
│    Media Segment 2      │  ← Starts with keyframe
│  (moof + mdat boxes)    │
└─────────────────────────┘
           │
           ▼
          ...
```

## Initialization Segment

The initialization segment contains metadata required to configure the decoder. It does not contain any video frames.

### Contents

| Box | Purpose |
|-----|---------|
| `ftyp` | File type declaration (brand: `iso5` or `isom`) |
| `moov` | Movie header containing codec and track information |

### Key Information in `moov`

- **Codec parameters**: H.264 SPS/PPS (Sequence/Picture Parameter Sets)
- **Resolution**: Width and height in pixels
- **Timescale**: Time units per second for timestamps

### Lifetime

- Generated once when the Sentinel starts a session
- Remains valid for the entire session
- Resolution and codec parameters do not change mid-session
- Server caches in memory for each active Sentinel
- Sent to Proctor on stream join request

## Media Segments

Each media segment contains one or more video frames packaged for streaming.

### Contents

| Box | Purpose |
|-----|---------|
| `moof` | Movie fragment header (timing, frame offsets) |
| `mdat` | Media data (actual H.264 NAL units) |

### Requirements

| Requirement | Description |
|-------------|-------------|
| Starts with keyframe | Every media segment must begin with an IDR frame |
| Self-contained timing | Timestamps in `moof` are absolute (not relative to previous segment) |
| Variable duration | Segments can have different durations |
| Fixed framerate per segment | Framerate is constant within a segment |

### Timing Information

The `moof` box contains a `tfdt` (Track Fragment Decode Time) box specifying the decode timestamp of the first frame. Each frame's duration is specified in the `trun` (Track Fragment Run) box.

{{< callout type="info" >}}
The timescale from the initialization segment determines how timestamps map to wall-clock time. A common choice is 90000 (90kHz), allowing sub-millisecond precision.
{{< /callout >}}

## Proctor Playback

To play a stream, the Proctor must:

{{% steps %}}

### Receive Initialization Segment

Obtain the initialization segment for the target Sentinel from the Server.

### Initialize MSE SourceBuffer

Create a `MediaSource`, add a `SourceBuffer` with the appropriate MIME type, and append the initialization segment.

```javascript
// Example MIME type for H.264 in fMP4
"video/mp4; codecs=\"avc1.42E01F\""
```

### Append Media Segments

As media segments arrive, append them to the `SourceBuffer` in order.

### Handle Playback

The browser's video element handles decoding and rendering automatically.

{{% /steps %}}

## MIME Type

The MIME type for MSE must specify both the container and codec:

```
video/mp4; codecs="avc1.PPCCLL"
```

Where `PPCCLL` is the H.264 profile/level indicator:
- `42` = Baseline profile
- `4D` = Main profile
- `E01F` = Level 3.1

Example for Baseline Profile, Level 3.1:
```
video/mp4; codecs="avc1.42E01F"
```

Example for Main Profile, Level 3.1:
```
video/mp4; codecs="avc1.4D401F"
```
