---
title: 2026-01-29
date: 2026-01-29
description: Reimplementing the Server brosky
author: Jakob Huemer-Fistelberger
---

Time: 20:30 - 22:00

## Attendees

- Jakob Huemer-Fistelberger (Second and First)
- Eldin Beganovic (Second and First)
- Gregor Geigenberger (Second and First)
- Clemens Zangenfeind (Second)

## Agenda Items

- Communications protocol for websockets between server-proctor, server-sentinel
- Sentinel Alpha-, Delta-Frame behaviour
- Proctor Frame Rendering
- Server has in Memory Cache for Frames

## Agenda Decisions

### Communications Protocol

Use json for now.
Define a communication Protocol in json.

### Alpha-, Delta-Frame behaviour

Scrap that for now. We send PNGs.

PNGs have an index and a sentinel id.

### Frame rendering

Proctor just gets that PNG and displays it.

### Server

Stores Image with index per Sentinel.
Lock the whole cache while reading/writing.
Later improve that.

## Related Items

{{< gh-issue-list ids="8" >}}

---

| Who     | What                              |
| ------- | --------------------------------- |
| Jakob   | {{< gh-issue-list ids="95,93" >}} |
| Eldin   | {{< gh-issue-list ids="95" >}}    |
| Gregor  | {{< gh-issue-list ids="95,96" >}} |
| Klemens | {{< gh-issue-list ids="95,94" >}} |
