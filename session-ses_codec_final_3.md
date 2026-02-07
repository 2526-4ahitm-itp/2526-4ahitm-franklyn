# 20s segments and real-time delivery latency

**Session ID:** ses_3caae0fbcffeTh8z9Ph3O2tkdG
**Created:** 2/7/2026, 12:38:08 AM
**Updated:** 2/7/2026, 2:20:43 AM

---

## Assistant (Build · gpt-5.2 · 10.5s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/join-flow.md\n@@\n When a Proctor wants to view a Sentinel's screen, it must:\n@@\n-3. Receive a keyframe segment (join point)\n-4. Continue receiving live segments\n+3. Receive a join fragment (IDR entry point)\n+4. Continue receiving live fragments\n@@\n-Srv -> P : keyframe segment\\n(oldest in buffer or latest)\n+Srv -> P : join fragment\\n(most recent in buffer)\n@@\n-loop as segments arrive\n-  S -> Srv : new segment\n-  Srv -> P : new segment\n+loop as fragments arrive\n+  S -> Srv : new fragment\n+  Srv -> P : new fragment\n end\n@@\n-### Server Sends Keyframe Segment\n+### Server Sends Join Fragment\n@@\n-The Server selects a segment from the memory buffer and sends it.\n+The Server selects a join fragment from the memory buffer and sends it.\n@@\n-| `startFrom` | Segment Selected |\n+| `startFrom` | Join Fragment Selected |\n |-------------|------------------|\n-| `\"oldest\"` | Oldest segment in buffer (maximum catch-up time) |\n-| `\"latest\"` | Most recent segment (lowest latency) |\n+| `\"oldest\"` | Oldest join fragment in buffer (maximum catch-up time) |\n+| `\"latest\"` | Most recent join fragment (lowest latency) |\n@@\n-The selected segment is guaranteed to start with a keyframe (all segments do).\n+The selected fragment is guaranteed to start with an IDR keyframe (join fragment).\n@@\n | Field | Type | Description |\n |-------|------|-------------|\n | `sentinelId` | string | Identifies the stream |\n-| `sequence` | integer | Segment sequence number |\n-| `data` | bytes | Raw fMP4 media segment |\n+| `sequence` | integer | Fragment sequence number |\n+| `data` | bytes | Raw fMP4 fragment (`moof` + `mdat`) |\n@@\n-### Server Continues Pushing Segments\n+### Server Continues Pushing Fragments\n@@\n-From this point, the Server pushes new segments to the Proctor as they arrive from the Sentinel.\n+From this point, the Server pushes new fragments to the Proctor as they arrive from the Sentinel.\n@@\n-If the Proctor wants to minimize join latency (not wait for the next segment), it can request an on-demand keyframe before or during the join.\n+If the Proctor wants to minimize join latency (not wait for the next join fragment), it can request an on-demand keyframe before or during the join.\n@@\n-S -> Srv : new segment\\n(starts with keyframe)\n+S -> Srv : new join fragment\\n(starts with keyframe)\n@@\n-Srv -> P : keyframe segment\\n(the just-created one)\n+Srv -> P : join fragment\\n(the just-created one)\n@@\n-loop as segments arrive\n-  S -> Srv : new segment\n-  Srv -> P : new segment\n+loop as fragments arrive\n+  S -> Srv : new fragment\n+  Srv -> P : new fragment\n end\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/join-flow.md
```
```

---

## Assistant (Build · gpt-5.2 · 2.3s)

```
Tool: read

**Input:**
```json
{
  "filePath": "/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/join-flow.md",
  "offset": 190,
  "limit": 40
}
```
**Output:**
```
<file>
00191| 
00192| {{% /steps %}}
00193| 
00194| ## Error Handling
00195| 
00196| | Condition | Server Response |
00197| |-----------|-----------------|
00198| | Sentinel not found | Error: unknown Sentinel |
00199| | Sentinel not streaming | Error: Sentinel offline |
00200| | Authorization failure | Error: not authorized |
00201| | No segments in buffer | Send init segment, wait for first segment |
00202| 
00203| ## Latency Considerations
00204| 
00205| | Factor | Impact on Join Latency |
00206| |--------|------------------------|
00207| | Buffer has segments | Immediate join (send from buffer) |
00208| | On-demand keyframe requested | Wait for next capture cycle |
00209| | No keyframe, must wait | Up to max keyframe interval (20-30s) |
00210| 
00211| For lowest latency joins:
00212| 1. Use on-demand keyframe requests
00213| 2. Use `startFrom: "latest"` 
00214| 3. Pre-fetch keyframes for likely next streams
00215| 

(End of file - total 215 lines)
</file>
```
```

---

## Assistant (Build · gpt-5.2 · 5.8s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/join-flow.md\n@@\n | Condition | Server Response |\n |-----------|-----------------|\n | Sentinel not found | Error: unknown Sentinel |\n | Sentinel not streaming | Error: Sentinel offline |\n | Authorization failure | Error: not authorized |\n-| No segments in buffer | Send init segment, wait for first segment |\n+| No join fragment in buffer | Send init segment, request/await next join fragment |\n@@\n | Factor | Impact on Join Latency |\n |--------|------------------------|\n-| Buffer has segments | Immediate join (send from buffer) |\n+| Buffer has join fragments | Immediate join (send from buffer) |\n | On-demand keyframe requested | Wait for next capture cycle |\n-| No keyframe, must wait | Up to max keyframe interval (20-30s) |\n+| No join fragment available | Up to max keyframe interval (20-30s) unless on-demand keyframe is used |\n@@\n 2. Use `startFrom: \"latest\"` \n 3. Pre-fetch keyframes for likely next streams\n+\n+{{< callout type=\"warning\" >}}\n+\"20-30 seconds\" is the maximum keyframe interval (join fragment spacing). Live video is still delivered continuously as fragments.\n+{{< /callout >}}\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/join-flow.md
```
```

---

## Assistant (Build · gpt-5.2 · 2.9s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/encoding.md\n@@\n When FPS changes, a new segment must begin (see [Segments](../segments)).\n+When FPS changes, a new join fragment must be produced (see [Fragments](../segments)).\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/encoding.md
```
```

---

## Assistant (Build · gpt-5.2 · 2.8s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/encoding.md\n@@\n-When FPS changes, a new segment must begin (see [Segments](../segments)).\n-When FPS changes, a new join fragment must be produced (see [Fragments](../segments)).\n+When FPS changes, a new join fragment must be produced (see [Fragments](../segments)).\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/encoding.md
```
```

---

## Assistant (Build · gpt-5.2 · 6.5s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/control-messages.md\n@@\n- S -> Srv : segment\\n(starts with keyframe)\n+ S -> Srv : join fragment\\n(starts with keyframe)\n@@\n ### Sentinel Behavior\n@@\n When the Sentinel receives a keyframe request:\n@@\n-1. The next captured frame becomes an IDR frame (keyframe)\n-2. A new segment begins with this keyframe\n-3. The segment is sent to the Server as usual\n+1. The next captured frame becomes an IDR frame (keyframe)\n+2. A new join fragment begins with this keyframe\n+3. The join fragment is sent to the Server as usual\n@@\n- S -> S : finish current segment\n+ S -> S : finish current fragment\n@@\n- S -> Srv : segment\\n(at old fps)\n+ S -> Srv : fragment\\n(at old fps)\n@@\n- S -> Srv : segment\\n(at new fps, starts with keyframe)\n+ S -> Srv : join fragment\\n(at new fps, starts with keyframe)\n@@\n ### Sentinel Behavior\n@@\n ### Finish Current Segment\n \n-Complete and send the current segment with the old framerate.\n+Complete and send the current fragment with the old framerate.\n@@\n ### Generate Keyframe\n@@\n-The next frame is an IDR frame, starting a new segment.\n+The next frame is an IDR frame, starting a new join fragment.\n@@\n ### Continue Streaming\n \n-New segments are sent at the new framerate.\n+New fragments are sent at the new framerate.\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/control-messages.md
```
```

---

## Assistant (Build · gpt-5.2 · 14.9s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/metadata.md\n@@\n-This document specifies the metadata associated with video segments, where it is stored, and how it is synchronized.\n+This document specifies the metadata associated with video fragments, where it is stored, and how it is synchronized.\n+\n+See [Terminology](../terminology) for the distinction between fragments and join fragments.\n@@\n ## In-Stream Metadata\n@@\n ### Media Segment\n+\n+In this spec, this refers to a media **fragment** (`moof` + `mdat`).\n@@\n ## Application Metadata\n@@\n ### Per-Segment Metadata\n+\n+This spec uses the term **fragment** for the live-delivery unit. The database may keep the naming `segment` if desired, but semantics must match this page.\n@@\n | Field | Type | Description |\n |-------|------|-------------|\n-| `sequence` | integer | Segment sequence number |\n-| `startTime` | timestamp | Wall-clock time of first frame |\n-| `duration` | integer | Duration in milliseconds |\n-| `framerate` | number | Frames per second for this segment |\n-| `filePath` | string | Path to segment file on disk |\n+| `sequence` | integer | Fragment sequence number |\n+| `startTime` | timestamp | Wall-clock time of first frame |\n+| `duration` | integer | Duration in milliseconds |\n+| `framerate` | number | Frames per second during this fragment |\n+| `filePath` | string | Path to fragment file on disk |\n+| `isJoin` | boolean | True if this fragment starts with an IDR keyframe |\n@@\n Example:\n@@\n {\n   \"sequence\": 142,\n   \"startTime\": \"2026-02-05T14:35:42.000Z\",\n   \"duration\": 4800,\n   \"framerate\": 5,\n-  \"filePath\": \"/var/franklyn/video/sentinel-a1b2c3/2026-02-05T14-30-00Z/000142.m4s\"\n+  \"filePath\": \"/var/franklyn/video/sentinel-a1b2c3/2026-02-05T14-30-00Z/000142.m4s\",\n+  \"isJoin\": false\n }\n@@\n ### Data Structure (Conceptual)\n@@\n-│       └── Segment Buffer\n-│           ├── Segment 140: { metadata, bytes }\n-│           ├── Segment 141: { metadata, bytes }\n-│           ├── Segment 142: { metadata, bytes }\n+│       └── Fragment Buffer\n+│           ├── Fragment 140: { metadata, bytes }\n+│           ├── Fragment 141: { metadata, bytes }\n+│           ├── Fragment 142: { metadata, bytes }\n │           └── ...\n@@\n | Operation | Data Source |\n |-----------|-------------|\n | Proctor joins stream | Memory (init segment + buffered segments) |\n | New segment arrives | Memory (add to buffer, update metadata) |\n | Proctor requests historical segment | Disk (metadata points to file path) |\n+\n+Update (terminology): the above operations apply to **fragments**.\n@@\n Application metadata is periodically synced to the database for durability.\n@@\n | Aspect | Behavior |\n |--------|----------|\n | Trigger | Periodic (e.g., every 5-10 seconds) |\n-| Scope | All new/updated segment metadata since last sync |\n+| Scope | All new/updated fragment metadata since last sync |\n | Blocking | Non-blocking (sync happens asynchronously) |\n | Failure handling | Retry on next sync interval |\n@@\n ### What is Persisted\n@@\n | Data | Persisted |\n |------|-----------|\n | Session metadata | Yes |\n-| Segment metadata | Yes |\n-| Segment bytes | No (stored as files on disk) |\n+| Fragment metadata | Yes |\n+| Fragment bytes | No (stored as files on disk) |\n | Init segment bytes | No (stored as file on disk) |\n@@\n ## Metadata for Historical Access\n@@\n-When a Proctor requests historical segments (via HTTP), the Server uses the persisted metadata to:\n+When a Proctor requests historical fragments (via HTTP), the Server uses the persisted metadata to:\n@@\n-1. Identify which segments exist for a Sentinel/session\n-2. Locate the segment files on disk\n-3. Serve the requested segment bytes\n+1. Identify which fragments exist for a Sentinel/session\n+2. Locate the fragment files on disk\n+3. Serve the requested fragment bytes\n@@\n The Proctor needs to know:\n - `sentinelId` and `sessionId` to identify the stream\n-- `sequence` to request specific segments\n+- `sequence` to request specific fragments\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/metadata.md
```
```

---

## Assistant (Build · gpt-5.2 · 11.3s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/disk-storage.md\n@@\n-This document specifies how segments are persisted to disk.\n+This document specifies how fragments are persisted to disk.\n+\n+See [Terminology](../terminology).\n@@\n ## Storage Principle\n@@\n-The Server writes segments to disk **as-is** with no processing, transcoding, or modification. The bytes received from the Sentinel are the exact bytes written to disk.\n+The Server writes fragments to disk **as-is** with no processing, transcoding, or modification. The bytes received from the Sentinel are the exact bytes written to disk.\n@@\n ## What is Stored\n@@\n | Item | Stored | Format |\n |------|--------|--------|\n | Initialization segment | Yes | Raw fMP4 bytes |\n- | Media segments | Yes | Raw fMP4 bytes |\n+ | Media fragments | Yes | Raw fMP4 bytes |\n | Metadata | Yes (separately) | See [Metadata](../metadata) |\n@@\n ## File Organization\n@@\n-Segments are organized on disk by Sentinel and session.\n+Fragments are organized on disk by Sentinel and session.\n@@\n ## Write Timing\n@@\n-Segments are written to disk immediately upon receipt from the Sentinel.\n+Fragments are written to disk immediately upon receipt from the Sentinel.\n@@\n | Event | Action |\n |-------|--------|\n | Initialization segment received | Write to `init.mp4` |\n- | Media segment received | Write to `{sequence}.m4s` |\n+ | Media fragment received | Write to `{sequence}.m4s` |\n@@\n {{< callout type=\"info\" >}}\n-Writing happens in parallel with adding the segment to the memory buffer. The live streaming path (memory) and archival path (disk) are independent.\n+Writing happens in parallel with adding the fragment to the memory buffer. The live streaming path (memory) and archival path (disk) are independent.\n {{< /callout >}}\n@@\n ## File Integrity\n@@\n-Each segment file is a complete, valid fMP4 media segment. Combined with the initialization segment, any media segment can be decoded independently.\n+Each fragment file is a complete, valid fMP4 media fragment. Combined with the initialization segment, any fragment can be decoded independently when appended in order; a Proctor SHOULD start at a join fragment.\n@@\n ### Playback from Disk\n@@\n ### Load Media Segments in Order\n \n-Read segment files in sequence order: `000000.m4s`, `000001.m4s`, etc.\n+Read fragment files in sequence order: `000000.m4s`, `000001.m4s`, etc.\n@@\n ### Concatenate and Play\n \n-Provide initialization segment + media segments to an fMP4-compatible player or MSE.\n+Provide initialization segment + media fragments to an fMP4-compatible player or MSE.\n@@\n ## Retention\n@@\n The spec does not mandate a retention policy. Implementations may:\n@@\n - Keep all segments indefinitely\n - Delete segments after a configured period\n - Delete entire sessions based on policy\n - Provide manual or automated cleanup\n+\n+Update (terminology): the above retention applies to fragment files.\n@@\n ## Later Viewing\n \n-Stored segments can be retrieved via HTTP for later viewing. See [Transport](../transport) for details on historical segment access.\n+Stored fragments can be retrieved via HTTP for later viewing. See [Transport](../transport) for details on historical fragment access.\n@@\n ### Transcoding for Export\n@@\n 1. Fetch the initialization segment\n-2. Fetch all media segments for a session\n+2. Fetch all media fragments for a session\n 3. Concatenate into a single playable file\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/disk-storage.md
```
```

---

## Assistant (Build · gpt-5.2 · 2.3s)

```
Tool: grep

**Input:**
```json
{
  "pattern": "\\bsegment(s)?\\b",
  "path": "hugo/content/docs/reference/media-spec",
  "include": "*.md"
}
```
**Output:**
```
Found 77 matches
/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/disk-storage.md:
  Line 17: | Initialization segment | Yes | Raw fMP4 bytes |
  Line 63: | Initialization segment received | Write to `init.mp4` |
  Line 91: Each fragment file is a complete, valid fMP4 media fragment. Combined with the initialization segment, any fragment can be decoded independently when appended in order; a Proctor SHOULD start at a join fragment.
  Line 109: Provide initialization segment + media fragments to an fMP4-compatible player or MSE.
  Line 117: - Keep all segments indefinitely
  Line 118: - Delete segments after a configured period
  Line 132: 1. Fetch the initialization segment
  Line 139: The transcoding/export workflow is out of scope for this spec. The stored segments are sufficient for playback via MSE or external tools.

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/metadata.md:
  Line 36: | Base decode time | `moof` → `tfdt` | Timestamp of first frame in segment |
  Line 56: | `initSegmentPath` | string | Path to initialization segment on disk |
  Line 75: This spec uses the term **fragment** for the live-delivery unit. The database may keep the naming `segment` if desired, but semantics must match this page.
  Line 122: | Proctor joins stream | Memory (init segment + buffered segments) |
  Line 123: | New segment arrives | Memory (add to buffer, update metadata) |
  Line 124: | Proctor requests historical segment | Disk (metadata points to file path) |
  Line 152: | Init segment bytes | No (stored as file on disk) |
  Line 157: 1. Load session and segment metadata from database
  Line 158: 2. Locate segment files on disk using stored paths
  Line 173: The exact API for querying available segments is implementation-defined. The metadata structure above provides the necessary information.

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/control-messages.md:
  Line 45: Srv -> P : segment available
  Line 94: No explicit response message is defined. The Proctor knows the keyframe request was fulfilled when a new segment arrives (which will start with a keyframe).
  Line 177: No explicit response message is defined. The Server observes the framerate change via segment metadata.
  Line 197: | FPS Change | Takes effect on next segment |
  Line 214: | Sentinel busy | Sentinel applies on next segment boundary |

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/encoding.md:
  Line 72: | Variability | Can change between segments, fixed within a segment |
  Line 76: - Framerate is constant within a single segment
  Line 77: - Framerate can change at segment boundaries (triggered by FPS change request)
  Line 88: When FPS changes, a new join fragment must be produced (see [Fragments](../segments)).
  Line 100: | On FPS change | New segment (starting with keyframe) when framerate changes |

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/join-flow.md:
  Line 12: 2. Receive the initialization segment
  Line 36: Srv -> P : init segment
  Line 83: The Server sends the cached initialization segment for the Sentinel's current session.
  Line 91: | `data` | bytes | Raw fMP4 init segment |
  Line 149: Srv -> P : init segment
  Line 179: Proctor notifies Server to stop sending segments for the current Sentinel.
  Line 189: - Append the new initialization segment
  Line 190: - Begin appending segments from the new stream
  Line 201: | No join fragment in buffer | Send init segment, request/await next join fragment |

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/memory-buffer.md:
  Line 13: 1. **Fast Proctor joins**: Proctors can immediately receive recent segments without disk I/O
  Line 14: 2. **Network resilience**: Proctors with slower connections can catch up from buffered segments
  Line 31: | **Initialization segment** | The codec/resolution configuration for the session |
  Line 63: The spec does not mandate a specific eviction strategy. Implementations may use lazy garbage collection, periodic cleanup, or immediate removal. The only requirement is that segments older than the buffer window are not required to remain in memory.
  Line 75: 1. Server sends the initialization segment
  Line 95: The initialization segment for each active Sentinel is cached separately from the media segment buffer.
  Line 103: Since the initialization segment is small (typically a few KB) and required for every new Proctor, it remains in memory for the duration of the Sentinel's session.
  Line 109: - **Buffer window duration**: Longer window = more segments
  Line 112: - **Keyframe frequency**: More keyframes = more segments (each starting with a keyframe)

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/segments.md:
  Line 75: | Extension | `.m4s` for media segments | |
  Line 87: The initialization segment uses a distinct name:
  Line 123: | Frame durations | `moof` → `trun` | Duration of each frame in segment |
  Line 141:  | Session start | Sequence resets to 0, new initialization segment created |
  Line 146: If a Sentinel reconnects (new session), it generates a new initialization segment and restarts sequence numbering at 0. The Server treats this as a new stream.

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/container.md:
  Line 5: This document specifies the container format for video segments.
  Line 51: The initialization segment contains metadata required to configure the decoder. It does not contain any video frames.
  Line 89:  | Decodable with init | A fragment is decodable when appended after the initialization segment and appropriate preceding fragments |
  Line 91:  | Self-contained timing | Timestamps in `moof` are absolute (not relative to previous segment) |
  Line 99: The timescale from the initialization segment determines how timestamps map to wall-clock time. A common choice is 90000 (90kHz), allowing sub-millisecond precision.
  Line 110: Obtain the initialization segment for the target Sentinel from the Server.
  Line 114: Create a `MediaSource`, add a `SourceBuffer` with the appropriate MIME type, and append the initialization segment.

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/transport.md:
  Line 60: Srv -> P : init segment
  Line 94: The initialization segment is sent separately, typically:
  Line 102: | `data` | bytes | Raw fMP4 initialization segment bytes |
  Line 135:  | `segments` | array | List of available fragment metadata |
  Line 156:  | Joining a stream | Yes (get init + recent segments) |
  Line 174: 3. Sentinel begins pushing segments
  Line 183: 4. Server pushes segments for subscribed streams

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/_index.md:
  Line 14: | **Segment Duration** | Variable (new segment on each keyframe) |
  Line 16: | **Memory Buffer** | All segments from last 15-20 seconds (configurable) |
  Line 17: | **Disk Storage** | All segments written as-is |
  Line 19: | **Framerate** | 1/5 fps to 5 fps, variable per session, fixed per segment |
  Line 20: | **Live Transport** | WebSocket (server pushes segments) |
  Line 25: - **Sentinel**: Captures screen, encodes video, sends segments to Server
  Line 26: - **Server**: Receives segments, buffers in memory, writes to disk, relays to Proctors
  Line 27: - **Proctor**: Receives segments, decodes via MSE, displays video
  Line 35: {{< card link="segments" title="Fragments" icon="collection" subtitle="Fragment cadence and join fragments" >}}
  Line 37: {{< card link="disk-storage" title="Disk Storage" icon="database" subtitle="Persistent segment storage" >}}

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/terminology.md:
  Line 15: | **Initialization segment** | fMP4 `ftyp` + `moov` bytes for the session. Contains codec config (SPS/PPS), resolution, timescale. Contains **no frames**. | Must be appended to MSE before any media data can be decoded.
  Line 39: It does **not** mean "start sending an empty 20s segment at t=0".
```
```

---

## Assistant (Build · gpt-5.2 · 7.5s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/_index.md\n@@\n ## Overview\n@@\n | Aspect | Decision |\n |--------|----------|\n | **Codec** | H.264 |\n | **Container** | Fragmented MP4 (fMP4) |\n | **Browser Delivery** | Media Source Extensions (MSE) |\n-| **Segment Duration** | Variable (new segment on each keyframe) |\n+| **Fragment Duration** | Variable, short (implementation choice for real-time delivery) |\n | **Keyframes** | On-demand + max 20-30s interval + on FPS change |\n-| **Memory Buffer** | All segments from last 15-20 seconds (configurable) |\n-| **Disk Storage** | All segments written as-is |\n+| **Memory Buffer** | All fragments from last 15-20 seconds (configurable) |\n+| **Disk Storage** | All fragments written as-is |\n | **Resolution** | Max 1080p, downscaled preserving aspect ratio |\n-| **Framerate** | 1/5 fps to 5 fps, variable per session, fixed per segment |\n-| **Live Transport** | WebSocket (server pushes segments) |\n+| **Framerate** | 1/5 fps to 5 fps, variable over time |\n+| **Live Transport** | WebSocket (server pushes fragments) |\n | **Historical Transport** | HTTP (Proctor fetches from disk) |\n@@\n ## Components\n@@\n-- **Sentinel**: Captures screen, encodes video, sends segments to Server\n-- **Server**: Receives segments, buffers in memory, writes to disk, relays to Proctors\n-- **Proctor**: Receives segments, decodes via MSE, displays video\n+- **Sentinel**: Captures screen, encodes video, sends fragments to Server\n+- **Server**: Receives fragments, buffers in memory, writes to disk, relays to Proctors\n+- **Proctor**: Receives fragments, decodes via MSE, displays video\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/_index.md
```
```

---

## Assistant (Build · gpt-5.2 · 2.3s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/container.md\n@@\n-This document specifies the container format for video segments.\n+This document specifies the container format for video data.\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/container.md
```
```

---

## Assistant (Build · gpt-5.2 · 5.6s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/memory-buffer.md\n@@\n-The memory buffer serves two purposes:\n+The memory buffer serves two purposes:\n@@\n-1. **Fast Proctor joins**: Proctors can immediately receive recent segments without disk I/O\n-2. **Network resilience**: Proctors with slower connections can catch up from buffered segments\n+1. **Fast Proctor joins**: Proctors can immediately receive recent fragments without disk I/O\n+2. **Network resilience**: Proctors with slower connections can catch up from buffered fragments\n@@\n- The spec does not mandate a specific eviction strategy. Implementations may use lazy garbage collection, periodic cleanup, or immediate removal. The only requirement is that segments older than the buffer window are not required to remain in memory.\n+ The spec does not mandate a specific eviction strategy. Implementations may use lazy garbage collection, periodic cleanup, or immediate removal. The only requirement is that fragments older than the buffer window are not required to remain in memory.\n@@\n-The initialization segment for each active Sentinel is cached separately from the media segment buffer.\n+The initialization segment for each active Sentinel is cached separately from the media fragment buffer.\n@@\n- - **Buffer window duration**: Longer window = more segments\n+ - **Buffer window duration**: Longer window = more fragments\n@@\n- - **Keyframe frequency**: More keyframes = more segments (each starting with a keyframe)\n+ - **Keyframe frequency**: More keyframes = more join fragments\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/memory-buffer.md
```
```

---

## Assistant (Build · gpt-5.2 · 3.9s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/transport.md\n@@\n | Scenario | Use WebSocket |\n |----------|---------------|\n | Live stream viewing | Yes |\n- | Joining a stream | Yes (get init + recent segments) |\n+ | Joining a stream | Yes (get init + recent fragments) |\n@@\n ### Sentinel Connection\n@@\n 1. Sentinel establishes WebSocket connection to Server\n 2. Sentinel sends registration/identification\n-3. Sentinel begins pushing segments\n+3. Sentinel begins pushing fragments\n@@\n ### Proctor Connection\n@@\n 3. Proctor subscribes to one or more Sentinel streams\n-4. Server pushes segments for subscribed streams\n+4. Server pushes fragments for subscribed streams\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/transport.md
```
```

---

## Assistant (Build · gpt-5.2 · 4.6s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/control-messages.md\n@@\n-Srv -> P : segment available\n+Srv -> P : join fragment available\n@@\n-No explicit response message is defined. The Proctor knows the keyframe request was fulfilled when a new segment arrives (which will start with a keyframe).\n+No explicit response message is defined. The Proctor knows the keyframe request was fulfilled when a new join fragment arrives.\n@@\n-No explicit response message is defined. The Server observes the framerate change via segment metadata.\n+No explicit response message is defined. The Server observes the framerate change via fragment metadata.\n@@\n | Message | Timing |\n |---------|--------|\n | Keyframe Request | Keyframe on next capture (up to 1/framerate delay) |\n-| FPS Change | Takes effect on next segment |\n+| FPS Change | Takes effect on next join fragment |\n@@\n | Condition | Handling |\n |-----------|----------|\n | Invalid framerate | Sentinel clamps to valid range |\n-| Sentinel busy | Sentinel applies on next segment boundary |\n+| Sentinel busy | Sentinel applies on next join fragment boundary |\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/control-messages.md
```
```

---

## Assistant (Build · gpt-5.2 · 5.4s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/metadata.md\n@@\n | Field | Location | Description |\n |-------|----------|-------------|\n-| Base decode time | `moof` → `tfdt` | Timestamp of first frame in segment |\n+| Base decode time | `moof` → `tfdt` | Timestamp of first frame in fragment |\n@@\n | Operation | Data Source |\n |-----------|-------------|\n-| Proctor joins stream | Memory (init segment + buffered segments) |\n-| New segment arrives | Memory (add to buffer, update metadata) |\n-| Proctor requests historical segment | Disk (metadata points to file path) |\n-\n-Update (terminology): the above operations apply to **fragments**.\n+| Proctor joins stream | Memory (init segment + buffered fragments) |\n+| New fragment arrives | Memory (add to buffer, update metadata) |\n+| Proctor requests historical fragment | Disk (metadata points to file path) |\n@@\n On Server restart:\n-1. Load session and segment metadata from database\n-2. Locate segment files on disk using stored paths\n+1. Load session and fragment metadata from database\n+2. Locate fragment files on disk using stored paths\n@@\n-The exact API for querying available segments is implementation-defined. The metadata structure above provides the necessary information.\n+The exact API for querying available fragments is implementation-defined. The metadata structure above provides the necessary information.\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/metadata.md
```
```

---

## Assistant (Build · gpt-5.2 · 4.0s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/disk-storage.md\n@@\n- - Keep all segments indefinitely\n- - Delete segments after a configured period\n+ - Keep all fragments indefinitely\n+ - Delete fragments after a configured period\n@@\n-Update (terminology): the above retention applies to fragment files.\n+ \n@@\n-{{< callout type=\"warning\" >}}\n-The transcoding/export workflow is out of scope for this spec. The stored segments are sufficient for playback via MSE or external tools.\n-{{< /callout >}}\n+{{< callout type=\"warning\" >}}\n+The transcoding/export workflow is out of scope for this spec. The stored fragments are sufficient for playback via MSE or external tools.\n+{{< /callout >}}\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/disk-storage.md
```
```

---

## Assistant (Build · gpt-5.2 · 4.9s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/encoding.md\n@@\n | Parameter | Value |\n |-----------|-------|\n | Minimum | 0.2 fps (1 frame per 5 seconds) |\n | Maximum | 5 fps |\n-| Variability | Can change between segments, fixed within a segment |\n+| Variability | Can change over time (see timestamps) |\n@@\n ### Variable Framerate Behavior\n \n-- Framerate is constant within a single segment\n-- Framerate can change at segment boundaries (triggered by FPS change request)\n+- Framerate can change when the Server requests it (see [Control Messages](../control-messages))\n - Each frame carries a timestamp for accurate playback timing\n - Players must use frame timestamps, not assume constant framerate\n@@\n ### Keyframe Rules\n@@\n | Rule | Description |\n |------|-------------|\n | On-demand | Sentinel must generate a keyframe when requested by Server |\n | Maximum interval | At least one keyframe every 20-30 seconds |\n-| On FPS change | New segment (starting with keyframe) when framerate changes |\n+| On FPS change | Next join fragment starts with a keyframe when framerate changes |\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/encoding.md
```
```

---

## Assistant (Build · gpt-5.2 · 4.3s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/join-flow.md\n@@\n When a Proctor wants to view a Sentinel's screen, it must:\n@@\n 2. Receive the initialization segment\n 3. Receive a join fragment (IDR entry point)\n 4. Continue receiving live fragments\n+\n+See [Terminology](../terminology) for the distinction between fragments (live delivery units) and join fragments (keyframe entry points).\n@@\n When a Proctor switches from one Sentinel to another:\n@@\n ### Unsubscribe from Current Stream\n \n-Proctor notifies Server to stop sending segments for the current Sentinel.\n+Proctor notifies Server to stop sending fragments for the current Sentinel.\n@@\n ### Join New Stream\n@@\n ### Reset MSE Buffer\n@@\n In the browser, the Proctor must:\n - Clear the existing `SourceBuffer`\n - Append the new initialization segment\n-- Begin appending segments from the new stream\n+- Begin appending fragments from the new stream\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/join-flow.md
```
```

---

## Assistant (Build · gpt-5.2 · 3.7s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/segments.md\n@@\n | Component | Description | Example |\n@@\n-| Extension | `.m4s` for media segments | |\n+| Extension | `.m4s` for fMP4 media fragments | |\n@@\n | Content | Location | Description |\n |---------|----------|-------------|\n | Decode timestamp | `moof` → `tfdt` | Absolute timestamp of first frame |\n-| Frame durations | `moof` → `trun` | Duration of each frame in segment |\n+| Frame durations | `moof` → `trun` | Duration of each frame in fragment |\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/segments.md
```
```

---

## Assistant (Build · gpt-5.2 · 2.1s)

```
Tool: grep

**Input:**
```json
{
  "pattern": "\\bsegment(s)?\\b",
  "path": "hugo/content/docs/reference/media-spec",
  "include": "*.md"
}
```
**Output:**
```
Found 38 matches
/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/segments.md:
  Line 87: The initialization segment uses a distinct name:
  Line 141:  | Session start | Sequence resets to 0, new initialization segment created |
  Line 146: If a Sentinel reconnects (new session), it generates a new initialization segment and restarts sequence numbering at 0. The Server treats this as a new stream.

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/join-flow.md:
  Line 12: 2. Receive the initialization segment
  Line 38: Srv -> P : init segment
  Line 85: The Server sends the cached initialization segment for the Sentinel's current session.
  Line 93: | `data` | bytes | Raw fMP4 init segment |
  Line 151: Srv -> P : init segment
  Line 191: - Append the new initialization segment
  Line 203: | No join fragment in buffer | Send init segment, request/await next join fragment |

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/encoding.md:
  Line 87: When FPS changes, a new join fragment must be produced (see [Fragments](../segments)).

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/disk-storage.md:
  Line 17: | Initialization segment | Yes | Raw fMP4 bytes |
  Line 63: | Initialization segment received | Write to `init.mp4` |
  Line 91: Each fragment file is a complete, valid fMP4 media fragment. Combined with the initialization segment, any fragment can be decoded independently when appended in order; a Proctor SHOULD start at a join fragment.
  Line 109: Provide initialization segment + media fragments to an fMP4-compatible player or MSE.
  Line 132: 1. Fetch the initialization segment

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/metadata.md:
  Line 56: | `initSegmentPath` | string | Path to initialization segment on disk |
  Line 75: This spec uses the term **fragment** for the live-delivery unit. The database may keep the naming `segment` if desired, but semantics must match this page.
  Line 122: | Proctor joins stream | Memory (init segment + buffered fragments) |
  Line 150: | Init segment bytes | No (stored as file on disk) |

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/transport.md:
  Line 60: Srv -> P : init segment
  Line 94: The initialization segment is sent separately, typically:
  Line 102: | `data` | bytes | Raw fMP4 initialization segment bytes |
  Line 135:  | `segments` | array | List of available fragment metadata |

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/memory-buffer.md:
  Line 31: | **Initialization segment** | The codec/resolution configuration for the session |
  Line 75: 1. Server sends the initialization segment
  Line 95: The initialization segment for each active Sentinel is cached separately from the media fragment buffer.
  Line 103: Since the initialization segment is small (typically a few KB) and required for every new Proctor, it remains in memory for the duration of the Sentinel's session.

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/container.md:
  Line 51: The initialization segment contains metadata required to configure the decoder. It does not contain any video frames.
  Line 89:  | Decodable with init | A fragment is decodable when appended after the initialization segment and appropriate preceding fragments |
  Line 91:  | Self-contained timing | Timestamps in `moof` are absolute (not relative to previous segment) |
  Line 99: The timescale from the initialization segment determines how timestamps map to wall-clock time. A common choice is 90000 (90kHz), allowing sub-millisecond precision.
  Line 110: Obtain the initialization segment for the target Sentinel from the Server.
  Line 114: Create a `MediaSource`, add a `SourceBuffer` with the appropriate MIME type, and append the initialization segment.

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/_index.md:
  Line 35: {{< card link="segments" title="Fragments" icon="collection" subtitle="Fragment cadence and join fragments" >}}
  Line 37: {{< card link="disk-storage" title="Disk Storage" icon="database" subtitle="Persistent segment storage" >}}

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/terminology.md:
  Line 15: | **Initialization segment** | fMP4 `ftyp` + `moov` bytes for the session. Contains codec config (SPS/PPS), resolution, timescale. Contains **no frames**. | Must be appended to MSE before any media data can be decoded.
  Line 39: It does **not** mean "start sending an empty 20s segment at t=0".
```
```

---

## Assistant (Build · gpt-5.2 · 3.4s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/container.md\n@@\n  | Requirement | Description |\n  |-------------|-------------|\n  | Decodable with init | A fragment is decodable when appended after the initialization segment and appropriate preceding fragments |\n  | Join points | A **join fragment** begins with an IDR frame and is a safe entry point for new viewers |\n- | Self-contained timing | Timestamps in `moof` are absolute (not relative to previous segment) |\n+ | Self-contained timing | Timestamps in `moof` are absolute (not relative to previous fragment) |\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/container.md
```
```

---

## Assistant (Build · gpt-5.2 · 4.2s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/metadata.md\n@@\n-This spec uses the term **fragment** for the live-delivery unit. The database may keep the naming `segment` if desired, but semantics must match this page.\n+This spec uses the term **fragment** for the live-delivery unit. If an implementation uses the word \"segment\" in database tables/fields, it MUST mean \"fragment\" as defined here.\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/metadata.md
```
```

---

## Assistant (Build · gpt-5.2 · 2.8s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/transport.md\n@@\n- | `segments` | array | List of available fragment metadata |\n+ | `segments` | array | List of available fragment metadata (field name is implementation-defined) |\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/transport.md
```
```

---

## Assistant (Build · gpt-5.2 · 2.2s)

```
Tool: grep

**Input:**
```json
{
  "pattern": "\\bSegments\\b",
  "path": "hugo/content/docs/reference/media-spec",
  "include": "*.md"
}
```
**Output:**
```
Found 4 matches
/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/transport.md:
  Line 127: ### Listing Available Segments

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/container.md:
  Line 15: - Segments can be played independently (with initialization data)
  Line 121: ### Append Media Segments

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/disk-storage.md:
  Line 103: ### Load Media Segments in Order
```
```

---

## Assistant (Build · gpt-5.2 · 2.9s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/transport.md\n@@\n-### Listing Available Segments\n+### Listing Available Fragments\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/transport.md
```
```

---

## Assistant (Build · gpt-5.2 · 3.7s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/container.md\n@@\n - Native support in browser Media Source Extensions (MSE)\n - No transcoding needed on Server or Proctor\n-- Segments can be played independently (with initialization data)\n+- Fragments can be appended incrementally (with initialization data)\n - Industry standard for adaptive streaming (DASH, HLS)\n@@\n-### Append Media Segments\n+### Append Media Fragments\n@@\n-As media fragments arrive, append them to the `SourceBuffer` in order.\n+As media fragments arrive, append them to the `SourceBuffer` in order.\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/container.md
```
```

---

## Assistant (Build · gpt-5.2 · 2.3s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/disk-storage.md\n@@\n-### Load Media Segments in Order\n+### Load Media Fragments in Order\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/disk-storage.md
```
```

---

## Assistant (Build · gpt-5.2 · 2.6s)

```
Tool: grep

**Input:**
```json
{
  "pattern": "\\bSegments\\b",
  "path": "hugo/content/docs/reference/media-spec",
  "include": "*.md"
}
```
**Output:**
```
No files found
```
```

---

## Assistant (Build · gpt-5.2 · 2.1s)

```
Tool: grep

**Input:**
```json
{
  "pattern": "\\bsegments\\b",
  "path": "hugo/content/docs/reference/media-spec",
  "include": "*.md"
}
```
**Output:**
```
Found 3 matches
/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/transport.md:
  Line 135:  | `segments` | array | List of available fragment metadata (field name is implementation-defined) |

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/encoding.md:
  Line 87: When FPS changes, a new join fragment must be produced (see [Fragments](../segments)).

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/_index.md:
  Line 35: {{< card link="segments" title="Fragments" icon="collection" subtitle="Fragment cadence and join fragments" >}}
```
```

---

## Assistant (Build · gpt-5.2 · 2.2s)

```
Tool: bash

**Input:**
```json
{
  "command": "git status --porcelain && git diff --stat",
  "description": "Show git status and diff stats"
}
```
**Output:**
```
 M hugo/content/docs/reference/media-spec/_index.md
 M hugo/content/docs/reference/media-spec/container.md
 M hugo/content/docs/reference/media-spec/control-messages.md
 M hugo/content/docs/reference/media-spec/disk-storage.md
 M hugo/content/docs/reference/media-spec/encoding.md
 M hugo/content/docs/reference/media-spec/join-flow.md
 M hugo/content/docs/reference/media-spec/memory-buffer.md
 M hugo/content/docs/reference/media-spec/metadata.md
 M hugo/content/docs/reference/media-spec/segments.md
 M hugo/content/docs/reference/media-spec/transport.md
?? hugo/content/docs/reference/media-spec/terminology.md
 hugo/content/docs/reference/media-spec/_index.md   |  19 ++--
 .../content/docs/reference/media-spec/container.md |  34 +++----
 .../docs/reference/media-spec/control-messages.md  |  28 +++---
 .../docs/reference/media-spec/disk-storage.md      |  36 +++----
 hugo/content/docs/reference/media-spec/encoding.md |   9 +-
 .../content/docs/reference/media-spec/join-flow.md |  60 ++++++------
 .../docs/reference/media-spec/memory-buffer.md     |  46 +++++----
 hugo/content/docs/reference/media-spec/metadata.md |  56 ++++++-----
 hugo/content/docs/reference/media-spec/segments.md | 103 ++++++++++++---------
 .../content/docs/reference/media-spec/transport.md |  94 ++++++++++---------
 10 files changed, 263 insertions(+), 222 deletions(-)

```
```

---

## Assistant (Build · gpt-5.2 · 10.8s)

Added clear, explicit terminology and rewired the spec to match it.

- Added `hugo/content/docs/reference/media-spec/terminology.md` (weighted first) defining: capture frame, encoded sample, IDR/keyframe, init segment, fragment, join fragment; includes the “keyframe interval != live latency” warning.
- Updated `hugo/content/docs/reference/media-spec/_index.md` to link `Terminology` first and renamed the “Segments” card to “Fragments”.
- Replaced “segment” with “fragment” across transport/join/buffer/storage/metadata/control docs where it previously implied “delivery unit”.
- Reworked `hugo/content/docs/reference/media-spec/segments.md` into “Fragments”: fragment vs join fragment, triggers, sequence, duration guidance, and explicit warning about the 20–30s being keyframe max interval (not fragment length).
- Updated `hugo/content/docs/reference/media-spec/memory-buffer.md` and `hugo/content/docs/reference/media-spec/join-flow.md` so joining starts from a join fragment (not “any segment”).

Changed/added files:
- Added: `hugo/content/docs/reference/media-spec/terminology.md`
- Updated: `hugo/content/docs/reference/media-spec/_index.md`
- Updated: `hugo/content/docs/reference/media-spec/segments.md`
- Updated: `hugo/content/docs/reference/media-spec/transport.md`
- Updated: `hugo/content/docs/reference/media-spec/join-flow.md`
- Updated: `hugo/content/docs/reference/media-spec/memory-buffer.md`
- Updated: `hugo/content/docs/reference/media-spec/container.md`
- Updated: `hugo/content/docs/reference/media-spec/encoding.md`
- Updated: `hugo/content/docs/reference/media-spec/control-messages.md`
- Updated: `hugo/content/docs/reference/media-spec/metadata.md`
- Updated: `hugo/content/docs/reference/media-spec/disk-storage.md`

Next step options:
1) I can run a quick hugo build/serve check to ensure navigation/order looks right.
2) If you want, I can make the transport/listing field names consistent (`segments` -> `fragments`) across the docs (right now it notes “implementation-defined”).

---

## User

yeah, move everything where segment is but fragment is meant to fragments.

---

## Assistant (Build · gpt-5.2 · 12.6s)

_Thinking:_



```
Tool: grep

**Input:**
```json
{
  "pattern": "\\bsegment(s)?\\b",
  "path": "hugo/content/docs/reference",
  "include": "*.md"
}
```
**Output:**
```
Found 37 matches
/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/disk-storage.md:
  Line 17: | Initialization segment | Yes | Raw fMP4 bytes |
  Line 63: | Initialization segment received | Write to `init.mp4` |
  Line 91: Each fragment file is a complete, valid fMP4 media fragment. Combined with the initialization segment, any fragment can be decoded independently when appended in order; a Proctor SHOULD start at a join fragment.
  Line 109: Provide initialization segment + media fragments to an fMP4-compatible player or MSE.
  Line 132: 1. Fetch the initialization segment

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/container.md:
  Line 51: The initialization segment contains metadata required to configure the decoder. It does not contain any video frames.
  Line 89:  | Decodable with init | A fragment is decodable when appended after the initialization segment and appropriate preceding fragments |
  Line 99: The timescale from the initialization segment determines how timestamps map to wall-clock time. A common choice is 90000 (90kHz), allowing sub-millisecond precision.
  Line 110: Obtain the initialization segment for the target Sentinel from the Server.
  Line 114: Create a `MediaSource`, add a `SourceBuffer` with the appropriate MIME type, and append the initialization segment.

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/transport.md:
  Line 60: Srv -> P : init segment
  Line 94: The initialization segment is sent separately, typically:
  Line 102: | `data` | bytes | Raw fMP4 initialization segment bytes |
  Line 135:  | `segments` | array | List of available fragment metadata (field name is implementation-defined) |

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/metadata.md:
  Line 56: | `initSegmentPath` | string | Path to initialization segment on disk |
  Line 75: This spec uses the term **fragment** for the live-delivery unit. If an implementation uses the word "segment" in database tables/fields, it MUST mean "fragment" as defined here.
  Line 122: | Proctor joins stream | Memory (init segment + buffered fragments) |
  Line 150: | Init segment bytes | No (stored as file on disk) |

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/segments.md:
  Line 87: The initialization segment uses a distinct name:
  Line 141:  | Session start | Sequence resets to 0, new initialization segment created |
  Line 146: If a Sentinel reconnects (new session), it generates a new initialization segment and restarts sequence numbering at 0. The Server treats this as a new stream.

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/join-flow.md:
  Line 12: 2. Receive the initialization segment
  Line 38: Srv -> P : init segment
  Line 85: The Server sends the cached initialization segment for the Sentinel's current session.
  Line 93: | `data` | bytes | Raw fMP4 init segment |
  Line 151: Srv -> P : init segment
  Line 191: - Append the new initialization segment
  Line 203: | No join fragment in buffer | Send init segment, request/await next join fragment |

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/encoding.md:
  Line 87: When FPS changes, a new join fragment must be produced (see [Fragments](../segments)).

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/memory-buffer.md:
  Line 31: | **Initialization segment** | The codec/resolution configuration for the session |
  Line 75: 1. Server sends the initialization segment
  Line 95: The initialization segment for each active Sentinel is cached separately from the media fragment buffer.
  Line 103: Since the initialization segment is small (typically a few KB) and required for every new Proctor, it remains in memory for the duration of the Sentinel's session.

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/_index.md:
  Line 35: {{< card link="segments" title="Fragments" icon="collection" subtitle="Fragment cadence and join fragments" >}}
  Line 37: {{< card link="disk-storage" title="Disk Storage" icon="database" subtitle="Persistent segment storage" >}}

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/terminology.md:
  Line 15: | **Initialization segment** | fMP4 `ftyp` + `moov` bytes for the session. Contains codec config (SPS/PPS), resolution, timescale. Contains **no frames**. | Must be appended to MSE before any media data can be decoded.
  Line 39: It does **not** mean "start sending an empty 20s segment at t=0".
```
```

---

## Assistant (Build · gpt-5.2 · 10.3s)

_Thinking:_



```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/transport.md\n@@\n- | `segments` | array | List of available fragment metadata (field name is implementation-defined) |\n+ | `fragments` | array | List of available fragment metadata |\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/transport.md
```
```

---

## Assistant (Build · gpt-5.2 · 3.3s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/metadata.md\n@@\n-This spec uses the term **fragment** for the live-delivery unit. If an implementation uses the word \"segment\" in database tables/fields, it MUST mean \"fragment\" as defined here.\n+This spec uses the term **fragment** for the live-delivery unit.\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/metadata.md
```
```

---

## Assistant (Build · gpt-5.2 · 3.8s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/transport.md\n@@\n-Proctors may need to query which fragments are available for a session. The response should include:\n+Proctors may need to query which fragments are available for a session. The response should include:\n@@\n- | `sentinelId` | string | Sentinel identifier |\n- | `sessionId` | string | Session identifier |\n- | `segments` | array | List of available fragment metadata |\n+ | `sentinelId` | string | Sentinel identifier |\n+ | `sessionId` | string | Session identifier |\n+ | `fragments` | array | List of available fragment metadata |\n*** End Patch"
}
```
**Error:**
```
Error: apply_patch verification failed: Error: Failed to find expected lines in /home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/transport.md:
 | `sentinelId` | string | Sentinel identifier |
 | `sessionId` | string | Session identifier |
 | `segments` | array | List of available fragment metadata |
```
```

---

## Assistant (Build · gpt-5.2 · 2.6s)

```
Tool: read

**Input:**
```json
{
  "filePath": "/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/transport.md",
  "offset": 110,
  "limit": 40
}
```
**Output:**
```
<file>
00111| 
00112| | Information | Description |
00113| |-------------|-------------|
00114| | `sentinelId` | Which Sentinel's stream |
00115| | `sessionId` | Which session |
00116|  | `sequence` | Which fragment (or range) |
00117| 
00118| ### Response
00119| 
00120| The HTTP response contains the raw fMP4 fragment bytes with appropriate content headers.
00121| 
00122| | Header | Value |
00123| |--------|-------|
00124| | `Content-Type` | `video/mp4` |
00125| | `Content-Length` | Size in bytes |
00126| 
00127| ### Listing Available Fragments
00128| 
00129| Proctors may need to query which fragments are available for a session. The response should include:
00130| 
00131|  | Field | Type | Description |
00132|  |-------|------|-------------|
00133|  | `sentinelId` | string | Sentinel identifier |
00134|  | `sessionId` | string | Session identifier |
00135|  | `fragments` | array | List of available fragment metadata |
00136| 
00137| Each entry:
00138| 
00139| | Field | Type | Description |
00140| |-------|------|-------------|
00141|  | `sequence` | integer | Fragment number |
00142|  | `startTime` | timestamp | When the fragment starts |
00143|  | `duration` | integer | Duration in milliseconds |
00144| 
00145| {{< callout type="info" >}}
00146| The exact HTTP endpoint structure is implementation-defined. The spec only defines what information must be available.
00147| {{< /callout >}}
00148| 
00149| ## Protocol Selection
00150| 

(File has more lines. Use 'offset' parameter to read beyond line 150)
</file>
```
```

---

## Assistant (Build · gpt-5.2 · 2.5s)

```
Tool: grep

**Input:**
```json
{
  "pattern": "`segments`",
  "path": "hugo/content/docs/reference/media-spec",
  "include": "*.md"
}
```
**Output:**
```
No files found
```
```

---

## Assistant (Build · gpt-5.2 · 3.9s)

```
Tool: grep

**Input:**
```json
{
  "pattern": "\\bsegment metadata\\b|\\bsegment\\s+sequence\\b|\\bsegment\\s+bytes\\b",
  "path": "hugo/content/docs/reference/media-spec",
  "include": "*.md"
}
```
**Output:**
```
Found 2 matches
/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/metadata.md:
  Line 150: | Init segment bytes | No (stored as file on disk) |

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/transport.md:
  Line 102: | `data` | bytes | Raw fMP4 initialization segment bytes |
```
```

---

## Assistant (Build · gpt-5.2 · 3.0s)

```
Tool: grep

**Input:**
```json
{
  "pattern": "\\bsegment\\b",
  "path": "hugo/content/docs/reference/media-spec",
  "include": "*.md"
}
```
**Output:**
```
Found 33 matches
/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/metadata.md:
  Line 56: | `initSegmentPath` | string | Path to initialization segment on disk |
  Line 122: | Proctor joins stream | Memory (init segment + buffered fragments) |
  Line 150: | Init segment bytes | No (stored as file on disk) |

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/transport.md:
  Line 60: Srv -> P : init segment
  Line 94: The initialization segment is sent separately, typically:
  Line 102: | `data` | bytes | Raw fMP4 initialization segment bytes |

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/disk-storage.md:
  Line 17: | Initialization segment | Yes | Raw fMP4 bytes |
  Line 63: | Initialization segment received | Write to `init.mp4` |
  Line 91: Each fragment file is a complete, valid fMP4 media fragment. Combined with the initialization segment, any fragment can be decoded independently when appended in order; a Proctor SHOULD start at a join fragment.
  Line 109: Provide initialization segment + media fragments to an fMP4-compatible player or MSE.
  Line 132: 1. Fetch the initialization segment

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/container.md:
  Line 51: The initialization segment contains metadata required to configure the decoder. It does not contain any video frames.
  Line 89:  | Decodable with init | A fragment is decodable when appended after the initialization segment and appropriate preceding fragments |
  Line 99: The timescale from the initialization segment determines how timestamps map to wall-clock time. A common choice is 90000 (90kHz), allowing sub-millisecond precision.
  Line 110: Obtain the initialization segment for the target Sentinel from the Server.
  Line 114: Create a `MediaSource`, add a `SourceBuffer` with the appropriate MIME type, and append the initialization segment.

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/segments.md:
  Line 87: The initialization segment uses a distinct name:
  Line 141:  | Session start | Sequence resets to 0, new initialization segment created |
  Line 146: If a Sentinel reconnects (new session), it generates a new initialization segment and restarts sequence numbering at 0. The Server treats this as a new stream.

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/join-flow.md:
  Line 12: 2. Receive the initialization segment
  Line 38: Srv -> P : init segment
  Line 85: The Server sends the cached initialization segment for the Sentinel's current session.
  Line 93: | `data` | bytes | Raw fMP4 init segment |
  Line 151: Srv -> P : init segment
  Line 191: - Append the new initialization segment
  Line 203: | No join fragment in buffer | Send init segment, request/await next join fragment |

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/memory-buffer.md:
  Line 31: | **Initialization segment** | The codec/resolution configuration for the session |
  Line 75: 1. Server sends the initialization segment
  Line 95: The initialization segment for each active Sentinel is cached separately from the media fragment buffer.
  Line 103: Since the initialization segment is small (typically a few KB) and required for every new Proctor, it remains in memory for the duration of the Sentinel's session.

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/_index.md:
  Line 37: {{< card link="disk-storage" title="Disk Storage" icon="database" subtitle="Persistent segment storage" >}}

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/terminology.md:
  Line 15: | **Initialization segment** | fMP4 `ftyp` + `moov` bytes for the session. Contains codec config (SPS/PPS), resolution, timescale. Contains **no frames**. | Must be appended to MSE before any media data can be decoded.
  Line 39: It does **not** mean "start sending an empty 20s segment at t=0".
```
```

---

## Assistant (Build · gpt-5.2 · 4.3s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/_index.md\n@@\n-{{< card link=\"disk-storage\" title=\"Disk Storage\" icon=\"database\" subtitle=\"Persistent segment storage\" >}}\n+{{< card link=\"disk-storage\" title=\"Disk Storage\" icon=\"database\" subtitle=\"Persistent fragment storage\" >}}\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/_index.md
```
```

---

## Assistant (Build · gpt-5.2 · 3.2s)

```
Tool: grep

**Input:**
```json
{
  "pattern": "\\bsegments\\b|`segments`",
  "path": "hugo/content/docs/reference/media-spec",
  "include": "*.md"
}
```
**Output:**
```
Found 2 matches
/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/_index.md:
  Line 35: {{< card link="segments" title="Fragments" icon="collection" subtitle="Fragment cadence and join fragments" >}}

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/encoding.md:
  Line 87: When FPS changes, a new join fragment must be produced (see [Fragments](../segments)).
```
```

---

## Assistant (Build · gpt-5.2 · 2.4s)

```
Tool: bash

**Input:**
```json
{
  "command": "git diff --stat && git diff",
  "description": "Show full diff for recent edits"
}
```
**Output:**
```
 hugo/content/docs/reference/media-spec/_index.md   |  21 +++--
 .../content/docs/reference/media-spec/container.md |  34 +++----
 .../docs/reference/media-spec/control-messages.md  |  28 +++---
 .../docs/reference/media-spec/disk-storage.md      |  36 +++----
 hugo/content/docs/reference/media-spec/encoding.md |   9 +-
 .../content/docs/reference/media-spec/join-flow.md |  60 ++++++------
 .../docs/reference/media-spec/memory-buffer.md     |  46 +++++----
 hugo/content/docs/reference/media-spec/metadata.md |  56 ++++++-----
 hugo/content/docs/reference/media-spec/segments.md | 103 ++++++++++++---------
 .../content/docs/reference/media-spec/transport.md |  94 ++++++++++---------
 10 files changed, 264 insertions(+), 223 deletions(-)
diff --git a/hugo/content/docs/reference/media-spec/_index.md b/hugo/content/docs/reference/media-spec/_index.md
index 55cb221..ef3b7f8 100644
--- a/hugo/content/docs/reference/media-spec/_index.md
+++ b/hugo/content/docs/reference/media-spec/_index.md
@@ -11,29 +11,30 @@ This specification defines how video is encoded, segmented, stored, and delivere
 | **Codec** | H.264 |
 | **Container** | Fragmented MP4 (fMP4) |
 | **Browser Delivery** | Media Source Extensions (MSE) |
-| **Segment Duration** | Variable (new segment on each keyframe) |
+| **Fragment Duration** | Variable, short (implementation choice for real-time delivery) |
 | **Keyframes** | On-demand + max 20-30s interval + on FPS change |
-| **Memory Buffer** | All segments from last 15-20 seconds (configurable) |
-| **Disk Storage** | All segments written as-is |
+| **Memory Buffer** | All fragments from last 15-20 seconds (configurable) |
+| **Disk Storage** | All fragments written as-is |
 | **Resolution** | Max 1080p, downscaled preserving aspect ratio |
-| **Framerate** | 1/5 fps to 5 fps, variable per session, fixed per segment |
-| **Live Transport** | WebSocket (server pushes segments) |
+| **Framerate** | 1/5 fps to 5 fps, variable over time |
+| **Live Transport** | WebSocket (server pushes fragments) |
 | **Historical Transport** | HTTP (Proctor fetches from disk) |
 
 ## Components
 
-- **Sentinel**: Captures screen, encodes video, sends segments to Server
-- **Server**: Receives segments, buffers in memory, writes to disk, relays to Proctors
-- **Proctor**: Receives segments, decodes via MSE, displays video
+- **Sentinel**: Captures screen, encodes video, sends fragments to Server
+- **Server**: Receives fragments, buffers in memory, writes to disk, relays to Proctors
+- **Proctor**: Receives fragments, decodes via MSE, displays video
 
 ## Documentation
 
 {{< cards >}}
+{{< card link="terminology" title="Terminology" icon="book-open" subtitle="Definitions: fragments vs keyframes vs init" >}}
 {{< card link="encoding" title="Encoding" icon="chip" subtitle="H.264 codec settings and framerate" >}}
 {{< card link="container" title="Container" icon="archive" subtitle="fMP4 structure and initialization" >}}
-{{< card link="segments" title="Segments" icon="collection" subtitle="Segment creation and naming" >}}
+{{< card link="segments" title="Fragments" icon="collection" subtitle="Fragment cadence and join fragments" >}}
 {{< card link="memory-buffer" title="Memory Buffer" icon="server" subtitle="Server-side buffering for live streams" >}}
-{{< card link="disk-storage" title="Disk Storage" icon="database" subtitle="Persistent segment storage" >}}
+{{< card link="disk-storage" title="Disk Storage" icon="database" subtitle="Persistent fragment storage" >}}
 {{< card link="metadata" title="Metadata" icon="document-text" subtitle="In-stream and application metadata" >}}
 {{< card link="transport" title="Transport" icon="switch-horizontal" subtitle="WebSocket and HTTP delivery" >}}
 {{< card link="join-flow" title="Join Flow" icon="login" subtitle="How Proctors join a stream" >}}
diff --git a/hugo/content/docs/reference/media-spec/container.md b/hugo/content/docs/reference/media-spec/container.md
index 78cd1f4..5ff66dc 100644
--- a/hugo/content/docs/reference/media-spec/container.md
+++ b/hugo/content/docs/reference/media-spec/container.md
@@ -2,7 +2,7 @@
 title: Container
 ---
 
-This document specifies the container format for video segments.
+This document specifies the container format for video data.
 
 ## Format: Fragmented MP4 (fMP4)
 
@@ -12,7 +12,7 @@ All video data is packaged in **Fragmented MP4** format. This is a variant of th
 
 - Native support in browser Media Source Extensions (MSE)
 - No transcoding needed on Server or Proctor
-- Segments can be played independently (with initialization data)
+- Fragments can be appended incrementally (with initialization data)
 - Industry standard for adaptive streaming (DASH, HLS)
 
 ## Structure Overview
@@ -22,7 +22,7 @@ An fMP4 stream consists of two types of data:
 | Type | Purpose | When Sent |
 |------|---------|-----------|
 | **Initialization Segment** | Contains codec configuration, resolution, timescale | Once per session, on Proctor join |
-| **Media Segment** | Contains actual video frames and timing | Continuously during streaming |
+ | **Media Fragment** | Contains encoded samples (frames) and timing (`moof` + `mdat`) | Continuously during streaming |
 
 ```
 ┌─────────────────────────┐
@@ -32,13 +32,13 @@ An fMP4 stream consists of two types of data:
            │
            ▼
 ┌─────────────────────────┐
-│    Media Segment 1      │  ← Starts with keyframe
+│    Media Fragment 1     │  ← May start with keyframe
 │  (moof + mdat boxes)    │
 └─────────────────────────┘
-           │
-           ▼
+            │
+            ▼
 ┌─────────────────────────┐
-│    Media Segment 2      │  ← Starts with keyframe
+│    Media Fragment 2     │  ← May start with keyframe
 │  (moof + mdat boxes)    │
 └─────────────────────────┘
            │
@@ -71,9 +71,9 @@ The initialization segment contains metadata required to configure the decoder.
 - Server caches in memory for each active Sentinel
 - Sent to Proctor on stream join request
 
-## Media Segments
+## Media Fragments
 
-Each media segment contains one or more video frames packaged for streaming.
+Each media fragment contains one or more encoded samples (video frames) packaged for streaming.
 
 ### Contents
 
@@ -84,12 +84,12 @@ Each media segment contains one or more video frames packaged for streaming.
 
 ### Requirements
 
-| Requirement | Description |
-|-------------|-------------|
-| Starts with keyframe | Every media segment must begin with an IDR frame |
-| Self-contained timing | Timestamps in `moof` are absolute (not relative to previous segment) |
-| Variable duration | Segments can have different durations |
-| Fixed framerate per segment | Framerate is constant within a segment |
+ | Requirement | Description |
+ |-------------|-------------|
+ | Decodable with init | A fragment is decodable when appended after the initialization segment and appropriate preceding fragments |
+ | Join points | A **join fragment** begins with an IDR frame and is a safe entry point for new viewers |
+ | Self-contained timing | Timestamps in `moof` are absolute (not relative to previous fragment) |
+ | Variable duration | Fragments can have different durations |
 
 ### Timing Information
 
@@ -118,9 +118,9 @@ Create a `MediaSource`, add a `SourceBuffer` with the appropriate MIME type, and
 "video/mp4; codecs=\"avc1.42E01F\""
 ```
 
-### Append Media Segments
+### Append Media Fragments
 
-As media segments arrive, append them to the `SourceBuffer` in order.
+As media fragments arrive, append them to the `SourceBuffer` in order.
 
 ### Handle Playback
 
diff --git a/hugo/content/docs/reference/media-spec/control-messages.md b/hugo/content/docs/reference/media-spec/control-messages.md
index 00f239c..0dc215f 100644
--- a/hugo/content/docs/reference/media-spec/control-messages.md
+++ b/hugo/content/docs/reference/media-spec/control-messages.md
@@ -39,10 +39,10 @@ activate S
 
 S -> S : mark next frame\nas keyframe
 
-S -> Srv : segment\n(starts with keyframe)
+ S -> Srv : join fragment\n(starts with keyframe)
 deactivate S
 
-Srv -> P : segment available
+Srv -> P : join fragment available
 deactivate Srv
 
 @enduml
@@ -82,8 +82,8 @@ Example:
 When the Sentinel receives a keyframe request:
 
 1. The next captured frame becomes an IDR frame (keyframe)
-2. A new segment begins with this keyframe
-3. The segment is sent to the Server as usual
+2. A new join fragment begins with this keyframe
+3. The join fragment is sent to the Server as usual
 
 {{< callout type="info" >}}
 The keyframe is generated on the **next capture**, not immediately. The delay depends on the current framerate. At 5 FPS, maximum delay is 200ms. At 1/5 FPS, maximum delay is 5 seconds.
@@ -91,7 +91,7 @@ The keyframe is generated on the **next capture**, not immediately. The delay de
 
 ### Response
 
-No explicit response message is defined. The Proctor knows the keyframe request was fulfilled when a new segment arrives (which will start with a keyframe).
+No explicit response message is defined. The Proctor knows the keyframe request was fulfilled when a new join fragment arrives.
 
 ## FPS Change Request
 
@@ -111,13 +111,13 @@ participant "Sentinel" as S
 Srv -> S : fps change request\n(newFps: 2)
 activate S
 
-S -> S : finish current segment
+ S -> S : finish current fragment
 
 S -> S : apply new framerate
 
-S -> Srv : segment\n(at old fps)
+ S -> Srv : fragment\n(at old fps)
 
-S -> Srv : segment\n(at new fps, starts with keyframe)
+ S -> Srv : join fragment\n(at new fps, starts with keyframe)
 deactivate S
 
 @enduml
@@ -147,11 +147,11 @@ When the Sentinel receives an FPS change request:
 
 ### Finish Current Segment
 
-Complete and send the current segment with the old framerate.
+Complete and send the current fragment with the old framerate.
 
 ### Generate Keyframe
 
-The next frame is an IDR frame, starting a new segment.
+The next frame is an IDR frame, starting a new join fragment.
 
 ### Apply New Framerate
 
@@ -159,7 +159,7 @@ Begin capturing at the new framerate.
 
 ### Continue Streaming
 
-New segments are sent at the new framerate.
+New fragments are sent at the new framerate.
 
 {{% /steps %}}
 
@@ -174,7 +174,7 @@ If the requested framerate is outside bounds, the Sentinel clamps it and applies
 
 ### Response
 
-No explicit response message is defined. The Server observes the framerate change via segment metadata.
+No explicit response message is defined. The Server observes the framerate change via fragment metadata.
 
 ## Server-Initiated vs Proctor-Initiated
 
@@ -194,7 +194,7 @@ The Proctor cannot directly request an FPS change. FPS changes are a Server-side
 | Message | Timing |
 |---------|--------|
 | Keyframe Request | Keyframe on next capture (up to 1/framerate delay) |
-| FPS Change | Takes effect on next segment |
+| FPS Change | Takes effect on next join fragment |
 
 ## Error Handling
 
@@ -211,7 +211,7 @@ The Proctor cannot directly request an FPS change. FPS changes are a Server-side
 | Condition | Handling |
 |-----------|----------|
 | Invalid framerate | Sentinel clamps to valid range |
-| Sentinel busy | Sentinel applies on next segment boundary |
+| Sentinel busy | Sentinel applies on next join fragment boundary |
 
 ## Message Type Summary
 
diff --git a/hugo/content/docs/reference/media-spec/disk-storage.md b/hugo/content/docs/reference/media-spec/disk-storage.md
index 9892e20..1644ccd 100644
--- a/hugo/content/docs/reference/media-spec/disk-storage.md
+++ b/hugo/content/docs/reference/media-spec/disk-storage.md
@@ -2,23 +2,25 @@
 title: Disk Storage
 ---
 
-This document specifies how segments are persisted to disk.
+This document specifies how fragments are persisted to disk.
+
+See [Terminology](../terminology).
 
 ## Storage Principle
 
-The Server writes segments to disk **as-is** with no processing, transcoding, or modification. The bytes received from the Sentinel are the exact bytes written to disk.
+The Server writes fragments to disk **as-is** with no processing, transcoding, or modification. The bytes received from the Sentinel are the exact bytes written to disk.
 
 ## What is Stored
 
 | Item | Stored | Format |
 |------|--------|--------|
 | Initialization segment | Yes | Raw fMP4 bytes |
-| Media segments | Yes | Raw fMP4 bytes |
+ | Media fragments | Yes | Raw fMP4 bytes |
 | Metadata | Yes (separately) | See [Metadata](../metadata) |
 
 ## File Organization
 
-Segments are organized on disk by Sentinel and session.
+Fragments are organized on disk by Sentinel and session.
 
 ### Directory Structure
 
@@ -54,15 +56,15 @@ Segments are organized on disk by Sentinel and session.
 
 ## Write Timing
 
-Segments are written to disk immediately upon receipt from the Sentinel.
+Fragments are written to disk immediately upon receipt from the Sentinel.
 
 | Event | Action |
 |-------|--------|
 | Initialization segment received | Write to `init.mp4` |
-| Media segment received | Write to `{sequence}.m4s` |
+ | Media fragment received | Write to `{sequence}.m4s` |
 
 {{< callout type="info" >}}
-Writing happens in parallel with adding the segment to the memory buffer. The live streaming path (memory) and archival path (disk) are independent.
+Writing happens in parallel with adding the fragment to the memory buffer. The live streaming path (memory) and archival path (disk) are independent.
 {{< /callout >}}
 
 ## No Server Processing
@@ -86,7 +88,7 @@ The Server's role is purely:
 
 ## File Integrity
 
-Each segment file is a complete, valid fMP4 media segment. Combined with the initialization segment, any media segment can be decoded independently.
+Each fragment file is a complete, valid fMP4 media fragment. Combined with the initialization segment, any fragment can be decoded independently when appended in order; a Proctor SHOULD start at a join fragment.
 
 ### Playback from Disk
 
@@ -98,13 +100,13 @@ To play back stored video:
 
 Read `init.mp4` for the session.
 
-### Load Media Segments in Order
+### Load Media Fragments in Order
 
-Read segment files in sequence order: `000000.m4s`, `000001.m4s`, etc.
+Read fragment files in sequence order: `000000.m4s`, `000001.m4s`, etc.
 
 ### Concatenate and Play
 
-Provide initialization segment + media segments to an fMP4-compatible player or MSE.
+Provide initialization segment + media fragments to an fMP4-compatible player or MSE.
 
 {{% /steps %}}
 
@@ -112,25 +114,27 @@ Provide initialization segment + media segments to an fMP4-compatible player or
 
 The spec does not mandate a retention policy. Implementations may:
 
-- Keep all segments indefinitely
-- Delete segments after a configured period
+ - Keep all fragments indefinitely
+ - Delete fragments after a configured period
 - Delete entire sessions based on policy
 - Provide manual or automated cleanup
 
+ 
+
 ## Later Viewing
 
-Stored segments can be retrieved via HTTP for later viewing. See [Transport](../transport) for details on historical segment access.
+Stored fragments can be retrieved via HTTP for later viewing. See [Transport](../transport) for details on historical fragment access.
 
 ### Transcoding for Export
 
 For exporting video to a standard format (e.g., a single MP4 file), a separate **transcoding client** can:
 
 1. Fetch the initialization segment
-2. Fetch all media segments for a session
+2. Fetch all media fragments for a session
 3. Concatenate into a single playable file
 
 This transcoding happens outside the Server (in the Proctor browser or a dedicated tool), maintaining the principle that the Server does no video processing.
 
 {{< callout type="warning" >}}
-The transcoding/export workflow is out of scope for this spec. The stored segments are sufficient for playback via MSE or external tools.
+The transcoding/export workflow is out of scope for this spec. The stored fragments are sufficient for playback via MSE or external tools.
 {{< /callout >}}
diff --git a/hugo/content/docs/reference/media-spec/encoding.md b/hugo/content/docs/reference/media-spec/encoding.md
index e8efbd7..0804972 100644
--- a/hugo/content/docs/reference/media-spec/encoding.md
+++ b/hugo/content/docs/reference/media-spec/encoding.md
@@ -69,12 +69,11 @@ The Sentinel must downscale captured frames to fit within 1920x1080 while preser
 |-----------|-------|
 | Minimum | 0.2 fps (1 frame per 5 seconds) |
 | Maximum | 5 fps |
-| Variability | Can change between segments, fixed within a segment |
+| Variability | Can change over time (see timestamps) |
 
 ### Variable Framerate Behavior
 
-- Framerate is constant within a single segment
-- Framerate can change at segment boundaries (triggered by FPS change request)
+- Framerate can change when the Server requests it (see [Control Messages](../control-messages))
 - Each frame carries a timestamp for accurate playback timing
 - Players must use frame timestamps, not assume constant framerate
 
@@ -85,7 +84,7 @@ The Server may request a framerate change from the Sentinel. Common reasons:
 - Network congestion detected
 - Administrative policy change
 
-When FPS changes, a new segment must begin (see [Segments](../segments)).
+When FPS changes, a new join fragment must be produced (see [Fragments](../segments)).
 
 ## Keyframes (I-Frames)
 
@@ -97,7 +96,7 @@ Keyframes are complete frames that can be decoded independently without referenc
 |------|-------------|
 | On-demand | Sentinel must generate a keyframe when requested by Server |
 | Maximum interval | At least one keyframe every 20-30 seconds |
-| On FPS change | New segment (starting with keyframe) when framerate changes |
+| On FPS change | Next join fragment starts with a keyframe when framerate changes |
 
 ### Why On-Demand Keyframes
 
diff --git a/hugo/content/docs/reference/media-spec/join-flow.md b/hugo/content/docs/reference/media-spec/join-flow.md
index aefc4d6..31855a0 100644
--- a/hugo/content/docs/reference/media-spec/join-flow.md
+++ b/hugo/content/docs/reference/media-spec/join-flow.md
@@ -10,8 +10,10 @@ When a Proctor wants to view a Sentinel's screen, it must:
 
 1. Request to join the stream
 2. Receive the initialization segment
-3. Receive a keyframe segment (join point)
-4. Continue receiving live segments
+3. Receive a join fragment (IDR entry point)
+4. Continue receiving live fragments
+
+See [Terminology](../terminology) for the distinction between fragments (live delivery units) and join fragments (keyframe entry points).
 
 ## Join Flow Diagram
 
@@ -35,13 +37,13 @@ Srv -> Srv : lookup Sentinel\nin memory buffer
 
 Srv -> P : init segment
 
-Srv -> P : keyframe segment\n(oldest in buffer or latest)
+Srv -> P : join fragment\n(most recent in buffer)
 
 == Live Streaming ==
 
-loop as segments arrive
-  S -> Srv : new segment
-  Srv -> P : new segment
+loop as fragments arrive
+  S -> Srv : new fragment
+  Srv -> P : new fragment
 end
 
 deactivate Srv
@@ -90,36 +92,36 @@ The Server sends the cached initialization segment for the Sentinel's current se
 | `sessionId` | string | Current session identifier |
 | `data` | bytes | Raw fMP4 init segment |
 
-### Server Sends Keyframe Segment
+### Server Sends Join Fragment
 
-The Server selects a segment from the memory buffer and sends it.
+The Server selects a join fragment from the memory buffer and sends it.
 
 **Selection strategy:**
 
-| `startFrom` | Segment Selected |
+| `startFrom` | Join Fragment Selected |
 |-------------|------------------|
-| `"oldest"` | Oldest segment in buffer (maximum catch-up time) |
-| `"latest"` | Most recent segment (lowest latency) |
+| `"oldest"` | Oldest join fragment in buffer (maximum catch-up time) |
+| `"latest"` | Most recent join fragment (lowest latency) |
 
-The selected segment is guaranteed to start with a keyframe (all segments do).
+The selected fragment is guaranteed to start with an IDR keyframe (join fragment).
 
 **Required fields:**
 
 | Field | Type | Description |
 |-------|------|-------------|
 | `sentinelId` | string | Identifies the stream |
-| `sequence` | integer | Segment sequence number |
-| `data` | bytes | Raw fMP4 media segment |
+| `sequence` | integer | Fragment sequence number |
+| `data` | bytes | Raw fMP4 fragment (`moof` + `mdat`) |
 
-### Server Continues Pushing Segments
+### Server Continues Pushing Fragments
 
-From this point, the Server pushes new segments to the Proctor as they arrive from the Sentinel.
+From this point, the Server pushes new fragments to the Proctor as they arrive from the Sentinel.
 
 {{% /steps %}}
 
 ## On-Demand Keyframe for Fast Join
 
-If the Proctor wants to minimize join latency (not wait for the next segment), it can request an on-demand keyframe before or during the join.
+If the Proctor wants to minimize join latency (not wait for the next join fragment), it can request an on-demand keyframe before or during the join.
 
 See [Control Messages](../control-messages) for the keyframe request flow.
 
@@ -140,20 +142,20 @@ Srv -> S : request keyframe
 
 S -> S : generate keyframe\non next capture
 
-S -> Srv : new segment\n(starts with keyframe)
+S -> Srv : new join fragment\n(starts with keyframe)
 
 == Join Request ==
 
 P -> Srv : request join stream\n(sentinelId)
 
 Srv -> P : init segment
-Srv -> P : keyframe segment\n(the just-created one)
+Srv -> P : join fragment\n(the just-created one)
 
 == Live Streaming ==
 
-loop as segments arrive
-  S -> Srv : new segment
-  Srv -> P : new segment
+loop as fragments arrive
+  S -> Srv : new fragment
+  Srv -> P : new fragment
 end
 
 @enduml
@@ -176,7 +178,7 @@ When a Proctor switches from one Sentinel to another:
 
 ### Unsubscribe from Current Stream
 
-Proctor notifies Server to stop sending segments for the current Sentinel.
+Proctor notifies Server to stop sending fragments for the current Sentinel.
 
 ### Join New Stream
 
@@ -187,7 +189,7 @@ Follow the standard join flow for the new Sentinel.
 In the browser, the Proctor must:
 - Clear the existing `SourceBuffer`
 - Append the new initialization segment
-- Begin appending segments from the new stream
+- Begin appending fragments from the new stream
 
 {{% /steps %}}
 
@@ -198,17 +200,21 @@ In the browser, the Proctor must:
 | Sentinel not found | Error: unknown Sentinel |
 | Sentinel not streaming | Error: Sentinel offline |
 | Authorization failure | Error: not authorized |
-| No segments in buffer | Send init segment, wait for first segment |
+| No join fragment in buffer | Send init segment, request/await next join fragment |
 
 ## Latency Considerations
 
 | Factor | Impact on Join Latency |
 |--------|------------------------|
-| Buffer has segments | Immediate join (send from buffer) |
+| Buffer has join fragments | Immediate join (send from buffer) |
 | On-demand keyframe requested | Wait for next capture cycle |
-| No keyframe, must wait | Up to max keyframe interval (20-30s) |
+| No join fragment available | Up to max keyframe interval (20-30s) unless on-demand keyframe is used |
 
 For lowest latency joins:
 1. Use on-demand keyframe requests
 2. Use `startFrom: "latest"` 
 3. Pre-fetch keyframes for likely next streams
+
+{{< callout type="warning" >}}
+"20-30 seconds" is the maximum keyframe interval (join fragment spacing). Live video is still delivered continuously as fragments.
+{{< /callout >}}
diff --git a/hugo/content/docs/reference/media-spec/memory-buffer.md b/hugo/content/docs/reference/media-spec/memory-buffer.md
index c2d9a86..68c45e8 100644
--- a/hugo/content/docs/reference/media-spec/memory-buffer.md
+++ b/hugo/content/docs/reference/media-spec/memory-buffer.md
@@ -2,21 +2,23 @@
 title: Memory Buffer
 ---
 
-This document specifies how the Server buffers segments in memory for live streaming.
+This document specifies how the Server buffers **fragments** in memory for live streaming.
+
+See [Terminology](../terminology) for definitions.
 
 ## Purpose
 
 The memory buffer serves two purposes:
 
-1. **Fast Proctor joins**: Proctors can immediately receive recent segments without disk I/O
-2. **Network resilience**: Proctors with slower connections can catch up from buffered segments
+1. **Fast Proctor joins**: Proctors can immediately receive recent fragments without disk I/O
+2. **Network resilience**: Proctors with slower connections can catch up from buffered fragments
 
 ## Buffer Requirements
 
 | Parameter | Value | Notes |
 |-----------|-------|-------|
 | Buffer window | 15-20 seconds | Configurable |
-| Contents | All segments with start time within the window | |
+| Contents | All fragments with start time within the window | |
 | Scope | Per Sentinel | Each Sentinel has its own buffer |
 | Storage | Memory only | No disk I/O for live streaming |
 
@@ -27,15 +29,16 @@ For each active Sentinel, the Server maintains in memory:
 | Item | Description |
 |------|-------------|
 | **Initialization segment** | The codec/resolution configuration for the session |
-| **Recent media segments** | All segments whose start timestamp falls within the buffer window |
-| **Segment metadata** | See [Metadata](../metadata) for details |
+| **Recent fragments** | All fragments whose start timestamp falls within the buffer window |
+| **Fragment metadata** | See [Metadata](../metadata) for details |
+| **Join fragment index** | Fast lookup of the most recent join fragment(s) in the buffer |
 
 ```
 Buffer Window (15-20 seconds)
 ◄──────────────────────────────────────────────►
 
 ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌───
-│ Seg N-3│ │ Seg N-2│ │ Seg N-1│ │ Seg N  │ │ ...
+│ Frag N-3│ │ Frag N-2│ │ Frag N-1│ │ Frag N  │ │ ...
 └────────┘ └────────┘ └────────┘ └────────┘ └───
      │          │          │          │
      └──────────┴──────────┴──────────┴── All in memory
@@ -47,28 +50,31 @@ Buffer Window (15-20 seconds)
 
 ## Eviction
 
-Segments are evicted from the buffer when they fall outside the buffer window.
+Fragments are evicted from the buffer when they fall outside the buffer window.
 
 | Behavior | Description |
 |----------|-------------|
-| Trigger | Segment's start timestamp is older than `now - buffer_window` |
-| Action | Remove from memory buffer |
-| Disk impact | None (segment was already written to disk when received) |
-| Method | Garbage collection or explicit removal (implementation choice) |
+ | Trigger | Fragment's start timestamp is older than `now - buffer_window` |
+ | Action | Remove from memory buffer |
+ | Disk impact | None (fragment was already written to disk when received) |
+ | Method | Garbage collection or explicit removal (implementation choice) |
 
 {{< callout type="info" >}}
-The spec does not mandate a specific eviction strategy. Implementations may use lazy garbage collection, periodic cleanup, or immediate removal. The only requirement is that segments older than the buffer window are not required to remain in memory.
+ The spec does not mandate a specific eviction strategy. Implementations may use lazy garbage collection, periodic cleanup, or immediate removal. The only requirement is that fragments older than the buffer window are not required to remain in memory.
 {{< /callout >}}
 
 ## Join Points
 
-Every segment in the buffer is a valid **join point** because every segment starts with a keyframe.
+Not every fragment is a safe join point.
+
+- A **join fragment** starts with an IDR keyframe.
+- A Proctor SHOULD begin playback from a join fragment.
 
 When a Proctor joins a stream:
 
 1. Server sends the initialization segment
-2. Server selects a segment from the buffer (typically the oldest to maximize catch-up time, or newest for lowest latency)
-3. Server sends that segment and all subsequent segments
+2. Server selects a join fragment from the buffer (typically the most recent for lowest latency)
+3. Server sends that join fragment and all subsequent fragments
 
 ### Buffer Depth and Network Quality
 
@@ -82,11 +88,11 @@ The buffer window (15-20 seconds) accommodates Proctors with varying network con
 
 If a Proctor falls further behind than the buffer window, they must either:
 - Skip forward to live (losing some video)
-- Request historical segments via HTTP (see [Transport](../transport))
+- Request historical fragments via HTTP (see [Transport](../transport))
 
 ## Initialization Segment Caching
 
-The initialization segment for each active Sentinel is cached separately from the media segment buffer.
+The initialization segment for each active Sentinel is cached separately from the media fragment buffer.
 
 | Property | Value |
 |----------|-------|
@@ -100,10 +106,10 @@ Since the initialization segment is small (typically a few KB) and required for
 
 The memory footprint per Sentinel depends on:
 
-- **Buffer window duration**: Longer window = more segments
+ - **Buffer window duration**: Longer window = more fragments
 - **Framerate**: Higher FPS = more data per second
 - **Resolution**: Higher resolution = larger frames
-- **Keyframe frequency**: More keyframes = more segments (each starting with a keyframe)
+ - **Keyframe frequency**: More keyframes = more join fragments
 
 ### Rough Estimates
 
diff --git a/hugo/content/docs/reference/media-spec/metadata.md b/hugo/content/docs/reference/media-spec/metadata.md
index 6230596..351aca2 100644
--- a/hugo/content/docs/reference/media-spec/metadata.md
+++ b/hugo/content/docs/reference/media-spec/metadata.md
@@ -2,7 +2,9 @@
 title: Metadata
 ---
 
-This document specifies the metadata associated with video segments, where it is stored, and how it is synchronized.
+This document specifies the metadata associated with video fragments, where it is stored, and how it is synchronized.
+
+See [Terminology](../terminology) for the distinction between fragments and join fragments.
 
 ## Metadata Locations
 
@@ -27,9 +29,11 @@ This metadata is embedded in the fMP4 container by the Sentinel encoder. The Ser
 
 ### Media Segment
 
+In this spec, this refers to a media **fragment** (`moof` + `mdat`).
+
 | Field | Location | Description |
 |-------|----------|-------------|
-| Base decode time | `moof` → `tfdt` | Timestamp of first frame in segment |
+| Base decode time | `moof` → `tfdt` | Timestamp of first frame in fragment |
 | Sample durations | `moof` → `trun` | Duration of each frame |
 | Sample sizes | `moof` → `trun` | Byte size of each frame |
 
@@ -68,13 +72,16 @@ Example:
 
 ### Per-Segment Metadata
 
+This spec uses the term **fragment** for the live-delivery unit.
+
 | Field | Type | Description |
 |-------|------|-------------|
-| `sequence` | integer | Segment sequence number |
+| `sequence` | integer | Fragment sequence number |
 | `startTime` | timestamp | Wall-clock time of first frame |
 | `duration` | integer | Duration in milliseconds |
-| `framerate` | number | Frames per second for this segment |
-| `filePath` | string | Path to segment file on disk |
+| `framerate` | number | Frames per second during this fragment |
+| `filePath` | string | Path to fragment file on disk |
+| `isJoin` | boolean | True if this fragment starts with an IDR keyframe |
 
 Example:
 
@@ -84,7 +91,8 @@ Example:
   "startTime": "2026-02-05T14:35:42.000Z",
   "duration": 4800,
   "framerate": 5,
-  "filePath": "/var/franklyn/video/sentinel-a1b2c3/2026-02-05T14-30-00Z/000142.m4s"
+  "filePath": "/var/franklyn/video/sentinel-a1b2c3/2026-02-05T14-30-00Z/000142.m4s",
+  "isJoin": false
 }
 ```
 
@@ -100,10 +108,10 @@ Server Memory
 │   └── {sentinelId}
 │       ├── Session Metadata
 │       ├── Init Segment (bytes)
-│       └── Segment Buffer
-│           ├── Segment 140: { metadata, bytes }
-│           ├── Segment 141: { metadata, bytes }
-│           ├── Segment 142: { metadata, bytes }
+│       └── Fragment Buffer
+│           ├── Fragment 140: { metadata, bytes }
+│           ├── Fragment 141: { metadata, bytes }
+│           ├── Fragment 142: { metadata, bytes }
 │           └── ...
 ```
 
@@ -111,9 +119,9 @@ Server Memory
 
 | Operation | Data Source |
 |-----------|-------------|
-| Proctor joins stream | Memory (init segment + buffered segments) |
-| New segment arrives | Memory (add to buffer, update metadata) |
-| Proctor requests historical segment | Disk (metadata points to file path) |
+| Proctor joins stream | Memory (init segment + buffered fragments) |
+| New fragment arrives | Memory (add to buffer, update metadata) |
+| Proctor requests historical fragment | Disk (metadata points to file path) |
 
 ## Database Persistence
 
@@ -124,7 +132,7 @@ Application metadata is periodically synced to the database for durability.
 | Aspect | Behavior |
 |--------|----------|
 | Trigger | Periodic (e.g., every 5-10 seconds) |
-| Scope | All new/updated segment metadata since last sync |
+| Scope | All new/updated fragment metadata since last sync |
 | Blocking | Non-blocking (sync happens asynchronously) |
 | Failure handling | Retry on next sync interval |
 
@@ -137,27 +145,27 @@ The sync interval is an implementation detail. The key requirement is that real-
 | Data | Persisted |
 |------|-----------|
 | Session metadata | Yes |
-| Segment metadata | Yes |
-| Segment bytes | No (stored as files on disk) |
+| Fragment metadata | Yes |
+| Fragment bytes | No (stored as files on disk) |
 | Init segment bytes | No (stored as file on disk) |
 
 ### Recovery
 
 On Server restart:
-1. Load session and segment metadata from database
-2. Locate segment files on disk using stored paths
+1. Load session and fragment metadata from database
+2. Locate fragment files on disk using stored paths
 3. Resume streaming for any Sentinels that reconnect
 
 ## Metadata for Historical Access
 
-When a Proctor requests historical segments (via HTTP), the Server uses the persisted metadata to:
+When a Proctor requests historical fragments (via HTTP), the Server uses the persisted metadata to:
 
-1. Identify which segments exist for a Sentinel/session
-2. Locate the segment files on disk
-3. Serve the requested segment bytes
+1. Identify which fragments exist for a Sentinel/session
+2. Locate the fragment files on disk
+3. Serve the requested fragment bytes
 
 The Proctor needs to know:
 - `sentinelId` and `sessionId` to identify the stream
-- `sequence` to request specific segments
+- `sequence` to request specific fragments
 
-The exact API for querying available segments is implementation-defined. The metadata structure above provides the necessary information.
+The exact API for querying available fragments is implementation-defined. The metadata structure above provides the necessary information.
diff --git a/hugo/content/docs/reference/media-spec/segments.md b/hugo/content/docs/reference/media-spec/segments.md
index 609a870..f1aa900 100644
--- a/hugo/content/docs/reference/media-spec/segments.md
+++ b/hugo/content/docs/reference/media-spec/segments.md
@@ -1,55 +1,66 @@
 ---
-title: Segments
+title: Fragments
 ---
 
-This document specifies when segments are created, how they are named, and their structure.
+This document specifies how **fragments** are created, how they are named, and how **join fragments** (keyframe entry points) work.
 
-## Segment Definition
+See [Terminology](../terminology) for definitions.
 
-A **segment** is a single fMP4 media segment containing one or more video frames. Each segment:
+## Fragment Definition
 
-- Starts with a keyframe (IDR frame)
-- Has a fixed framerate throughout
-- Has variable duration
-- Is independently decodable (with the initialization segment)
+A **fragment** is a single fMP4 media unit (`moof` + `mdat`) containing one or more encoded samples. Fragments are the unit of live delivery and MSE appends.
 
-## Segment Creation Triggers
+Fragments:
 
-A new segment is created when any of the following occur:
+- Are produced continuously during streaming
+- Are appended to MSE in order
+
+{{< callout type="warning" >}}
+Keyframes control **join/switch latency**, not live latency.
+
+Live latency is determined by how often fragments are finalized and pushed.
+{{< /callout >}}
+
+## Join Fragments
+
+A **join fragment** is a fragment whose first sample is an IDR keyframe. Join fragments are random access points for Proctors.
+
+## Join Fragment Triggers
+
+A new join fragment is produced when any of the following occur:
 
 | Trigger | Description |
 |---------|-------------|
-| **Keyframe generated** | Any keyframe (scheduled or on-demand) starts a new segment |
-| **FPS change** | Framerate change request forces a keyframe and new segment |
-| **Maximum interval reached** | If no keyframe has occurred in 20-30 seconds, one is forced |
+ | **On-demand keyframe** | Proctor initiates; next capture becomes IDR |
+ | **FPS change** | Server requests new FPS; next capture becomes IDR |
+ | **Maximum interval reached** | If no keyframe has occurred in 20-30 seconds, one is forced |
 
 ```
-Timeline:
-├── Segment 1 ──────────┼── Segment 2 ────┼── Segment 3 ──────────────┤
-│   [KF]...[F]...[F]    │   [KF]...[F]    │   [KF]...[F]...[F]...[F]  │
-│                       │                 │                           │
-└─ Scheduled keyframe   └─ On-demand      └─ FPS change triggered
-                           keyframe          keyframe
+Timeline (conceptual):
+Fragments are produced continuously, while join fragments occur on keyframes.
+
+├─ fragment ─ fragment ─ join fragment ─ fragment ─ ... ─ join fragment ─ fragment ─┤
+                  [IDR]                            [IDR]
 ```
 
-*KF = Keyframe, F = Frame*
+*IDR = keyframe*
 
 ## Sequence Numbers
 
-Each Sentinel maintains a **sequence counter** for its segments.
+Each Sentinel maintains a **sequence counter** for its fragments.
 
 | Property | Value |
 |----------|-------|
 | Start value | 0 |
-| Increment | 1 per segment |
+ | Increment | 1 per fragment |
 | Scope | Per Sentinel, per session |
 | Controller | Sentinel (not Server) |
 
-The sequence number is assigned by the Sentinel when the segment is created and included in the segment metadata sent to the Server.
+The sequence number is assigned by the Sentinel when the fragment is created and included in the metadata sent to the Server.
 
 ## Naming Convention
 
-Segments are identified by the combination of Sentinel ID and sequence number.
+Fragments are identified by the combination of Sentinel ID and sequence number.
 
 ### Format
 
@@ -61,14 +72,14 @@ Segments are identified by the combination of Sentinel ID and sequence number.
 |-----------|-------------|---------|
 | `sentinelId` | Unique identifier for the Sentinel | `sentinel-a1b2c3` |
 | `sequence` | Zero-padded sequence number | `000142` |
-| Extension | `.m4s` for media segments | |
+| Extension | `.m4s` for fMP4 media fragments | |
 
 ### Examples
 
 ```
-sentinel-a1b2c3-000000.m4s   # First segment
-sentinel-a1b2c3-000001.m4s   # Second segment
-sentinel-a1b2c3-000142.m4s   # 143rd segment
+sentinel-a1b2c3-000000.m4s   # First fragment
+sentinel-a1b2c3-000001.m4s   # Second fragment
+sentinel-a1b2c3-000142.m4s   # 143rd fragment
 ```
 
 ### Initialization Segment Naming
@@ -84,38 +95,42 @@ Example:
 sentinel-a1b2c3-init.mp4
 ```
 
-## Segment Duration
+## Fragment Duration
 
-Segment duration is **variable** and depends on when keyframes occur.
+Fragment duration is **variable** and chosen by the Sentinel implementation to balance latency and overhead.
+
+The spec intentionally does not mandate an exact fragment duration, but fragments MUST be produced frequently enough to satisfy the real-time requirement.
 
 | Scenario | Typical Duration |
 |----------|------------------|
-| Normal operation (no on-demand keyframes) | 20-30 seconds |
-| Frequent Proctor joins | Shorter segments due to on-demand keyframes |
-| FPS changes | Segment ends immediately, new segment begins |
+| Typical real-time operation | ~0.25s to ~2s (implementation choice) |
+| Very low FPS mode (0.2 fps) | One fragment per capture (up to 5s) |
+| Joins / FPS changes | A join fragment is produced on the next capture |
 
 {{< callout type="warning" >}}
-There is no guaranteed minimum or maximum segment duration. Implementations should handle segments of any duration.
+Do not design around the assumption that fragments are 20-30 seconds long.
+
+20-30 seconds is the **maximum keyframe interval** (join fragment spacing), not the fragment duration.
 {{< /callout >}}
 
-## Segment Contents
+## Fragment Contents
 
-Each media segment contains:
+Each media fragment contains:
 
 | Content | Location | Description |
 |---------|----------|-------------|
 | Decode timestamp | `moof` → `tfdt` | Absolute timestamp of first frame |
-| Frame durations | `moof` → `trun` | Duration of each frame in segment |
+| Frame durations | `moof` → `trun` | Duration of each frame in fragment |
 | Frame data | `mdat` | Encoded H.264 NAL units |
 
 ### Frame Timestamps
 
-Every frame within a segment has a precise timestamp derived from:
+Every sample within a fragment has a precise timestamp derived from:
 
-1. The segment's base decode time (`tfdt`)
-2. The cumulative duration of preceding frames (`trun` sample durations)
+1. The fragment's base decode time (`tfdt`)
+2. The cumulative duration of preceding samples (`trun` sample durations)
 
-This allows accurate playback timing regardless of variable framerate across segments.
+This allows accurate playback timing regardless of FPS changes over time.
 
 ## Relationship to Sessions
 
@@ -123,9 +138,9 @@ A **session** is the period from when a Sentinel connects to when it disconnects
 
 | Session Event | Segment Behavior |
 |---------------|------------------|
-| Session start | Sequence resets to 0, new initialization segment created |
-| Session continues | Sequence increments with each segment |
-| Session ends | Final segment may be shorter than normal |
+ | Session start | Sequence resets to 0, new initialization segment created |
+ | Session continues | Sequence increments with each fragment |
+ | Session ends | Final fragment may be shorter than normal |
 
 {{< callout type="info" >}}
 If a Sentinel reconnects (new session), it generates a new initialization segment and restarts sequence numbering at 0. The Server treats this as a new stream.
diff --git a/hugo/content/docs/reference/media-spec/transport.md b/hugo/content/docs/reference/media-spec/transport.md
index 116c281..96c8547 100644
--- a/hugo/content/docs/reference/media-spec/transport.md
+++ b/hugo/content/docs/reference/media-spec/transport.md
@@ -19,7 +19,9 @@ All live video data flows over WebSocket connections.
 
 ### Sentinel → Server
 
-The Sentinel pushes segments to the Server as they are created.
+The Sentinel pushes **fragments** to the Server as they are finalized.
+
+See [Terminology](../terminology) for the distinction between fragments (live delivery units) and keyframes (join points).
 
 ```plantuml
 @startuml
@@ -28,23 +30,23 @@ skinparam sequenceMessageAlign center
 participant "Sentinel" as S
 participant "Server" as Srv
 
-== Segment Streaming ==
+== Fragment Streaming ==
 
-S -> Srv : segment data
-note right: Segment 140
+S -> Srv : fragment data
+note right: Fragment 140
 
-S -> Srv : segment data
-note right: Segment 141
+S -> Srv : fragment data
+note right: Fragment 141
 
-S -> Srv : segment data
-note right: Segment 142
+S -> Srv : fragment data
+note right: Fragment 142
 
 @enduml
 ```
 
 ### Server → Proctor
 
-The Server pushes segments to subscribed Proctors as they arrive.
+The Server pushes fragments to subscribed Proctors as they arrive.
 
 ```plantuml
 @startuml
@@ -56,14 +58,14 @@ participant "Proctor" as P
 == Live Push ==
 
 Srv -> P : init segment
-Srv -> P : segment data
-note left: Segment 140
+Srv -> P : fragment data
+note left: Fragment 140
 
-Srv -> P : segment data
-note left: Segment 141
+Srv -> P : fragment data
+note left: Fragment 141
 
-Srv -> P : segment data
-note left: Segment 142
+Srv -> P : fragment data
+note left: Fragment 142
 
 @enduml
 ```
@@ -79,13 +81,13 @@ The spec does not mandate a specific serialization format for WebSocket messages
 
 The key requirement is that the message contains:
 
-| Field | Type | Description |
-|-------|------|-------------|
-| `sentinelId` | string | Identifies which Sentinel this segment belongs to |
-| `sequence` | integer | Segment sequence number |
-| `data` | bytes | Raw fMP4 segment bytes |
+ | Field | Type | Description |
+ |-------|------|-------------|
+ | `sentinelId` | string | Identifies which Sentinel this fragment belongs to |
+ | `sequence` | integer | Fragment sequence number |
+ | `data` | bytes | Raw fMP4 fragment bytes (`moof` + `mdat`) |
 
-Additional metadata (framerate, timestamp) may be included or derived from the segment bytes.
+Additional metadata (framerate, timestamp) may be included or derived from the fragment bytes.
 
 ### Initialization Segment
 
@@ -101,44 +103,44 @@ The initialization segment is sent separately, typically:
 
 ## HTTP: Historical Playback
 
-For accessing segments that have aged out of the memory buffer, Proctors use HTTP.
+For accessing fragments that have aged out of the memory buffer, Proctors use HTTP.
 
 ### Required Information
 
-To fetch a historical segment, the Proctor needs:
+To fetch a historical fragment, the Proctor needs:
 
 | Information | Description |
 |-------------|-------------|
 | `sentinelId` | Which Sentinel's stream |
 | `sessionId` | Which session |
-| `sequence` | Which segment (or range) |
+ | `sequence` | Which fragment (or range) |
 
 ### Response
 
-The HTTP response contains the raw fMP4 segment bytes with appropriate content headers.
+The HTTP response contains the raw fMP4 fragment bytes with appropriate content headers.
 
 | Header | Value |
 |--------|-------|
 | `Content-Type` | `video/mp4` |
 | `Content-Length` | Size in bytes |
 
-### Listing Available Segments
+### Listing Available Fragments
 
-Proctors may need to query which segments are available for a session. The response should include:
+Proctors may need to query which fragments are available for a session. The response should include:
 
-| Field | Type | Description |
-|-------|------|-------------|
-| `sentinelId` | string | Sentinel identifier |
-| `sessionId` | string | Session identifier |
-| `segments` | array | List of available segment metadata |
+ | Field | Type | Description |
+ |-------|------|-------------|
+ | `sentinelId` | string | Sentinel identifier |
+ | `sessionId` | string | Session identifier |
+ | `fragments` | array | List of available fragment metadata |
 
-Each segment entry:
+Each entry:
 
 | Field | Type | Description |
 |-------|------|-------------|
-| `sequence` | integer | Segment number |
-| `startTime` | timestamp | When the segment starts |
-| `duration` | integer | Duration in milliseconds |
+ | `sequence` | integer | Fragment number |
+ | `startTime` | timestamp | When the fragment starts |
+ | `duration` | integer | Duration in milliseconds |
 
 {{< callout type="info" >}}
 The exact HTTP endpoint structure is implementation-defined. The spec only defines what information must be available.
@@ -151,17 +153,17 @@ The exact HTTP endpoint structure is implementation-defined. The spec only defin
 | Scenario | Use WebSocket |
 |----------|---------------|
 | Live stream viewing | Yes |
-| Joining a stream | Yes (get init + recent segments) |
-| Control messages (keyframe request, FPS change) | Yes |
-| Real-time segment push from Sentinel | Yes |
+ | Joining a stream | Yes (get init + recent fragments) |
+ | Control messages (keyframe request, FPS change) | Yes |
+ | Real-time fragment push from Sentinel | Yes |
 
 ### When to Use HTTP
 
-| Scenario | Use HTTP |
-|----------|----------|
-| Fetching segments older than buffer window | Yes |
-| Querying available sessions/segments | Yes |
-| Downloading for export/archival | Yes |
+ | Scenario | Use HTTP |
+ |----------|----------|
+ | Fetching fragments older than buffer window | Yes |
+ | Querying available sessions/fragments | Yes |
+ | Downloading for export/archival | Yes |
 
 ## Connection Lifecycle
 
@@ -169,7 +171,7 @@ The exact HTTP endpoint structure is implementation-defined. The spec only defin
 
 1. Sentinel establishes WebSocket connection to Server
 2. Sentinel sends registration/identification
-3. Sentinel begins pushing segments
+3. Sentinel begins pushing fragments
 4. Connection remains open for session duration
 5. On disconnect, session ends
 
@@ -178,7 +180,7 @@ The exact HTTP endpoint structure is implementation-defined. The spec only defin
 1. Proctor establishes WebSocket connection to Server
 2. Proctor sends registration/identification
 3. Proctor subscribes to one or more Sentinel streams
-4. Server pushes segments for subscribed streams
+4. Server pushes fragments for subscribed streams
 5. Proctor may switch subscriptions during session
 6. Connection remains open while Proctor is active
 

```
```

---

## Assistant (Build · gpt-5.2 · 10.7s)

_Thinking:_



```
Tool: read

**Input:**
```json
{
  "filePath": "/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/metadata.md",
  "offset": 1,
  "limit": 120
}
```
**Output:**
```
<file>
00002| title: Metadata
00003| ---
00004| 
00005| This document specifies the metadata associated with video fragments, where it is stored, and how it is synchronized.
00006| 
00007| See [Terminology](../terminology) for the distinction between fragments and join fragments.
00008| 
00009| ## Metadata Locations
00010| 
00011| Metadata exists in two locations:
00012| 
00013| | Location | Contents | Purpose |
00014| |----------|----------|---------|
00015| | **In-stream** | Timestamps, duration | Required for browser playback |
00016| | **Application** | Sentinel ID, sequence, framerate, file paths | Server/Proctor coordination |
00017| 
00018| ## In-Stream Metadata
00019| 
00020| This metadata is embedded in the fMP4 container by the Sentinel encoder. The Server does not modify it.
00021| 
00022| ### Initialization Segment
00023| 
00024| | Field | Location | Description |
00025| |-------|----------|-------------|
00026| | Timescale | `moov` → `mdhd` | Time units per second (e.g., 90000) |
00027| | Resolution | `moov` → `tkhd` | Width and height in pixels |
00028| | Codec info | `moov` → `stsd` | H.264 SPS/PPS |
00029| 
00030| ### Media Segment
00031| 
00032| In this spec, this refers to a media **fragment** (`moof` + `mdat`).
00033| 
00034| | Field | Location | Description |
00035| |-------|----------|-------------|
00036| | Base decode time | `moof` → `tfdt` | Timestamp of first frame in fragment |
00037| | Sample durations | `moof` → `trun` | Duration of each frame |
00038| | Sample sizes | `moof` → `trun` | Byte size of each frame |
00039| 
00040| {{< callout type="info" >}}
00041| The in-stream metadata is sufficient for a browser to decode and display the video at correct timing. The application metadata provides additional context for stream management.
00042| {{< /callout >}}
00043| 
00044| ## Application Metadata
00045| 
00046| This metadata is managed by the Server and stored in memory, with periodic persistence to the database.
00047| 
00048| ### Per-Session Metadata
00049| 
00050| | Field | Type | Description |
00051| |-------|------|-------------|
00052| | `sentinelId` | string | Unique identifier for the Sentinel |
00053| | `sessionId` | string | Unique identifier for this session |
00054| | `startTime` | timestamp | When the session started |
00055| | `resolution` | object | Width and height |
00056| | `initSegmentPath` | string | Path to initialization segment on disk |
00057| 
00058| Example:
00059| 
00060| ```json
00061| {
00062|   "sentinelId": "sentinel-a1b2c3",
00063|   "sessionId": "2026-02-05T14-30-00Z",
00064|   "startTime": "2026-02-05T14:30:00.000Z",
00065|   "resolution": {
00066|     "width": 1920,
00067|     "height": 1080
00068|   },
00069|   "initSegmentPath": "/var/franklyn/video/sentinel-a1b2c3/2026-02-05T14-30-00Z/init.mp4"
00070| }
00071| ```
00072| 
00073| ### Per-Segment Metadata
00074| 
00075| This spec uses the term **fragment** for the live-delivery unit.
00076| 
00077| | Field | Type | Description |
00078| |-------|------|-------------|
00079| | `sequence` | integer | Fragment sequence number |
00080| | `startTime` | timestamp | Wall-clock time of first frame |
00081| | `duration` | integer | Duration in milliseconds |
00082| | `framerate` | number | Frames per second during this fragment |
00083| | `filePath` | string | Path to fragment file on disk |
00084| | `isJoin` | boolean | True if this fragment starts with an IDR keyframe |
00085| 
00086| Example:
00087| 
00088| ```json
00089| {
00090|   "sequence": 142,
00091|   "startTime": "2026-02-05T14:35:42.000Z",
00092|   "duration": 4800,
00093|   "framerate": 5,
00094|   "filePath": "/var/franklyn/video/sentinel-a1b2c3/2026-02-05T14-30-00Z/000142.m4s",
00095|   "isJoin": false
00096| }
00097| ```
00098| 
00099| ## Memory Storage
00100| 
00101| During active streaming, all application metadata is held in memory for fast access.
00102| 
00103| ### Data Structure (Conceptual)
00104| 
00105| ```
00106| Server Memory
00107| ├── Active Sessions
00108| │   └── {sentinelId}
00109| │       ├── Session Metadata
00110| │       ├── Init Segment (bytes)
00111| │       └── Fragment Buffer
00112| │           ├── Fragment 140: { metadata, bytes }
00113| │           ├── Fragment 141: { metadata, bytes }
00114| │           ├── Fragment 142: { metadata, bytes }
00115| │           └── ...
00116| ```
00117| 
00118| ### Access Patterns
00119| 
00120| | Operation | Data Source |
00121| |-----------|-------------|

(File has more lines. Use 'offset' parameter to read beyond line 121)
</file>
```
```

---

## Assistant (Build · gpt-5.2 · 2.9s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/metadata.md\n@@\n-### Media Segment\n+### Media Fragment\n@@\n-### Per-Segment Metadata\n+### Per-Fragment Metadata\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/metadata.md
```
```

---

## Assistant (Build · gpt-5.2 · 3.5s)

```
Tool: grep

**Input:**
```json
{
  "pattern": "Per-Segment|Media Segment|segment\\b(?!\\s*\\)|\\s*bytes)|segment metadata|Segment metadata|new segment arrives|historical segment|available segments|buffered segments",
  "path": "hugo/content/docs/reference/media-spec",
  "include": "*.md"
}
```
**Output:**
```
No files found
```
```

---

## Assistant (Build · gpt-5.2 · 2.8s)

```
Tool: bash

**Input:**
```json
{
  "command": "git diff --stat",
  "description": "Show diff stat after renames"
}
```
**Output:**
```
 hugo/content/docs/reference/media-spec/_index.md   |  21 +++--
 .../content/docs/reference/media-spec/container.md |  34 +++----
 .../docs/reference/media-spec/control-messages.md  |  28 +++---
 .../docs/reference/media-spec/disk-storage.md      |  36 +++----
 hugo/content/docs/reference/media-spec/encoding.md |   9 +-
 .../content/docs/reference/media-spec/join-flow.md |  60 ++++++------
 .../docs/reference/media-spec/memory-buffer.md     |  46 +++++----
 hugo/content/docs/reference/media-spec/metadata.md |  60 ++++++------
 hugo/content/docs/reference/media-spec/segments.md | 103 ++++++++++++---------
 .../content/docs/reference/media-spec/transport.md |  94 ++++++++++---------
 10 files changed, 266 insertions(+), 225 deletions(-)

```
```

---

## Assistant (Build · gpt-5.2 · 3.2s)

```
Tool: grep

**Input:**
```json
{
  "pattern": "\\bsegment(s)?\\b",
  "path": "hugo/content/docs/reference/media-spec",
  "include": "*.md"
}
```
**Output:**
```
Found 34 matches
/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/metadata.md:
  Line 56: | `initSegmentPath` | string | Path to initialization segment on disk |
  Line 122: | Proctor joins stream | Memory (init segment + buffered fragments) |
  Line 150: | Init segment bytes | No (stored as file on disk) |

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/_index.md:
  Line 35: {{< card link="segments" title="Fragments" icon="collection" subtitle="Fragment cadence and join fragments" >}}

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/transport.md:
  Line 60: Srv -> P : init segment
  Line 94: The initialization segment is sent separately, typically:
  Line 102: | `data` | bytes | Raw fMP4 initialization segment bytes |

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/disk-storage.md:
  Line 17: | Initialization segment | Yes | Raw fMP4 bytes |
  Line 63: | Initialization segment received | Write to `init.mp4` |
  Line 91: Each fragment file is a complete, valid fMP4 media fragment. Combined with the initialization segment, any fragment can be decoded independently when appended in order; a Proctor SHOULD start at a join fragment.
  Line 109: Provide initialization segment + media fragments to an fMP4-compatible player or MSE.
  Line 132: 1. Fetch the initialization segment

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/container.md:
  Line 51: The initialization segment contains metadata required to configure the decoder. It does not contain any video frames.
  Line 89:  | Decodable with init | A fragment is decodable when appended after the initialization segment and appropriate preceding fragments |
  Line 99: The timescale from the initialization segment determines how timestamps map to wall-clock time. A common choice is 90000 (90kHz), allowing sub-millisecond precision.
  Line 110: Obtain the initialization segment for the target Sentinel from the Server.
  Line 114: Create a `MediaSource`, add a `SourceBuffer` with the appropriate MIME type, and append the initialization segment.

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/segments.md:
  Line 87: The initialization segment uses a distinct name:
  Line 141:  | Session start | Sequence resets to 0, new initialization segment created |
  Line 146: If a Sentinel reconnects (new session), it generates a new initialization segment and restarts sequence numbering at 0. The Server treats this as a new stream.

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/join-flow.md:
  Line 12: 2. Receive the initialization segment
  Line 38: Srv -> P : init segment
  Line 85: The Server sends the cached initialization segment for the Sentinel's current session.
  Line 93: | `data` | bytes | Raw fMP4 init segment |
  Line 151: Srv -> P : init segment
  Line 191: - Append the new initialization segment
  Line 203: | No join fragment in buffer | Send init segment, request/await next join fragment |

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/encoding.md:
  Line 87: When FPS changes, a new join fragment must be produced (see [Fragments](../segments)).

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/memory-buffer.md:
  Line 31: | **Initialization segment** | The codec/resolution configuration for the session |
  Line 75: 1. Server sends the initialization segment
  Line 95: The initialization segment for each active Sentinel is cached separately from the media fragment buffer.
  Line 103: Since the initialization segment is small (typically a few KB) and required for every new Proctor, it remains in memory for the duration of the Sentinel's session.

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/terminology.md:
  Line 15: | **Initialization segment** | fMP4 `ftyp` + `moov` bytes for the session. Contains codec config (SPS/PPS), resolution, timescale. Contains **no frames**. | Must be appended to MSE before any media data can be decoded.
  Line 39: It does **not** mean "start sending an empty 20s segment at t=0".
```
```

---

## Assistant (Build · gpt-5.2 · 9.1s)

_Thinking:_



```
Tool: grep

**Input:**
```json
{
  "pattern": "\\bsegments\\b|\\bsegment\\b",
  "path": "hugo/content/docs/reference",
  "include": "*.md"
}
```
**Output:**
```
Found 34 matches
/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/metadata.md:
  Line 56: | `initSegmentPath` | string | Path to initialization segment on disk |
  Line 122: | Proctor joins stream | Memory (init segment + buffered fragments) |
  Line 150: | Init segment bytes | No (stored as file on disk) |

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/_index.md:
  Line 35: {{< card link="segments" title="Fragments" icon="collection" subtitle="Fragment cadence and join fragments" >}}

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/transport.md:
  Line 60: Srv -> P : init segment
  Line 94: The initialization segment is sent separately, typically:
  Line 102: | `data` | bytes | Raw fMP4 initialization segment bytes |

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/disk-storage.md:
  Line 17: | Initialization segment | Yes | Raw fMP4 bytes |
  Line 63: | Initialization segment received | Write to `init.mp4` |
  Line 91: Each fragment file is a complete, valid fMP4 media fragment. Combined with the initialization segment, any fragment can be decoded independently when appended in order; a Proctor SHOULD start at a join fragment.
  Line 109: Provide initialization segment + media fragments to an fMP4-compatible player or MSE.
  Line 132: 1. Fetch the initialization segment

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/container.md:
  Line 51: The initialization segment contains metadata required to configure the decoder. It does not contain any video frames.
  Line 89:  | Decodable with init | A fragment is decodable when appended after the initialization segment and appropriate preceding fragments |
  Line 99: The timescale from the initialization segment determines how timestamps map to wall-clock time. A common choice is 90000 (90kHz), allowing sub-millisecond precision.
  Line 110: Obtain the initialization segment for the target Sentinel from the Server.
  Line 114: Create a `MediaSource`, add a `SourceBuffer` with the appropriate MIME type, and append the initialization segment.

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/segments.md:
  Line 87: The initialization segment uses a distinct name:
  Line 141:  | Session start | Sequence resets to 0, new initialization segment created |
  Line 146: If a Sentinel reconnects (new session), it generates a new initialization segment and restarts sequence numbering at 0. The Server treats this as a new stream.

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/join-flow.md:
  Line 12: 2. Receive the initialization segment
  Line 38: Srv -> P : init segment
  Line 85: The Server sends the cached initialization segment for the Sentinel's current session.
  Line 93: | `data` | bytes | Raw fMP4 init segment |
  Line 151: Srv -> P : init segment
  Line 191: - Append the new initialization segment
  Line 203: | No join fragment in buffer | Send init segment, request/await next join fragment |

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/encoding.md:
  Line 87: When FPS changes, a new join fragment must be produced (see [Fragments](../segments)).

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/memory-buffer.md:
  Line 31: | **Initialization segment** | The codec/resolution configuration for the session |
  Line 75: 1. Server sends the initialization segment
  Line 95: The initialization segment for each active Sentinel is cached separately from the media fragment buffer.
  Line 103: Since the initialization segment is small (typically a few KB) and required for every new Proctor, it remains in memory for the duration of the Sentinel's session.

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/terminology.md:
  Line 15: | **Initialization segment** | fMP4 `ftyp` + `moov` bytes for the session. Contains codec config (SPS/PPS), resolution, timescale. Contains **no frames**. | Must be appended to MSE before any media data can be decoded.
  Line 39: It does **not** mean "start sending an empty 20s segment at t=0".
```
```

---

## Assistant (Build · gpt-5.2 · 2.3s)

```
Tool: bash

**Input:**
```json
{
  "command": "git status --porcelain",
  "description": "Show working tree status"
}
```
**Output:**
```
 M hugo/content/docs/reference/media-spec/_index.md
 M hugo/content/docs/reference/media-spec/container.md
 M hugo/content/docs/reference/media-spec/control-messages.md
 M hugo/content/docs/reference/media-spec/disk-storage.md
 M hugo/content/docs/reference/media-spec/encoding.md
 M hugo/content/docs/reference/media-spec/join-flow.md
 M hugo/content/docs/reference/media-spec/memory-buffer.md
 M hugo/content/docs/reference/media-spec/metadata.md
 M hugo/content/docs/reference/media-spec/segments.md
 M hugo/content/docs/reference/media-spec/transport.md
?? hugo/content/docs/reference/media-spec/terminology.md

```
```

---

## Assistant (Build · gpt-5.2 · 4.6s)

Done—everywhere the spec previously used a `segments` field/name but meant “fragments”, it now uses `fragments`.

Changes made:
- `hugo/content/docs/reference/media-spec/transport.md`: renamed listing response field from `segments` -> `fragments`
- `hugo/content/docs/reference/media-spec/metadata.md`: renamed headings to `Media Fragment` and `Per-Fragment Metadata`; removed the “db can call it segments” allowance so the spec is consistent
- `hugo/content/docs/reference/media-spec/_index.md`: updated “Persistent segment storage” -> “Persistent fragment storage”

Notes:
- Remaining occurrences of the word “segment” are now only “initialization segment” (correct MP4 term) or the filename `segments.md` (page path), not the data concept.

---

## User

one other question. in permiere i see high adaptive bitrate and i also don't see the spec mention bitrate.
is high adaptive bitrate basically unlimited and send just what you need to send so it can go as low as a couple of kb to mb or what is it in the context of the spec

---

## Assistant (Plan · gpt-5.2 · 18.0s)

_Thinking:_



“High adaptive bitrate” in Premiere is not “unlimited”; it’s Premiere’s (somewhat fuzzy) UI label for a *variable bitrate* mode where the encoder changes bitrate over time based on scene complexity to hit a quality/size goal.

Two different things often get conflated:

1) Adaptive bitrate in *export/encoding settings* (Premiere)
- Meaning: the encoder allocates more bits to complex frames and fewer bits to simple frames.
- Reality: it is still bounded by encoder constraints (profile/level, VBV buffer, and usually a max bitrate if you set one). It can spike up to that max.
- For screen content, this can swing a lot:
  - Static desktop: very low kbps
  - Fast scrolling/video playback/text movement: can jump to Mbps, especially on keyframes (IDR)

2) Adaptive bitrate in *streaming systems* (HLS/DASH ABR)
- Meaning: you encode multiple renditions (e.g., 200 kbps, 800 kbps, 2 Mbps) and the player switches between them.
- Your spec explicitly chose MSE + single stream, so you’re not doing ABR streaming unless you add multiple encodes (which would also increase Sentinel CPU/GPU load).

How this maps to your spec (Sentinel -> Server -> Proctor)
- Your spec currently defines codec/container/transport/join semantics but does not constrain *rate control*.
- Without a bitrate policy, “what you need to send” is determined entirely by the encoder’s mode:
  - CBR-ish modes: stable bandwidth, quality varies
  - VBR modes: bandwidth varies, quality more consistent
  - CRF/ICQ/CQP modes (quality-target): bitrate varies widely; effectively “as many bits as needed” to reach the requested quality *but still subject to optional caps*

So, “high adaptive bitrate” is best understood as:
- “Let bitrate rise when necessary to preserve quality,”
- but it should still be paired with an explicit max (even on LAN) if you want predictable worst-case load.

If you tell me which encoder family you expect on Sentinels (x264, NVENC, QuickSync, AMF), I can translate this into concrete spec language (recommended mode + default target quality + max bitrate cap) that’s actually implementable across hardware.

---

## User

i will use openh264 and other mit license compatible software for my project.
plan to update the spec for that. some other time i saw someone mention that openh264 does't support all recommended profiles.

---

## Assistant (Plan · gpt-5.2 · 21.4s)

_Thinking:_



```
Tool: webfetch

**Input:**
```json
{
  "url": "https://github.com/cisco/openh264",
  "format": "markdown",
  "timeout": 60
}
```
**Output:**
```
                    GitHub - cisco/openh264: Open Source H.264 Codec                                             

[Skip to content](#start-of-content)   

## Navigation Menu

Toggle navigation

[](/)

[Sign in](/login?return_to=https%3A%2F%2Fgithub.com%2Fcisco%2Fopenh264)

Appearance settings

  

-   Platform
    
    -   AI CODE CREATION
        
        -   [
            
            GitHub CopilotWrite better code with AI
            
            ](https://github.com/features/copilot)
        -   [
            
            GitHub SparkBuild and deploy intelligent apps
            
            ](https://github.com/features/spark)
        -   [
            
            GitHub ModelsManage and compare prompts
            
            ](https://github.com/features/models)
        -   [
            
            MCP RegistryNewIntegrate external tools
            
            ](https://github.com/mcp)
        
    -   DEVELOPER WORKFLOWS
        
        -   [
            
            ActionsAutomate any workflow
            
            ](https://github.com/features/actions)
        -   [
            
            CodespacesInstant dev environments
            
            ](https://github.com/features/codespaces)
        -   [
            
            IssuesPlan and track work
            
            ](https://github.com/features/issues)
        -   [
            
            Code ReviewManage code changes
            
            ](https://github.com/features/code-review)
        
    -   APPLICATION SECURITY
        
        -   [
            
            GitHub Advanced SecurityFind and fix vulnerabilities
            
            ](https://github.com/security/advanced-security)
        -   [
            
            Code securitySecure your code as you build
            
            ](https://github.com/security/advanced-security/code-security)
        -   [
            
            Secret protectionStop leaks before they start
            
            ](https://github.com/security/advanced-security/secret-protection)
        
    -   EXPLORE
        
        -   [Why GitHub](https://github.com/why-github)
        -   [Documentation](https://docs.github.com)
        -   [Blog](https://github.blog)
        -   [Changelog](https://github.blog/changelog)
        -   [Marketplace](https://github.com/marketplace)
        
    
    [View all features](https://github.com/features)
    
-   Solutions
    
    -   BY COMPANY SIZE
        
        -   [Enterprises](https://github.com/enterprise)
        -   [Small and medium teams](https://github.com/team)
        -   [Startups](https://github.com/enterprise/startups)
        -   [Nonprofits](https://github.com/solutions/industry/nonprofits)
        
    -   BY USE CASE
        
        -   [App Modernization](https://github.com/solutions/use-case/app-modernization)
        -   [DevSecOps](https://github.com/solutions/use-case/devsecops)
        -   [DevOps](https://github.com/solutions/use-case/devops)
        -   [CI/CD](https://github.com/solutions/use-case/ci-cd)
        -   [View all use cases](https://github.com/solutions/use-case)
        
    -   BY INDUSTRY
        
        -   [Healthcare](https://github.com/solutions/industry/healthcare)
        -   [Financial services](https://github.com/solutions/industry/financial-services)
        -   [Manufacturing](https://github.com/solutions/industry/manufacturing)
        -   [Government](https://github.com/solutions/industry/government)
        -   [View all industries](https://github.com/solutions/industry)
        
    
    [View all solutions](https://github.com/solutions)
    
-   Resources
    
    -   EXPLORE BY TOPIC
        
        -   [AI](https://github.com/resources/articles?topic=ai)
        -   [Software Development](https://github.com/resources/articles?topic=software-development)
        -   [DevOps](https://github.com/resources/articles?topic=devops)
        -   [Security](https://github.com/resources/articles?topic=security)
        -   [View all topics](https://github.com/resources/articles)
        
    -   EXPLORE BY TYPE
        
        -   [Customer stories](https://github.com/customer-stories)
        -   [Events & webinars](https://github.com/resources/events)
        -   [Ebooks & reports](https://github.com/resources/whitepapers)
        -   [Business insights](https://github.com/solutions/executive-insights)
        -   [GitHub Skills](https://skills.github.com)
        
    -   SUPPORT & SERVICES
        
        -   [Documentation](https://docs.github.com)
        -   [Customer support](https://support.github.com)
        -   [Community forum](https://github.com/orgs/community/discussions)
        -   [Trust center](https://github.com/trust-center)
        -   [Partners](https://github.com/partners)
        
    
-   Open Source
    
    -   COMMUNITY
        
        -   [
            
            GitHub SponsorsFund open source developers
            
            ](https://github.com/sponsors)
        
    -   PROGRAMS
        
        -   [Security Lab](https://securitylab.github.com)
        -   [Maintainer Community](https://maintainers.github.com)
        -   [Accelerator](https://github.com/accelerator)
        -   [Archive Program](https://archiveprogram.github.com)
        
    -   REPOSITORIES
        
        -   [Topics](https://github.com/topics)
        -   [Trending](https://github.com/trending)
        -   [Collections](https://github.com/collections)
        
    
-   Enterprise
    
    -   ENTERPRISE SOLUTIONS
        
        -   [
            
            Enterprise platformAI-powered developer platform
            
            ](https://github.com/enterprise)
        
    -   AVAILABLE ADD-ONS
        
        -   [
            
            GitHub Advanced SecurityEnterprise-grade security features
            
            ](https://github.com/security/advanced-security)
        -   [
            
            Copilot for BusinessEnterprise-grade AI features
            
            ](https://github.com/features/copilot/copilot-business)
        -   [
            
            Premium SupportEnterprise-grade 24/7 support
            
            ](https://github.com/premium-support)
        
    
-   [Pricing](https://github.com/pricing)

Search or jump to...

# Search code, repositories, users, issues, pull requests...

Search

Clear

[Search syntax tips](https://docs.github.com/search-github/github-code-search/understanding-github-code-search-syntax)

# Provide feedback

We read every piece of feedback, and take your input very seriously.

 Include my email address so I can be contacted

Cancel Submit feedback

# Saved searches

## Use saved searches to filter your results more quickly

Name  

Query 

To see all available qualifiers, see our [documentation](https://docs.github.com/search-github/github-code-search/understanding-github-code-search-syntax).

Cancel Create saved search

[Sign in](/login?return_to=https%3A%2F%2Fgithub.com%2Fcisco%2Fopenh264)

[Sign up](/signup?ref_cta=Sign+up&ref_loc=header+logged+out&ref_page=%2F%3Cuser-name%3E%2F%3Crepo-name%3E&source=header-repo&source_repo=cisco%2Fopenh264)

Appearance settings

Resetting focus

You signed in with another tab or window. Reload to refresh your session. You signed out in another tab or window. Reload to refresh your session. You switched accounts on another tab or window. Reload to refresh your session. Dismiss alert

[cisco](/cisco) / **[openh264](/cisco/openh264)** Public

-   [Notifications](/login?return_to=%2Fcisco%2Fopenh264) You must be signed in to change notification settings
-   [Fork 1.9k](/login?return_to=%2Fcisco%2Fopenh264)
-   [Star 6.1k](/login?return_to=%2Fcisco%2Fopenh264)
    

Open Source H.264 Codec

### License

[BSD-2-Clause license](/cisco/openh264/blob/master/LICENSE)

[6.1k stars](/cisco/openh264/stargazers) [1.9k forks](/cisco/openh264/forks) [Branches](/cisco/openh264/branches) [Tags](/cisco/openh264/tags) [Activity](/cisco/openh264/activity)

[Star](/login?return_to=%2Fcisco%2Fopenh264)

[Notifications](/login?return_to=%2Fcisco%2Fopenh264) You must be signed in to change notification settings

-   [Code](/cisco/openh264)
-   [Issues 258](/cisco/openh264/issues)
-   [Pull requests 29](/cisco/openh264/pulls)
-   [Actions](/cisco/openh264/actions)
-   [Projects 0](/cisco/openh264/projects)
-   [Wiki](/cisco/openh264/wiki)
-   [Security 1](/cisco/openh264/security)
-   [Insights](/cisco/openh264/pulse)

Additional navigation options

-   [Code](/cisco/openh264)
-   [Issues](/cisco/openh264/issues)
-   [Pull requests](/cisco/openh264/pulls)
-   [Actions](/cisco/openh264/actions)
-   [Projects](/cisco/openh264/projects)
-   [Wiki](/cisco/openh264/wiki)
-   [Security](/cisco/openh264/security)
-   [Insights](/cisco/openh264/pulse)

# cisco/openh264

  

 master

[Branches](/cisco/openh264/branches)[Tags](/cisco/openh264/tags)

[](/cisco/openh264/branches)[](/cisco/openh264/tags)

Go to file

Code

Open more actions menu

## Folders and files

Name

Name

Last commit message

Last commit date

## Latest commit

## History

[5,264 Commits](/cisco/openh264/commits/master/)

[](/cisco/openh264/commits/master/)5,264 Commits

[.github/workflows](/cisco/openh264/tree/master/.github/workflows "This path skips through empty directories")

[.github/workflows](/cisco/openh264/tree/master/.github/workflows "This path skips through empty directories")

[autotest](/cisco/openh264/tree/master/autotest "autotest")

[autotest](/cisco/openh264/tree/master/autotest "autotest")

[build](/cisco/openh264/tree/master/build "build")

[build](/cisco/openh264/tree/master/build "build")

[codec](/cisco/openh264/tree/master/codec "codec")

[codec](/cisco/openh264/tree/master/codec "codec")

[docs](/cisco/openh264/tree/master/docs "docs")

[docs](/cisco/openh264/tree/master/docs "docs")

[module](/cisco/openh264/tree/master/module "module")

[module](/cisco/openh264/tree/master/module "module")

[res](/cisco/openh264/tree/master/res "res")

[res](/cisco/openh264/tree/master/res "res")

[subprojects](/cisco/openh264/tree/master/subprojects "subprojects")

[subprojects](/cisco/openh264/tree/master/subprojects "subprojects")

[test](/cisco/openh264/tree/master/test "test")

[test](/cisco/openh264/tree/master/test "test")

[testbin](/cisco/openh264/tree/master/testbin "testbin")

[testbin](/cisco/openh264/tree/master/testbin "testbin")

[.gitignore](/cisco/openh264/blob/master/.gitignore ".gitignore")

[.gitignore](/cisco/openh264/blob/master/.gitignore ".gitignore")

[.reviewboardrc](/cisco/openh264/blob/master/.reviewboardrc ".reviewboardrc")

[.reviewboardrc](/cisco/openh264/blob/master/.reviewboardrc ".reviewboardrc")

[.travis.yml](/cisco/openh264/blob/master/.travis.yml ".travis.yml")

[.travis.yml](/cisco/openh264/blob/master/.travis.yml ".travis.yml")

[CODING\_STYLE](/cisco/openh264/blob/master/CODING_STYLE "CODING_STYLE")

[CODING\_STYLE](/cisco/openh264/blob/master/CODING_STYLE "CODING_STYLE")

[CONTRIBUTORS](/cisco/openh264/blob/master/CONTRIBUTORS "CONTRIBUTORS")

[CONTRIBUTORS](/cisco/openh264/blob/master/CONTRIBUTORS "CONTRIBUTORS")

[LICENSE](/cisco/openh264/blob/master/LICENSE "LICENSE")

[LICENSE](/cisco/openh264/blob/master/LICENSE "LICENSE")

[Makefile](/cisco/openh264/blob/master/Makefile "Makefile")

[Makefile](/cisco/openh264/blob/master/Makefile "Makefile")

[README.md](/cisco/openh264/blob/master/README.md "README.md")

[README.md](/cisco/openh264/blob/master/README.md "README.md")

[RELEASES](/cisco/openh264/blob/master/RELEASES "RELEASES")

[RELEASES](/cisco/openh264/blob/master/RELEASES "RELEASES")

[SECURITY.md](/cisco/openh264/blob/master/SECURITY.md "SECURITY.md")

[SECURITY.md](/cisco/openh264/blob/master/SECURITY.md "SECURITY.md")

[build.gradle](/cisco/openh264/blob/master/build.gradle "build.gradle")

[build.gradle](/cisco/openh264/blob/master/build.gradle "build.gradle")

[code-coverage.sh](/cisco/openh264/blob/master/code-coverage.sh "code-coverage.sh")

[code-coverage.sh](/cisco/openh264/blob/master/code-coverage.sh "code-coverage.sh")

[gmpopenh264.info](/cisco/openh264/blob/master/gmpopenh264.info "gmpopenh264.info")

[gmpopenh264.info](/cisco/openh264/blob/master/gmpopenh264.info "gmpopenh264.info")

[gradlew](/cisco/openh264/blob/master/gradlew "gradlew")

[gradlew](/cisco/openh264/blob/master/gradlew "gradlew")

[meson.build](/cisco/openh264/blob/master/meson.build "meson.build")

[meson.build](/cisco/openh264/blob/master/meson.build "meson.build")

[meson\_options.txt](/cisco/openh264/blob/master/meson_options.txt "meson_options.txt")

[meson\_options.txt](/cisco/openh264/blob/master/meson_options.txt "meson_options.txt")

[openh264.def](/cisco/openh264/blob/master/openh264.def "openh264.def")

[openh264.def](/cisco/openh264/blob/master/openh264.def "openh264.def")

[openh264.pc.in](/cisco/openh264/blob/master/openh264.pc.in "openh264.pc.in")

[openh264.pc.in](/cisco/openh264/blob/master/openh264.pc.in "openh264.pc.in")

[openh264.rc](/cisco/openh264/blob/master/openh264.rc "openh264.rc")

[openh264.rc](/cisco/openh264/blob/master/openh264.rc "openh264.rc")

[openh264.rc.template](/cisco/openh264/blob/master/openh264.rc.template "openh264.rc.template")

[openh264.rc.template](/cisco/openh264/blob/master/openh264.rc.template "openh264.rc.template")

[run\_Test.sh](/cisco/openh264/blob/master/run_Test.sh "run_Test.sh")

[run\_Test.sh](/cisco/openh264/blob/master/run_Test.sh "run_Test.sh")

[settings.gradle](/cisco/openh264/blob/master/settings.gradle "settings.gradle")

[settings.gradle](/cisco/openh264/blob/master/settings.gradle "settings.gradle")

[ut.def](/cisco/openh264/blob/master/ut.def "ut.def")

[ut.def](/cisco/openh264/blob/master/ut.def "ut.def")

View all files

## Repository files navigation

-   [README](#)
-   [BSD-2-Clause license](#)
-   [Security](#)

# OpenH264

[](#openh264)

OpenH264 is a codec library which supports H.264 encoding and decoding. It is suitable for use in real time applications such as WebRTC. See [http://www.openh264.org/](http://www.openh264.org/) for more details.

## Encoder Features

[](#encoder-features)

-   Constrained Baseline Profile up to Level 5.2 (Max frame size is 36864 macro-blocks)
-   Arbitrary resolution, not constrained to multiples of 16x16
-   Rate control with adaptive quantization, or constant quantization
-   Slice options: 1 slice per frame, N slices per frame, N macroblocks per slice, or N bytes per slice
-   Multiple threads automatically used for multiple slices
-   Temporal scalability up to 4 layers in a dyadic hierarchy
-   Simulcast AVC up to 4 resolutions from a single input
-   Spatial simulcast up to 4 resolutions from a single input
-   Long Term Reference (LTR) frames
-   Memory Management Control Operation (MMCO)
-   Reference picture list modification
-   Single reference frame for inter prediction
-   Multiple reference frames when using LTR and/or 3-4 temporal layers
-   Periodic and on-demand Instantaneous Decoder Refresh (IDR) frame insertion
-   Dynamic changes to bit rate, frame rate, and resolution
-   Annex B byte stream output
-   YUV 4:2:0 planar input

## Decoder Features

[](#decoder-features)

-   Constrained Baseline Profile up to Level 5.2 (Max frame size is 36864 macro-blocks)
-   Arbitrary resolution, not constrained to multiples of 16x16
-   Single thread for all slices
-   Long Term Reference (LTR) frames
-   Memory Management Control Operation (MMCO)
-   Reference picture list modification
-   Multiple reference frames when specified in Sequence Parameter Set (SPS)
-   Annex B byte stream input
-   YUV 4:2:0 planar output

## OS Support

[](#os-support)

-   Windows 64-bit and 32-bit
-   Mac OS X 64-bit and 32-bit
-   Mac OS X ARM64
-   Linux 64-bit and 32-bit
-   Android 64-bit and 32-bit
-   iOS 64-bit and 32-bit
-   Windows Phone 32-bit

## Architectures verified to be working

[](#architectures-verified-to-be-working)

-   ppc64el

## Processor Support

[](#processor-support)

-   Intel x86 optionally with MMX/SSE (no AVX yet, help is welcome)
-   ARMv7 optionally with NEON, AArch64 optionally with NEON
-   Any architecture using C/C++ fallback functions

## Building the Library

[](#building-the-library)

NASM needed to be installed for assembly code: workable version 2.10.06 or above, NASM can be downloaded from [http://www.nasm.us/](http://www.nasm.us/). For Mac OSX 64-bit NASM needed to be below version 2.11.08 as NASM 2.11.08 will introduce error when using RIP-relative addresses in Mac OSX 64-bit

To build the arm assembly for Windows Phone, gas-preprocessor is required. It can be downloaded from git://git.libav.org/gas-preprocessor.git

## For Android Builds

[](#for-android-builds)

To build for android platform, You need to install android sdk and ndk. You also need to export `**ANDROID_SDK**/tools` to PATH. On Linux, this can be done by

```
export PATH=**ANDROID_SDK**/tools:$PATH
```

The codec and demo can be built by

```
make OS=android NDKROOT=**ANDROID_NDK** TARGET=**ANDROID_TARGET**
```

Valid `**ANDROID_TARGET**` can be found in `**ANDROID_SDK**/platforms`, such as `android-12`. You can also set `ARCH`, `NDKLEVEL` according to your device and NDK version. `ARCH` specifies the architecture of android device. Currently `arm`, `arm64`, `x86` and `x86_64` are supported, the default is `arm`. (`mips` and `mips64` can also be used, but there's no specific optimization for those architectures.) `NDKLEVEL` specifies android api level, the default is 12. Available possibilities can be found in `**ANDROID_NDK**/platforms`, such as `android-21` (strip away the `android-` prefix).

By default these commands build for the `armeabi-v7a` ABI. To build for the other android ABIs, add `ARCH=arm64`, `ARCH=x86`, `ARCH=x86_64`, `ARCH=mips` or `ARCH=mips64`. To build for the older `armeabi` ABI (which has armv5te as baseline), add `APP_ABI=armeabi` (`ARCH=arm` is implicit). To build for 64-bit ABI, such as `arm64`, explicitly set `NDKLEVEL` to 21 or higher.

## For iOS Builds

[](#for-ios-builds)

You can build the libraries and demo applications using xcode project files located in `codec/build/iOS/dec` and `codec/build/iOS/enc`.

You can also build the libraries (but not the demo applications) using the make based build system from the command line. Build with

```
make OS=ios ARCH=**ARCH**
```

Valid values for `**ARCH**` are the normal iOS architecture names such as `armv7`, `armv7s`, `arm64`, and `i386` and `x86_64` for the simulator. Another settable iOS specific parameter is `SDK_MIN`, specifying the minimum deployment target for the built library. For other details on building using make on the command line, see 'For All Platforms' below.

## For Linux Builds

[](#for-linux-builds)

You can build the libraries (but not the demo applications) using the make based build system from the command line. Build with

```
make OS=linux ARCH=**ARCH**
```

You can set `ARCH` according to your linux device . `ARCH` specifies the architecture of the device. Currently `arm`, `arm64`, `x86` and `x86_64` are supported

NOTICE: If your computer is x86 architecture, for build the libnary which be used on arm/aarch64 machine, you may need to use cross-compiler, for example: make OS=linux CC=aarch64-linux-gnu-gcc CXX=aarch64-linux-gnu-g++ ARCH=arm64 or make OS=linux CC=arm-linux-gnueabi-gcc CXX=arm-linux-gnueabi-g++ ARCH=arm

## For Windows Builds

[](#for-windows-builds)

"make" must be installed. It is recommended to install the Cygwin and "make" must be selected to be included in the installation. After the installation, please add the Cygwin bin path to your PATH.

openh264/build/AutoBuildForWindows.bat is provided to help compile the libraries on Windows platform.  
Usage of the .bat script:

```
`AutoBuildForWindows.bat Win32-Release-ASM` for x86 Release build  
`AutoBuildForWindows.bat Win64-Release-ASM` for x86_64 Release build  
`AutoBuildForWindows.bat ARM64-Release-ASM` for arm64 release build  
```

for more usage, please refer to the .bat script help.

## For All Platforms

[](#for-all-platforms)

## Using make

[](#using-make)

From the main project directory:

-   `make` for automatically detecting architecture and building accordingly
-   `make ARCH=i386` for x86 32-bit builds
-   `make ARCH=x86_64` for x86 64-bit builds
-   `make ARCH=arm64` for arm64 Mac 64-bit builds
-   `make V=No` for a silent build (not showing the actual compiler commands)
-   `make DEBUGSYMBOLS=True` for two libraries, one is normal libraries, another one is removed the debugging symbol table entries (those created by the -g option)

The command line programs `h264enc` and `h264dec` will appear in the main project directory.

A shell script to run the command-line apps is in `testbin/CmdLineExample.sh`

Usage information can be found in `testbin/CmdLineReadMe`

## Using meson

[](#using-meson)

Meson build definitions have been added, and are known to work on Linux and Windows, for x86 and x86 64-bit.

See [http://mesonbuild.com/Installing.html](http://mesonbuild.com/Installing.html) for instructions on how to install meson, then:

meson setup builddir
ninja -C builddir

Run the tests with:

meson test -C builddir -v

Install with:

ninja -C builddir install

## Using the Source

[](#using-the-source)

-   `codec` - encoder, decoder, console (test app), build (makefile, vcproj)
-   `build` - scripts for Makefile build system
-   `test` - GTest unittest files
-   `testbin` - autobuild scripts, test app config files
-   `res` - yuv and bitstream test files

## Known Issues

[](#known-issues)

See the issue tracker on [https://github.com/cisco/openh264/issues](https://github.com/cisco/openh264/issues)

-   Encoder errors when resolution exceeds 3840x2160
-   Encoder errors when compressed frame size exceeds half uncompressed size
-   Decoder errors when compressed frame size exceeds 1MB
-   Encoder RC requires frame skipping to be enabled to hit the target bitrate, if frame skipping is disabled the target bitrate may be exceeded

## License

[](#license)

BSD, see `LICENSE` file for details.

## About

Open Source H.264 Codec

### Resources

[Readme](#readme-ov-file)

### License

[BSD-2-Clause license](#BSD-2-Clause-1-ov-file)

### Security policy

[Security policy](#security-ov-file)

### Uh oh!

There was an error while loading. Please reload this page.

[Activity](/cisco/openh264/activity)

[Custom properties](/cisco/openh264/custom-properties)

### Stars

[**6.1k** stars](/cisco/openh264/stargazers)

### Watchers

[**512** watching](/cisco/openh264/watchers)

### Forks

[**1.9k** forks](/cisco/openh264/forks)

[Report repository](/contact/report-content?content_url=https%3A%2F%2Fgithub.com%2Fcisco%2Fopenh264&report=cisco+%28user%29)

## [Releases 20](/cisco/openh264/releases)

[

Release Version 2.6.0 Latest

Feb 12, 2025



](/cisco/openh264/releases/tag/v2.6.0)

[\+ 19 releases](/cisco/openh264/releases)

## [Packages 0](/orgs/cisco/packages?repo_name=openh264)

No packages published  

### Uh oh!

There was an error while loading. Please reload this page.

## [Contributors 128](/cisco/openh264/graphs/contributors)

### Uh oh!

There was an error while loading. Please reload this page.

[\+ 114 contributors](/cisco/openh264/graphs/contributors)

## Languages

-   [C++ 59.9%](/cisco/openh264/search?l=c%2B%2B)
-   [Assembly 19.7%](/cisco/openh264/search?l=assembly)
-   [C 16.1%](/cisco/openh264/search?l=c)
-   [Shell 1.4%](/cisco/openh264/search?l=shell)
-   [Makefile 0.9%](/cisco/openh264/search?l=makefile)
-   [Objective-C 0.6%](/cisco/openh264/search?l=objective-c)
-   Other 1.4%

## Footer

[](https://github.com)© 2026 GitHub, Inc.

### Footer navigation

-   [Terms](https://docs.github.com/site-policy/github-terms/github-terms-of-service)
-   [Privacy](https://docs.github.com/site-policy/privacy-policies/github-privacy-statement)
-   [Security](https://github.com/security)
-   [Status](https://www.githubstatus.com/)
-   [Community](https://github.community/)
-   [Docs](https://docs.github.com/)
-   [Contact](https://support.github.com?tags=dotcom-footer)
-   Manage cookies
-   Do not share my personal information

You can’t perform that action at this time.
```
```

```
Tool: webfetch

**Input:**
```json
{
  "url": "https://github.com/cisco/openh264/wiki/FAQ",
  "format": "markdown",
  "timeout": 60
}
```
**Output:**
```
                  Home · cisco/openh264 Wiki · GitHub                                           

[Skip to content](#start-of-content)   

## Navigation Menu

Toggle navigation

[](/)

[Sign in](/login?return_to=https%3A%2F%2Fgithub.com%2Fcisco%2Fopenh264%2Fwiki%2F)

Appearance settings

  

-   Platform
    
    -   AI CODE CREATION
        
        -   [
            
            GitHub CopilotWrite better code with AI
            
            ](https://github.com/features/copilot)
        -   [
            
            GitHub SparkBuild and deploy intelligent apps
            
            ](https://github.com/features/spark)
        -   [
            
            GitHub ModelsManage and compare prompts
            
            ](https://github.com/features/models)
        -   [
            
            MCP RegistryNewIntegrate external tools
            
            ](https://github.com/mcp)
        
    -   DEVELOPER WORKFLOWS
        
        -   [
            
            ActionsAutomate any workflow
            
            ](https://github.com/features/actions)
        -   [
            
            CodespacesInstant dev environments
            
            ](https://github.com/features/codespaces)
        -   [
            
            IssuesPlan and track work
            
            ](https://github.com/features/issues)
        -   [
            
            Code ReviewManage code changes
            
            ](https://github.com/features/code-review)
        
    -   APPLICATION SECURITY
        
        -   [
            
            GitHub Advanced SecurityFind and fix vulnerabilities
            
            ](https://github.com/security/advanced-security)
        -   [
            
            Code securitySecure your code as you build
            
            ](https://github.com/security/advanced-security/code-security)
        -   [
            
            Secret protectionStop leaks before they start
            
            ](https://github.com/security/advanced-security/secret-protection)
        
    -   EXPLORE
        
        -   [Why GitHub](https://github.com/why-github)
        -   [Documentation](https://docs.github.com)
        -   [Blog](https://github.blog)
        -   [Changelog](https://github.blog/changelog)
        -   [Marketplace](https://github.com/marketplace)
        
    
    [View all features](https://github.com/features)
    
-   Solutions
    
    -   BY COMPANY SIZE
        
        -   [Enterprises](https://github.com/enterprise)
        -   [Small and medium teams](https://github.com/team)
        -   [Startups](https://github.com/enterprise/startups)
        -   [Nonprofits](https://github.com/solutions/industry/nonprofits)
        
    -   BY USE CASE
        
        -   [App Modernization](https://github.com/solutions/use-case/app-modernization)
        -   [DevSecOps](https://github.com/solutions/use-case/devsecops)
        -   [DevOps](https://github.com/solutions/use-case/devops)
        -   [CI/CD](https://github.com/solutions/use-case/ci-cd)
        -   [View all use cases](https://github.com/solutions/use-case)
        
    -   BY INDUSTRY
        
        -   [Healthcare](https://github.com/solutions/industry/healthcare)
        -   [Financial services](https://github.com/solutions/industry/financial-services)
        -   [Manufacturing](https://github.com/solutions/industry/manufacturing)
        -   [Government](https://github.com/solutions/industry/government)
        -   [View all industries](https://github.com/solutions/industry)
        
    
    [View all solutions](https://github.com/solutions)
    
-   Resources
    
    -   EXPLORE BY TOPIC
        
        -   [AI](https://github.com/resources/articles?topic=ai)
        -   [Software Development](https://github.com/resources/articles?topic=software-development)
        -   [DevOps](https://github.com/resources/articles?topic=devops)
        -   [Security](https://github.com/resources/articles?topic=security)
        -   [View all topics](https://github.com/resources/articles)
        
    -   EXPLORE BY TYPE
        
        -   [Customer stories](https://github.com/customer-stories)
        -   [Events & webinars](https://github.com/resources/events)
        -   [Ebooks & reports](https://github.com/resources/whitepapers)
        -   [Business insights](https://github.com/solutions/executive-insights)
        -   [GitHub Skills](https://skills.github.com)
        
    -   SUPPORT & SERVICES
        
        -   [Documentation](https://docs.github.com)
        -   [Customer support](https://support.github.com)
        -   [Community forum](https://github.com/orgs/community/discussions)
        -   [Trust center](https://github.com/trust-center)
        -   [Partners](https://github.com/partners)
        
    
-   Open Source
    
    -   COMMUNITY
        
        -   [
            
            GitHub SponsorsFund open source developers
            
            ](https://github.com/sponsors)
        
    -   PROGRAMS
        
        -   [Security Lab](https://securitylab.github.com)
        -   [Maintainer Community](https://maintainers.github.com)
        -   [Accelerator](https://github.com/accelerator)
        -   [Archive Program](https://archiveprogram.github.com)
        
    -   REPOSITORIES
        
        -   [Topics](https://github.com/topics)
        -   [Trending](https://github.com/trending)
        -   [Collections](https://github.com/collections)
        
    
-   Enterprise
    
    -   ENTERPRISE SOLUTIONS
        
        -   [
            
            Enterprise platformAI-powered developer platform
            
            ](https://github.com/enterprise)
        
    -   AVAILABLE ADD-ONS
        
        -   [
            
            GitHub Advanced SecurityEnterprise-grade security features
            
            ](https://github.com/security/advanced-security)
        -   [
            
            Copilot for BusinessEnterprise-grade AI features
            
            ](https://github.com/features/copilot/copilot-business)
        -   [
            
            Premium SupportEnterprise-grade 24/7 support
            
            ](https://github.com/premium-support)
        
    
-   [Pricing](https://github.com/pricing)

Search or jump to...

# Search code, repositories, users, issues, pull requests...

Search

Clear

[Search syntax tips](https://docs.github.com/search-github/github-code-search/understanding-github-code-search-syntax)

# Provide feedback

We read every piece of feedback, and take your input very seriously.

 Include my email address so I can be contacted

Cancel Submit feedback

# Saved searches

## Use saved searches to filter your results more quickly

Name  

Query 

To see all available qualifiers, see our [documentation](https://docs.github.com/search-github/github-code-search/understanding-github-code-search-syntax).

Cancel Create saved search

[Sign in](/login?return_to=https%3A%2F%2Fgithub.com%2Fcisco%2Fopenh264%2Fwiki%2F)

[Sign up](/signup?ref_cta=Sign+up&ref_loc=header+logged+out&ref_page=%2F%3Cuser-name%3E%2F%3Crepo-name%3E%2Fwiki%2Findex&source=header-repo&source_repo=cisco%2Fopenh264)

Appearance settings

Resetting focus

You signed in with another tab or window. Reload to refresh your session. You signed out in another tab or window. Reload to refresh your session. You switched accounts on another tab or window. Reload to refresh your session. Dismiss alert

[cisco](/cisco) / **[openh264](/cisco/openh264)** Public

-   [Notifications](/login?return_to=%2Fcisco%2Fopenh264) You must be signed in to change notification settings
-   [Fork 1.9k](/login?return_to=%2Fcisco%2Fopenh264)
-   [Star 6.1k](/login?return_to=%2Fcisco%2Fopenh264)
    

-   [Code](/cisco/openh264)
-   [Issues 258](/cisco/openh264/issues)
-   [Pull requests 29](/cisco/openh264/pulls)
-   [Actions](/cisco/openh264/actions)
-   [Projects 0](/cisco/openh264/projects)
-   [Wiki](/cisco/openh264/wiki)
-   [Security 1](/cisco/openh264/security)
-   [Insights](/cisco/openh264/pulse)

Additional navigation options

-   [Code](/cisco/openh264)
-   [Issues](/cisco/openh264/issues)
-   [Pull requests](/cisco/openh264/pulls)
-   [Actions](/cisco/openh264/actions)
-   [Projects](/cisco/openh264/projects)
-   [Wiki](/cisco/openh264/wiki)
-   [Security](/cisco/openh264/security)
-   [Insights](/cisco/openh264/pulse)

# Home

[Jump to bottom](#wiki-pages-box)

HaiboZhu edited this page Jul 22, 2016 · [10 revisions](/cisco/openh264/wiki/Home/_history)

# OpenH264

[](#openh264)

OpenH264 is a codec library which supports H.264 encoding and decoding. It is suitable for use in real time applications such as WebRTC. See [http://www.openh264.org/](http://www.openh264.org/) for more details.

## Encoder Features

[](#encoder-features)

-   Constrained Baseline Profile up to Level 5.2 (Max frame size is 36864 macro-blocks)
-   Arbitrary resolution, not constrained to multiples of 16x16
-   Rate control with adaptive quantization, or constant quantization
-   Slice options: 1 slice per frame, N slices per frame, N macroblocks per slice, or N bytes per slice
-   Multiple threads automatically used for multiple slices
-   Temporal scalability up to 4 layers in a dyadic hierarchy
-   Spatial simulcast up to 4 resolutions from a single input
-   Long Term Reference (LTR) frames
-   Memory Management Control Operation (MMCO)
-   Reference picture list modification
-   Single reference frame for inter prediction
-   Multiple reference frames when using LTR and/or 3-4 temporal layers
-   Periodic and on-demand Instantaneous Decoder Refresh (IDR) frame insertion
-   Dynamic changes to bit rate, frame rate, and resolution
-   Annex B byte stream output
-   YUV 4:2:0 planar input

## Decoder Features

[](#decoder-features)

-   Constrained Baseline Profile up to Level 5.2 (Max frame size is 36864 macro-blocks)
-   Arbitrary resolution, not constrained to multiples of 16x16
-   Single thread for all slices
-   Long Term Reference (LTR) frames
-   Memory Management Control Operation (MMCO)
-   Reference picture list modification
-   Multiple reference frames when specified in Sequence Parameter Set (SPS)
-   Annex B byte stream input
-   YUV 4:2:0 planar output

## OS Support

[](#os-support)

-   Windows 64-bit and 32-bit
-   Mac OS X 64-bit and 32-bit
-   Linux 64-bit and 32-bit
-   Android 64-bit and 32-bit
-   iOS 64-bit and 32-bit
-   Windows Phone 32-bit

## Processor Support

[](#processor-support)

-   Intel x86 optionally with MMX/SSE/AVX (help is welcome)
-   ARMv7 optionally with NEON, AArch64 optionally with NEON
-   Any architecture using C/C++ fallback functions

## Building the Library

[](#building-the-library)

NASM needed to be installed for assembly code: workable version 2.07 or above, nasm can downloaded from [http://www.nasm.us/](http://www.nasm.us/) For Mac OSX 64-bit NASM needed to be below version 2.11.08 as nasm 2.11.08 will introduce error when using RIP-relative addresses in Mac OSX 64-bit

To build the arm assembly for Windows Phone, gas-preprocessor is required. It can be downloaded from git://git.libav.org/gas-preprocessor.git

## For Android Builds

[](#for-android-builds)

To build for android platform, You need to install android sdk and ndk. You also need to export \*\*ANDROID\_SDK\*\*/tools to PATH. On Linux, this can be done by

> export PATH=\*\*ANDROID\_SDK\*\*/tools:$PATH

The codec and demo can be built by

> make OS=android NDKROOT=\*\*ANDROID\_NDK\*\* TARGET=\*\*ANDROID\_TARGET\*\*

Valid \*\*ANDROID\_TARGET\*\* can be found in \*\*ANDROID\_SDK\*\*/platforms, such as android-12. You can also set ARCH, NDKLEVEL according to your device and NDK version. ARCH specifies the architecture of android device. Currently arm, arm64, x86 and x86\_64 are supported, the default is arm. (mips and mips64 can also be used, but there's no specific optimization for those architectures.) NDKLEVEL specifies android api level, the api level can be 12-19, the default is 12.

By default these commands build for the armeabi-v7a ABI. To build for the other android ABIs, add ARCH=arm64, ARCH=x86, ARCH=x86\_64, ARCH=mips or ARCH=mips64. To build for the older armeabi ABI (which has armv5te as baseline), add APP\_ABI=armeabi (ARCH=arm is implicit).

## For iOS Builds

[](#for-ios-builds)

You can build the libraries and demo applications using xcode project files located in codec/build/iOS/dec and codec/build/iOS/enc.

You can also build the libraries (but not the demo applications) using the make based build system from the command line. Build with

> make OS=ios ARCH=\*\*ARCH\*\*

Valid values for \*\*ARCH\*\* are the normal iOS architecture names such as armv7, armv7s, arm64, and i386 and x86\_64 for the simulator. Another settable iOS specific parameter is SDK\_MIN, specifying the minimum deployment target for the built library. For other details on building using make on the command line, see 'For All Platforms' below.

## For Windows Builds

[](#for-windows-builds)

Our Windows builds use MinGW which can be found here - [http://www.mingw.org/](http://www.mingw.org/)

To build with gcc, add the MinGW bin directory (e.g. /c/MinGW/bin) to your path and follow the 'For All Platforms' instructions below.

To build with Visual Studio you will need to set up your path to run cl.exe. The easiest way is to start MSYS from a developer command line session - [http://msdn.microsoft.com/en-us/library/ms229859(v=vs.110).aspx](http://msdn.microsoft.com/en-us/library/ms229859\(v=vs.110\).aspx) If you need to do it by hand here is an example from a Windows 64bit install of VS2012:

> export PATH="$PATH:/c/Program Files (x86)/Microsoft Visual Studio 11.0/VC/bin:/c/Program Files (x86)/Microsoft Visual Studio 11.0/Common7/IDE"

You will also need to set your INCLUDE and LIB paths to point to your VS and SDK installs. Something like this, again from Win64 with VS2012 (note the use of Windows-style paths here).

> export INCLUDE="C:Program Files (x86)Microsoft Visual Studio 11.0VCinclude;C:Program Files (x86)Windows Kits8.0Includeum;C:Program Files (x86)Windows Kits8.0Includeshared" export LIB="C:Program Files (x86)Windows Kits8.0LibWin8umx86;C:Program Files (x86)Microsoft Visual Studio 11.0VClib"

Then add OS=msvc to the make line of the 'For All Platforms' instructions.

## For Windows Phone builds

[](#for-windows-phone-builds)

Follow the instructions above for normal Windows builds, but use OS=msvc-wp instead of OS=msvc. You will also need gas-preprocessor (as mentioned below "Building the Library").

If building for Windows Phone with MSVC 2013, there's no included bat file that sets the lib paths to the Windows Phone kit, but that can be done with a command like this:

> export LIB="c:Program Files (x86)Microsoft Visual Studio 12.0VClibstorearm;c:Program Files (x86)Microsoft Visual Studio 12.0VClibarm;c:Program Files (x86)Windows Phone Kits8.1libarm"

This is only necessary for building the DLL; the static library can be built without setting this.

## For All Platforms

[](#for-all-platforms)

From the main project directory: - make for automatically detecting architecture and building accordingly - make ARCH=i386 for x86 32bit builds - make ARCH=x86\_64 for x86 64bit builds - make V=No for a silent build (not showing the actual compiler commands)

The command line programs h264enc and h264dec will appear in the main project directory.

A shell script to run the command-line apps is in testbin/CmdLineExample.sh

Usage information can be found in testbin/CmdLineReadMe

## Using the Source

[](#using-the-source)

-   codec - encoder, decoder, console (test app), build (makefile, vcproj)
-   build - scripts for Makefile build system.
-   test - GTest unittest files.
-   testbin - autobuild scripts, test app config files
-   res - yuv and bitstream test files

## Known Issues

[](#known-issues)

See the issue tracker on [https://github.com/cisco/openh264/issues](https://github.com/cisco/openh264/issues) - Encoder errors when resolution exceeds 3840x2160 - Encoder errors when compressed frame size exceeds half uncompressed size - Decoder errors when compressed frame size exceeds 1MB - Encoder RC requires frame skipping to be enabled to hit the target bitrate,

> if frame skipping is disabled the target bitrate may be exceeded

## License

[](#license)

BSD, see LICENSE file for details.

footer

## Toggle table of contents Pages 7

-   Loading[
    
    Home
    
    ](/cisco/openh264/wiki)
    
    -   [OpenH264](/cisco/openh264/wiki#openh264)
    -   [Encoder Features](/cisco/openh264/wiki#encoder-features)
    -   [Decoder Features](/cisco/openh264/wiki#decoder-features)
    -   [OS Support](/cisco/openh264/wiki#os-support)
    -   [Processor Support](/cisco/openh264/wiki#processor-support)
    -   [Building the Library](/cisco/openh264/wiki#building-the-library)
    -   [For Android Builds](/cisco/openh264/wiki#for-android-builds)
    -   [For iOS Builds](/cisco/openh264/wiki#for-ios-builds)
    -   [For Windows Builds](/cisco/openh264/wiki#for-windows-builds)
    -   [For Windows Phone builds](/cisco/openh264/wiki#for-windows-phone-builds)
    -   [For All Platforms](/cisco/openh264/wiki#for-all-platforms)
    -   [Using the Source](/cisco/openh264/wiki#using-the-source)
    -   [Known Issues](/cisco/openh264/wiki#known-issues)
    -   [License](/cisco/openh264/wiki#license)
    
-   Loading[
    
    API2Wiki
    
    ](/cisco/openh264/wiki/API2Wiki)
    
    ### Uh oh!
    
    There was an error while loading. Please reload this page.
    
-   Loading[
    
    ISVCDecoder
    
    ](/cisco/openh264/wiki/ISVCDecoder)
    
    ### Uh oh!
    
    There was an error while loading. Please reload this page.
    
-   Loading[
    
    ISVCEncoder
    
    ](/cisco/openh264/wiki/ISVCEncoder)
    
    ### Uh oh!
    
    There was an error while loading. Please reload this page.
    
-   Loading[
    
    TypesAndStructures
    
    ](/cisco/openh264/wiki/TypesAndStructures)
    
    ### Uh oh!
    
    There was an error while loading. Please reload this page.
    
-   Loading[
    
    UsageExampleForDecoder
    
    ](/cisco/openh264/wiki/UsageExampleForDecoder)
    
    ### Uh oh!
    
    There was an error while loading. Please reload this page.
    
-   Loading[
    
    UsageExampleForEncoder
    
    ](/cisco/openh264/wiki/UsageExampleForEncoder)
    
    ### Uh oh!
    
    There was an error while loading. Please reload this page.
    

### Clone this wiki locally

## Footer

[](https://github.com)© 2026 GitHub, Inc.

### Footer navigation

-   [Terms](https://docs.github.com/site-policy/github-terms/github-terms-of-service)
-   [Privacy](https://docs.github.com/site-policy/privacy-policies/github-privacy-statement)
-   [Security](https://github.com/security)
-   [Status](https://www.githubstatus.com/)
-   [Community](https://github.community/)
-   [Docs](https://docs.github.com/)
-   [Contact](https://support.github.com?tags=dotcom-footer)
-   Manage cookies
-   Do not share my personal information

You can’t perform that action at this time.
```
```

```
Tool: webfetch

**Input:**
```json
{
  "url": "https://github.com/cisco/openh264/wiki",
  "format": "markdown",
  "timeout": 60
}
```
**Output:**
```
                  Home · cisco/openh264 Wiki · GitHub                                           

[Skip to content](#start-of-content)   

## Navigation Menu

Toggle navigation

[](/)

[Sign in](/login?return_to=https%3A%2F%2Fgithub.com%2Fcisco%2Fopenh264%2Fwiki)

Appearance settings

  

-   Platform
    
    -   AI CODE CREATION
        
        -   [
            
            GitHub CopilotWrite better code with AI
            
            ](https://github.com/features/copilot)
        -   [
            
            GitHub SparkBuild and deploy intelligent apps
            
            ](https://github.com/features/spark)
        -   [
            
            GitHub ModelsManage and compare prompts
            
            ](https://github.com/features/models)
        -   [
            
            MCP RegistryNewIntegrate external tools
            
            ](https://github.com/mcp)
        
    -   DEVELOPER WORKFLOWS
        
        -   [
            
            ActionsAutomate any workflow
            
            ](https://github.com/features/actions)
        -   [
            
            CodespacesInstant dev environments
            
            ](https://github.com/features/codespaces)
        -   [
            
            IssuesPlan and track work
            
            ](https://github.com/features/issues)
        -   [
            
            Code ReviewManage code changes
            
            ](https://github.com/features/code-review)
        
    -   APPLICATION SECURITY
        
        -   [
            
            GitHub Advanced SecurityFind and fix vulnerabilities
            
            ](https://github.com/security/advanced-security)
        -   [
            
            Code securitySecure your code as you build
            
            ](https://github.com/security/advanced-security/code-security)
        -   [
            
            Secret protectionStop leaks before they start
            
            ](https://github.com/security/advanced-security/secret-protection)
        
    -   EXPLORE
        
        -   [Why GitHub](https://github.com/why-github)
        -   [Documentation](https://docs.github.com)
        -   [Blog](https://github.blog)
        -   [Changelog](https://github.blog/changelog)
        -   [Marketplace](https://github.com/marketplace)
        
    
    [View all features](https://github.com/features)
    
-   Solutions
    
    -   BY COMPANY SIZE
        
        -   [Enterprises](https://github.com/enterprise)
        -   [Small and medium teams](https://github.com/team)
        -   [Startups](https://github.com/enterprise/startups)
        -   [Nonprofits](https://github.com/solutions/industry/nonprofits)
        
    -   BY USE CASE
        
        -   [App Modernization](https://github.com/solutions/use-case/app-modernization)
        -   [DevSecOps](https://github.com/solutions/use-case/devsecops)
        -   [DevOps](https://github.com/solutions/use-case/devops)
        -   [CI/CD](https://github.com/solutions/use-case/ci-cd)
        -   [View all use cases](https://github.com/solutions/use-case)
        
    -   BY INDUSTRY
        
        -   [Healthcare](https://github.com/solutions/industry/healthcare)
        -   [Financial services](https://github.com/solutions/industry/financial-services)
        -   [Manufacturing](https://github.com/solutions/industry/manufacturing)
        -   [Government](https://github.com/solutions/industry/government)
        -   [View all industries](https://github.com/solutions/industry)
        
    
    [View all solutions](https://github.com/solutions)
    
-   Resources
    
    -   EXPLORE BY TOPIC
        
        -   [AI](https://github.com/resources/articles?topic=ai)
        -   [Software Development](https://github.com/resources/articles?topic=software-development)
        -   [DevOps](https://github.com/resources/articles?topic=devops)
        -   [Security](https://github.com/resources/articles?topic=security)
        -   [View all topics](https://github.com/resources/articles)
        
    -   EXPLORE BY TYPE
        
        -   [Customer stories](https://github.com/customer-stories)
        -   [Events & webinars](https://github.com/resources/events)
        -   [Ebooks & reports](https://github.com/resources/whitepapers)
        -   [Business insights](https://github.com/solutions/executive-insights)
        -   [GitHub Skills](https://skills.github.com)
        
    -   SUPPORT & SERVICES
        
        -   [Documentation](https://docs.github.com)
        -   [Customer support](https://support.github.com)
        -   [Community forum](https://github.com/orgs/community/discussions)
        -   [Trust center](https://github.com/trust-center)
        -   [Partners](https://github.com/partners)
        
    
-   Open Source
    
    -   COMMUNITY
        
        -   [
            
            GitHub SponsorsFund open source developers
            
            ](https://github.com/sponsors)
        
    -   PROGRAMS
        
        -   [Security Lab](https://securitylab.github.com)
        -   [Maintainer Community](https://maintainers.github.com)
        -   [Accelerator](https://github.com/accelerator)
        -   [Archive Program](https://archiveprogram.github.com)
        
    -   REPOSITORIES
        
        -   [Topics](https://github.com/topics)
        -   [Trending](https://github.com/trending)
        -   [Collections](https://github.com/collections)
        
    
-   Enterprise
    
    -   ENTERPRISE SOLUTIONS
        
        -   [
            
            Enterprise platformAI-powered developer platform
            
            ](https://github.com/enterprise)
        
    -   AVAILABLE ADD-ONS
        
        -   [
            
            GitHub Advanced SecurityEnterprise-grade security features
            
            ](https://github.com/security/advanced-security)
        -   [
            
            Copilot for BusinessEnterprise-grade AI features
            
            ](https://github.com/features/copilot/copilot-business)
        -   [
            
            Premium SupportEnterprise-grade 24/7 support
            
            ](https://github.com/premium-support)
        
    
-   [Pricing](https://github.com/pricing)

Search or jump to...

# Search code, repositories, users, issues, pull requests...

Search

Clear

[Search syntax tips](https://docs.github.com/search-github/github-code-search/understanding-github-code-search-syntax)

# Provide feedback

We read every piece of feedback, and take your input very seriously.

 Include my email address so I can be contacted

Cancel Submit feedback

# Saved searches

## Use saved searches to filter your results more quickly

Name  

Query 

To see all available qualifiers, see our [documentation](https://docs.github.com/search-github/github-code-search/understanding-github-code-search-syntax).

Cancel Create saved search

[Sign in](/login?return_to=https%3A%2F%2Fgithub.com%2Fcisco%2Fopenh264%2Fwiki)

[Sign up](/signup?ref_cta=Sign+up&ref_loc=header+logged+out&ref_page=%2F%3Cuser-name%3E%2F%3Crepo-name%3E%2Fwiki%2Findex&source=header-repo&source_repo=cisco%2Fopenh264)

Appearance settings

Resetting focus

You signed in with another tab or window. Reload to refresh your session. You signed out in another tab or window. Reload to refresh your session. You switched accounts on another tab or window. Reload to refresh your session. Dismiss alert

[cisco](/cisco) / **[openh264](/cisco/openh264)** Public

-   [Notifications](/login?return_to=%2Fcisco%2Fopenh264) You must be signed in to change notification settings
-   [Fork 1.9k](/login?return_to=%2Fcisco%2Fopenh264)
-   [Star 6.1k](/login?return_to=%2Fcisco%2Fopenh264)
    

-   [Code](/cisco/openh264)
-   [Issues 258](/cisco/openh264/issues)
-   [Pull requests 29](/cisco/openh264/pulls)
-   [Actions](/cisco/openh264/actions)
-   [Projects 0](/cisco/openh264/projects)
-   [Wiki](/cisco/openh264/wiki)
-   [Security 1](/cisco/openh264/security)
-   [Insights](/cisco/openh264/pulse)

Additional navigation options

-   [Code](/cisco/openh264)
-   [Issues](/cisco/openh264/issues)
-   [Pull requests](/cisco/openh264/pulls)
-   [Actions](/cisco/openh264/actions)
-   [Projects](/cisco/openh264/projects)
-   [Wiki](/cisco/openh264/wiki)
-   [Security](/cisco/openh264/security)
-   [Insights](/cisco/openh264/pulse)

# Home

[Jump to bottom](#wiki-pages-box)

HaiboZhu edited this page Jul 22, 2016 · [10 revisions](/cisco/openh264/wiki/Home/_history)

# OpenH264

[](#openh264)

OpenH264 is a codec library which supports H.264 encoding and decoding. It is suitable for use in real time applications such as WebRTC. See [http://www.openh264.org/](http://www.openh264.org/) for more details.

## Encoder Features

[](#encoder-features)

-   Constrained Baseline Profile up to Level 5.2 (Max frame size is 36864 macro-blocks)
-   Arbitrary resolution, not constrained to multiples of 16x16
-   Rate control with adaptive quantization, or constant quantization
-   Slice options: 1 slice per frame, N slices per frame, N macroblocks per slice, or N bytes per slice
-   Multiple threads automatically used for multiple slices
-   Temporal scalability up to 4 layers in a dyadic hierarchy
-   Spatial simulcast up to 4 resolutions from a single input
-   Long Term Reference (LTR) frames
-   Memory Management Control Operation (MMCO)
-   Reference picture list modification
-   Single reference frame for inter prediction
-   Multiple reference frames when using LTR and/or 3-4 temporal layers
-   Periodic and on-demand Instantaneous Decoder Refresh (IDR) frame insertion
-   Dynamic changes to bit rate, frame rate, and resolution
-   Annex B byte stream output
-   YUV 4:2:0 planar input

## Decoder Features

[](#decoder-features)

-   Constrained Baseline Profile up to Level 5.2 (Max frame size is 36864 macro-blocks)
-   Arbitrary resolution, not constrained to multiples of 16x16
-   Single thread for all slices
-   Long Term Reference (LTR) frames
-   Memory Management Control Operation (MMCO)
-   Reference picture list modification
-   Multiple reference frames when specified in Sequence Parameter Set (SPS)
-   Annex B byte stream input
-   YUV 4:2:0 planar output

## OS Support

[](#os-support)

-   Windows 64-bit and 32-bit
-   Mac OS X 64-bit and 32-bit
-   Linux 64-bit and 32-bit
-   Android 64-bit and 32-bit
-   iOS 64-bit and 32-bit
-   Windows Phone 32-bit

## Processor Support

[](#processor-support)

-   Intel x86 optionally with MMX/SSE/AVX (help is welcome)
-   ARMv7 optionally with NEON, AArch64 optionally with NEON
-   Any architecture using C/C++ fallback functions

## Building the Library

[](#building-the-library)

NASM needed to be installed for assembly code: workable version 2.07 or above, nasm can downloaded from [http://www.nasm.us/](http://www.nasm.us/) For Mac OSX 64-bit NASM needed to be below version 2.11.08 as nasm 2.11.08 will introduce error when using RIP-relative addresses in Mac OSX 64-bit

To build the arm assembly for Windows Phone, gas-preprocessor is required. It can be downloaded from git://git.libav.org/gas-preprocessor.git

## For Android Builds

[](#for-android-builds)

To build for android platform, You need to install android sdk and ndk. You also need to export \*\*ANDROID\_SDK\*\*/tools to PATH. On Linux, this can be done by

> export PATH=\*\*ANDROID\_SDK\*\*/tools:$PATH

The codec and demo can be built by

> make OS=android NDKROOT=\*\*ANDROID\_NDK\*\* TARGET=\*\*ANDROID\_TARGET\*\*

Valid \*\*ANDROID\_TARGET\*\* can be found in \*\*ANDROID\_SDK\*\*/platforms, such as android-12. You can also set ARCH, NDKLEVEL according to your device and NDK version. ARCH specifies the architecture of android device. Currently arm, arm64, x86 and x86\_64 are supported, the default is arm. (mips and mips64 can also be used, but there's no specific optimization for those architectures.) NDKLEVEL specifies android api level, the api level can be 12-19, the default is 12.

By default these commands build for the armeabi-v7a ABI. To build for the other android ABIs, add ARCH=arm64, ARCH=x86, ARCH=x86\_64, ARCH=mips or ARCH=mips64. To build for the older armeabi ABI (which has armv5te as baseline), add APP\_ABI=armeabi (ARCH=arm is implicit).

## For iOS Builds

[](#for-ios-builds)

You can build the libraries and demo applications using xcode project files located in codec/build/iOS/dec and codec/build/iOS/enc.

You can also build the libraries (but not the demo applications) using the make based build system from the command line. Build with

> make OS=ios ARCH=\*\*ARCH\*\*

Valid values for \*\*ARCH\*\* are the normal iOS architecture names such as armv7, armv7s, arm64, and i386 and x86\_64 for the simulator. Another settable iOS specific parameter is SDK\_MIN, specifying the minimum deployment target for the built library. For other details on building using make on the command line, see 'For All Platforms' below.

## For Windows Builds

[](#for-windows-builds)

Our Windows builds use MinGW which can be found here - [http://www.mingw.org/](http://www.mingw.org/)

To build with gcc, add the MinGW bin directory (e.g. /c/MinGW/bin) to your path and follow the 'For All Platforms' instructions below.

To build with Visual Studio you will need to set up your path to run cl.exe. The easiest way is to start MSYS from a developer command line session - [http://msdn.microsoft.com/en-us/library/ms229859(v=vs.110).aspx](http://msdn.microsoft.com/en-us/library/ms229859\(v=vs.110\).aspx) If you need to do it by hand here is an example from a Windows 64bit install of VS2012:

> export PATH="$PATH:/c/Program Files (x86)/Microsoft Visual Studio 11.0/VC/bin:/c/Program Files (x86)/Microsoft Visual Studio 11.0/Common7/IDE"

You will also need to set your INCLUDE and LIB paths to point to your VS and SDK installs. Something like this, again from Win64 with VS2012 (note the use of Windows-style paths here).

> export INCLUDE="C:Program Files (x86)Microsoft Visual Studio 11.0VCinclude;C:Program Files (x86)Windows Kits8.0Includeum;C:Program Files (x86)Windows Kits8.0Includeshared" export LIB="C:Program Files (x86)Windows Kits8.0LibWin8umx86;C:Program Files (x86)Microsoft Visual Studio 11.0VClib"

Then add OS=msvc to the make line of the 'For All Platforms' instructions.

## For Windows Phone builds

[](#for-windows-phone-builds)

Follow the instructions above for normal Windows builds, but use OS=msvc-wp instead of OS=msvc. You will also need gas-preprocessor (as mentioned below "Building the Library").

If building for Windows Phone with MSVC 2013, there's no included bat file that sets the lib paths to the Windows Phone kit, but that can be done with a command like this:

> export LIB="c:Program Files (x86)Microsoft Visual Studio 12.0VClibstorearm;c:Program Files (x86)Microsoft Visual Studio 12.0VClibarm;c:Program Files (x86)Windows Phone Kits8.1libarm"

This is only necessary for building the DLL; the static library can be built without setting this.

## For All Platforms

[](#for-all-platforms)

From the main project directory: - make for automatically detecting architecture and building accordingly - make ARCH=i386 for x86 32bit builds - make ARCH=x86\_64 for x86 64bit builds - make V=No for a silent build (not showing the actual compiler commands)

The command line programs h264enc and h264dec will appear in the main project directory.

A shell script to run the command-line apps is in testbin/CmdLineExample.sh

Usage information can be found in testbin/CmdLineReadMe

## Using the Source

[](#using-the-source)

-   codec - encoder, decoder, console (test app), build (makefile, vcproj)
-   build - scripts for Makefile build system.
-   test - GTest unittest files.
-   testbin - autobuild scripts, test app config files
-   res - yuv and bitstream test files

## Known Issues

[](#known-issues)

See the issue tracker on [https://github.com/cisco/openh264/issues](https://github.com/cisco/openh264/issues) - Encoder errors when resolution exceeds 3840x2160 - Encoder errors when compressed frame size exceeds half uncompressed size - Decoder errors when compressed frame size exceeds 1MB - Encoder RC requires frame skipping to be enabled to hit the target bitrate,

> if frame skipping is disabled the target bitrate may be exceeded

## License

[](#license)

BSD, see LICENSE file for details.

footer

## Toggle table of contents Pages 7

-   Loading[
    
    Home
    
    ](/cisco/openh264/wiki)
    
    -   [OpenH264](/cisco/openh264/wiki#openh264)
    -   [Encoder Features](/cisco/openh264/wiki#encoder-features)
    -   [Decoder Features](/cisco/openh264/wiki#decoder-features)
    -   [OS Support](/cisco/openh264/wiki#os-support)
    -   [Processor Support](/cisco/openh264/wiki#processor-support)
    -   [Building the Library](/cisco/openh264/wiki#building-the-library)
    -   [For Android Builds](/cisco/openh264/wiki#for-android-builds)
    -   [For iOS Builds](/cisco/openh264/wiki#for-ios-builds)
    -   [For Windows Builds](/cisco/openh264/wiki#for-windows-builds)
    -   [For Windows Phone builds](/cisco/openh264/wiki#for-windows-phone-builds)
    -   [For All Platforms](/cisco/openh264/wiki#for-all-platforms)
    -   [Using the Source](/cisco/openh264/wiki#using-the-source)
    -   [Known Issues](/cisco/openh264/wiki#known-issues)
    -   [License](/cisco/openh264/wiki#license)
    
-   Loading[
    
    API2Wiki
    
    ](/cisco/openh264/wiki/API2Wiki)
    
    ### Uh oh!
    
    There was an error while loading. Please reload this page.
    
-   Loading[
    
    ISVCDecoder
    
    ](/cisco/openh264/wiki/ISVCDecoder)
    
    ### Uh oh!
    
    There was an error while loading. Please reload this page.
    
-   Loading[
    
    ISVCEncoder
    
    ](/cisco/openh264/wiki/ISVCEncoder)
    
    ### Uh oh!
    
    There was an error while loading. Please reload this page.
    
-   Loading[
    
    TypesAndStructures
    
    ](/cisco/openh264/wiki/TypesAndStructures)
    
    ### Uh oh!
    
    There was an error while loading. Please reload this page.
    
-   Loading[
    
    UsageExampleForDecoder
    
    ](/cisco/openh264/wiki/UsageExampleForDecoder)
    
    ### Uh oh!
    
    There was an error while loading. Please reload this page.
    
-   Loading[
    
    UsageExampleForEncoder
    
    ](/cisco/openh264/wiki/UsageExampleForEncoder)
    
    ### Uh oh!
    
    There was an error while loading. Please reload this page.
    

### Clone this wiki locally

## Footer

[](https://github.com)© 2026 GitHub, Inc.

### Footer navigation

-   [Terms](https://docs.github.com/site-policy/github-terms/github-terms-of-service)
-   [Privacy](https://docs.github.com/site-policy/privacy-policies/github-privacy-statement)
-   [Security](https://github.com/security)
-   [Status](https://www.githubstatus.com/)
-   [Community](https://github.community/)
-   [Docs](https://docs.github.com/)
-   [Contact](https://support.github.com?tags=dotcom-footer)
-   Manage cookies
-   Do not share my personal information

You can’t perform that action at this time.
```
```

---

## Assistant (Plan · gpt-5.2 · 16.1s)

_Thinking:_



```
Tool: webfetch

**Input:**
```json
{
  "url": "https://github.com/axiomatic-systems/Bento4",
  "format": "markdown",
  "timeout": 60
}
```
**Output:**
```
                    GitHub - axiomatic-systems/Bento4: Full-featured MP4 format, MPEG DASH, HLS, CMAF SDK and tools                                             

[Skip to content](#start-of-content)   

## Navigation Menu

Toggle navigation

[](/)

[Sign in](/login?return_to=https%3A%2F%2Fgithub.com%2Faxiomatic-systems%2FBento4)

Appearance settings

  

-   Platform
    
    -   AI CODE CREATION
        
        -   [
            
            GitHub CopilotWrite better code with AI
            
            ](https://github.com/features/copilot)
        -   [
            
            GitHub SparkBuild and deploy intelligent apps
            
            ](https://github.com/features/spark)
        -   [
            
            GitHub ModelsManage and compare prompts
            
            ](https://github.com/features/models)
        -   [
            
            MCP RegistryNewIntegrate external tools
            
            ](https://github.com/mcp)
        
    -   DEVELOPER WORKFLOWS
        
        -   [
            
            ActionsAutomate any workflow
            
            ](https://github.com/features/actions)
        -   [
            
            CodespacesInstant dev environments
            
            ](https://github.com/features/codespaces)
        -   [
            
            IssuesPlan and track work
            
            ](https://github.com/features/issues)
        -   [
            
            Code ReviewManage code changes
            
            ](https://github.com/features/code-review)
        
    -   APPLICATION SECURITY
        
        -   [
            
            GitHub Advanced SecurityFind and fix vulnerabilities
            
            ](https://github.com/security/advanced-security)
        -   [
            
            Code securitySecure your code as you build
            
            ](https://github.com/security/advanced-security/code-security)
        -   [
            
            Secret protectionStop leaks before they start
            
            ](https://github.com/security/advanced-security/secret-protection)
        
    -   EXPLORE
        
        -   [Why GitHub](https://github.com/why-github)
        -   [Documentation](https://docs.github.com)
        -   [Blog](https://github.blog)
        -   [Changelog](https://github.blog/changelog)
        -   [Marketplace](https://github.com/marketplace)
        
    
    [View all features](https://github.com/features)
    
-   Solutions
    
    -   BY COMPANY SIZE
        
        -   [Enterprises](https://github.com/enterprise)
        -   [Small and medium teams](https://github.com/team)
        -   [Startups](https://github.com/enterprise/startups)
        -   [Nonprofits](https://github.com/solutions/industry/nonprofits)
        
    -   BY USE CASE
        
        -   [App Modernization](https://github.com/solutions/use-case/app-modernization)
        -   [DevSecOps](https://github.com/solutions/use-case/devsecops)
        -   [DevOps](https://github.com/solutions/use-case/devops)
        -   [CI/CD](https://github.com/solutions/use-case/ci-cd)
        -   [View all use cases](https://github.com/solutions/use-case)
        
    -   BY INDUSTRY
        
        -   [Healthcare](https://github.com/solutions/industry/healthcare)
        -   [Financial services](https://github.com/solutions/industry/financial-services)
        -   [Manufacturing](https://github.com/solutions/industry/manufacturing)
        -   [Government](https://github.com/solutions/industry/government)
        -   [View all industries](https://github.com/solutions/industry)
        
    
    [View all solutions](https://github.com/solutions)
    
-   Resources
    
    -   EXPLORE BY TOPIC
        
        -   [AI](https://github.com/resources/articles?topic=ai)
        -   [Software Development](https://github.com/resources/articles?topic=software-development)
        -   [DevOps](https://github.com/resources/articles?topic=devops)
        -   [Security](https://github.com/resources/articles?topic=security)
        -   [View all topics](https://github.com/resources/articles)
        
    -   EXPLORE BY TYPE
        
        -   [Customer stories](https://github.com/customer-stories)
        -   [Events & webinars](https://github.com/resources/events)
        -   [Ebooks & reports](https://github.com/resources/whitepapers)
        -   [Business insights](https://github.com/solutions/executive-insights)
        -   [GitHub Skills](https://skills.github.com)
        
    -   SUPPORT & SERVICES
        
        -   [Documentation](https://docs.github.com)
        -   [Customer support](https://support.github.com)
        -   [Community forum](https://github.com/orgs/community/discussions)
        -   [Trust center](https://github.com/trust-center)
        -   [Partners](https://github.com/partners)
        
    
-   Open Source
    
    -   COMMUNITY
        
        -   [
            
            GitHub SponsorsFund open source developers
            
            ](https://github.com/sponsors)
        
    -   PROGRAMS
        
        -   [Security Lab](https://securitylab.github.com)
        -   [Maintainer Community](https://maintainers.github.com)
        -   [Accelerator](https://github.com/accelerator)
        -   [Archive Program](https://archiveprogram.github.com)
        
    -   REPOSITORIES
        
        -   [Topics](https://github.com/topics)
        -   [Trending](https://github.com/trending)
        -   [Collections](https://github.com/collections)
        
    
-   Enterprise
    
    -   ENTERPRISE SOLUTIONS
        
        -   [
            
            Enterprise platformAI-powered developer platform
            
            ](https://github.com/enterprise)
        
    -   AVAILABLE ADD-ONS
        
        -   [
            
            GitHub Advanced SecurityEnterprise-grade security features
            
            ](https://github.com/security/advanced-security)
        -   [
            
            Copilot for BusinessEnterprise-grade AI features
            
            ](https://github.com/features/copilot/copilot-business)
        -   [
            
            Premium SupportEnterprise-grade 24/7 support
            
            ](https://github.com/premium-support)
        
    
-   [Pricing](https://github.com/pricing)

Search or jump to...

# Search code, repositories, users, issues, pull requests...

Search

Clear

[Search syntax tips](https://docs.github.com/search-github/github-code-search/understanding-github-code-search-syntax)

# Provide feedback

We read every piece of feedback, and take your input very seriously.

 Include my email address so I can be contacted

Cancel Submit feedback

# Saved searches

## Use saved searches to filter your results more quickly

Name  

Query 

To see all available qualifiers, see our [documentation](https://docs.github.com/search-github/github-code-search/understanding-github-code-search-syntax).

Cancel Create saved search

[Sign in](/login?return_to=https%3A%2F%2Fgithub.com%2Faxiomatic-systems%2FBento4)

[Sign up](/signup?ref_cta=Sign+up&ref_loc=header+logged+out&ref_page=%2F%3Cuser-name%3E%2F%3Crepo-name%3E&source=header-repo&source_repo=axiomatic-systems%2FBento4)

Appearance settings

Resetting focus

You signed in with another tab or window. Reload to refresh your session. You signed out in another tab or window. Reload to refresh your session. You switched accounts on another tab or window. Reload to refresh your session. Dismiss alert

[axiomatic-systems](/axiomatic-systems) / **[Bento4](/axiomatic-systems/Bento4)** Public

-   [Notifications](/login?return_to=%2Faxiomatic-systems%2FBento4) You must be signed in to change notification settings
-   [Fork 519](/login?return_to=%2Faxiomatic-systems%2FBento4)
-   [Star 2.4k](/login?return_to=%2Faxiomatic-systems%2FBento4)
    

Full-featured MP4 format, MPEG DASH, HLS, CMAF SDK and tools

[www.bento4.com](http://www.bento4.com "http://www.bento4.com")

[2.4k stars](/axiomatic-systems/Bento4/stargazers) [519 forks](/axiomatic-systems/Bento4/forks) [Branches](/axiomatic-systems/Bento4/branches) [Tags](/axiomatic-systems/Bento4/tags) [Activity](/axiomatic-systems/Bento4/activity)

[Star](/login?return_to=%2Faxiomatic-systems%2FBento4)

[Notifications](/login?return_to=%2Faxiomatic-systems%2FBento4) You must be signed in to change notification settings

-   [Code](/axiomatic-systems/Bento4)
-   [Issues 546](/axiomatic-systems/Bento4/issues)
-   [Pull requests 27](/axiomatic-systems/Bento4/pulls)
-   [Actions](/axiomatic-systems/Bento4/actions)
-   [Projects 0](/axiomatic-systems/Bento4/projects)
-   [Wiki](/axiomatic-systems/Bento4/wiki)
-   [Security 0](/axiomatic-systems/Bento4/security)
-   [Insights](/axiomatic-systems/Bento4/pulse)

Additional navigation options

-   [Code](/axiomatic-systems/Bento4)
-   [Issues](/axiomatic-systems/Bento4/issues)
-   [Pull requests](/axiomatic-systems/Bento4/pulls)
-   [Actions](/axiomatic-systems/Bento4/actions)
-   [Projects](/axiomatic-systems/Bento4/projects)
-   [Wiki](/axiomatic-systems/Bento4/wiki)
-   [Security](/axiomatic-systems/Bento4/security)
-   [Insights](/axiomatic-systems/Bento4/pulse)

# axiomatic-systems/Bento4

  

 master

[Branches](/axiomatic-systems/Bento4/branches)[Tags](/axiomatic-systems/Bento4/tags)

[](/axiomatic-systems/Bento4/branches)[](/axiomatic-systems/Bento4/tags)

Go to file

Code

Open more actions menu

## Folders and files

Name

Name

Last commit message

Last commit date

## Latest commit

## History

[1,341 Commits](/axiomatic-systems/Bento4/commits/master/)

[](/axiomatic-systems/Bento4/commits/master/)1,341 Commits

[.github](/axiomatic-systems/Bento4/tree/master/.github ".github")

[.github](/axiomatic-systems/Bento4/tree/master/.github ".github")

[Build](/axiomatic-systems/Bento4/tree/master/Build "Build")

[Build](/axiomatic-systems/Bento4/tree/master/Build "Build")

[Documents](/axiomatic-systems/Bento4/tree/master/Documents "Documents")

[Documents](/axiomatic-systems/Bento4/tree/master/Documents "Documents")

[Scripts](/axiomatic-systems/Bento4/tree/master/Scripts "Scripts")

[Scripts](/axiomatic-systems/Bento4/tree/master/Scripts "Scripts")

[Source](/axiomatic-systems/Bento4/tree/master/Source "Source")

[Source](/axiomatic-systems/Bento4/tree/master/Source "Source")

[Test](/axiomatic-systems/Bento4/tree/master/Test "Test")

[Test](/axiomatic-systems/Bento4/tree/master/Test "Test")

[tasks](/axiomatic-systems/Bento4/tree/master/tasks "tasks")

[tasks](/axiomatic-systems/Bento4/tree/master/tasks "tasks")

[.gitignore](/axiomatic-systems/Bento4/blob/master/.gitignore ".gitignore")

[.gitignore](/axiomatic-systems/Bento4/blob/master/.gitignore ".gitignore")

[.lgtm.yml](/axiomatic-systems/Bento4/blob/master/.lgtm.yml ".lgtm.yml")

[.lgtm.yml](/axiomatic-systems/Bento4/blob/master/.lgtm.yml ".lgtm.yml")

[.travis.yml](/axiomatic-systems/Bento4/blob/master/.travis.yml ".travis.yml")

[.travis.yml](/axiomatic-systems/Bento4/blob/master/.travis.yml ".travis.yml")

[CMakeLists.txt](/axiomatic-systems/Bento4/blob/master/CMakeLists.txt "CMakeLists.txt")

[CMakeLists.txt](/axiomatic-systems/Bento4/blob/master/CMakeLists.txt "CMakeLists.txt")

[README.md](/axiomatic-systems/Bento4/blob/master/README.md "README.md")

[README.md](/axiomatic-systems/Bento4/blob/master/README.md "README.md")

[SConstruct](/axiomatic-systems/Bento4/blob/master/SConstruct "SConstruct")

[SConstruct](/axiomatic-systems/Bento4/blob/master/SConstruct "SConstruct")

View all files

## Repository files navigation

-   [README](#)

# Bento4

[](#bento4)

[![CI](https://github.com/axiomatic-systems/Bento4/workflows/CI/badge.svg?branch=master)](https://github.com/axiomatic-systems/Bento4/workflows/CI/badge.svg?branch=master)

Bento4 is a C++ class library and tools designed to read and write ISO-MP4 files. This format is defined in international specifications ISO/IEC 14496-12, 14496-14 and 14496-15. The format is a derivative of the Apple Quicktime file format, so Bento4 can be used to read and write most Quicktime files as well.

Visit [www.bento4.com](http://www.bento4.com) for details

## Features

[](#features)

A number of formats and features based on the ISO-MP4 format and related technologies are also supported, including:

-   MPEG DASH with fragmented MP4 files, as defined in ISO/IEC 23009-1
-   CMAF (Common Media Application Format) as defined in ISO/IEC 23000-19
-   MPEG Common Encryption (CENC) as specified in ISO/IEC 23001-7
-   PIFF (Protected Interoperable File Format): encrypted, fragmented MP4 format specified by Microsoft and used for encrypted HTTP Smooth Streaming.
-   Reading and writing 3GPP and iTunes-compatible metadata.
-   ISMA Encrytion and Decryption as defined in the ISMA E&A specification
-   OMA 2.0 and 2.1 DCF/PDCF Encryption and Decryption as defined in the OMA specifications.
-   ISO-MP4 files profiled as part of the 3GPP family of standards.
-   The UltraViolet (DECE) CFF (Common File Format).
-   Parsing and multiplexing of H.264 (AVC) video and AAC audio elementary streams
-   Support for multiple DRM systems that are compatible with MP4-formatted content (usually leveraging CENC Common Encryption), such as Marlin, PlayReady and Widevine.
-   Support for a wide range of codecs, including H.264 (AVC), H.265 (HEVC), AAC, AC-3, EC-3 (Dolby Digital Plus), AC-4, Dolby ATMOS, DTS, ALAC, and many more.

## Design

[](#design)

The SDK is designed to be cross-platform. The code is very portable; it can be compiled with any sufficiently modern C++ compiler. The implementation does not rely on any external library. All the code necessary to compile the SDK and tools is included in the standard distribution. The standard distribution contains makefiles for unix-like operating systems, including Linux and Android, project files for Microsoft Visual Studio, and an XCode project for MacOS X and iOS. There is also support for building the library with the SCons build system.

## License

[](#license)

The library is Open Source, with a dual-license model. You can find out more about the license on the About Page. The Developers Page contains specific information on where to obtain the source code and documentation. The Downloads Page contains the links to pre-built SDKs and tools that you can use to get started quickly.

## Included Applications

[](#included-applications)

The Bento4 SDK includes several command-line applications/tools that are built using the SDK API. These include:

app name

description

mp4info

displays high level info about an MP4 file, including all tracks and codec details

mp4dump

displays the entire atom/box structure of an MP4 file

mp4edit

add/insert/remove/replace atom/box items of an MP4 file

mp4extract

extracts an atom/box from an MP4 file

mp4encrypt

encrypts an MP4 file (multiple encryption schemes are supported)

mp4decrypt

decrypts an MP4 file (multiple encryption schemes are supported)

mp4dcfpackager

encrypts a media file into an OMA DCF file

mp4compact

converts ‘stsz’ tables into ‘stz2′ tables to create more compact MP4 files

mp4fragment

creates a fragmented MP4 file from a non-fragmented one or re-fragments an already-fragmented file

mp4split

splits a fragmented MP4 file into discrete files

mp4tag

show/edit MP4 metadata (iTunes-style and others)

mp4mux

multiplexes one or more elementary streams (H264, AAC) into an MP4 file

mp42aac

extract a raw AAC elementary stream from an MP4 file

mp42avc

extract a raw AVC/H.264 elementary stream from an MP4 file

mp42hls

converts an MP4 file to an HLS (HTTP Live Streaming) presentation, including the generation of the segments and .m3u8 playlist.

mp42ts

converts an MP4 file to an MPEG2-TS file.

mp4-dash

creates an MPEG DASH output from one or more MP4 files, including encryption.

mp4-dash-clone

creates a local clone of a remote or local MPEG DASH presentation, optionally encrypting the segments as they are cloned.

## Building

[](#building)

The code can be built either by using the pre-configured IDE project files (Mac OSX, iOS and Windows), or compiled/cross-compiled using the SCons build system or CMake, or compiled using Make. Target platform specific build files and configurations are located under subdirectories Buid/Targets/xxxx where xxxx takes the form `<architecture>-<vendor>-<os>`. For example, the Linux x86 target specific files are located under `Build/Targets/x86-unknown-linux`. The XCode project files for Mac OSX are located under `Build/Targets/universal-apple-macosx`.

### Mac OSX and iOS using XCode

[](#mac-osx-and-ios-using-xcode)

Open the XCode project file Build/Targets/universal-apple-macosx/Bento4.xcodeproj and build

### Windows using Visual Studio

[](#windows-using-visual-studio)

Open the Visual Studio solution file Build/Targets/x86-microsoft-win32-vs2010/Bento4.sln and build

### On Linux and other platforms, Using CMake

[](#on-linux-and-other-platforms-using-cmake)

CMake can generate Makefiles, Xcode project files, or Visual Studios project files.

#### CMake/Make

[](#cmakemake)

```
mkdir cmakebuild
cd cmakebuild
cmake -DCMAKE_BUILD_TYPE=Release ..
make
```

#### CMake/Xcode

[](#cmakexcode)

```
mkdir cmakebuild
cd cmakebuild
cmake -G Xcode ..
cmake --build . --config Release
```

#### CMake/Visual Studio

[](#cmakevisual-studio)

```
mkdir cmakebuild
cd cmakebuild
cmake -DCMAKE_BUILD_TYPE=Release ..
cmake --build . --config Release
```

#### CMake for Android NDK

[](#cmake-for-android-ndk)

```
mkdir cmakebuild
cd cmakebuild
cmake -DCMAKE_TOOLCHAIN_FILE=$NDK/build/cmake/android.toolchain.cmake -DANDROID_ABI=$ABI -DANDROID_NATIVE_API_LEVEL=$MINSDKVERSION ..
make

See https://developer.android.com/ndk/guides/cmake for details on the choice of ABI and other parameters.

Where $NDK is set to the directory path where you have installed the NDK, $ABI is the Android ABI (ex: arm64-v8a) and $MINSDKVERSION is the minimum SDK version (ex: 23)
```

### On Linux and other platforms, using SCons (deprecated)

[](#on-linux-and-other-platforms-using-scons-deprecated)

Make sure you the the SCons build tool installed on your host machine ([http://www.scons.org](http://www.scons.org)). To build the Debug configuration, simply enter the command:

`scons -u`

in a terminal from any directory (either from the top level directory where you downloaded the Bento4 distribution, or from the Build/Targets/xxx subdirectory for your specific target).

To build the Release configuration, use the command:

`scons -u build_config=Release`

To cross-compile for a target other than your host architecture, specify target=xxxx as an argument to the scons build command.

Example:

`scons -u build_config=Release target=x86_64-unknown-linux`

### Using Make

[](#using-make)

From a command shell, go to your build target directory.

For Debug builds: `make`

For Release builds: `make AP4_BUILD_CONFIG=Release`

## Installing Bento4 (vcpkg)

[](#installing-bento4-vcpkg)

Alternatively, you can build and install Bento4 using [vcpkg](https://github.com/Microsoft/vcpkg/) dependency manager:

```
git clone https://github.com/Microsoft/vcpkg.git
cd vcpkg
./bootstrap-vcpkg.sh
./vcpkg integrate install
./vcpkg install bento4
```

The Bento4 port in vcpkg is kept up to date by Microsoft team members and community contributors. If the version is out of date, please [create an issue or pull request](https://github.com/Microsoft/vcpkg) on the vcpkg repository.

## Release Notes

[](#release-notes)

### 1.6.0-638

[](#160-638)

-   support multi-bitrate audio
-   new docs using MkDocs
-   add av1 files and remove deprecated option from vs2019 build
-   add AV1 support
-   better handling of USAC signaling
-   add UTF-8 support on Windows
-   fix LGTM warnings
-   account for last sample when at EOS
-   new inspector API
-   bug fixes

### 1.6.0-636

[](#160-636)

Dolby Vision encryption now properly encrypts in a NAL-unit-aware mode

### Previous releases

[](#previous-releases)

(no seaparate notes, please refer to commit logs)

## About

Full-featured MP4 format, MPEG DASH, HLS, CMAF SDK and tools

[www.bento4.com](http://www.bento4.com "http://www.bento4.com")

### Topics

[audio](/topics/audio "Topic: audio") [streaming](/topics/streaming "Topic: streaming") [video](/topics/video "Topic: video") [mp4](/topics/mp4 "Topic: mp4") [hls](/topics/hls "Topic: hls") [aac](/topics/aac "Topic: aac") [dash](/topics/dash "Topic: dash") [codec](/topics/codec "Topic: codec") [hevc](/topics/hevc "Topic: hevc") [av1](/topics/av1 "Topic: av1") [avc](/topics/avc "Topic: avc") [ac-3](/topics/ac-3 "Topic: ac-3") [cmaf](/topics/cmaf "Topic: cmaf") [ac-4](/topics/ac-4 "Topic: ac-4")

### Resources

[Readme](#readme-ov-file)

### Uh oh!

There was an error while loading. Please reload this page.

[Activity](/axiomatic-systems/Bento4/activity)

[Custom properties](/axiomatic-systems/Bento4/custom-properties)

### Stars

[**2.4k** stars](/axiomatic-systems/Bento4/stargazers)

### Watchers

[**77** watching](/axiomatic-systems/Bento4/watchers)

### Forks

[**519** forks](/axiomatic-systems/Bento4/forks)

[Report repository](/contact/report-content?content_url=https%3A%2F%2Fgithub.com%2Faxiomatic-systems%2FBento4&report=axiomatic-systems+%28user%29)

## [Releases](/axiomatic-systems/Bento4/releases)

[57 tags](/axiomatic-systems/Bento4/tags)

## [Packages 0](/orgs/axiomatic-systems/packages?repo_name=Bento4)

No packages published  

### Uh oh!

There was an error while loading. Please reload this page.

## [Contributors 53](/axiomatic-systems/Bento4/graphs/contributors)

### Uh oh!

There was an error while loading. Please reload this page.

[\+ 39 contributors](/axiomatic-systems/Bento4/graphs/contributors)

## Languages

-   [C++ 74.5%](/axiomatic-systems/Bento4/search?l=c%2B%2B)
-   [JavaScript 15.0%](/axiomatic-systems/Bento4/search?l=javascript)
-   [Python 6.4%](/axiomatic-systems/Bento4/search?l=python)
-   [Java 2.0%](/axiomatic-systems/Bento4/search?l=java)
-   [Makefile 1.0%](/axiomatic-systems/Bento4/search?l=makefile)
-   [C 0.6%](/axiomatic-systems/Bento4/search?l=c)
-   Other 0.5%

## Footer

[](https://github.com)© 2026 GitHub, Inc.

### Footer navigation

-   [Terms](https://docs.github.com/site-policy/github-terms/github-terms-of-service)
-   [Privacy](https://docs.github.com/site-policy/privacy-policies/github-privacy-statement)
-   [Security](https://github.com/security)
-   [Status](https://www.githubstatus.com/)
-   [Community](https://github.community/)
-   [Docs](https://docs.github.com/)
-   [Contact](https://support.github.com?tags=dotcom-footer)
-   Manage cookies
-   Do not share my personal information

You can’t perform that action at this time.
```
```

```
Tool: webfetch

**Input:**
```json
{
  "url": "https://github.com/axiomatic-systems/Bento4/blob/master/LICENSE.txt",
  "format": "markdown",
  "timeout": 60
}
```
**Error:**
```
Error: Request failed with status code: 404
```
```

```
Tool: webfetch

**Input:**
```json
{
  "url": "https://gpac.wp.imt.fr/",
  "format": "markdown",
  "timeout": 60
}
```
**Output:**
```
  gpac.io - Ultramedia Open Source Infrastructure                                       

[![](/wp-content/themes/custom2013/images/gpac-logo.png)

# gpac.io

## Ultramedia Open Source Infrastructure

*For Video Streaming and Next-Gen Multimedia Transcoding, Packaging and Delivery.*



](https://gpac.io/)

Menu [Skip to content](#content)

-   [About](https://gpac.io/about/)
-   [Features](https://gpac.io/features/)
-   [Download](https://gpac.io/downloads/gpac-nightly-builds/)
-   [FAQ](https://gpac.io/faq/)
-   [Community](https://gpac.io/community/)
-   [Projects & Funding](https://gpac.io/projects-funding/)

Search for:  

# [GPAC 26.02](https://gpac.io/2026/02/05/gpac-26-02/)

[5 February 2026](https://gpac.io/2026/02/05/gpac-26-02/ "Permalink to GPAC 26.02")[Blog](https://gpac.io/category/blog/), [Community](https://gpac.io/category/community/), [News](https://gpac.io/category/news/), [Release](https://gpac.io/category/release/)[Jean Le Feuvre](https://gpac.io/author/lefeuvretelecom-paristech-fr/ "View all posts by Jean Le Feuvre")

We are happy to announce the release of GPAC 26.02, moving to year.month naming scheme from now on.

This release brings many new features in packaging, Multicast ABR with HTTP repair, HTTP/3 support and other goodies, check the complete changelog below for more details !

This release also brings a new web UI for remote monitoring of long-running GPAC sessions, allowing real-time visualization of the session.

As usual, installers are available on [gpac.io](https://gpac.io/downloads/gpac-nightly-builds/) for most common platforms.

Enjoy, give us feedback and spread the news!

[Read more: GPAC 26.02](https://gpac.io/2026/02/05/gpac-26-02/)

Detailed changelog:

## gpac

-   Added mode for testing deferred graph linking apps
-   `main()` can return filter session error code using -rv

## MP4Box

-   Better support for HEIF/AVIF import
-   New ‘times’ option to rewrite timestamps

## Core tools

-   Network Capture and Replay using pcap or pcapng, including looping, loss and reordering simulation
-   HTTP/3 support for client and server
-   Added libcurl as backend for GPAC downloader
-   QuickJS 2025, FFmpeg 8
-   Improved GFIO (including file deletion)

## Media Formats

-   ISOBMFF external tracks support
-   Event Message Tracks support
-   Improved support SCTE-35, id3, CC, timecodes and other markers
-   Improved HDR signaling support
-   IAMF support
-   Motion JPEG2000
-   AC-4 support
-   AVS3 support

## MPEG-DASH & HLS

-   SSR support for L3D low latency, base64 encoding of init segments
-   HLS groups, IV injection
-   DASH/HLS: new `segcts` option to derive startNumber from first packet cts
-   mux time prft injection

## Remote monitoring

-   A new WebSocket based remote monitoring UI is available for GPAC
-   WebSocket server for JS scripts

## Filters

-   DVB-I MABR FLUTE mux and demux
-   MABR (ROUTE/FLUTE) HTTP repair support with full or partial modes
-   MABR (ROUTE/FLUTE) on unicast
-   mediaserver.js HTTP gateway filter supporting MABR sources
-   avmix playlists now accept ipid:// urls to locate input pids, allowing to specify playlists independently from source URLs
-   ClosedCaptions encoder
-   TTML merger
-   flist: Playlist piping, DASH perdiod auto-switch signaling
-   pin: flush signaling upon broken pipe
-   M2TS: USAC support, non real-time NTP injection for TEMI, real-time regulation option for tssplit and tsgendts
-   dvb4linux is back (Terrestrial and Satelite including dibseqc)
-   reframer: time-aligned mode, time discontinuities handling
-   nhml: ability to process fragmented streams
-   bsrw: timecodes injection and rewriting
-   seiloader filter for SEI and AV1 OBUs
-   FFmpeg raw protocol support (use gpac for demux and mux)

## Emscripten

-   Improved WASM support
-   Fixes in UI

## Other

-   Improved Wiki: glossary, developer section, …
-   Integration with GStreamer ([gpac-gst-plugin](https://github.com/gpac/gst-gpac-plugin))
-   Introduce unit tests in complement to the testsuite and various buildbot continuous checks
-   Many bug fixes and security patches

# [Announcing MP4Box.js 1.0.0 with TypeScript support](https://gpac.io/2025/06/19/announcing-mp4box-js-1-0-0-with-typescript-support/)

[19 June 2025](https://gpac.io/2025/06/19/announcing-mp4box-js-1-0-0-with-typescript-support/ "Permalink to Announcing MP4Box.js 1.0.0 with TypeScript support")[Blog](https://gpac.io/category/blog/)[romain bouqueau](https://gpac.io/author/bouqueau/ "View all posts by romain bouqueau")

[MP4Box.js](https://github.com/gpac/mp4box.js) – GPAC’s first venture into JavaScript inspired by the MP4Box tool – makes it easy to parse, segment, and manipulate MP4 files in browsers or Node.js.

Over time it’s become an unavoidable tool for Javascript developers willing to analyze, manipulate or generate media content in the browser or any Javascript runtime.

Since version 0.5.2 (Mar 2022), the library has undergone significant evolution: the codebase was modernized, new capabilities were added, and support for additional MP4 box types and streaming formats was extended. Below [Deniz Uğur](https://github.com/denizugur) and I highlight the most important changes (released officially in v0.5.3/v0.5.4 and v0.6.x up through v1.0.0), focusing on new features, interface enhancements, and architectural improvements.

## **Refactored Codebase and TypeScript Support**

A key milestone came in version 0.6.0, which is a **complete refactor to modern JavaScript**. The library was converted into an ECMAScript Module and rewritten in TypeScript.

In practice this means MP4Box.js now ships as an ES module (with CJS compatibility) and includes TypeScript type definitions out-of-the-box. Developers can import MP4Box.js with modern import syntax and enjoy full typing support. This modernization also brought an updated build toolchain (e.g. bundler and linting) and makes integration into contemporary web apps and Node environments much smoother.

The migration is largely transparent to existing code.  

## **Expanded Compatibility for Box Types and MPEG Conformance Streams**

Alongside the architectural rewrite, several updates improved compatibility with new MP4 box types and streaming scenarios:

-   **MPEG ISOBMFF Box Support** – So much to write here, that led us to be up-to-date with MPEG’s ISOBMFF specification. For example, a fix was added to recognize version 1 of the cslg (composition to decode timeline) box, which is used by certain tools like GStreamer. Previously MP4Box.js ignored this newer box version, but now it can parse it correctly. MP4Box.js 1.0.0 enhances compatibility with files produced by modern encoders.  
    
-   **Stream Type Extensions (v0.6.4)** – The parsing interface was extended to accept *additional stream types*. In other words, MP4Box.js now recognizes more container streams when you call its parse methods. This lets developers feed in different kinds of input (e.g. alternative fetch or file streams) without having to patch the library.  
    
-   **ArrayBuffer** **fileStart** **Parameter (v0.6.4)** – MP4Box.js’ extended ArrayBuffer type (MP4BoxBuffer.fromArrayBuffer) was updated to require fileStart property explicitlyThis allows you to append ArrayBuffer segments at a specific offset in the virtual file. In practice, this makes progressive loading more flexible (for example, appending fragments of a large MP4 file in order), and it aligns MP4Box.js’s streaming API more closely with the original MP4Box (CLI) behavior.  
    

## **Enhanced File Saving and** **mdat** **Handling**

Versions leading up to 1.0.0 introduced more powerful file output capabilities, particularly around the media data (mdat):

-   **Rewriting Entire MP4 (v1.0.0)** – A big portion of the effort went into fixing issues around [MP4Box.js](https://github.com/gpac/mp4box.js) that was preventing valid *rewriting of the file including the* *mdat* *box*. In earlier versions, saving an MP4 often omitted the large media payload (mdat), resulting in an output with only headers. Now MP4Box.js can generate a complete MP4 file (with both metadata and media data) in one step. This is useful for workflows that manipulate or concatenate full MP4 files on the client side.  
    
-   **Breaking Change:** **discardMdatData** **Default (v1.0.0)** – To manage memory use, version 1.0.0 changed the default behavior so that discardMdatData is now true by default. This means by default MP4Box.js will discard (not store) the raw media data it parses unless you explicitly disable this flag. If your application needs the media bytes for rewriting, you can create the file with createFile(true)before parsing. Be aware of this change if upgrading, as it was not the previous default behavior.

**More Comprehensive Testing**

MPEG Group has built a File Format Conformance Framework around 2 years ago that made it easier to access conformance files. Our contributor [Deniz Uğur](https://github.com/denizugur) took advantage of this and tested [MP4Box.js](https://github.com/gpac/mp4box.js) against the conformance files from there.

-   **Structural Tests** – Our testsuite ensures the parsed box layout is identical to what GPAC can output and what was reviewed and accepted by the MPEG File Format group.
-   **Roundtrip Tests** – We also make sure we can read a file, write it, and read it again without any discrepancies.

## **Other Interface Improvements and Fixes**

Beyond the headline changes above, MP4Box.js received numerous smaller but impactful tweaks:

-   **Bug Fixes and Registry Improvements (v0.6.4)** – Various internal fixes were made to the box-type registry and parsing logic. For example, box definitions were cleaned up to separate different internal cases, and validation was tightened. While these are mostly behind-the-scenes, they improve stability when dealing with edge-case MP4 files.  
    
-   **Streamlining and Cleanup** – In multiple releases (v0.6.2, v0.6.3, etc.) general fixes were applied across the codebase (e.g. dependency fixes, housekeeping, and compliance updates). These don’t add new user-facing features, but they ensure the library is more maintainable and compliant with future standards (for instance, fixing build scripts and updating dependencies).  
    

Overall, since v0.5.2 the MP4Box.js library has matured significantly. It now leverages modern JavaScript practices (ESM + TypeScript), has better support for varied MP4 formats and streaming scenarios, and can fully rewrite MP4 files with their media data. These enhancements make MP4Box.js a more powerful and flexible tool for web developers working with GPAC.Last but not least: many thanks to the community and [our contributors](https://github.com/gpac/mp4box.js/graphs/contributors). Long live [MP4Box.js](https://github.com/gpac/mp4box.js)!

# [100 Million Downloads: A Milestone for the GPAC Community](https://gpac.io/2025/06/10/100-million-downloads-a-milestone-for-the-gpac-community/)

[10 June 2025](https://gpac.io/2025/06/10/100-million-downloads-a-milestone-for-the-gpac-community/ "Permalink to 100 Million Downloads: A Milestone for the GPAC Community")[Blog](https://gpac.io/category/blog/)[romain bouqueau](https://gpac.io/author/bouqueau/ "View all posts by romain bouqueau")

Looking back on 25 years of code, collaboration, and quiet, but massive impact.

![](https://gpac.io/wp-content/files//2025/06/gpac_100M_DLs-1-1024x749.jpg)

*Illustration by Lluc Pallejà of [squeakycarrot.c](https://www.squeakycarrot.com)*[om](https://www.squeakycarrot.com)

As GPAC approaches 100 million downloads across its ecosystem of tools, we’d like to take a moment to reflect — and thank the people who made it possible: our users, contributors, testers, and long-time supporters.

From the early academic days at Télécom Paris to the growing set of tools used in research, prototyping, packaging, streaming, and browser-based applications, GPAC has always had one core mission: to give developers high-quality, efficient, and modular building blocks for multimedia workflows.

What’s in the 100 Million?

The number includes cumulative downloads across:

-   The core GPAC framework
-   MP4Box, our popular MP4 multiplexer/demultiplexer
-   MP4Box.js, used in browser environments
-   Other associated GPAC tools and libraries available via GitHub, npm, and other repositories

We know download numbers don’t tell the whole story. Open-source software is widely reused, embedded, and adapted — sometimes anonymously. But when a project like GPAC crosses a milestone like this, it’s a signal of sustained interest, real-world use, and global relevance.

🌍 Where GPAC Shows Up

While we don’t always know who our users are, we’ve seen GPAC show up in:

-   Academic research papers, standardization contributions and student projects
-   Streaming architecture experiments
-   Streaming media workflows as used by Netflix with the help of [Motion Spell](https://www.motionspell.com)
-   Browser-based applications using MP4Box.js
-   Open-source media toolkits and larger software stacks

We welcome this diversity. It keeps the project grounded, evolving, and truly open.

The upcoming GPAC release will include new features and refinements based on feedback from our contributors and community — especially in areas like:

-   CMAF packaging
-   Pro workflows in DRM and Advertising
-   Enhanced GPAC Filters documentation
-   Browser-based video handling with MP4Box.js

We’ll also continue efforts to make our tools easier to adopt, whether you’re building for experimentation or integrating GPAC into production environments.

Whether you downloaded GPAC once, use it daily, or contributed code, tests, bug reports, or documentation — thank you.

If you’re using GPAC in your work, we’d love to hear about it. You can drop us a note, contribute to the GitHub discussion, or just share a link. Your stories help shape the future of the project.

Here’s to the next 100 million — and to keeping GPAC useful, efficient, and open.

*The GPAC team*

# [The Security Landscape of the GPAC Open-Source Project: A Balanced Perspective](https://gpac.io/2024/10/28/the-security-landscape-of-the-gpac-open-source-project-a-balanced-perspective/)

[28 October 2024](https://gpac.io/2024/10/28/the-security-landscape-of-the-gpac-open-source-project-a-balanced-perspective/ "Permalink to The Security Landscape of the GPAC Open-Source Project: A Balanced Perspective")[Blog](https://gpac.io/category/blog/), [Community](https://gpac.io/category/community/)[romain bouqueau](https://gpac.io/author/bouqueau/ "View all posts by romain bouqueau")

GPAC is an open-source multimedia framework used by many developers and organizations to manipulate, package, and stream multimedia content. Given the popularity of GPAC in media manipulation tasks, it has naturally caught the attention of security researchers and organizations such as the Cybersecurity and Infrastructure Security Agency ([CISA](https://www.cisa.gov/)). Over time, many bugs were discovered, a few vulnerabilities have been flagged, prompting some concern in the development community. However, these reports, especially the recent CISA GPAC advisories, are either outdated or have been adequately addressed by the [GPAC team](https://github.com/search?q=repo%3Agpac%2Fgpac%20security&type=issues), rendering the issues largely non-serious today.

**Understanding GPAC Vulnerabilities**

Like any large software project written in C, dealing with [bitstream](https://en.wikipedia.org/wiki/Bitstream_format) parsing, and started at a time where security was not a concern, GPAC’s codebase has been exposed to [many types of crashes and vulnerabilities](https://github.com/search?q=repo%3Agpac%2Fgpac%20security&type=issues) when fed with wrong input data. The most recent CISA GPAC advisories on GPAC vulnerabilities, while helpful for raising awareness, highlight problems that are no longer pressing.

For example, certain vulnerabilities that surfaced in 2024, which included concerns around memory safety, buffer overflows, and input validation, have already been patched in newer releases.

While CISA’s advisories motivated the GPAC team to address these issues more quickly, it is crucial to understand that CISA GPAC reports have a delayed effect when disseminated to the public, meaning the issues are often resolved by the time the advisories are released.

Most of the vulnerabilities cited by CISA are also categorized as **low to medium severity**, meaning they do not pose immediate or significant risks for most users. Moreover, they primarily affect environments where the code is not sandboxed properly or where media files are processed directly from untrusted sources—scenarios that can often be mitigated with basic security best practices. Even so, beside causing a potential crash, the path to exploitation remains unclear, making most of these reports more of simple bugs than actual security vulnerabilities.

In addition GPAC has a [security policy](https://github.com/gpac/gpac/blob/master/SECURITY.md) in place. We invite security researchers to follow the instructions for a swift analysis and resolution of their concerns.

**Why The Recent CISA Issues Are Not Serious**

A few key reasons illustrate why the CISA-reported GPAC issues are not a current concern:

1.  **Timely Patching by the GPAC Team**: GPAC’s developer community is highly active, with frequent updates and patches released. The vulnerabilities that CISA flagged have, in many cases, been swiftly addressed by GPAC developers. For example, buffer overflow issues raised in early 2023 were quickly resolved in subsequent software patches. The project’s maintainers work closely with the security community and enroll to the public fuzzing and analysis infrastructures to ensure that these issues are catched and mitigated before they are reported.
2.  **Limited Exploitability**: The majority of the flagged vulnerabilities require specific, often unrealistic conditions to be exploited. Many of the issues only become relevant when processing malicious media files in very particular environments. For developers who follow standard practices—such as sandboxing, using trusted input sources, and staying updated with the latest patches—the risk remains minimal.
3.  **Open-Source Advantages**: Being an open-source project, GPAC benefits from having many eyes on its codebase. Vulnerabilities are discovered faster, and the community of developers often provides fixes before any serious exploitation can occur. Additionally, transparency is a cornerstone of GPAC, allowing users to inspect the changes and patches themselves, contributing to a sense of shared responsibility and trust.

**Practical Steps for Developers Using GPAC**

While GPAC’s security situation is stable, it’s always wise to follow a few best practices when using open-source software:

-   **Regularly Updated**: Ensure you’re using the latest version of GPAC. The project is regularly maintained, and updates contain security fixes.
-   **Sandbox Media Processing**: When processing media files, especially from unknown or untrusted sources, use sandboxing to limit the impact of any potential vulnerabilities.
-   **Monitor Vulnerability Feeds**: Keep an eye on any new GPAC vulnerabilities of your deplyed version by keeping an eye on vulnerability databases like the [National Vulnerability Database (NVD)](https://nvd.nist.gov/) to stay informed about any emerging issues that might affect you.
-   **Harden Your Systems**: Apply general hardening practices to your systems and environments that use GPAC, such as enabling ASLR (Address Space Layout Randomization), DEP (Data Execution Prevention), and other standard security mechanisms.

**Conclusion**

The security issues surrounding GPAC, flagged by CISA and other agencies, have been managed with care by the open-source community. Most of the vulnerabilities were low to medium severity, and the project’s maintainers have been proactive in detecting and addressing them using a state-of-the-art [security policy](https://github.com/gpac/gpac/blob/master/SECURITY.md).

For developers and organizations using GPAC, following basic security practices—such as updating regularly and using sandboxing—ensures a safe and secure experience. The concerns raised by CISA’s GPAC advisories, while relevant at the time, have become outdated in the current context.

GPAC remains a robust and secure tool for multimedia processing and streaming, with a community that prioritizes both functionality and security.

# [MABR: “Multicast Adaptive BitRate”](https://gpac.io/2024/09/16/mabr-multicast-adaptive-bitrate/)

[16 September 2024](https://gpac.io/2024/09/16/mabr-multicast-adaptive-bitrate/ "Permalink to MABR: “Multicast Adaptive BitRate”")[Blog](https://gpac.io/category/blog/), [News](https://gpac.io/category/news/)[romain bouqueau](https://gpac.io/author/bouqueau/ "View all posts by romain bouqueau")

### **Introduction: Hybrid by Default**

GPAC has a [long history of seamlessly blending transport channels](https://gpac.io/tag/shvc/), such as broadband and broadcast, to reassemble signals without interruption. This innovative approach is more relevant than ever as it resurfaces in the form of a hybrid unicast OTT combined with Adaptive Bitrate (ABR) streaming, aimed at reducing transport costs while maintaining quality.

GPAC’s commitment to mixing traditional broadcast media with modern interactive applications—what we proudly call “UltraMedia”—is at the core of our vision for the future of media. 

GPAC has been architected to embody this strong vision because we believe it is the future of media, supporting the convergence of media experiences across different platforms and formats. It’s exciting to see multicast and hybrid solutions gaining renewed attention as the industry evolves.

### **The Most Versatile Multicast-ABR Solution**

GPAC stands as the only open-source solution that supports both [ROUTE](https://www.rfc-editor.org/rfc/rfc9223) and [FLUTE](https://datatracker.ietf.org/doc/html/rfc6726) protocols, which is why it is highly regarded within industry consortiums. This makes GPAC the ideal platform for evaluating and experimenting with various protocols, offering reproducible results that can inform decisions on the best approaches to adopt.

Our expertise in ROUTE, showcased by [our ATSC 3.0 implementation](https://wiki.gpac.io/Howtos/route/) (which earned us a [NAB Innovation Award in 2018](https://www.motionspell.com/2018/04/10/2018-nab-technology-innovation-award/)), and our recent addition of FLUTE support for [DVB-MABR (2024)](https://github.com/gpac/gpac/commit/789bf66dce5158ea3d3f9e4e8f72d754bbf95e38), highlight our commitment to staying at the forefront of technology. GPAC also supports DASH, HLS, and other media formats (albeit with some limitations), allowing users to leverage Multicast-ABR as they would any other format—whether for analyzing, dumping, or integrating with other content.

As we continue to push the boundaries of what’s possible, we value the feedback from our community. Your insights are invaluable to our journey; let us know what features or improvements you need as we shape the future of media together.

### **Practical Applications of Multicast-ABR**

Over time, several compelling applications of multicast-ABR have emerged, showcasing the versatility and potential of this technology in different broadcasting scenarios:

-   **Rich-Media Delivery via Broadcast Carousels**: One of the standout applications is the use of carousels to send rich-media content over a broadcast signal. This method allows broadcasters to deliver interactive and enhanced content, such as multimedia presentations or additional data layers, alongside the main broadcast stream.
-   **Layered Media Transmission**: Another innovative use case involves sending a base layer on one channel and an improvement layer on another. This technique enables efficient bandwidth usage while still offering the option to enhance the content quality for users who have the capability to receive and process the additional data.
-   **Separate Channel Media Distribution**: There’s also the possibility of distributing different media components—such as audio, video, and subtitles—across separate channels. This approach can optimize the delivery process, ensuring that each component is transmitted with the appropriate level of quality and bandwidth allocation.

These examples underscore the adaptability of multicast-ABR and GPAC in addressing various media distribution challenges, further solidifying its role in the future of broadcast and streaming technologies.

### **The Evolution of IP Multicast in Broadcast**

Over the last decade, traditional broadcast has found new life through IP multicast. On mobile networks, technologies like LTE and more recently 5G have driven the broadcasting of content, particularly within managed networks—spaces where IP multicast has been a mainstay for years. As consumer habits shift away from linear consumption, the challenge of merging OTT adaptive streaming with the efficiency of multicast has re-emerged, and GPAC is at the forefront of meeting this challenge.

GPAC’s involvement in HbbTV dates back to [2011](https://github.com/gpac/gpac/commit/87d995d30ed02bfbee7efd129167abcfc0f65f70), with carousel technologies in use for enhanced radio services as early as [2009](https://github.com/gpac/gpac/commit/721bc690a8a0416e32b00db48dbf76ed53e68d4a) through initiatives like the Radio+ project. When ATSC 3.0 proposed ROUTE, GPAC quickly implemented it, earning the 2018 NAB Innovation Award. This achievement was made possible through the collaborative efforts of our academic partner, Telecom Paris, and GPAC’s commercial arm, Motion Spell, as part of the ConvergenceTV consortium.

Fast forward to 2023, and [Motion Spell](https://www.motionspell.com) (the commercial entity backing GPAC) has been selected as the [DVB MABR](https://dvb.org/?standard=adaptive-media-streaming-over-ip-multicast) (leveraging FLUTE, a protocol related to ROUTE) solution, positioning it as a potential future standard in the industry. This recognition further cements our role as a leader in the development of cutting-edge media delivery technologies.

### **Innovating with Sustainability: The SMART-CD Initiative**

In media technology, sustainability has become increasingly important. At GPAC, we recognize that innovation must go hand in hand with environmental responsibility. That’s why we’re proud to be part of the [SMART-CD consortium](https://www.smart-cd.fr/), which stands for “Sustainable Media Architecture for TV Content Delivery,” an initiative aimed at addressing the environmental and technological challenges associated with TV service distribution. 

This consortium focuses on optimizing video distribution infrastructure, reducing redundancy in content production and delivery, and developing energy-efficient codecs and transport protocols. This initiative is dedicated to exploring how MABR can reduce the environmental footprint of media delivery, all while maintaining the high-quality experiences that consumers expect. One of its key goals is to create metrics to accurately measure and reduce the carbon footprint of video streaming, particularly within cloud-native architectures.

Through SMART-CD, we are conducting rigorous experiments to assess the potential for energy savings and other environmental benefits when deploying MABR technology. This work not only reinforces GPAC’s commitment to cutting-edge media solutions but also highlights our dedication to driving sustainability within the industry.

The consortium is a collaboration between various industry leaders, including [Motion Spell](https://www.motionspell.com), [Telecom Paris](https://www.telecom-paris.fr/), Ateme, Viaccess-Orca, Nexedi, Greenweb and others, and is working on building a sustainable video streaming ecosystem. This includes creating a monitoring framework to collect environmental impact data and an orchestration agent to dynamically manage energy efficiency across the entire video delivery chain​.

### **Conclusion**

The journey towards perfecting multicast-ABR and its integration into modern media landscapes is ongoing. At GPAC, we are proud to contribute to this evolving narrative, combining our technical expertise with a forward-thinking approach. As we continue to innovate, we invite you to join us in shaping the future of media.

# Posts navigation

[← Older posts](https://gpac.io/page/2/)

#### Quicklinks

-   [Documentation](https://wiki.gpac.io/)
-   [GPAC on Github](https://github.com/gpac/gpac)
-   [GPAC filters architecture](https://wiki.gpac.io/Filters/filters_general/)
-   [MP4Box](https://wiki.gpac.io/MP4Box/MP4Box/)
-   [Licensing](https://gpac.io/licensing)
-   [Jobs](https://gpac.io/jobs)

[Download](https://gpac.io/downloads/gpac-nightly-builds)

[![](https://gpac.io/wp-content/files/2023/12/sponsor-sidebar-2.png)](https://gpac.io/sponsorship)

-   [GPAC 26.02](https://gpac.io/2026/02/05/gpac-26-02/)
    
    by Jean Le Feuvre
    
-   [Announcing MP4Box.js 1.0.0 with TypeScript support](https://gpac.io/2025/06/19/announcing-mp4box-js-1-0-0-with-typescript-support/)
    
    by romain bouqueau
    
-   [100 Million Downloads: A Milestone for the GPAC Community](https://gpac.io/2025/06/10/100-million-downloads-a-milestone-for-the-gpac-community/)
    
    by romain bouqueau
    
-   [The Security Landscape of the GPAC Open-Source Project: A Balanced Perspective](https://gpac.io/2024/10/28/the-security-landscape-of-the-gpac-open-source-project-a-balanced-perspective/)
    
    by romain bouqueau
    
-   [MABR: “Multicast Adaptive BitRate”](https://gpac.io/2024/09/16/mabr-multicast-adaptive-bitrate/)
    
    by romain bouqueau
    
-   [Introducing GPAC.WASM – the new WebAssembly Interface to try GPAC](https://gpac.io/2024/05/03/introducing-gpac-webassembly-console/)
    
    by romain bouqueau
    

#### Categories

-   [Features](https://gpac.io/category/features/)
-   [News](https://gpac.io/category/news/)
-   [Release](https://gpac.io/category/release/)

[Android](https://gpac.io/tag/android/) [AV1](https://gpac.io/tag/av1/) [DASH](https://gpac.io/tag/dash/) [devices](https://gpac.io/tag/devices/) [Digital Radio](https://gpac.io/tag/digital-radio/) [ebu-tt](https://gpac.io/tag/ebu-tt/) [fmp4](https://gpac.io/tag/fmp4/) [gsoc](https://gpac.io/tag/gsoc/) [HbbTV](https://gpac.io/tag/hbbtv/) [HEVC](https://gpac.io/tag/hevc/) [HLS](https://gpac.io/tag/hls/) [HTTP Streaming](https://gpac.io/tag/http-streaming/) [interleaving](https://gpac.io/tag/interleaving/) [isobmff](https://gpac.io/tag/isobmff/) [javascript](https://gpac.io/tag/javascript/) [MP4](https://gpac.io/tag/mp4/) [MP4Box](https://gpac.io/tag/mp4box/) [mp4boxjs](https://gpac.io/tag/mp4boxjs/) [MPEG](https://gpac.io/tag/mpeg/) [MPEG-2 TS](https://gpac.io/tag/mpeg-2-ts/) [OTT](https://gpac.io/tag/ott/) [segmentation](https://gpac.io/tag/segmentation/) [SHVC](https://gpac.io/tag/shvc/) [stereoscopic 3D](https://gpac.io/tag/stereoscopic-3d/) [Subtitle](https://gpac.io/tag/subtitle/) [SVC](https://gpac.io/tag/svc/) [SVG](https://gpac.io/tag/svg/) [UHD](https://gpac.io/tag/uhd/) [VP9](https://gpac.io/tag/vp9/) [W3C](https://gpac.io/tag/w3c/)

[Proudly powered by WordPress](https://wordpress.org/)

[PHP Code Snippets](http://xyzscripts.com/wordpress-plugins/insert-php-code-snippet/ "Insert PHP Snippet Wordpress Plugin") Powered By : [XYZScripts.com](http://www.xyzscripts.com "PHP Scripts & Wordpress Plugins")
```
```

---

## User

---

## Assistant (Compaction · gpt-5.2 · 30.7s)

_Thinking:_



## What we did so far

### Main issue identified and resolved (conceptually)
- You noticed an inconsistency: calling the system “real-time” while also describing **20s “segments”** implied a minimum ~20s latency.
- We clarified the root cause: confusing **keyframe interval** with **delivery unit size**.
- We introduced a clear separation:
  - **Fragments** = frequent fMP4 `moof+mdat` units appended to MSE for low-latency playback
  - **Join fragments** = fragments that start with an **IDR keyframe** (safe random-access entry point)
  - **Initialization segment** = fMP4 `ftyp+moov` sent once per session/join (no frames)

### Spec refactor implemented in the Hugo docs
We updated the existing Hugo/Hextra docs under:

- `hugo/content/docs/reference/media-spec/`

Key changes:
- Added a dedicated **Terminology** page and made it the first entry point.
- Replaced ambiguous “segments” (when it meant live delivery units) with **fragments** everywhere.
- Updated join/buffer logic to explicitly start playback from **join fragments**, not “any segment”.
- Updated transport listing field names to use `fragments` (not `segments`) to match terminology.

### Files created/modified
**Added**
- `hugo/content/docs/reference/media-spec/terminology.md` (new, with `weight: 1`)

**Modified**
- `hugo/content/docs/reference/media-spec/_index.md` (overview table + cards updated; “Fragments” instead of “Segments”)
- `hugo/content/docs/reference/media-spec/segments.md` (retitled content to “Fragments”; defines join fragments; warns about keyframe interval vs latency)
- `hugo/content/docs/reference/media-spec/transport.md` (WS/HTTP terminology; listing uses `fragments`)
- `hugo/content/docs/reference/media-spec/join-flow.md` (join uses join fragments; warning callout)
- `hugo/content/docs/reference/media-spec/memory-buffer.md` (buffers fragments + indexes join fragments)
- `hugo/content/docs/reference/media-spec/container.md` (uses “media fragments”; clarifies join points)
- `hugo/content/docs/reference/media-spec/encoding.md` (updated wording around FPS change and keyframe behavior)
- `hugo/content/docs/reference/media-spec/control-messages.md` (keyframe request yields join fragment; wording updated)
- `hugo/content/docs/reference/media-spec/metadata.md` (Per-Fragment metadata, includes `isJoin`)

Repo status at the time: these files are modified and not committed yet.

### New topic introduced but not yet applied to spec
- Bitrate: you asked about Premiere’s “high adaptive bitrate”; we explained it’s essentially VBR/quality-target behavior, not “unlimited”.
- You then said you plan to use **OpenH264** (MIT-compatible overall project intent; OpenH264 itself is BSD-2-Clause).
- We noted (from OpenH264 README) that OpenH264 supports **Constrained Baseline Profile** (not Main/High), and supports **on-demand IDR**, and dynamic bitrate/fps changes.
- We have **not yet updated the spec to explicitly align encoding requirements with OpenH264 limitations** (profiles, rate control knobs, bitrate policy).

---

## Detailed prompt to continue in a new session (copy/paste)

You are continuing work on a Hugo (Hextra theme) documentation spec for a real-time screen streaming system (Sentinel -> Server -> Proctor). The spec lives under:

`/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/`

Work already done:
- We refactored the spec to fix a major terminology/latency inconsistency: previously “segments” implied long keyframe-based units (20–30s) which would break “real-time”. We introduced:
  - **Initialization segment**: fMP4 `ftyp+moov` (no frames), cached per session
  - **Fragments**: frequent fMP4 `moof+mdat` units for live delivery and MSE appends
  - **Join fragments**: fragments starting with **IDR** keyframes (random access points)
- We added `terminology.md` and updated all docs to use “fragments” for live delivery units and “join fragments” for keyframe entry points.
- We also renamed protocol listing field names in the docs to `fragments` instead of `segments` where “fragment” is meant.
- Files modified/added (uncommitted):
  - Added: `media-spec/terminology.md`
  - Modified: `_index.md`, `container.md`, `segments.md` (content now “Fragments”), `transport.md`, `join-flow.md`, `memory-buffer.md`, `encoding.md`, `control-messages.md`, `metadata.md`, `disk-storage.md`.

Current request:
- Update the spec to explicitly target **OpenH264** as the Sentinel encoder library.
- Incorporate OpenH264’s documented constraints and capabilities:
  - OpenH264 encoder supports **Constrained Baseline Profile** (per OpenH264 README), so the spec must not recommend Main/High as “recommended”; it can be “optional if encoder supports”, but baseline must be the required baseline for compliance.
  - Keep requirements: on-demand IDR insertion, dynamic bitrate and FPS changes supported, max 1080p, 0.2–5 fps.
- Add/clarify a bitrate/rate-control section in `encoding.md`:
  - Define required rate control mode(s) to ensure predictable network/storage, while allowing variable bitrate.
  - Decide whether to specify: target bitrate + max bitrate cap (VBV-like), or quality-based (constant QP) with optional caps.
  - Emphasize that “adaptive bitrate” here means encoder VBR/scene-adaptive, not multi-rendition streaming ABR.
- Ensure all terminology remains consistent: “fragment/join fragment/init segment”.
- After edits, run a grep in `media-spec/` to ensure no remaining “segment(s)” words are used to mean “fragment” (except “initialization segment” which is correct).
- Optionally run a hugo build/serve check to ensure navigation ordering and links are valid.

Constraints/preferences:
- Server does no video processing/transcoding; it stores and relays bytes as-is.
- Live via WebSocket push; older via HTTP pull.
- MSE playback on Proctor.
- Join requires init segment + join fragment + subsequent fragments.
- Buffer last 15–20 seconds of fragments in memory; index join fragments for quick entry.

---

## User

continu

---

## Assistant (Plan · gpt-5.2 · 5.3s)

_Thinking:_



```
Tool: bash

**Input:**
```json
{
  "command": "git status --porcelain=v1 && git diff --stat",
  "description": "Show repo status and diff stats"
}
```
**Output:**
```
 M hugo/content/docs/reference/media-spec/_index.md
 M hugo/content/docs/reference/media-spec/container.md
 M hugo/content/docs/reference/media-spec/control-messages.md
 M hugo/content/docs/reference/media-spec/disk-storage.md
 M hugo/content/docs/reference/media-spec/encoding.md
 M hugo/content/docs/reference/media-spec/join-flow.md
 M hugo/content/docs/reference/media-spec/memory-buffer.md
 M hugo/content/docs/reference/media-spec/metadata.md
 M hugo/content/docs/reference/media-spec/segments.md
 M hugo/content/docs/reference/media-spec/transport.md
?? hugo/content/docs/reference/media-spec/terminology.md
 hugo/content/docs/reference/media-spec/_index.md   |  21 +++--
 .../content/docs/reference/media-spec/container.md |  34 +++----
 .../docs/reference/media-spec/control-messages.md  |  28 +++---
 .../docs/reference/media-spec/disk-storage.md      |  36 +++----
 hugo/content/docs/reference/media-spec/encoding.md |   9 +-
 .../content/docs/reference/media-spec/join-flow.md |  60 ++++++------
 .../docs/reference/media-spec/memory-buffer.md     |  46 +++++----
 hugo/content/docs/reference/media-spec/metadata.md |  60 ++++++------
 hugo/content/docs/reference/media-spec/segments.md | 103 ++++++++++++---------
 .../content/docs/reference/media-spec/transport.md |  94 ++++++++++---------
 10 files changed, 266 insertions(+), 225 deletions(-)

```
```

```
Tool: glob

**Input:**
```json
{
  "pattern": "hugo/content/docs/reference/media-spec/*.md"
}
```
**Output:**
```
/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/metadata.md
/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/_index.md
/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/transport.md
/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/disk-storage.md
/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/container.md
/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/segments.md
/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/join-flow.md
/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/encoding.md
/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/control-messages.md
/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/memory-buffer.md
/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/terminology.md
```
```

```
Tool: grep

**Input:**
```json
{
  "pattern": "\\bsegment(s)?\\b",
  "path": "hugo/content/docs/reference/media-spec",
  "include": "*.md"
}
```
**Output:**
```
Found 34 matches
/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/metadata.md:
  Line 56: | `initSegmentPath` | string | Path to initialization segment on disk |
  Line 122: | Proctor joins stream | Memory (init segment + buffered fragments) |
  Line 150: | Init segment bytes | No (stored as file on disk) |

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/_index.md:
  Line 35: {{< card link="segments" title="Fragments" icon="collection" subtitle="Fragment cadence and join fragments" >}}

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/transport.md:
  Line 60: Srv -> P : init segment
  Line 94: The initialization segment is sent separately, typically:
  Line 102: | `data` | bytes | Raw fMP4 initialization segment bytes |

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/disk-storage.md:
  Line 17: | Initialization segment | Yes | Raw fMP4 bytes |
  Line 63: | Initialization segment received | Write to `init.mp4` |
  Line 91: Each fragment file is a complete, valid fMP4 media fragment. Combined with the initialization segment, any fragment can be decoded independently when appended in order; a Proctor SHOULD start at a join fragment.
  Line 109: Provide initialization segment + media fragments to an fMP4-compatible player or MSE.
  Line 132: 1. Fetch the initialization segment

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/container.md:
  Line 51: The initialization segment contains metadata required to configure the decoder. It does not contain any video frames.
  Line 89:  | Decodable with init | A fragment is decodable when appended after the initialization segment and appropriate preceding fragments |
  Line 99: The timescale from the initialization segment determines how timestamps map to wall-clock time. A common choice is 90000 (90kHz), allowing sub-millisecond precision.
  Line 110: Obtain the initialization segment for the target Sentinel from the Server.
  Line 114: Create a `MediaSource`, add a `SourceBuffer` with the appropriate MIME type, and append the initialization segment.

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/segments.md:
  Line 87: The initialization segment uses a distinct name:
  Line 141:  | Session start | Sequence resets to 0, new initialization segment created |
  Line 146: If a Sentinel reconnects (new session), it generates a new initialization segment and restarts sequence numbering at 0. The Server treats this as a new stream.

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/join-flow.md:
  Line 12: 2. Receive the initialization segment
  Line 38: Srv -> P : init segment
  Line 85: The Server sends the cached initialization segment for the Sentinel's current session.
  Line 93: | `data` | bytes | Raw fMP4 init segment |
  Line 151: Srv -> P : init segment
  Line 191: - Append the new initialization segment
  Line 203: | No join fragment in buffer | Send init segment, request/await next join fragment |

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/encoding.md:
  Line 87: When FPS changes, a new join fragment must be produced (see [Fragments](../segments)).

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/memory-buffer.md:
  Line 31: | **Initialization segment** | The codec/resolution configuration for the session |
  Line 75: 1. Server sends the initialization segment
  Line 95: The initialization segment for each active Sentinel is cached separately from the media fragment buffer.
  Line 103: Since the initialization segment is small (typically a few KB) and required for every new Proctor, it remains in memory for the duration of the Sentinel's session.

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/terminology.md:
  Line 15: | **Initialization segment** | fMP4 `ftyp` + `moov` bytes for the session. Contains codec config (SPS/PPS), resolution, timescale. Contains **no frames**. | Must be appended to MSE before any media data can be decoded.
  Line 39: It does **not** mean "start sending an empty 20s segment at t=0".
```
```

```
Tool: grep

**Input:**
```json
{
  "pattern": "OpenH264|openh264|Baseline|Constrained Baseline|profile",
  "path": "hugo/content/docs/reference/media-spec",
  "include": "*.md"
}
```
**Output:**
```
Found 8 matches
/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/container.md:
  Line 139: Where `PPCCLL` is the H.264 profile/level indicator:
  Line 140: - `42` = Baseline profile
  Line 141: - `4D` = Main profile
  Line 144: Example for Baseline Profile, Level 3.1:

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/encoding.md:
  Line 24: ### Recommended: Baseline Profile
  Line 28: | Profile | Baseline | Maximum decoder compatibility, simpler encoding |
  Line 32: - Baseline lacks B-frames, resulting in slightly larger files
  Line 44: - 10-20% smaller file sizes than Baseline
```
```

---

## Assistant (Plan · gpt-5.2 · 3.4s)

```
Tool: read

**Input:**
```json
{
  "filePath": "/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/encoding.md"
}
```
**Output:**
```
<file>
00001| ---
00002| title: Encoding
00003| ---
00004| 
00005| This document specifies the video encoding requirements for Sentinel screen capture.
00006| 
00007| ## Codec
00008| 
00009| **H.264 (AVC)** is the required codec for all video streams.
00010| 
00011| ### Why H.264
00012| 
00013| - Universal hardware decoding support (Intel Quick Sync, NVIDIA NVENC, AMD VCE)
00014| - Native playback in all modern browsers via MSE
00015| - Low CPU overhead when hardware encoding is available
00016| - Widely supported on school/institutional hardware
00017| 
00018| ## Profile and Level
00019| 
00020| {{< callout type="info" >}}
00021| These are recommendations. Implementations may adjust based on hardware capabilities.
00022| {{< /callout >}}
00023| 
00024| ### Recommended: Baseline Profile
00025| 
00026| | Setting | Value | Rationale |
00027| |---------|-------|-----------|
00028| | Profile | Baseline | Maximum decoder compatibility, simpler encoding |
00029| | Level | 3.1 | Supports 1080p at low framerates |
00030| 
00031| **Tradeoffs:**
00032| - Baseline lacks B-frames, resulting in slightly larger files
00033| - Guaranteed to decode on all hardware, including older/weaker devices
00034| - Fastest encoding speed
00035| 
00036| ### Alternative: Main Profile
00037| 
00038| | Setting | Value | Rationale |
00039| |---------|-------|-----------|
00040| | Profile | Main | Better compression via B-frames and CABAC |
00041| | Level | 3.1 | Supports 1080p at low framerates |
00042| 
00043| **Tradeoffs:**
00044| - 10-20% smaller file sizes than Baseline
00045| - Requires slightly more capable hardware for encoding
00046| - Still universally supported for decoding in browsers
00047| 
00048| ### Level Reference
00049| 
00050| | Level | Max Resolution | Max Framerate | Notes |
00051| |-------|----------------|---------------|-------|
00052| | 3.0 | 1280x720 | 30 fps | Sufficient for 720p |
00053| | 3.1 | 1920x1080 | 30 fps | Recommended for 1080p |
00054| | 4.0 | 2048x1024 | 30 fps | Overkill for this use case |
00055| 
00056| ## Resolution
00057| 
00058| | Constraint | Value |
00059| |------------|-------|
00060| | Maximum | 1920x1080 (Full HD) |
00061| | Aspect Ratio | Preserved from source |
00062| | Downscaling | Required if source exceeds 1080p |
00063| 
00064| The Sentinel must downscale captured frames to fit within 1920x1080 while preserving the original aspect ratio. For example, a 2560x1440 capture would be downscaled to 1920x1080.
00065| 
00066| ## Framerate
00067| 
00068| | Parameter | Value |
00069| |-----------|-------|
00070| | Minimum | 0.2 fps (1 frame per 5 seconds) |
00071| | Maximum | 5 fps |
00072| | Variability | Can change over time (see timestamps) |
00073| 
00074| ### Variable Framerate Behavior
00075| 
00076| - Framerate can change when the Server requests it (see [Control Messages](../control-messages))
00077| - Each frame carries a timestamp for accurate playback timing
00078| - Players must use frame timestamps, not assume constant framerate
00079| 
00080| ### FPS Change Triggers
00081| 
00082| The Server may request a framerate change from the Sentinel. Common reasons:
00083| - Server under heavy load (reduce FPS to reduce message volume)
00084| - Network congestion detected
00085| - Administrative policy change
00086| 
00087| When FPS changes, a new join fragment must be produced (see [Fragments](../segments)).
00088| 
00089| ## Keyframes (I-Frames)
00090| 
00091| Keyframes are complete frames that can be decoded independently without reference to previous frames.
00092| 
00093| ### Keyframe Rules
00094| 
00095| | Rule | Description |
00096| |------|-------------|
00097| | On-demand | Sentinel must generate a keyframe when requested by Server |
00098| | Maximum interval | At least one keyframe every 20-30 seconds |
00099| | On FPS change | Next join fragment starts with a keyframe when framerate changes |
00100| 
00101| ### Why On-Demand Keyframes
00102| 
00103| - Allows Proctors to join streams quickly without waiting for the next scheduled keyframe
00104| - Enables predictive pre-fetching (Proctor requests keyframe before switching streams)
00105| - Minimizes unnecessary keyframes, reducing bandwidth
00106| 
00107| ### IDR Frames
00108| 
00109| All keyframes must be **IDR (Instantaneous Decoder Refresh)** frames, not just I-frames. IDR frames clear the decoder reference buffer, ensuring clean entry points for new viewers.
00110| 

(End of file - total 110 lines)
</file>
```
```

```
Tool: read

**Input:**
```json
{
  "filePath": "/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/container.md"
}
```
**Output:**
```
<file>
00001| ---
00002| title: Container
00003| ---
00004| 
00005| This document specifies the container format for video data.
00006| 
00007| ## Format: Fragmented MP4 (fMP4)
00008| 
00009| All video data is packaged in **Fragmented MP4** format. This is a variant of the standard MP4 container optimized for streaming.
00010| 
00011| ### Why fMP4
00012| 
00013| - Native support in browser Media Source Extensions (MSE)
00014| - No transcoding needed on Server or Proctor
00015| - Fragments can be appended incrementally (with initialization data)
00016| - Industry standard for adaptive streaming (DASH, HLS)
00017| 
00018| ## Structure Overview
00019| 
00020| An fMP4 stream consists of two types of data:
00021| 
00022| | Type | Purpose | When Sent |
00023| |------|---------|-----------|
00024| | **Initialization Segment** | Contains codec configuration, resolution, timescale | Once per session, on Proctor join |
00025|  | **Media Fragment** | Contains encoded samples (frames) and timing (`moof` + `mdat`) | Continuously during streaming |
00026| 
00027| ```
00028| ┌─────────────────────────┐
00029| │  Initialization Segment │  ← Sent once per session
00030| │  (ftyp + moov boxes)    │
00031| └─────────────────────────┘
00032|            │
00033|            ▼
00034| ┌─────────────────────────┐
00035| │    Media Fragment 1     │  ← May start with keyframe
00036| │  (moof + mdat boxes)    │
00037| └─────────────────────────┘
00038|             │
00039|             ▼
00040| ┌─────────────────────────┐
00041| │    Media Fragment 2     │  ← May start with keyframe
00042| │  (moof + mdat boxes)    │
00043| └─────────────────────────┘
00044|            │
00045|            ▼
00046|           ...
00047| ```
00048| 
00049| ## Initialization Segment
00050| 
00051| The initialization segment contains metadata required to configure the decoder. It does not contain any video frames.
00052| 
00053| ### Contents
00054| 
00055| | Box | Purpose |
00056| |-----|---------|
00057| | `ftyp` | File type declaration (brand: `iso5` or `isom`) |
00058| | `moov` | Movie header containing codec and track information |
00059| 
00060| ### Key Information in `moov`
00061| 
00062| - **Codec parameters**: H.264 SPS/PPS (Sequence/Picture Parameter Sets)
00063| - **Resolution**: Width and height in pixels
00064| - **Timescale**: Time units per second for timestamps
00065| 
00066| ### Lifetime
00067| 
00068| - Generated once when the Sentinel starts a session
00069| - Remains valid for the entire session
00070| - Resolution and codec parameters do not change mid-session
00071| - Server caches in memory for each active Sentinel
00072| - Sent to Proctor on stream join request
00073| 
00074| ## Media Fragments
00075| 
00076| Each media fragment contains one or more encoded samples (video frames) packaged for streaming.
00077| 
00078| ### Contents
00079| 
00080| | Box | Purpose |
00081| |-----|---------|
00082| | `moof` | Movie fragment header (timing, frame offsets) |
00083| | `mdat` | Media data (actual H.264 NAL units) |
00084| 
00085| ### Requirements
00086| 
00087|  | Requirement | Description |
00088|  |-------------|-------------|
00089|  | Decodable with init | A fragment is decodable when appended after the initialization segment and appropriate preceding fragments |
00090|  | Join points | A **join fragment** begins with an IDR frame and is a safe entry point for new viewers |
00091|  | Self-contained timing | Timestamps in `moof` are absolute (not relative to previous fragment) |
00092|  | Variable duration | Fragments can have different durations |
00093| 
00094| ### Timing Information
00095| 
00096| The `moof` box contains a `tfdt` (Track Fragment Decode Time) box specifying the decode timestamp of the first frame. Each frame's duration is specified in the `trun` (Track Fragment Run) box.
00097| 
00098| {{< callout type="info" >}}
00099| The timescale from the initialization segment determines how timestamps map to wall-clock time. A common choice is 90000 (90kHz), allowing sub-millisecond precision.
00100| {{< /callout >}}
00101| 
00102| ## Proctor Playback
00103| 
00104| To play a stream, the Proctor must:
00105| 
00106| {{% steps %}}
00107| 
00108| ### Receive Initialization Segment
00109| 
00110| Obtain the initialization segment for the target Sentinel from the Server.
00111| 
00112| ### Initialize MSE SourceBuffer
00113| 
00114| Create a `MediaSource`, add a `SourceBuffer` with the appropriate MIME type, and append the initialization segment.
00115| 
00116| ```javascript
00117| // Example MIME type for H.264 in fMP4
00118| "video/mp4; codecs=\"avc1.42E01F\""
00119| ```
00120| 
00121| ### Append Media Fragments
00122| 
00123| As media fragments arrive, append them to the `SourceBuffer` in order.
00124| 
00125| ### Handle Playback
00126| 
00127| The browser's video element handles decoding and rendering automatically.
00128| 
00129| {{% /steps %}}
00130| 
00131| ## MIME Type
00132| 
00133| The MIME type for MSE must specify both the container and codec:
00134| 
00135| ```
00136| video/mp4; codecs="avc1.PPCCLL"
00137| ```
00138| 
00139| Where `PPCCLL` is the H.264 profile/level indicator:
00140| - `42` = Baseline profile
00141| - `4D` = Main profile
00142| - `E01F` = Level 3.1
00143| 
00144| Example for Baseline Profile, Level 3.1:
00145| ```
00146| video/mp4; codecs="avc1.42E01F"
00147| ```
00148| 
00149| Example for Main Profile, Level 3.1:
00150| ```
00151| video/mp4; codecs="avc1.4D401F"
00152| ```
00153| 

(End of file - total 153 lines)
</file>
```
```

```
Tool: read

**Input:**
```json
{
  "filePath": "/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/segments.md"
}
```
**Output:**
```
<file>
00001| ---
00002| title: Fragments
00003| ---
00004| 
00005| This document specifies how **fragments** are created, how they are named, and how **join fragments** (keyframe entry points) work.
00006| 
00007| See [Terminology](../terminology) for definitions.
00008| 
00009| ## Fragment Definition
00010| 
00011| A **fragment** is a single fMP4 media unit (`moof` + `mdat`) containing one or more encoded samples. Fragments are the unit of live delivery and MSE appends.
00012| 
00013| Fragments:
00014| 
00015| - Are produced continuously during streaming
00016| - Are appended to MSE in order
00017| 
00018| {{< callout type="warning" >}}
00019| Keyframes control **join/switch latency**, not live latency.
00020| 
00021| Live latency is determined by how often fragments are finalized and pushed.
00022| {{< /callout >}}
00023| 
00024| ## Join Fragments
00025| 
00026| A **join fragment** is a fragment whose first sample is an IDR keyframe. Join fragments are random access points for Proctors.
00027| 
00028| ## Join Fragment Triggers
00029| 
00030| A new join fragment is produced when any of the following occur:
00031| 
00032| | Trigger | Description |
00033| |---------|-------------|
00034|  | **On-demand keyframe** | Proctor initiates; next capture becomes IDR |
00035|  | **FPS change** | Server requests new FPS; next capture becomes IDR |
00036|  | **Maximum interval reached** | If no keyframe has occurred in 20-30 seconds, one is forced |
00037| 
00038| ```
00039| Timeline (conceptual):
00040| Fragments are produced continuously, while join fragments occur on keyframes.
00041| 
00042| ├─ fragment ─ fragment ─ join fragment ─ fragment ─ ... ─ join fragment ─ fragment ─┤
00043|                   [IDR]                            [IDR]
00044| ```
00045| 
00046| *IDR = keyframe*
00047| 
00048| ## Sequence Numbers
00049| 
00050| Each Sentinel maintains a **sequence counter** for its fragments.
00051| 
00052| | Property | Value |
00053| |----------|-------|
00054| | Start value | 0 |
00055|  | Increment | 1 per fragment |
00056| | Scope | Per Sentinel, per session |
00057| | Controller | Sentinel (not Server) |
00058| 
00059| The sequence number is assigned by the Sentinel when the fragment is created and included in the metadata sent to the Server.
00060| 
00061| ## Naming Convention
00062| 
00063| Fragments are identified by the combination of Sentinel ID and sequence number.
00064| 
00065| ### Format
00066| 
00067| ```
00068| {sentinelId}-{sequence}.m4s
00069| ```
00070| 
00071| | Component | Description | Example |
00072| |-----------|-------------|---------|
00073| | `sentinelId` | Unique identifier for the Sentinel | `sentinel-a1b2c3` |
00074| | `sequence` | Zero-padded sequence number | `000142` |
00075| | Extension | `.m4s` for fMP4 media fragments | |
00076| 
00077| ### Examples
00078| 
00079| ```
00080| sentinel-a1b2c3-000000.m4s   # First fragment
00081| sentinel-a1b2c3-000001.m4s   # Second fragment
00082| sentinel-a1b2c3-000142.m4s   # 143rd fragment
00083| ```
00084| 
00085| ### Initialization Segment Naming
00086| 
00087| The initialization segment uses a distinct name:
00088| 
00089| ```
00090| {sentinelId}-init.mp4
00091| ```
00092| 
00093| Example:
00094| ```
00095| sentinel-a1b2c3-init.mp4
00096| ```
00097| 
00098| ## Fragment Duration
00099| 
00100| Fragment duration is **variable** and chosen by the Sentinel implementation to balance latency and overhead.
00101| 
00102| The spec intentionally does not mandate an exact fragment duration, but fragments MUST be produced frequently enough to satisfy the real-time requirement.
00103| 
00104| | Scenario | Typical Duration |
00105| |----------|------------------|
00106| | Typical real-time operation | ~0.25s to ~2s (implementation choice) |
00107| | Very low FPS mode (0.2 fps) | One fragment per capture (up to 5s) |
00108| | Joins / FPS changes | A join fragment is produced on the next capture |
00109| 
00110| {{< callout type="warning" >}}
00111| Do not design around the assumption that fragments are 20-30 seconds long.
00112| 
00113| 20-30 seconds is the **maximum keyframe interval** (join fragment spacing), not the fragment duration.
00114| {{< /callout >}}
00115| 
00116| ## Fragment Contents
00117| 
00118| Each media fragment contains:
00119| 
00120| | Content | Location | Description |
00121| |---------|----------|-------------|
00122| | Decode timestamp | `moof` → `tfdt` | Absolute timestamp of first frame |
00123| | Frame durations | `moof` → `trun` | Duration of each frame in fragment |
00124| | Frame data | `mdat` | Encoded H.264 NAL units |
00125| 
00126| ### Frame Timestamps
00127| 
00128| Every sample within a fragment has a precise timestamp derived from:
00129| 
00130| 1. The fragment's base decode time (`tfdt`)
00131| 2. The cumulative duration of preceding samples (`trun` sample durations)
00132| 
00133| This allows accurate playback timing regardless of FPS changes over time.
00134| 
00135| ## Relationship to Sessions
00136| 
00137| A **session** is the period from when a Sentinel connects to when it disconnects.
00138| 
00139| | Session Event | Segment Behavior |
00140| |---------------|------------------|
00141|  | Session start | Sequence resets to 0, new initialization segment created |
00142|  | Session continues | Sequence increments with each fragment |
00143|  | Session ends | Final fragment may be shorter than normal |
00144| 
00145| {{< callout type="info" >}}
00146| If a Sentinel reconnects (new session), it generates a new initialization segment and restarts sequence numbering at 0. The Server treats this as a new stream.
00147| {{< /callout >}}
00148| 

(End of file - total 148 lines)
</file>
```
```

```
Tool: read

**Input:**
```json
{
  "filePath": "/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/transport.md"
}
```
**Output:**
```
<file>
00001| ---
00002| title: Transport
00003| ---
00004| 
00005| This document specifies how video data is transported between components.
00006| 
00007| ## Overview
00008| 
00009| | Use Case | Protocol | Direction |
00010| |----------|----------|-----------|
00011| | Live streaming | WebSocket | Server → Proctor (push) |
00012| | Live streaming | WebSocket | Sentinel → Server (push) |
00013| | Historical playback | HTTP | Proctor → Server (pull) |
00014| | Control messages | WebSocket | Bidirectional |
00015| 
00016| ## WebSocket: Live Streaming
00017| 
00018| All live video data flows over WebSocket connections.
00019| 
00020| ### Sentinel → Server
00021| 
00022| The Sentinel pushes **fragments** to the Server as they are finalized.
00023| 
00024| See [Terminology](../terminology) for the distinction between fragments (live delivery units) and keyframes (join points).
00025| 
00026| ```plantuml
00027| @startuml
00028| skinparam sequenceMessageAlign center
00029| 
00030| participant "Sentinel" as S
00031| participant "Server" as Srv
00032| 
00033| == Fragment Streaming ==
00034| 
00035| S -> Srv : fragment data
00036| note right: Fragment 140
00037| 
00038| S -> Srv : fragment data
00039| note right: Fragment 141
00040| 
00041| S -> Srv : fragment data
00042| note right: Fragment 142
00043| 
00044| @enduml
00045| ```
00046| 
00047| ### Server → Proctor
00048| 
00049| The Server pushes fragments to subscribed Proctors as they arrive.
00050| 
00051| ```plantuml
00052| @startuml
00053| skinparam sequenceMessageAlign center
00054| 
00055| participant "Server" as Srv
00056| participant "Proctor" as P
00057| 
00058| == Live Push ==
00059| 
00060| Srv -> P : init segment
00061| Srv -> P : fragment data
00062| note left: Fragment 140
00063| 
00064| Srv -> P : fragment data
00065| note left: Fragment 141
00066| 
00067| Srv -> P : fragment data
00068| note left: Fragment 142
00069| 
00070| @enduml
00071| ```
00072| 
00073| ### Data Format
00074| 
00075| The spec does not mandate a specific serialization format for WebSocket messages. Implementations may use:
00076| 
00077| - JSON with base64-encoded binary data
00078| - Binary WebSocket frames with a header
00079| - Protocol Buffers
00080| - Other formats
00081| 
00082| The key requirement is that the message contains:
00083| 
00084|  | Field | Type | Description |
00085|  |-------|------|-------------|
00086|  | `sentinelId` | string | Identifies which Sentinel this fragment belongs to |
00087|  | `sequence` | integer | Fragment sequence number |
00088|  | `data` | bytes | Raw fMP4 fragment bytes (`moof` + `mdat`) |
00089| 
00090| Additional metadata (framerate, timestamp) may be included or derived from the fragment bytes.
00091| 
00092| ### Initialization Segment
00093| 
00094| The initialization segment is sent separately, typically:
00095| 
00096| - Once when a Proctor joins a stream
00097| - On request (see [Control Messages](../control-messages))
00098| 
00099| | Field | Type | Description |
00100| |-------|------|-------------|
00101| | `sentinelId` | string | Identifies which Sentinel |
00102| | `data` | bytes | Raw fMP4 initialization segment bytes |
00103| 
00104| ## HTTP: Historical Playback
00105| 
00106| For accessing fragments that have aged out of the memory buffer, Proctors use HTTP.
00107| 
00108| ### Required Information
00109| 
00110| To fetch a historical fragment, the Proctor needs:
00111| 
00112| | Information | Description |
00113| |-------------|-------------|
00114| | `sentinelId` | Which Sentinel's stream |
00115| | `sessionId` | Which session |
00116|  | `sequence` | Which fragment (or range) |
00117| 
00118| ### Response
00119| 
00120| The HTTP response contains the raw fMP4 fragment bytes with appropriate content headers.
00121| 
00122| | Header | Value |
00123| |--------|-------|
00124| | `Content-Type` | `video/mp4` |
00125| | `Content-Length` | Size in bytes |
00126| 
00127| ### Listing Available Fragments
00128| 
00129| Proctors may need to query which fragments are available for a session. The response should include:
00130| 
00131|  | Field | Type | Description |
00132|  |-------|------|-------------|
00133|  | `sentinelId` | string | Sentinel identifier |
00134|  | `sessionId` | string | Session identifier |
00135|  | `fragments` | array | List of available fragment metadata |
00136| 
00137| Each entry:
00138| 
00139| | Field | Type | Description |
00140| |-------|------|-------------|
00141|  | `sequence` | integer | Fragment number |
00142|  | `startTime` | timestamp | When the fragment starts |
00143|  | `duration` | integer | Duration in milliseconds |
00144| 
00145| {{< callout type="info" >}}
00146| The exact HTTP endpoint structure is implementation-defined. The spec only defines what information must be available.
00147| {{< /callout >}}
00148| 
00149| ## Protocol Selection
00150| 
00151| ### When to Use WebSocket
00152| 
00153| | Scenario | Use WebSocket |
00154| |----------|---------------|
00155| | Live stream viewing | Yes |
00156|  | Joining a stream | Yes (get init + recent fragments) |
00157|  | Control messages (keyframe request, FPS change) | Yes |
00158|  | Real-time fragment push from Sentinel | Yes |
00159| 
00160| ### When to Use HTTP
00161| 
00162|  | Scenario | Use HTTP |
00163|  |----------|----------|
00164|  | Fetching fragments older than buffer window | Yes |
00165|  | Querying available sessions/fragments | Yes |
00166|  | Downloading for export/archival | Yes |
00167| 
00168| ## Connection Lifecycle
00169| 
00170| ### Sentinel Connection
00171| 
00172| 1. Sentinel establishes WebSocket connection to Server
00173| 2. Sentinel sends registration/identification
00174| 3. Sentinel begins pushing fragments
00175| 4. Connection remains open for session duration
00176| 5. On disconnect, session ends
00177| 
00178| ### Proctor Connection
00179| 
00180| 1. Proctor establishes WebSocket connection to Server
00181| 2. Proctor sends registration/identification
00182| 3. Proctor subscribes to one or more Sentinel streams
00183| 4. Server pushes fragments for subscribed streams
00184| 5. Proctor may switch subscriptions during session
00185| 6. Connection remains open while Proctor is active
00186| 
00187| ## Bandwidth Considerations
00188| 
00189| Since Sentinel and Server are expected to be on the same LAN:
00190| 
00191| - Bandwidth is not a primary constraint
00192| - Single-frame messages are acceptable
00193| - No need for aggressive batching or compression beyond H.264
00194| 
00195| For Proctor connections (potentially over WAN):
00196| 
00197| - The memory buffer (15-20 seconds) provides catch-up capacity
00198| - Proctors with slow connections may fall behind
00199| - If behind by more than buffer window, Proctor must skip forward or use HTTP for historical catch-up
00200| 

(End of file - total 200 lines)
</file>
```
```

```
Tool: read

**Input:**
```json
{
  "filePath": "/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/terminology.md"
}
```
**Output:**
```
<file>
00001| ---
00002| title: Terminology
00003| weight: 1
00004| ---
00005| 
00006| This specification uses a few terms that are easy to mix up in real-time video systems. This page defines them precisely.
00007| 
00008| ## Core Terms
00009| 
00010| | Term | Meaning in this spec | Why it matters |
00011| |------|-----------------------|----------------|
00012| | **Capture frame** | A single screen image sampled by the Sentinel (pre-encode). | Controls what the user *could* see and when.
00013| | **Encoded sample** | The encoded representation of a capture frame in the H.264 stream (what MP4 carries as a sample). | This is what is actually transported and stored.
00014| | **Keyframe (IDR)** | An H.264 IDR frame (Instantaneous Decoder Refresh). A decoder can start cleanly from here. | Controls *join/switch latency* for a new Proctor.
00015| | **Initialization segment** | fMP4 `ftyp` + `moov` bytes for the session. Contains codec config (SPS/PPS), resolution, timescale. Contains **no frames**. | Must be appended to MSE before any media data can be decoded.
00016| | **Fragment** | A small fMP4 media unit (`moof` + `mdat`) produced frequently and pushed live. Contains **one or more encoded samples**. | Controls *live latency* and how often Proctors see updates.
00017| | **Join fragment** | A fragment whose first sample is an **IDR** keyframe (random access point). | A Proctor should start playback from a join fragment.
00018| 
00019| {{< callout type="warning" >}}
00020| Do not equate **keyframe interval** with **delivery latency**.
00021| 
00022| - Keyframe interval controls how quickly a new viewer can join without an on-demand keyframe.
00023| - Fragment cadence (how often fragments are produced and pushed) controls how quickly an existing viewer sees new video.
00024| {{< /callout >}}
00025| 
00026| ## Practical Implications
00027| 
00028| ### Real-Time Requirement
00029| 
00030| Live streaming MUST push **fragments** continuously. A "20 second" value can apply to the *maximum keyframe interval* (join point spacing), but MUST NOT imply that media is only delivered every 20 seconds.
00031| 
00032| ### What "Sent As It Is Created" Means
00033| 
00034| When this spec says "sent as it is created", it means:
00035| 
00036| - A fragment is finalized (it already contains at least one encoded sample).
00037| - That finalized fragment is immediately sent over WebSocket.
00038| 
00039| It does **not** mean "start sending an empty 20s segment at t=0".
00040| 

(End of file - total 40 lines)
</file>
```
```

---

## Assistant (Plan · gpt-5.2 · 10.5s)

_Thinking:_



```
Tool: webfetch

**Input:**
```json
{
  "url": "https://github.com/cisco/openh264",
  "format": "markdown",
  "timeout": 120
}
```
**Output:**
```
                    GitHub - cisco/openh264: Open Source H.264 Codec                                             

[Skip to content](#start-of-content)   

## Navigation Menu

Toggle navigation

[](/)

[Sign in](/login?return_to=https%3A%2F%2Fgithub.com%2Fcisco%2Fopenh264)

Appearance settings

  

-   Platform
    
    -   AI CODE CREATION
        
        -   [
            
            GitHub CopilotWrite better code with AI
            
            ](https://github.com/features/copilot)
        -   [
            
            GitHub SparkBuild and deploy intelligent apps
            
            ](https://github.com/features/spark)
        -   [
            
            GitHub ModelsManage and compare prompts
            
            ](https://github.com/features/models)
        -   [
            
            MCP RegistryNewIntegrate external tools
            
            ](https://github.com/mcp)
        
    -   DEVELOPER WORKFLOWS
        
        -   [
            
            ActionsAutomate any workflow
            
            ](https://github.com/features/actions)
        -   [
            
            CodespacesInstant dev environments
            
            ](https://github.com/features/codespaces)
        -   [
            
            IssuesPlan and track work
            
            ](https://github.com/features/issues)
        -   [
            
            Code ReviewManage code changes
            
            ](https://github.com/features/code-review)
        
    -   APPLICATION SECURITY
        
        -   [
            
            GitHub Advanced SecurityFind and fix vulnerabilities
            
            ](https://github.com/security/advanced-security)
        -   [
            
            Code securitySecure your code as you build
            
            ](https://github.com/security/advanced-security/code-security)
        -   [
            
            Secret protectionStop leaks before they start
            
            ](https://github.com/security/advanced-security/secret-protection)
        
    -   EXPLORE
        
        -   [Why GitHub](https://github.com/why-github)
        -   [Documentation](https://docs.github.com)
        -   [Blog](https://github.blog)
        -   [Changelog](https://github.blog/changelog)
        -   [Marketplace](https://github.com/marketplace)
        
    
    [View all features](https://github.com/features)
    
-   Solutions
    
    -   BY COMPANY SIZE
        
        -   [Enterprises](https://github.com/enterprise)
        -   [Small and medium teams](https://github.com/team)
        -   [Startups](https://github.com/enterprise/startups)
        -   [Nonprofits](https://github.com/solutions/industry/nonprofits)
        
    -   BY USE CASE
        
        -   [App Modernization](https://github.com/solutions/use-case/app-modernization)
        -   [DevSecOps](https://github.com/solutions/use-case/devsecops)
        -   [DevOps](https://github.com/solutions/use-case/devops)
        -   [CI/CD](https://github.com/solutions/use-case/ci-cd)
        -   [View all use cases](https://github.com/solutions/use-case)
        
    -   BY INDUSTRY
        
        -   [Healthcare](https://github.com/solutions/industry/healthcare)
        -   [Financial services](https://github.com/solutions/industry/financial-services)
        -   [Manufacturing](https://github.com/solutions/industry/manufacturing)
        -   [Government](https://github.com/solutions/industry/government)
        -   [View all industries](https://github.com/solutions/industry)
        
    
    [View all solutions](https://github.com/solutions)
    
-   Resources
    
    -   EXPLORE BY TOPIC
        
        -   [AI](https://github.com/resources/articles?topic=ai)
        -   [Software Development](https://github.com/resources/articles?topic=software-development)
        -   [DevOps](https://github.com/resources/articles?topic=devops)
        -   [Security](https://github.com/resources/articles?topic=security)
        -   [View all topics](https://github.com/resources/articles)
        
    -   EXPLORE BY TYPE
        
        -   [Customer stories](https://github.com/customer-stories)
        -   [Events & webinars](https://github.com/resources/events)
        -   [Ebooks & reports](https://github.com/resources/whitepapers)
        -   [Business insights](https://github.com/solutions/executive-insights)
        -   [GitHub Skills](https://skills.github.com)
        
    -   SUPPORT & SERVICES
        
        -   [Documentation](https://docs.github.com)
        -   [Customer support](https://support.github.com)
        -   [Community forum](https://github.com/orgs/community/discussions)
        -   [Trust center](https://github.com/trust-center)
        -   [Partners](https://github.com/partners)
        
    
-   Open Source
    
    -   COMMUNITY
        
        -   [
            
            GitHub SponsorsFund open source developers
            
            ](https://github.com/sponsors)
        
    -   PROGRAMS
        
        -   [Security Lab](https://securitylab.github.com)
        -   [Maintainer Community](https://maintainers.github.com)
        -   [Accelerator](https://github.com/accelerator)
        -   [Archive Program](https://archiveprogram.github.com)
        
    -   REPOSITORIES
        
        -   [Topics](https://github.com/topics)
        -   [Trending](https://github.com/trending)
        -   [Collections](https://github.com/collections)
        
    
-   Enterprise
    
    -   ENTERPRISE SOLUTIONS
        
        -   [
            
            Enterprise platformAI-powered developer platform
            
            ](https://github.com/enterprise)
        
    -   AVAILABLE ADD-ONS
        
        -   [
            
            GitHub Advanced SecurityEnterprise-grade security features
            
            ](https://github.com/security/advanced-security)
        -   [
            
            Copilot for BusinessEnterprise-grade AI features
            
            ](https://github.com/features/copilot/copilot-business)
        -   [
            
            Premium SupportEnterprise-grade 24/7 support
            
            ](https://github.com/premium-support)
        
    
-   [Pricing](https://github.com/pricing)

Search or jump to...

# Search code, repositories, users, issues, pull requests...

Search

Clear

[Search syntax tips](https://docs.github.com/search-github/github-code-search/understanding-github-code-search-syntax)

# Provide feedback

We read every piece of feedback, and take your input very seriously.

 Include my email address so I can be contacted

Cancel Submit feedback

# Saved searches

## Use saved searches to filter your results more quickly

Name  

Query 

To see all available qualifiers, see our [documentation](https://docs.github.com/search-github/github-code-search/understanding-github-code-search-syntax).

Cancel Create saved search

[Sign in](/login?return_to=https%3A%2F%2Fgithub.com%2Fcisco%2Fopenh264)

[Sign up](/signup?ref_cta=Sign+up&ref_loc=header+logged+out&ref_page=%2F%3Cuser-name%3E%2F%3Crepo-name%3E&source=header-repo&source_repo=cisco%2Fopenh264)

Appearance settings

Resetting focus

You signed in with another tab or window. Reload to refresh your session. You signed out in another tab or window. Reload to refresh your session. You switched accounts on another tab or window. Reload to refresh your session. Dismiss alert

[cisco](/cisco) / **[openh264](/cisco/openh264)** Public

-   [Notifications](/login?return_to=%2Fcisco%2Fopenh264) You must be signed in to change notification settings
-   [Fork 1.9k](/login?return_to=%2Fcisco%2Fopenh264)
-   [Star 6.1k](/login?return_to=%2Fcisco%2Fopenh264)
    

Open Source H.264 Codec

### License

[BSD-2-Clause license](/cisco/openh264/blob/master/LICENSE)

[6.1k stars](/cisco/openh264/stargazers) [1.9k forks](/cisco/openh264/forks) [Branches](/cisco/openh264/branches) [Tags](/cisco/openh264/tags) [Activity](/cisco/openh264/activity)

[Star](/login?return_to=%2Fcisco%2Fopenh264)

[Notifications](/login?return_to=%2Fcisco%2Fopenh264) You must be signed in to change notification settings

-   [Code](/cisco/openh264)
-   [Issues 258](/cisco/openh264/issues)
-   [Pull requests 29](/cisco/openh264/pulls)
-   [Actions](/cisco/openh264/actions)
-   [Projects 0](/cisco/openh264/projects)
-   [Wiki](/cisco/openh264/wiki)
-   [Security 1](/cisco/openh264/security)
-   [Insights](/cisco/openh264/pulse)

Additional navigation options

-   [Code](/cisco/openh264)
-   [Issues](/cisco/openh264/issues)
-   [Pull requests](/cisco/openh264/pulls)
-   [Actions](/cisco/openh264/actions)
-   [Projects](/cisco/openh264/projects)
-   [Wiki](/cisco/openh264/wiki)
-   [Security](/cisco/openh264/security)
-   [Insights](/cisco/openh264/pulse)

# cisco/openh264

  

 master

[Branches](/cisco/openh264/branches)[Tags](/cisco/openh264/tags)

[](/cisco/openh264/branches)[](/cisco/openh264/tags)

Go to file

Code

Open more actions menu

## Folders and files

Name

Name

Last commit message

Last commit date

## Latest commit

## History

[5,264 Commits](/cisco/openh264/commits/master/)

[](/cisco/openh264/commits/master/)5,264 Commits

[.github/workflows](/cisco/openh264/tree/master/.github/workflows "This path skips through empty directories")

[.github/workflows](/cisco/openh264/tree/master/.github/workflows "This path skips through empty directories")

[autotest](/cisco/openh264/tree/master/autotest "autotest")

[autotest](/cisco/openh264/tree/master/autotest "autotest")

[build](/cisco/openh264/tree/master/build "build")

[build](/cisco/openh264/tree/master/build "build")

[codec](/cisco/openh264/tree/master/codec "codec")

[codec](/cisco/openh264/tree/master/codec "codec")

[docs](/cisco/openh264/tree/master/docs "docs")

[docs](/cisco/openh264/tree/master/docs "docs")

[module](/cisco/openh264/tree/master/module "module")

[module](/cisco/openh264/tree/master/module "module")

[res](/cisco/openh264/tree/master/res "res")

[res](/cisco/openh264/tree/master/res "res")

[subprojects](/cisco/openh264/tree/master/subprojects "subprojects")

[subprojects](/cisco/openh264/tree/master/subprojects "subprojects")

[test](/cisco/openh264/tree/master/test "test")

[test](/cisco/openh264/tree/master/test "test")

[testbin](/cisco/openh264/tree/master/testbin "testbin")

[testbin](/cisco/openh264/tree/master/testbin "testbin")

[.gitignore](/cisco/openh264/blob/master/.gitignore ".gitignore")

[.gitignore](/cisco/openh264/blob/master/.gitignore ".gitignore")

[.reviewboardrc](/cisco/openh264/blob/master/.reviewboardrc ".reviewboardrc")

[.reviewboardrc](/cisco/openh264/blob/master/.reviewboardrc ".reviewboardrc")

[.travis.yml](/cisco/openh264/blob/master/.travis.yml ".travis.yml")

[.travis.yml](/cisco/openh264/blob/master/.travis.yml ".travis.yml")

[CODING\_STYLE](/cisco/openh264/blob/master/CODING_STYLE "CODING_STYLE")

[CODING\_STYLE](/cisco/openh264/blob/master/CODING_STYLE "CODING_STYLE")

[CONTRIBUTORS](/cisco/openh264/blob/master/CONTRIBUTORS "CONTRIBUTORS")

[CONTRIBUTORS](/cisco/openh264/blob/master/CONTRIBUTORS "CONTRIBUTORS")

[LICENSE](/cisco/openh264/blob/master/LICENSE "LICENSE")

[LICENSE](/cisco/openh264/blob/master/LICENSE "LICENSE")

[Makefile](/cisco/openh264/blob/master/Makefile "Makefile")

[Makefile](/cisco/openh264/blob/master/Makefile "Makefile")

[README.md](/cisco/openh264/blob/master/README.md "README.md")

[README.md](/cisco/openh264/blob/master/README.md "README.md")

[RELEASES](/cisco/openh264/blob/master/RELEASES "RELEASES")

[RELEASES](/cisco/openh264/blob/master/RELEASES "RELEASES")

[SECURITY.md](/cisco/openh264/blob/master/SECURITY.md "SECURITY.md")

[SECURITY.md](/cisco/openh264/blob/master/SECURITY.md "SECURITY.md")

[build.gradle](/cisco/openh264/blob/master/build.gradle "build.gradle")

[build.gradle](/cisco/openh264/blob/master/build.gradle "build.gradle")

[code-coverage.sh](/cisco/openh264/blob/master/code-coverage.sh "code-coverage.sh")

[code-coverage.sh](/cisco/openh264/blob/master/code-coverage.sh "code-coverage.sh")

[gmpopenh264.info](/cisco/openh264/blob/master/gmpopenh264.info "gmpopenh264.info")

[gmpopenh264.info](/cisco/openh264/blob/master/gmpopenh264.info "gmpopenh264.info")

[gradlew](/cisco/openh264/blob/master/gradlew "gradlew")

[gradlew](/cisco/openh264/blob/master/gradlew "gradlew")

[meson.build](/cisco/openh264/blob/master/meson.build "meson.build")

[meson.build](/cisco/openh264/blob/master/meson.build "meson.build")

[meson\_options.txt](/cisco/openh264/blob/master/meson_options.txt "meson_options.txt")

[meson\_options.txt](/cisco/openh264/blob/master/meson_options.txt "meson_options.txt")

[openh264.def](/cisco/openh264/blob/master/openh264.def "openh264.def")

[openh264.def](/cisco/openh264/blob/master/openh264.def "openh264.def")

[openh264.pc.in](/cisco/openh264/blob/master/openh264.pc.in "openh264.pc.in")

[openh264.pc.in](/cisco/openh264/blob/master/openh264.pc.in "openh264.pc.in")

[openh264.rc](/cisco/openh264/blob/master/openh264.rc "openh264.rc")

[openh264.rc](/cisco/openh264/blob/master/openh264.rc "openh264.rc")

[openh264.rc.template](/cisco/openh264/blob/master/openh264.rc.template "openh264.rc.template")

[openh264.rc.template](/cisco/openh264/blob/master/openh264.rc.template "openh264.rc.template")

[run\_Test.sh](/cisco/openh264/blob/master/run_Test.sh "run_Test.sh")

[run\_Test.sh](/cisco/openh264/blob/master/run_Test.sh "run_Test.sh")

[settings.gradle](/cisco/openh264/blob/master/settings.gradle "settings.gradle")

[settings.gradle](/cisco/openh264/blob/master/settings.gradle "settings.gradle")

[ut.def](/cisco/openh264/blob/master/ut.def "ut.def")

[ut.def](/cisco/openh264/blob/master/ut.def "ut.def")

View all files

## Repository files navigation

-   [README](#)
-   [BSD-2-Clause license](#)
-   [Security](#)

# OpenH264

[](#openh264)

OpenH264 is a codec library which supports H.264 encoding and decoding. It is suitable for use in real time applications such as WebRTC. See [http://www.openh264.org/](http://www.openh264.org/) for more details.

## Encoder Features

[](#encoder-features)

-   Constrained Baseline Profile up to Level 5.2 (Max frame size is 36864 macro-blocks)
-   Arbitrary resolution, not constrained to multiples of 16x16
-   Rate control with adaptive quantization, or constant quantization
-   Slice options: 1 slice per frame, N slices per frame, N macroblocks per slice, or N bytes per slice
-   Multiple threads automatically used for multiple slices
-   Temporal scalability up to 4 layers in a dyadic hierarchy
-   Simulcast AVC up to 4 resolutions from a single input
-   Spatial simulcast up to 4 resolutions from a single input
-   Long Term Reference (LTR) frames
-   Memory Management Control Operation (MMCO)
-   Reference picture list modification
-   Single reference frame for inter prediction
-   Multiple reference frames when using LTR and/or 3-4 temporal layers
-   Periodic and on-demand Instantaneous Decoder Refresh (IDR) frame insertion
-   Dynamic changes to bit rate, frame rate, and resolution
-   Annex B byte stream output
-   YUV 4:2:0 planar input

## Decoder Features

[](#decoder-features)

-   Constrained Baseline Profile up to Level 5.2 (Max frame size is 36864 macro-blocks)
-   Arbitrary resolution, not constrained to multiples of 16x16
-   Single thread for all slices
-   Long Term Reference (LTR) frames
-   Memory Management Control Operation (MMCO)
-   Reference picture list modification
-   Multiple reference frames when specified in Sequence Parameter Set (SPS)
-   Annex B byte stream input
-   YUV 4:2:0 planar output

## OS Support

[](#os-support)

-   Windows 64-bit and 32-bit
-   Mac OS X 64-bit and 32-bit
-   Mac OS X ARM64
-   Linux 64-bit and 32-bit
-   Android 64-bit and 32-bit
-   iOS 64-bit and 32-bit
-   Windows Phone 32-bit

## Architectures verified to be working

[](#architectures-verified-to-be-working)

-   ppc64el

## Processor Support

[](#processor-support)

-   Intel x86 optionally with MMX/SSE (no AVX yet, help is welcome)
-   ARMv7 optionally with NEON, AArch64 optionally with NEON
-   Any architecture using C/C++ fallback functions

## Building the Library

[](#building-the-library)

NASM needed to be installed for assembly code: workable version 2.10.06 or above, NASM can be downloaded from [http://www.nasm.us/](http://www.nasm.us/). For Mac OSX 64-bit NASM needed to be below version 2.11.08 as NASM 2.11.08 will introduce error when using RIP-relative addresses in Mac OSX 64-bit

To build the arm assembly for Windows Phone, gas-preprocessor is required. It can be downloaded from git://git.libav.org/gas-preprocessor.git

## For Android Builds

[](#for-android-builds)

To build for android platform, You need to install android sdk and ndk. You also need to export `**ANDROID_SDK**/tools` to PATH. On Linux, this can be done by

```
export PATH=**ANDROID_SDK**/tools:$PATH
```

The codec and demo can be built by

```
make OS=android NDKROOT=**ANDROID_NDK** TARGET=**ANDROID_TARGET**
```

Valid `**ANDROID_TARGET**` can be found in `**ANDROID_SDK**/platforms`, such as `android-12`. You can also set `ARCH`, `NDKLEVEL` according to your device and NDK version. `ARCH` specifies the architecture of android device. Currently `arm`, `arm64`, `x86` and `x86_64` are supported, the default is `arm`. (`mips` and `mips64` can also be used, but there's no specific optimization for those architectures.) `NDKLEVEL` specifies android api level, the default is 12. Available possibilities can be found in `**ANDROID_NDK**/platforms`, such as `android-21` (strip away the `android-` prefix).

By default these commands build for the `armeabi-v7a` ABI. To build for the other android ABIs, add `ARCH=arm64`, `ARCH=x86`, `ARCH=x86_64`, `ARCH=mips` or `ARCH=mips64`. To build for the older `armeabi` ABI (which has armv5te as baseline), add `APP_ABI=armeabi` (`ARCH=arm` is implicit). To build for 64-bit ABI, such as `arm64`, explicitly set `NDKLEVEL` to 21 or higher.

## For iOS Builds

[](#for-ios-builds)

You can build the libraries and demo applications using xcode project files located in `codec/build/iOS/dec` and `codec/build/iOS/enc`.

You can also build the libraries (but not the demo applications) using the make based build system from the command line. Build with

```
make OS=ios ARCH=**ARCH**
```

Valid values for `**ARCH**` are the normal iOS architecture names such as `armv7`, `armv7s`, `arm64`, and `i386` and `x86_64` for the simulator. Another settable iOS specific parameter is `SDK_MIN`, specifying the minimum deployment target for the built library. For other details on building using make on the command line, see 'For All Platforms' below.

## For Linux Builds

[](#for-linux-builds)

You can build the libraries (but not the demo applications) using the make based build system from the command line. Build with

```
make OS=linux ARCH=**ARCH**
```

You can set `ARCH` according to your linux device . `ARCH` specifies the architecture of the device. Currently `arm`, `arm64`, `x86` and `x86_64` are supported

NOTICE: If your computer is x86 architecture, for build the libnary which be used on arm/aarch64 machine, you may need to use cross-compiler, for example: make OS=linux CC=aarch64-linux-gnu-gcc CXX=aarch64-linux-gnu-g++ ARCH=arm64 or make OS=linux CC=arm-linux-gnueabi-gcc CXX=arm-linux-gnueabi-g++ ARCH=arm

## For Windows Builds

[](#for-windows-builds)

"make" must be installed. It is recommended to install the Cygwin and "make" must be selected to be included in the installation. After the installation, please add the Cygwin bin path to your PATH.

openh264/build/AutoBuildForWindows.bat is provided to help compile the libraries on Windows platform.  
Usage of the .bat script:

```
`AutoBuildForWindows.bat Win32-Release-ASM` for x86 Release build  
`AutoBuildForWindows.bat Win64-Release-ASM` for x86_64 Release build  
`AutoBuildForWindows.bat ARM64-Release-ASM` for arm64 release build  
```

for more usage, please refer to the .bat script help.

## For All Platforms

[](#for-all-platforms)

## Using make

[](#using-make)

From the main project directory:

-   `make` for automatically detecting architecture and building accordingly
-   `make ARCH=i386` for x86 32-bit builds
-   `make ARCH=x86_64` for x86 64-bit builds
-   `make ARCH=arm64` for arm64 Mac 64-bit builds
-   `make V=No` for a silent build (not showing the actual compiler commands)
-   `make DEBUGSYMBOLS=True` for two libraries, one is normal libraries, another one is removed the debugging symbol table entries (those created by the -g option)

The command line programs `h264enc` and `h264dec` will appear in the main project directory.

A shell script to run the command-line apps is in `testbin/CmdLineExample.sh`

Usage information can be found in `testbin/CmdLineReadMe`

## Using meson

[](#using-meson)

Meson build definitions have been added, and are known to work on Linux and Windows, for x86 and x86 64-bit.

See [http://mesonbuild.com/Installing.html](http://mesonbuild.com/Installing.html) for instructions on how to install meson, then:

meson setup builddir
ninja -C builddir

Run the tests with:

meson test -C builddir -v

Install with:

ninja -C builddir install

## Using the Source

[](#using-the-source)

-   `codec` - encoder, decoder, console (test app), build (makefile, vcproj)
-   `build` - scripts for Makefile build system
-   `test` - GTest unittest files
-   `testbin` - autobuild scripts, test app config files
-   `res` - yuv and bitstream test files

## Known Issues

[](#known-issues)

See the issue tracker on [https://github.com/cisco/openh264/issues](https://github.com/cisco/openh264/issues)

-   Encoder errors when resolution exceeds 3840x2160
-   Encoder errors when compressed frame size exceeds half uncompressed size
-   Decoder errors when compressed frame size exceeds 1MB
-   Encoder RC requires frame skipping to be enabled to hit the target bitrate, if frame skipping is disabled the target bitrate may be exceeded

## License

[](#license)

BSD, see `LICENSE` file for details.

## About

Open Source H.264 Codec

### Resources

[Readme](#readme-ov-file)

### License

[BSD-2-Clause license](#BSD-2-Clause-1-ov-file)

### Security policy

[Security policy](#security-ov-file)

### Uh oh!

There was an error while loading. Please reload this page.

[Activity](/cisco/openh264/activity)

[Custom properties](/cisco/openh264/custom-properties)

### Stars

[**6.1k** stars](/cisco/openh264/stargazers)

### Watchers

[**512** watching](/cisco/openh264/watchers)

### Forks

[**1.9k** forks](/cisco/openh264/forks)

[Report repository](/contact/report-content?content_url=https%3A%2F%2Fgithub.com%2Fcisco%2Fopenh264&report=cisco+%28user%29)

## [Releases 20](/cisco/openh264/releases)

[

Release Version 2.6.0 Latest

Feb 12, 2025



](/cisco/openh264/releases/tag/v2.6.0)

[\+ 19 releases](/cisco/openh264/releases)

## [Packages 0](/orgs/cisco/packages?repo_name=openh264)

No packages published  

### Uh oh!

There was an error while loading. Please reload this page.

## [Contributors 128](/cisco/openh264/graphs/contributors)

### Uh oh!

There was an error while loading. Please reload this page.

[\+ 114 contributors](/cisco/openh264/graphs/contributors)

## Languages

-   [C++ 59.9%](/cisco/openh264/search?l=c%2B%2B)
-   [Assembly 19.7%](/cisco/openh264/search?l=assembly)
-   [C 16.1%](/cisco/openh264/search?l=c)
-   [Shell 1.4%](/cisco/openh264/search?l=shell)
-   [Makefile 0.9%](/cisco/openh264/search?l=makefile)
-   [Objective-C 0.6%](/cisco/openh264/search?l=objective-c)
-   Other 1.4%

## Footer

[](https://github.com)© 2026 GitHub, Inc.

### Footer navigation

-   [Terms](https://docs.github.com/site-policy/github-terms/github-terms-of-service)
-   [Privacy](https://docs.github.com/site-policy/privacy-policies/github-privacy-statement)
-   [Security](https://github.com/security)
-   [Status](https://www.githubstatus.com/)
-   [Community](https://github.community/)
-   [Docs](https://docs.github.com/)
-   [Contact](https://support.github.com?tags=dotcom-footer)
-   Manage cookies
-   Do not share my personal information

You can’t perform that action at this time.
```
```

---

## Assistant (Plan · gpt-5.2 · 37.8s)

_Thinking:_



Here’s what I’d do next (read-only plan) to “continue” and align the spec with OpenH264 + clean up a couple remaining correctness issues.

**Plan**

- Update `hugo/content/docs/reference/media-spec/encoding.md` to explicitly target OpenH264 capabilities:
  - Make **Constrained Baseline** the required/primary profile (OpenH264 encoder supports Constrained Baseline; Main/High should not be “recommended” if we’re standardizing on OpenH264).
  - Keep **Level 3.1** as the practical target for 1080p here.
  - Add a **Rate Control** section:
    - Recommended default: **target bitrate (RC on) with adaptive quantization** + enforce a **max bitrate cap** (documented as “should cap peaks”, not strict ABR).
    - Optional mode: **constant quantization (constant QP)** for “quality-first” if bandwidth isn’t a concern.
  - Clarify what triggers a **new join fragment** (IDR): on-demand IDR, FPS change, max interval.
  - Clarify that **bitrate changes do not require** a new init segment; **resolution changes do require** a new init segment (so treat as new session or explicit re-init flow).

- Update `hugo/content/docs/reference/media-spec/container.md` to correct the `avc1` codec string explanation (it’s currently wrong/misleading):
  - `avc1.<profile_idc><constraints><level_idc>` (6 hex bytes total), e.g. `avc1.42E01F` (Constrained Baseline, Level 3.1).
  - Keep Main profile example only if we decide it’s allowed; otherwise demote to “non-OpenH264 encoders may emit …” or remove.

- Add a short “Encoder output vs fMP4 packaging” note (likely in `container.md` or `encoding.md`):
  - OpenH264 can output **Annex B**; MP4/fMP4 typically stores **length-prefixed NAL units** with SPS/PPS in `avcC` (so Sentinel’s muxer must convert if needed).

- Fix the small leftover terminology slip in `hugo/content/docs/reference/media-spec/segments.md`:
  - Table row says “Session Event | Segment Behavior” → should be “Fragment Behavior”.

- Run a consistency sweep after edits:
  - `rg -n "\\bsegments?\\b" hugo/content/docs/reference/media-spec -S` and verify remaining matches are only “initialization segment” or intentional prose.
  - Optionally run `hugo` build/serve to confirm nav ordering + links (Terminology weight, Fragments page link).

One question (blocks wording scope)
Do you want the spec to:
1) Require OpenH264 specifically (implementation requirement), or
2) Require an output contract (Constrained Baseline fMP4 + IDR behavior) and list OpenH264 as the reference/recommended encoder (my recommendation)?

What changes: (1) removes most “alternative encoder” language; (2) keeps the door open for NVENC/VideoToolbox/etc as long as output stays compliant.

---

## User

1) just mark that this spec is written for implementing it with openh264 and other h.264 libraries can be used but the spec is written specifically for this project that wants to stay mit licensed and uses openh264 because of this
2) yes as said in point 1

but before finalizing this answer, tell me a little bit how much the spec would change if it where to target only openh264

---

## Assistant (Plan · gpt-5.2 · 24.5s)

_Thinking:_



If we targeted ONLY OpenH264 (instead of “OpenH264-first, but other H.264 encoders allowed if they meet the same output contract”), the spec would tighten in a few concrete places, but it wouldn’t require a full rewrite.

What would change noticeably

- Encoding profile/level section (`encoding.md`)
  - Today it reads like general H.264 guidance (Baseline recommended, Main as alternative, mentions hardware encoders).
  - OpenH264-only would make **Constrained Baseline** effectively the only supported profile in-spec; “Main Profile” would be removed (or moved to “non-compliant / out of scope”).
  - Hardware-encoder rationale/examples (QSV/NVENC/VCE) would be removed or demoted, because those are explicitly “not the target implementation”.

- Rate control / bitrate language (`encoding.md`)
  - OpenH264-only would name the exact rate-control modes OpenH264 supports (RC with adaptive quantization vs constant quantization) as the normative modes, and describe expected behavior/limits in those terms.
  - A “generic encoder” spec can just say “target bitrate, cap peaks, allow scene-adaptive VBR”; OpenH264-only would define it in OpenH264’s vocabulary and constraints (including its known tendency to overshoot unless certain RC options are enabled).

- Join/keyframe behavior (`encoding.md`, `segments.md`, `control-messages.md`)
  - The current “on-demand IDR” requirement already matches OpenH264 well.
  - OpenH264-only would likely add small implementation-specific notes like: “on-demand IDR insertion is supported” and narrow any language that implies other encoder behaviors (like B-frame related latency considerations).

- Container/MSE codec string (`container.md`)
  - This needs fixing either way, but OpenH264-only would make it simpler: the example codec string would consistently be **Constrained Baseline** (e.g. `avc1.42E01F`) and you wouldn’t carry “Main profile” examples as first-class.

- Annex B vs MP4 packaging (`container.md` / `encoding.md`)
  - OpenH264 advertises Annex B output; MP4/fMP4 typically wants AVCC-style NAL formatting + `avcC` in the init segment.
  - OpenH264-only spec would likely add a short, explicit “muxer must convert Annex B to fMP4-compatible format” requirement (a generic spec might keep this as “encoder/muxer must produce valid fMP4” without naming Annex B).

- “Dynamic resolution changes” scope
  - OpenH264 supports dynamic resolution changes, but your spec currently implies “resolution and codec params do not change mid-session” (`container.md`).
  - If OpenH264-only, you’d have to choose: either forbid mid-session res changes (simpler) or define a re-init behavior (new init segment / new session semantics). In a generic spec, you can keep it abstract; OpenH264-only pushes you to be explicit.

Net: the biggest delta is removing “general H.264 ecosystem” alternatives (Main profile, hardware encoders, generic RC talk) and replacing them with OpenH264-specific constraints/terms. The transport/join/buffering/fragments parts barely change.

Given what you said you want (“spec written for this MIT-licensed project using OpenH264, but other H.264 libs may be used”), we should keep an output-contract spec, and add a short “Reference encoder: OpenH264 (BSD-2); project licensing stays MIT; encoder choice motivated by licensing” note near the top of `encoding.md`.

---

## User

ok, then target it fully at openh264 but add little notes where possible easily to tell you concisely the generic part for other encoders decoders.

---

## Assistant (Plan · gpt-5.2 · 3.9s)

---

## User

now make the docs

---

## Assistant (Build · gpt-5.2 · 26.5s)

_Thinking:_



```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/encoding.md\n@@\n This document specifies the video encoding requirements for Sentinel screen capture.\n+\n+This spec is written for an implementation that uses the OpenH264 library (BSD-2-Clause) so the overall project can remain MIT-licensed.\n+\n+Other H.264 encoders MAY be used, but they must produce output that matches the same on-the-wire/container requirements (fMP4 init segment + fragments, IDR join points, timestamps).\n@@\n ## Codec\n@@\n ### Why H.264\n \n - Universal hardware decoding support (Intel Quick Sync, NVIDIA NVENC, AMD VCE)\n - Native playback in all modern browsers via MSE\n-- Low CPU overhead when hardware encoding is available\n+- Low CPU overhead when hardware decoding is available\n - Widely supported on school/institutional hardware\n@@\n ## Profile and Level\n \n {{< callout type=\"info\" >}}\n-These are recommendations. Implementations may adjust based on hardware capabilities.\n+The encoder requirements here match OpenH264 capabilities. Other encoders MAY use higher profiles for better compression, but this project standardizes on Constrained Baseline for maximum compatibility.\n {{< /callout >}}\n \n-### Recommended: Baseline Profile\n+### Required: Constrained Baseline Profile\n \n | Setting | Value | Rationale |\n |---------|-------|-----------|\n-| Profile | Baseline | Maximum decoder compatibility, simpler encoding |\n+| Profile | Constrained Baseline | OpenH264-supported profile; maximum decoder compatibility |\n | Level | 3.1 | Supports 1080p at low framerates |\n@@\n **Tradeoffs:**\n - Baseline lacks B-frames, resulting in slightly larger files\n - Guaranteed to decode on all hardware, including older/weaker devices\n - Fastest encoding speed\n-\n-### Alternative: Main Profile\n-\n-| Setting | Value | Rationale |\n-|---------|-------|-----------|\n-| Profile | Main | Better compression via B-frames and CABAC |\n-| Level | 3.1 | Supports 1080p at low framerates |\n-\n-**Tradeoffs:**\n-- 10-20% smaller file sizes than Baseline\n-- Requires slightly more capable hardware for encoding\n-- Still universally supported for decoding in browsers\n+\n+{{< callout type=\"info\" >}}\n+If you use a different encoder, Main/High profiles MAY be acceptable for decoding in browsers, but they are out of scope for this project's default encoder choice.\n+{{< /callout >}}\n@@\n ## Resolution\n@@\n ## Framerate\n@@\n When FPS changes, a new join fragment must be produced (see [Fragments](../segments)).\n+\n+## Bitrate and Rate Control (OpenH264)\n+\n+OpenH264 supports either:\n+\n+- Rate control with adaptive quantization (target bitrate)\n+- Constant quantization (constant QP)\n+\n+### Recommended (default): Target Bitrate\n+\n+The Sentinel SHOULD configure OpenH264 to target a bitrate appropriate for the current FPS and resolution.\n+\n+If the encoder exposes peak control (VBV-style max bitrate / buffer), implementations SHOULD set it to limit short-term bitrate spikes.\n+\n+{{< callout type=\"info\" >}}\n+OpenH264 documents that its rate control may exceed the target bitrate unless frame skipping is enabled. If strict caps are required, enable the relevant RC options for your OpenH264 version.\n+{{< /callout >}}\n+\n+### Alternative: Constant Quantization (Quality-First)\n+\n+Constant-QP mode MAY be used when bitrate predictability is not important (e.g. LAN-only deployments), but it can produce large fragments during high-motion screen updates.\n@@\n ## Keyframes (I-Frames)\n@@\n ### Keyframe Rules\n@@\n | Rule | Description |\n |------|-------------|\n | On-demand | Sentinel must generate a keyframe when requested by Server |\n | Maximum interval | At least one keyframe every 20-30 seconds |\n | On FPS change | Next join fragment starts with a keyframe when framerate changes |\n@@\n ### IDR Frames\n@@\n All keyframes must be **IDR (Instantaneous Decoder Refresh)** frames, not just I-frames. IDR frames clear the decoder reference buffer, ensuring clean entry points for new viewers.\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/encoding.md
```
```

---

## Assistant (Build · gpt-5.2 · 7.2s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/container.md\n@@\n ## MIME Type\n@@\n The MIME type for MSE must specify both the container and codec:\n@@\n ```\n video/mp4; codecs=\"avc1.PPCCLL\"\n ```\n \n-Where `PPCCLL` is the H.264 profile/level indicator:\n-- `42` = Baseline profile\n-- `4D` = Main profile\n-- `E01F` = Level 3.1\n+Where the `avc1` codec string uses the AVCDecoderConfigurationRecord triplet:\n+\n+- `PP` = `AVCProfileIndication` (profile)\n+- `CC` = `profile_compatibility` (constraint flags)\n+- `LL` = `AVCLevelIndication` (level)\n+\n+For this project (OpenH264), the expected profile is Constrained Baseline.\n@@\n-Example for Baseline Profile, Level 3.1:\n+Example for Constrained Baseline Profile, Level 3.1:\n ```\n video/mp4; codecs=\"avc1.42E01F\"\n ```\n-\n-Example for Main Profile, Level 3.1:\n-```\n-video/mp4; codecs=\"avc1.4D401F\"\n-```\n+\n+{{< callout type=\"info\" >}}\n+Other encoders MAY produce different `avc1` values (e.g. Main/High), as long as Proctor playback targets environments that can decode them.\n+{{< /callout >}}\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/container.md
```
```

---

## Assistant (Build · gpt-5.2 · 2.6s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/segments.md\n@@\n | Session Event | Segment Behavior |\n |---------------|------------------|\n   | Session start | Sequence resets to 0, new initialization segment created |\n   | Session continues | Sequence increments with each fragment |\n   | Session ends | Final fragment may be shorter than normal |\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/segments.md
```
```

---

## Assistant (Build · gpt-5.2 · 2.5s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/segments.md\n@@\n-| Session Event | Segment Behavior |\n+| Session Event | Fragment Behavior |\n |---------------|------------------|\n   | Session start | Sequence resets to 0, new initialization segment created |\n   | Session continues | Sequence increments with each fragment |\n   | Session ends | Final fragment may be shorter than normal |\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/segments.md
```
```

---

## Assistant (Build · gpt-5.2 · 2.5s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/encoding.md\n@@\n ### Why H.264\n \n-- Universal hardware decoding support (Intel Quick Sync, NVIDIA NVENC, AMD VCE)\n+- Universal hardware decoding support\n - Native playback in all modern browsers via MSE\n - Low CPU overhead when hardware decoding is available\n - Widely supported on school/institutional hardware\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/encoding.md
```
```

---

## Assistant (Build · gpt-5.2 · 2.0s)

```
Tool: grep

**Input:**
```json
{
  "pattern": "\\bSegment Behavior\\b|NVENC|Quick Sync|VCE|Main Profile|High Profile|Baseline Profile",
  "path": "hugo/content/docs/reference/media-spec",
  "include": "*.md"
}
```
**Output:**
```
Found 2 matches
/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/encoding.md:
  Line 28: ### Required: Constrained Baseline Profile

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/container.md:
  Line 147: Example for Constrained Baseline Profile, Level 3.1:
```
```

---

## Assistant (Build · gpt-5.2 · 1.9s)

```
Tool: grep

**Input:**
```json
{
  "pattern": "\\bsegment(s)?\\b",
  "path": "hugo/content/docs/reference/media-spec",
  "include": "*.md"
}
```
**Output:**
```
Found 35 matches
/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/encoding.md:
  Line 9: Other H.264 encoders MAY be used, but they must produce output that matches the same on-the-wire/container requirements (fMP4 init segment + fragments, IDR join points, timestamps).
  Line 83: When FPS changes, a new join fragment must be produced (see [Fragments](../segments)).

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/segments.md:
  Line 87: The initialization segment uses a distinct name:
  Line 141:   | Session start | Sequence resets to 0, new initialization segment created |
  Line 146: If a Sentinel reconnects (new session), it generates a new initialization segment and restarts sequence numbering at 0. The Server treats this as a new stream.

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/container.md:
  Line 51: The initialization segment contains metadata required to configure the decoder. It does not contain any video frames.
  Line 89:  | Decodable with init | A fragment is decodable when appended after the initialization segment and appropriate preceding fragments |
  Line 99: The timescale from the initialization segment determines how timestamps map to wall-clock time. A common choice is 90000 (90kHz), allowing sub-millisecond precision.
  Line 110: Obtain the initialization segment for the target Sentinel from the Server.
  Line 114: Create a `MediaSource`, add a `SourceBuffer` with the appropriate MIME type, and append the initialization segment.

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/metadata.md:
  Line 56: | `initSegmentPath` | string | Path to initialization segment on disk |
  Line 122: | Proctor joins stream | Memory (init segment + buffered fragments) |
  Line 150: | Init segment bytes | No (stored as file on disk) |

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/_index.md:
  Line 35: {{< card link="segments" title="Fragments" icon="collection" subtitle="Fragment cadence and join fragments" >}}

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/transport.md:
  Line 60: Srv -> P : init segment
  Line 94: The initialization segment is sent separately, typically:
  Line 102: | `data` | bytes | Raw fMP4 initialization segment bytes |

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/disk-storage.md:
  Line 17: | Initialization segment | Yes | Raw fMP4 bytes |
  Line 63: | Initialization segment received | Write to `init.mp4` |
  Line 91: Each fragment file is a complete, valid fMP4 media fragment. Combined with the initialization segment, any fragment can be decoded independently when appended in order; a Proctor SHOULD start at a join fragment.
  Line 109: Provide initialization segment + media fragments to an fMP4-compatible player or MSE.
  Line 132: 1. Fetch the initialization segment

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/join-flow.md:
  Line 12: 2. Receive the initialization segment
  Line 38: Srv -> P : init segment
  Line 85: The Server sends the cached initialization segment for the Sentinel's current session.
  Line 93: | `data` | bytes | Raw fMP4 init segment |
  Line 151: Srv -> P : init segment
  Line 191: - Append the new initialization segment
  Line 203: | No join fragment in buffer | Send init segment, request/await next join fragment |

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/memory-buffer.md:
  Line 31: | **Initialization segment** | The codec/resolution configuration for the session |
  Line 75: 1. Server sends the initialization segment
  Line 95: The initialization segment for each active Sentinel is cached separately from the media fragment buffer.
  Line 103: Since the initialization segment is small (typically a few KB) and required for every new Proctor, it remains in memory for the duration of the Sentinel's session.

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/terminology.md:
  Line 15: | **Initialization segment** | fMP4 `ftyp` + `moov` bytes for the session. Contains codec config (SPS/PPS), resolution, timescale. Contains **no frames**. | Must be appended to MSE before any media data can be decoded.
  Line 39: It does **not** mean "start sending an empty 20s segment at t=0".
```
```

---

## Assistant (Build · gpt-5.2 · 2.8s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/encoding.md\n@@\n-Other H.264 encoders MAY be used, but they must produce output that matches the same on-the-wire/container requirements (fMP4 init segment + fragments, IDR join points, timestamps).\n+Other H.264 encoders MAY be used, but they must produce output that matches the same on-the-wire/container requirements (fMP4 initialization segment + fragments, IDR join points, timestamps).\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/encoding.md
```
```

---

## Assistant (Build · gpt-5.2 · 4.4s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/encoding.md\n@@\n ## Codec\n \n **H.264 (AVC)** is the required codec for all video streams.\n+\n+{{< callout type=\"info\" >}}\n+OpenH264 can output an Annex B byte stream. This project packages video into fMP4 for transport/playback, so the Sentinel's muxing layer MUST produce valid fMP4 initialization segments and fragments (not raw Annex B).\n+{{< /callout >}}\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/encoding.md
```
```

---

## Assistant (Build · gpt-5.2 · 1.9s)

```
Tool: grep

**Input:**
```json
{
  "pattern": "\\binit segment\\b",
  "path": "hugo/content/docs/reference/media-spec",
  "include": "*.md"
}
```
**Output:**
```
Found 6 matches
/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/metadata.md:
  Line 122: | Proctor joins stream | Memory (init segment + buffered fragments) |

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/transport.md:
  Line 60: Srv -> P : init segment

/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/join-flow.md:
  Line 38: Srv -> P : init segment
  Line 93: | `data` | bytes | Raw fMP4 init segment |
  Line 151: Srv -> P : init segment
  Line 203: | No join fragment in buffer | Send init segment, request/await next join fragment |
```
```

---

## Assistant (Build · gpt-5.2 · 3.3s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/transport.md\n@@\n- Srv -> P : init segment\n+ Srv -> P : initialization segment\n@@\n-### Initialization Segment\n+### Initialization Segment\n@@\n-| `sentinelId` | string | Identifies which Sentinel |\n-| `data` | bytes | Raw fMP4 initialization segment bytes |\n+| `sentinelId` | string | Identifies which Sentinel |\n+| `data` | bytes | Raw fMP4 initialization segment bytes |\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/transport.md
```
```

---

## Assistant (Build · gpt-5.2 · 3.0s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/join-flow.md\n@@\n-Srv -> P : init segment\n+Srv -> P : initialization segment\n@@\n-| `data` | bytes | Raw fMP4 init segment |\n+| `data` | bytes | Raw fMP4 initialization segment |\n@@\n-Srv -> P : init segment\n+Srv -> P : initialization segment\n@@\n-| No join fragment in buffer | Send init segment, request/await next join fragment |\n+| No join fragment in buffer | Send initialization segment, request/await next join fragment |\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/join-flow.md
```
```

---

## Assistant (Build · gpt-5.2 · 3.0s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/metadata.md\n@@\n-| Proctor joins stream | Memory (init segment + buffered fragments) |\n+| Proctor joins stream | Memory (initialization segment + buffered fragments) |\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/metadata.md
```
```

---

## Assistant (Build · gpt-5.2 · 1.8s)

```
Tool: grep

**Input:**
```json
{
  "pattern": "\\binit segment\\b",
  "path": "hugo/content/docs/reference/media-spec",
  "include": "*.md"
}
```
**Output:**
```
No files found
```
```

---

## Assistant (Build · gpt-5.2 · 1.8s)

```
Tool: bash

**Input:**
```json
{
  "command": "git diff --stat && git diff",
  "description": "Show diff summary and full patch"
}
```
**Output:**
```
 .../content/docs/reference/media-spec/container.md | 20 ++++----
 hugo/content/docs/reference/media-spec/encoding.md | 53 +++++++++++++++-------
 .../content/docs/reference/media-spec/join-flow.md |  8 ++--
 hugo/content/docs/reference/media-spec/metadata.md |  2 +-
 hugo/content/docs/reference/media-spec/segments.md |  8 ++--
 .../content/docs/reference/media-spec/transport.md |  2 +-
 6 files changed, 58 insertions(+), 35 deletions(-)
diff --git a/hugo/content/docs/reference/media-spec/container.md b/hugo/content/docs/reference/media-spec/container.md
index 5ff66dc..b8ef1db 100644
--- a/hugo/content/docs/reference/media-spec/container.md
+++ b/hugo/content/docs/reference/media-spec/container.md
@@ -136,17 +136,19 @@ The MIME type for MSE must specify both the container and codec:
 video/mp4; codecs="avc1.PPCCLL"
 ```
 
-Where `PPCCLL` is the H.264 profile/level indicator:
-- `42` = Baseline profile
-- `4D` = Main profile
-- `E01F` = Level 3.1
+Where the `avc1` codec string uses the AVCDecoderConfigurationRecord triplet:
 
-Example for Baseline Profile, Level 3.1:
+- `PP` = `AVCProfileIndication` (profile)
+- `CC` = `profile_compatibility` (constraint flags)
+- `LL` = `AVCLevelIndication` (level)
+
+For this project (OpenH264), the expected profile is Constrained Baseline.
+
+Example for Constrained Baseline Profile, Level 3.1:
 ```
 video/mp4; codecs="avc1.42E01F"
 ```
 
-Example for Main Profile, Level 3.1:
-```
-video/mp4; codecs="avc1.4D401F"
-```
+{{< callout type="info" >}}
+Other encoders MAY produce different `avc1` values (e.g. Main/High), as long as Proctor playback targets environments that can decode them.
+{{< /callout >}}
diff --git a/hugo/content/docs/reference/media-spec/encoding.md b/hugo/content/docs/reference/media-spec/encoding.md
index 0804972..36157ff 100644
--- a/hugo/content/docs/reference/media-spec/encoding.md
+++ b/hugo/content/docs/reference/media-spec/encoding.md
@@ -4,28 +4,36 @@ title: Encoding
 
 This document specifies the video encoding requirements for Sentinel screen capture.
 
+This spec is written for an implementation that uses the OpenH264 library (BSD-2-Clause) so the overall project can remain MIT-licensed.
+
+Other H.264 encoders MAY be used, but they must produce output that matches the same on-the-wire/container requirements (fMP4 initialization segment + fragments, IDR join points, timestamps).
+
 ## Codec
 
 **H.264 (AVC)** is the required codec for all video streams.
 
+{{< callout type="info" >}}
+OpenH264 can output an Annex B byte stream. This project packages video into fMP4 for transport/playback, so the Sentinel's muxing layer MUST produce valid fMP4 initialization segments and fragments (not raw Annex B).
+{{< /callout >}}
+
 ### Why H.264
 
-- Universal hardware decoding support (Intel Quick Sync, NVIDIA NVENC, AMD VCE)
+- Universal hardware decoding support
 - Native playback in all modern browsers via MSE
-- Low CPU overhead when hardware encoding is available
+- Low CPU overhead when hardware decoding is available
 - Widely supported on school/institutional hardware
 
 ## Profile and Level
 
 {{< callout type="info" >}}
-These are recommendations. Implementations may adjust based on hardware capabilities.
+The encoder requirements here match OpenH264 capabilities. Other encoders MAY use higher profiles for better compression, but this project standardizes on Constrained Baseline for maximum compatibility.
 {{< /callout >}}
 
-### Recommended: Baseline Profile
+### Required: Constrained Baseline Profile
 
 | Setting | Value | Rationale |
 |---------|-------|-----------|
-| Profile | Baseline | Maximum decoder compatibility, simpler encoding |
+| Profile | Constrained Baseline | OpenH264-supported profile; maximum decoder compatibility |
 | Level | 3.1 | Supports 1080p at low framerates |
 
 **Tradeoffs:**
@@ -33,17 +41,9 @@ These are recommendations. Implementations may adjust based on hardware capabili
 - Guaranteed to decode on all hardware, including older/weaker devices
 - Fastest encoding speed
 
-### Alternative: Main Profile
-
-| Setting | Value | Rationale |
-|---------|-------|-----------|
-| Profile | Main | Better compression via B-frames and CABAC |
-| Level | 3.1 | Supports 1080p at low framerates |
-
-**Tradeoffs:**
-- 10-20% smaller file sizes than Baseline
-- Requires slightly more capable hardware for encoding
-- Still universally supported for decoding in browsers
+{{< callout type="info" >}}
+If you use a different encoder, Main/High profiles MAY be acceptable for decoding in browsers, but they are out of scope for this project's default encoder choice.
+{{< /callout >}}
 
 ### Level Reference
 
@@ -86,6 +86,27 @@ The Server may request a framerate change from the Sentinel. Common reasons:
 
 When FPS changes, a new join fragment must be produced (see [Fragments](../segments)).
 
+## Bitrate and Rate Control (OpenH264)
+
+OpenH264 supports either:
+
+- Rate control with adaptive quantization (target bitrate)
+- Constant quantization (constant QP)
+
+### Recommended (default): Target Bitrate
+
+The Sentinel SHOULD configure OpenH264 to target a bitrate appropriate for the current FPS and resolution.
+
+If the encoder exposes peak control (VBV-style max bitrate / buffer), implementations SHOULD set it to limit short-term bitrate spikes.
+
+{{< callout type="info" >}}
+OpenH264 documents that its rate control may exceed the target bitrate unless frame skipping is enabled. If strict caps are required, enable the relevant RC options for your OpenH264 version.
+{{< /callout >}}
+
+### Alternative: Constant Quantization (Quality-First)
+
+Constant-QP mode MAY be used when bitrate predictability is not important (e.g. LAN-only deployments), but it can produce large fragments during high-motion screen updates.
+
 ## Keyframes (I-Frames)
 
 Keyframes are complete frames that can be decoded independently without reference to previous frames.
diff --git a/hugo/content/docs/reference/media-spec/join-flow.md b/hugo/content/docs/reference/media-spec/join-flow.md
index 31855a0..bdb9edc 100644
--- a/hugo/content/docs/reference/media-spec/join-flow.md
+++ b/hugo/content/docs/reference/media-spec/join-flow.md
@@ -35,7 +35,7 @@ Srv -> Srv : lookup Sentinel\nin memory buffer
 
 == Initial Data ==
 
-Srv -> P : init segment
+Srv -> P : initialization segment
 
 Srv -> P : join fragment\n(most recent in buffer)
 
@@ -90,7 +90,7 @@ The Server sends the cached initialization segment for the Sentinel's current se
 |-------|------|-------------|
 | `sentinelId` | string | Identifies the stream |
 | `sessionId` | string | Current session identifier |
-| `data` | bytes | Raw fMP4 init segment |
+| `data` | bytes | Raw fMP4 initialization segment |
 
 ### Server Sends Join Fragment
 
@@ -148,7 +148,7 @@ S -> Srv : new join fragment\n(starts with keyframe)
 
 P -> Srv : request join stream\n(sentinelId)
 
-Srv -> P : init segment
+Srv -> P : initialization segment
 Srv -> P : join fragment\n(the just-created one)
 
 == Live Streaming ==
@@ -200,7 +200,7 @@ In the browser, the Proctor must:
 | Sentinel not found | Error: unknown Sentinel |
 | Sentinel not streaming | Error: Sentinel offline |
 | Authorization failure | Error: not authorized |
-| No join fragment in buffer | Send init segment, request/await next join fragment |
+| No join fragment in buffer | Send initialization segment, request/await next join fragment |
 
 ## Latency Considerations
 
diff --git a/hugo/content/docs/reference/media-spec/metadata.md b/hugo/content/docs/reference/media-spec/metadata.md
index 532711f..ee91e3c 100644
--- a/hugo/content/docs/reference/media-spec/metadata.md
+++ b/hugo/content/docs/reference/media-spec/metadata.md
@@ -119,7 +119,7 @@ Server Memory
 
 | Operation | Data Source |
 |-----------|-------------|
-| Proctor joins stream | Memory (init segment + buffered fragments) |
+| Proctor joins stream | Memory (initialization segment + buffered fragments) |
 | New fragment arrives | Memory (add to buffer, update metadata) |
 | Proctor requests historical fragment | Disk (metadata points to file path) |
 
diff --git a/hugo/content/docs/reference/media-spec/segments.md b/hugo/content/docs/reference/media-spec/segments.md
index f1aa900..c92c626 100644
--- a/hugo/content/docs/reference/media-spec/segments.md
+++ b/hugo/content/docs/reference/media-spec/segments.md
@@ -136,11 +136,11 @@ This allows accurate playback timing regardless of FPS changes over time.
 
 A **session** is the period from when a Sentinel connects to when it disconnects.
 
-| Session Event | Segment Behavior |
+| Session Event | Fragment Behavior |
 |---------------|------------------|
- | Session start | Sequence resets to 0, new initialization segment created |
- | Session continues | Sequence increments with each fragment |
- | Session ends | Final fragment may be shorter than normal |
+  | Session start | Sequence resets to 0, new initialization segment created |
+  | Session continues | Sequence increments with each fragment |
+  | Session ends | Final fragment may be shorter than normal |
 
 {{< callout type="info" >}}
 If a Sentinel reconnects (new session), it generates a new initialization segment and restarts sequence numbering at 0. The Server treats this as a new stream.
diff --git a/hugo/content/docs/reference/media-spec/transport.md b/hugo/content/docs/reference/media-spec/transport.md
index 96c8547..4d9a7da 100644
--- a/hugo/content/docs/reference/media-spec/transport.md
+++ b/hugo/content/docs/reference/media-spec/transport.md
@@ -57,7 +57,7 @@ participant "Proctor" as P
 
 == Live Push ==
 
-Srv -> P : init segment
+ Srv -> P : initialization segment
 Srv -> P : fragment data
 note left: Fragment 140
 

```
```

---

## Assistant (Build · gpt-5.2 · 2.1s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/transport.md\n@@\n- Srv -> P : initialization segment\n+Srv -> P : initialization segment\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/transport.md
```
```

---

## Assistant (Build · gpt-5.2 · 3.2s)

```
Tool: apply_patch

**Input:**
```json
{
  "patchText": "*** Begin Patch\n*** Update File: hugo/content/docs/reference/media-spec/segments.md\n@@\n-| Session Event | Fragment Behavior |\n-|---------------|------------------|\n-  | Session start | Sequence resets to 0, new initialization segment created |\n-  | Session continues | Sequence increments with each fragment |\n-  | Session ends | Final fragment may be shorter than normal |\n+| Session Event | Fragment Behavior |\n+|---------------|------------------|\n+| Session start | Sequence resets to 0, new initialization segment created |\n+| Session continues | Sequence increments with each fragment |\n+| Session ends | Final fragment may be shorter than normal |\n*** End Patch"
}
```
**Output:**
```
Success. Updated the following files:
M hugo/content/docs/reference/media-spec/segments.md
```
```

---

## Assistant (Build · gpt-5.2 · 2.1s)

```
Tool: bash

**Input:**
```json
{
  "command": "git diff --stat",
  "description": "Show updated diff stats"
}
```
**Output:**
```
 .../content/docs/reference/media-spec/container.md | 20 ++++----
 hugo/content/docs/reference/media-spec/encoding.md | 53 +++++++++++++++-------
 .../content/docs/reference/media-spec/join-flow.md |  8 ++--
 hugo/content/docs/reference/media-spec/metadata.md |  2 +-
 hugo/content/docs/reference/media-spec/segments.md |  8 ++--
 .../content/docs/reference/media-spec/transport.md |  2 +-
 6 files changed, 58 insertions(+), 35 deletions(-)

```
```

---

## Assistant (Build · gpt-5.2 · 1.9s)

```
Tool: bash

**Input:**
```json
{
  "command": "hugo version",
  "description": "Check Hugo availability"
}
```
**Output:**
```
hugo v0.152.2+extended+withdeploy linux/amd64 BuildDate=unknown VendorInfo=nixpkgs

```
```

---

## Assistant (Build · gpt-5.2 · 2.2s)

```
Tool: bash

**Input:**
```json
{
  "command": "hugo --source hugo --minify",
  "timeout": 120000,
  "description": "Build Hugo site to verify docs"
}
```
**Output:**
```
Start building sites … 
hugo v0.152.2+extended+withdeploy linux/amd64 BuildDate=unknown VendorInfo=nixpkgs


                  │ EN 
──────────────────┼────
 Pages            │ 70 
 Paginator pages  │  0 
 Non-page files   │ 10 
 Static files     │ 22 
 Processed images │  0 
 Aliases          │  0 
 Cleaned          │  0 

Total in 162 ms

```
```

---

## Assistant (Build · gpt-5.2 · 1.9s)

```
Tool: bash

**Input:**
```json
{
  "command": "git status --porcelain=v1",
  "description": "Show working tree status"
}
```
**Output:**
```
M  hugo/content/docs/reference/media-spec/_index.md
MM hugo/content/docs/reference/media-spec/container.md
M  hugo/content/docs/reference/media-spec/control-messages.md
M  hugo/content/docs/reference/media-spec/disk-storage.md
MM hugo/content/docs/reference/media-spec/encoding.md
MM hugo/content/docs/reference/media-spec/join-flow.md
M  hugo/content/docs/reference/media-spec/memory-buffer.md
MM hugo/content/docs/reference/media-spec/metadata.md
MM hugo/content/docs/reference/media-spec/segments.md
A  hugo/content/docs/reference/media-spec/terminology.md
MM hugo/content/docs/reference/media-spec/transport.md

```
```

---

## Assistant (Build · gpt-5.2 · 6.4s)

Updated the media spec to be OpenH264-first, with concise notes for other H.264 implementations.

Changes made
- OpenH264 targeting + licensing rationale + “other encoders may be used if output matches spec” note in `hugo/content/docs/reference/media-spec/encoding.md`.
- Made profile requirement “Constrained Baseline” (OpenH264-capable); demoted Main/High to an informational out-of-scope note in `hugo/content/docs/reference/media-spec/encoding.md`.
- Added OpenH264 rate-control section (target bitrate vs constant QP) + note about RC overshoot/frame skipping in `hugo/content/docs/reference/media-spec/encoding.md`.
- Added Annex B vs fMP4 packaging callout in `hugo/content/docs/reference/media-spec/encoding.md`.
- Fixed `avc1` codec string explanation and aligned example to Constrained Baseline (`avc1.42E01F`) in `hugo/content/docs/reference/media-spec/container.md`, with a brief note about other encoders.
- Cleaned up terminology (“initialization segment” instead of “init segment”) in `hugo/content/docs/reference/media-spec/transport.md`, `hugo/content/docs/reference/media-spec/join-flow.md`, `hugo/content/docs/reference/media-spec/metadata.md`.
- Fixed table label “Fragment Behavior” in `hugo/content/docs/reference/media-spec/segments.md`.

Verification
- `hugo --source hugo --minify` succeeds.

If you want, next I can do a quick pass to add one short OpenH264 note in `hugo/content/docs/reference/media-spec/control-messages.md` where keyframe requests are defined (to explicitly map it to OpenH264 “on-demand IDR insertion”).

---

## User

now tell me how this mse in browsers would adapt to android/ios apps. do these also support some of this manual video stuf?

---

## Assistant (Plan · gpt-5.2 · 28.4s)

_Thinking:_



MSE is a browser API (Media Source Extensions): it gives you a `SourceBuffer` you can append fMP4 init + media fragments into. Native Android/iOS don’t expose an equivalent “append fMP4 fragments into a decoder” API in the same simple way, but you can get the same outcome via different stacks.

**Android**
- Closest “it just works” path: run the same web player in an Android WebView (Chromium) and keep using MSE.
- Native path: ExoPlayer can demux/play fragmented MP4 (CMAF-style) and will use `MediaCodec` for decode; you typically integrate by providing a custom `DataSource` (for bytes coming from WebSocket) or by switching transport to HTTP so ExoPlayer can pull normally.
- Fully manual path: parse fMP4 yourself (extract H.264 samples + timestamps) and feed `MediaCodec` (hardest; most control).

**iOS**
- MSE in Safari/WKWebView exists in newer iOS versions, but it’s historically been more constrained than desktop Chromium; if you want maximum predictability you shouldn’t assume “MSE everywhere” on iOS.
- AVFoundation (`AVPlayer`) is great at HLS/progressive MP4 over HTTP, but it’s not designed for “append arbitrary fMP4 fragments arriving over WebSocket”.
- Native manual path: demux fMP4 yourself, then decode with VideoToolbox and render (e.g. via `AVSampleBufferDisplayLayer` / custom pipeline). This is doable but is a significant implementation project.

**What this means for your spec/architecture**
1) If you want to keep the current “WebSocket + init segment + fragments + join fragments” design with minimal changes across platforms, the most uniform approach is “web player everywhere” (desktop browser + Android WebView + iOS WKWebView if your target iOS supports it well enough).
2) If you want first-class native apps, you’ll likely want to adjust delivery to something native players expect (HTTP-based CMAF/DASH/HLS-style fetching), or accept building a custom demux+decode pipeline (especially on iOS).

If you tell me your target minimum iOS version and whether you’re okay using WebView for playback, I can recommend the lowest-effort, highest-reliability path.

---

## User

so i often hear the word mux/demux. what is that actually

---

## Assistant (Plan · gpt-5.2 · 6.7s)

Mux/demux is just “packaging” vs “unpacking” media.

- Mux (multiplex): takes one or more elementary streams (e.g. H.264 video, AAC audio) + timing info and packages them into a container format (e.g. MP4 / fragmented MP4). Output is the bytes you store/ship: `init.mp4` + `.m4s` fragments in your spec.
- Demux (demultiplex): takes that container (MP4/fMP4) and extracts the streams back out: “here are the H.264 NAL units/samples and their timestamps”.

In your pipeline:
- Sentinel encodes H.264 frames -> muxes into fMP4 init segment + fMP4 fragments.
- Proctor player receives bytes -> demuxes fMP4 fragments -> feeds decoded H.264 samples to the decoder (browser does this internally when you append to MSE).

Concrete intuition:
- H.264 by itself is “raw video bitstream”.
- MP4/fMP4 is “a box/file format that carries that bitstream plus indexing/timestamps so a player can play it correctly.”

---

## User

write a quick summary which has been changed for the git commit message i will create

---

## Assistant (Plan · gpt-5.2 · 8.1s)

---

## User

i mean all changes since the last git commit

---

## Assistant (Plan · gpt-5.2 · 13.6s)

_Thinking:_



```
Tool: bash

**Input:**
```json
{
  "command": "git diff --name-status HEAD && git diff --stat HEAD",
  "description": "List all changes since HEAD"
}
```
**Output:**
```
M	hugo/content/docs/reference/media-spec/_index.md
M	hugo/content/docs/reference/media-spec/container.md
M	hugo/content/docs/reference/media-spec/control-messages.md
M	hugo/content/docs/reference/media-spec/disk-storage.md
M	hugo/content/docs/reference/media-spec/encoding.md
M	hugo/content/docs/reference/media-spec/join-flow.md
M	hugo/content/docs/reference/media-spec/memory-buffer.md
M	hugo/content/docs/reference/media-spec/metadata.md
M	hugo/content/docs/reference/media-spec/segments.md
A	hugo/content/docs/reference/media-spec/terminology.md
M	hugo/content/docs/reference/media-spec/transport.md
 hugo/content/docs/reference/media-spec/_index.md   |  21 +++--
 .../content/docs/reference/media-spec/container.md |  54 +++++------
 .../docs/reference/media-spec/control-messages.md  |  28 +++---
 .../docs/reference/media-spec/disk-storage.md      |  36 +++----
 hugo/content/docs/reference/media-spec/encoding.md |  62 ++++++++-----
 .../content/docs/reference/media-spec/join-flow.md |  66 +++++++------
 .../docs/reference/media-spec/memory-buffer.md     |  46 +++++----
 hugo/content/docs/reference/media-spec/metadata.md |  60 ++++++------
 hugo/content/docs/reference/media-spec/segments.md | 103 ++++++++++++---------
 .../docs/reference/media-spec/terminology.md       |  39 ++++++++
 .../content/docs/reference/media-spec/transport.md |  96 +++++++++----------
 11 files changed, 357 insertions(+), 254 deletions(-)

```
```

---

## Assistant (Plan · gpt-5.2 · 4.3s)

```
Tool: bash

**Input:**
```json
{
  "command": "git diff HEAD -- hugo/content/docs/reference/media-spec/_index.md hugo/content/docs/reference/media-spec/segments.md hugo/content/docs/reference/media-spec/transport.md hugo/content/docs/reference/media-spec/join-flow.md hugo/content/docs/reference/media-spec/memory-buffer.md hugo/content/docs/reference/media-spec/metadata.md hugo/content/docs/reference/media-spec/control-messages.md hugo/content/docs/reference/media-spec/disk-storage.md hugo/content/docs/reference/media-spec/container.md hugo/content/docs/reference/media-spec/encoding.md hugo/content/docs/reference/media-spec/terminology.md | sed -n '1,220p'",
  "timeout": 120000,
  "description": "Show start of full diff for summary"
}
```
**Output:**
```
diff --git a/hugo/content/docs/reference/media-spec/_index.md b/hugo/content/docs/reference/media-spec/_index.md
index 55cb221..ef3b7f8 100644
--- a/hugo/content/docs/reference/media-spec/_index.md
+++ b/hugo/content/docs/reference/media-spec/_index.md
@@ -11,29 +11,30 @@ This specification defines how video is encoded, segmented, stored, and delivere
 | **Codec** | H.264 |
 | **Container** | Fragmented MP4 (fMP4) |
 | **Browser Delivery** | Media Source Extensions (MSE) |
-| **Segment Duration** | Variable (new segment on each keyframe) |
+| **Fragment Duration** | Variable, short (implementation choice for real-time delivery) |
 | **Keyframes** | On-demand + max 20-30s interval + on FPS change |
-| **Memory Buffer** | All segments from last 15-20 seconds (configurable) |
-| **Disk Storage** | All segments written as-is |
+| **Memory Buffer** | All fragments from last 15-20 seconds (configurable) |
+| **Disk Storage** | All fragments written as-is |
 | **Resolution** | Max 1080p, downscaled preserving aspect ratio |
-| **Framerate** | 1/5 fps to 5 fps, variable per session, fixed per segment |
-| **Live Transport** | WebSocket (server pushes segments) |
+| **Framerate** | 1/5 fps to 5 fps, variable over time |
+| **Live Transport** | WebSocket (server pushes fragments) |
 | **Historical Transport** | HTTP (Proctor fetches from disk) |
 
 ## Components
 
-- **Sentinel**: Captures screen, encodes video, sends segments to Server
-- **Server**: Receives segments, buffers in memory, writes to disk, relays to Proctors
-- **Proctor**: Receives segments, decodes via MSE, displays video
+- **Sentinel**: Captures screen, encodes video, sends fragments to Server
+- **Server**: Receives fragments, buffers in memory, writes to disk, relays to Proctors
+- **Proctor**: Receives fragments, decodes via MSE, displays video
 
 ## Documentation
 
 {{< cards >}}
+{{< card link="terminology" title="Terminology" icon="book-open" subtitle="Definitions: fragments vs keyframes vs init" >}}
 {{< card link="encoding" title="Encoding" icon="chip" subtitle="H.264 codec settings and framerate" >}}
 {{< card link="container" title="Container" icon="archive" subtitle="fMP4 structure and initialization" >}}
-{{< card link="segments" title="Segments" icon="collection" subtitle="Segment creation and naming" >}}
+{{< card link="segments" title="Fragments" icon="collection" subtitle="Fragment cadence and join fragments" >}}
 {{< card link="memory-buffer" title="Memory Buffer" icon="server" subtitle="Server-side buffering for live streams" >}}
-{{< card link="disk-storage" title="Disk Storage" icon="database" subtitle="Persistent segment storage" >}}
+{{< card link="disk-storage" title="Disk Storage" icon="database" subtitle="Persistent fragment storage" >}}
 {{< card link="metadata" title="Metadata" icon="document-text" subtitle="In-stream and application metadata" >}}
 {{< card link="transport" title="Transport" icon="switch-horizontal" subtitle="WebSocket and HTTP delivery" >}}
 {{< card link="join-flow" title="Join Flow" icon="login" subtitle="How Proctors join a stream" >}}
diff --git a/hugo/content/docs/reference/media-spec/container.md b/hugo/content/docs/reference/media-spec/container.md
index 78cd1f4..b8ef1db 100644
--- a/hugo/content/docs/reference/media-spec/container.md
+++ b/hugo/content/docs/reference/media-spec/container.md
@@ -2,7 +2,7 @@
 title: Container
 ---
 
-This document specifies the container format for video segments.
+This document specifies the container format for video data.
 
 ## Format: Fragmented MP4 (fMP4)
 
@@ -12,7 +12,7 @@ All video data is packaged in **Fragmented MP4** format. This is a variant of th
 
 - Native support in browser Media Source Extensions (MSE)
 - No transcoding needed on Server or Proctor
-- Segments can be played independently (with initialization data)
+- Fragments can be appended incrementally (with initialization data)
 - Industry standard for adaptive streaming (DASH, HLS)
 
 ## Structure Overview
@@ -22,7 +22,7 @@ An fMP4 stream consists of two types of data:
 | Type | Purpose | When Sent |
 |------|---------|-----------|
 | **Initialization Segment** | Contains codec configuration, resolution, timescale | Once per session, on Proctor join |
-| **Media Segment** | Contains actual video frames and timing | Continuously during streaming |
+ | **Media Fragment** | Contains encoded samples (frames) and timing (`moof` + `mdat`) | Continuously during streaming |
 
 ```
 ┌─────────────────────────┐
@@ -32,13 +32,13 @@ An fMP4 stream consists of two types of data:
            │
            ▼
 ┌─────────────────────────┐
-│    Media Segment 1      │  ← Starts with keyframe
+│    Media Fragment 1     │  ← May start with keyframe
 │  (moof + mdat boxes)    │
 └─────────────────────────┘
-           │
-           ▼
+            │
+            ▼
 ┌─────────────────────────┐
-│    Media Segment 2      │  ← Starts with keyframe
+│    Media Fragment 2     │  ← May start with keyframe
 │  (moof + mdat boxes)    │
 └─────────────────────────┘
            │
@@ -71,9 +71,9 @@ The initialization segment contains metadata required to configure the decoder.
 - Server caches in memory for each active Sentinel
 - Sent to Proctor on stream join request
 
-## Media Segments
+## Media Fragments
 
-Each media segment contains one or more video frames packaged for streaming.
+Each media fragment contains one or more encoded samples (video frames) packaged for streaming.
 
 ### Contents
 
@@ -84,12 +84,12 @@ Each media segment contains one or more video frames packaged for streaming.
 
 ### Requirements
 
-| Requirement | Description |
-|-------------|-------------|
-| Starts with keyframe | Every media segment must begin with an IDR frame |
-| Self-contained timing | Timestamps in `moof` are absolute (not relative to previous segment) |
-| Variable duration | Segments can have different durations |
-| Fixed framerate per segment | Framerate is constant within a segment |
+ | Requirement | Description |
+ |-------------|-------------|
+ | Decodable with init | A fragment is decodable when appended after the initialization segment and appropriate preceding fragments |
+ | Join points | A **join fragment** begins with an IDR frame and is a safe entry point for new viewers |
+ | Self-contained timing | Timestamps in `moof` are absolute (not relative to previous fragment) |
+ | Variable duration | Fragments can have different durations |
 
 ### Timing Information
 
@@ -118,9 +118,9 @@ Create a `MediaSource`, add a `SourceBuffer` with the appropriate MIME type, and
 "video/mp4; codecs=\"avc1.42E01F\""
 ```
 
-### Append Media Segments
+### Append Media Fragments
 
-As media segments arrive, append them to the `SourceBuffer` in order.
+As media fragments arrive, append them to the `SourceBuffer` in order.
 
 ### Handle Playback
 
@@ -136,17 +136,19 @@ The MIME type for MSE must specify both the container and codec:
 video/mp4; codecs="avc1.PPCCLL"
 ```
 
-Where `PPCCLL` is the H.264 profile/level indicator:
-- `42` = Baseline profile
-- `4D` = Main profile
-- `E01F` = Level 3.1
+Where the `avc1` codec string uses the AVCDecoderConfigurationRecord triplet:
+
+- `PP` = `AVCProfileIndication` (profile)
+- `CC` = `profile_compatibility` (constraint flags)
+- `LL` = `AVCLevelIndication` (level)
+
+For this project (OpenH264), the expected profile is Constrained Baseline.
 
-Example for Baseline Profile, Level 3.1:
+Example for Constrained Baseline Profile, Level 3.1:
 ```
 video/mp4; codecs="avc1.42E01F"
 ```
 
-Example for Main Profile, Level 3.1:
-```
-video/mp4; codecs="avc1.4D401F"
-```
+{{< callout type="info" >}}
+Other encoders MAY produce different `avc1` values (e.g. Main/High), as long as Proctor playback targets environments that can decode them.
+{{< /callout >}}
diff --git a/hugo/content/docs/reference/media-spec/control-messages.md b/hugo/content/docs/reference/media-spec/control-messages.md
index 00f239c..0dc215f 100644
--- a/hugo/content/docs/reference/media-spec/control-messages.md
+++ b/hugo/content/docs/reference/media-spec/control-messages.md
@@ -39,10 +39,10 @@ activate S
 
 S -> S : mark next frame\nas keyframe
 
-S -> Srv : segment\n(starts with keyframe)
+ S -> Srv : join fragment\n(starts with keyframe)
 deactivate S
 
-Srv -> P : segment available
+Srv -> P : join fragment available
 deactivate Srv
 
 @enduml
@@ -82,8 +82,8 @@ Example:
 When the Sentinel receives a keyframe request:
 
 1. The next captured frame becomes an IDR frame (keyframe)
-2. A new segment begins with this keyframe
-3. The segment is sent to the Server as usual
+2. A new join fragment begins with this keyframe
+3. The join fragment is sent to the Server as usual
 
 {{< callout type="info" >}}
 The keyframe is generated on the **next capture**, not immediately. The delay depends on the current framerate. At 5 FPS, maximum delay is 200ms. At 1/5 FPS, maximum delay is 5 seconds.
@@ -91,7 +91,7 @@ The keyframe is generated on the **next capture**, not immediately. The delay de
 
 ### Response
 
-No explicit response message is defined. The Proctor knows the keyframe request was fulfilled when a new segment arrives (which will start with a keyframe).
+No explicit response message is defined. The Proctor knows the keyframe request was fulfilled when a new join fragment arrives.
 
 ## FPS Change Request
 
@@ -111,13 +111,13 @@ participant "Sentinel" as S
 Srv -> S : fps change request\n(newFps: 2)
 activate S
 
-S -> S : finish current segment
+ S -> S : finish current fragment
 
 S -> S : apply new framerate
 
-S -> Srv : segment\n(at old fps)
+ S -> Srv : fragment\n(at old fps)
 
-S -> Srv : segment\n(at new fps, starts with keyframe)
+ S -> Srv : join fragment\n(at new fps, starts with keyframe)
 deactivate S
 
 @enduml

```
```

---

## Assistant (Plan · gpt-5.2 · 15.0s)

_Thinking:_



Here’s a commit-message-ready summary of *all changes since the last commit* (docs only):

Proposed commit title
- `docs(media-spec): clarify fMP4 fragments/join points; align encoding with OpenH264`

Proposed commit body
- Replace ambiguous “segments” language with precise fMP4 terms: initialization segment, (media) fragments, and IDR-based join fragments to avoid implying 20–30s delivery latency.
- Add `hugo/content/docs/reference/media-spec/terminology.md` and update `hugo/content/docs/reference/media-spec/_index.md` to lead with definitions and link labels (“Fragments”).
- Update `hugo/content/docs/reference/media-spec/segments.md` to define fragment cadence, join-fragment triggers (on-demand IDR, FPS change, max interval), naming/sequence rules, and session behavior.
- Update join + transport flows to send initialization segment separately and start playback at a join fragment (`hugo/content/docs/reference/media-spec/join-flow.md`, `hugo/content/docs/reference/media-spec/transport.md`).
- Update control-message semantics so keyframe requests yield a join fragment; clarify FPS-change behavior (`hugo/content/docs/reference/media-spec/control-messages.md`).
- Update buffering/storage/metadata docs to consistently model “buffered fragments + cached initialization segment” (`hugo/content/docs/reference/media-spec/memory-buffer.md`, `hugo/content/docs/reference/media-spec/disk-storage.md`, `hugo/content/docs/reference/media-spec/metadata.md`).
- Align encoding requirements with OpenH264: Constrained Baseline, add OpenH264 rate-control notes (target bitrate vs constant QP), and note Annex B vs fMP4 packaging (`hugo/content/docs/reference/media-spec/encoding.md`).
- Fix/clarify MSE codec-string explanation (`avc1.PPCCLL`) and standardize example on Constrained Baseline (`avc1.42E01F`) (`hugo/content/docs/reference/media-spec/container.md`).

---

