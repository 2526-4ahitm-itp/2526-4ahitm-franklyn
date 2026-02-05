# Screen capture storage and transfer questions

**Session ID:** ses_3d145c73dffeseO6bWDF2TefrL
**Created:** 2/5/2026, 5:54:42 PM
**Updated:** 2/5/2026, 7:42:54 PM

---

## User

write a spec for the following.

3 parts of a software exist.

the client, which installed on a computer and captures the screen in a specified interval.

the webview can observe the screen of the selected client in realtime.
there is no audio.

the server is the "connector" and stores all data. the server shall not need to process video or images and only stores and retreives data in the specified format, format being http, websocket, whatever. the video data stays the same as soon as it is on the server.

NOW DO NOT WRITE THE SPEC BUT ASK ME QUESTIONS. DO NOT MAKE ASSUMPTIONS ABOUT THE ARCHITECTURE.

the goal is a spec for how the video should be stored, sent, provided and how much of it at once to keep a real time, low storage application.

the maximum framerate would be 5 fps, minimum would be 1/5 fps.
No ask the questions.

---

## Assistant (Plan · claude-opus-4.5 · 13.0s)

I'll ask questions to understand the architecture and requirements better before writing the spec.

## Client Questions

1. **Screen capture scope**: Does the client capture the entire screen, a specific window, or a specific monitor (in multi-monitor setups)?

2. **Image format**: What format should the captured frames be in? (e.g., JPEG, PNG, WebP) And should compression quality be configurable?

3. **Resolution**: Should frames be captured at native resolution, or downscaled? Is there a maximum resolution you want to support?

4. **Framerate determination**: What determines whether the client uses 5 fps vs 1/5 fps (one frame every 5 seconds)?
   - User configuration?
   - Bandwidth/network conditions?
   - Screen activity detection?

5. **Offline handling**: What happens if the client loses connection to the server? Should it buffer frames locally?

## Server Questions

6. **Storage duration**: How long should frames be retained on the server? Or is this purely a relay with no persistent storage?

7. **Multiple clients**: Can multiple clients be connected simultaneously? If so, how are they identified?

8. **Multiple viewers**: Can multiple webviews observe the same client simultaneously?

9. **Authentication/Authorization**: Do you need any auth mechanism, or is this for a trusted internal network?

## Webview Questions

10. **Latency tolerance**: What's the acceptable delay between capture and display? (e.g., <1 second, <5 seconds)

11. **Historical playback**: Does the webview only show live/realtime frames, or should it be able to "rewind" and view past frames?

12. **Connection behavior**: When a webview connects, should it:
    - Wait for the next frame?
    - Immediately receive the most recent frame?
    - Receive some backlog of recent frames?

## Protocol Questions

13. **Push vs Pull**: Should frames be pushed to viewers as they arrive, or should viewers poll for new frames?

14. **Network constraints**: Any bandwidth limits to design around? Is this for LAN, WAN, or both?

15. **Frame ordering**: Must frames be delivered in strict chronological order, or is it acceptable to drop frames if viewers fall behind?

---

## User

it seems like you are already thinking about building the software. you are way too far. i am only talking about the form of the video/stream etc.
rethink and ask questions.

---

## Assistant (Plan · claude-opus-4.5 · 8.8s)

You're right, I was overcomplicating this. Let me focus purely on the video/frame data format and delivery.

## Frame Format Questions

1. **Image format**: What format should each frame be encoded as? (JPEG, PNG, WebP, raw pixels?)

2. **Compression**: Should frames be individually compressed, or do you want any inter-frame compression (like video codecs do with keyframes and delta frames)?

3. **Resolution**: Is there a target resolution, or does it vary per client/use case?

## Delivery Questions

4. **Frame-by-frame or chunked**: Should frames be sent individually as they're captured, or batched together (e.g., send 5 frames at once every second)?

5. **Buffering on server**: Should the server hold onto any frames for viewers who connect late, or only relay the current/latest frame?

6. **Dropped frames**: If a viewer can't keep up, should old frames be dropped, or queued?

## Metadata Questions

7. **Timestamps**: Do frames need timestamps? If so, client-side capture time, server receive time, or both?

8. **Sequence numbers**: Do frames need sequence identifiers to detect gaps or ordering?

---

## User

Frame Format Questions:
1. I was thinking about using streams because images are too high storage and seems unreal
2. yes, video codecs where the content is a stream rather than individual frames
3. will be max fullhd and will be downscaled if need be to contain fullhd with preserved aspect ratio

Delivery:
4. Whatever is better for realtime applications, the bandwidth and amount of messages shouldn't be a problem as server and client are in the same lan. so rather be able to send single frames.
5. The server should be buffering the latest 2-3 points at which you can join on the webview to the stream and writes everything just to disk. but scrobbing support should be also there which would then require disk reads. but the realtime part should be memory only. disk is for preservation.
6. A viewer should always get the latest stuff. if it buffers then it should jump to the latest part and continue where you left off. but if there is bad internet and the webview needs a larger buffer, the video codec should support that the buffer is larger and is a little behind.
7. timestamps would be best per frame so there are no random speed ups or so and every player can play it with the realtime speed.
8. maybe, we want currently don't know about dropped frames and how we want to handle them. one solution i would think of is to reuse the previous frame for dropped frames and detect dropped frames by the sequence or to have a complete additional workflow where the client buffers the whole video and can provide the server with any dropped frames. i am not understanding how the server would then insert the frame if it should not have to process video (but ordering based on metadata would be fine hust no changing or recoding the video)

i am ready for your next questions

---

## Assistant (Plan · claude-opus-4.5 · 0.0s)

---

## User

ready for your next questions.

---

## Assistant (Plan · claude-opus-4.5 · 14.1s)

Good, this clarifies a lot. Now I'm understanding the shape better. Follow-up questions:

## Video Codec / Stream Format

1. **Codec choice**: Are you considering a specific codec (H.264, VP8, VP9, AV1) or should the spec recommend one? Each has different tradeoffs for low-framerate, low-latency use cases.

2. **Keyframe interval**: Given your 1/5 fps to 5 fps range, how often should keyframes (I-frames) occur? This affects:
   - How quickly a viewer can "join" the stream
   - File size
   - The "2-3 join points" you mentioned — are these meant to be keyframes?

3. **Container format**: For the disk storage, do you have a preference? (e.g., MP4, WebM, fragmented MP4, raw stream chunks)

## Segmentation / Chunking

4. **Segment duration**: Should the stream be written to disk in segments (e.g., 10-second or 30-second chunks)? This would make scrubbing and the "join points" easier to implement without video processing.

5. **Join points = segment boundaries?**: When you say "2-3 points at which you can join," do you mean the server keeps 2-3 recent segments in memory, each starting with a keyframe?

## Dropped Frames / Recovery

6. **Client-side buffering for recovery**: If the client buffers locally and can provide dropped frames later, should these be stored separately (as a "patch" file) rather than inserted into the main stream? This way the server never re-encodes, it just stores an additional recovery file.

7. **Playback of recovered frames**: Should the webview be responsible for merging the main stream + recovery data during playback, or is that out of scope?

## Variable Framerate

8. **VFR handling**: With framerates between 1/5 fps and 5 fps, is the framerate constant per session, or can it change mid-stream? If variable, the timestamp-per-frame approach you mentioned becomes critical.

---

## User

1.

The codec should be supported on a little weak hardware and should also play fine in all modern browsers. it should support that the server requests an fps change mid session but also may request a new entry point to the stream when a webview wants to join in as the webview will be switching streams frequently so fast switching should be supported. This can be possibly improved by fetching likely new sessions early so the effect would be that the switch is instant. by this i mean: The webview predicts the next session (not your conern) and requests a new entrypoint so it can start the stream immeditelly and doesn't have to wait for another entrypoint that may happend later on automatically.

2.
I want on demand keyframes and maybe every 20-30 seconds but the best solution would be as few as possible. this would go against the scrubbing point i made so forget scrubbing for now.
The 2-3 join points i mentioned are exaclty meant to be keyframes. but i'll change 2-3 to maybe all in the latest 15-20 seconds (could be configurable) so webviews with a bad internet can buffer more time and still watch rather new video.

3.
because the server does no processing at all, the stream is stored as is and should be already in a format where a webview can be served the content and already display it without having to do heavy in browser transcoding.

4. yes, store in chunks because although i scrapped the scrubbing i may consider it later. the segment duration would be equvalent to the keyframe frequency wouldn't it or am i missing something.

5. i would rather (as i already mentioned in an answer above in this message) keep all segments in the last 10 - 15 seconds for webviews with bad internet where each segment starts with a keyframe.

6. yes, the "server never encodes/decodes/transcodes" choice. but only consider this "patching" optional and if it present the slightest difficulty, scrap it.

7. the patch frames would be for watching the video later and are not part of realtime applications.

8. yes, the fps change mid session, for example if the server is under heavy load, it demands lower fps frames which would be less messages per client. that is why i want timestamps to not have some weird relative timing shit but have every frame exactly where it was in time on the screen.

i also forgot to mention, that the video should be available for viewing later, this could be provided by transcoding in the webview, providing an extra transcoding client (which is completely different from the streaming client) which would download all stream segments and all patches or parts and reconnects them, the server should not be processing stuff.

---

## Assistant (Plan · claude-opus-4.5 · 13.6s)

This is getting clearer. A few more questions before I can write the spec:

## Codec / Browser Compatibility

1. **H.264 vs VP8/VP9**: H.264 has the widest hardware decoder support (including weak devices) and universal browser support, but has licensing concerns. VP8/VP9 is royalty-free and well-supported in browsers but hardware decoding is less universal on older/weaker devices. Do you have a preference, or should the spec recommend one based on your constraints?

## On-Demand Keyframes

2. **Keyframe request flow**: When a webview wants to join, who requests the keyframe?
   - Webview → Server → Client (server relays the request)
   - Server decides autonomously when a new viewer joins
   - Something else?

3. **Keyframe latency**: When a keyframe is requested, is it acceptable to wait until the next captured frame to make it a keyframe, or should the client immediately capture and send one?

## Segments and Storage

4. **Segment boundaries**: If keyframes happen on-demand (not at fixed intervals), segments won't have uniform duration. Is that acceptable, or do you want fixed-duration segments with keyframes forced at segment boundaries?

5. **Segment format for disk**: You mentioned the stream should be servable directly to the browser. Does this mean each segment file should be a standalone playable unit (e.g., a small MP4/WebM file), or is a raw byte stream acceptable as long as the browser can decode it when concatenated?

## FPS Change Mid-Session

6. **FPS change mechanism**: When the server requests an FPS change, should this also trigger a keyframe (so the new framerate segment is cleanly separable), or can framerate change mid-segment?

## Later Viewing / Transcoding Client

7. **Transcoding client output**: When the separate transcoding client reassembles segments + patches into a final video, what format should it produce? A single MP4/WebM file?

---

## User

1. This would require more research. but in general our project is planned to be licensed under the MIT License but copyleft license would also be fine if the improvement is a great one.
The client would run on school computers of austrian HTLs where premiere pro, after effects, photoshop, cinema4d and other programs run fine. Give me a more detailed cons, pros and details about the difference of the codes.

2. the keyframe request in initiated by the webview where the server would "relay" it. "relay" in quotes because it still handles validation, has internal structure and the request in never passed one to one. for the client, the webview doesn't exist, it only does what the server does. But this is again a little to application specific because the codec doesn't care about who requested the frame. I at least want keyframes on demand.

3. it is acceptable to wait for the next frame.

4. not uniform segments are acceptable.

5. As long as any modern browser can show what is being served from the browser in short time without heavy processing like common straming platforms do, any format is acceptable

6. yes, fps change triggers a new keyframe and segment. so a single segment has a fixed framerate but multiple segments can have different frame rates.

7. the transcoding client/app should produce at best a single outputfile. but optimally the webview already handles that if system native transcoding at this level is possible.

---

## Assistant (Plan · claude-opus-4.5 · 21.7s)

## Codec Comparison: H.264 vs VP8 vs VP9

| Aspect | H.264 (AVC) | VP8 | VP9 |
|--------|-------------|-----|-----|
| **Browser Support** | Universal (all browsers) | All modern browsers | All modern browsers |
| **Hardware Decoding** | Excellent — virtually all GPUs since ~2010 | Limited — mostly software decode on older hardware | Good on newer hardware (2015+), spotty on older |
| **Hardware Encoding** | Excellent — Intel Quick Sync, NVIDIA NVENC, AMD VCE | Rare | Available on newer Intel/NVIDIA |
| **Licensing** | Patented, but freely licensed for web streaming via Cisco's OpenH264 | Royalty-free (BSD) | Royalty-free (BSD) |
| **Low-framerate efficiency** | Good | Acceptable | Better than H.264 at low bitrates |
| **Keyframe-on-demand** | Yes (IDR frames) | Yes | Yes |
| **Container for web** | MP4 (fMP4 for streaming) | WebM | WebM |
| **Latency / fast start** | Excellent with fragmented MP4 | Good | Good |
| **Weak hardware encoding** | Best option — hardware acceleration widely available | Likely software-only = CPU load | Likely software-only = CPU load |

### My Assessment

Given your constraints:
- School computers that run Premiere/After Effects (so decent hardware, likely Intel iGPU or discrete GPU)
- Must play in all modern browsers without heavy processing
- Client should not be CPU-heavy during capture

**H.264 is the safer choice** because:
1. Hardware encoding is nearly guaranteed on school machines (Intel Quick Sync alone covers most)
2. Universal browser playback with no issues
3. Fragmented MP4 (fMP4) allows segment-based streaming that browsers handle natively via Media Source Extensions (MSE)
4. The Cisco OpenH264 license makes it royalty-free for this use case

**VP9 would be viable** if you want royalty-free without any licensing nuance, but you risk software-only encoding on some machines, which increases CPU load during capture.

---

## Remaining Questions

### Stream Delivery to Browser

1. **Media Source Extensions (MSE)**: For the webview to play segments as they arrive (and switch streams, buffer, seek to latest), the browser would use MSE. This means the server serves raw fMP4/WebM segments and the webview JavaScript assembles them into a playable stream. Is this acceptable, or do you want something simpler like an HLS/DASH manifest?

2. **HLS / DASH**: These are standard adaptive streaming protocols that wrap fMP4/WebM segments with a manifest file. The server would need to generate/update a simple text manifest (no video processing), but it adds complexity. The benefit is simpler playback code. Worth it or overkill?

### Segment Metadata

3. **Segment metadata**: Each segment needs to carry or be associated with:
   - Start timestamp
   - Duration (or frame count + timestamps)
   - Framerate for that segment
   - Client identifier
   
   Should this be embedded in the container, in a sidecar file per segment, or in a separate metadata stream/index?

### Patches (Optional Feature)

4. **Patch granularity**: If implemented, would patches be individual frames (as separate tiny segments or images) or re-encoded mini-segments? Just want to confirm this is "per-frame" recovery.

---

## User

ok, lets go with h.264 and i'll do the licensing stuff myself later.

1. elaborate as this is rather new to me. simple would be best but if the performance gain and controll is there i would consider picking the more difficult one which has more control.
2. this processing is acceptable for the server but this is the same like point 1., i need more information about the complexity and control trade off.
3. elaborate again and inform me about the technicalities about this because i am not informed about "container", "sidecar file" and i also don't know what i then have to handle in code and what is handled for me.
4. lets not talk about patches for now but discuss that after the discussion about points 1, 2 and 3

---

## Assistant (Plan · claude-opus-4.5 · 40.1s)

## Elaboration: MSE vs HLS/DASH vs Simple Streaming

### Option A: Media Source Extensions (MSE) — Direct Segment Feeding

**What it is:**
MSE is a browser JavaScript API that lets you manually feed raw video segments into a `<video>` element. You fetch segment files yourself and append them to a buffer.

**How it works:**
1. Client encodes H.264 frames into fMP4 (fragmented MP4) segments
2. Server stores/relays these raw segment files
3. Webview JavaScript fetches segments via HTTP or WebSocket
4. JavaScript calls `sourceBuffer.appendBuffer(segmentData)` to feed the video element

**Pros:**
- Maximum control — you decide exactly when to fetch, which segment, when to switch streams
- No manifest overhead
- Can implement custom logic: "jump to latest keyframe," "switch client instantly," "drop old buffer"
- Lower latency potential since you control timing

**Cons:**
- You write more JavaScript — fetching, buffering, error handling, gap management
- You handle stream switching logic yourself
- Browser quirks with MSE can require debugging

**Complexity:** Medium-high on the webview side, minimal on the server side.

---

### Option B: HLS (HTTP Live Streaming)

**What it is:**
HLS is Apple's streaming protocol. The server provides a `.m3u8` playlist file (plain text) that lists available segments. The browser (or an HLS.js library) reads the playlist and fetches segments automatically.

**How it works:**
1. Client encodes H.264 into fMP4 segments (same as MSE)
2. Server stores segments AND generates/updates a simple text playlist file listing them
3. Webview uses HLS.js (a JavaScript library) which reads the playlist and handles fetching/buffering

**Example playlist (live stream):**
```
#EXTM3U
#EXT-X-VERSION:7
#EXT-X-TARGETDURATION:5
#EXT-X-MEDIA-SEQUENCE:142
#EXTINF:4.8,
segment-142.m4s
#EXTINF:5.0,
segment-143.m4s
#EXTINF:4.2,
segment-144.m4s
```

**Pros:**
- HLS.js handles most playback complexity — buffering, segment fetching, error recovery
- Well-documented, battle-tested
- Easier to get basic playback working

**Cons:**
- Less direct control over "jump to latest" behavior (HLS.js has APIs but they're less granular)
- Playlist generation adds server logic (though it's just text manipulation, no video processing)
- Slight latency overhead from playlist polling (can be reduced with Low-Latency HLS extensions)
- Stream switching (changing clients) requires switching playlists, which HLS.js supports but is less instant than raw MSE

**Complexity:** Lower on the webview side (library does work), slightly more on server (playlist management).

---

### My Recommendation

Given your requirements:
- Fast stream switching (webview switches between clients frequently)
- Custom buffering (keep last 15-20 seconds of keyframes)
- "Jump to latest" behavior
- Predictive pre-fetching of other streams

**MSE gives you the control you need**, but you'll write more webview code. HLS would fight you on the custom switching/buffering behavior.

However, a hybrid is possible: use fMP4 segments (compatible with both), implement MSE for live viewing, but structure segments in a way that you *could* generate an HLS playlist later for archival playback.

---

## Elaboration: Metadata Storage Options

### What needs to be stored per segment:
- **Start timestamp** (wall-clock time when first frame was captured)
- **Duration** (how long the segment covers)
- **Framerate** (for this segment)
- **Client ID** (which machine this came from)
- **Sequence number** (ordering)

### Option 1: Embedded in Container

fMP4 containers have metadata boxes (like `mdhd`, `tfdt`) that store timing info. The client encodes this into the segment itself.

**Pros:**
- Self-contained — segment file has everything needed to play it
- No separate files to manage

**Cons:**
- Some metadata (like client ID, custom fields) doesn't fit standard boxes — requires custom boxes or awkward workarounds
- Extracting metadata requires parsing the container (though libraries exist)

---

### Option 2: Sidecar File

Each segment (e.g., `segment-142.m4s`) has a companion metadata file (e.g., `segment-142.json`):

```json
{
  "client_id": "lab-pc-42",
  "start_time": "2026-02-05T14:23:07.482Z",
  "duration_ms": 4800,
  "framerate": 5,
  "sequence": 142,
  "is_keyframe_start": true
}
```

**Pros:**
- Easy to read/write without touching video data
- Flexible — add any fields you want
- Server can index/query metadata without parsing video

**Cons:**
- Two files per segment to manage
- Must keep them in sync

---

### Option 3: Separate Metadata Index

A single index file or database per session/client that lists all segments:

```json
{
  "client_id": "lab-pc-42",
  "segments": [
    { "file": "segment-142.m4s", "start_time": "...", "duration_ms": 4800, "framerate": 5 },
    { "file": "segment-143.m4s", "start_time": "...", "duration_ms": 5000, "framerate": 5 }
  ]
}
```

**Pros:**
- Single place to look up all segments
- Efficient for scrubbing/seeking (if you add that later)
- No per-segment file clutter

**Cons:**
- Must update the index each time a segment is written
- Concurrent writes need care (or append-only log format)

---

### My Recommendation

**Hybrid of Option 1 + Option 3:**
- Embed standard timing (timestamps, duration) in the fMP4 container — browsers need this anyway
- Maintain a lightweight append-only index on the server with extended metadata (client ID, sequence, framerate, segment file path)

This gives you self-contained playable segments while also having an easy-to-query index for the webview to know "what segments exist for client X in the last 20 seconds."

---

## Questions for You

1. **MSE vs HLS**: Based on the above, are you comfortable with MSE and writing more webview JavaScript for the control it provides? Or would you prefer HLS simplicity even if it means less precise control over switching/buffering?

2. **Metadata**: Does the hybrid approach (timing in container + separate index file) work for you? Or do you prefer one of the other options?

3. **Index format**: For the metadata index, would a simple append-only JSON lines file work, or do you want something more structured (like SQLite)? This affects how the server stores and the webview queries segment info.

---

## User

1. About MSE vs HLS/DASH

i would indeed pick MSE.

2. About Metadat Storage Options.

the option sounds good.
I would encode the mandatory metadata needed for browsers etc or other stuff in the stream itself (not clientId though) and handle other informtion or the same in a memory only aspect and periodically sync that to the database only for persistence so the realtime aspect is given and we don't have to block or lock out on database read/writes.

3. as in point 2 addressed, i would keep it in memory and sync periodically to the database we use for other stuff.

---

## Assistant (Plan · claude-opus-4.5 · 18.9s)

Good, we're aligned on the core decisions. Let me confirm my understanding and ask final clarifying questions.

## Summary of Decisions So Far

| Aspect | Decision |
|--------|----------|
| **Codec** | H.264 |
| **Container** | Fragmented MP4 (fMP4) |
| **Delivery to browser** | MSE (Media Source Extensions) |
| **Segments** | Variable duration, new segment on keyframe |
| **Keyframes** | On-demand + every 20-30 seconds max + on FPS change |
| **Buffered in memory** | All segments from last 15-20 seconds (configurable) |
| **Disk storage** | All segments, written as-is |
| **Metadata in stream** | Timestamps, duration (browser-required) |
| **Metadata in memory/DB** | Client ID, sequence, framerate, segment references, synced periodically to DB |
| **Resolution** | Max 1080p, downscaled preserving aspect ratio |
| **Framerate** | 1/5 fps to 5 fps, variable mid-session, fixed per segment |
| **Patches** | Deferred for now |

---

## Final Questions

### Segment File Structure

1. **fMP4 initialization segment**: fMP4 requires an initialization segment (contains codec info, resolution, etc.) sent once at stream start, then media segments follow. When resolution or codec parameters change, a new init segment is needed. Should the spec assume resolution is fixed for an entire session, or can it change mid-session (requiring a new init segment)?

### Memory Buffer Behavior

2. **Buffer eviction**: When a segment ages out of the 15-20 second memory buffer, it's already on disk. Should the server actively delete it from memory, or just let it be garbage collected / overwritten? (This affects whether the spec mentions explicit eviction.)

### Webview Joining a Stream

3. **Join flow**: When a webview wants to join a client's stream, it needs:
   - The init segment (codec/resolution info)
   - A keyframe segment to start decoding
   - Subsequent segments as they arrive

   Should the init segment be:
   - Stored separately and served on request?
   - Prepended to every keyframe segment (redundant but simpler)?
   - Cached in memory per client alongside the segment buffer?

### Segment Naming / Identification

4. **Segment identification**: How should segments be identified? Options:
   - Sequential number per client (e.g., `client-42-seg-00142.m4s`)
   - Timestamp-based (e.g., `client-42-1738765387482.m4s`)
   - UUID
   
   This affects how the webview requests "latest" or "specific" segments.

### WebSocket vs HTTP for Segment Delivery

5. **Transport**: For realtime delivery to the webview, should segments be:
   - Pushed via WebSocket (lower latency, server pushes as soon as available)
   - Pulled via HTTP (webview polls or long-polls, simpler but slightly more latency)
   - Both (WebSocket for live, HTTP for fetching older segments from disk)

---

## User

1. assume the same resolution and codec params for a single session for every segment.
2. let is just garbage collect, the implementation can choose to remove it but the 15-20 seconds are a a requrement.
3. stored in memory for each session that is active an served on request.
4. sequential numbers controlled by the client per client
5. using websockets for the live aspect and http for older segments.

---

## Assistant (Plan · claude-opus-4.5 · 11.5s)

Good, I now have enough information to write the spec. One final confirmation:

## Final Confirmation

Before I write the spec, let me confirm the scope of what I'll document:

### The spec will cover:

1. **Video encoding requirements** — H.264 settings, keyframe behavior, framerate constraints
2. **Container format** — fMP4 structure, initialization segment, media segments
3. **Segment rules** — when to create new segments, naming convention, metadata embedded
4. **Memory buffer requirements** — what the server keeps in memory, eviction rules
5. **Disk storage format** — how segments are written, file structure
6. **Metadata structure** — what's tracked in memory/DB per segment and per session
7. **Transport protocols** — WebSocket for live delivery, HTTP for historical segments
8. **Webview join flow** — how a viewer connects and receives init + keyframe + stream
9. **On-demand keyframe request flow** — how webview triggers keyframe via server
10. **FPS change flow** — how server requests framerate change, segment boundary behavior

### The spec will NOT cover:

- Authentication/authorization
- Client application architecture
- Webview UI/UX
- Server internal architecture beyond the streaming/storage behavior
- Patch/recovery system (deferred)
- Scrubbing (deferred)
- Transcoding client for archival (mentioned but not detailed)

### Format question:

Do you want the spec as:
- **A single markdown document** with sections for each topic
- **Multiple smaller documents** (e.g., one for encoding, one for transport, one for storage)

---

## User

multiple smaller documents using hugo with the hextra theme (https://imfing.github.io/hextra/docs/) and place it in @hugo/content/docs/reference/, create a new folder and link correctly between files, easy navigation and use of hextra features where apropriately.

---

## Assistant (Plan · claude-opus-4.5 · 5.8s)

I'll explore the existing structure and hextra documentation to understand how to best organize this.

```
Tool: read

**Input:**
```json
{
  "filePath": "/home/jakki/projects/franklyn/hugo/content/docs/reference/_index.md"
}
```
**Output:**
```
<file>
00001| ---
00002| title: Reference
00003| ---
00004| 

(End of file - total 4 lines)
</file>
```
```

```
Tool: read

**Input:**
```json
{
  "filePath": "/home/jakki/projects/franklyn/hugo/content/docs/reference/websocket-comm/_index.md"
}
```
**Output:**
```
<file>
00001| ---
00002| title: WS Comms Protocol
00003| ---
00004| 
00005| Real-time communication between the Franklyn server, Sentinels, and Proctors happens over WebSocket connections using JSON messages.
00006| 
00007| ## Overview
00008| 
00009| | Connection Type   | Role           | Description                                              |
00010| | ----------------- | -------------- | -------------------------------------------------------- |
00011| | Server - Sentinel | Frame Producer | Student machines stream screen captures to the server    |
00012| | Server - Proctor  | Frame Consumer | Teacher interface receives frames for monitored students |
00013| 
00014| ## Documentation
00015| 
00016| {{< cards >}}
00017| {{< card link="lifecycle" title="Connection Lifecycle" icon="refresh" subtitle="Connection flow and sequence diagrams" >}}
00018| {{< card link="server-sentinel" title="Server - Sentinel" icon="upload" subtitle="Registration and frame streaming" >}}
00019| {{< card link="server-proctor" title="Server - Proctor" icon="download" subtitle="Registration, subscriptions, and frame receiving" >}}
00020| {{< card link="special-datatype" title="Special Datatypes" icon="cube" subtitle="Custom data structures used in messages" >}}
00021| {{< /cards >}}
00022| 

(End of file - total 22 lines)
</file>
```
```

```
Tool: webfetch

**Input:**
```json
{
  "url": "https://imfing.github.io/hextra/docs/guide/organize-files/",
  "format": "markdown"
}
```
**Output:**
```
Organize Files – Hextra

Hextra **v0.11** is here! 🎉 Discover [what’s new](https://imfing.github.io/hextra/blog/v0.11/)

  [![Logo](/hextra/images/logo.svg) ![Dark Logo](/hextra/images/logo-dark.svg) Hextra](/hextra/) [Documentation](/hextra/docs)

Versions

-   [Development ↗](https://imfing.github.io/hextra/versions/latest/)
-   [v0.10 ↗](https://imfing.github.io/hextra/versions/v0.10/)
-   [v0.9 ↗](https://imfing.github.io/hextra/versions/v0.9/)

[Blog](/hextra/blog) [About](/hextra/about) [Showcase](/hextra/showcase)

 CTRL K

[GitHub](https://github.com/imfing/hextra "GitHub")

 CTRL K

-   [About](/hextra/about/)
-   [Blog](/hextra/blog/)
    
    -   [Hextra v0.11](/hextra/blog/v0.11/)
    -   [Hextra v0.10](/hextra/blog/v0.10/)
    -   [Markdown Syntax Guide](/hextra/blog/markdown/)
    
-   [Documentation](/hextra/docs/)
    
    -   [Getting Started](/hextra/docs/getting-started/)
    -   [Guide](/hextra/docs/guide/)
        
        -   [Organize Files](/hextra/docs/guide/organize-files/)
            -   [Directory Structure](#directory-structure)
            -   [Layouts](#layouts)
            -   [Sidebar Navigation](#sidebar-navigation)
            -   [Section Navigation](#section-navigation)
            -   [Breadcrumb Navigation](#breadcrumb-navigation)
            -   [Configure Content Directory](#configure-content-directory)
            -   [Add Images](#add-images)
        -   [Configuration](/hextra/docs/guide/configuration/)
        -   [Markdown](/hextra/docs/guide/markdown/)
        -   [Syntax Highlighting](/hextra/docs/guide/syntax-highlighting/)
        -   [LaTeX](/hextra/docs/guide/latex/)
        -   [Diagrams](/hextra/docs/guide/diagrams/)
        -   [Shortcodes](/hextra/docs/guide/shortcodes/)
            
            -   [Callout](/hextra/docs/guide/shortcodes/callout/)
            -   [Cards](/hextra/docs/guide/shortcodes/cards/)
            -   [Details](/hextra/docs/guide/shortcodes/details/)
            -   [FileTree](/hextra/docs/guide/shortcodes/filetree/)
            -   [Icon](/hextra/docs/guide/shortcodes/icon/)
            -   [Others](/hextra/docs/guide/shortcodes/others/)
            -   [Steps](/hextra/docs/guide/shortcodes/steps/)
            -   [Tabs](/hextra/docs/guide/shortcodes/tabs/)
            
        -   [Deploy Site](/hextra/docs/guide/deploy-site/)
        
    -   [Advanced](/hextra/docs/advanced/)
        
        -   [Multi-language](/hextra/docs/advanced/multi-language/)
        -   [Comments](/hextra/docs/advanced/comments/)
        -   [Customization](/hextra/docs/advanced/customization/)
        
    
-   [Showcase](/hextra/showcase/)
-   More
-   [About](/hextra/about)
-   [Hugo Docs ↗](https://gohugo.io/documentation/)

-   [Getting Started](/hextra/docs/getting-started/)
-   [Guide](/hextra/docs/guide/)
    
    -   [Organize Files](/hextra/docs/guide/organize-files/)
    -   [Configuration](/hextra/docs/guide/configuration/)
    -   [Markdown](/hextra/docs/guide/markdown/)
    -   [Syntax Highlighting](/hextra/docs/guide/syntax-highlighting/)
    -   [LaTeX](/hextra/docs/guide/latex/)
    -   [Diagrams](/hextra/docs/guide/diagrams/)
    -   [Shortcodes](/hextra/docs/guide/shortcodes/)
        
        -   [Callout](/hextra/docs/guide/shortcodes/callout/)
        -   [Cards](/hextra/docs/guide/shortcodes/cards/)
        -   [Details](/hextra/docs/guide/shortcodes/details/)
        -   [FileTree](/hextra/docs/guide/shortcodes/filetree/)
        -   [Icon](/hextra/docs/guide/shortcodes/icon/)
        -   [Others](/hextra/docs/guide/shortcodes/others/)
        -   [Steps](/hextra/docs/guide/shortcodes/steps/)
        -   [Tabs](/hextra/docs/guide/shortcodes/tabs/)
        
    -   [Deploy Site](/hextra/docs/guide/deploy-site/)
    
-   [Advanced](/hextra/docs/advanced/)
    
    -   [Multi-language](/hextra/docs/advanced/multi-language/)
    -   [Comments](/hextra/docs/advanced/comments/)
    -   [Customization](/hextra/docs/advanced/customization/)
    
-   More
-   [About](/hextra/about)
-   [Hugo Docs ↗](https://gohugo.io/documentation/)

English

-   [English](/hextra/docs/guide/organize-files/)
-   [فارسی](/hextra/fa/docs/guide/organize-files/)
-   [日本語](/hextra/ja/docs/guide/organize-files/)
-   [简体中文](/hextra/zh-cn/docs/guide/organize-files/)

-   Light
    
-   Dark
    
-   System
    

On this page

-   [Directory Structure](#directory-structure)
-   [Layouts](#layouts)
-   [Sidebar Navigation](#sidebar-navigation)
-   [Section Navigation](#section-navigation)
-   [Section Pagination Order](#section-pagination-order)
-   [Example](#example)
-   [Breadcrumb Navigation](#breadcrumb-navigation)
-   [Customizing Breadcrumb Link Titles](#customizing-breadcrumb-link-titles)
-   [Enabling and Disabling Breadcrumbs](#enabling-and-disabling-breadcrumbs)
-   [Configure Content Directory](#configure-content-directory)
-   [Add Images](#add-images)

[Edit this page on GitHub →](https://github.com/imfing/hextra/edit/main/docs/content/docs/guide/organize-files.md) Scroll to top

[Documentation](/hextra/docs/)

[Guide](/hextra/docs/guide/)

Organize Files

# Organize Files

## Directory Structure[](#directory-structure)

By default, Hugo searches for Markdown files in the `content` directory, and the structure of the directory determines the final output structure of your website. Take this site as an example:

-   content
    -   \_index.md
    -   docs
        -   \_index.md
        -   getting-started.md
        -   guide
            -   \_index.md
            -   organize-files.md
    -   blog
        -   \_index.md
        -   post-1.md

Each of the `_index.md` files is the index page for the corresponding section. The other Markdown files are regular pages.

```
content
├── _index.md // <- /
├── docs
│   ├── _index.md // <- /docs/
│   ├── getting-started.md // <- /docs/getting-started/
│   └── guide
│       ├── _index.md // <- /docs/guide/
│       └── organize-files.md // <- /docs/guide/organize-files/
└── blog
    ├── _index.md // <- /blog/
    └── post-1.md // <- /blog/post-1/
```

## Layouts[](#layouts)

Hextra offers three layouts for different content types:

Layout

Directory

Features

`docs`

`content/docs/`

Ideal for structured documentation, same as this section.

`blog`

`content/blog/`

For blog postings, with both listing and detailed article views.

`default`

All other directories

Single-page article view without sidebar.

To customize a section to mirror the behavior of a built-in layout, specify the desired type in the front matter of the section’s `_index.md`.

content/my-docs/\_index.md

```yaml
---
title: My Docs
cascade:
  type: docs
---
```

The above example configuration ensures that the content files inside `content/my-docs/` will be treated as documentation (`docs` type) by default.

## Sidebar Navigation[](#sidebar-navigation)

The sidebar navigation is generated automatically based on the content organization alphabetically. To manually configure the sidebar order, we can use the `weight` parameter in the front matter of the Markdown files.

content/docs/guide/\_index.md

```yaml
---
title: Guide
weight: 2
---
```

It is recommended to keep the sidebar not too deep. If you have a lot of content, consider **splitting them into multiple sections**.

## Section Navigation[](#section-navigation)

### Section Pagination Order[](#section-pagination-order)

The order in which pages, accessed via [`PAGE.PrevInSection`](https://gohugo.io/methods/page/previnsection/) and [`PAGE.NextInSection`](https://gohugo.io/methods/page/nextinsection/) in a [page collection](https://gohugo.io/quick-reference/glossary/#page-collection), are ordered, is reversed by default.

To disable this reversed ordering you can set the `reversePagination` custom parameter in the page front matter to `false`. By default `reversePagination` is set to `true`.

#### Example[](#example)

Given the following directory structure:

-   content
    -   \_index.md
    -   blog
        -   \_index.md
        -   my-blog-series
            -   \_index.md
            -   post-a
                -   index.md
            -   post-b
                -   index.md
            -   post-c
                -   index.md

And the following front matter in the posts:

content/blog/my-blog-series/post-a/index.md

```yaml
---
title: Post A
weight: 1
---
```

content/blog/my-blog-series/post-b/index.md

```yaml
---
title: Post B
weight: 2
---
```

content/blog/my-blog-series/post-c/index.md

```yaml
---
title: Post C
weight: 3
---
```

If the reader is at the bottom of `post-b/index.md`, they will see that the next page is `post-a`, and the previous page is `post-c`. This is due to `reversePagination` being set to `true` by default. This is ok when we want our posts to be displayed in chronological order from latest to oldest. However, in the case of a blog series where there are multiple parts, we typically want people to read the first post, and then move to the second and so on. So we want to disable the reversed ordering.

We can turn off `reversePagination` in every blog post in this series by adding the following front matter to `my-blog-series/_index.md`

content/blog/my-blog-series/\_index.md

```yaml
---
title: My Blog Series
cascade:
    params:
        reversePagination: false
---
```

We are using [`cascade`](https://gohugo.io/content-management/front-matter/#cascade-1) here to propagate the setting to all posts in the `my-blog-series` so that `reversePagination` is set to `false` for all descendents. This will now ensure that when the reader is on `post-b/index.md` they will see that the next page is `post-c` and the previous page is `post-a`.

## Breadcrumb Navigation[](#breadcrumb-navigation)

Breadcrumbs are auto-generated based on the directory structure of `/content`.

For example, consider the file structure [demonstrated above](#directory-structure). Given that structure, the breadcrumbs atop the page at `/docs/guide/organize-files/` would appear automatically as follows:

```
Documentation > Guide > Organize Files
```

### Customizing Breadcrumb Link Titles[](#customizing-breadcrumb-link-titles)

By default, each breadcrumb link is generated based on that page’s `title` parameter. You can customize this by specifying a `linkTitle`.

For example, if instead of `Organize Files` we wanted the breadcrumb to be `Foo Bar`:

content/docs/guide/organize-files.md

```yaml
---
linkTitle: Foo Bar
title: Organize Files
---
```

This would now generate the following breadcrumbs:

```
Documentation > Guide > Foo Bar
```

### Enabling and Disabling Breadcrumbs[](#enabling-and-disabling-breadcrumbs)

Whether breadcrumbs are enabled, or disabled, by default for a page, is determined by its [content type](https://gohugo.io/quick-reference/glossary/#content-type) and [page kind](https://gohugo.io/quick-reference/glossary/#page-kind):

Content Type

Section

Page

`docs`

Enabled

Enabled

`blog`

Disabled

Enabled

Any other type

Disabled

Disabled

You can override these defaults on a page by setting `breadcrumbs` in its front matter:

content/docs/guide/organize-files.md

```yaml
---
breadcrumbs: false
title: Organize Files
---
```

Similarly you can use [cascade](https://gohugo.io/content-management/front-matter/#cascade-1) to override the defaults on a page and its decendents:

content/portfolio/\_index.md

```yaml
---
title: "Portfolio"

cascade:
  params:
    breadcrumbs: true
---
```

## Configure Content Directory[](#configure-content-directory)

By default, the root `content/` directory is used by Hugo to build the site. If you need to use a different directory for content, for example `docs/`, this can be done by setting the [`contentDir`](https://gohugo.io/getting-started/configuration/#contentdir) parameter in the site configuration `hugo.yaml`.

## Add Images[](#add-images)

To add images, the easiest way is to put the image files in the same directory as the Markdown file. For example, add an image file `image.png` alongside the `my-page.md` file:

-   content
    -   docs
        -   my-page.md
        -   image.png

Then, we can use the following Markdown syntax to add the image to the content:

content/docs/my-page.md

```markdown
![](image.png)
```

We can also utilize the [page bundles](https://gohugo.io/content-management/page-bundles/#leaf-bundles) feature of Hugo to organize the image files together with the Markdown file. To achieve that, turn the `my-page.md` file into a directory `my-page` and put the content into a file named `index.md`, and put the image files inside the `my-page` directory:

-   content
    -   docs
        -   my-page
            -   index.md
            -   image.png

content/docs/my-page/index.md

```markdown
![](image.png)
```

Alternatively, we can also put the image files in the `static` directory, which will make the images available for all pages:

-   static
    -   images
        -   image.png
-   content
    -   docs
        -   my-page.md

Note that the image path begins with a slash `/` and is relative to the static directory:

content/docs/my-page.md

```markdown
![](/images/image.png)
```

Last updated on September 6, 2025

[Guide](/hextra/docs/guide/ "Guide")[Configuration](/hextra/docs/guide/configuration/ "Configuration")

[Powered by Hextra](https://github.com/imfing/hextra "Hextra GitHub Homepage")

© 2025 Hextra Project.
```
```

---

## Assistant (Plan · claude-opus-4.5 · 6.4s)

Let me also look at some existing spec files and fetch more info about hextra shortcodes:

```
Tool: read

**Input:**
```json
{
  "filePath": "/home/jakki/projects/franklyn/hugo/content/docs/reference/websocket-comm/lifecycle.md"
}
```
**Output:**
```
<file>
00001| ---
00002| title: Lifecycle
00003| ---
00004| 
00005| This document describes the lifecycle of WebSocket connections for both Sentinels and Proctors.
00006| 
00007| - **Sentinel**: Frame producer (runs on student machines)
00008| - **Proctor**: Frame consumer (teacher interface)
00009| 
00010| ---
00011| 
00012| ## Sentinel Lifecycle
00013| 
00014| ### Flow
00015| 
00016| 1. Connect to server via WebSocket
00017| 2. Send `sentinel.register` as the first message
00018| 3. Receive `server.registration.ack` or `server.registration.reject`
00019| 4. If accepted: send `sentinel.frame` every couple of seconds
00020| 5. Connection closes when the sentinel shuts down
00021| 
00022| ### Sequence Diagram
00023| 
00024| ```plantuml
00025| @startuml
00026| skinparam sequenceMessageAlign center
00027| 
00028| participant "Sentinel" as S
00029| participant "Server" as Srv
00030| 
00031| == Connection ==
00032| S -> Srv : WebSocket connect
00033| activate Srv
00034| 
00035| == Registration ==
00036| S -> Srv : sentinel.register
00037| alt registration accepted
00038|   Srv -> S : server.registration.ack
00039| else registration rejected
00040|   Srv -> S : server.registration.reject
00041|   S <-> Srv : connection closed
00042| end
00043| 
00044| == Frame Streaming ==
00045| loop every couple of seconds
00046|   S -> Srv : sentinel.frame
00047| end
00048| 
00049| == Disconnection ==
00050| S <-> Srv : connection closed
00051| deactivate Srv
00052| 
00053| @enduml
00054| ```
00055| 
00056| ---
00057| 
00058| ## Proctor Lifecycle
00059| 
00060| ### Flow
00061| 
00062| 1. Connect to server via WebSocket
00063| 2. Send `proctor.register` as the first message
00064| 3. Receive `server.registration.ack` or `server.registration.reject`
00065| 4. If accepted:
00066|    - Receive `server.update-sentinels` with the list of available sentinels
00067|    - Send `proctor.subscribe` or `proctor.revoke-subscription` as needed
00068|    - Receive `server.frame` for subscribed sentinels
00069| 5. Connection closes when the proctor shuts down
00070| 
00071| ### Sentinel Updates
00072| 
00073| The server sends `server.update-sentinels` to the proctor:
00074| 
00075| - Immediately after successful registration
00076| - Whenever a sentinel connects or disconnects
00077| 
00078| ### Sequence Diagram
00079| 
00080| ```plantuml
00081| @startuml
00082| skinparam sequenceMessageAlign center
00083| 
00084| participant "Proctor" as P
00085| participant "Server" as Srv
00086| 
00087| == Connection ==
00088| P -> Srv : WebSocket connect
00089| activate Srv
00090| 
00091| == Registration ==
00092| P -> Srv : proctor.register
00093| alt registration accepted
00094|   Srv -> P : server.registration.ack
00095|   Srv -> P : server.update-sentinels
00096| else registration rejected
00097|   Srv -> P : server.registration.reject
00098|   P <-> Srv : connection closed
00099| end
00100| 
00101| == Monitoring ==
00102| 
00103| group Subscription Management [can occur anytime]
00104|   P -> Srv : proctor.subscribe
00105|   P -> Srv : proctor.revoke-subscription
00106| end
00107| 
00108| loop frames available for subscriptions
00109|   Srv -> P : server.frame
00110| end
00111| 
00112| Srv -> P : server.update-sentinels
00113| note right : sent when sentinels\nconnect or disconnect
00114| 
00115| == Disconnection ==
00116| P <-> Srv : connection closed
00117| deactivate Srv
00118| 
00119| @enduml
00120| ```
00121| 

(End of file - total 121 lines)
</file>
```
```

```
Tool: read

**Input:**
```json
{
  "filePath": "/home/jakki/projects/franklyn/hugo/content/docs/reference/websocket-comm/server-sentinel.md"
}
```
**Output:**
```
<file>
00001| ---
00002| title: Server - Sentinel
00003| ---
00004| 
00005| Communications between Server and Sentinel are done with json via a websocket connection.
00006| 
00007| ## Message Format
00008| 
00009| All messages follow a consistent envelope structure:
00010| 
00011| | Field       | Type    | Required | Description                                    |
00012| | ----------- | ------- | -------- | ---------------------------------------------- |
00013| | `type`      | string  | yes      | Determines the message type                    |
00014| | `payload`   | object  | no       | Contains the message content                   |
00015| | `timestamp` | integer | yes      | The time this message was sent in unix seconds |
00016| 
00017| ---
00018| 
00019| ## Message Types
00020| 
00021| ### `sentinel.register`
00022| 
00023| Used to register a Sentinel when connecting to the server.
00024| This message must be the first message sent or the sentinel will be disconnected.
00025| 
00026| **Direction:** Sentinel -> Server
00027| 
00028| **Payload:**
00029| 
00030| `<empty>`
00031| 
00032| **Example:**
00033| 
00034| ```json
00035| {
00036|   "type": "sentinel.register",
00037|   "timestamp": 1696969420
00038| }
00039| ```
00040| 
00041| ---
00042| 
00043| ### `server.registration.ack`
00044| 
00045| This message will be sent from the server to acknowledge a registration of a sentinel.
00046| 
00047| **Direction:** Server -> Sentinel
00048| 
00049| **Payload:**
00050| 
00051| | Field        | Type   | Required | Description                       |
00052| | ------------ | ------ | -------- | --------------------------------- |
00053| | `sentinelId` | string | yes      | The UUID assigned to the sentinel |
00054| 
00055| **Example:**
00056| 
00057| ```json
00058| {
00059|   "type": "server.registration.ack",
00060|   "timestamp": 1696969420,
00061|   "payload": {
00062|     "sentinelId": "e0a1e92b-7aae-4885-b5f7-7f7a89fce101"
00063|   }
00064| }
00065| ```
00066| 
00067| ---
00068| 
00069| ### `server.registration.reject`
00070| 
00071| This message will be sent from the server to reject the registration of a sentinel.
00072| If the sentinel receives this message, it should close the connection.
00073| 
00074| **Direction:** Server -> Sentinel
00075| 
00076| **Payload:**
00077| 
00078| | Field    | Type   | Required | Description                  |
00079| | -------- | ------ | -------- | ---------------------------- |
00080| | `reason` | string | yes      | The reason for the rejection |
00081| 
00082| **Example:**
00083| 
00084| ```json
00085| {
00086|   "type": "server.registration.reject",
00087|   "timestamp": 1696969420,
00088|   "payload": {
00089|     "reason": "Server busy"
00090|   }
00091| }
00092| ```
00093| 
00094| ---
00095| 
00096| ### `sentinel.frame`
00097| 
00098| The sentinel sends its frames every couple of seconds to the server.
00099| 
00100| **Direction:** Sentinel -> Server
00101| 
00102| **Payload:**
00103| 
00104| | Field    | Type                                 | Required | Description                                                 |
00105| | -------- | ------------------------------------ | -------- | ----------------------------------------------------------- |
00106| | `frames` | [Frame](../special-datatype#frame)[] | yes      | All Frames that have been made between the sending interval |
00107| 
00108| **Example:**
00109| 
00110| ```json
00111| {
00112|   "type": "sentinel.frame",
00113|   "timestamp": 1696969420,
00114|   "payload": {
00115|     "frames": [
00116|       {
00117|         "sentinelId": "b255e355-e398-43d7-b772-101bbf4ca8f0",
00118|         "frameId": "4799566e-ecdf-40e0-99c2-7bdc63a4038c",
00119|         "index": 5,
00120|         "data": "/9j/4AAQSkZ....Lj/1bP/F1v0A//9k="
00121|       },
00122|       {
00123|         "sentinelId": "b255e355-e398-43d7-b772-101bbf4ca8f0",
00124|         "frameId": "d7994246-35a6-4e2d-aae7-14bf9022f927",
00125|         "index": 23,
00126|         "data": "/9j/4AAQSkZJ....ejBknVXUhEj/9k="
00127|       }
00128|     ]
00129|   }
00130| }
00131| ```
00132| 

(End of file - total 132 lines)
</file>
```
```

```
Tool: webfetch

**Input:**
```json
{
  "format": "markdown",
  "url": "https://imfing.github.io/hextra/docs/guide/shortcodes/callout/"
}
```
**Output:**
```
Callout Component – Hextra

Hextra **v0.11** is here! 🎉 Discover [what’s new](https://imfing.github.io/hextra/blog/v0.11/)

  [![Logo](/hextra/images/logo.svg) ![Dark Logo](/hextra/images/logo-dark.svg) Hextra](/hextra/) [Documentation](/hextra/docs)

Versions

-   [Development ↗](https://imfing.github.io/hextra/versions/latest/)
-   [v0.10 ↗](https://imfing.github.io/hextra/versions/v0.10/)
-   [v0.9 ↗](https://imfing.github.io/hextra/versions/v0.9/)

[Blog](/hextra/blog) [About](/hextra/about) [Showcase](/hextra/showcase)

 CTRL K

[GitHub](https://github.com/imfing/hextra "GitHub")

 CTRL K

-   [About](/hextra/about/)
-   [Blog](/hextra/blog/)
    
    -   [Hextra v0.11](/hextra/blog/v0.11/)
    -   [Hextra v0.10](/hextra/blog/v0.10/)
    -   [Markdown Syntax Guide](/hextra/blog/markdown/)
    
-   [Documentation](/hextra/docs/)
    
    -   [Getting Started](/hextra/docs/getting-started/)
    -   [Guide](/hextra/docs/guide/)
        
        -   [Organize Files](/hextra/docs/guide/organize-files/)
        -   [Configuration](/hextra/docs/guide/configuration/)
        -   [Markdown](/hextra/docs/guide/markdown/)
        -   [Syntax Highlighting](/hextra/docs/guide/syntax-highlighting/)
        -   [LaTeX](/hextra/docs/guide/latex/)
        -   [Diagrams](/hextra/docs/guide/diagrams/)
        -   [Shortcodes](/hextra/docs/guide/shortcodes/)
            
            -   [Callout](/hextra/docs/guide/shortcodes/callout/)
                -   [Examples](#examples)
                -   [Options](#options)
            -   [Cards](/hextra/docs/guide/shortcodes/cards/)
            -   [Details](/hextra/docs/guide/shortcodes/details/)
            -   [FileTree](/hextra/docs/guide/shortcodes/filetree/)
            -   [Icon](/hextra/docs/guide/shortcodes/icon/)
            -   [Others](/hextra/docs/guide/shortcodes/others/)
            -   [Steps](/hextra/docs/guide/shortcodes/steps/)
            -   [Tabs](/hextra/docs/guide/shortcodes/tabs/)
            
        -   [Deploy Site](/hextra/docs/guide/deploy-site/)
        
    -   [Advanced](/hextra/docs/advanced/)
        
        -   [Multi-language](/hextra/docs/advanced/multi-language/)
        -   [Comments](/hextra/docs/advanced/comments/)
        -   [Customization](/hextra/docs/advanced/customization/)
        
    
-   [Showcase](/hextra/showcase/)
-   More
-   [About](/hextra/about)
-   [Hugo Docs ↗](https://gohugo.io/documentation/)

-   [Getting Started](/hextra/docs/getting-started/)
-   [Guide](/hextra/docs/guide/)
    
    -   [Organize Files](/hextra/docs/guide/organize-files/)
    -   [Configuration](/hextra/docs/guide/configuration/)
    -   [Markdown](/hextra/docs/guide/markdown/)
    -   [Syntax Highlighting](/hextra/docs/guide/syntax-highlighting/)
    -   [LaTeX](/hextra/docs/guide/latex/)
    -   [Diagrams](/hextra/docs/guide/diagrams/)
    -   [Shortcodes](/hextra/docs/guide/shortcodes/)
        
        -   [Callout](/hextra/docs/guide/shortcodes/callout/)
        -   [Cards](/hextra/docs/guide/shortcodes/cards/)
        -   [Details](/hextra/docs/guide/shortcodes/details/)
        -   [FileTree](/hextra/docs/guide/shortcodes/filetree/)
        -   [Icon](/hextra/docs/guide/shortcodes/icon/)
        -   [Others](/hextra/docs/guide/shortcodes/others/)
        -   [Steps](/hextra/docs/guide/shortcodes/steps/)
        -   [Tabs](/hextra/docs/guide/shortcodes/tabs/)
        
    -   [Deploy Site](/hextra/docs/guide/deploy-site/)
    
-   [Advanced](/hextra/docs/advanced/)
    
    -   [Multi-language](/hextra/docs/advanced/multi-language/)
    -   [Comments](/hextra/docs/advanced/comments/)
    -   [Customization](/hextra/docs/advanced/customization/)
    
-   More
-   [About](/hextra/about)
-   [Hugo Docs ↗](https://gohugo.io/documentation/)

English

-   [English](/hextra/docs/guide/shortcodes/callout/)
-   [فارسی](/hextra/fa/docs/guide/shortcodes/callout/)
-   [日本語](/hextra/ja/docs/guide/shortcodes/callout/)
-   [简体中文](/hextra/zh-cn/docs/guide/shortcodes/callout/)

-   Light
    
-   Dark
    
-   System
    

On this page

-   [Examples](#examples)
-   [Default](#default)
-   [Info](#info)
-   [Warning](#warning)
-   [Error](#error)
-   [Important](#important)
-   [Custom Icon](#custom-icon)
-   [Emoji](#emoji)
-   [Options](#options)

[Edit this page on GitHub →](https://github.com/imfing/hextra/edit/main/docs/content/docs/guide/shortcodes/callout.md) Scroll to top

[Documentation](/hextra/docs/)

[Guide](/hextra/docs/guide/)

[Shortcodes](/hextra/docs/guide/shortcodes/)

Callout

# Callout Component

A built-in component to show important information to the reader.

Note

[GitHub-style alerts](../../markdown#alerts) are supported since [v0.9.0](https://github.com/imfing/hextra/releases/tag/v0.9.0). It leverages Markdown syntax to render the callout which ensures better portability and readability of the content.

## Examples[](#examples)

A **callout** is a short piece of text intended to attract attention.

A **callout** is a short piece of text intended to attract attention.

A **callout** is a short piece of text intended to attract attention.

A **callout** is a short piece of text intended to attract attention.

A **callout** is a short piece of text intended to attract attention.

### Default[](#default)

A **callout** is a short piece of text intended to attract attention.

```markdown
{{< callout >}}
  A **callout** is a short piece of text intended to attract attention.
{{< /callout >}}
```

### Info[](#info)

A **callout** is a short piece of text intended to attract attention.

```markdown
{{< callout type="info" >}}
  A **callout** is a short piece of text intended to attract attention.
{{< /callout >}}
```

### Warning[](#warning)

A **callout** is a short piece of text intended to attract attention.

```markdown
{{< callout type="warning" >}}
  A **callout** is a short piece of text intended to attract attention.
{{< /callout >}}
```

### Error[](#error)

A **callout** is a short piece of text intended to attract attention.

```markdown
{{< callout type="error" >}}
  A **callout** is a short piece of text intended to attract attention.
{{< /callout >}}
```

### Important[](#important)

A **callout** is a short piece of text intended to attract attention.

```markdown
{{< callout type="important" >}} 
  A **callout** is a short piece of text intended to attract attention.
{{< /callout >}}
```

### Custom Icon[](#custom-icon)

A **callout** is a short piece of text intended to attract attention.

```markdown
{{< callout icon="sparkles" >}}
  A **callout** is a short piece of text intended to attract attention.
{{< /callout >}}
```

A **callout** is a short piece of text intended to attract attention.

```markdown
{{< callout type="important" icon="sparkles" >}}
  A **callout** is a short piece of text intended to attract attention.
{{< /callout >}}
```

### Emoji[](#emoji)

🌐

A **callout** is a short piece of text intended to attract attention.

```markdown
{{< callout emoji="🌐" >}}
  A **callout** is a short piece of text intended to attract attention.
{{< /callout >}}
```

ℹ️

A **callout** is a short piece of text intended to attract attention.

```markdown
{{< callout type="info" emoji="ℹ️" >}}
  A **callout** is a short piece of text intended to attract attention.
{{< /callout >}}
```

## Options[](#options)

Parameter

Description

`type`

The type of callout. (default, `info`, `warning`, `error`, `important`)

`emoji`

The emoji to show before the callout.

`icon`

The icon to show before the callout. (related to type or can be a custom icon).

Last updated on September 6, 2025

[Shortcodes](/hextra/docs/guide/shortcodes/ "Shortcodes")[Cards](/hextra/docs/guide/shortcodes/cards/ "Cards")

[Powered by Hextra](https://github.com/imfing/hextra "Hextra GitHub Homepage")

© 2025 Hextra Project.
```
```

---

## Assistant (Plan · claude-opus-4.5 · 4.6s)

Let me also check the steps and tabs shortcodes as they'll be useful for the spec:

```
Tool: webfetch

**Input:**
```json
{
  "format": "markdown",
  "url": "https://imfing.github.io/hextra/docs/guide/shortcodes/steps/"
}
```
**Output:**
```
Steps – Hextra

Hextra **v0.11** is here! 🎉 Discover [what’s new](https://imfing.github.io/hextra/blog/v0.11/)

  [![Logo](/hextra/images/logo.svg) ![Dark Logo](/hextra/images/logo-dark.svg) Hextra](/hextra/) [Documentation](/hextra/docs)

Versions

-   [Development ↗](https://imfing.github.io/hextra/versions/latest/)
-   [v0.10 ↗](https://imfing.github.io/hextra/versions/v0.10/)
-   [v0.9 ↗](https://imfing.github.io/hextra/versions/v0.9/)

[Blog](/hextra/blog) [About](/hextra/about) [Showcase](/hextra/showcase)

 CTRL K

[GitHub](https://github.com/imfing/hextra "GitHub")

 CTRL K

-   [About](/hextra/about/)
-   [Blog](/hextra/blog/)
    
    -   [Hextra v0.11](/hextra/blog/v0.11/)
    -   [Hextra v0.10](/hextra/blog/v0.10/)
    -   [Markdown Syntax Guide](/hextra/blog/markdown/)
    
-   [Documentation](/hextra/docs/)
    
    -   [Getting Started](/hextra/docs/getting-started/)
    -   [Guide](/hextra/docs/guide/)
        
        -   [Organize Files](/hextra/docs/guide/organize-files/)
        -   [Configuration](/hextra/docs/guide/configuration/)
        -   [Markdown](/hextra/docs/guide/markdown/)
        -   [Syntax Highlighting](/hextra/docs/guide/syntax-highlighting/)
        -   [LaTeX](/hextra/docs/guide/latex/)
        -   [Diagrams](/hextra/docs/guide/diagrams/)
        -   [Shortcodes](/hextra/docs/guide/shortcodes/)
            
            -   [Callout](/hextra/docs/guide/shortcodes/callout/)
            -   [Cards](/hextra/docs/guide/shortcodes/cards/)
            -   [Details](/hextra/docs/guide/shortcodes/details/)
            -   [FileTree](/hextra/docs/guide/shortcodes/filetree/)
            -   [Icon](/hextra/docs/guide/shortcodes/icon/)
            -   [Others](/hextra/docs/guide/shortcodes/others/)
            -   [Steps](/hextra/docs/guide/shortcodes/steps/)
                -   [Example](#example)
                -   [Usage](#usage)
            -   [Tabs](/hextra/docs/guide/shortcodes/tabs/)
            
        -   [Deploy Site](/hextra/docs/guide/deploy-site/)
        
    -   [Advanced](/hextra/docs/advanced/)
        
        -   [Multi-language](/hextra/docs/advanced/multi-language/)
        -   [Comments](/hextra/docs/advanced/comments/)
        -   [Customization](/hextra/docs/advanced/customization/)
        
    
-   [Showcase](/hextra/showcase/)
-   More
-   [About](/hextra/about)
-   [Hugo Docs ↗](https://gohugo.io/documentation/)

-   [Getting Started](/hextra/docs/getting-started/)
-   [Guide](/hextra/docs/guide/)
    
    -   [Organize Files](/hextra/docs/guide/organize-files/)
    -   [Configuration](/hextra/docs/guide/configuration/)
    -   [Markdown](/hextra/docs/guide/markdown/)
    -   [Syntax Highlighting](/hextra/docs/guide/syntax-highlighting/)
    -   [LaTeX](/hextra/docs/guide/latex/)
    -   [Diagrams](/hextra/docs/guide/diagrams/)
    -   [Shortcodes](/hextra/docs/guide/shortcodes/)
        
        -   [Callout](/hextra/docs/guide/shortcodes/callout/)
        -   [Cards](/hextra/docs/guide/shortcodes/cards/)
        -   [Details](/hextra/docs/guide/shortcodes/details/)
        -   [FileTree](/hextra/docs/guide/shortcodes/filetree/)
        -   [Icon](/hextra/docs/guide/shortcodes/icon/)
        -   [Others](/hextra/docs/guide/shortcodes/others/)
        -   [Steps](/hextra/docs/guide/shortcodes/steps/)
        -   [Tabs](/hextra/docs/guide/shortcodes/tabs/)
        
    -   [Deploy Site](/hextra/docs/guide/deploy-site/)
    
-   [Advanced](/hextra/docs/advanced/)
    
    -   [Multi-language](/hextra/docs/advanced/multi-language/)
    -   [Comments](/hextra/docs/advanced/comments/)
    -   [Customization](/hextra/docs/advanced/customization/)
    
-   More
-   [About](/hextra/about)
-   [Hugo Docs ↗](https://gohugo.io/documentation/)

English

-   [English](/hextra/docs/guide/shortcodes/steps/)
-   [فارسی](/hextra/fa/docs/guide/shortcodes/steps/)
-   [日本語](/hextra/ja/docs/guide/shortcodes/steps/)
-   [简体中文](/hextra/zh-cn/docs/guide/shortcodes/steps/)

-   Light
    
-   Dark
    
-   System
    

On this page

-   [Example](#example)
-   [Step 1](#step-1)
-   [Step 2](#step-2)
-   [Step 3](#step-3)
-   [Usage](#usage)

[Edit this page on GitHub →](https://github.com/imfing/hextra/edit/main/docs/content/docs/guide/shortcodes/steps.md) Scroll to top

[Documentation](/hextra/docs/)

[Guide](/hextra/docs/guide/)

[Shortcodes](/hextra/docs/guide/shortcodes/)

Steps

# Steps

A built-in component to display a series of steps.

## Example[](#example)

### Step 1[](#step-1)

This is the first step.

### Step 2[](#step-2)

This is the second step.

### Step 3[](#step-3)

This is the third step.

## Usage[](#usage)

Please note that this shortcode is intended **only for Markdown content**. If you put HTML content or other shortcodes as step content, it may not render as expected.

Put Markdown h3 header within `steps` shortcode.

```
{{% steps %}}

### Step 1

This is the first step.

### Step 2

This is the second step.

{{% /steps %}}
```

Last updated on September 6, 2025

[Others](/hextra/docs/guide/shortcodes/others/ "Others")[Tabs](/hextra/docs/guide/shortcodes/tabs/ "Tabs")

[Powered by Hextra](https://github.com/imfing/hextra "Hextra GitHub Homepage")

© 2025 Hextra Project.
```
```

```
Tool: webfetch

**Input:**
```json
{
  "format": "markdown",
  "url": "https://imfing.github.io/hextra/docs/guide/shortcodes/tabs/"
}
```
**Output:**
```
Tabs – Hextra

Hextra **v0.11** is here! 🎉 Discover [what’s new](https://imfing.github.io/hextra/blog/v0.11/)

  [![Logo](/hextra/images/logo.svg) ![Dark Logo](/hextra/images/logo-dark.svg) Hextra](/hextra/) [Documentation](/hextra/docs)

Versions

-   [Development ↗](https://imfing.github.io/hextra/versions/latest/)
-   [v0.10 ↗](https://imfing.github.io/hextra/versions/v0.10/)
-   [v0.9 ↗](https://imfing.github.io/hextra/versions/v0.9/)

[Blog](/hextra/blog) [About](/hextra/about) [Showcase](/hextra/showcase)

 CTRL K

[GitHub](https://github.com/imfing/hextra "GitHub")

 CTRL K

-   [About](/hextra/about/)
-   [Blog](/hextra/blog/)
    
    -   [Hextra v0.11](/hextra/blog/v0.11/)
    -   [Hextra v0.10](/hextra/blog/v0.10/)
    -   [Markdown Syntax Guide](/hextra/blog/markdown/)
    
-   [Documentation](/hextra/docs/)
    
    -   [Getting Started](/hextra/docs/getting-started/)
    -   [Guide](/hextra/docs/guide/)
        
        -   [Organize Files](/hextra/docs/guide/organize-files/)
        -   [Configuration](/hextra/docs/guide/configuration/)
        -   [Markdown](/hextra/docs/guide/markdown/)
        -   [Syntax Highlighting](/hextra/docs/guide/syntax-highlighting/)
        -   [LaTeX](/hextra/docs/guide/latex/)
        -   [Diagrams](/hextra/docs/guide/diagrams/)
        -   [Shortcodes](/hextra/docs/guide/shortcodes/)
            
            -   [Callout](/hextra/docs/guide/shortcodes/callout/)
            -   [Cards](/hextra/docs/guide/shortcodes/cards/)
            -   [Details](/hextra/docs/guide/shortcodes/details/)
            -   [FileTree](/hextra/docs/guide/shortcodes/filetree/)
            -   [Icon](/hextra/docs/guide/shortcodes/icon/)
            -   [Others](/hextra/docs/guide/shortcodes/others/)
            -   [Steps](/hextra/docs/guide/shortcodes/steps/)
            -   [Tabs](/hextra/docs/guide/shortcodes/tabs/)
                -   [Example](#example)
                -   [Usage](#usage)
            
        -   [Deploy Site](/hextra/docs/guide/deploy-site/)
        
    -   [Advanced](/hextra/docs/advanced/)
        
        -   [Multi-language](/hextra/docs/advanced/multi-language/)
        -   [Comments](/hextra/docs/advanced/comments/)
        -   [Customization](/hextra/docs/advanced/customization/)
        
    
-   [Showcase](/hextra/showcase/)
-   More
-   [About](/hextra/about)
-   [Hugo Docs ↗](https://gohugo.io/documentation/)

-   [Getting Started](/hextra/docs/getting-started/)
-   [Guide](/hextra/docs/guide/)
    
    -   [Organize Files](/hextra/docs/guide/organize-files/)
    -   [Configuration](/hextra/docs/guide/configuration/)
    -   [Markdown](/hextra/docs/guide/markdown/)
    -   [Syntax Highlighting](/hextra/docs/guide/syntax-highlighting/)
    -   [LaTeX](/hextra/docs/guide/latex/)
    -   [Diagrams](/hextra/docs/guide/diagrams/)
    -   [Shortcodes](/hextra/docs/guide/shortcodes/)
        
        -   [Callout](/hextra/docs/guide/shortcodes/callout/)
        -   [Cards](/hextra/docs/guide/shortcodes/cards/)
        -   [Details](/hextra/docs/guide/shortcodes/details/)
        -   [FileTree](/hextra/docs/guide/shortcodes/filetree/)
        -   [Icon](/hextra/docs/guide/shortcodes/icon/)
        -   [Others](/hextra/docs/guide/shortcodes/others/)
        -   [Steps](/hextra/docs/guide/shortcodes/steps/)
        -   [Tabs](/hextra/docs/guide/shortcodes/tabs/)
        
    -   [Deploy Site](/hextra/docs/guide/deploy-site/)
    
-   [Advanced](/hextra/docs/advanced/)
    
    -   [Multi-language](/hextra/docs/advanced/multi-language/)
    -   [Comments](/hextra/docs/advanced/comments/)
    -   [Customization](/hextra/docs/advanced/customization/)
    
-   More
-   [About](/hextra/about)
-   [Hugo Docs ↗](https://gohugo.io/documentation/)

English

-   [English](/hextra/docs/guide/shortcodes/tabs/)
-   [فارسی](/hextra/fa/docs/guide/shortcodes/tabs/)
-   [日本語](/hextra/ja/docs/guide/shortcodes/tabs/)
-   [简体中文](/hextra/zh-cn/docs/guide/shortcodes/tabs/)

-   Light
    
-   Dark
    
-   System
    

On this page

-   [Example](#example)
-   [Usage](#usage)
-   [Default](#default)
-   [Specify Selected Index](#specify-selected-index)
-   [Use Markdown](#use-markdown)
-   [Sync Tabs](#sync-tabs)

[Edit this page on GitHub →](https://github.com/imfing/hextra/edit/main/docs/content/docs/guide/shortcodes/tabs.md) Scroll to top

[Documentation](/hextra/docs/)

[Guide](/hextra/docs/guide/)

[Shortcodes](/hextra/docs/guide/shortcodes/)

Tabs

# Tabs

## Example[](#example)

macOSLinuxWindows

**macOS**: A desktop operating system by Apple.

**Linux**: An open-source operating system.

**Windows**: A desktop operating system by Microsoft.

## Usage[](#usage)

### Default[](#default)

```
{{< tabs items="JSON,YAML,TOML" >}}

  {{< tab >}}**JSON**: JavaScript Object Notation (JSON) is a standard text-based format for representing structured data based on JavaScript object syntax.{{< /tab >}}
  {{< tab >}}**YAML**: YAML is a human-readable data serialization language.{{< /tab >}}
  {{< tab >}}**TOML**: TOML aims to be a minimal configuration file format that's easy to read due to obvious semantics.{{< /tab >}}

{{< /tabs >}}
```

### Specify Selected Index[](#specify-selected-index)

Use `defaultIndex` property to specify the selected tab. The index starts from 0.

```
{{< tabs items="JSON,YAML,TOML" defaultIndex="1" >}}

  {{< tab >}}**JSON**: JavaScript Object Notation (JSON) is a standard text-based format for representing structured data based on JavaScript object syntax.{{< /tab >}}
  {{< tab >}}**YAML**: YAML is a human-readable data serialization language.{{< /tab >}}
  {{< tab >}}**TOML**: TOML aims to be a minimal configuration file format that's easy to read due to obvious semantics.{{< /tab >}}

{{< /tabs >}}
```

The `YAML` tab will be selected by default.

JSONYAMLTOML

**JSON**: JavaScript Object Notation (JSON) is a standard text-based format for representing structured data based on JavaScript object syntax.

**YAML**: YAML is a human-readable data serialization language.

**TOML**: TOML aims to be a minimal configuration file format that’s easy to read due to obvious semantics.

### Use Markdown[](#use-markdown)

Markdown syntax including code block is also supported:

```
{{< tabs items="JSON,YAML,TOML" >}}

  {{< tab >}}
  ```json
  { "hello": "world" }
  ```
  {{< /tab >}}

  ... add other tabs similarly

{{< /tabs >}}
```

JSONYAMLTOML

```json
{ "hello": "world" }
```

```yaml
hello: world
```

```toml
hello = "world"
```

### Sync Tabs[](#sync-tabs)

Tabs with the same list of `items` can be synchronized. When enabled, selecting a tab updates all other tabs with the same `items` and remembers the selection across pages.

Enable globally in your `hugo.yaml` under the `page` section:

hugo.yaml

```yaml
params:
  page:
    tabs:
      sync: true
```

With this enabled the following two tab blocks will always display the same selected item:

```markdown
{{< tabs items="A,B" >}}

  {{< tab >}}A content{{< /tab >}}
  {{< tab >}}B content{{< /tab >}}

{{< /tabs >}}

{{< tabs items="A,B" >}}

  {{< tab >}}Second A content{{< /tab >}}
  {{< tab >}}Second B content{{< /tab >}}

{{< /tabs >}}
```

Last updated on September 6, 2025

[Steps](/hextra/docs/guide/shortcodes/steps/ "Steps")[Deploy Site](/hextra/docs/guide/deploy-site/ "Deploy Site")

[Powered by Hextra](https://github.com/imfing/hextra "Hextra GitHub Homepage")

© 2025 Hextra Project.
```
```

---

## Assistant (Plan · claude-opus-4.5 · 22.5s)

Now I have a good understanding of the existing documentation style and hextra features. Let me present the plan.

---

## Proposed Plan: Video Streaming Spec Documentation

### Folder Structure

```
hugo/content/docs/reference/video-streaming/
├── _index.md                 # Overview with cards linking to sub-pages
├── encoding.md               # Video encoding requirements (H.264, keyframes, framerate)
├── container.md              # fMP4 structure, init segment, media segments
├── segments.md               # Segment rules, naming, boundaries
├── memory-buffer.md          # Server memory buffer behavior
├── disk-storage.md           # How segments are persisted to disk
├── metadata.md               # Metadata structure (in-stream and in-memory/DB)
├── transport.md              # WebSocket for live, HTTP for historical
├── join-flow.md              # How webview joins a stream
└── control-messages.md       # Keyframe requests, FPS change requests
```

### Document Contents Summary

| File | Content |
|------|---------|
| `_index.md` | Overview of the video streaming system, summary table of decisions, cards linking to each sub-page |
| `encoding.md` | H.264 profile/level, resolution constraints (max 1080p), framerate range (1/5 to 5 fps), keyframe behavior (on-demand + max interval + on FPS change) |
| `container.md` | fMP4 structure, initialization segment vs media segments, what metadata is embedded (timestamps, duration) |
| `segments.md` | When new segments are created, naming convention (`{clientId}-{sequence}.m4s`), variable duration rules |
| `memory-buffer.md` | 15-20 second configurable buffer, all segments starting with keyframes, eviction behavior |
| `disk-storage.md` | Segments written as-is, file structure on disk, no server-side processing |
| `metadata.md` | What's embedded in stream vs what's in memory/DB, index structure, periodic sync to DB |
| `transport.md` | WebSocket for live segment push, HTTP for historical segment fetch, binary vs message framing |
| `join-flow.md` | Steps for webview to join: request init segment, receive keyframe segment, continue stream |
| `control-messages.md` | On-demand keyframe request flow, FPS change request flow, segment boundary behavior |

### Hextra Features to Use

- **Cards** in `_index.md` for navigation (matching existing `websocket-comm/_index.md` style)
- **Tables** for structured data (parameters, message formats)
- **Callouts** for important notes and warnings
- **Steps** for flow descriptions (join flow, control message flows)
- **Code blocks** for JSON examples (metadata structure)
- **PlantUML diagrams** for sequence diagrams (matching existing `lifecycle.md` style)

### Questions Before Proceeding

1. **Naming**: The existing docs use "Sentinel" for client and "Proctor" for webview. Should the video streaming spec use the same terminology, or use generic terms like "client" and "webview"?

2. **Folder name**: Is `video-streaming` acceptable, or would you prefer something else like `stream-protocol` or `media-spec`?

3. **Depth of technical detail**: Should the spec include specific H.264 profile/level recommendations (e.g., "Baseline Profile, Level 3.1"), or leave that as implementation choice?

4. **Control messages**: Should the keyframe request and FPS change messages be documented here, or should they be added to the existing `websocket-comm` spec and cross-referenced?

---

## User

1. yes, use existing names like sentinel for client and proctor for webview, the server stays the server.
2. media-spec would be preferred
3. address the specific h.264 profile/level recommendations a little an what effects they have but that is just a recommendation.
4. Ignore the existing websocket-comm documentation completely and everything else content wise. everything you write down is only from our conversation, so the comms over websocket should be open to use json, xml or even protobuf.

any other questions

---

## Assistant (Plan · claude-opus-4.5 · 10.5s)

Good clarification on point 4. A few more questions before I finalize the plan:

### Message Format Questions

1. **Format agnostic spec**: Since you want the spec to be format-agnostic (JSON, XML, protobuf), should I document the messages as abstract structures (field names + types + descriptions) without specific serialization examples, or should I include examples in one format (e.g., JSON) with a note that other formats are acceptable?

2. **Binary data**: For the actual video segment data being sent over WebSocket, is this:
   - Raw binary (segment bytes sent as a binary WebSocket frame)
   - Base64 encoded within a message envelope
   - Or should the spec leave this open?

### Scope Clarification

3. **Init segment delivery**: When the webview requests an init segment, is this via:
   - A control message over the existing WebSocket connection
   - A separate HTTP request
   - Or should the spec define both options?

4. **Historical segments (HTTP)**: For fetching older segments from disk, should the spec define the HTTP endpoint structure (e.g., `GET /sessions/{clientId}/segments/{sequence}`) or just describe what information is needed to fetch a segment?

### Documentation Depth

5. **Sequence diagrams**: Should I include PlantUML sequence diagrams for:
   - Webview join flow
   - On-demand keyframe request
   - FPS change request
   
   Or is prose with steps sufficient?

---

## User

1. use json as example but use generic field names + types and descriptions. but do not be influenced by structures anywhere else in the hugo documentation.
2. spec leaves this option. how the data is transferred and the format is not the specs matter.
3. a controll message over websocket as all live aspects should be as already mentioned.
4. define only the information needed but not how the endpoints should be defined.
5. yeah, plantuml diagrams are nice so include them where it is very easy to explain things using diagrams.

---

## Assistant (Plan · claude-opus-4.5 · 19.4s)

Good, I have all the information I need. Here's the final plan:

---

## Final Plan: Media Streaming Specification

### Folder Structure

```
hugo/content/docs/reference/media-spec/
├── _index.md              # Overview + navigation cards
├── encoding.md            # H.264 encoding requirements
├── container.md           # fMP4 structure
├── segments.md            # Segment creation rules + naming
├── memory-buffer.md       # Server memory buffer behavior
├── disk-storage.md        # Disk persistence format
├── metadata.md            # Metadata structure (in-stream + in-memory/DB)
├── transport.md           # WebSocket (live) + HTTP (historical)
├── join-flow.md           # Proctor joining a Sentinel stream
└── control-messages.md    # Keyframe + FPS change requests
```

### Document Details

| File | Summary |
|------|---------|
| **_index.md** | Overview of the streaming system, summary table of all decisions, cards linking to sub-pages |
| **encoding.md** | H.264 codec, profile/level recommendations with tradeoff explanations, resolution (max 1080p, aspect preserved), framerate (1/5 to 5 fps, variable per segment, fixed within segment), keyframe rules (on-demand, max 20-30s, on FPS change) |
| **container.md** | fMP4 format, initialization segment (once per session, contains codec/resolution info), media segments (contain frames + timing), what's embedded (timestamps, duration) |
| **segments.md** | New segment triggers (keyframe, FPS change), naming convention (`{clientId}-{sequence}.m4s`), variable duration, sequence numbers controlled by Sentinel |
| **memory-buffer.md** | Configurable 15-20 second buffer, stores all segments starting with keyframes from that window, eviction by garbage collection, purpose: fast Proctor join |
| **disk-storage.md** | Segments written as-is (no server processing), file organization on disk, retention (not specified, implementation choice) |
| **metadata.md** | In-stream: timestamps, duration (browser-required). In-memory/DB: client ID, sequence, framerate, segment file path, start time. Periodic sync to DB for persistence. |
| **transport.md** | WebSocket for live (server pushes segments to Proctor as they arrive), HTTP for historical (Proctor fetches older segments from disk). Spec defines what data is needed, not endpoint structure. |
| **join-flow.md** | Steps + PlantUML diagram: Proctor requests stream → Server sends init segment → Server sends latest keyframe segment → Server continues pushing new segments |
| **control-messages.md** | Two flows with PlantUML diagrams: (1) On-demand keyframe request (Proctor → Server → Sentinel), (2) FPS change request (Server → Sentinel). Abstract message structures with JSON examples. |

### Style Conventions

- Use **Sentinel** (not client) for the screen capture application
- Use **Proctor** (not webview) for the viewer
- Use **Server** for the relay/storage component
- Message structures as tables (field, type, required, description) with JSON examples
- PlantUML sequence diagrams for flows
- Callouts for important notes and recommendations
- No dependency on existing `websocket-comm` documentation

### H.264 Profile/Level Coverage

Will include a brief section recommending:
- **Baseline Profile** for maximum compatibility (weaker hardware, all browsers)
- **Main Profile** as alternative if hardware encoding supports it (better compression)
- **Level 3.1** sufficient for 1080p at low framerates
- Note that these are recommendations, not requirements

---

Ready to proceed when you give the go-ahead.

---

## User

go ahead and create the documentation

---

## Assistant (Build · claude-opus-4.5 · 7.0s)

```
Tool: todowrite

**Input:**
```json
{
  "todos": [
    {
      "id": "1",
      "content": "Create _index.md - Overview + navigation cards",
      "status": "in_progress",
      "priority": "high"
    },
    {
      "id": "2",
      "content": "Create encoding.md - H.264 encoding requirements",
      "status": "pending",
      "priority": "high"
    },
    {
      "id": "3",
      "content": "Create container.md - fMP4 structure",
      "status": "pending",
      "priority": "high"
    },
    {
      "id": "4",
      "content": "Create segments.md - Segment creation rules + naming",
      "status": "pending",
      "priority": "high"
    },
    {
      "id": "5",
      "content": "Create memory-buffer.md - Server memory buffer behavior",
      "status": "pending",
      "priority": "high"
    },
    {
      "id": "6",
      "content": "Create disk-storage.md - Disk persistence format",
      "status": "pending",
      "priority": "high"
    },
    {
      "id": "7",
      "content": "Create metadata.md - Metadata structure",
      "status": "pending",
      "priority": "high"
    },
    {
      "id": "8",
      "content": "Create transport.md - WebSocket + HTTP transport",
      "status": "pending",
      "priority": "high"
    },
    {
      "id": "9",
      "content": "Create join-flow.md - Proctor joining a Sentinel stream",
      "status": "pending",
      "priority": "high"
    },
    {
      "id": "10",
      "content": "Create control-messages.md - Keyframe + FPS change requests",
      "status": "pending",
      "priority": "high"
    }
  ]
}
```
**Output:**
```
[
  {
    "id": "1",
    "content": "Create _index.md - Overview + navigation cards",
    "status": "in_progress",
    "priority": "high"
  },
  {
    "id": "2",
    "content": "Create encoding.md - H.264 encoding requirements",
    "status": "pending",
    "priority": "high"
  },
  {
    "id": "3",
    "content": "Create container.md - fMP4 structure",
    "status": "pending",
    "priority": "high"
  },
  {
    "id": "4",
    "content": "Create segments.md - Segment creation rules + naming",
    "status": "pending",
    "priority": "high"
  },
  {
    "id": "5",
    "content": "Create memory-buffer.md - Server memory buffer behavior",
    "status": "pending",
    "priority": "high"
  },
  {
    "id": "6",
    "content": "Create disk-storage.md - Disk persistence format",
    "status": "pending",
    "priority": "high"
  },
  {
    "id": "7",
    "content": "Create metadata.md - Metadata structure",
    "status": "pending",
    "priority": "high"
  },
  {
    "id": "8",
    "content": "Create transport.md - WebSocket + HTTP transport",
    "status": "pending",
    "priority": "high"
  },
  {
    "id": "9",
    "content": "Create join-flow.md - Proctor joining a Sentinel stream",
    "status": "pending",
    "priority": "high"
  },
  {
    "id": "10",
    "content": "Create control-messages.md - Keyframe + FPS change requests",
    "status": "pending",
    "priority": "high"
  }
]
```
```

---

## Assistant (Build · claude-opus-4.5 · 7.7s)

```
Tool: bash

**Input:**
```json
{
  "command": "mkdir -p /home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec",
  "description": "Create media-spec directory"
}
```
```

---

## Assistant (Build · claude-opus-4.5 · 12.2s)

```
Tool: write

**Input:**
```json
{
  "filePath": "/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/_index.md",
  "content": "---\ntitle: Media Streaming Spec\n---\n\nThis specification defines how video is encoded, segmented, stored, and delivered for real-time screen sharing between Sentinels and Proctors.\n\n## Overview\n\n| Aspect | Decision |\n|--------|----------|\n| **Codec** | H.264 |\n| **Container** | Fragmented MP4 (fMP4) |\n| **Browser Delivery** | Media Source Extensions (MSE) |\n| **Segment Duration** | Variable (new segment on each keyframe) |\n| **Keyframes** | On-demand + max 20-30s interval + on FPS change |\n| **Memory Buffer** | All segments from last 15-20 seconds (configurable) |\n| **Disk Storage** | All segments written as-is |\n| **Resolution** | Max 1080p, downscaled preserving aspect ratio |\n| **Framerate** | 1/5 fps to 5 fps, variable per session, fixed per segment |\n| **Live Transport** | WebSocket (server pushes segments) |\n| **Historical Transport** | HTTP (Proctor fetches from disk) |\n\n## Components\n\n- **Sentinel**: Captures screen, encodes video, sends segments to Server\n- **Server**: Receives segments, buffers in memory, writes to disk, relays to Proctors\n- **Proctor**: Receives segments, decodes via MSE, displays video\n\n## Documentation\n\n{{< cards >}}\n{{< card link=\"encoding\" title=\"Encoding\" icon=\"chip\" subtitle=\"H.264 codec settings and framerate\" >}}\n{{< card link=\"container\" title=\"Container\" icon=\"archive\" subtitle=\"fMP4 structure and initialization\" >}}\n{{< card link=\"segments\" title=\"Segments\" icon=\"collection\" subtitle=\"Segment creation and naming\" >}}\n{{< card link=\"memory-buffer\" title=\"Memory Buffer\" icon=\"server\" subtitle=\"Server-side buffering for live streams\" >}}\n{{< card link=\"disk-storage\" title=\"Disk Storage\" icon=\"database\" subtitle=\"Persistent segment storage\" >}}\n{{< card link=\"metadata\" title=\"Metadata\" icon=\"document-text\" subtitle=\"In-stream and application metadata\" >}}\n{{< card link=\"transport\" title=\"Transport\" icon=\"switch-horizontal\" subtitle=\"WebSocket and HTTP delivery\" >}}\n{{< card link=\"join-flow\" title=\"Join Flow\" icon=\"login\" subtitle=\"How Proctors join a stream\" >}}\n{{< card link=\"control-messages\" title=\"Control Messages\" icon=\"adjustments\" subtitle=\"Keyframe and FPS change requests\" >}}\n{{< /cards >}}\n"
}
```
**Output:**
```
Wrote file successfully.
```
```

---

## Assistant (Build · claude-opus-4.5 · 7.6s)

```
Tool: todowrite

**Input:**
```json
{
  "todos": [
    {
      "content": "Create _index.md - Overview + navigation cards",
      "id": "1",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create encoding.md - H.264 encoding requirements",
      "id": "2",
      "priority": "high",
      "status": "in_progress"
    },
    {
      "content": "Create container.md - fMP4 structure",
      "id": "3",
      "priority": "high",
      "status": "pending"
    },
    {
      "content": "Create segments.md - Segment creation rules + naming",
      "id": "4",
      "priority": "high",
      "status": "pending"
    },
    {
      "content": "Create memory-buffer.md - Server memory buffer behavior",
      "id": "5",
      "priority": "high",
      "status": "pending"
    },
    {
      "content": "Create disk-storage.md - Disk persistence format",
      "id": "6",
      "priority": "high",
      "status": "pending"
    },
    {
      "content": "Create metadata.md - Metadata structure",
      "id": "7",
      "priority": "high",
      "status": "pending"
    },
    {
      "content": "Create transport.md - WebSocket + HTTP transport",
      "id": "8",
      "priority": "high",
      "status": "pending"
    },
    {
      "content": "Create join-flow.md - Proctor joining a Sentinel stream",
      "id": "9",
      "priority": "high",
      "status": "pending"
    },
    {
      "content": "Create control-messages.md - Keyframe + FPS change requests",
      "id": "10",
      "priority": "high",
      "status": "pending"
    }
  ]
}
```
**Output:**
```
[
  {
    "content": "Create _index.md - Overview + navigation cards",
    "id": "1",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create encoding.md - H.264 encoding requirements",
    "id": "2",
    "priority": "high",
    "status": "in_progress"
  },
  {
    "content": "Create container.md - fMP4 structure",
    "id": "3",
    "priority": "high",
    "status": "pending"
  },
  {
    "content": "Create segments.md - Segment creation rules + naming",
    "id": "4",
    "priority": "high",
    "status": "pending"
  },
  {
    "content": "Create memory-buffer.md - Server memory buffer behavior",
    "id": "5",
    "priority": "high",
    "status": "pending"
  },
  {
    "content": "Create disk-storage.md - Disk persistence format",
    "id": "6",
    "priority": "high",
    "status": "pending"
  },
  {
    "content": "Create metadata.md - Metadata structure",
    "id": "7",
    "priority": "high",
    "status": "pending"
  },
  {
    "content": "Create transport.md - WebSocket + HTTP transport",
    "id": "8",
    "priority": "high",
    "status": "pending"
  },
  {
    "content": "Create join-flow.md - Proctor joining a Sentinel stream",
    "id": "9",
    "priority": "high",
    "status": "pending"
  },
  {
    "content": "Create control-messages.md - Keyframe + FPS change requests",
    "id": "10",
    "priority": "high",
    "status": "pending"
  }
]
```
```

---

## Assistant (Build · claude-opus-4.5 · 24.4s)

```
Tool: write

**Input:**
```json
{
  "content": "---\ntitle: Encoding\n---\n\nThis document specifies the video encoding requirements for Sentinel screen capture.\n\n## Codec\n\n**H.264 (AVC)** is the required codec for all video streams.\n\n### Why H.264\n\n- Universal hardware decoding support (Intel Quick Sync, NVIDIA NVENC, AMD VCE)\n- Native playback in all modern browsers via MSE\n- Low CPU overhead when hardware encoding is available\n- Widely supported on school/institutional hardware\n\n## Profile and Level\n\n{{< callout type=\"info\" >}}\nThese are recommendations. Implementations may adjust based on hardware capabilities.\n{{< /callout >}}\n\n### Recommended: Baseline Profile\n\n| Setting | Value | Rationale |\n|---------|-------|-----------|\n| Profile | Baseline | Maximum decoder compatibility, simpler encoding |\n| Level | 3.1 | Supports 1080p at low framerates |\n\n**Tradeoffs:**\n- Baseline lacks B-frames, resulting in slightly larger files\n- Guaranteed to decode on all hardware, including older/weaker devices\n- Fastest encoding speed\n\n### Alternative: Main Profile\n\n| Setting | Value | Rationale |\n|---------|-------|-----------|\n| Profile | Main | Better compression via B-frames and CABAC |\n| Level | 3.1 | Supports 1080p at low framerates |\n\n**Tradeoffs:**\n- 10-20% smaller file sizes than Baseline\n- Requires slightly more capable hardware for encoding\n- Still universally supported for decoding in browsers\n\n### Level Reference\n\n| Level | Max Resolution | Max Framerate | Notes |\n|-------|----------------|---------------|-------|\n| 3.0 | 1280x720 | 30 fps | Sufficient for 720p |\n| 3.1 | 1920x1080 | 30 fps | Recommended for 1080p |\n| 4.0 | 2048x1024 | 30 fps | Overkill for this use case |\n\n## Resolution\n\n| Constraint | Value |\n|------------|-------|\n| Maximum | 1920x1080 (Full HD) |\n| Aspect Ratio | Preserved from source |\n| Downscaling | Required if source exceeds 1080p |\n\nThe Sentinel must downscale captured frames to fit within 1920x1080 while preserving the original aspect ratio. For example, a 2560x1440 capture would be downscaled to 1920x1080.\n\n## Framerate\n\n| Parameter | Value |\n|-----------|-------|\n| Minimum | 0.2 fps (1 frame per 5 seconds) |\n| Maximum | 5 fps |\n| Variability | Can change between segments, fixed within a segment |\n\n### Variable Framerate Behavior\n\n- Framerate is constant within a single segment\n- Framerate can change at segment boundaries (triggered by FPS change request)\n- Each frame carries a timestamp for accurate playback timing\n- Players must use frame timestamps, not assume constant framerate\n\n### FPS Change Triggers\n\nThe Server may request a framerate change from the Sentinel. Common reasons:\n- Server under heavy load (reduce FPS to reduce message volume)\n- Network congestion detected\n- Administrative policy change\n\nWhen FPS changes, a new segment must begin (see [Segments](../segments)).\n\n## Keyframes (I-Frames)\n\nKeyframes are complete frames that can be decoded independently without reference to previous frames.\n\n### Keyframe Rules\n\n| Rule | Description |\n|------|-------------|\n| On-demand | Sentinel must generate a keyframe when requested by Server |\n| Maximum interval | At least one keyframe every 20-30 seconds |\n| On FPS change | New segment (starting with keyframe) when framerate changes |\n\n### Why On-Demand Keyframes\n\n- Allows Proctors to join streams quickly without waiting for the next scheduled keyframe\n- Enables predictive pre-fetching (Proctor requests keyframe before switching streams)\n- Minimizes unnecessary keyframes, reducing bandwidth\n\n### IDR Frames\n\nAll keyframes must be **IDR (Instantaneous Decoder Refresh)** frames, not just I-frames. IDR frames clear the decoder reference buffer, ensuring clean entry points for new viewers.\n",
  "filePath": "/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/encoding.md"
}
```
**Output:**
```
Wrote file successfully.
```
```

---

## Assistant (Build · claude-opus-4.5 · 5.6s)

```
Tool: todowrite

**Input:**
```json
{
  "todos": [
    {
      "content": "Create _index.md - Overview + navigation cards",
      "id": "1",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create encoding.md - H.264 encoding requirements",
      "id": "2",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create container.md - fMP4 structure",
      "id": "3",
      "priority": "high",
      "status": "in_progress"
    },
    {
      "content": "Create segments.md - Segment creation rules + naming",
      "id": "4",
      "priority": "high",
      "status": "pending"
    },
    {
      "content": "Create memory-buffer.md - Server memory buffer behavior",
      "id": "5",
      "priority": "high",
      "status": "pending"
    },
    {
      "content": "Create disk-storage.md - Disk persistence format",
      "id": "6",
      "priority": "high",
      "status": "pending"
    },
    {
      "content": "Create metadata.md - Metadata structure",
      "id": "7",
      "priority": "high",
      "status": "pending"
    },
    {
      "content": "Create transport.md - WebSocket + HTTP transport",
      "id": "8",
      "priority": "high",
      "status": "pending"
    },
    {
      "content": "Create join-flow.md - Proctor joining a Sentinel stream",
      "id": "9",
      "priority": "high",
      "status": "pending"
    },
    {
      "content": "Create control-messages.md - Keyframe + FPS change requests",
      "id": "10",
      "priority": "high",
      "status": "pending"
    }
  ]
}
```
**Output:**
```
[
  {
    "content": "Create _index.md - Overview + navigation cards",
    "id": "1",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create encoding.md - H.264 encoding requirements",
    "id": "2",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create container.md - fMP4 structure",
    "id": "3",
    "priority": "high",
    "status": "in_progress"
  },
  {
    "content": "Create segments.md - Segment creation rules + naming",
    "id": "4",
    "priority": "high",
    "status": "pending"
  },
  {
    "content": "Create memory-buffer.md - Server memory buffer behavior",
    "id": "5",
    "priority": "high",
    "status": "pending"
  },
  {
    "content": "Create disk-storage.md - Disk persistence format",
    "id": "6",
    "priority": "high",
    "status": "pending"
  },
  {
    "content": "Create metadata.md - Metadata structure",
    "id": "7",
    "priority": "high",
    "status": "pending"
  },
  {
    "content": "Create transport.md - WebSocket + HTTP transport",
    "id": "8",
    "priority": "high",
    "status": "pending"
  },
  {
    "content": "Create join-flow.md - Proctor joining a Sentinel stream",
    "id": "9",
    "priority": "high",
    "status": "pending"
  },
  {
    "content": "Create control-messages.md - Keyframe + FPS change requests",
    "id": "10",
    "priority": "high",
    "status": "pending"
  }
]
```
```

---

## Assistant (Build · claude-opus-4.5 · 26.8s)

```
Tool: write

**Input:**
```json
{
  "content": "---\ntitle: Container\n---\n\nThis document specifies the container format for video segments.\n\n## Format: Fragmented MP4 (fMP4)\n\nAll video data is packaged in **Fragmented MP4** format. This is a variant of the standard MP4 container optimized for streaming.\n\n### Why fMP4\n\n- Native support in browser Media Source Extensions (MSE)\n- No transcoding needed on Server or Proctor\n- Segments can be played independently (with initialization data)\n- Industry standard for adaptive streaming (DASH, HLS)\n\n## Structure Overview\n\nAn fMP4 stream consists of two types of data:\n\n| Type | Purpose | When Sent |\n|------|---------|-----------|\n| **Initialization Segment** | Contains codec configuration, resolution, timescale | Once per session, on Proctor join |\n| **Media Segment** | Contains actual video frames and timing | Continuously during streaming |\n\n```\n┌─────────────────────────┐\n│  Initialization Segment │  ← Sent once per session\n│  (ftyp + moov boxes)    │\n└─────────────────────────┘\n           │\n           ▼\n┌─────────────────────────┐\n│    Media Segment 1      │  ← Starts with keyframe\n│  (moof + mdat boxes)    │\n└─────────────────────────┘\n           │\n           ▼\n┌─────────────────────────┐\n│    Media Segment 2      │  ← Starts with keyframe\n│  (moof + mdat boxes)    │\n└─────────────────────────┘\n           │\n           ▼\n          ...\n```\n\n## Initialization Segment\n\nThe initialization segment contains metadata required to configure the decoder. It does not contain any video frames.\n\n### Contents\n\n| Box | Purpose |\n|-----|---------|\n| `ftyp` | File type declaration (brand: `iso5` or `isom`) |\n| `moov` | Movie header containing codec and track information |\n\n### Key Information in `moov`\n\n- **Codec parameters**: H.264 SPS/PPS (Sequence/Picture Parameter Sets)\n- **Resolution**: Width and height in pixels\n- **Timescale**: Time units per second for timestamps\n\n### Lifetime\n\n- Generated once when the Sentinel starts a session\n- Remains valid for the entire session\n- Resolution and codec parameters do not change mid-session\n- Server caches in memory for each active Sentinel\n- Sent to Proctor on stream join request\n\n## Media Segments\n\nEach media segment contains one or more video frames packaged for streaming.\n\n### Contents\n\n| Box | Purpose |\n|-----|---------|\n| `moof` | Movie fragment header (timing, frame offsets) |\n| `mdat` | Media data (actual H.264 NAL units) |\n\n### Requirements\n\n| Requirement | Description |\n|-------------|-------------|\n| Starts with keyframe | Every media segment must begin with an IDR frame |\n| Self-contained timing | Timestamps in `moof` are absolute (not relative to previous segment) |\n| Variable duration | Segments can have different durations |\n| Fixed framerate per segment | Framerate is constant within a segment |\n\n### Timing Information\n\nThe `moof` box contains a `tfdt` (Track Fragment Decode Time) box specifying the decode timestamp of the first frame. Each frame's duration is specified in the `trun` (Track Fragment Run) box.\n\n{{< callout type=\"info\" >}}\nThe timescale from the initialization segment determines how timestamps map to wall-clock time. A common choice is 90000 (90kHz), allowing sub-millisecond precision.\n{{< /callout >}}\n\n## Proctor Playback\n\nTo play a stream, the Proctor must:\n\n{{% steps %}}\n\n### Receive Initialization Segment\n\nObtain the initialization segment for the target Sentinel from the Server.\n\n### Initialize MSE SourceBuffer\n\nCreate a `MediaSource`, add a `SourceBuffer` with the appropriate MIME type, and append the initialization segment.\n\n```javascript\n// Example MIME type for H.264 in fMP4\n\"video/mp4; codecs=\\\"avc1.42E01F\\\"\"\n```\n\n### Append Media Segments\n\nAs media segments arrive, append them to the `SourceBuffer` in order.\n\n### Handle Playback\n\nThe browser's video element handles decoding and rendering automatically.\n\n{{% /steps %}}\n\n## MIME Type\n\nThe MIME type for MSE must specify both the container and codec:\n\n```\nvideo/mp4; codecs=\"avc1.PPCCLL\"\n```\n\nWhere `PPCCLL` is the H.264 profile/level indicator:\n- `42` = Baseline profile\n- `4D` = Main profile\n- `E01F` = Level 3.1\n\nExample for Baseline Profile, Level 3.1:\n```\nvideo/mp4; codecs=\"avc1.42E01F\"\n```\n\nExample for Main Profile, Level 3.1:\n```\nvideo/mp4; codecs=\"avc1.4D401F\"\n```\n",
  "filePath": "/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/container.md"
}
```
**Output:**
```
Wrote file successfully.
```
```

---

## Assistant (Build · claude-opus-4.5 · 7.8s)

```
Tool: todowrite

**Input:**
```json
{
  "todos": [
    {
      "content": "Create _index.md - Overview + navigation cards",
      "id": "1",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create encoding.md - H.264 encoding requirements",
      "id": "2",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create container.md - fMP4 structure",
      "id": "3",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create segments.md - Segment creation rules + naming",
      "id": "4",
      "priority": "high",
      "status": "in_progress"
    },
    {
      "content": "Create memory-buffer.md - Server memory buffer behavior",
      "id": "5",
      "priority": "high",
      "status": "pending"
    },
    {
      "content": "Create disk-storage.md - Disk persistence format",
      "id": "6",
      "priority": "high",
      "status": "pending"
    },
    {
      "content": "Create metadata.md - Metadata structure",
      "id": "7",
      "priority": "high",
      "status": "pending"
    },
    {
      "content": "Create transport.md - WebSocket + HTTP transport",
      "id": "8",
      "priority": "high",
      "status": "pending"
    },
    {
      "content": "Create join-flow.md - Proctor joining a Sentinel stream",
      "id": "9",
      "priority": "high",
      "status": "pending"
    },
    {
      "content": "Create control-messages.md - Keyframe + FPS change requests",
      "id": "10",
      "priority": "high",
      "status": "pending"
    }
  ]
}
```
**Output:**
```
[
  {
    "content": "Create _index.md - Overview + navigation cards",
    "id": "1",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create encoding.md - H.264 encoding requirements",
    "id": "2",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create container.md - fMP4 structure",
    "id": "3",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create segments.md - Segment creation rules + naming",
    "id": "4",
    "priority": "high",
    "status": "in_progress"
  },
  {
    "content": "Create memory-buffer.md - Server memory buffer behavior",
    "id": "5",
    "priority": "high",
    "status": "pending"
  },
  {
    "content": "Create disk-storage.md - Disk persistence format",
    "id": "6",
    "priority": "high",
    "status": "pending"
  },
  {
    "content": "Create metadata.md - Metadata structure",
    "id": "7",
    "priority": "high",
    "status": "pending"
  },
  {
    "content": "Create transport.md - WebSocket + HTTP transport",
    "id": "8",
    "priority": "high",
    "status": "pending"
  },
  {
    "content": "Create join-flow.md - Proctor joining a Sentinel stream",
    "id": "9",
    "priority": "high",
    "status": "pending"
  },
  {
    "content": "Create control-messages.md - Keyframe + FPS change requests",
    "id": "10",
    "priority": "high",
    "status": "pending"
  }
]
```
```

---

## Assistant (Build · claude-opus-4.5 · 22.9s)

```
Tool: write

**Input:**
```json
{
  "content": "---\ntitle: Segments\n---\n\nThis document specifies when segments are created, how they are named, and their structure.\n\n## Segment Definition\n\nA **segment** is a single fMP4 media segment containing one or more video frames. Each segment:\n\n- Starts with a keyframe (IDR frame)\n- Has a fixed framerate throughout\n- Has variable duration\n- Is independently decodable (with the initialization segment)\n\n## Segment Creation Triggers\n\nA new segment is created when any of the following occur:\n\n| Trigger | Description |\n|---------|-------------|\n| **Keyframe generated** | Any keyframe (scheduled or on-demand) starts a new segment |\n| **FPS change** | Framerate change request forces a keyframe and new segment |\n| **Maximum interval reached** | If no keyframe has occurred in 20-30 seconds, one is forced |\n\n```\nTimeline:\n├── Segment 1 ──────────┼── Segment 2 ────┼── Segment 3 ──────────────┤\n│   [KF]...[F]...[F]    │   [KF]...[F]    │   [KF]...[F]...[F]...[F]  │\n│                       │                 │                           │\n└─ Scheduled keyframe   └─ On-demand      └─ FPS change triggered\n                           keyframe          keyframe\n```\n\n*KF = Keyframe, F = Frame*\n\n## Sequence Numbers\n\nEach Sentinel maintains a **sequence counter** for its segments.\n\n| Property | Value |\n|----------|-------|\n| Start value | 0 |\n| Increment | 1 per segment |\n| Scope | Per Sentinel, per session |\n| Controller | Sentinel (not Server) |\n\nThe sequence number is assigned by the Sentinel when the segment is created and included in the segment metadata sent to the Server.\n\n## Naming Convention\n\nSegments are identified by the combination of Sentinel ID and sequence number.\n\n### Format\n\n```\n{sentinelId}-{sequence}.m4s\n```\n\n| Component | Description | Example |\n|-----------|-------------|---------|\n| `sentinelId` | Unique identifier for the Sentinel | `sentinel-a1b2c3` |\n| `sequence` | Zero-padded sequence number | `000142` |\n| Extension | `.m4s` for media segments | |\n\n### Examples\n\n```\nsentinel-a1b2c3-000000.m4s   # First segment\nsentinel-a1b2c3-000001.m4s   # Second segment\nsentinel-a1b2c3-000142.m4s   # 143rd segment\n```\n\n### Initialization Segment Naming\n\nThe initialization segment uses a distinct name:\n\n```\n{sentinelId}-init.mp4\n```\n\nExample:\n```\nsentinel-a1b2c3-init.mp4\n```\n\n## Segment Duration\n\nSegment duration is **variable** and depends on when keyframes occur.\n\n| Scenario | Typical Duration |\n|----------|------------------|\n| Normal operation (no on-demand keyframes) | 20-30 seconds |\n| Frequent Proctor joins | Shorter segments due to on-demand keyframes |\n| FPS changes | Segment ends immediately, new segment begins |\n\n{{< callout type=\"warning\" >}}\nThere is no guaranteed minimum or maximum segment duration. Implementations should handle segments of any duration.\n{{< /callout >}}\n\n## Segment Contents\n\nEach media segment contains:\n\n| Content | Location | Description |\n|---------|----------|-------------|\n| Decode timestamp | `moof` → `tfdt` | Absolute timestamp of first frame |\n| Frame durations | `moof` → `trun` | Duration of each frame in segment |\n| Frame data | `mdat` | Encoded H.264 NAL units |\n\n### Frame Timestamps\n\nEvery frame within a segment has a precise timestamp derived from:\n\n1. The segment's base decode time (`tfdt`)\n2. The cumulative duration of preceding frames (`trun` sample durations)\n\nThis allows accurate playback timing regardless of variable framerate across segments.\n\n## Relationship to Sessions\n\nA **session** is the period from when a Sentinel connects to when it disconnects.\n\n| Session Event | Segment Behavior |\n|---------------|------------------|\n| Session start | Sequence resets to 0, new initialization segment created |\n| Session continues | Sequence increments with each segment |\n| Session ends | Final segment may be shorter than normal |\n\n{{< callout type=\"info\" >}}\nIf a Sentinel reconnects (new session), it generates a new initialization segment and restarts sequence numbering at 0. The Server treats this as a new stream.\n{{< /callout >}}\n",
  "filePath": "/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/segments.md"
}
```
**Output:**
```
Wrote file successfully.
```
```

---

## Assistant (Build · claude-opus-4.5 · 6.2s)

```
Tool: todowrite

**Input:**
```json
{
  "todos": [
    {
      "content": "Create _index.md - Overview + navigation cards",
      "id": "1",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create encoding.md - H.264 encoding requirements",
      "id": "2",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create container.md - fMP4 structure",
      "id": "3",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create segments.md - Segment creation rules + naming",
      "id": "4",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create memory-buffer.md - Server memory buffer behavior",
      "id": "5",
      "priority": "high",
      "status": "in_progress"
    },
    {
      "content": "Create disk-storage.md - Disk persistence format",
      "id": "6",
      "priority": "high",
      "status": "pending"
    },
    {
      "content": "Create metadata.md - Metadata structure",
      "id": "7",
      "priority": "high",
      "status": "pending"
    },
    {
      "content": "Create transport.md - WebSocket + HTTP transport",
      "id": "8",
      "priority": "high",
      "status": "pending"
    },
    {
      "content": "Create join-flow.md - Proctor joining a Sentinel stream",
      "id": "9",
      "priority": "high",
      "status": "pending"
    },
    {
      "content": "Create control-messages.md - Keyframe + FPS change requests",
      "id": "10",
      "priority": "high",
      "status": "pending"
    }
  ]
}
```
**Output:**
```
[
  {
    "content": "Create _index.md - Overview + navigation cards",
    "id": "1",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create encoding.md - H.264 encoding requirements",
    "id": "2",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create container.md - fMP4 structure",
    "id": "3",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create segments.md - Segment creation rules + naming",
    "id": "4",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create memory-buffer.md - Server memory buffer behavior",
    "id": "5",
    "priority": "high",
    "status": "in_progress"
  },
  {
    "content": "Create disk-storage.md - Disk persistence format",
    "id": "6",
    "priority": "high",
    "status": "pending"
  },
  {
    "content": "Create metadata.md - Metadata structure",
    "id": "7",
    "priority": "high",
    "status": "pending"
  },
  {
    "content": "Create transport.md - WebSocket + HTTP transport",
    "id": "8",
    "priority": "high",
    "status": "pending"
  },
  {
    "content": "Create join-flow.md - Proctor joining a Sentinel stream",
    "id": "9",
    "priority": "high",
    "status": "pending"
  },
  {
    "content": "Create control-messages.md - Keyframe + FPS change requests",
    "id": "10",
    "priority": "high",
    "status": "pending"
  }
]
```
```

---

## Assistant (Build · claude-opus-4.5 · 26.2s)

```
Tool: write

**Input:**
```json
{
  "content": "---\ntitle: Memory Buffer\n---\n\nThis document specifies how the Server buffers segments in memory for live streaming.\n\n## Purpose\n\nThe memory buffer serves two purposes:\n\n1. **Fast Proctor joins**: Proctors can immediately receive recent segments without disk I/O\n2. **Network resilience**: Proctors with slower connections can catch up from buffered segments\n\n## Buffer Requirements\n\n| Parameter | Value | Notes |\n|-----------|-------|-------|\n| Buffer window | 15-20 seconds | Configurable |\n| Contents | All segments with start time within the window | |\n| Scope | Per Sentinel | Each Sentinel has its own buffer |\n| Storage | Memory only | No disk I/O for live streaming |\n\n## What is Buffered\n\nFor each active Sentinel, the Server maintains in memory:\n\n| Item | Description |\n|------|-------------|\n| **Initialization segment** | The codec/resolution configuration for the session |\n| **Recent media segments** | All segments whose start timestamp falls within the buffer window |\n| **Segment metadata** | See [Metadata](../metadata) for details |\n\n```\nBuffer Window (15-20 seconds)\n◄──────────────────────────────────────────────►\n\n┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌───\n│ Seg N-3│ │ Seg N-2│ │ Seg N-1│ │ Seg N  │ │ ...\n└────────┘ └────────┘ └────────┘ └────────┘ └───\n     │          │          │          │\n     └──────────┴──────────┴──────────┴── All in memory\n\n                                         ▲\n                                         │\n                                    Most recent\n```\n\n## Eviction\n\nSegments are evicted from the buffer when they fall outside the buffer window.\n\n| Behavior | Description |\n|----------|-------------|\n| Trigger | Segment's start timestamp is older than `now - buffer_window` |\n| Action | Remove from memory buffer |\n| Disk impact | None (segment was already written to disk when received) |\n| Method | Garbage collection or explicit removal (implementation choice) |\n\n{{< callout type=\"info\" >}}\nThe spec does not mandate a specific eviction strategy. Implementations may use lazy garbage collection, periodic cleanup, or immediate removal. The only requirement is that segments older than the buffer window are not required to remain in memory.\n{{< /callout >}}\n\n## Join Points\n\nEvery segment in the buffer is a valid **join point** because every segment starts with a keyframe.\n\nWhen a Proctor joins a stream:\n\n1. Server sends the initialization segment\n2. Server selects a segment from the buffer (typically the oldest to maximize catch-up time, or newest for lowest latency)\n3. Server sends that segment and all subsequent segments\n\n### Buffer Depth and Network Quality\n\nThe buffer window (15-20 seconds) accommodates Proctors with varying network conditions:\n\n| Network Quality | Behavior |\n|-----------------|----------|\n| Good | Proctor plays near-realtime, buffer provides redundancy |\n| Moderate | Proctor buffers a few seconds, catches up during low-activity periods |\n| Poor | Proctor buffers more aggressively, may be 10-15 seconds behind live |\n\nIf a Proctor falls further behind than the buffer window, they must either:\n- Skip forward to live (losing some video)\n- Request historical segments via HTTP (see [Transport](../transport))\n\n## Initialization Segment Caching\n\nThe initialization segment for each active Sentinel is cached separately from the media segment buffer.\n\n| Property | Value |\n|----------|-------|\n| Lifetime | Entire session |\n| Eviction | When Sentinel disconnects |\n| Access | Served on every Proctor join request |\n\nSince the initialization segment is small (typically a few KB) and required for every new Proctor, it remains in memory for the duration of the Sentinel's session.\n\n## Memory Considerations\n\nThe memory footprint per Sentinel depends on:\n\n- **Buffer window duration**: Longer window = more segments\n- **Framerate**: Higher FPS = more data per second\n- **Resolution**: Higher resolution = larger frames\n- **Keyframe frequency**: More keyframes = more segments (each starting with a keyframe)\n\n### Rough Estimates\n\nAt 1080p, 5 FPS, with H.264 compression:\n\n| Buffer Window | Approximate Memory per Sentinel |\n|---------------|--------------------------------|\n| 15 seconds | 2-5 MB |\n| 20 seconds | 3-7 MB |\n\nThese are rough estimates. Actual usage depends on screen content complexity and encoder settings.\n",
  "filePath": "/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/memory-buffer.md"
}
```
**Output:**
```
Wrote file successfully.
```
```

---

## Assistant (Build · claude-opus-4.5 · 5.7s)

```
Tool: todowrite

**Input:**
```json
{
  "todos": [
    {
      "content": "Create _index.md - Overview + navigation cards",
      "id": "1",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create encoding.md - H.264 encoding requirements",
      "id": "2",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create container.md - fMP4 structure",
      "id": "3",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create segments.md - Segment creation rules + naming",
      "id": "4",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create memory-buffer.md - Server memory buffer behavior",
      "id": "5",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create disk-storage.md - Disk persistence format",
      "id": "6",
      "priority": "high",
      "status": "in_progress"
    },
    {
      "content": "Create metadata.md - Metadata structure",
      "id": "7",
      "priority": "high",
      "status": "pending"
    },
    {
      "content": "Create transport.md - WebSocket + HTTP transport",
      "id": "8",
      "priority": "high",
      "status": "pending"
    },
    {
      "content": "Create join-flow.md - Proctor joining a Sentinel stream",
      "id": "9",
      "priority": "high",
      "status": "pending"
    },
    {
      "content": "Create control-messages.md - Keyframe + FPS change requests",
      "id": "10",
      "priority": "high",
      "status": "pending"
    }
  ]
}
```
**Output:**
```
[
  {
    "content": "Create _index.md - Overview + navigation cards",
    "id": "1",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create encoding.md - H.264 encoding requirements",
    "id": "2",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create container.md - fMP4 structure",
    "id": "3",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create segments.md - Segment creation rules + naming",
    "id": "4",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create memory-buffer.md - Server memory buffer behavior",
    "id": "5",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create disk-storage.md - Disk persistence format",
    "id": "6",
    "priority": "high",
    "status": "in_progress"
  },
  {
    "content": "Create metadata.md - Metadata structure",
    "id": "7",
    "priority": "high",
    "status": "pending"
  },
  {
    "content": "Create transport.md - WebSocket + HTTP transport",
    "id": "8",
    "priority": "high",
    "status": "pending"
  },
  {
    "content": "Create join-flow.md - Proctor joining a Sentinel stream",
    "id": "9",
    "priority": "high",
    "status": "pending"
  },
  {
    "content": "Create control-messages.md - Keyframe + FPS change requests",
    "id": "10",
    "priority": "high",
    "status": "pending"
  }
]
```
```

---

## Assistant (Build · claude-opus-4.5 · 20.5s)

```
Tool: write

**Input:**
```json
{
  "content": "---\ntitle: Disk Storage\n---\n\nThis document specifies how segments are persisted to disk.\n\n## Storage Principle\n\nThe Server writes segments to disk **as-is** with no processing, transcoding, or modification. The bytes received from the Sentinel are the exact bytes written to disk.\n\n## What is Stored\n\n| Item | Stored | Format |\n|------|--------|--------|\n| Initialization segment | Yes | Raw fMP4 bytes |\n| Media segments | Yes | Raw fMP4 bytes |\n| Metadata | Yes (separately) | See [Metadata](../metadata) |\n\n## File Organization\n\nSegments are organized on disk by Sentinel and session.\n\n### Directory Structure\n\n```\n{storage_root}/\n└── {sentinelId}/\n    └── {sessionId}/\n        ├── init.mp4\n        ├── 000000.m4s\n        ├── 000001.m4s\n        ├── 000002.m4s\n        └── ...\n```\n\n| Component | Description |\n|-----------|-------------|\n| `storage_root` | Base directory for all video storage |\n| `sentinelId` | Unique identifier for the Sentinel |\n| `sessionId` | Unique identifier for the session (e.g., timestamp or UUID) |\n\n### Example\n\n```\n/var/franklyn/video/\n└── sentinel-a1b2c3/\n    └── 2026-02-05T14-30-00Z/\n        ├── init.mp4\n        ├── 000000.m4s\n        ├── 000001.m4s\n        ├── 000002.m4s\n        └── ...\n```\n\n## Write Timing\n\nSegments are written to disk immediately upon receipt from the Sentinel.\n\n| Event | Action |\n|-------|--------|\n| Initialization segment received | Write to `init.mp4` |\n| Media segment received | Write to `{sequence}.m4s` |\n\n{{< callout type=\"info\" >}}\nWriting happens in parallel with adding the segment to the memory buffer. The live streaming path (memory) and archival path (disk) are independent.\n{{< /callout >}}\n\n## No Server Processing\n\nThe Server performs **no video processing**:\n\n| Operation | Performed by Server |\n|-----------|---------------------|\n| Decoding | No |\n| Encoding | No |\n| Transcoding | No |\n| Re-muxing | No |\n| Frame extraction | No |\n| Concatenation | No |\n\nThe Server's role is purely:\n- Receive bytes from Sentinel\n- Write bytes to disk\n- Read bytes from disk\n- Send bytes to Proctor\n\n## File Integrity\n\nEach segment file is a complete, valid fMP4 media segment. Combined with the initialization segment, any media segment can be decoded independently.\n\n### Playback from Disk\n\nTo play back stored video:\n\n{{% steps %}}\n\n### Load Initialization Segment\n\nRead `init.mp4` for the session.\n\n### Load Media Segments in Order\n\nRead segment files in sequence order: `000000.m4s`, `000001.m4s`, etc.\n\n### Concatenate and Play\n\nProvide initialization segment + media segments to an fMP4-compatible player or MSE.\n\n{{% /steps %}}\n\n## Retention\n\nThe spec does not mandate a retention policy. Implementations may:\n\n- Keep all segments indefinitely\n- Delete segments after a configured period\n- Delete entire sessions based on policy\n- Provide manual or automated cleanup\n\n## Later Viewing\n\nStored segments can be retrieved via HTTP for later viewing. See [Transport](../transport) for details on historical segment access.\n\n### Transcoding for Export\n\nFor exporting video to a standard format (e.g., a single MP4 file), a separate **transcoding client** can:\n\n1. Fetch the initialization segment\n2. Fetch all media segments for a session\n3. Concatenate into a single playable file\n\nThis transcoding happens outside the Server (in the Proctor browser or a dedicated tool), maintaining the principle that the Server does no video processing.\n\n{{< callout type=\"warning\" >}}\nThe transcoding/export workflow is out of scope for this spec. The stored segments are sufficient for playback via MSE or external tools.\n{{< /callout >}}\n",
  "filePath": "/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/disk-storage.md"
}
```
**Output:**
```
Wrote file successfully.
```
```

---

## Assistant (Build · claude-opus-4.5 · 5.4s)

```
Tool: todowrite

**Input:**
```json
{
  "todos": [
    {
      "content": "Create _index.md - Overview + navigation cards",
      "id": "1",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create encoding.md - H.264 encoding requirements",
      "id": "2",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create container.md - fMP4 structure",
      "id": "3",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create segments.md - Segment creation rules + naming",
      "id": "4",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create memory-buffer.md - Server memory buffer behavior",
      "id": "5",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create disk-storage.md - Disk persistence format",
      "id": "6",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create metadata.md - Metadata structure",
      "id": "7",
      "priority": "high",
      "status": "in_progress"
    },
    {
      "content": "Create transport.md - WebSocket + HTTP transport",
      "id": "8",
      "priority": "high",
      "status": "pending"
    },
    {
      "content": "Create join-flow.md - Proctor joining a Sentinel stream",
      "id": "9",
      "priority": "high",
      "status": "pending"
    },
    {
      "content": "Create control-messages.md - Keyframe + FPS change requests",
      "id": "10",
      "priority": "high",
      "status": "pending"
    }
  ]
}
```
**Output:**
```
[
  {
    "content": "Create _index.md - Overview + navigation cards",
    "id": "1",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create encoding.md - H.264 encoding requirements",
    "id": "2",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create container.md - fMP4 structure",
    "id": "3",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create segments.md - Segment creation rules + naming",
    "id": "4",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create memory-buffer.md - Server memory buffer behavior",
    "id": "5",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create disk-storage.md - Disk persistence format",
    "id": "6",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create metadata.md - Metadata structure",
    "id": "7",
    "priority": "high",
    "status": "in_progress"
  },
  {
    "content": "Create transport.md - WebSocket + HTTP transport",
    "id": "8",
    "priority": "high",
    "status": "pending"
  },
  {
    "content": "Create join-flow.md - Proctor joining a Sentinel stream",
    "id": "9",
    "priority": "high",
    "status": "pending"
  },
  {
    "content": "Create control-messages.md - Keyframe + FPS change requests",
    "id": "10",
    "priority": "high",
    "status": "pending"
  }
]
```
```

---

## Assistant (Build · claude-opus-4.5 · 26.4s)

```
Tool: write

**Input:**
```json
{
  "content": "---\ntitle: Metadata\n---\n\nThis document specifies the metadata associated with video segments, where it is stored, and how it is synchronized.\n\n## Metadata Locations\n\nMetadata exists in two locations:\n\n| Location | Contents | Purpose |\n|----------|----------|---------|\n| **In-stream** | Timestamps, duration | Required for browser playback |\n| **Application** | Sentinel ID, sequence, framerate, file paths | Server/Proctor coordination |\n\n## In-Stream Metadata\n\nThis metadata is embedded in the fMP4 container by the Sentinel encoder. The Server does not modify it.\n\n### Initialization Segment\n\n| Field | Location | Description |\n|-------|----------|-------------|\n| Timescale | `moov` → `mdhd` | Time units per second (e.g., 90000) |\n| Resolution | `moov` → `tkhd` | Width and height in pixels |\n| Codec info | `moov` → `stsd` | H.264 SPS/PPS |\n\n### Media Segment\n\n| Field | Location | Description |\n|-------|----------|-------------|\n| Base decode time | `moof` → `tfdt` | Timestamp of first frame in segment |\n| Sample durations | `moof` → `trun` | Duration of each frame |\n| Sample sizes | `moof` → `trun` | Byte size of each frame |\n\n{{< callout type=\"info\" >}}\nThe in-stream metadata is sufficient for a browser to decode and display the video at correct timing. The application metadata provides additional context for stream management.\n{{< /callout >}}\n\n## Application Metadata\n\nThis metadata is managed by the Server and stored in memory, with periodic persistence to the database.\n\n### Per-Session Metadata\n\n| Field | Type | Description |\n|-------|------|-------------|\n| `sentinelId` | string | Unique identifier for the Sentinel |\n| `sessionId` | string | Unique identifier for this session |\n| `startTime` | timestamp | When the session started |\n| `resolution` | object | Width and height |\n| `initSegmentPath` | string | Path to initialization segment on disk |\n\nExample:\n\n```json\n{\n  \"sentinelId\": \"sentinel-a1b2c3\",\n  \"sessionId\": \"2026-02-05T14-30-00Z\",\n  \"startTime\": \"2026-02-05T14:30:00.000Z\",\n  \"resolution\": {\n    \"width\": 1920,\n    \"height\": 1080\n  },\n  \"initSegmentPath\": \"/var/franklyn/video/sentinel-a1b2c3/2026-02-05T14-30-00Z/init.mp4\"\n}\n```\n\n### Per-Segment Metadata\n\n| Field | Type | Description |\n|-------|------|-------------|\n| `sequence` | integer | Segment sequence number |\n| `startTime` | timestamp | Wall-clock time of first frame |\n| `duration` | integer | Duration in milliseconds |\n| `framerate` | number | Frames per second for this segment |\n| `filePath` | string | Path to segment file on disk |\n\nExample:\n\n```json\n{\n  \"sequence\": 142,\n  \"startTime\": \"2026-02-05T14:35:42.000Z\",\n  \"duration\": 4800,\n  \"framerate\": 5,\n  \"filePath\": \"/var/franklyn/video/sentinel-a1b2c3/2026-02-05T14-30-00Z/000142.m4s\"\n}\n```\n\n## Memory Storage\n\nDuring active streaming, all application metadata is held in memory for fast access.\n\n### Data Structure (Conceptual)\n\n```\nServer Memory\n├── Active Sessions\n│   └── {sentinelId}\n│       ├── Session Metadata\n│       ├── Init Segment (bytes)\n│       └── Segment Buffer\n│           ├── Segment 140: { metadata, bytes }\n│           ├── Segment 141: { metadata, bytes }\n│           ├── Segment 142: { metadata, bytes }\n│           └── ...\n```\n\n### Access Patterns\n\n| Operation | Data Source |\n|-----------|-------------|\n| Proctor joins stream | Memory (init segment + buffered segments) |\n| New segment arrives | Memory (add to buffer, update metadata) |\n| Proctor requests historical segment | Disk (metadata points to file path) |\n\n## Database Persistence\n\nApplication metadata is periodically synced to the database for durability.\n\n### Sync Strategy\n\n| Aspect | Behavior |\n|--------|----------|\n| Trigger | Periodic (e.g., every 5-10 seconds) |\n| Scope | All new/updated segment metadata since last sync |\n| Blocking | Non-blocking (sync happens asynchronously) |\n| Failure handling | Retry on next sync interval |\n\n{{< callout type=\"warning\" >}}\nThe sync interval is an implementation detail. The key requirement is that real-time operations (live streaming) never block on database writes.\n{{< /callout >}}\n\n### What is Persisted\n\n| Data | Persisted |\n|------|-----------|\n| Session metadata | Yes |\n| Segment metadata | Yes |\n| Segment bytes | No (stored as files on disk) |\n| Init segment bytes | No (stored as file on disk) |\n\n### Recovery\n\nOn Server restart:\n1. Load session and segment metadata from database\n2. Locate segment files on disk using stored paths\n3. Resume streaming for any Sentinels that reconnect\n\n## Metadata for Historical Access\n\nWhen a Proctor requests historical segments (via HTTP), the Server uses the persisted metadata to:\n\n1. Identify which segments exist for a Sentinel/session\n2. Locate the segment files on disk\n3. Serve the requested segment bytes\n\nThe Proctor needs to know:\n- `sentinelId` and `sessionId` to identify the stream\n- `sequence` to request specific segments\n\nThe exact API for querying available segments is implementation-defined. The metadata structure above provides the necessary information.\n",
  "filePath": "/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/metadata.md"
}
```
**Output:**
```
Wrote file successfully.
```
```

---

## Assistant (Build · claude-opus-4.5 · 5.4s)

```
Tool: todowrite

**Input:**
```json
{
  "todos": [
    {
      "content": "Create _index.md - Overview + navigation cards",
      "id": "1",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create encoding.md - H.264 encoding requirements",
      "id": "2",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create container.md - fMP4 structure",
      "id": "3",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create segments.md - Segment creation rules + naming",
      "id": "4",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create memory-buffer.md - Server memory buffer behavior",
      "id": "5",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create disk-storage.md - Disk persistence format",
      "id": "6",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create metadata.md - Metadata structure",
      "id": "7",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create transport.md - WebSocket + HTTP transport",
      "id": "8",
      "priority": "high",
      "status": "in_progress"
    },
    {
      "content": "Create join-flow.md - Proctor joining a Sentinel stream",
      "id": "9",
      "priority": "high",
      "status": "pending"
    },
    {
      "content": "Create control-messages.md - Keyframe + FPS change requests",
      "id": "10",
      "priority": "high",
      "status": "pending"
    }
  ]
}
```
**Output:**
```
[
  {
    "content": "Create _index.md - Overview + navigation cards",
    "id": "1",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create encoding.md - H.264 encoding requirements",
    "id": "2",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create container.md - fMP4 structure",
    "id": "3",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create segments.md - Segment creation rules + naming",
    "id": "4",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create memory-buffer.md - Server memory buffer behavior",
    "id": "5",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create disk-storage.md - Disk persistence format",
    "id": "6",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create metadata.md - Metadata structure",
    "id": "7",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create transport.md - WebSocket + HTTP transport",
    "id": "8",
    "priority": "high",
    "status": "in_progress"
  },
  {
    "content": "Create join-flow.md - Proctor joining a Sentinel stream",
    "id": "9",
    "priority": "high",
    "status": "pending"
  },
  {
    "content": "Create control-messages.md - Keyframe + FPS change requests",
    "id": "10",
    "priority": "high",
    "status": "pending"
  }
]
```
```

---

## Assistant (Build · claude-opus-4.5 · 26.2s)

```
Tool: write

**Input:**
```json
{
  "content": "---\ntitle: Transport\n---\n\nThis document specifies how video data is transported between components.\n\n## Overview\n\n| Use Case | Protocol | Direction |\n|----------|----------|-----------|\n| Live streaming | WebSocket | Server → Proctor (push) |\n| Live streaming | WebSocket | Sentinel → Server (push) |\n| Historical playback | HTTP | Proctor → Server (pull) |\n| Control messages | WebSocket | Bidirectional |\n\n## WebSocket: Live Streaming\n\nAll live video data flows over WebSocket connections.\n\n### Sentinel → Server\n\nThe Sentinel pushes segments to the Server as they are created.\n\n```plantuml\n@startuml\nskinparam sequenceMessageAlign center\n\nparticipant \"Sentinel\" as S\nparticipant \"Server\" as Srv\n\n== Segment Streaming ==\n\nS -> Srv : segment data\nnote right: Segment 140\n\nS -> Srv : segment data\nnote right: Segment 141\n\nS -> Srv : segment data\nnote right: Segment 142\n\n@enduml\n```\n\n### Server → Proctor\n\nThe Server pushes segments to subscribed Proctors as they arrive.\n\n```plantuml\n@startuml\nskinparam sequenceMessageAlign center\n\nparticipant \"Server\" as Srv\nparticipant \"Proctor\" as P\n\n== Live Push ==\n\nSrv -> P : init segment\nSrv -> P : segment data\nnote left: Segment 140\n\nSrv -> P : segment data\nnote left: Segment 141\n\nSrv -> P : segment data\nnote left: Segment 142\n\n@enduml\n```\n\n### Data Format\n\nThe spec does not mandate a specific serialization format for WebSocket messages. Implementations may use:\n\n- JSON with base64-encoded binary data\n- Binary WebSocket frames with a header\n- Protocol Buffers\n- Other formats\n\nThe key requirement is that the message contains:\n\n| Field | Type | Description |\n|-------|------|-------------|\n| `sentinelId` | string | Identifies which Sentinel this segment belongs to |\n| `sequence` | integer | Segment sequence number |\n| `data` | bytes | Raw fMP4 segment bytes |\n\nAdditional metadata (framerate, timestamp) may be included or derived from the segment bytes.\n\n### Initialization Segment\n\nThe initialization segment is sent separately, typically:\n\n- Once when a Proctor joins a stream\n- On request (see [Control Messages](../control-messages))\n\n| Field | Type | Description |\n|-------|------|-------------|\n| `sentinelId` | string | Identifies which Sentinel |\n| `data` | bytes | Raw fMP4 initialization segment bytes |\n\n## HTTP: Historical Playback\n\nFor accessing segments that have aged out of the memory buffer, Proctors use HTTP.\n\n### Required Information\n\nTo fetch a historical segment, the Proctor needs:\n\n| Information | Description |\n|-------------|-------------|\n| `sentinelId` | Which Sentinel's stream |\n| `sessionId` | Which session |\n| `sequence` | Which segment (or range) |\n\n### Response\n\nThe HTTP response contains the raw fMP4 segment bytes with appropriate content headers.\n\n| Header | Value |\n|--------|-------|\n| `Content-Type` | `video/mp4` |\n| `Content-Length` | Size in bytes |\n\n### Listing Available Segments\n\nProctors may need to query which segments are available for a session. The response should include:\n\n| Field | Type | Description |\n|-------|------|-------------|\n| `sentinelId` | string | Sentinel identifier |\n| `sessionId` | string | Session identifier |\n| `segments` | array | List of available segment metadata |\n\nEach segment entry:\n\n| Field | Type | Description |\n|-------|------|-------------|\n| `sequence` | integer | Segment number |\n| `startTime` | timestamp | When the segment starts |\n| `duration` | integer | Duration in milliseconds |\n\n{{< callout type=\"info\" >}}\nThe exact HTTP endpoint structure is implementation-defined. The spec only defines what information must be available.\n{{< /callout >}}\n\n## Protocol Selection\n\n### When to Use WebSocket\n\n| Scenario | Use WebSocket |\n|----------|---------------|\n| Live stream viewing | Yes |\n| Joining a stream | Yes (get init + recent segments) |\n| Control messages (keyframe request, FPS change) | Yes |\n| Real-time segment push from Sentinel | Yes |\n\n### When to Use HTTP\n\n| Scenario | Use HTTP |\n|----------|----------|\n| Fetching segments older than buffer window | Yes |\n| Querying available sessions/segments | Yes |\n| Downloading for export/archival | Yes |\n\n## Connection Lifecycle\n\n### Sentinel Connection\n\n1. Sentinel establishes WebSocket connection to Server\n2. Sentinel sends registration/identification\n3. Sentinel begins pushing segments\n4. Connection remains open for session duration\n5. On disconnect, session ends\n\n### Proctor Connection\n\n1. Proctor establishes WebSocket connection to Server\n2. Proctor sends registration/identification\n3. Proctor subscribes to one or more Sentinel streams\n4. Server pushes segments for subscribed streams\n5. Proctor may switch subscriptions during session\n6. Connection remains open while Proctor is active\n\n## Bandwidth Considerations\n\nSince Sentinel and Server are expected to be on the same LAN:\n\n- Bandwidth is not a primary constraint\n- Single-frame messages are acceptable\n- No need for aggressive batching or compression beyond H.264\n\nFor Proctor connections (potentially over WAN):\n\n- The memory buffer (15-20 seconds) provides catch-up capacity\n- Proctors with slow connections may fall behind\n- If behind by more than buffer window, Proctor must skip forward or use HTTP for historical catch-up\n",
  "filePath": "/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/transport.md"
}
```
**Output:**
```
Wrote file successfully.
```
```

---

## Assistant (Build · claude-opus-4.5 · 5.5s)

```
Tool: todowrite

**Input:**
```json
{
  "todos": [
    {
      "content": "Create _index.md - Overview + navigation cards",
      "id": "1",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create encoding.md - H.264 encoding requirements",
      "id": "2",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create container.md - fMP4 structure",
      "id": "3",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create segments.md - Segment creation rules + naming",
      "id": "4",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create memory-buffer.md - Server memory buffer behavior",
      "id": "5",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create disk-storage.md - Disk persistence format",
      "id": "6",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create metadata.md - Metadata structure",
      "id": "7",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create transport.md - WebSocket + HTTP transport",
      "id": "8",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create join-flow.md - Proctor joining a Sentinel stream",
      "id": "9",
      "priority": "high",
      "status": "in_progress"
    },
    {
      "content": "Create control-messages.md - Keyframe + FPS change requests",
      "id": "10",
      "priority": "high",
      "status": "pending"
    }
  ]
}
```
**Output:**
```
[
  {
    "content": "Create _index.md - Overview + navigation cards",
    "id": "1",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create encoding.md - H.264 encoding requirements",
    "id": "2",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create container.md - fMP4 structure",
    "id": "3",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create segments.md - Segment creation rules + naming",
    "id": "4",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create memory-buffer.md - Server memory buffer behavior",
    "id": "5",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create disk-storage.md - Disk persistence format",
    "id": "6",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create metadata.md - Metadata structure",
    "id": "7",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create transport.md - WebSocket + HTTP transport",
    "id": "8",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create join-flow.md - Proctor joining a Sentinel stream",
    "id": "9",
    "priority": "high",
    "status": "in_progress"
  },
  {
    "content": "Create control-messages.md - Keyframe + FPS change requests",
    "id": "10",
    "priority": "high",
    "status": "pending"
  }
]
```
```

---

## Assistant (Build · claude-opus-4.5 · 26.8s)

```
Tool: write

**Input:**
```json
{
  "content": "---\ntitle: Join Flow\n---\n\nThis document specifies how a Proctor joins a Sentinel's video stream.\n\n## Overview\n\nWhen a Proctor wants to view a Sentinel's screen, it must:\n\n1. Request to join the stream\n2. Receive the initialization segment\n3. Receive a keyframe segment (join point)\n4. Continue receiving live segments\n\n## Join Flow Diagram\n\n```plantuml\n@startuml\nskinparam sequenceMessageAlign center\n\nparticipant \"Proctor\" as P\nparticipant \"Server\" as Srv\nparticipant \"Sentinel\" as S\n\n== Join Request ==\n\nP -> Srv : request join stream\\n(sentinelId)\nactivate Srv\n\nSrv -> Srv : validate request\nSrv -> Srv : lookup Sentinel\\nin memory buffer\n\n== Initial Data ==\n\nSrv -> P : init segment\n\nSrv -> P : keyframe segment\\n(oldest in buffer or latest)\n\n== Live Streaming ==\n\nloop as segments arrive\n  S -> Srv : new segment\n  Srv -> P : new segment\nend\n\ndeactivate Srv\n\n@enduml\n```\n\n## Step-by-Step\n\n{{% steps %}}\n\n### Proctor Sends Join Request\n\nThe Proctor sends a message over WebSocket requesting to join a specific Sentinel's stream.\n\n**Required fields:**\n\n| Field | Type | Description |\n|-------|------|-------------|\n| `sentinelId` | string | The Sentinel to subscribe to |\n\n**Optional fields:**\n\n| Field | Type | Description |\n|-------|------|-------------|\n| `startFrom` | string | `\"oldest\"` (default) or `\"latest\"` |\n\n### Server Validates and Looks Up\n\nThe Server:\n- Validates the Proctor is authorized to view the Sentinel\n- Checks if the Sentinel is currently streaming\n- Locates the session data in memory\n\nIf the Sentinel is not streaming, the Server responds with an error.\n\n### Server Sends Initialization Segment\n\nThe Server sends the cached initialization segment for the Sentinel's current session.\n\n**Required fields:**\n\n| Field | Type | Description |\n|-------|------|-------------|\n| `sentinelId` | string | Identifies the stream |\n| `sessionId` | string | Current session identifier |\n| `data` | bytes | Raw fMP4 init segment |\n\n### Server Sends Keyframe Segment\n\nThe Server selects a segment from the memory buffer and sends it.\n\n**Selection strategy:**\n\n| `startFrom` | Segment Selected |\n|-------------|------------------|\n| `\"oldest\"` | Oldest segment in buffer (maximum catch-up time) |\n| `\"latest\"` | Most recent segment (lowest latency) |\n\nThe selected segment is guaranteed to start with a keyframe (all segments do).\n\n**Required fields:**\n\n| Field | Type | Description |\n|-------|------|-------------|\n| `sentinelId` | string | Identifies the stream |\n| `sequence` | integer | Segment sequence number |\n| `data` | bytes | Raw fMP4 media segment |\n\n### Server Continues Pushing Segments\n\nFrom this point, the Server pushes new segments to the Proctor as they arrive from the Sentinel.\n\n{{% /steps %}}\n\n## On-Demand Keyframe for Fast Join\n\nIf the Proctor wants to minimize join latency (not wait for the next segment), it can request an on-demand keyframe before or during the join.\n\nSee [Control Messages](../control-messages) for the keyframe request flow.\n\nWith on-demand keyframes:\n\n```plantuml\n@startuml\nskinparam sequenceMessageAlign center\n\nparticipant \"Proctor\" as P\nparticipant \"Server\" as Srv\nparticipant \"Sentinel\" as S\n\n== Pre-Join Keyframe Request ==\n\nP -> Srv : request keyframe\\n(sentinelId)\nSrv -> S : request keyframe\n\nS -> S : generate keyframe\\non next capture\n\nS -> Srv : new segment\\n(starts with keyframe)\n\n== Join Request ==\n\nP -> Srv : request join stream\\n(sentinelId)\n\nSrv -> P : init segment\nSrv -> P : keyframe segment\\n(the just-created one)\n\n== Live Streaming ==\n\nloop as segments arrive\n  S -> Srv : new segment\n  Srv -> P : new segment\nend\n\n@enduml\n```\n\n## Predictive Pre-Fetching\n\nProctors may predict which Sentinel they will view next (e.g., based on UI layout or user behavior) and pre-fetch:\n\n1. Request a keyframe for the predicted Sentinel\n2. When ready to switch, join is near-instant\n\nThis is optional behavior implemented in the Proctor application.\n\n## Switching Streams\n\nWhen a Proctor switches from one Sentinel to another:\n\n{{% steps %}}\n\n### Unsubscribe from Current Stream\n\nProctor notifies Server to stop sending segments for the current Sentinel.\n\n### Join New Stream\n\nFollow the standard join flow for the new Sentinel.\n\n### Reset MSE Buffer\n\nIn the browser, the Proctor must:\n- Clear the existing `SourceBuffer`\n- Append the new initialization segment\n- Begin appending segments from the new stream\n\n{{% /steps %}}\n\n## Error Handling\n\n| Condition | Server Response |\n|-----------|-----------------|\n| Sentinel not found | Error: unknown Sentinel |\n| Sentinel not streaming | Error: Sentinel offline |\n| Authorization failure | Error: not authorized |\n| No segments in buffer | Send init segment, wait for first segment |\n\n## Latency Considerations\n\n| Factor | Impact on Join Latency |\n|--------|------------------------|\n| Buffer has segments | Immediate join (send from buffer) |\n| On-demand keyframe requested | Wait for next capture cycle |\n| No keyframe, must wait | Up to max keyframe interval (20-30s) |\n\nFor lowest latency joins:\n1. Use on-demand keyframe requests\n2. Use `startFrom: \"latest\"` \n3. Pre-fetch keyframes for likely next streams\n",
  "filePath": "/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/join-flow.md"
}
```
**Output:**
```
Wrote file successfully.
```
```

---

## Assistant (Build · claude-opus-4.5 · 7.3s)

```
Tool: todowrite

**Input:**
```json
{
  "todos": [
    {
      "content": "Create _index.md - Overview + navigation cards",
      "id": "1",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create encoding.md - H.264 encoding requirements",
      "id": "2",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create container.md - fMP4 structure",
      "id": "3",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create segments.md - Segment creation rules + naming",
      "id": "4",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create memory-buffer.md - Server memory buffer behavior",
      "id": "5",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create disk-storage.md - Disk persistence format",
      "id": "6",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create metadata.md - Metadata structure",
      "id": "7",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create transport.md - WebSocket + HTTP transport",
      "id": "8",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create join-flow.md - Proctor joining a Sentinel stream",
      "id": "9",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create control-messages.md - Keyframe + FPS change requests",
      "id": "10",
      "priority": "high",
      "status": "in_progress"
    }
  ]
}
```
**Output:**
```
[
  {
    "content": "Create _index.md - Overview + navigation cards",
    "id": "1",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create encoding.md - H.264 encoding requirements",
    "id": "2",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create container.md - fMP4 structure",
    "id": "3",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create segments.md - Segment creation rules + naming",
    "id": "4",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create memory-buffer.md - Server memory buffer behavior",
    "id": "5",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create disk-storage.md - Disk persistence format",
    "id": "6",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create metadata.md - Metadata structure",
    "id": "7",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create transport.md - WebSocket + HTTP transport",
    "id": "8",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create join-flow.md - Proctor joining a Sentinel stream",
    "id": "9",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create control-messages.md - Keyframe + FPS change requests",
    "id": "10",
    "priority": "high",
    "status": "in_progress"
  }
]
```
```

---

## Assistant (Build · claude-opus-4.5 · 26.6s)

```
Tool: write

**Input:**
```json
{
  "content": "---\ntitle: Control Messages\n---\n\nThis document specifies the control messages for keyframe requests and FPS changes.\n\n## Overview\n\nControl messages allow coordination between components without transferring video data.\n\n| Message Type | Direction | Purpose |\n|--------------|-----------|---------|\n| Keyframe Request | Proctor → Server → Sentinel | Request immediate keyframe |\n| FPS Change Request | Server → Sentinel | Change capture framerate |\n\n## Keyframe Request\n\nAllows a Proctor (via Server) to request an on-demand keyframe from a Sentinel.\n\n### Flow Diagram\n\n```plantuml\n@startuml\nskinparam sequenceMessageAlign center\n\nparticipant \"Proctor\" as P\nparticipant \"Server\" as Srv\nparticipant \"Sentinel\" as S\n\n== Keyframe Request ==\n\nP -> Srv : keyframe request\\n(sentinelId)\nactivate Srv\n\nSrv -> Srv : validate request\n\nSrv -> S : keyframe request\nactivate S\n\nS -> S : mark next frame\\nas keyframe\n\nS -> Srv : segment\\n(starts with keyframe)\ndeactivate S\n\nSrv -> P : segment available\ndeactivate Srv\n\n@enduml\n```\n\n### Request Message (Proctor → Server)\n\n| Field | Type | Required | Description |\n|-------|------|----------|-------------|\n| `sentinelId` | string | yes | Target Sentinel |\n\nExample:\n\n```json\n{\n  \"type\": \"keyframe.request\",\n  \"sentinelId\": \"sentinel-a1b2c3\"\n}\n```\n\n### Request Message (Server → Sentinel)\n\n| Field | Type | Required | Description |\n|-------|------|----------|-------------|\n| `type` | string | yes | Message type identifier |\n\nExample:\n\n```json\n{\n  \"type\": \"keyframe.request\"\n}\n```\n\n### Sentinel Behavior\n\nWhen the Sentinel receives a keyframe request:\n\n1. The next captured frame becomes an IDR frame (keyframe)\n2. A new segment begins with this keyframe\n3. The segment is sent to the Server as usual\n\n{{< callout type=\"info\" >}}\nThe keyframe is generated on the **next capture**, not immediately. The delay depends on the current framerate. At 5 FPS, maximum delay is 200ms. At 1/5 FPS, maximum delay is 5 seconds.\n{{< /callout >}}\n\n### Response\n\nNo explicit response message is defined. The Proctor knows the keyframe request was fulfilled when a new segment arrives (which will start with a keyframe).\n\n## FPS Change Request\n\nAllows the Server to request a framerate change from a Sentinel.\n\n### Flow Diagram\n\n```plantuml\n@startuml\nskinparam sequenceMessageAlign center\n\nparticipant \"Server\" as Srv\nparticipant \"Sentinel\" as S\n\n== FPS Change ==\n\nSrv -> S : fps change request\\n(newFps: 2)\nactivate S\n\nS -> S : finish current segment\n\nS -> S : apply new framerate\n\nS -> Srv : segment\\n(at old fps)\n\nS -> Srv : segment\\n(at new fps, starts with keyframe)\ndeactivate S\n\n@enduml\n```\n\n### Request Message (Server → Sentinel)\n\n| Field | Type | Required | Description |\n|-------|------|----------|-------------|\n| `type` | string | yes | Message type identifier |\n| `framerate` | number | yes | New target framerate (0.2 to 5) |\n\nExample:\n\n```json\n{\n  \"type\": \"fps.change\",\n  \"framerate\": 2\n}\n```\n\n### Sentinel Behavior\n\nWhen the Sentinel receives an FPS change request:\n\n{{% steps %}}\n\n### Finish Current Segment\n\nComplete and send the current segment with the old framerate.\n\n### Generate Keyframe\n\nThe next frame is an IDR frame, starting a new segment.\n\n### Apply New Framerate\n\nBegin capturing at the new framerate.\n\n### Continue Streaming\n\nNew segments are sent at the new framerate.\n\n{{% /steps %}}\n\n### Framerate Bounds\n\n| Bound | Value | Behavior if Exceeded |\n|-------|-------|---------------------|\n| Minimum | 0.2 fps (1 frame per 5 seconds) | Clamp to minimum |\n| Maximum | 5 fps | Clamp to maximum |\n\nIf the requested framerate is outside bounds, the Sentinel clamps it and applies the bounded value.\n\n### Response\n\nNo explicit response message is defined. The Server observes the framerate change via segment metadata.\n\n## Server-Initiated vs Proctor-Initiated\n\n| Message | Who Initiates | Server's Role |\n|---------|---------------|---------------|\n| Keyframe Request | Proctor | Relay to Sentinel |\n| FPS Change | Server | Originates from Server |\n\nThe Proctor cannot directly request an FPS change. FPS changes are a Server-side decision based on:\n\n- Server load\n- Network conditions\n- Administrative policy\n\n## Timing Guarantees\n\n| Message | Timing |\n|---------|--------|\n| Keyframe Request | Keyframe on next capture (up to 1/framerate delay) |\n| FPS Change | Takes effect on next segment |\n\n## Error Handling\n\n### Keyframe Request Errors\n\n| Condition | Handling |\n|-----------|----------|\n| Sentinel not found | Server returns error to Proctor |\n| Sentinel offline | Server returns error to Proctor |\n| Request during encoding | Sentinel queues request for next frame |\n\n### FPS Change Errors\n\n| Condition | Handling |\n|-----------|----------|\n| Invalid framerate | Sentinel clamps to valid range |\n| Sentinel busy | Sentinel applies on next segment boundary |\n\n## Message Type Summary\n\n| Type Identifier | Direction | Description |\n|-----------------|-----------|-------------|\n| `keyframe.request` | Proctor → Server | Request keyframe for a Sentinel |\n| `keyframe.request` | Server → Sentinel | Relay keyframe request |\n| `fps.change` | Server → Sentinel | Request framerate change |\n\n{{< callout type=\"warning\" >}}\nThe message type identifiers shown are examples. Implementations may use different naming conventions as long as the semantics are preserved.\n{{< /callout >}}\n",
  "filePath": "/home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/control-messages.md"
}
```
**Output:**
```
Wrote file successfully.
```
```

---

## Assistant (Build · claude-opus-4.5 · 6.1s)

```
Tool: todowrite

**Input:**
```json
{
  "todos": [
    {
      "content": "Create _index.md - Overview + navigation cards",
      "id": "1",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create encoding.md - H.264 encoding requirements",
      "id": "2",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create container.md - fMP4 structure",
      "id": "3",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create segments.md - Segment creation rules + naming",
      "id": "4",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create memory-buffer.md - Server memory buffer behavior",
      "id": "5",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create disk-storage.md - Disk persistence format",
      "id": "6",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create metadata.md - Metadata structure",
      "id": "7",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create transport.md - WebSocket + HTTP transport",
      "id": "8",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create join-flow.md - Proctor joining a Sentinel stream",
      "id": "9",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create control-messages.md - Keyframe + FPS change requests",
      "id": "10",
      "priority": "high",
      "status": "completed"
    }
  ]
}
```
**Output:**
```
[
  {
    "content": "Create _index.md - Overview + navigation cards",
    "id": "1",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create encoding.md - H.264 encoding requirements",
    "id": "2",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create container.md - fMP4 structure",
    "id": "3",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create segments.md - Segment creation rules + naming",
    "id": "4",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create memory-buffer.md - Server memory buffer behavior",
    "id": "5",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create disk-storage.md - Disk persistence format",
    "id": "6",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create metadata.md - Metadata structure",
    "id": "7",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create transport.md - WebSocket + HTTP transport",
    "id": "8",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create join-flow.md - Proctor joining a Sentinel stream",
    "id": "9",
    "priority": "high",
    "status": "completed"
  },
  {
    "content": "Create control-messages.md - Keyframe + FPS change requests",
    "id": "10",
    "priority": "high",
    "status": "completed"
  }
]
```
```

---

## Assistant (Build · claude-opus-4.5 · 4.3s)

All documentation has been created. Let me verify the structure:

```
Tool: bash

**Input:**
```json
{
  "command": "ls -la /home/jakki/projects/franklyn/hugo/content/docs/reference/media-spec/",
  "description": "List created media-spec files"
}
```
**Output:**
```
total 68
drwxr-xr-x 1 jakki users  256 Feb  5 19:42 .
drwxr-xr-x 1 jakki users  100 Feb  5 19:37 ..
-rw-r--r-- 1 jakki users 4621 Feb  5 19:38 container.md
-rw-r--r-- 1 jakki users 5350 Feb  5 19:42 control-messages.md
-rw-r--r-- 1 jakki users 3682 Feb  5 19:40 disk-storage.md
-rw-r--r-- 1 jakki users 3679 Feb  5 19:38 encoding.md
-rw-r--r-- 1 jakki users 2171 Feb  5 19:37 _index.md
-rw-r--r-- 1 jakki users 5125 Feb  5 19:41 join-flow.md
-rw-r--r-- 1 jakki users 4699 Feb  5 19:39 memory-buffer.md
-rw-r--r-- 1 jakki users 5104 Feb  5 19:40 metadata.md
-rw-r--r-- 1 jakki users 4136 Feb  5 19:39 segments.md
-rw-r--r-- 1 jakki users 5214 Feb  5 19:41 transport.md

```
```

---

## Assistant (Build · claude-opus-4.5 · 10.0s)

All 10 files have been created. Here's a summary of what was created:

---

## Documentation Complete

Created the media streaming specification in `hugo/content/docs/reference/media-spec/` with the following structure:

| File | Description |
|------|-------------|
| `_index.md` | Overview page with summary table and navigation cards |
| `encoding.md` | H.264 codec requirements, profile/level recommendations, resolution, framerate, keyframe rules |
| `container.md` | fMP4 structure, initialization vs media segments, MIME types |
| `segments.md` | Segment creation triggers, naming convention, sequence numbers, variable duration |
| `memory-buffer.md` | 15-20 second buffer, eviction, join points, memory considerations |
| `disk-storage.md` | File organization, no server processing, playback from disk |
| `metadata.md` | In-stream vs application metadata, periodic DB sync |
| `transport.md` | WebSocket for live, HTTP for historical, protocol selection |
| `join-flow.md` | Proctor join sequence with PlantUML diagrams, predictive pre-fetching |
| `control-messages.md` | Keyframe request and FPS change flows with PlantUML diagrams |

### Features Used

- Hextra cards for navigation
- Tables for structured data
- Callouts for important notes and warnings
- Steps shortcode for sequential flows
- PlantUML sequence diagrams for visual flows
- JSON examples for message structures

---

