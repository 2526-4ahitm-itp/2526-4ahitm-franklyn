---
title: Server - Sentinel
---

Communications between Server and Sentinel are done with json via a websocket connection.

## Message Format

All messages follow a consistent envelope structure:

| Field       | Type    | Required | Description                                    |
| ----------- | ------- | -------- | ---------------------------------------------- |
| `type`      | string  | yes      | Determines the message type                    |
| `payload`   | object  | no       | Contains the message content                   |
| `timestamp` | integer | yes      | The time this message was sent in unix seconds |

---

## Message Types

### `sentinel.register`

Used to register a Sentinel when connecting to the server.
This message must be the first message sent or the sentinel will be disconnected.

**Direction:** Sentinel -> Server

**Payload:**

| Field | Type   | Required | Description                    |
|-------|--------|----------|--------------------------------|
| `pin` | integer| yes      | PIN code (1337-4200)         |
| `auth`| string | yes      | Authentication token           |

**Example:**

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

This message will be sent from the server to acknowledge a registration of a sentinel.

**Direction:** Server -> Sentinel

**Payload:**

| Field        | Type   | Required | Description                       |
| ------------ | ------ | -------- | --------------------------------- |
| `sentinelId` | string | yes      | The UUID assigned to the sentinel |

**Example:**

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

This message will be sent from the server to reject the registration of a sentinel.
If the sentinel receives this message, it should close the connection.

**Direction:** Server -> Sentinel

**Payload:**

| Field    | Type   | Required | Description                  |
| -------- | ------ | -------- | ---------------------------- |
| `reason` | string | yes      | The reason for the rejection |

**Example:**

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

Request a concrete resolution from the sentinel. The sentinel only receives a
`maxSidePx` value and must preserve the original aspect ratio when scaling.

**Direction:** Server -> Sentinel

**Payload:**

| Field       | Type    | Required | Description                                  |
| ----------- | ------- | -------- | -------------------------------------------- |
| `maxSidePx` | integer | yes      | Maximum length of the longer side in pixels |

**Example:**

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

The sentinel sends its frames every couple of seconds to the server.

**Direction:** Sentinel -> Server

**Payload:**

| Field    | Type                                 | Required | Description                                                 |
| -------- | ------------------------------------ | -------- | ----------------------------------------------------------- |
| `frames` | [Frame](../special-datatype#frame)[] | yes      | All Frames that have been made between the sending interval |

**Example:**

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
