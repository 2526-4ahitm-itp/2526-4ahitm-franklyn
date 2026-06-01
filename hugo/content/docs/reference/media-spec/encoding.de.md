---
title: Kodierung
---

Dieses Dokument spezifiziert die Video-Kodierungsanforderungen für die Bildschirmerfassung des Sentinels.

Diese Spezifikation ist für eine Implementierung geschrieben, die die OpenH264-Bibliothek (BSD-2-Clause) verwendet, damit das Gesamtprojekt MIT-lizenziert bleiben kann.

Andere H.264-Encoder KÖNNEN verwendet werden, müssen aber Output erzeugen, der denselben On-the-Wire/Container-Anforderungen entspricht (fMP4-Initialisierungssegment + Fragmente, IDR-Join-Punkte, Zeitstempel).

## Codec

**H.264 (AVC)** ist der erforderliche Codec für alle Video-Streams.

{{< callout type="info" >}}
OpenH264 kann einen Annex-B-Bytestrom ausgeben. Dieses Projekt verpackt Video in fMP4 für Transport/Wiedergabe, daher MUSS die Muxing-Schicht des Sentinels gültige fMP4-Initialisierungssegmente und Fragmente erzeugen (kein rohes Annex B).
{{< /callout >}}

### Warum H.264

- Universelle Hardware-Dekodierungsunterstützung
- Native Wiedergabe in allen modernen Browsern via MSE
- Geringer CPU-Overhead bei verfügbarer Hardware-Dekodierung
- Weitgehend unterstützt auf Schul-/Institutionshardware

## Profil und Level

{{< callout type="info" >}}
Die Encoder-Anforderungen entsprechen den OpenH264-Fähigkeiten. Andere Encoder KÖNNEN höhere Profile für bessere Kompression verwenden, aber dieses Projekt standardisiert auf Constrained Baseline für maximale Kompatibilität.
{{< /callout >}}

### Erforderlich: Constrained Baseline Profile

| Einstellung | Wert | Begründung |
|---------|-------|-----------|
| Profil | Constrained Baseline | Von OpenH264 unterstütztes Profil; maximale Decoder-Kompatibilität |
| Level | 3.1 | Unterstützt 1080p bei niedrigen Bildraten |

**Abwägungen:**
- Baseline hat keine B-Frames, was zu etwas größeren Dateien führt
- Garantierte Dekodierung auf jeder Hardware, einschließlich älterer/schwächerer Geräte
- Schnellste Kodierungsgeschwindigkeit

{{< callout type="info" >}}
Bei Verwendung eines anderen Encoders KÖNNEN Main/High-Profile für die Browser-Dekodierung akzeptabel sein, liegen aber außerhalb des Geltungsbereichs der Standard-Encoder-Wahl dieses Projekts.
{{< /callout >}}

### Level-Referenz

| Level | Max. Auflösung | Max. Bildrate | Hinweise |
|-------|----------------|---------------|-------|
| 3.0 | 1280x720 | 30 fps | Ausreichend für 720p |
| 3.1 | 1920x1080 | 30 fps | Empfohlen für 1080p |
| 4.0 | 2048x1024 | 30 fps | Überdimensioniert für diesen Anwendungsfall |

## Auflösung

| Beschränkung | Wert |
|------------|-------|
| Maximum | 1920x1080 (Full HD) |
| Seitenverhältnis | Aus Quelle beibehalten |
| Herunterskalierung | Erforderlich, wenn Quelle 1080p übersteigt |

Der Sentinel muss erfasste Frames auf 1920x1080 herunterskalieren, dabei das ursprüngliche Seitenverhältnis beibehaltend. Beispielsweise würde eine 2560x1440-Erfassung auf 1920x1080 herunterskaliert.

## Bildrate

| Parameter | Wert |
|-----------|-------|
| Minimum | 0,2 fps (1 Frame pro 5 Sekunden) |
| Maximum | 5 fps |
| Variabilität | Kann sich im Laufe der Zeit ändern (siehe Zeitstempel) |

### Variables Bildraten-Verhalten

- Die Bildrate kann sich ändern, wenn der Server dies anfordert (siehe [Steuernachrichten](../control-messages))
- Jeder Frame trägt einen Zeitstempel für genaues Wiedergabe-Timing
- Player müssen Frame-Zeitstempel verwenden, keine konstante Bildrate annehmen

### FPS-Änderungsauslöser

Der Server kann eine Bildratenänderung vom Sentinel anfordern. Häufige Gründe:
- Server unter hoher Last (FPS reduzieren, um Nachrichtenvolumen zu senken)
- Netzwerküberlastung erkannt
- Änderung der administrativen Richtlinie

Bei FPS-Änderung muss ein neues Join-Fragment erzeugt werden (siehe [Fragmente](../segments)).

## Bitrate und Ratensteuerung (OpenH264)

OpenH264 unterstützt entweder:

- Ratensteuerung mit adaptiver Quantisierung (Ziel-Bitrate)
- Konstante Quantisierung (konstantes QP)

### Empfohlen (Standard): Ziel-Bitrate

Der Sentinel SOLLTE OpenH264 so konfigurieren, dass eine für die aktuelle FPS und Auflösung angemessene Bitrate angestrebt wird.

Wenn der Encoder Peak-Control (VBV-ähnliche maximale Bitrate/Puffer) anbietet, SOLLTEN Implementierungen diesen setzen, um kurzfristige Bitratespitzen zu begrenzen.

{{< callout type="info" >}}
OpenH264 dokumentiert, dass die Ratensteuerung die Ziel-Bitrate überschreiten kann, sofern Frame-Skipping nicht aktiviert ist. Wenn strikte Obergrenzen erforderlich sind, aktiviere die entsprechenden RC-Optionen für deine OpenH264-Version.
{{< /callout >}}

### Alternative: Konstante Quantisierung (Qualitätsorientiert)

Constant-QP-Modus KANN verwendet werden, wenn Bitratenvorhersagbarkeit nicht wichtig ist (z. B. LAN-only-Deployments), kann aber bei hochbewegten Bildschirmaktualisierungen große Fragmente erzeugen.

## Keyframes (I-Frames)

Keyframes sind vollständige Frames, die unabhängig ohne Referenz auf vorherige Frames dekodiert werden können.

### Keyframe-Regeln

| Regel | Beschreibung |
|------|-------------|
| On-Demand | Sentinel muss einen Keyframe generieren, wenn vom Server angefordert |
| Maximales Intervall | Mindestens ein Keyframe alle 20–30 Sekunden |
| Bei FPS-Änderung | Das nächste Join-Fragment beginnt mit einem Keyframe, wenn sich die Bildrate ändert |

### Warum On-Demand-Keyframes

- Ermöglicht Proctors, Streams schnell beizutreten, ohne auf den nächsten geplanten Keyframe zu warten
- Ermöglicht schnelles Beitreten, wenn der Server einen Keyframe für einen Stream ohne aktuellen Einstiegspunkt anfordert
- Minimiert unnötige Keyframes, reduziert Bandbreite

### IDR-Frames

Alle Keyframes müssen **IDR-Frames (Instantaneous Decoder Refresh)** sein, nicht nur I-Frames. IDR-Frames löschen den Decoder-Referenzpuffer und gewährleisten saubere Einstiegspunkte für neue Zuschauer.
