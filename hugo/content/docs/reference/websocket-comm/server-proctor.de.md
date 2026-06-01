---
title: Server - Proctor
---

Die Kommunikation zwischen Server und Proctor erfolgt mit JSON über eine WebSocket-Verbindung.

## Nachrichtenformat

Alle Nachrichten folgen einer einheitlichen Hüllenstruktur:

| Feld        | Typ     | Erforderlich | Beschreibung                                    |
| ----------- | ------- | -------- | ---------------------------------------------- |
| `type`      | string  | ja       | Bestimmt den Nachrichtentyp                    |
| `payload`   | object  | nein     | Enthält den Nachrichteninhalt                  |
| `timestamp` | integer | ja       | Zeitpunkt, zu dem die Nachricht gesendet wurde, in Unix-Sekunden |

---

## Nachrichtentypen

### `proctor.register`

Wird verwendet, um sich als Proctor zu registrieren. Diese Nachricht muss als erste Nachricht
beim Verbinden gesendet werden. Falls die erste Nachricht eine andere ist, wird die Verbindung abgebrochen.
Falls diese Nachricht in einer bereits registrierten Verbindung gesendet wird, wird sie ignoriert.

**Richtung:** Proctor -> Server

**Payload:**

| Feld  | Typ    | Erforderlich | Beschreibung          |
|--------|--------|----------|----------------------|
| `auth` | string | ja       | Authentifizierungstoken |

**Beispiel:**

```json
{
  "type": "proctor.register",
  "timestamp": 1696969420,
  "payload": {
    "auth": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

---

### `proctor.set-pin`

Wird verwendet, um einen PIN zum Filtern von Sentinels zu setzen. Der Server sendet nur Updates für Sentinels,
die sich mit diesem PIN registriert haben. Ein neuer PIN ersetzt den vorherigen PIN-Filter.

**Richtung:** Proctor -> Server

**Payload:**

| Feld  | Typ     | Erforderlich | Beschreibung         |
|-------|--------|----------|---------------------|
| `pin` | integer | ja       | PIN-Code (1337–4200) |

**Beispiel:**

```json
{
  "type": "proctor.set-pin",
  "timestamp": 1696969420,
  "payload": {
    "pin": 2024
  }
}
```

---

### `server.registration.ack`

Diese Nachricht wird vom Server gesendet, um die Registrierung eines Proctors zu bestätigen.

**Richtung:** Server -> Proctor

**Payload:**

| Feld        | Typ    | Erforderlich | Beschreibung                      |
| ----------- | ------ | -------- | -------------------------------- |
| `proctorId` | string | ja       | Die dem Proctor zugewiesene UUID |

**Beispiel:**

```json
{
  "type": "server.registration.ack",
  "timestamp": 1696969420,
  "payload": {
    "proctorId": "e0a1e92b-7aae-4885-b5f7-7f7a89fce101"
  }
}
```

---

### `server.registration.reject`

Diese Nachricht wird vom Server gesendet, um die Registrierung eines Proctors abzulehnen.
Falls der Proctor diese Nachricht empfängt, sollte er die Verbindung schließen.

**Richtung:** Server -> Proctor

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
    "reason": "Server busy"
  }
}
```

---

### `server.update-sentinels`

Sendet eine Liste von Sentinels, die für den aktuell gesetzten PIN des Proctors verfügbar sind.
Nur Sentinels, die sich mit diesem PIN registriert haben, sind enthalten.
Alle Sentinels, die nicht in dieser Liste sind, sind entweder offline oder mit einem anderen PIN registriert.

**Richtung:** Server -> Proctor

**Payload:**

| Feld        | Typ      | Erforderlich | Beschreibung            |
| ----------- | -------- | -------- | ---------------------- |
| `sentinels` | object[] | ja       | Liste der Sentinel-Einträge |

Jedes Objekt in `sentinels`:

| Feld         | Typ    | Erforderlich | Beschreibung                            |
| ------------ | ------ | -------- | -------------------------------------- |
| `sentinelId` | string | ja       | Die UUID des Sentinels               |
| `name`       | string | ja       | Ein lesbarer Name für den Sentinel |

**Beispiel:**

```json
{
  "type": "server.update-sentinels",
  "timestamp": 1696969420,
  "payload": {
    "sentinels": [
      { "sentinelId": "0c0a4509-cd12-4118-81ae-d13b5b9e7274", "name": "Max Mustermann" },
      { "sentinelId": "df402174-1c26-426b-947f-b5360254d00c", "name": "Mix Mistermann" },
      { "sentinelId": "b255e355-e398-43d7-b772-101bbf4ca8f0", "name": "Mux Mastermann" }
    ]
  }
}
```

---

### `proctor.subscribe`

Abonniert einen Sentinel, für den der Proctor Frames empfangen möchte.
Mehrere Sentinels können gleichzeitig abonniert werden.

**Richtung:** Proctor -> Server

**Payload:**

| Feld         | Typ    | Erforderlich | Beschreibung                          |
| ------------ | ------ | -------- | ------------------------------------ |
| `sentinelId` | string | ja       | UUID des zu abonnierenden Sentinels |

**Beispiel:**

```json
{
  "type": "proctor.subscribe",
  "timestamp": 1696969420,
  "payload": {
    "sentinelId": "b255e355-e398-43d7-b772-101bbf4ca8f0"
  }
}
```

---

### `proctor.set-profile`

Fordert ein Auflösungsprofil für einen bestimmten Sentinel an. Der Server entscheidet,
welche Auflösung tatsächlich verwendet wird. Der Proctor arbeitet nur mit Profilen;
der Sentinel erhält vom Server einen konkreten `maxSidePx`-Wert.

**Richtung:** Proctor -> Server

**Payload:**

| Feld         | Typ    | Erforderlich | Beschreibung                                |
| ------------ | ------ | -------- | ------------------------------------------ |
| `sentinelId` | string | ja       | UUID des zu aktualisierenden Sentinels             |
| `profile`    | string | ja       | Angefordertes Profil: `HIGH`, `MEDIUM`, `LOW` |

**Beispiel:**

```json
{
  "type": "proctor.set-profile",
  "timestamp": 1696969420,
  "payload": {
    "sentinelId": "b255e355-e398-43d7-b772-101bbf4ca8f0",
    "profile": "MEDIUM"
  }
}
```

---

### `proctor.revoke-subscription`

Hebt ein Abonnement für einen Sentinel auf.

**Richtung:** Proctor -> Server

**Payload:**

| Feld         | Typ    | Erforderlich | Beschreibung                                          |
| ------------ | ------ | -------- | ---------------------------------------------------- |
| `sentinelId` | string | ja       | UUID des Sentinels, dessen Abonnement aufgehoben werden soll |

**Beispiel:**

```json
{
  "type": "proctor.revoke-subscription",
  "timestamp": 1696969420,
  "payload": {
    "sentinelId": "b255e355-e398-43d7-b772-101bbf4ca8f0"
  }
}
```

---

### `server.frame`

Der Server sendet alle neuen Frames aus der Abonnementliste an den Proctor.

**Richtung:** Server -> Proctor

**Payload:**

| Feld      | Typ                                  | Erforderlich | Beschreibung                                         |
| --------- | ------------------------------------ | -------- | --------------------------------------------------- |
| `frames`  | [Frame](../special-datatype#frame)[] | ja       | Alle Frames aller aktuell verfügbaren Abonnements |
| `profile` | string                               | ja       | Profil der Frames: `HIGH`, `MEDIUM`, `LOW`      |

**Beispiel:**

```json
{
  "type": "server.frame",
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
        "sentinelId": "b784823d-805b-4129-b61d-12ca7da6d726",
        "frameId": "d7994246-35a6-4e2d-aae7-14bf9022f927",
        "index": 23,
        "data": "/9j/4AAQSkZJ....ejBknVXUhEj/9k="
      }
    ],
    "profile": "MEDIUM"
  }
}
```
