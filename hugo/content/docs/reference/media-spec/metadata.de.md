---
title: Metadaten
---

Dieses Dokument spezifiziert die mit Video-Fragmenten verknüpften Metadaten, wo sie gespeichert werden und wie sie synchronisiert werden.

Siehe [Terminologie](../terminology) für den Unterschied zwischen Fragmenten und Join-Fragmenten.

## Metadaten-Speicherorte

Metadaten existieren an zwei Orten:

| Ort | Inhalt | Zweck |
|----------|----------|---------|
| **In-Stream** | Zeitstempel, Dauer | Erforderlich für Browser-Wiedergabe |
| **Anwendung** | Sentinel-ID, Sequenz, Bildrate, Dateipfade | Server/Proctor-Koordination |

## In-Stream-Metadaten

Diese Metadaten werden vom Sentinel-Encoder in den fMP4-Container eingebettet. Der Server modifiziert sie nicht.

### Initialisierungssegment

| Feld | Ort | Beschreibung |
|-------|----------|-------------|
| Zeitskala | `moov` → `mdhd` | Zeiteinheiten pro Sekunde (z. B. 90000) |
| Auflösung | `moov` → `tkhd` | Breite und Höhe in Pixeln |
| Codec-Info | `moov` → `stsd` | H.264 SPS/PPS |

### Medienfragment

In dieser Spezifikation bezieht sich dies auf ein Medien-**Fragment** (`moof` + `mdat`).

| Feld | Ort | Beschreibung |
|-------|----------|-------------|
| Basis-Dekodierzeit | `moof` → `tfdt` | Zeitstempel des ersten Frames im Fragment |
| Sample-Dauern | `moof` → `trun` | Dauer jedes Frames |
| Sample-Größen | `moof` → `trun` | Byte-Größe jedes Frames |

{{< callout type="info" >}}
Die In-Stream-Metadaten sind ausreichend, damit ein Browser das Video mit korrektem Timing dekodieren und anzeigen kann. Die Anwendungsmetadaten bieten zusätzlichen Kontext für das Stream-Management.
{{< /callout >}}

## Anwendungsmetadaten

Diese Metadaten werden vom Server verwaltet und im Speicher gehalten, mit periodischer Persistenz in der Datenbank.

### Metadaten pro Session

| Feld | Typ | Beschreibung |
|-------|------|-------------|
| `sentinelId` | string | Eindeutige Kennung des Sentinels |
| `sessionId` | string | Eindeutige Kennung dieser Session |
| `startTime` | timestamp | Zeitpunkt des Session-Starts |
| `resolution` | object | Breite und Höhe |
| `initSegmentPath` | string | Pfad zum Initialisierungssegment auf der Festplatte |

Beispiel:

```json
{
  "sentinelId": "sentinel-a1b2c3",
  "sessionId": "2026-02-05T14-30-00Z",
  "startTime": "2026-02-05T14:30:00.000Z",
  "resolution": {
    "width": 1920,
    "height": 1080
  },
  "initSegmentPath": "/var/franklyn/video/sentinel-a1b2c3/2026-02-05T14-30-00Z/init.mp4"
}
```

### Metadaten pro Fragment

Diese Spezifikation verwendet den Begriff **Fragment** für die Live-Übertragungseinheit.

| Feld | Typ | Beschreibung |
|-------|------|-------------|
| `sequence` | integer | Fragment-Sequenznummer |
| `startTime` | timestamp | Echtzeit des ersten Frames |
| `duration` | integer | Dauer in Millisekunden |
| `framerate` | number | Frames pro Sekunde während dieses Fragments |
| `filePath` | string | Pfad zur Fragment-Datei auf der Festplatte |
| `isJoin` | boolean | True, wenn dieses Fragment mit einem IDR-Keyframe beginnt |

Beispiel:

```json
{
  "sequence": 142,
  "startTime": "2026-02-05T14:35:42.000Z",
  "duration": 4800,
  "framerate": 5,
  "filePath": "/var/franklyn/video/sentinel-a1b2c3/2026-02-05T14-30-00Z/000142.m4s",
  "isJoin": false
}
```

## Speicher-Ablage

Während des aktiven Streamings werden alle Anwendungsmetadaten für schnellen Zugriff im Speicher gehalten.

### Datenstruktur (konzeptionell)

```
Server-Speicher
├── Aktive Sessions
│   └── {sentinelId}
│       ├── Session-Metadaten
│       ├── Init-Segment (Bytes)
│       └── Fragment-Puffer
│           ├── Fragment 140: { Metadaten, Bytes }
│           ├── Fragment 141: { Metadaten, Bytes }
│           ├── Fragment 142: { Metadaten, Bytes }
│           └── ...
```

### Zugriffsmuster

| Operation | Datenquelle |
|-----------|-------------|
| Proctor tritt Stream bei | Speicher (Initialisierungssegment + gepufferte Fragmente) |
| Neues Fragment trifft ein | Speicher (zum Puffer hinzufügen, Metadaten aktualisieren) |
| Proctor fragt historisches Fragment an | Festplatte (Metadaten zeigen auf Dateipfad) |

## Datenbank-Persistenz

Anwendungsmetadaten werden periodisch zur Dauerhaftigkeit in die Datenbank synchronisiert.

### Synchronisierungsstrategie

| Aspekt | Verhalten |
|--------|----------|
| Auslöser | Periodisch (z. B. alle 5–10 Sekunden) |
| Geltungsbereich | Alle neuen/aktualisierten Fragment-Metadaten seit der letzten Synchronisierung |
| Blockierend | Nicht-blockierend (Synchronisierung erfolgt asynchron) |
| Fehlerbehandlung | Wiederholung beim nächsten Synchronisierungsintervall |

{{< callout type="warning" >}}
Das Synchronisierungsintervall ist ein Implementierungsdetail. Die Kernanforderung ist, dass Echtzeit-Operationen (Live-Streaming) niemals durch Datenbankschreibvorgänge blockiert werden.
{{< /callout >}}

### Was persistiert wird

| Daten | Persistiert |
|------|-----------|
| Session-Metadaten | Ja |
| Fragment-Metadaten | Ja |
| Fragment-Bytes | Nein (als Dateien auf der Festplatte gespeichert) |
| Init-Segment-Bytes | Nein (als Datei auf der Festplatte gespeichert) |

### Wiederherstellung

Beim Server-Neustart:
1. Session- und Fragment-Metadaten aus der Datenbank laden
2. Fragment-Dateien auf der Festplatte anhand gespeicherter Pfade lokalisieren
3. Streaming für alle Sentinels fortsetzen, die sich wieder verbinden

## Metadaten für historischen Zugriff

Wenn ein Proctor historische Fragmente anfragt (via HTTP), verwendet der Server die persistierten Metadaten um:

1. Zu identifizieren, welche Fragmente für einen Sentinel/eine Session existieren
2. Die Fragment-Dateien auf der Festplatte zu lokalisieren
3. Die angeforderten Fragment-Bytes zu liefern

Der Proctor muss wissen:
- `sentinelId` und `sessionId` zur Identifizierung des Streams
- `sequence` zum Anfordern bestimmter Fragmente

Die genaue API zur Abfrage verfügbarer Fragmente ist implementierungsdefiniert. Die obige Metadatenstruktur stellt die notwendigen Informationen bereit.
