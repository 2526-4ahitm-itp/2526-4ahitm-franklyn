---
title: Legacy Server Performance Analysis 2
weight: 200
---

## Problem

During real exams with 90 concurrent clients, teachers observed that student screenshot previews in the Proctor view updated only every **~3 minutes** instead of the configured **5-10 second** interval. This made effective proctoring impossible.

## Agreement

We agreed to:

1. Build a stress testing tool (`openbox-dos`) to reproduce the issue in a controlled
   environment and identify the problem.

## Approach

### Phase 1: Adding Observability

We added profiling metrics to both the server and frontend to track:

- Screenshot request latency (end-to-end)
- Image decode/encode times
- Queue sizes and active request counts
- WebSocket ping latency
- Image download times

### Phase 2: Building the Stress Test Tool

We built `openbox-dos`, a clone of the openbox rust app
with removed ui, support for multiple clients and screenshot mocking.
Frames are pregenerated and then loaded into memory to make the network
bandwidth the bottleneck so we aren't limited by I/O or computation.

### Phase 3: Load Testing and Observation

We ran the stress test with 150 clients on 2 machines against the server infrastructure
and observed the metrics dashboard.

## Observations

### Server Metrics (150 connected clients)

| Metric                   | Value   | Significance                                 |
| ------------------------ | ------- | -------------------------------------------- |
| Queue Size               | 135     | 90% of clients always waiting                |
| Active Requests          | 15      | Hard limit on concurrent requests            |
| Connected Clients        | 150     | All clients connected successfully           |
| Uploads/sec              | 7.2     | Actual throughput achieved                   |
| Screenshot Request (p50) | 1.46s   | End-to-end request latency                   |
| Image Decode (p50)       | 92.3ms  | Server-side decode time                      |
| Image Encode (p50)       | 79.7ms  | Server-side encode time                      |
| Image Save Total (p50)   | 1.13s   | Full save pipeline (see breakdown below)     |
| Image Download (p50)     | 327.2ms | Proctor downloading screenshots for web view |

#### Image Save Total Breakdown

The "Image Save Total" metric (1.13s) measures the entire `saveFrameOfSession()` method in `ImageService.java`, which includes:

1. **Database lookup**: Find participation by session ID
2. **Permission check**: Verify upload is allowed via `ScreenshotRequestManager`
3. **State validation**: Check if exam is ongoing
4. **Database persist**: Save image metadata to database
5. **Directory creation**: Create screenshot folder if needed
6. **Image Decode** (92ms): Decode uploaded image bytes
7. **Beta frame processing** (if applicable):
   - DB query for latest alpha frame
   - File read from disk (21ms)
   - Graphics merge operation (3.8ms)
8. **Image Encode** (80ms): Encode and write PNG to disk

The sub-metrics (decode: 92ms, encode: 80ms, file read: 21ms, merge: 3.8ms) total ~197ms, but the full pipeline takes 1.13s. The **hidden cost is database operations** under high concurrency - multiple reactive DB queries that become slow when the connection pool is saturated.

### Analysis

1. **Screenshot request queue was constantly backed up** - With 150 clients and only 15 concurrent request slots, 135 clients were always waiting in queue.

2. **Screenshot request times were abnormally high** - End-to-end screenshot requests took 1.46s (p50), with p99 reaching 2.96s.

3. **Image downloads for the Proctor view were also slow** - Even with just 3 web views open in the Proctor, image download times increased significantly (327ms p50, up to 1.27s max).

4. **The concurrent request limit was the bottleneck** - The server was configured to allow only 15 concurrent screenshot requests at a time.

### Configuration Analysis

We examined the server configuration in `application.properties`:

```properties
# max concurrent screenshot requests
screenshots.max-concurrent-requests=15
# maximum amount of milliseconds to wait before invalidating a screenshot request
screenshots.upload-timeout=3000
```

Git history revealed these values were set conservatively during initial implementation (starting at 10, later bumped to 15) without load testing against production workloads.

### Attempt: Increasing Concurrency Limits

We attempted to increase the limits to 50 concurrent requests:

```properties
screenshots.max-concurrent-requests=50
websocket.ping.max-concurrent-requests=50
```

**Result**: Client connections became extremely unstable. Clients received error responses from the server and were disconnected:

```
[Client 67] Upload error: hyper::Error(IncompleteMessage)
[Client 67] Upload error: Connection reset by peer
[Client 30] Disconnected by server
[Client 70] Disconnected by server
[Client 44] Disconnected by server
...
```

The server could not handle 50 concurrent image processing operations, leading to resource exhaustion and connection resets.

## Conclusion

The 3-minute screenshot delay is caused by a **queue backup** due to the combination of:

1. **Low concurrent request limit (15)** - Only 15 screenshot requests can be processed simultaneously
2. **High per-request processing time (~1.5s)** - Each screenshot requires decode, merge, encode, and disk write operations
3. **Math that doesn't work**:
   - Maximum throughput: 15 slots × (1 request / 1.5s) = **10 requests/second**
   - Required throughput for 90 clients at 5s interval: 90 / 5 = **18 requests/second**
   - The server cannot keep up, causing queue growth and increasing delays

Note: Our test results where applied to the actual test environment.

The queue continuously grows faster than it drains, causing screenshot update times to degrade from seconds to minutes over the course of an exam.

Increasing the concurrency limit is not a viable solution - the server becomes unstable when processing more than ~15-20 concurrent image operations.

## Solution

The throttling limits are a **symptom protector**, not the root cause. The real solutions require architectural changes:

Rewrite the Architecture to make the server a pure I/O relay and encode/decode
on the client.
