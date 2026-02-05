---
title: Encoding
---

This document specifies the video encoding requirements for Sentinel screen capture.

## Codec

**H.264 (AVC)** is the required codec for all video streams.

### Why H.264

- Universal hardware decoding support (Intel Quick Sync, NVIDIA NVENC, AMD VCE)
- Native playback in all modern browsers via MSE
- Low CPU overhead when hardware encoding is available
- Widely supported on school/institutional hardware

## Profile and Level

{{< callout type="info" >}}
These are recommendations. Implementations may adjust based on hardware capabilities.
{{< /callout >}}

### Recommended: Baseline Profile

| Setting | Value | Rationale |
|---------|-------|-----------|
| Profile | Baseline | Maximum decoder compatibility, simpler encoding |
| Level | 3.1 | Supports 1080p at low framerates |

**Tradeoffs:**
- Baseline lacks B-frames, resulting in slightly larger files
- Guaranteed to decode on all hardware, including older/weaker devices
- Fastest encoding speed

### Alternative: Main Profile

| Setting | Value | Rationale |
|---------|-------|-----------|
| Profile | Main | Better compression via B-frames and CABAC |
| Level | 3.1 | Supports 1080p at low framerates |

**Tradeoffs:**
- 10-20% smaller file sizes than Baseline
- Requires slightly more capable hardware for encoding
- Still universally supported for decoding in browsers

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
| Variability | Can change between segments, fixed within a segment |

### Variable Framerate Behavior

- Framerate is constant within a single segment
- Framerate can change at segment boundaries (triggered by FPS change request)
- Each frame carries a timestamp for accurate playback timing
- Players must use frame timestamps, not assume constant framerate

### FPS Change Triggers

The Server may request a framerate change from the Sentinel. Common reasons:
- Server under heavy load (reduce FPS to reduce message volume)
- Network congestion detected
- Administrative policy change

When FPS changes, a new segment must begin (see [Segments](../segments)).

## Keyframes (I-Frames)

Keyframes are complete frames that can be decoded independently without reference to previous frames.

### Keyframe Rules

| Rule | Description |
|------|-------------|
| On-demand | Sentinel must generate a keyframe when requested by Server |
| Maximum interval | At least one keyframe every 20-30 seconds |
| On FPS change | New segment (starting with keyframe) when framerate changes |

### Why On-Demand Keyframes

- Allows Proctors to join streams quickly without waiting for the next scheduled keyframe
- Enables predictive pre-fetching (Proctor requests keyframe before switching streams)
- Minimizes unnecessary keyframes, reducing bandwidth

### IDR Frames

All keyframes must be **IDR (Instantaneous Decoder Refresh)** frames, not just I-frames. IDR frames clear the decoder reference buffer, ensuring clean entry points for new viewers.
