# Spezifikation: Prüfungsüberwachung für Programmier-Leistungsfeststellungen

## 1. Zweck und Zielbild

Diese Applikation überwacht digitale Leistungsfeststellungen in Computerräumen, um unerlaubte Hilfsmittel (insbesondere KI-Dienste) zu erkennen und zu dokumentieren.

Primäre Ziele:
- Automatisierte Erkennung von Verstößen.
- Live-Überwachung von Schüler-Bildschirmen durch Lehrkräfte.
- Nachträgliche Beweisbarkeit über Videoaufzeichnung, Ereignisse und Dateiverläufe.

Nicht-Ziel:
- Technisches Blockieren von Anwendungen/URLs/Prozessen (System erkennt und meldet nur).

---

## 2. Rollen und Berechtigungen

## 2.1 Rollen
- `Schüler`: beobachtete Person im Exam.
- `Lehrer`: erstellt/verwaltet eigene Exams, überwacht live, sieht Auswertungen eigener Exams.
- `Admin`: Vollzugriff.

## 2.2 Rechte
- `Schüler`
  - Login in Exam mit Keycloak + Exam-PIN.
  - Sieht nur Verbindungs-/Statushinweis.
- `Lehrer`
  - Exams erstellen, starten, überwachen, löschen (nur eigene Exams).
  - Live-Ansicht und Zoom auf einzelne Schüler.
  - Playback und Ereignisliste für eigene Exams.
- `Admin` (Vollzugriff)
  - Zugriff auf alle Funktionen und Daten.
  - Verwaltung der Liste verbotener AI-Domains/Prozesse.

---

## 3. Systemkontext und technische Leitplanken

## 3.1 Plattformen
- Schüler-Clients: `Windows 11`, `macOS 15`, `Ubuntu 24.04 LTS`, `Debian 12`.
- Lehrer-UI: Webanwendung (Browser-Support in Doku: Browser-Releases ab 2024; keine technische Versionssperre in der App).

## 3.2 Tech-Stack (verbindlich)
- Backend: `Java + Quarkus` (monolithisch).
- Frontend: `Vue.js`.
- Client-Daemon: `Rust` (kein nativer Swift/Kotlin-Client erforderlich).
- Datenbank: `PostgreSQL`.
- Migrationen: `Flyway`.
- Identity: `Keycloak` (JWT/OIDC).

## 3.3 Infrastruktur
- On-Prem-Server (keine Cloud).
- Gleicher Schulnetz-Kontext während Prüfungen.
- Keine Offline-Pufferung; Verbindungsverlust führt zu Alarm.

---

## 4. Fachliche Kernobjekte

## 4.1 Klasse
- Klassenstammdaten kommen aus Keycloak.
- Klassenzuordnung über Claim `distinguishedName`; Klasse wird aus `OU=<Klasse>` extrahiert (z. B. `OU=4AHITM`).

## 4.2 Exam
Pflichtfelder:
- Titel
- Klasse
- Raum
- Startzeit
- Endzeit

Eigenschaften:
- Geplante Exams und Sofort-Exams sind gleiches Modell.
- Mehrere Exams gleichzeitig möglich.
- Exams derselben Klasse dürfen sich zeitlich überschneiden.
- Eindeutiger PIN pro Exam, gültig nur im Prüfungszeitfenster.

## 4.3 Session
- Ein Schüler darf global nur eine aktive Session haben (nicht nur pro Exam).
- Mehrfach-Login desselben Schülers wird verhindert.

---

## 5. Authentifizierung und Zuordnung

## 5.1 Login-Flow Schüler
1. Schüler startet Client-Dienst.
2. Schüler meldet sich via Keycloak an.
3. Schüler gibt Exam-PIN ein.
4. System ordnet Schüler automatisch über Keycloak-Daten zu.

## 5.2 Login-Flow Lehrer/Admin
- Authentifizierung via Keycloak (JWT/OIDC).

---

## 6. Exam-Lifecycle

## 6.1 Überwachungsstart
- Überwachung/Recording startet beim Login, wenn Loginzeit im Intervall liegt: `[Exam-Start - 60 Minuten, Exam-Ende]`.
- Login früher als 60 Minuten vor Start: kein Recording.

## 6.2 Überwachungsende
- Recording endet erst mit manuellem Logout des Schülers.

## 6.3 Dienst-Status
- Client-Dienst muss laufen.
- Wenn Dienst beendet/Verbindung fehlt: Alarm an Lehrkraft.
- Keine harte Exam-Blockade, nur Warnung/Meldung.

---

## 7. Live-Überwachung (Bildschirm)

## 7.1 Live-Ansicht
- Lehrer sieht 6 Schüler gleichzeitig, Navigation per Pagination.
- Zoom/Detailansicht auf einzelnen Schüler möglich.
- Nur Ansicht, keine Fernsteuerung.

## 7.2 Stream/Qualität
- Primäre Aufnahmequalität: `1080p`, Default `10 FPS`.
- Live-Stream darf adaptiv in Qualität/FPS heruntergeregelt werden.
- Ziel-Latenz für Alarme und Live-Reaktion: `10s` (für alle Alarmtypen).

## 7.3 Multi-Monitor / Audio
- Kein Multi-Monitor-Support (nur Standard-Anzeige).
- Kein Audio-Capture.

---

## 8. Aufzeichnung und Playback

## 8.1 Videoaufzeichnung
- Format: `MP4`.
- Codec: `H.265`.
- Ohne Audio.

## 8.2 Playback-Funktionen
- Play/Pause.
- Sprung zu Alarmen/Markern.
- Frame-by-Frame.

## 8.3 Zeitliche Synchronisierung
- Playback-Timeline zeigt synchron:
  - Screen-Ereignisse
  - Datei-Ereignisse/Diffs
  - Alarmmarker

---

## 9. Datei-/Code-Überwachung

## 9.1 Datei-Scope
- Nur Textdateien.
- Erfassung „best effort“ über:
  - aktive Fenster-App
  - zuletzt gespeicherte Datei
- Für den 1-Minuten-Diff-Lauf werden alle beobachteten Dateien berücksichtigt.

## 9.2 Speichermodell
- Es werden nur Diffs gespeichert (kein vollständiger Snapshot als Primärmodell).
- Diff-Erzeugung erzwungen jede Minute.
- Diffs sind inkrementell gegen den zuletzt gespeicherten Stand.

## 9.3 Nicht im Scope
- Binärdateien.
- Rekonstruktion gelöschter Dateien.

---

## 10. Verstoß-Erkennung

## 10.1 Erkennungsmodus
- Startet automatisch, sobald Schüler verbunden ist.
- Rein detektierend und meldend (kein Blockieren).

## 10.2 Erlaubte Signale (DSGVO-freigegeben)
- Aktive Fenster-/Prozessnamen.
- Browser-URL des aktiven Tabs/Fensters.
- OCR auf Bildschirmbildern (kontinuierlich).
- Netzwerkziel-Domains des gesamten Geräts (inkl. nötiger OS-Rechte).

Nicht erlaubt:
- Clipboard-Inhalt.
- Keylogging/Tastaturanschläge.

## 10.3 Regelwerk
- Verbotene AI-Dienste über Liste in Datenbank (Domains/Prozesse), verwaltet durch Admin.
- Massen-Paste-Regel: Alarm bei `>= 10` eingefügten Zeilen innerhalb `<= 1s`.
- Einheitliche Regeln für alle Exams (keine exam-spezifische Regelkonfiguration in v1).

## 10.4 Alarmierung bei Verstößen
- Bei Treffer:
  - Live-Popup bei Lehrer.
  - Eintrag in Ereignisliste.
  - Persistierung in Datenbank.
  - Marker in Timeline/Video.
- Wiederholungslogik: maximal 1 Warnung pro Minute je fortbestehendem Verstoß.

---

## 11. Alarmtypen

Pflicht-Alarmtypen:
- Verbindung weg.
- Exam-Regelverstoß.
- AI-Verdacht.
- Überwachter Dateizugriff/Dateiquelle nicht verfügbar.

Eigenschaften:
- Alarme quittierbar.
- Keine Eskalationsstufen.
- Kein E-Mail-Alarm in v1.
- Ziel-Latenz: `<= 10s` bis Anzeige.

---

## 12. Datenhaltung, Löschung, Retention

## 12.1 Retention
- Standardaufbewahrung: 30 Tage ab Exam-Ende (für alle Datentypen gleich).

## 12.2 Manuelles Löschen
- „Exam löschen“ = sofortige Hard-Delete aller zugehörigen Daten:
  - Video
  - Diffs
  - Events/Alarme
  - Metadaten
  - Backups

## 12.3 Export
- Kein Pflicht-Reporting-Exportformat in v1.
- Rohmaterial (Video) soll verfügbar sein.

---

## 13. Sicherheit und Datenschutz

## 13.1 Datenschutzrahmen
- DSGVO als Rahmen.
- Rechtsgrundlage: gesetzliche Pflicht.

## 13.2 Zugriff auf Daten
- Lehrer (eigene Exams), Admin (Vollzugriff).

## 13.3 Verschlüsselung
- In-Transit: ja (sichere Internetprotokolle/TLS).
- At-Rest am Server: bewusst unverschlüsselt (akzeptiertes Risiko).

## 13.4 Audit/Compliance
- Keine formale Revisionspflicht/Auditpflicht für v1.

---

## 14. Nicht-funktionale Anforderungen

- Gleichzeitigkeit: bis zu 19 Klassen.
- Gleichzeitige Nutzer: bis zu 950 Schüler gesamt; bis zu 50 Schüler pro Exam; bis zu 70 Lehrkräfte.
- Verfügbarkeit/SLA: kein SLA in v1.
- Lastgrenzen (CPU/RAM) nicht numerisch vorgegeben; Ziel ist keine spürbare Beeinträchtigung auf Schülergeräten.
- Max. Abbruchrate Streams: `<= 1%` pro Exam.

---

## 15. UI-Anforderungen (Lehrer-Webapp)

Mindestansichten:
- Dashboard.
- Monitor View (Live-Überwachung).

Zusätzliche funktionale UI-Pflichten:
- Schülerstatus sichtbar (verbunden/getrennt).
- Alarm-Popup und Ereignisliste.
- Detailansicht pro Schüler.
- Playback mit Marker-Navigation.

Nicht erforderlich in v1:
- i18n (als Soll für später genannt).
- Tablet-Optimierung.
- Accessibility-Anforderungen.

---

## 16. User Stories mit Akzeptanzkriterien

## US-01 Exam erstellen
Als Lehrer möchte ich ein Exam mit Titel, Klasse, Raum, Start und Ende erstellen.

Akzeptanzkriterien:
- Formular speichert Exam mit den Pflichtfeldern.
- System erzeugt eindeutigen PIN.
- Exam erscheint im Lehrer-Dashboard.

## US-02 Schüler-Teilnahme
Als Schüler möchte ich per Keycloak + PIN einem Exam beitreten.

Akzeptanzkriterien:
- Login via Keycloak erforderlich.
- PIN-Prüfung nur im gültigen Zeitfenster.
- Pro Schüler ist global nur eine aktive Session erlaubt.

## US-03 Live-Monitoring
Als Lehrer möchte ich Schülerbildschirme live sehen und in einen Bildschirm zoomen.

Akzeptanzkriterien:
- Live-Grid zeigt 6 Schüler gleichzeitig.
- Pagination für weitere Schüler funktioniert.
- Detailansicht/Zoom verfügbar.
- Kein Remote-Control möglich.

## US-04 Verstoß-Erkennung
Als Lehrer möchte ich bei KI-Verdacht und Regelverstößen sofort gewarnt werden.

Akzeptanzkriterien:
- Alarme erscheinen innerhalb 10s.
- Popup + Ereignisliste + DB-Persistenz + Marker werden erzeugt.
- Fortbestehender Verstoß erzeugt höchstens 1 Alarm/Minute.

## US-05 Dateiverlauf
Als Lehrer möchte ich Dateiveränderungen der Schüler als Diffs nachvollziehen.

Akzeptanzkriterien:
- Nur Textdateien werden verarbeitet.
- Jede Minute wird ein inkrementeller Diff erfasst.
- Diffs sind der passenden Schüler-Session zugeordnet.

## US-06 Playback
Als Lehrer möchte ich die Prüfung im Nachhinein abspielen und zu Vorfällen springen.

Akzeptanzkriterien:
- MP4/H.265-Video ist verfügbar.
- Play/Pause, Frame-by-Frame und „Sprung zu Alarm“ funktionieren.
- Timeline zeigt Screen- und Datei-Events synchron.

## US-07 Exam löschen
Als Lehrer möchte ich eigene Exams löschen.

Akzeptanzkriterien:
- Löschen führt zu sofortiger Hard-Delete aller Exam-Daten.
- Daten werden auch aus Backups entfernt.
- Gelöschtes Exam ist nicht mehr sichtbar/abrufbar.

## US-08 Admin-Vollzugriff
Als Admin möchte ich systemweit eingreifen können.

Akzeptanzkriterien:
- Admin hat Zugriff auf alle Daten/Funktionen.
- Admin kann verbotene AI-Domains/Prozesse verwalten.

---

## 17. Abnahme für v1

Ein v1-Build gilt als abnahmefähig, wenn mindestens erfüllt ist:
- Lehrer kann Schülerbildschirme live sehen.
- Teilnahme-Log dokumentiert, welche Schüler im Exam waren.
- Verstöße werden erkannt und als Ereignisse gespeichert.
- Videos der Schülerprüfungen werden gespeichert und abspielbar gemacht.
- Exams können erstellt und gelöscht werden.

Zusätzlich:
- Mock-Exams für Demo/Abnahme vorhanden.

---

## 18. Priorisierung

## Muss (v1)
- Bildschirm-Liveansicht.
- Verstoß-Erkennung.
- Videoaufzeichnung.
- Log/Teilnahme-Tracking.
- Test-/Exam-Erstellung.

## Soll (v1.1/v2)
- i18n.

## Kann (später)
- Skalierung auf mehr Klassen/Teilnehmer optimieren.

---

## 19. Offene Punkte

Keine offenen fachlichen Fragen. Diese Spezifikation ist auf Basis der beantworteten Fragekataloge vollständig und konsistent definiert.
