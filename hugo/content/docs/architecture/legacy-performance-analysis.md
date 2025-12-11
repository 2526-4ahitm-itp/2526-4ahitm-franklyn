---
title: Legacy Server Performance Analysis
weight: 100
---

## Problem

Our Teachers reported a massive degradation of the Franklyn Server.
The Video Preview of a student only updated every 3 minutes instead of the
programmed 5 seconds.

## Agreement

We reached an agreement with the Teachers to find out what the issue is so we
are making a tool to overwhelm the Franklyn Server (DoS) as written in
[Issue #65](https://github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/issues/65).

## Approach

We copied the openbox project and wrapped it with some controls:

-   `spread`: controls how spread out the client requests are where 1 is very
    spread out and 0 is all clients send at the same time
-   `clients`: how many clients are sending requests
-   `interval`: the time in seconds that passes between each request per client (defaults to 5s)
-   `noise`: how much of the image changes (delta) with 1 being 100% and 0 being 0%
-   `prefix`: a string that is prepended to the random hash-like name the user registers to the server

## Approach

We first ran the server locally and observed that the DDoS tester was bottlenecked solely by available
bandwidth, reaching throughput levels of roughly 2 GiB/s—rates far above anything expected in production.
This indicates that the tester is sufficiently powerful to stress the server effectively.

Then we deployed the Franklyn Server to the Server Machine of Franklyn 1 and port forwarded 8080 to
the local 8080 via ssh.

```shell
ssh -L 8080:localhost:8080 franklyn@franklyn.htl-leonding.ac.at
```

this had to happen in the school network as direct outside ssh access to the franklyn server
is not provided and the intermediate leotux server doesn't allow jumping over it using the `-J`
flag in ssh.

## Testin

The ddos-tester was started with the following args:

```shell
cargo run -- --clients 50 --noise 0.23 --spread 1
```

This replicates medium busy situations with 2 simultaneously running tests
and an average size of ~1.6 Mb per request per client every 5 seconds
for an overall network usage of:

```
~1.6 Mb / 5 * 50 = ~16 Mb/s
```

## Observations

-   Server CPU immediately hit **100%**.
-   The system could only handle approximately **2.5 requests per second**
    with medium sized images.

## Analysis

We have identified the following issues:

-   Clients were transmitting full png images sized between **1-3 Mb** for
    every request instead of sending deltas
-   The server needs per thread per image uploaded ~400 ms to process the image and save to disk
