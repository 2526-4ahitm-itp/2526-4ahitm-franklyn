---
title: "Iteration 8 Sprint Review"
date: 2026-04-06
layout: single
type: slides
---

{{< front title="Iteration 8" subtitle="Sprint Review" >}}

---

## Stats

{{< stats >}}
{{< stat value="112" label="Commits" color="info" >}}
{{< stat value="19" label="Pull Requests" color="accent-2" >}}
{{< stat value="22" label="Issues Resolved" color="success" >}}
{{< stat prefix="+" value="5,108" label="Lines Added" color="success" >}}
{{< stat prefix="-" value="3,440" label="Lines Removed" color="error" >}}
{{< stat value="189" label="Files Modified" color="warning" >}}
{{< /stats >}}

---

## User Story

{{< gh-issue-list ids="199" >}}

**As a** teacher\
**I want** to run my own exam\
**So that** so that i can see only the students of my exam.

<ul style="font-size: 1.6rem">
  <li style="font-size: inherit">at least 2 exams can be run in parallel.</li>
  <li style="font-size: inherit">the teacher creates two exams.<br/>
  The teacher forwards the two pin codes to two different students.<br/>
  The students login with the pin code.<br/>
  The teacher can switch between their exams and sees only one students in each test with matching pin codes.</li>
</ul>

---

## Features

{{% steps %}}
**Mehrere Lehrer** können Tests erstellen und nur ihre **eigenen Schüler** sehen.

Jeder Test bekommt einen **4-stelligen Pin**, mit dem der Schüler dem Test beitreten kann.

**Wayland** wird unterstützt.
{{% /steps %}}

---

## Architecture

{{< center >}}

{{< twocol >}}
{{< col >}}

### v0.5.0 (xcap)

{{< plantuml src="./arch-old.puml" />}}
{{< /col >}}
{{< col >}}

### v0.6.0 (GStreamer)

{{< plantuml src="./arch-new.puml" />}}
{{< /col >}}
{{< /twocol >}}
{{< /center >}}

---

{{< center >}}

## Demo

{{< /center >}}
