# Screen capture storage and transfer questions

**Session ID:** ses_3d145c73dffeseO6bWDF2TefrL
**Created:** 2/5/2026, 5:54:42 PM
**Updated:** 2/5/2026, 6:10:13 PM

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

