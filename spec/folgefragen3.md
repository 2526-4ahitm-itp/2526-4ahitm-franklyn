# Letzte Präzisierungen (wirklich nur noch wenige Punkte)

Bitte beantworte mit `H1`, `H2`, ... in `answers4.md` (oder in `answers3.md` ergänzt).

H1. **Alarm-Latenz als Zahl:** Du hast „normaler Betriebslatenz“ geschrieben. Bitte gib einen festen Zielwert für v1 an:
- Beispiel: `Regelverstoß-Alarm <= 5s`, `Disconnect-Alarm nach 10s Heartbeat-Ausfall`

H2. **Keycloak-Klassenzuordnung konkret:** Über welches Feld erfolgt die Zuordnung final?
- Option A: Keycloak `group`
- Option B: Keycloak `realm role`
- Option C: Keycloak `user attribute` (z. B. `class=4AHITM`)

A: "distinguishedName" als key und "OU=4AHITM" als Wert innerhalb des Strings.

H3. **Browser-Mindestversionen konkret:** „alle Browser ab 2024“ ist noch nicht maschinenlesbar. Bitte nenne Mindestversionen für v1:
- Chrome >= ?
- Edge >= ?
- Firefox >= ?
- Safari >= ?

A: Zu spezifisch. Browser ab 2024 ist ausreichend.

H4. **MP4-Codec festlegen:** Soll gespeichert werden als
- Option A: H.264 + AAC (AAC ohne Audio-Track möglich)
- Option B: H.265
- Option C: anderer Codec (bitte nennen)

A: H.265 nur ohne Audio.

H5. **AI-Liste ohne Admin-Rolle:** Wenn es keine Admin-Rolle in der App gibt: Wer darf die AI-Domain/Prozessliste ändern?
- Option A: Nur per Codeänderung + Deployment durch IT
- Option B: Lehrer dürfen es in der UI bearbeiten
- Option C: andere Lösung

A: Es gibt eine Admin rolle.

H6. **Datei-Diff mit Option C (best effort):** Welche Dateien kommen in den 1-Minuten-Diff-Job?
- Option A: nur aktuell aktive Datei
- Option B: alle seit Exam-Beginn einmal gespeicherten Dateien
- Option C: andere Regel

A: Alle Dateien

H7. **Netzwerkziel-Domains (Option B, ganzes Gerät):** Darf der Client dafür OS-/Firewall-Rechte anfordern, falls nötig (je nach OS evtl. Adminrechte)?
- Ja / Nein

A: c

H8. **Vor-Exam-Aufzeichnung:** Bestätigung der finalen Regel:
- Startet Aufzeichnung bei Login, **wenn Loginzeit in [Exam-Start - 60 min, Exam-Ende]** liegt; sonst kein Recording.
- Ende weiterhin erst bei manuellem Logout.
Ist das exakt korrekt? (Ja/Nein + Korrektur)

A: Ja

H9. **Mehrfach-Login verhindern:** Gilt „ein Schüler nur eine aktive Session“ klassenübergreifend global oder nur innerhalb eines Exams?

A: Global

H10. **Speicherung unverschlüsselt:** Final bestätigen, dass Server-Storage (Videos, Diffs, Events) bewusst unverschlüsselt bleibt und das als akzeptiertes Risiko dokumentiert werden soll.

A: bewusst unverschlüsselt