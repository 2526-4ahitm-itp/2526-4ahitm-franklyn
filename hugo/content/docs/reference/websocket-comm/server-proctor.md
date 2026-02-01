---
title: Server - Proctor
---

Communications between Server and Proctor are done with json via a websocket connection.

## Message Format

All messages follow a consistent envelope structure:

| Field       | Type    | Required | Description                                    |
| ----------- | ------- | -------- | ---------------------------------------------- |
| `type`      | string  | yes      | Determines the message type                    |
| `payload`   | object  | no       | Contains the message content                   |
| `timestamp` | integer | yes      | The time this message was sent in unix seconds |

---

## Message Types

### `proctor.register`

Used to register as a proctor viewing. This must be sent as the first message upon
connecting. If the initial message is a different one, the connection will be aborted.
If this message is sent in a registered connection it will just be ignored.

**Direction:** Proctor -> Server

**Payload:**

`<empty>`

**Example:**

```json
{
  "type": "proctor.register",
  "timestamp": 1696969420
}
```

---

### `server.registration.ack`

This message will be sent from the server to acknowledge a registration of a proctor.

**Direction:** Server -> Proctor

**Payload:**

| Field       | Type   | Required | Description                      |
| ----------- | ------ | -------- | -------------------------------- |
| `proctorId` | string | no       | The UUID assigned to the proctor |

**Example:**

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

This message will be sent from the server to reject the registration of a proctor.
If the proctor receives this message, it should close the connection.

**Direction:** Server -> Proctor

**Payload:**

| Field    | Type   | Required | Description                  |
| -------- | ------ | -------- | ---------------------------- |
| `reason` | string | no       | The reason for the rejection |

**Example:**

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

Sends a list of all available sentinels to choose from to the Proctor.
All sentinels not in this list are assumed to be dead.

**Direction:** Server -> Proctor

**Payload:**

| Field       | Type     | Required | Description             |
| ----------- | -------- | -------- | ----------------------- |
| `sentinels` | string[] | yes      | List of sentinels UUIDs |

**Example:**

```json
{
  "type": "server.update-sentinels",
  "timestamp": 1696969420,
  "payload": {
    "sentinels": ["0c0a4509-cd12-4118-81ae-d13b5b9e7274", "df402174-1c26-426b-947f-b5360254d00c", "b255e355-e398-43d7-b772-101bbf4ca8f0", "431b410b-b8de-4fac-82f3-87b0826b220f"]
  }
}
```

---

### `proctor.subscribe`

Subscribe to a sentinel for which the proctor would like to receive frames.
Multiple sentinels can be subscribed to at the same time.

**Direction:** Proctor -> Server

**Payload:**

| Field        | Type   | Required | Description                          |
| ------------ | ------ | -------- | ------------------------------------ |
| `sentinelId` | string | yes      | UUID of the sentinel to subscribe to |

**Example:**

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

### `proctor.revoke-subscription`

Revoke a subscription to a sentinel.

**Direction:** Proctor -> Server

**Payload:**

| Field        | Type   | Required | Description                                          |
| ------------ | ------ | -------- | ---------------------------------------------------- |
| `sentinelId` | string | yes      | UUID of the sentinel to revoke the subscription from |

**Example:**

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

The Server sends all Frames to the proctor that are new from the subscribed list.

**Direction:** Server -> Proctor

**Payload:**

| Field    | Type                                 | Required | Description                                         |
| -------- | ------------------------------------ | -------- | --------------------------------------------------- |
| `frames` | [Frame](../special-datatype#frame)[] | yes      | All Frames for all subscription currently available |

**Example:**

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
    ]
  }
}
```
