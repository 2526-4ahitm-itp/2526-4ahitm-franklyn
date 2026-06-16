---
title: "Iteration 12 Sprint Review"
date: 2026-06-15
layout: single
type: slides
watermark: Iteration 12
---

{{< front title="Iteration 12" subtitle="Sprint Review" >}}

---

## Neues Franklyn Sentinel CLI

{{% steps %}}
<div style="padding-bottom: 3rem">

**Test beitreten:**

```shell
franklyn join <pin>
```

</div>

<div style="padding-bottom: 3rem">

**Server ändern:**

```shell
franklyn config set api_url "franklyn3.htl-leonding.ac.at/api"
```

</div>

<div>

**Konfiguration editieren:**

```shell
franklyn config edit  # öffnet $HOME/.config/franklyn/config.toml
```

</div>

{{% /steps %}}

---

## Configuration

{{% center %}}
{{< plantuml src="config-layers.puml" />}}
{{% /center %}}

---

## Guides

<div style="display: flex; gap: 1.5vw; justify-content: center; align-items: flex-start; margin-top: 2vh;">
  <img src="students-setup.png" style="height: 45vh; width: auto;">
  <img src="teacher-preparing-students.png" style="height: 45vh; width: auto;">
  <img src="teachers-guide.png" style="height: 45vh; width: auto;">
  <img src="administrator-guide.png" style="height: 45vh; width: auto;">
</div>

<p style="text-align: center; margin-top: 1.5vh;"><a href="/guide">franklyn.htl-leonding.ac.at/guide</a></p>

---

## Stats

{{< stats >}}
{{< stat value="132" label="Commits" color="info" >}}
{{< stat value="11" label="Pull Requests" color="accent-2" >}}
{{< stat value="9" label="Issues Resolved" color="success" >}}
{{< stat prefix="+" value="11,189" label="Lines Added" color="success" >}}
{{< stat prefix="-" value="2,772" label="Lines Removed" color="error" >}}
{{< stat value="280" label="Files Modified" color="warning" >}}
{{< /stats >}}

---

{{% center %}}

![Franklyn Team](franklyn-team.png)

{{% /center %}}
