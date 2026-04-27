# Finale Restfragen (danach ist die Spezifikation eindeutig)

Bitte beantworte mit `J1`, `J2`, ... in `answers5.md` (oder ergänze `answers4.md`).

J1. **Admin-Rolle final:** Welche Rechte hat `Admin` genau?
- Option A: nur AI-Domain/Prozessliste verwalten
- Option B: A + alle Exams/Logs lesen
- Option C: Vollzugriff (inkl. Löschen/Ändern)
- Option D: eigene Rechtebeschreibung

A: Vollzugriff

J2. **Keycloak-Mapping konkret:** Kommt `distinguishedName` als Claim direkt im Access-Token?
- Falls nein: aus welchem Token/Endpoint wird es gelesen?
- Bitte auch die Extraktionsregel bestätigen: Klasse wird aus `OU=<Klasse>` im String gelesen.

A: Ja, Ja

J3. **Exam-Löschung vs. 30 Tage:** Was gilt final bei manuellem „Exam löschen“?
- Option A: sofortige Hard-Delete überall (inkl. Backups)
- Option B: sofort im Hauptsystem löschen, Backups spätestens nach 30 Tagen
- Option C: keine sofortige Löschung, nur automatische Löschung nach 30 Tagen

A: sofort hard delete überall.

J4. **Datei-Erfassung final:** In `answers3.md` steht „Alle Dateien“, früher war „nur Textdateien“ und „keine Binärdateien“.
Bitte final festlegen:
- Option A: nur Textdateien
- Option B: alle Dateien inkl. Binärdateien

A: nur Textdateien

J5. **Alarm-Latenz 10s:** Gilt der 10s-Zielwert für
- nur Disconnect-Alarme
- nur Regelverstoß-Alarme
- oder für beide?

A: für alle

J6. **Browser-Anforderung „ab 2024“:** Soll das nur ein **Support-Ziel** sein (nicht technisch geprüft), oder muss die App Browser-Versionen aktiv blockieren, die davor veröffentlicht wurden?

A: Limit existiert nur in den Docs, nicht in der App
