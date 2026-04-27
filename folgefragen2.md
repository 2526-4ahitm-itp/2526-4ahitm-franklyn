# Letzte offene Fragen zur Eindeutigkeit der Spezifikation

Bitte beantworte wieder mit `G1`, `G2`, ... (in `answers2.md` oder `answers3.md`).

## 1) Widersprüche/Unklarheiten aus den bisherigen Antworten

G1. In `answers.md` stand E-Mail-Alarm **ja** (an `franklyn@...`), in `answers2.md` steht **kein E-Mail-Alarm**. Was gilt final für v1?
G2. Rollen waren zuerst nur „Lehrer“ und „Schüler“, später pflegen „Admins“ die AI-Blockliste. Gibt es final doch eine dritte Rolle **Admin**? Wenn ja: welche Rechte genau?
G3. Du hast „alle Browser“ geschrieben. Für die Spezifikation brauche ich konkrete Mindestversionen. Bitte nenne je Browser (Chrome, Edge, Firefox, Safari) die Mindestversion oder „nicht unterstützt“.
G4. Du hast „ubuntu 24.05“ angegeben. Meinst du `Ubuntu 24.04 LTS`? Bitte genaue OS-Versionen final bestätigen.

## 2) Identität, Klassen und Keycloak

G5. Wie wird ein Schüler eindeutig einer Klasse zugeordnet: über Keycloak-Group, Realm-Role oder Attribut? Bitte genau ein Modell festlegen.
G6. Kann ein Lehrer mehrere Klassen haben? Falls ja: darf er nur diese sehen?
G7. Darf ein Lehrer Exams anderer Lehrer sehen?
G8. Müssen Lehrkräfte sich ebenfalls über Keycloak authentifizieren (OIDC), oder gibt es lokale Accounts?

## 3) Exam-Regeln und gleichzeitige Prüfungen

G9. Bei parallelen Exams: Darf ein Schüler gleichzeitig in zwei Exams eingeloggt sein? (wahrscheinlich nein, bitte bestätigen)
G10. Was passiert, wenn der Schüler nach Exam-Ende weiter eingeloggt bleibt? Aufnahme sofort stoppen oder bis manuell logout?
G11. Soll es einen „Exam gestartet“ Zustand geben, ab dem erst Überwachung aktiv ist, auch wenn Login schon vorher passiert ist?

## 4) Live-Ansicht, Aufnahme, Skalierung

G12. Bitte bestätige final: Live-Grid zeigt **6 gleichzeitig**, Navigation via Pagination; kein 36er-Grid – korrekt?
G13. Aufzeichnung soll 1080p mit 1–10 FPS sein. Bitte gib einen festen Default für v1 (z. B. 1080p/5 FPS), damit Implementierung und Storage planbar sind.
G14. Soll Live-Stream dieselbe Qualität wie Recording haben oder darf Live adaptiv heruntergeregelt werden?
G15. Welcher Video-Codec/Container ist gewünscht für Speicherung/Export (z. B. H.264 in MP4)?
G16. Soll Audio dauerhaft ausgeschlossen bleiben (auch beim Export)?

## 5) Datei-Überwachung (technische Präzisierung)

G17. „Alle Pfade, die während Exam geöffnet/editiert werden“: Wie erkennt der Client das auf allen OS ohne IDE-Integration?
- Option A: Nur Dateien in einem konfigurierten Arbeitsverzeichnis überwachen
- Option B: OS-Datei-Events global beobachten (inkl. allen User-Pfaden)
- Option C: Nur aktive Fenster-App + zuletzt gespeicherte Datei (best effort)
Bitte eine Option final festlegen.
G18. „Nur Diffs jede Minute erzwungen“: Wird der Diff jeweils gegen den letzten gespeicherten Stand berechnet (incremental), korrekt?
G19. Sollen sehr große Textdateien eine Obergrenze haben (z. B. max 5 MB pro Datei), um Serverlast zu begrenzen?

## 6) AI-Erkennung / Signals

G20. Für URL-Erkennung: Dürfen nur Browser im Vollbildmodus überwacht werden oder immer das aktive Browserfenster?
G21. Für Netzwerkziel-Domains: auf welcher Ebene?
- Option A: Nur vom Browser-Prozess
- Option B: Alle ausgehenden Verbindungen des Geräts
G22. Bei Treffer auf verbotene Domain/Prozess: Soll pro Ereignis ein neuer Alarm erzeugt werden oder mit Cooldown (z. B. max 1 Alarm pro 30s je Schüler + Regel)?
G23. Soll OCR kontinuierlich laufen oder nur bei Trigger (z. B. unbekannter Browser-Tab/Fensterwechsel)?

## 7) Sicherheit und Datenschutz    

G24. Bitte final bestätigen: TLS in Transit = **ja**, Verschlüsselung at-rest auf Server = **nein**.
G25. Wenn Daten auch aus Backups gelöscht werden müssen: Welche maximale Zeit bis vollständige Löschung (z. B. <= 24h, <= 7 Tage)?
G26. Wer darf „Exam löschen“ ausführen – nur Exam-Eigentümer (Lehrer) oder zusätzlich Admin?
G27. Soll das System ein Audit-Log für sicherheitsrelevante Aktionen führen (Login, Exam erstellt/gelöscht, Rollenänderung), auch wenn keine formale Revisionspflicht besteht?

## 8) Nicht-funktionale Anforderungen

G28. Bitte gib konkrete Zielwerte für Schüler-Client-Last an (z. B. CPU <= 10% im Mittel, RAM <= 300 MB).
G29. Alarm-Latenz final: bei Regelverstoß oder Disconnect innerhalb welcher Zeit (z. B. <= 2s, <= 5s)?
G30. Verfügbarkeit/Zuverlässigkeit für v1: gibt es ein Ziel (z. B. 99% während Prüfungszeiten), oder kein SLA?
