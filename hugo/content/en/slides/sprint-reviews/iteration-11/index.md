---
title: "Iteration 10 Sprint Review"
date: 2026-05-02
layout: single
type: slides
watermark: Iteration 11
---

{{< front title="Iteration 11" subtitle="Sprint Review" >}}

---


## User Story

{{< gh-issue-list ids="308" >}}

**As a** Teacher\
**I want** to view the screen recording of a student after an exam\
**So that** I can check something after the exam.

<ul style="font-size: 1.6rem">
  <li style="font-size: inherit"> The entire session of the student is available as a video after completion
{{% gh-issue-list ids="313,311" %}}</li>
  <li style="font-size: inherit">The teacher can download the video per student. 
{{% gh-issue-list ids="314" %}}</li>
  <li style="font-size: inherit">An option to download all students videos at once. {{% gh-issue-list ids="314" %}}</li>
</ul>

---

## Video Download

![img.png](downloads-list.png)

![img.png](download-all.png)

---

## Internationalization

{{% steps %}}

Sprachen im Proctor:
- Deutsch
- English

{{< twocol >}}

{{< col >}}
![](lang-english.png)
{{< /col >}}

{{< col >}}
![](lang-german.png)
{{< /col >}}

{{< /twocol >}}

{{% /steps %}}

---

## Notice Banners


{{< twocol >}}

{{< col >}}
{{% steps %}}
Notice Banners unterstützen jetzt auch Markdown

- **bold**
- *italic*
- ~~strikethrough~~
- inline `code`
- [link](https://youtube.com)

{{% /steps %}}
{{< /col >}}

{{< col >}}
{{% steps %}}
![img.png](notice-banners-markdown.png)
{{% /steps %}}
{{< /col >}}

{{< /twocol >}}



---

## Stats

{{< stats >}}
{{< stat value="113" label="Commits" color="info" >}}
{{< stat value="19" label="Pull Requests" color="accent-2" >}}
{{< stat value="16" label="Issues Resolved" color="success" >}}
{{< stat prefix="+" value="4,643" label="Lines Added" color="success" >}}
{{< stat prefix="-" value="845" label="Lines Removed" color="error" >}}
{{< stat value="98" label="Files Modified" color="warning" >}}
{{< /stats >}}


---

{{% center %}}

![Franklyn Team](franklyn-team.png)
{{% /center %}}
