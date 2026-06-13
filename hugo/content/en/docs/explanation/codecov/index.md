---
title: Code Coverage
date: 2026-02-09
---

We use [Codecov](https://Codecov.io/) for our code coverage.

The configuration for Codecov is already defined in the root of the project
in `codecov.yml`.

This configuration defines flags and project/patch targets where a PR fails the checks
if the project/patch coverage is below the specified values.

{{< callout type="info">}}
No extra settings are required in the Codecov UI after setup.
{{< /callout >}}

## Getting Started

To start using Codecov on the project, install the Codecov GitHub App for the organisation
and give Codecov access to the Franklyn repository. This requires admin permissions you you have to ask your teacher
to install the Codecov GitHub App for you.

Then go to [app.codecov.io](https://app.codecov.io), choose the organisation in which the Franklyn repository
is in and then click on "configure" for the Franklyn repository.

Read more at [Codecov quick start](https://docs.Codecov.com/docs/quick-start)

## How it works

`pr-checks` is a workflow that runs on PRs targeting main.
The PR-Checks workflow tests each subproject and generates a coverage report
(`cobertura.xml` for rust using tarpaulin, `jacoco-report/jacoco.xml` for maven jacoco, ...).

The [Codecov GitHub Action](https://github.com/codecov/codecov-action) runs for each project and takes care of automatically finding the report and uploading it with its [flags](#flags) at upload time.

The coverage targets and thresholds are defined in [Coverage](#coverage).

## Flags

Flags make it possible to group reports per subproject (sentinel, server, proctor).

All sentinel reports are uploaded with the `sentinel` flag and so with the `server` and the `proctor`.

Flags are defined in the `codecov.yml` under the `flags` section.

## Coverage

The `coverage` section in `codecov.yml` defines the project/patch target and threshold.

- **project** measures the complete project coverage.
  - **default** defines the coverage target and threshold for all subprojects combined.
  - **sentinel/server/proctor** defines the coverage target and threshold for the subproject flag defines in ´flags` section.
- **patch** only measures the coverage of new code introduced in a PR.
  - **sentinel/server/proctor** defines the patch coverage for the subproject flag defined in `flags` section.
