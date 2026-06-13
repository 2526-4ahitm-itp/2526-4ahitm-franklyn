---
title: 2026-03-19
date: 2026-03-19
description: IOS User Story
author: Clemens Zangenfeind
---

Time: 20:00 - 21:00

## Attendees

- Jakob Huemer-Fistelberger
- Eldin Beganovic
- Gregor Geigenberger
- Clemens Zangenfeind

## Agenda Items

- Discussing what we will be doing on the IOS front
- Also discussing the new Mobile Computing User Story

## Agenda Decisions

### Websockets Next

- no longer protected by quarkus oidc
- send jwt as parameter
- send through pipe manually (means verify, augment) onMessage (initial message) and depending on User (student, teacher) reject or accept (correct codes when rejecting).
- no param 401, when student tries accessing teacher resource return 403.

### added Tasks to User Story #199

- see GitHub for additional Info

Issue 206: Proctor Student Dashboard
Issue 207: Exam Pin Server
Issue 208: Pin protocol
Issue 209: Proctor Pin selection
Issue 211: Sentinel Pin join
Issue 212: Server Pin

## Related Items

{{< gh-issue-list ids="8" >}}

---

| Who     | What                                      |
| ------- |-------------------------------------------|
| Jakob   | {{< gh-issue-list ids="208, 211, 206" >}} |
| Eldin   | {{< gh-issue-list ids="212" >}}           |
| Gregor  | {{< gh-issue-list ids="209" >}}           |
| Klemens | {{< gh-issue-list ids="207" >}}           |
