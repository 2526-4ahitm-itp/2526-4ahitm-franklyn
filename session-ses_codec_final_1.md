# Screen capture storage and transfer questions

**Session ID:** ses_3d145c73dffeseO6bWDF2TefrL
**Created:** 2/5/2026, 5:54:42 PM
**Updated:** 2/5/2026, 7:37:37 PM

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

## Assistant (Build · claude-opus-4.5)

```
Tool: write

**Input:**
```json
{}
```
```

---

