# Session Recording — Concept

Record the student screen, upload continuously in the background, replay after the session ends.

Replay during the session is not a requirement today, but the format must not rule it out.

## Approach

Record **fragmented MP4 / CMAF segments** instead of one MP4 file.

A plain MP4 writes its index at the end: unplayable until finished, destroyed by an interrupted
write. Segments are playable as they land, survive a crash, and are already an HLS playlist — so
live replay later is a feature flag, not a rewrite.

Segments are also the upload unit. Each one is small and independent, so the upload worker just
sends files and retries failures. No chunking protocol, no resume offsets.

## Pipeline

```
screen capture → convert → H.264 encode → parse → CMAF segment sink
```

The sink writes an init segment, numbered media segments, and a playlist to a local spool
directory. A background worker uploads whatever appears there, playlist last.

The server serves those files back unchanged. No transcoding, no stitching.

## Session breaks

A break restarts the pipeline, which resets timestamps. Each restart becomes a new **run** with its
own init segment and a discontinuity marker in the playlist.

Side effect: resolution and encoder settings may change between runs without breaking playback.

## Gaps and metadata

A sidecar metadata file lists the runs and the gaps between them, mapping media time to wall-clock
time.

The player draws marks on the scrub bar from that list and uses wall-clock as the primary time
axis — a teacher asks what was on screen at 09:42, not at 00:14:20.

Gaps are not filled with black video. Only real blind spots get marked; a stalled upload where
recording continued is not one.

## Single-file download

`ffmpeg -i <playlist> -c copy recording.mp4`, on demand. Not part of the recording path.

## Technologies

| Concern | Choice |
|---|---|
| Capture | GStreamer (`pipewiresrc` on Wayland, `ximagesrc` on X11) |
| Encode | `x264enc` — faster and better quality than `openh264enc` |
| Segmenting | `hlscmafsink` (gst-plugins-rs) |
| Delivery | HLS playlist over HTTP, static files |

openh264 is not the royalty-free alternative it looks like: Cisco's patent grant covers only the
binaries Cisco itself distributes, not source builds.

## Licensing

libx264 is GPL-2.0-or-later. Any artifact that bundles it is distributed under GPL-2.0-or-later
with matching sources. Our own source stays MIT; the GPL binds the bundle, not the repository.

H.264 patent royalties are nil at our scale (Via LA: first 100,000 units per year free).

## Sources

- [`hlscmafsink`](https://gstreamer.freedesktop.org/documentation/hlssink3/hlscmafsink.html)
- [OBS — Writing an MP4 Muxer](https://obsproject.com/blog/obs-studio-hybrid-mp4) — why plain MP4 is unsafe to record to
- [HLS and Fragmented MP4](https://hlsbook.net/hls-fragmented-mp4/)
- [LiveKit Egress — fMP4 segmented output](https://github.com/livekit/egress/pull/1419) — same pattern in production
- [Via LA AVC briefing](https://via-la.com/wp-content/uploads/2025/09/avcweb.pdf)
