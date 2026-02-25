---
title: Release Lifecycle
date: 2025-12-04
---

Franklyn follows [**Semantic Versioning (SemVer)**](https://semver.org/)
with release candidates and optional build metadata.

## Version Format

```
MAJOR.MINOR.PATCH[-rc.N][+dev.N]
```

- **MAJOR**: Incremented for incompatible API changes or breaking changes
- **MINOR**: Incremented for new features that are backward-compatible
- **PATCH**: Incremented for backward-compatible bug fixes (hotfixes)
- **rc.N**: Optional release candidate sequence for the *next* version
- **dev.N**: Optional build metadata sequence for internal testing on any version

### Examples

| Version                   | Type   | Description                                  |
| ------------------------- | ------ | -------------------------------------------- |
| `1.2.3`                   | Stable | Latest official release                      |
| `1.2.4-rc.1`              | RC     | First release candidate for next patch       |
| `1.3.0-rc.1`              | RC     | First release candidate for next minor       |
| `2.0.0-rc.1`              | RC     | First release candidate for next major       |
| `1.2.3+dev.1`             | Dev    | Dev build on a stable release                |
| `1.2.4-rc.2+dev.1`        | Dev    | Dev build on a release candidate             |
| `1.2.4-rc.2+dev.1`        | Dev    | Dev build updated for newer commit           |

{{< callout type="info" >}}
**Initial Development (0.y.z):** Major version zero is for initial development.
The public API should not be considered stable. Anything may change at any time.
{{< /callout >}}

## Release Candidates (RC)

Release candidates are pre-release versions for the *next* target version.
The target version must be bumped first, then `-rc.N` is added.

- `-rc.N` indicates sequencing toward the upcoming release
- RCs precede the associated stable release in version order

**Starting an RC chain (from stable):**

```
1.2.3 → 1.2.4-rc.1
```

**Incrementing an RC:**

```
1.2.4-rc.1 → 1.2.4-rc.2 → 1.2.4-rc.3
```

**Releasing after RC:**

```
1.2.4-rc.3 → 1.2.4
```

## Dev Build Metadata

Dev builds are internal snapshots for testing the current code state without
changing version precedence. They use build metadata with a counter.

- Uses `+dev.N` (previous N + 1 starting at 1)
- Can be applied to stable or RC versions

**Dev build on stable:**

```
1.2.3 → 1.2.3+dev.1
```

**Dev build on RC:**

```
1.2.4-rc.2 → 1.2.4-rc.2+dev.1
```

**Replacing a dev build:**

```
1.2.4-rc.2+dev.1 → 1.2.4-rc.2+dev.2
```

## Release Flow

Version changes are driven by the target release intent, independent of any
tooling or automation details.

- **Stable release:** increment MAJOR, MINOR, or PATCH and publish `X.Y.Z`
- **Release candidate:** bump the target version first, then add `-rc.N`
- **Dev build:** keep the base version and append `+dev.N`

## Distribution Channels

- **Docker tags:** `stable` and `latest` for releases, `dev` for rc/dev builds
- **Debian APT suites:** `stable` for releases only, `dev` for rc + dev builds

## Version File

The current version is stored in the `VERSION` file at the repository root.
This file is the single source of truth for tags and releases.
Tags and release artifacts are built from the committed `VERSION` value.
