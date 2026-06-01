---
title: Festplattenspeicher
---

Dieses Dokument spezifiziert, wie Fragmente auf der Festplatte gespeichert werden.

Siehe [Terminologie](../terminology).

## Speicherprinzip

Der Server schreibt Fragmente **unverändert** auf die Festplatte – ohne Verarbeitung, Transcodierung oder Modifikation. Die vom Sentinel empfangenen Bytes sind exakt die Bytes, die auf die Festplatte geschrieben werden.

## Was gespeichert wird

| Element | Gespeichert | Format |
|------|--------|--------|
| Initialisierungssegment | Ja | Rohe fMP4-Bytes |
 | Medienfragmente | Ja | Rohe fMP4-Bytes |
| Metadaten | Ja (separat) | Siehe [Metadaten](../metadata) |

## Dateiorganisation

Fragmente sind auf der Festplatte nach Sentinel und Session organisiert.

### Verzeichnisstruktur

```
{storage_root}/
└── {sentinelId}/
    └── {sessionId}/
        ├── init.mp4
        ├── 000000.m4s
        ├── 000001.m4s
        ├── 000002.m4s
        └── ...
```

| Komponente | Beschreibung |
|-----------|-------------|
| `storage_root` | Basisverzeichnis für alle Video-Speicher |
| `sentinelId` | Eindeutige Kennung des Sentinels |
| `sessionId` | Eindeutige Kennung der Session (z. B. Zeitstempel oder UUID) |

### Beispiel

```
/var/franklyn/video/
└── sentinel-a1b2c3/
    └── 2026-02-05T14-30-00Z/
        ├── init.mp4
        ├── 000000.m4s
        ├── 000001.m4s
        ├── 000002.m4s
        └── ...
```

## Schreibzeitpunkt

Fragmente werden sofort beim Empfang vom Sentinel auf die Festplatte geschrieben.

| Ereignis | Aktion |
|-------|--------|
| Initialisierungssegment empfangen | In `init.mp4` schreiben |
 | Medienfragment empfangen | In `{sequence}.m4s` schreiben |

{{< callout type="info" >}}
Das Schreiben erfolgt parallel zum Hinzufügen des Fragments in den Speicherpuffer. Der Live-Streaming-Pfad (Speicher) und der Archivierungspfad (Festplatte) sind unabhängig voneinander.
{{< /callout >}}

## Keine Server-Verarbeitung

Der Server führt **keine Videoverarbeitung** durch:

| Operation | Vom Server durchgeführt |
|-----------|---------------------|
| Dekodierung | Nein |
| Kodierung | Nein |
| Transcodierung | Nein |
| Re-Muxing | Nein |
| Frame-Extraktion | Nein |
| Verkettung | Nein |

Die Rolle des Servers ist rein:
- Bytes vom Sentinel empfangen
- Bytes auf Festplatte schreiben
- Bytes von Festplatte lesen
- Bytes an Proctor senden

## Dateiintegrität

Jede Fragment-Datei ist ein vollständiges, gültiges fMP4-Medienfragment. Zusammen mit dem Initialisierungssegment kann jedes Fragment unabhängig dekodiert werden, wenn es der Reihe nach angehängt wird; ein Proctor SOLLTE bei einem Join-Fragment beginnen.

### Wiedergabe von Festplatte

Um gespeichertes Video wiederzugeben:

{{% steps %}}

### Initialisierungssegment laden

`init.mp4` für die Session lesen.

### Medienfragmente der Reihe nach laden

Fragment-Dateien in Sequenzreihenfolge lesen: `000000.m4s`, `000001.m4s` usw.

### Verketten und abspielen

Initialisierungssegment + Medienfragmente einem fMP4-kompatiblen Player oder MSE übergeben.

{{% /steps %}}

## Aufbewahrung

Die Spezifikation schreibt keine Aufbewahrungsrichtlinie vor. Implementierungen können:

 - Alle Fragmente unbegrenzt aufbewahren
 - Fragmente nach einem konfigurierten Zeitraum löschen
- Ganze Sessions basierend auf einer Richtlinie löschen
- Manuelles oder automatisches Bereinigen bereitstellen

## Spätere Ansicht

Gespeicherte Fragmente können per HTTP für die spätere Ansicht abgerufen werden. Siehe [Transport](../transport) für Details zum historischen Fragment-Zugriff.

### Transcodierung für Export

Zum Exportieren von Video in ein Standardformat (z. B. eine einzelne MP4-Datei) kann ein separater **Transcodierungs-Client**:

1. Das Initialisierungssegment abrufen
2. Alle Medienfragmente einer Session abrufen
3. Zu einer einzelnen abspielbaren Datei verketten

Diese Transcodierung erfolgt außerhalb des Servers (im Proctor-Browser oder einem dedizierten Tool), was das Prinzip aufrechterhält, dass der Server keine Videoverarbeitung durchführt.

{{< callout type="warning" >}}
Der Transcodierungs-/Export-Workflow liegt außerhalb des Geltungsbereichs dieser Spezifikation. Die gespeicherten Fragmente sind für die Wiedergabe via MSE oder externe Tools ausreichend.
{{< /callout >}}
