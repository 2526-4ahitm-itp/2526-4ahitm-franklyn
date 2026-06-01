---
title: Fragmente
---

Dieses Dokument spezifiziert, wie **Fragmente** erstellt werden, wie sie benannt werden und wie **Join-Fragmente** (Keyframe-Einstiegspunkte) funktionieren.

Siehe [Terminologie](../terminology) für Definitionen.

## Fragment-Definition

Ein **Fragment** ist eine einzelne fMP4-Medieneinheit (`moof` + `mdat`), die ein oder mehrere kodierte Samples enthält. Fragmente sind die Einheit der Live-Übertragung und MSE-Anhänge.

Fragmente:

- Werden kontinuierlich während des Streamings erzeugt
- Werden der Reihe nach an MSE angehängt

{{< callout type="warning" >}}
Keyframes steuern die **Join/Wechsel-Latenz**, nicht die Live-Latenz.

Live-Latenz wird dadurch bestimmt, wie oft Fragmente finalisiert und gepusht werden.
{{< /callout >}}

## Join-Fragmente

Ein **Join-Fragment** ist ein Fragment, dessen erstes Sample ein IDR-Keyframe ist. Join-Fragmente sind zufällige Zugriffspunkte für Proctors.

## Join-Fragment-Auslöser

Ein neues Join-Fragment wird erzeugt, wenn eines der folgenden Ereignisse eintritt:

| Auslöser | Beschreibung |
|---------|-------------|
 | **On-Demand-Keyframe** | Server initiiert; nächste Erfassung wird zu IDR |
 | **FPS-Änderung** | Server fordert neue FPS an; nächste Erfassung wird zu IDR |
 | **Maximales Intervall erreicht** | Falls kein Keyframe in 20–30 Sekunden aufgetreten ist, wird einer erzwungen |

```
Zeitlinie (konzeptionell):
Fragmente werden kontinuierlich erzeugt, Join-Fragmente treten bei Keyframes auf.

├─ Fragment ─ Fragment ─ Join-Fragment ─ Fragment ─ ... ─ Join-Fragment ─ Fragment ─┤
                  [IDR]                            [IDR]
```

*IDR = Keyframe*

## Sequenznummern

Jeder Sentinel führt einen **Sequenzzähler** für seine Fragmente.

| Eigenschaft | Wert |
|----------|-------|
| Startwert | 0 |
 | Inkrement | 1 pro Fragment |
| Geltungsbereich | Pro Sentinel, pro Session |
| Controller | Sentinel (nicht Server) |

Die Sequenznummer wird vom Sentinel beim Erstellen des Fragments vergeben und in den an den Server gesendeten Metadaten enthalten.

## Namenskonvention

Fragmente werden durch die Kombination aus Sentinel-ID und Sequenznummer identifiziert.

### Format

```
{sentinelId}-{sequence}.m4s
```

| Komponente | Beschreibung | Beispiel |
|-----------|-------------|---------|
| `sentinelId` | Eindeutige Kennung des Sentinels | `sentinel-a1b2c3` |
| `sequence` | Nullaufgefüllte Sequenznummer | `000142` |
| Erweiterung | `.m4s` für fMP4-Medienfragmente | |

### Beispiele

```
sentinel-a1b2c3-000000.m4s   # Erstes Fragment
sentinel-a1b2c3-000001.m4s   # Zweites Fragment
sentinel-a1b2c3-000142.m4s   # 143. Fragment
```

### Namensgebung für Initialisierungssegment

Das Initialisierungssegment verwendet einen eigenen Namen:

```
{sentinelId}-init.mp4
```

Beispiel:
```
sentinel-a1b2c3-init.mp4
```

## Fragment-Dauer

Die Fragment-Dauer ist **variabel** und wird von der Sentinel-Implementierung gewählt, um Latenz und Overhead auszubalancieren.

Die Spezifikation schreibt keine exakte Fragment-Dauer vor, aber Fragmente MÜSSEN häufig genug erzeugt werden, um die Echtzeit-Anforderung zu erfüllen.

| Szenario | Typische Dauer |
|----------|------------------|
| Typischer Echtzeit-Betrieb | ~0,25 s bis ~2 s (Implementierungsentscheidung) |
| Sehr niedrige FPS-Modus (0,2 fps) | Ein Fragment pro Erfassung (bis zu 5 s) |
| Joins / FPS-Änderungen | Ein Join-Fragment wird bei der nächsten Erfassung erzeugt |

{{< callout type="warning" >}}
Geh nicht davon aus, dass Fragmente 20–30 Sekunden lang sind.

20–30 Sekunden ist das **maximale Keyframe-Intervall** (Join-Fragment-Abstand), nicht die Fragment-Dauer.
{{< /callout >}}

## Fragment-Inhalt

Jedes Medienfragment enthält:

| Inhalt | Ort | Beschreibung |
|---------|----------|-------------|
| Dekodier-Zeitstempel | `moof` → `tfdt` | Absoluter Zeitstempel des ersten Frames |
| Frame-Dauern | `moof` → `trun` | Dauer jedes Frames im Fragment |
| Frame-Daten | `mdat` | Kodierte H.264-NAL-Units |

### Frame-Zeitstempel

Jedes Sample in einem Fragment hat einen präzisen Zeitstempel, der sich ergibt aus:

1. Der Basis-Dekodierzeit des Fragments (`tfdt`)
2. Der kumulierten Dauer vorhergehender Samples (`trun`-Sample-Dauern)

Dies ermöglicht genaues Wiedergabe-Timing unabhängig von FPS-Änderungen über die Zeit.

## Beziehung zu Sessions

Eine **Session** ist der Zeitraum von der Verbindung eines Sentinels bis zu seiner Trennung.

| Session-Ereignis | Fragment-Verhalten |
|---------------|------------------|
| Session-Start | Sequenz setzt auf 0 zurück, neues Initialisierungssegment erstellt |
| Session läuft | Sequenz erhöht sich mit jedem Fragment |
| Session endet | Letztes Fragment kann kürzer als normal sein |

{{< callout type="info" >}}
Wenn ein Sentinel sich wieder verbindet (neue Session), generiert er ein neues Initialisierungssegment und startet die Sequenznummerierung bei 0 neu. Der Server behandelt dies als neuen Stream.
{{< /callout >}}
