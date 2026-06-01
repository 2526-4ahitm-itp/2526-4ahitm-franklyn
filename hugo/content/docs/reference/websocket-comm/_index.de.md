---
title: WS-Kommunikationsprotokoll
---

Die Echtzeit-Kommunikation zwischen Franklyn-Server, Sentinels und Proctors erfolgt über WebSocket-Verbindungen mit JSON-Nachrichten. Die Authentifizierung wird über ein `auth`-Feld in den initialen Registrierungsnachrichten abgewickelt.

## Übersicht

| Verbindungstyp    | Rolle           | Beschreibung                                              |
| ----------------- | -------------- | -------------------------------------------------------- |
| Server - Sentinel | Frame-Produzent | Schülerrechner streamen Bildschirmaufnahmen zum Server    |
| Server - Proctor  | Frame-Konsument | Lehrer-Interface empfängt Frames für überwachte Schüler |

## Dokumentation

{{< cards >}}
{{< card link="lifecycle" title="Verbindungslebenszyklus" icon="refresh" subtitle="Verbindungsablauf und Sequenzdiagramme" >}}
{{< card link="server-sentinel" title="Server - Sentinel" icon="upload" subtitle="Registrierung und Frame-Streaming" >}}
{{< card link="server-proctor" title="Server - Proctor" icon="download" subtitle="Registrierung, Abonnements und Frame-Empfang" >}}
{{< card link="special-datatype" title="Spezielle Datentypen" icon="cube" subtitle="Benutzerdefinierte Datenstrukturen in Nachrichten" >}}
{{< /cards >}}
