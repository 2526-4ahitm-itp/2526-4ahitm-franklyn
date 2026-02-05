---
title: Media Streaming Spec
---

This specification defines how video is encoded, segmented, stored, and delivered for real-time screen sharing between Sentinels and Proctors.

## Overview

| Aspect | Decision |
|--------|----------|
| **Codec** | H.264 |
| **Container** | Fragmented MP4 (fMP4) |
| **Browser Delivery** | Media Source Extensions (MSE) |
| **Segment Duration** | Variable (new segment on each keyframe) |
| **Keyframes** | On-demand + max 20-30s interval + on FPS change |
| **Memory Buffer** | All segments from last 15-20 seconds (configurable) |
| **Disk Storage** | All segments written as-is |
| **Resolution** | Max 1080p, downscaled preserving aspect ratio |
| **Framerate** | 1/5 fps to 5 fps, variable per session, fixed per segment |
| **Live Transport** | WebSocket (server pushes segments) |
| **Historical Transport** | HTTP (Proctor fetches from disk) |

## Components

- **Sentinel**: Captures screen, encodes video, sends segments to Server
- **Server**: Receives segments, buffers in memory, writes to disk, relays to Proctors
- **Proctor**: Receives segments, decodes via MSE, displays video

## Documentation

{{< cards >}}
{{< card link="encoding" title="Encoding" icon="chip" subtitle="H.264 codec settings and framerate" >}}
{{< card link="container" title="Container" icon="archive" subtitle="fMP4 structure and initialization" >}}
{{< card link="segments" title="Segments" icon="collection" subtitle="Segment creation and naming" >}}
{{< card link="memory-buffer" title="Memory Buffer" icon="server" subtitle="Server-side buffering for live streams" >}}
{{< card link="disk-storage" title="Disk Storage" icon="database" subtitle="Persistent segment storage" >}}
{{< card link="metadata" title="Metadata" icon="document-text" subtitle="In-stream and application metadata" >}}
{{< card link="transport" title="Transport" icon="switch-horizontal" subtitle="WebSocket and HTTP delivery" >}}
{{< card link="join-flow" title="Join Flow" icon="login" subtitle="How Proctors join a stream" >}}
{{< card link="control-messages" title="Control Messages" icon="adjustments" subtitle="Keyframe and FPS change requests" >}}
{{< /cards >}}
