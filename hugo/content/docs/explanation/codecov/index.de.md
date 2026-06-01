---
title: Code-Abdeckung
date: 2026-02-09
---

Wir verwenden [Codecov](https://Codecov.io/) für unsere Code-Abdeckung.

Die Konfiguration für Codecov ist bereits im Projektstamm in der Datei `codecov.yml` definiert.

Diese Konfiguration definiert Flags sowie Projekt- und Patch-Ziele, bei denen ein PR die Checks nicht besteht,
wenn die Projekt- bzw. Patch-Abdeckung unter den angegebenen Werten liegt.

{{< callout type="info">}}
Nach der Einrichtung sind keine zusätzlichen Einstellungen in der Codecov-Oberfläche erforderlich.
{{< /callout >}}

## Erste Schritte

Um Codecov im Projekt zu nutzen, installiere die Codecov GitHub App für die Organisation
und gib Codecov Zugriff auf das Franklyn-Repository. Dafür werden Admin-Berechtigungen benötigt,
also bitte deinen Lehrer, die Codecov GitHub App für euch zu installieren.

Gehe dann zu [app.codecov.io](https://app.codecov.io), wähle die Organisation aus, in der sich das Franklyn-Repository befindet,
und klicke für das Franklyn-Repository auf „configure".

Mehr dazu unter [Codecov Quick Start](https://docs.Codecov.com/docs/quick-start)

## Funktionsweise

`pr-checks` ist ein Workflow, der bei PRs auf main ausgeführt wird.
Der PR-Checks-Workflow testet jedes Teilprojekt und erstellt einen Coverage-Report
(`cobertura.xml` für Rust mit tarpaulin, `jacoco-report/jacoco.xml` für Maven jacoco usw.).

Die [Codecov GitHub Action](https://github.com/codecov/codecov-action) läuft für jedes Projekt und kümmert sich darum,
den Report automatisch zu finden und beim Upload mit den entsprechenden [Flags](#flags) hochzuladen.

Die Coverage-Ziele und Schwellenwerte sind unter [Coverage](#coverage) definiert.

## Flags

Flags ermöglichen es, Reports pro Teilprojekt zu gruppieren (sentinel, server, proctor).

Alle Sentinel-Reports werden mit dem Flag `sentinel` hochgeladen, ebenso `server` und `proctor`.

Flags werden in der `codecov.yml` unter dem Abschnitt `flags` definiert.

## Coverage

Der Abschnitt `coverage` in `codecov.yml` definiert das Projekt- bzw. Patch-Ziel und den Schwellenwert.

- **project** misst die gesamte Projektabdeckung.
  - **default** definiert das Coverage-Ziel und den Schwellenwert für alle Teilprojekte zusammen.
  - **sentinel/server/proctor** definiert das Coverage-Ziel und den Schwellenwert für das jeweilige Teilprojekt-Flag aus dem Abschnitt `flags`.
- **patch** misst nur die Abdeckung von neuem Code, der in einem PR eingeführt wurde.
  - **sentinel/server/proctor** definiert die Patch-Coverage für das jeweilige Teilprojekt-Flag aus dem Abschnitt `flags`.
