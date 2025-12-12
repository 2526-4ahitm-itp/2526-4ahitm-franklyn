---
title: Legacy Server Performance Analysis
weight: 100
---

## Problem

Teachers saw heavy slowdowns on the Franklyn server: the student video preview
updated every **3 minutes** instead of the planned **5 seconds**.

## Agreement

Together with the Teachers we decided to find the cause. We built a simple load
tester (see [Issue #65](https://github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/issues/65))
to repeat the problem and measure it.

## Approach

We reused the openbox project and added these settings:

-   `spread`: how spread out the client requests are (1 = spread, 0 = all at once)
-   `clients`: number of clients sending requests
-   `interval`: seconds between requests per client (default 5s)
-   `noise`: how much of the image changes (0%–100%)
-   `prefix`: text added before each random client name

A local run showed the tester can push around 2 GiB/s from a single laptop, so the only
real bottleneck is bandwidth—meaning it’s fully capable of stressing the Franklyn server
to the point of a DoS. The Franklyn server ran on the Franklyn 1 server and was
port-forwarded to local 8080 from inside the school network:

```shell
ssh -L 8080:localhost:8080 franklyn@franklyn.htl-leonding.ac.at
```

## Test Runs (grouped)

All runs used `--noise 0.23 --spread 1 --interval 5`. Each request has a size
of **~1.6 Mb**, which is around **24 Mb/s** with 75 clients.

-   **Run 1 — 75 clients** (`cargo run -- --clients 75`)

    -   CPU: goes to **100%**, then stable around **80+%**
    -   Throughput: about **15 requests/s**
    -   Per frame per thread: **~400 ms**

-   **Run 2 — 80 clients** (`cargo run -- --clients 80`)

    -   CPU: often **100%**, mostly around **95%**
    -   Throughput: about **16 requests/s**
    -   Per frame per thread: **~750 ms**

-   **Run 3 — 90 clients** (`cargo run -- --clients 90`)
    -   CPU: **100%** all the time
    -   Per frame per thread: starts near **827 ms**, climbs to **~4500 ms** after 2:30
    -   Throughput: maxxed out at about **16-17 requests/s**
    -   Response times: API calls take several seconds
    -   Memory usage: 17% - 20%

## Analysis

-   Clients send **1.6 Mb** per frame each time instead of only the delta.
-   The server handles every request and drops nothing, so higher client counts
    overload it.
-   The bottleneck is encoding the image from a ByteArray and saving it to disk

## Conclusion

The server was slightly overwhelmed with 90 clients.
This required 18 requests per seconds but the server can only handle 16 max.
Because the server will accept every single request and has many requests pending
the time for processing the images increases. Now that even less images are being
processed, encoding times skyrocket and lead to a **3 minute delay** after some time
in the test.

## Images

### 75 clients

**413.1 ms** average frame time

![Instructor Clients](image-1.png)

### 80 clients

**768 ms** average frame time

![Instructor Client](image.png)

### 90 clients (5 seconds after start)

**827.3 ms** average frame time

![Instructor Client](image-2.png)

after 2 minutes and 30 seconds

**3 252.1 ms** average frame time

![Instructor Client](image-3.png)

#### Memory Usage

![alt text](image-4.png)
