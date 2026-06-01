---
title: Release-Lebenszyklus
date: 2026-04-28
---

Franklyn-Releases werden durch Git-Tags gesteuert. CI erstellt keine Tags.

## Versionsformat

```
X.Y.Z
X.Y.Z-rc.N
X.Y.Z+dev.N
```

Jede Version, die `-` oder `+` enthält, wird als Vorveröffentlichung/Dev-Build behandelt.

## Tagging und VERSION

- Tags werden manuell gepusht. Vor dem Tagging muss die `VERSION`-Datei im Ziel-Commit
  manuell aktualisiert werden — der Tag-Name ohne führendes `v` muss exakt mit dem Inhalt übereinstimmen
  (z. B. erfordert Tag `v0.6.4` den Inhalt `0.6.4` in `VERSION`).
- Tag-Format: `vX.Y.Z`, `vX.Y.Z-rc.N`, `vX.Y.Z+dev.N` (sowie `-alpha.N`, `-beta.N` usw.).

Beispiel:

```shell
echo -n "0.6.4" > VERSION
git add VERSION
git commit -m "chore: bump version to 0.6.4"
git tag -a v0.6.4 -m "[lts] backport fix"
git push origin HEAD --follow-tags
```

## LTS und Vorveröffentlichungen

- LTS wird durch einen annotierten Tag mit `[lts]` signalisiert.
- Vorveröffentlichungs-/Dev-Tags werden von CI alle gleich behandelt; sie existieren für interne Tests.

## Verwendete Branches

- LTS-Linie: `release/X.Y.x` erstellen und Fixes per Cherry-Pick einpflegen (z. B. `release/0.6.x`).
- RC-Linie: Feature-Freeze mit nur noch Bugfixes, entweder auf `main` oder auf einem kurzlebigen Branch wie `release/0.6.3` für `0.6.3-rc.1`.
- Dev-Builds können auf jedem Commit erfolgen.

## Veröffentlichungsverhalten

Docker-Tags für Server und Proctor:

| Release-Typ | Gepushte Tags |
|---|---|
| Stabil | `X.Y.Z`, `latest` |
| LTS | `X.Y.Z`, `X.Y`, `lts` |
| Vorveröffentlichung/Dev | `X.Y.Z-rc.N` oder `X.Y.Z+dev.N`, `dev` |

Bei LTS ist der `X.Y.Z`-Tag der normale Versions-Tag, während `X.Y` und `lts` auf den neuesten Patch in der LTS-Linie zeigen (z. B. aktualisiert `0.5.4` sowohl `0.5` als auch `lts`).

## Kompatibilität

Wir folgen SemVer. Kompatibilität innerhalb von `1.x.x` wird erwartet. `0.x.x` ist für uns ebenfalls SemVer, kann sich aber schneller ändern.
