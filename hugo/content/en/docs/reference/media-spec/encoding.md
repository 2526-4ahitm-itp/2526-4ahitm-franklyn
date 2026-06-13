---
title: Encoding
---

This document specifies the video encoding requirements for Sentinel screen capture.

This spec is written for an implementation that uses the OpenH264 library (BSD-2-Clause) so the overall project can remain MIT-licensed.

Other H.264 encoders MAY be used, but they must produce output that matches the same on-the-wire/container requirements (fMP4 initialization segment + fragments, IDR join points, timestamps).

## Codec

**H.264 (AVC)** is the required codec for all video streams.

{{< callout type="info" >}}
OpenH264 can output an Annex B byte stream. This project packages video into fMP4 for transport/playback, so the Sentinel's muxing layer MUST produce valid fMP4 initialization segments and fragments (not raw Annex B).
{{< /callout >}}

### Why H.264

- Universal hardware decoding support
- Native playback in all modern browsers via MSE
- Low CPU overhead when hardware decoding is available
- Widely supported on school/institutional hardware

## Profile and Level

{{< callout type="info" >}}
The encoder requirements here match OpenH264 capabilities. Other encoders MAY use higher profiles for better compression, but this project standardizes on Constrained Baseline for maximum compatibility.
{{< /callout >}}

### Required: Constrained Baseline Profile

| Setting | Value | Rationale |
|---------|-------|-----------|
| Profile | Constrained Baseline | OpenH264-supported profile; maximum decoder compatibility |
| Level | 3.1 | Supports 1080p at low framerates |

**Tradeoffs:**
- Baseline lacks B-frames, resulting in slightly larger files
- Guaranteed to decode on all hardware, including older/weaker devices
- Fastest encoding speed

{{< callout type="info" >}}
If you use a different encoder, Main/High profiles MAY be acceptable for decoding in browsers, but they are out of scope for this project's default encoder choice.
{{< /callout >}}

### Level Reference

| Level | Max Resolution | Max Framerate | Notes |
|-------|----------------|---------------|-------|
| 3.0 | 1280x720 | 30 fps | Sufficient for 720p |
| 3.1 | 1920x1080 | 30 fps | Recommended for 1080p |
| 4.0 | 2048x1024 | 30 fps | Overkill for this use case |

## Resolution

| Constraint | Value |
|------------|-------|
| Maximum | 1920x1080 (Full HD) |
| Aspect Ratio | Preserved from source |
| Downscaling | Required if source exceeds 1080p |

The Sentinel must downscale captured frames to fit within 1920x1080 while preserving the original aspect ratio. For example, a 2560x1440 capture would be downscaled to 1920x1080.

## Framerate

| Parameter | Value |
|-----------|-------|
| Minimum | 0.2 fps (1 frame per 5 seconds) |
| Maximum | 5 fps |
| Variability | Can change over time (see timestamps) |

### Variable Framerate Behavior

- Framerate can change when the Server requests it (see [Control Messages](../control-messages))
- Each frame carries a timestamp for accurate playback timing
- Players must use frame timestamps, not assume constant framerate

### FPS Change Triggers

The Server may request a framerate change from the Sentinel. Common reasons:
- Server under heavy load (reduce FPS to reduce message volume)
- Network congestion detected
- Administrative policy change

When FPS changes, a new join fragment must be produced (see [Fragments](../segments)).

## Bitrate and Rate Control (OpenH264)

OpenH264 supports either:

- Rate control with adaptive quantization (target bitrate)
- Constant quantization (constant QP)

### Recommended (default): Target Bitrate

The Sentinel SHOULD configure OpenH264 to target a bitrate appropriate for the current FPS and resolution.

If the encoder exposes peak control (VBV-style max bitrate / buffer), implementations SHOULD set it to limit short-term bitrate spikes.

{{< callout type="info" >}}
OpenH264 documents that its rate control may exceed the target bitrate unless frame skipping is enabled. If strict caps are required, enable the relevant RC options for your OpenH264 version.
{{< /callout >}}

### Alternative: Constant Quantization (Quality-First)

Constant-QP mode MAY be used when bitrate predictability is not important (e.g. LAN-only deployments), but it can produce large fragments during high-motion screen updates.

## Keyframes (I-Frames)

Keyframes are complete frames that can be decoded independently without reference to previous frames.

### Keyframe Rules

| Rule | Description |
|------|-------------|
| On-demand | Sentinel must generate a keyframe when requested by Server |
| Maximum interval | At least one keyframe every 20-30 seconds |
| On FPS change | Next join fragment starts with a keyframe when framerate changes |

### Why On-Demand Keyframes

- Allows Proctors to join streams quickly without waiting for the next scheduled keyframe
- Enables fast joins when the Server requests a keyframe for a stream with no recent entrypoint
- Minimizes unnecessary keyframes, reducing bandwidth

### IDR Frames

All keyframes must be **IDR (Instantaneous Decoder Refresh)** frames, not just I-frames. IDR frames clear the decoder reference buffer, ensuring clean entry points for new viewers.
