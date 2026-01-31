---
title: WS Comms Protocol
---

Real-time communication between the Franklyn server, Sentinels, and Proctors happens over WebSocket connections using JSON messages.

## Overview

| Connection Type   | Role           | Description                                              |
| ----------------- | -------------- | -------------------------------------------------------- |
| Server - Sentinel | Frame Producer | Student machines stream screen captures to the server    |
| Server - Proctor  | Frame Consumer | Teacher interface receives frames for monitored students |

## Documentation

{{< cards >}}
{{< card link="lifecycle" title="Connection Lifecycle" icon="refresh" subtitle="Connection flow and sequence diagrams" >}}
{{< card link="server-sentinel" title="Server - Sentinel" icon="upload" subtitle="Registration and frame streaming" >}}
{{< card link="server-proctor" title="Server - Proctor" icon="download" subtitle="Registration, subscriptions, and frame receiving" >}}
{{< card link="special-datatype" title="Special Datatypes" icon="cube" subtitle="Custom data structures used in messages" >}}
{{< /cards >}}
