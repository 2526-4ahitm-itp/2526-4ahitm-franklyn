---
title: Lebenszyklus
---

Dieses Dokument beschreibt den Lebenszyklus der WebSocket-Verbindungen für Sentinels und Proctors.

- **Sentinel**: Frame-Produzent (läuft auf Schülerrechnern)
- **Proctor**: Frame-Konsument (Lehrer-Interface)

---

## Sentinel-Lebenszyklus

### Ablauf

1. Verbindung zum Server via WebSocket herstellen
2. `sentinel.register` als erste Nachricht mit PIN-Code (1337–4200) und `auth`-Token senden
3. `server.registration.ack` oder `server.registration.reject` empfangen
   - Bei Ablehnung wegen ungültigem PIN lautet der Grund „Invalid PIN"
   - Bei Ablehnung wegen ungültigem Auth oder ungültiger Nachricht wird die Verbindung geschlossen oder abgelehnt
4. Bei Annahme: `server.set-resolution` empfangen, wenn der Server die Erfassungsauflösung aktualisiert
5. `sentinel.frame` alle paar Sekunden senden
6. Verbindung schließt, wenn der Sentinel herunterfährt

### Sequenzdiagramm

```plantuml
@startuml
skinparam sequenceMessageAlign center

participant "Sentinel" as S
participant "Server" as Srv

== Verbindung ==
S -> Srv : WebSocket verbinden
activate Srv

== Registrierung ==
S -> Srv : sentinel.register (mit PIN)
alt Registrierung akzeptiert
  Srv -> S : server.registration.ack
else Registrierung abgelehnt
  Srv -> S : server.registration.reject (Invalid PIN)
  S <-> Srv : Verbindung geschlossen
end

== Frame-Streaming ==
note right : Server kann Auflösung anpassen
Srv -> S : server.set-resolution
loop alle paar Sekunden
  S -> Srv : sentinel.frame
end

== Verbindungsabbruch ==
S <-> Srv : Verbindung geschlossen
deactivate Srv

@enduml
```

---

## Proctor-Lebenszyklus

### Ablauf

1. Verbindung zum Server via WebSocket herstellen
2. `proctor.register` als erste Nachricht mit einem `auth`-Token senden
3. `server.registration.ack` oder `server.registration.reject` empfangen
   - Bei Ablehnung wegen ungültigem Auth oder ungültiger Nachricht wird die Verbindung geschlossen oder abgelehnt
4. Bei Annahme:
    - `proctor.set-pin` senden, um anzugeben, welche Sentinels des PINs überwacht werden sollen (1337–4200)
    - `server.update-sentinels` mit der Liste der verfügbaren Sentinels für diesen PIN empfangen
    - `proctor.subscribe` oder `proctor.revoke-subscription` nach Bedarf senden
    - `proctor.set-profile` senden, um `HIGH`, `MEDIUM` oder `LOW` anzufordern
    - `server.frame` für abonnierte Sentinels empfangen
5. Verbindung schließt, wenn der Proctor herunterfährt

### Sentinel-Updates

Der Server sendet `server.update-sentinels` an den Proctor:

- Unmittelbar nach erfolgreicher Registrierung
- Wann immer ein Sentinel verbindet oder trennt
- Wenn der Proctor seinen PIN aktualisiert

### Sequenzdiagramm

```plantuml
@startuml
skinparam sequenceMessageAlign center

participant "Proctor" as P
participant "Server" as Srv

== Verbindung ==
P -> Srv : WebSocket verbinden
activate Srv

== Registrierung ==
P -> Srv : proctor.register
alt Registrierung akzeptiert
  Srv -> P : server.registration.ack
else Registrierung abgelehnt
  Srv -> P : server.registration.reject
  P <-> Srv : Verbindung geschlossen
end

== PIN setzen ==
P -> Srv : proctor.set-pin (mit PIN)
Srv -> P : server.update-sentinels (für PIN)

== Überwachung ==

group Abonnement-Verwaltung [kann jederzeit erfolgen]
   P -> Srv : proctor.subscribe
   P -> Srv : proctor.revoke-subscription
   P -> Srv : proctor.set-profile
end

loop Frames für Abonnements verfügbar
   Srv -> P : server.frame
end

Srv -> P : server.update-sentinels
note right : gesendet wenn Sentinels\nverbinden oder trennen\nmit aktuellem PIN

== Verbindungsabbruch ==
P <-> Srv : Verbindung geschlossen
deactivate Srv

@enduml
```
