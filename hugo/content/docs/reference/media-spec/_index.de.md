---
title: Medien-Streaming-Spezifikation
---

Diese Spezifikation definiert, wie Video für das Echtzeit-Screensharing zwischen Sentinels und Proctors kodiert, segmentiert, gespeichert und übertragen wird.

Diese Spezifikation wurde iterativ mit GPT 5.2 erstellt. Den Chat findest du im Repository-Stammverzeichnis bei diesem Commit `a46981632a5e3c2a9bac8f540a6cefa1d06d4082`.

## Übersicht

| Aspekt | Entscheidung |
|--------|----------|
| **Codec** | H.264 |
| **Container** | Fragmented MP4 (fMP4) |
| **Browser-Wiedergabe** | Media Source Extensions (MSE) |
| **Fragment-Dauer** | Variabel, kurz (Implementierungsentscheidung für Echtzeit-Übertragung) |
| **Keyframes** | On-Demand + max. 20–30 s Intervall + bei FPS-Änderung |
| **Speicherpuffer** | Alle Fragmente der letzten 15–20 Sekunden (konfigurierbar) |
| **Festplattenspeicher** | Alle Fragmente werden unverändert geschrieben |
| **Auflösung** | Max. 1080p, herunterskaliert unter Beibehaltung des Seitenverhältnisses |
| **Bildrate** | 1/5 fps bis 5 fps, zeitlich variabel |
| **Live-Transport** | WebSocket (Server pusht Fragmente) |
| **Historischer Transport** | HTTP (Proctor holt vom Festplattenspeicher) |

## Komponenten

- **Sentinel**: Erfasst den Bildschirm, kodiert Video, sendet Fragmente an den Server
- **Server**: Empfängt Fragmente, puffert im Speicher, schreibt auf Festplatte, leitet an Proctors weiter
- **Proctor**: Empfängt Fragmente, dekodiert via MSE, zeigt Video an

## Dokumentation

{{< cards >}}
{{< card link="terminology" title="Terminologie" icon="book-open" subtitle="Definitionen: Fragmente vs. Keyframes vs. Init" >}}
{{< card link="encoding" title="Kodierung" icon="chip" subtitle="H.264-Codec-Einstellungen und Bildrate" >}}
{{< card link="container" title="Container" icon="archive" subtitle="fMP4-Struktur und Initialisierung" >}}
{{< card link="segments" title="Fragmente" icon="collection" subtitle="Fragment-Takt und Join-Fragmente" >}}
{{< card link="memory-buffer" title="Speicherpuffer" icon="server" subtitle="Serverseitiges Puffern für Live-Streams" >}}
{{< card link="disk-storage" title="Festplattenspeicher" icon="database" subtitle="Persistente Fragment-Speicherung" >}}
{{< card link="metadata" title="Metadaten" icon="document-text" subtitle="In-Stream- und Anwendungsmetadaten" >}}
{{< card link="transport" title="Transport" icon="switch-horizontal" subtitle="WebSocket- und HTTP-Übertragung" >}}
{{< card link="join-flow" title="Join-Ablauf" icon="login" subtitle="Wie Proctors einem Stream beitreten" >}}
{{< card link="control-messages" title="Steuernachrichten" icon="adjustments" subtitle="Keyframe- und FPS-Änderungsanfragen" >}}
{{< /cards >}}
