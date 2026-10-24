# stream.md

## Overview

Students run a native agent that publishes their screen. Teachers watch from a browser. A Go backend sits between them and forwards media.

Three transports:

1. WebSocket for all control, metadata and thumbnails.
2. WHIP for student video going in.
3. WHEP for teacher video coming out.

## Components

### Student agent (Rust, GStreamer)

Responsible for capture, encode and publish.

Flow:

1. Connect WebSocket. Authenticate with the device credential.
2. Receive session start from server. Message includes a short lived WHIP token (JWT with studentId, sessionId, scope whip:publish, 5 minute expiry).
3. Set `signaller::whip-endpoint` and `signaller::auth-token` on `whipclientsink`. Endpoint URL is generic. Identity lives in the token.
4. Set pipeline to Playing. The sink handles SDP, ICE, DTLS and session teardown by itself. It sends the HTTP DELETE to the session URL on shutdown.
5. Capture thumbnails in parallel. JPEG or WebP, one per second, send on the WebSocket.
6. On `pause` command, set `valve drop=true`. On `resume`, set `drop=false` and force a keyframe.

Pipeline ends: `... ! valve ! whipclientsink`

### Backend (Go, Pion)

Responsible for identity, routing and session state. Forwards RTP payloads without decoding. Header extensions are stripped before writing to the outbound track.

Flow:

1. Terminate WebSockets for students and teachers. Authenticate both.
2. Mint WHIP and WHEP tokens on demand. Short lived, single use.
3. `POST /whip`: validate token, create PeerConnection, answer the offer, return 201 with `Content-Type: application/sdp` and a Location header pointing at the session URL.
4. `OnTrack`: create a `TrackLocalStaticRTP`, copy packets across in a loop, store it in a map keyed by sessionId. That map is the routing table.
5. `POST /whep`: validate token, `AddTrack` the stored local track onto the teacher's PeerConnection, return 201 with `Content-Type: application/sdp` and a Location header. When the offer cannot be accepted, return 406 with a counter offer and a Location header.
6. Fan thumbnails from student sockets to the right teacher sockets.
7. Push roster and state changes to teachers. Students joining, leaving and going offline.
8. Send `pause` and `resume` to students based on whether anyone is watching.

### Teacher client (browser)

Responsible for display and user input.

Flow:

1. Connect WebSocket. Authenticate.
2. Receive roster for the room.
3. Render the grid from incoming thumbnails.
4. On click, request a stream. Server returns a WHEP token.
5. `addTransceiver('video', {direction: 'recvonly'})`, `createOffer`, POST the SDP to the WHEP endpoint, `setRemoteDescription` on the answer.
6. `ontrack`, attach to a `<video>` element.
7. On `session_ended`, tear down the PeerConnection. This event arrives over the WebSocket.
8. On switching students, close the old PeerConnection and open a new one. The student's WHIP session continues.
