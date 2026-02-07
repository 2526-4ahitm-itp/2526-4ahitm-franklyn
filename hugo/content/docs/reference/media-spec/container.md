---
title: Container
---

This document specifies the container format for video data.

## Format: Fragmented MP4 (fMP4)

All video data is packaged in **Fragmented MP4** format. This is a variant of the standard MP4 container optimized for streaming.

### Why fMP4

- Native support in browser Media Source Extensions (MSE)
- No transcoding needed on Server or Proctor
- Fragments can be appended incrementally (with initialization data)
- Industry standard for adaptive streaming (DASH, HLS)

## Structure Overview

An fMP4 stream consists of two types of data:

| Type | Purpose | When Sent |
|------|---------|-----------|
| **Initialization Segment** | Contains codec configuration, resolution, timescale | Once per session, on Proctor join |
 | **Media Fragment** | Contains encoded samples (frames) and timing (`moof` + `mdat`) | Continuously during streaming |

```
┌─────────────────────────┐
│  Initialization Segment │  ← Sent once per session
│  (ftyp + moov boxes)    │
└─────────────────────────┘
           │
           ▼
┌─────────────────────────┐
│    Media Fragment 1     │  ← May start with keyframe
│  (moof + mdat boxes)    │
└─────────────────────────┘
            │
            ▼
┌─────────────────────────┐
│    Media Fragment 2     │  ← May start with keyframe
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

## Media Fragments

Each media fragment contains one or more encoded samples (video frames) packaged for streaming.

### Contents

| Box | Purpose |
|-----|---------|
| `moof` | Movie fragment header (timing, frame offsets) |
| `mdat` | Media data (actual H.264 NAL units) |

### Requirements

 | Requirement | Description |
 |-------------|-------------|
 | Decodable with init | A fragment is decodable when appended after the initialization segment and appropriate preceding fragments |
 | Join points | A **join fragment** begins with an IDR frame and is a safe entry point for new viewers |
 | Self-contained timing | Timestamps in `moof` are absolute (not relative to previous fragment) |
 | Variable duration | Fragments can have different durations |

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

### Append Media Fragments

As media fragments arrive, append them to the `SourceBuffer` in order.

### Handle Playback

The browser's video element handles decoding and rendering automatically.

{{% /steps %}}

## MIME Type

The MIME type for MSE must specify both the container and codec:

```
video/mp4; codecs="avc1.PPCCLL"
```

Where the `avc1` codec string uses the AVCDecoderConfigurationRecord triplet:

- `PP` = `AVCProfileIndication` (profile)
- `CC` = `profile_compatibility` (constraint flags)
- `LL` = `AVCLevelIndication` (level)

For this project (OpenH264), the expected profile is Constrained Baseline.

Example for Constrained Baseline Profile, Level 3.1:
```
video/mp4; codecs="avc1.42E01F"
```

{{< callout type="info" >}}
Other encoders MAY produce different `avc1` values (e.g. Main/High), as long as Proctor playback targets environments that can decode them.
{{< /callout >}}
