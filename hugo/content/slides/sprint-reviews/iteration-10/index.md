---
title: "Iteration 10 Sprint Review"
date: 2026-04-06
layout: single
type: slides
watermark: Iteration 10
---

{{< front title="Iteration 10" subtitle="Sprint Review" >}}

---

## Stats

{{< stats >}}
{{< stat value="143" label="Commits" color="info" >}}
{{< stat value="11" label="Pull Requests" color="accent-2" >}}
{{< stat value="7" label="Issues Resolved" color="success" >}}
{{< stat prefix="+" value="7,270" label="Lines Added" color="success" >}}
{{< stat prefix="-" value="387" label="Lines Removed" color="error" >}}
{{< stat value="92" label="Files Modified" color="warning" >}}
{{< /stats >}}

---

## User Story

{{< gh-issue-list ids="280" >}}

**As a** Teacher\
**I want** to use Franklyn during an exam\
**So that** I can provide an isolated environment.

<ul style="font-size: 1.6rem">
  <li style="font-size: inherit">Easy installation/use of Franklyn Sentinel {{% gh-issue-list ids="165" %}}</li>
  <li style="font-size: inherit">Tell teachers how to use Proctor or where to proctor on front page</li>
  <li style="font-size: inherit">FSD Up to date.</li>
</ul>

---

## Organisatorisches

{{% steps %}}
**Latest** (v0.7.0) bekommt neue features. `main`

**LTS** Line (v0.6.x) bleibt stabil. `release/0.6.x`
{{% /steps %}}

---

## Release Workflow

{{< center >}}

{{< twocol >}}
{{< col >}}

### v0.6.0 Release Trigger

{{< plantuml src="./release-trigger-0.6.0.puml" />}}
{{< /col >}}
{{< col >}}

### v0.7.0 Release Trigger

{{< plantuml src="./release-trigger-0.7.0.puml" />}}
{{< /col >}}
{{< /twocol >}}
{{< /center >}}

---

## Notice Banners

{{% steps %}}
Bieten eine Möglichkeit, um Lehrer aus sicht eines Admins zu informieren.

**3 Typen:**

- Alarm (rot, permanent)
- Zeitbasiert
- Einmalig

![](./banners.png)
{{% /steps %}}

---

{{< center >}}

## Demo

{{< /center >}}
