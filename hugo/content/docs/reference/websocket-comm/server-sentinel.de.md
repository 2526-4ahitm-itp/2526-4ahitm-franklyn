---
title: Server - Sentinel
---

Die Kommunikation zwischen Server und Sentinel erfolgt mit JSON über eine WebSocket-Verbindung.

## Nachrichtenformat

Alle Nachrichten folgen einer einheitlichen Hüllenstruktur:

| Feld        | Typ     | Erforderlich | Beschreibung                                    |
| ----------- | ------- | -------- | ---------------------------------------------- |
| `type`      | string  | ja       | Bestimmt den Nachrichtentyp                    |
| `payload`   | object  | nein     | Enthält den Nachrichteninhalt                  |
| `timestamp` | integer | ja       | Zeitpunkt, zu dem die Nachricht gesendet wurde, in Unix-Sekunden |

---

## Nachrichtentypen

### `sentinel.register`

Wird verwendet, um einen Sentinel beim Verbinden mit dem Server zu registrieren.
Diese Nachricht muss die erste gesendete Nachricht sein, sonst wird der Sentinel getrennt.

**Richtung:** Sentinel -> Server

**Payload:**

| Feld   | Typ     | Erforderlich | Beschreibung                    |
|-------|--------|----------|--------------------------------|
| `pin`  | integer | ja       | PIN-Code (1337–4200)           |
| `auth` | string  | ja       | Authentifizierungstoken        |

**Beispiel:**

```json
{
  "type": "sentinel.register",
  "timestamp": 1696969420,
  "payload": {
    "pin": 2024,
    "auth": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

---

### `server.registration.ack`

Diese Nachricht wird vom Server gesendet, um die Registrierung eines Sentinels zu bestätigen.

**Richtung:** Server -> Sentinel

**Payload:**

| Feld         | Typ    | Erforderlich | Beschreibung                       |
| ------------ | ------ | -------- | --------------------------------- |
| `sentinelId` | string | ja       | Die dem Sentinel zugewiesene UUID |

**Beispiel:**

```json
{
  "type": "server.registration.ack",
  "timestamp": 1696969420,
  "payload": {
    "sentinelId": "e0a1e92b-7aae-4885-b5f7-7f7a89fce101"
  }
}
```

---

### `server.registration.reject`

Diese Nachricht wird vom Server gesendet, um die Registrierung eines Sentinels abzulehnen.
Falls der Sentinel diese Nachricht empfängt, sollte er die Verbindung schließen.

**Richtung:** Server -> Sentinel

**Payload:**

| Feld     | Typ    | Erforderlich | Beschreibung                  |
| -------- | ------ | -------- | ---------------------------- |
| `reason` | string | ja       | Der Grund für die Ablehnung |

**Beispiel:**

```json
{
  "type": "server.registration.reject",
  "timestamp": 1696969420,
  "payload": {
    "reason": "Invalid PIN"
  }
}
```

---

### `server.set-resolution`

Fordert eine konkrete Auflösung vom Sentinel an. Der Sentinel erhält nur einen
`maxSidePx`-Wert und muss beim Skalieren das ursprüngliche Seitenverhältnis beibehalten.

**Richtung:** Server -> Sentinel

**Payload:**

| Feld        | Typ     | Erforderlich | Beschreibung                                  |
| ----------- | ------- | -------- | -------------------------------------------- |
| `maxSidePx` | integer | ja       | Maximale Länge der längeren Seite in Pixeln |

**Beispiel:**

```json
{
  "type": "server.set-resolution",
  "timestamp": 1696969420,
  "payload": {
    "maxSidePx": 720
  }
}
```

---

### `sentinel.frame`

Der Sentinel sendet alle paar Sekunden seine Frames an den Server.

**Richtung:** Sentinel -> Server

**Payload:**

| Feld     | Typ                                  | Erforderlich | Beschreibung                                                 |
| -------- | ------------------------------------ | -------- | ----------------------------------------------------------- |
| `frames` | [Frame](../special-datatype#frame)[] | ja       | Alle Frames, die zwischen dem Sendeintervall erstellt wurden |

**Beispiel:**

```json
{
  "type": "sentinel.frame",
  "timestamp": 1696969420,
  "payload": {
    "frames": [
      {
        "sentinelId": "b255e355-e398-43d7-b772-101bbf4ca8f0",
        "frameId": "4799566e-ecdf-40e0-99c2-7bdc63a4038c",
        "index": 5,
        "data": "/9j/4AAQSkZ....Lj/1bP/F1v0A//9k="
      },
      {
        "sentinelId": "b255e355-e398-43d7-b772-101bbf4ca8f0",
        "frameId": "d7994246-35a6-4e2d-aae7-14bf9022f927",
        "index": 23,
        "data": "/9j/4AAQSkZJ....ejBknVXUhEj/9k="
      }
    ]
  }
}
```
