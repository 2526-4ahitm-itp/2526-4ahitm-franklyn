---
title: 2025-12-07 Iteration 2
date: 2025-12-07
---

{{< report-card commits="162" prs="17" issues="9" newlines="5936" remlines="248" >}}

Report Period: 2025-11-16 - 2025-12-07

## Overview

- Added Kubernetes Deployments and other.
- Added Backend Endpoints for creating and controlling tests.
- Added Frontend for creating, starting and stopping tests.
- Added multiple diagrams and docs for the project setup

## Related GitHub Issues

{{< gh-issue-list ids="14,55,47,50,49,51,34,39,14,22" >}}

## Related PRs

{{< gh-issue-list ids="64,63,61,62,60,58,56,53,46,45,41,40,37,38,31,35,5,30" >}}

## Other related items

- [Looks / Color specification](/docs/looks/color-specification/_index.md)
- [MoM 2025-11-20](/docs/mom/2025-11-20)
- [MoM 2025-11-27](/docs/mom/2025-11-27)
- [Scrum Team](/docs/scrum)
- Architecture
  - [CI/CD](/docs/architecture/ci-cd)
  - [Release Lifecycle](/docs/architecture/release-lifecycle)
  - [Authentication](/docs/architecture/authentication)

### Completed This Period

#### Documentation

- Added architecture pages: authentication, CI/CD, release lifecycle, and server logistics.
- Added look-and-feel documentation and a color specification with PDF.
- Added scrum overview and assets for the new scrum team.
- Added MoM entries for 2025-11-20 and 2025-11-27.

#### Infrastructure / Deployments

- Added Kubernetes manifests (ingress, deployments, config map, volume claims) 
  for Hugo, Postgres, Proctor, and Server.
- Added Docker CI files for Hugo, Proctor and Server.

#### Proctor (frontend)

- Added new views and services for test pages and a TestView.
- Added nginx configuration for Proctor.

#### Server

- Introduced teacher and test endpoints and related DTOs/mappers.
