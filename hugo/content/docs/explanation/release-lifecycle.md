---
title: Release Lifecycle
date: 2026-04-28
---

Franklyn releases are driven by git tags. CI does not create tags.

## Version format

```
X.Y.Z
X.Y.Z-rc.N
X.Y.Z+dev.N
```

Any version containing `-` or `+` is treated as a prerelease/dev build.

## Tagging and VERSION

- Tags are pushed manually and must match the `VERSION` file on that commit.
- Tag format: `vX.Y.Z`, `vX.Y.Z-rc.N`, `vX.Y.Z+dev.N` (and `-alpha`, `-beta`, etc.).

Example:

```bash
git tag -a v0.6.4 -m "[lts] backport fix"
git push origin v0.6.4
```

## LTS and prerelease handling

- LTS is signaled by an annotated tag containing `[lts]`.
- Pre-release/dev tags are all treated the same by CI; they exist for internal testing.

## Branches we use

- LTS line: create `release/X.Y.x` and cherry-pick fixes there (e.g. `release/0.6.x`).
- RC line: feature freeze with fixes only, either on `main` or on a short-lived branch like `release/0.6.3` for `0.6.3-rc.1`.
- Dev builds can happen on any commit.

## Publishing behavior

Docker tags for server and proctor:

| Release type | Tags pushed |
|---|---|
| Stable | `X.Y.Z`, `latest` |
| LTS | `X.Y.Z`, `X.Y`, `lts` |
| Prerelease/dev | `X.Y.Z-rc.N` or `X.Y.Z+dev.N`, `dev` |

For LTS, the `X.Y.Z` tag is the normal version tag, while `X.Y` and `lts` float to the newest patch in that LTS line (e.g. `0.5.4` updates `0.5` and `lts`).

## Compatibility

We follow SemVer. Compatibility within `1.x.x` is expected. `0.x.x` is still just SemVer for us and may change more quickly.
