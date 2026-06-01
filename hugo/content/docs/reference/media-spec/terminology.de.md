---
title: Terminologie
weight: 1
---

Diese Spezifikation verwendet einige Begriffe, die in Echtzeit-Video-Systemen leicht verwechselt werden können. Diese Seite definiert sie präzise.

## Kernbegriffe

| Begriff | Bedeutung in dieser Spezifikation | Warum es wichtig ist |
|------|-----------------------|----------------|
| **Capture-Frame** | Ein einzelnes Bildschirmbild, das vom Sentinel aufgenommen wird (vor der Kodierung). | Bestimmt, was der Benutzer *potenziell* sieht und wann. |
| **Kodiertes Sample** | Die kodierte Darstellung eines Capture-Frames im H.264-Stream (was MP4 als Sample transportiert). | Dies ist, was tatsächlich transportiert und gespeichert wird. |
| **Keyframe (IDR)** | Ein H.264-IDR-Frame (Instantaneous Decoder Refresh). Ein Decoder kann hier sauber beginnen. | Bestimmt die *Join/Wechsel-Latenz* für einen neuen Proctor. |
| **Initialisierungssegment** | fMP4 `ftyp` + `moov`-Bytes für die Session. Enthält Codec-Konfiguration (SPS/PPS), Auflösung, Zeitskala. Enthält **keine Frames**. | Muss an MSE angehängt werden, bevor Mediendaten dekodiert werden können. |
| **Fragment** | Eine kleine fMP4-Medieneinheit (`moof` + `mdat`), die häufig erzeugt und live gepusht wird. Enthält **ein oder mehrere kodierte Samples**. | Bestimmt die *Live-Latenz* und wie oft Proctors Updates sehen. |
| **Join-Fragment** | Ein Fragment, dessen erstes Sample ein **IDR**-Keyframe (zufälliger Zugriffspunkt) ist. | Ein Proctor sollte die Wiedergabe von einem Join-Fragment beginnen. |

{{< callout type="warning" >}}
Verwechsle **Keyframe-Intervall** nicht mit **Übertragungslatenz**.

- Das Keyframe-Intervall bestimmt, wie schnell ein neuer Zuschauer beitreten kann, ohne einen server-initiierten On-Demand-Keyframe zu benötigen.
- Der Fragment-Takt (wie oft Fragmente erzeugt und gepusht werden) bestimmt, wie schnell ein bestehender Zuschauer neues Video sieht.
{{< /callout >}}

## Praktische Implikationen

### Echtzeit-Anforderung

Live-Streaming MUSS **Fragmente** kontinuierlich pushen. Ein „20-Sekunden"-Wert kann für das *maximale Keyframe-Intervall* (Join-Punkt-Abstand) gelten, darf aber NICHT implizieren, dass Medien nur alle 20 Sekunden übertragen werden.

### Was „Gesendet wie erstellt" bedeutet

Wenn diese Spezifikation sagt „gesendet wie erstellt", bedeutet das:

- Ein Fragment ist finalisiert (es enthält bereits mindestens ein kodiertes Sample).
- Dieses finalisierte Fragment wird sofort über WebSocket gesendet.

Es bedeutet **nicht** „beginne mit dem Senden eines leeren 20-s-Segments bei t=0".
