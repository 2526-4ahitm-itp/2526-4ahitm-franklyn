---
title: Datatypes
---

Datatypes that are commonly used in many WebSocket messages over different sections
are defined here.

## `Frame`

Holds the Image data, sentinel, and other important information you need for a Frame.

| Field        | Type    | Required | Description                                                             |
| ------------ | ------- | -------- | ----------------------------------------------------------------------- |
| `sentinelId` | string  | yes      | UUID of the sentinel that the Frame belongs to                          |
| `frameId`    | string  | yes      | UUID of the frame itself                                                |
| `index`      | integer | yes      | Index of the frame in the order it was created relative to other frames |
| `data`       | string  | yes      | Base64 encoded data of the image                                        |

**Example:**

```json
{
  "sentinelId": "b255e355-e398-43d7-b772-101bbf4ca8f0",
  "frameId": "4799566e-ecdf-40e0-99c2-7bdc63a4038c",
  "index": 5,
  "data": "/9j/4AAQSkZ....yl0p8Bg/g/wBLj/1bP/F1v0A//9k="
}
```
