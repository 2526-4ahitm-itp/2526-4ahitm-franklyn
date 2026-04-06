---
title: "Iteration 7 Sprint Review"
date: 2026-03-16
layout: single
type: slides
---

{{< front title="Iteration 7" subtitle="Sprint Review" >}}

---

## Overview

{{% steps %}}

A Keycloak login is now required for sentinel and proctor users.

The names of students are now displayed under their screen in the proctor layout.

A screen in proctor can now be focused by clicking the screen and it is displayed in a higher resolution.

{{% /steps %}}

---

## Stats

{{< stats >}}
{{< stat value="166" label="Commits" color="info" >}}
{{< stat value="32" label="Pull Requests" color="accent-2" >}}
{{< stat value="20" label="Issues Resolved" color="success" >}}
{{< stat prefix="+" value="9,139" label="Lines Added" color="success" >}}
{{< stat prefix="-" value="1,623" label="Lines Removed" color="error" >}}
{{< stat value="195" label="Files Modified" color="warning" >}}
{{< /stats >}}

---

## Related User Stories

### User Story

- {{< gh-issue-list ids="141" >}}

### Other Issues

- {{< gh-issue-list ids="169,157,164,147,170,171,163" >}}

---

## Image Formatting

By default, an image injected via markdown sits cleanly aligned to the left of your slide. It is bounded to not take up more than `60vh` so it doesn't break the page!

{{< figure src="https://picsum.photos/seed/helloworld/1000/400" title="Some Caption lorem kjlhsdlf lkjasf kljasdf lkjasdlkf jhaslkdjfh laksjdhfjkalsdkfj hlkdsfhlkash  lfhasdfl khasldkf haslkdfh ljkasdhf l asdf asdf asdf  ashdfkg ajshdfjlk hasojd fhasdhf lk" >}}

---

{{< center >}}
#### Off-Thread Parsing

## JS parsing now runs on **worker threads**

Written in safe Rust, so parallelizing it was straightforward.
{{< /center >}}

---

## Releases

- **GitHub Release v0.5.0:** Tag `v0.5.0` is now available on GitHub.
- **Local Release Note:** Available at [v0.5.0](/releases/v0-5-0)
