# Folgefragen zur Präzisierung (bitte in `answers.md` beantworten)

Bitte beantworte diese Punkte mit dem Schema `F1`, `F2`, … (oder gerne in einem separaten `answers2.md`).

## A) Scope und Regeln

F1. Soll das System **nur erkennen und melden** oder auch aktiv **blockieren** (z. B. Prozess beenden, URL sperren, Exam automatisch stoppen)?
F2. Was ist die **konkrete Reaktion** bei AI-Verdacht: nur Warnung + Marker + Log, oder weitere Maßnahmen?
F3. Was gilt als „viele Zeilen auf einmal eingefügt“ (exakter Schwellwert, z. B. `>= 20` Zeilen innerhalb von `<= 2` Sekunden)?
F4. Gelten dieselben Regeln für alle Prüfungen oder pro Exam konfigurierbar?

## B) Plattform und Client-Implementierung

F5. Für v1: Welche Schüler-OS sind **verpflichtend**? Bitte mit Versionen angeben (z. B. Windows 11, macOS 14, Ubuntu 22.04).   
F6. Welche Lehrer-OS sind für die Webanwendung relevant (Browser-Support: Chrome/Edge/Firefox/Safari + Mindestversion)? 
F7. Du hast „Swift und Kotlin“ genannt: Soll es **native Clients** geben? Falls ja, welche Sprache pro OS?
F8. Muss der Schüler-Client im Hintergrund laufen, auch wenn der Schüler die UI schließt?

## C) Exam-Start, Identität, Zuordnung

F9. Ist der PIN pro Exam eindeutig und nur im Prüfungszeitfenster gültig?
F10. Reicht „Name eingeben“ oder muss zusätzlich ein eindeutiges Merkmal geprüft werden (z. B. Keycloak-Login, Matrikelnummer, Geräte-ID)?
F11. Darf ein Schüler sich mehrfach mit demselben Namen verbinden (z. B. auf zwei Geräten), oder muss das verhindert werden?
F12. Was passiert, wenn ein Schüler den Client während des Exams beendet? (nur Alarm / erneute Anmeldung erlauben / Exam als ungültig markieren)

## D) Streaming und Aufnahme

F13. Bitte konkretisieren: gewünschte Live-Latenz in Zahlen (z. B. P95 <= 2s).
F14. Soll 1080p für **Live-Ansicht** gelten, für **Aufzeichnung**, oder für beides?
F15. Welche FPS-Ziele gelten für Live und Recording (z. B. 10/15/25/30 FPS)?
F16. Soll die Aufzeichnung während des gesamten Exams durchgehend laufen?
F17. Muss der Lehrer bei 36 Kacheln alle gleichzeitig als Live-Video sehen, oder dürfen in der Grid-Ansicht reduzierte Qualität/FPS verwendet werden?

## E) Dateisystem-Monitoring

F18. „Alle aktiv verwendeten Ordner“ ist technisch nicht eindeutig: Bitte fixe Regel definieren:
- Option A: Nur ein vordefinierter Exam-Workspace-Pfad je OS
- Option B: Alle Pfade, die während Exam geöffnet/editiert werden
- Option C: Manuell vom Lehrer pro Exam definierte Ordnerliste
F19. Soll der Datei-Diff auf Save-Events basieren oder strikt jede Minute erzwungen werden?
F20. Sollen nur Textdateien verarbeitet werden? Falls ja: welche Extensions sind erlaubt?
F21. Wenn ein Schüler außerhalb des erlaubten Ordners arbeitet: nur Warnung oder auch Markierung als Regelverstoß?

## F) Erkennungssignale (DSGVO-kritisch)

F22. Bitte gib eine **explizite Allowlist** der erlaubten Signale an (ja/nein je Punkt):
- Aktive Fenster-/Prozessnamen J
- Browser-URL des aktiven Tabs J
- OCR auf Bildschirmbildern J
- Clipboard-Inhalt  N
- Tastaturanschläge (Keylogging) N
- Netzwerkziel-Domains J
F23. Welche Signale sind explizit verboten?
F24. Wer pflegt die Liste verbotener AI-Dienste (Domains/Prozesse), und wie oft wird sie aktualisiert?


## G) Datenhaltung, Löschung, Sicherheit

F25. Werden Daten 30 Tage ab **Exam-Ende** gespeichert und danach automatisch gelöscht?
F26. Gilt die 30-Tage-Frist für alle Datentypen gleichermaßen (Video, Diffs, Events, Alarme)?
F27. Wenn „Exam löschen“ ausgeführt wird: sofortige Hard-Delete auch vor Ablauf der 30 Tage?
F28. Sollen gelöschte Daten auch aus Backups entfernt werden, oder dürfen sie dort bis Backup-Retention verbleiben?
F29. Du hast „keine Verschlüsselung“ angegeben: gilt das wirklich für
- Speicherung am Server (at rest)
- Übertragung Client ↔ Server (TLS)
Bitte explizit je Punkt bestätigen.



## H) Architektur und Betrieb

F30. Soll der Server monolithisch sein (Quarkus + Postgres) oder mit separatem Streaming-Service?
F31. Gibt es bereits ein Message-System (z. B. Kafka/RabbitMQ/Redis), das verwendet werden soll?
F32. Soll bei Verbindungsverlust „sofort Alarm“ schon bei z. B. >5 Sekunden ohne Heartbeat ausgelöst werden? Bitte exakten Schwellwert nennen.
F33. E-Mail-Alarm: immer nur an `franklyn@htl-leonding.ac.at` oder zusätzlich an den jeweiligen Lehrer des Exams?

## I) Qualität und Abnahme

F34. Welche minimalen Akzeptanzkriterien für v1 gelten konkret (bitte mit Zahlen, z. B. max. 2s Alarm-Latenz, max. 1% Stream-Abbrüche pro Exam)?
F35. Soll es Testdaten/Mock-Exams für Demo und Abnahme geben (z. B. 1 Klasse mit 30 simulierten Clients)?
