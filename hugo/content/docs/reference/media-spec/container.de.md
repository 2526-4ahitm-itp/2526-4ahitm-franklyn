---
title: Container
---

Dieses Dokument spezifiziert das Container-Format für Videodaten.

## Format: Fragmented MP4 (fMP4)

Alle Videodaten werden im **Fragmented MP4**-Format verpackt. Dies ist eine Variante des Standard-MP4-Containers, die für Streaming optimiert ist.

### Warum fMP4

- Native Unterstützung in Browser Media Source Extensions (MSE)
- Kein Transcodieren auf Server oder Proctor nötig
- Fragmente können inkrementell angehängt werden (mit Initialisierungsdaten)
- Industriestandard für adaptives Streaming (DASH, HLS)

## Strukturübersicht

Ein fMP4-Stream besteht aus zwei Datentypen:

| Typ | Zweck | Wann gesendet |
|------|---------|-----------|
| **Initialisierungssegment** | Enthält Codec-Konfiguration, Auflösung, Zeitskala | Einmal pro Session, beim Proctor-Join |
 | **Medienfragment** | Enthält kodierte Samples (Frames) und Timing (`moof` + `mdat`) | Kontinuierlich während des Streamings |

```
┌─────────────────────────┐
│  Initialisierungssegment│  ← Einmal pro Session gesendet
│  (ftyp + moov Boxen)    │
└─────────────────────────┘
           │
           ▼
┌─────────────────────────┐
│    Medienfragment 1     │  ← Kann mit Keyframe beginnen
│  (moof + mdat Boxen)    │
└─────────────────────────┘
            │
            ▼
┌─────────────────────────┐
│    Medienfragment 2     │  ← Kann mit Keyframe beginnen
│  (moof + mdat Boxen)    │
└─────────────────────────┘
           │
           ▼
          ...
```

## Initialisierungssegment

Das Initialisierungssegment enthält Metadaten, die für die Konfiguration des Decoders benötigt werden. Es enthält keine Video-Frames.

### Inhalt

| Box | Zweck |
|-----|---------|
| `ftyp` | Dateityp-Deklaration (Brand: `iso5` oder `isom`) |
| `moov` | Film-Header mit Codec- und Track-Informationen |

### Schlüsselinformationen in `moov`

- **Codec-Parameter**: H.264 SPS/PPS (Sequence/Picture Parameter Sets)
- **Auflösung**: Breite und Höhe in Pixeln
- **Zeitskala**: Zeiteinheiten pro Sekunde für Zeitstempel

### Lebensdauer

- Einmalig generiert, wenn der Sentinel eine Session startet
- Gilt für die gesamte Session
- Auflösung und Codec-Parameter ändern sich nicht während einer Session
- Vom Server im Speicher für jeden aktiven Sentinel gecacht
- Wird beim Stream-Join-Request an den Proctor gesendet

## Medienfragmente

Jedes Medienfragment enthält ein oder mehrere kodierte Samples (Video-Frames), die für das Streaming verpackt sind.

### Inhalt

| Box | Zweck |
|-----|---------|
| `moof` | Film-Fragment-Header (Timing, Frame-Offsets) |
| `mdat` | Mediendaten (eigentliche H.264-NAL-Units) |

### Anforderungen

 | Anforderung | Beschreibung |
 |-------------|-------------|
 | Dekodierbar mit Init | Ein Fragment ist dekodierbar, wenn es nach dem Initialisierungssegment und entsprechenden vorangehenden Fragmenten angehängt wird |
 | Join-Punkte | Ein **Join-Fragment** beginnt mit einem IDR-Frame und ist ein sicherer Einstiegspunkt für neue Zuschauer |
 | Eigenständiges Timing | Zeitstempel in `moof` sind absolut (nicht relativ zum vorherigen Fragment) |
 | Variable Dauer | Fragmente können unterschiedliche Dauern haben |

### Timing-Informationen

Die `moof`-Box enthält eine `tfdt`-Box (Track Fragment Decode Time), die den Dekodier-Zeitstempel des ersten Frames angibt. Die Dauer jedes Frames wird in der `trun`-Box (Track Fragment Run) angegeben.

{{< callout type="info" >}}
Die Zeitskala aus dem Initialisierungssegment bestimmt, wie Zeitstempel auf die Echtzeit abgebildet werden. Eine gängige Wahl ist 90000 (90 kHz), was Submillisekunden-Präzision ermöglicht.
{{< /callout >}}

## Proctor-Wiedergabe

Um einen Stream wiederzugeben, muss der Proctor:

{{% steps %}}

### Initialisierungssegment empfangen

Das Initialisierungssegment für den Ziel-Sentinel vom Server abrufen.

### MSE SourceBuffer initialisieren

Eine `MediaSource` erstellen, einen `SourceBuffer` mit dem entsprechenden MIME-Typ hinzufügen und das Initialisierungssegment anhängen.

```javascript
// Beispiel-MIME-Typ für H.264 in fMP4
"video/mp4; codecs=\"avc1.42E01F\""
```

### Medienfragmente anhängen

Wenn Medienfragmente eintreffen, diese der Reihe nach an den `SourceBuffer` anhängen.

### Wiedergabe steuern

Das Video-Element des Browsers übernimmt Dekodierung und Rendering automatisch.

{{% /steps %}}

## MIME-Typ

Der MIME-Typ für MSE muss sowohl Container als auch Codec angeben:

```
video/mp4; codecs="avc1.PPCCLL"
```

Dabei verwendet der `avc1`-Codec-String das AVCDecoderConfigurationRecord-Triplet:

- `PP` = `AVCProfileIndication` (Profil)
- `CC` = `profile_compatibility` (Constraint-Flags)
- `LL` = `AVCLevelIndication` (Level)

Für dieses Projekt (OpenH264) wird das Constrained Baseline Profile erwartet.

Beispiel für Constrained Baseline Profile, Level 3.1:
```
video/mp4; codecs="avc1.42E01F"
```

{{< callout type="info" >}}
Andere Encoder KÖNNEN unterschiedliche `avc1`-Werte erzeugen (z. B. Main/High), sofern die Proctor-Wiedergabe in Umgebungen erfolgt, die diese dekodieren können.
{{< /callout >}}
