---
title: Terminology
weight: 1
---

This specification uses a few terms that are easy to mix up in real-time video systems. This page defines them precisely.

## Core Terms

| Term | Meaning in this spec | Why it matters |
|------|-----------------------|----------------|
| **Capture frame** | A single screen image sampled by the Sentinel (pre-encode). | Controls what the user *could* see and when.
| **Encoded sample** | The encoded representation of a capture frame in the H.264 stream (what MP4 carries as a sample). | This is what is actually transported and stored.
| **Keyframe (IDR)** | An H.264 IDR frame (Instantaneous Decoder Refresh). A decoder can start cleanly from here. | Controls *join/switch latency* for a new Proctor.
| **Initialization segment** | fMP4 `ftyp` + `moov` bytes for the session. Contains codec config (SPS/PPS), resolution, timescale. Contains **no frames**. | Must be appended to MSE before any media data can be decoded.
| **Fragment** | A small fMP4 media unit (`moof` + `mdat`) produced frequently and pushed live. Contains **one or more encoded samples**. | Controls *live latency* and how often Proctors see updates.
| **Join fragment** | A fragment whose first sample is an **IDR** keyframe (random access point). | A Proctor should start playback from a join fragment.

{{< callout type="warning" >}}
Do not equate **keyframe interval** with **delivery latency**.

- Keyframe interval controls how quickly a new viewer can join without an on-demand keyframe.
- Fragment cadence (how often fragments are produced and pushed) controls how quickly an existing viewer sees new video.
{{< /callout >}}

## Practical Implications

### Real-Time Requirement

Live streaming MUST push **fragments** continuously. A "20 second" value can apply to the *maximum keyframe interval* (join point spacing), but MUST NOT imply that media is only delivered every 20 seconds.

### What "Sent As It Is Created" Means

When this spec says "sent as it is created", it means:

- A fragment is finalized (it already contains at least one encoded sample).
- That finalized fragment is immediately sent over WebSocket.

It does **not** mean "start sending an empty 20s segment at t=0".
