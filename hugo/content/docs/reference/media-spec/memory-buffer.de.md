---
title: Speicherpuffer
---

Dieses Dokument spezifiziert, wie der Server **Fragmente** im Speicher für Live-Streaming puffert.

Siehe [Terminologie](../terminology) für Definitionen.

## Zweck

Der Speicherpuffer dient zwei Zwecken:

1. **Schneller Proctor-Beitritt**: Proctors können sofort aktuelle Fragmente empfangen, ohne Festplatten-I/O
2. **Netzwerkresilienz**: Proctors mit langsameren Verbindungen können von gepufferten Fragmenten aufholen

## Puffer-Anforderungen

| Parameter | Wert | Hinweise |
|-----------|-------|-------|
| Pufferfenster | 15–20 Sekunden | Konfigurierbar |
| Inhalt | Alle Fragmente mit Startzeitpunkt innerhalb des Fensters | |
| Geltungsbereich | Pro Sentinel | Jeder Sentinel hat seinen eigenen Puffer |
| Speicher | Nur im Speicher | Kein Festplatten-I/O für Live-Streaming |

## Was gepuffert wird

Für jeden aktiven Sentinel hält der Server im Speicher vor:

| Element | Beschreibung |
|------|-------------|
| **Initialisierungssegment** | Die Codec-/Auflösungskonfiguration für die Session |
| **Aktuelle Fragmente** | Alle Fragmente, deren Startzeitpunkt innerhalb des Pufferfensters liegt |
| **Fragment-Metadaten** | Siehe [Metadaten](../metadata) für Details |
| **Join-Fragment-Index** | Schneller Zugriff auf die aktuellsten Join-Fragmente im Puffer |

```
Pufferfenster (15–20 Sekunden)
◄──────────────────────────────────────────────►

┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌───
│ Frag N-3│ │ Frag N-2│ │ Frag N-1│ │ Frag N  │ │ ...
└────────┘ └────────┘ └────────┘ └────────┘ └───
     │          │          │          │
     └──────────┴──────────┴──────────┴── Alle im Speicher

                                         ▲
                                         │
                                    Aktuellstes
```

## Verdrängung

Fragmente werden aus dem Puffer entfernt, wenn sie außerhalb des Pufferfensters fallen.

| Verhalten | Beschreibung |
|----------|-------------|
 | Auslöser | Startzeitpunkt des Fragments ist älter als `jetzt - Pufferfenster` |
 | Aktion | Aus dem Speicherpuffer entfernen |
 | Festplattenauswirkung | Keine (Fragment wurde bereits beim Empfang auf die Festplatte geschrieben) |
 | Methode | Garbage Collection oder explizite Entfernung (Implementierungsentscheidung) |

{{< callout type="info" >}}
Die Spezifikation schreibt keine bestimmte Verdrängungsstrategie vor. Implementierungen können Lazy Garbage Collection, periodische Bereinigung oder sofortige Entfernung verwenden. Die einzige Anforderung ist, dass Fragmente, die älter als das Pufferfenster sind, nicht im Speicher verbleiben müssen.
{{< /callout >}}

## Join-Punkte

Nicht jedes Fragment ist ein sicherer Join-Punkt.

- Ein **Join-Fragment** beginnt mit einem IDR-Keyframe.
- Ein Proctor SOLLTE die Wiedergabe von einem Join-Fragment beginnen.

Wenn ein Proctor einem Stream beitritt:

1. Server sendet das Initialisierungssegment
2. Server wählt ein Join-Fragment aus dem Puffer (typischerweise das aktuellste für geringste Latenz)
3. Server sendet dieses Join-Fragment und alle nachfolgenden Fragmente

### Puffertiefe und Netzwerkqualität

Das Pufferfenster (15–20 Sekunden) berücksichtigt Proctors mit unterschiedlichen Netzwerkbedingungen:

| Netzwerkqualität | Verhalten |
|-----------------|----------|
| Gut | Proctor spielt nahezu in Echtzeit, Puffer bietet Redundanz |
| Mittel | Proctor puffert einige Sekunden, holt in Niedrig-Aktivitätsphasen auf |
| Schlecht | Proctor puffert aggressiver, kann 10–15 Sekunden hinter Live liegen |

Wenn ein Proctor weiter als das Pufferfenster zurückliegt, muss er entweder:
- Zu Live vorspringen (etwas Video verlieren)
- Historische Fragmente via HTTP anfordern (siehe [Transport](../transport))

## Initialisierungssegment-Caching

Das Initialisierungssegment für jeden aktiven Sentinel wird separat vom Medienfragment-Puffer gecacht.

| Eigenschaft | Wert |
|----------|-------|
| Lebensdauer | Gesamte Session |
| Verdrängung | Wenn Sentinel trennt |
| Zugriff | Bei jeder Proctor-Join-Anfrage gesendet |

Da das Initialisierungssegment klein ist (typischerweise einige KB) und für jeden neuen Proctor benötigt wird, verbleibt es für die Dauer der Sentinel-Session im Speicher.

## Speicher-Überlegungen

Der Speicherbedarf pro Sentinel hängt ab von:

 - **Pufferfensterdauer**: Längeres Fenster = mehr Fragmente
- **Bildrate**: Höhere FPS = mehr Daten pro Sekunde
- **Auflösung**: Höhere Auflösung = größere Frames
 - **Keyframe-Häufigkeit**: Mehr Keyframes = mehr Join-Fragmente

### Grobe Schätzungen

Bei 1080p, 5 FPS, mit H.264-Kompression:

| Pufferfenster | Ungefährer Speicher pro Sentinel |
|---------------|--------------------------------|
| 15 Sekunden | 2–5 MB |
| 20 Sekunden | 3–7 MB |

Dies sind grobe Schätzungen. Der tatsächliche Verbrauch hängt von der Bildschirminhalts-Komplexität und Encoder-Einstellungen ab.
