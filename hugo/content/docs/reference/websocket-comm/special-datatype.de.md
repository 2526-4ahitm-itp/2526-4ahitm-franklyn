---
title: Datentypen
---

Datentypen, die häufig in vielen WebSocket-Nachrichten über verschiedene Abschnitte hinweg verwendet werden,
sind hier definiert.

## `Frame`

Enthält die Bilddaten, den Sentinel und andere wichtige Informationen für einen Frame.

| Feld         | Typ     | Erforderlich | Beschreibung                                                             |
| ------------ | ------- | -------- | ----------------------------------------------------------------------- |
| `sentinelId` | string  | ja       | UUID des Sentinels, zu dem der Frame gehört                            |
| `frameId`    | string  | ja       | UUID des Frames selbst                                                  |
| `index`      | integer | ja       | Index des Frames in der Reihenfolge, in der er relativ zu anderen Frames erstellt wurde |
| `data`       | string  | ja       | Base64-kodierte JPEG-Daten des Bildes                                   |

**Beispiel:**

```json
{
  "sentinelId": "b255e355-e398-43d7-b772-101bbf4ca8f0",
  "frameId": "4799566e-ecdf-40e0-99c2-7bdc63a4038c",
  "index": 5,
  "data": "/9j/4AAQSkZ....yl0p8Bg/g/wBLj/1bP/F1v0A//9k="
}
```
