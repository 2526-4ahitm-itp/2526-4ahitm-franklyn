---
title: "Project State"
date: 2026-10-05
layout: single
type: slides
watermark: Franklyn
---

{{< front title="Franklyn" subtitle="Project State" >}}

---

## What Franklyn Does

{{% steps %}}

Students join an exam with a **4-digit pin** — their screen is streamed live.

The teacher watches **all screens in a grid** or zooms into a **single screen**.

Every session is **recorded** and can be reviewed or downloaded after the exam.

{{% /steps %}}

---

## How an Exam Runs

{{% steps %}}

**1. Create** — teacher creates an exam, server generates a pin.

**2. Join** — student runs `franklyn join <pin>`, Sentinel starts capturing.

**3. Monitor** — teacher watches the grid, zooms into any student.

**4. End** — exam closes, streams stop, recordings are finalized.

**5. Review** — teacher replays or downloads the videos.

{{% /steps %}}

---

## Architecture

{{% center %}}
{{< plantuml src="arch.puml" />}}
{{% /center %}}

---

## Proctor

{{% center %}}

<img src="front-page.png" style="height: 55vh; width: auto;">

{{% /center %}}

<p style="text-align: center; width: 100%">Vue 3 · GraphQL + WebSocket · Keycloak login · German and English · light/dark theme</p>

---

## Sentinel

{{% steps %}}
<div style="padding-bottom: 2rem">

```shell
franklyn join <pin>
franklyn config set api_url "franklyn3.htl-leonding.ac.at/api"
```

</div>

<div style="padding-bottom: 2rem">

Rust + GStreamer · **X11 and Wayland** (XDG desktop portal)

</div>

<div>

Layered config: **system → user → environment**

</div>

{{% /steps %}}

---

## Streaming Pipeline

<div style="font-size: 1.6rem">

- **H.264** encoded on the student device, no transcoding on the server
- Packed as **fragmented MP4** — plays natively in the browser via MSE
- Transported over **WebSocket** with **protobuf** messages
- Adaptive rate: from 0.2 fps idle up to 30 fps at 1080p

</div>

---

## Recordings

{{% center %}}

<img src="downloads-list.png" style="height: 48vh; width: auto;">

{{% /center %}}

<p style="text-align: center; width: 100%">Stored per session · bulk download after the exam · auto-deleted 30 days after exam end</p>

---

## Operations

<div style="font-size: 1.6rem">

- **Nix flake** as the single source of truth for dev shells, CI and builds
- Path-filtered **PR checks** per component, Codecov on the server
- Deployment via **Docker Compose** behind Caddy, with PostgreSQL
- Packaging: **openSUSE Build Service** (rpm), aptly (deb), Windows installer
- **GlitchTip / Sentry** error monitoring in Proctor and Sentinel

</div>

---

## Documentation

<div style="display: flex; gap: 1.5vw; justify-content: center; align-items: flex-start; margin-top: 2vh;">
  <img src="students-setup.png" style="height: 45vh; width: auto;">
  <img src="teachers-guide.png" style="height: 45vh; width: auto;">
  <img src="administrator-guide.png" style="height: 45vh; width: auto;">
</div>

<p style="text-align: center; width: 100%">Guides for students, teachers, administrators and self-hosting · Diátaxis-structured developer docs · protocol and media specs</p>

---

## By the Numbers

{{< stats >}}
{{< stat value="v0.9.5" label="Current Release" color="info" >}}
{{< stat value="12" label="Iterations" color="accent-2" >}}
{{< stat value="1,396" label="Commits" color="success" >}}
{{< stat value="14" label="Contributors" color="warning" >}}
{{< stat value="4" label="Clients and Services" color="error" >}}
{{< /stats >}}

---

{{% center %}}

<img src="franklyn-team.png" alt="Franklyn Team" style="height: 62vh; width: auto;">

{{% /center %}}
