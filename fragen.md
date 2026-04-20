# Fragen zur Spezifikation der Prüfungs-Überwachungsapplikation
Bitte beantworte **jede Frage mit derselben Nummer** in `answers.md`.
Wenn bei einer Frage mehrere Optionen genannt sind, kannst du eine Option wählen oder eine eigene präzise Antwort geben.
## 1) Ziele, Rahmen, Erfolgskriterien
1. Was ist das **primäre Ziel** der Lösung (z. B. Abschreckung, Live-Überwachung, nachträgliche Beweisbarkeit, automatisierte Erkennung, alles zusammen)?
2. Welche **konkreten Missbrauchsfälle** sollen erkannt/verhindert werden (z. B. ChatGPT-Webseite, Copilot in IDE, Messenger, File-Sharing, Remote-Desktop, USB-Stick, Handyfoto)?
3. Welche Missbrauchsfälle sind **explizit außerhalb des Projekts**?
4. Wie definierst du „**unerlaubte Hilfsmittel**“ rechtlich/organisatorisch exakt?
5. Welche **Erfolgskriterien (messbar)** gelten für Version 1 (z. B. Erkennungsrate, max. Fehlalarme, max. Latenz Live-Stream, Verfügbarkeit)?
6. Gibt es einen **Termin** oder Meilensteine (Pilot, Go-Live, Schuljahr)?
## 2) Nutzerrollen und Berechtigungen
7. Welche Rollen gibt es genau (z. B. Lehrkraft, Admin, IT-Admin, Beobachter, Schulleitung)?
8. Welche Aktionen darf jede Rolle (lesen, planen, starten/stoppen Exam, Live ansehen, Zoom, Export, Löschen, Benutzerverwaltung)?
9. Dürfen mehrere Lehrkräfte gleichzeitig denselben Exam überwachen?
10. Braucht ihr eine „Read-only“-Rolle für Prüfungsaufsicht ohne Administrationsrechte?
11. Sollen Schüler selbst irgendeine Oberfläche sehen dürfen (Status, Verbindung, Warnhinweise)?
## 3) Zielplattformen und Infrastruktur
12. Welche Betriebssysteme laufen auf Schüler-PCs (Windows/macOS/Linux, Versionen)?
13. Auf welchem Betriebssystem läuft die Lehrer-Anwendung?
14. Sind alle Geräte im selben lokalen Netz/VLAN während Prüfungen?
15. Gibt es Schulstandorte mit getrennten Netzen/VPN?
16. Ist Internet während Prüfungen immer verfügbar oder nur LAN-intern zuverlässig?
17. Gibt es bereits Server-Infrastruktur (on-prem) oder soll Cloud verwendet werden?
18. Falls Cloud erlaubt: gibt es Vorgaben zu Region (z. B. EU/AT/DE)?
19. Gibt es Vorgaben zu bevorzugten Technologien (z. B. .NET, Java, Node, Python, PostgreSQL)?
## 4) Deployment und Betrieb
20. Wie soll der Schüler-Daemon installiert werden (manuell, Softwareverteilung, GPO, MDM)?
21. Muss der Daemon als Systemdienst mit Autostart laufen?
22. Dürfen Schüler den Dienst beenden/deaktivieren oder soll das technisch verhindert werden?
23. Soll ein fehlender Dienst nur warnen oder den Prüfungsstart blockieren?
24. Wie wird ein Gerät eindeutig einem Schüler zugeordnet (Login, Geräte-ID, QR-Code, Sitzplatz)?
25. Muss die Lösung in Offline-Phasen Daten puffern und später synchronisieren?
26. Wie lange darf ein Client offline sein, bevor ein Alarm entsteht?
27. Wie werden Updates verteilt (automatisch, manuell, Wartungsfenster)?
## 5) Exam-Lebenszyklus und Planung
28. Welche Stammdaten braucht eine Klasse (Name, Jahrgang, Fach, Schülerliste)?
29. Wie werden Schülerlisten gepflegt (manuell, CSV-Import, Schulverwaltungsschnittstelle)?
30. Welche Daten hat ein Exam genau (Titel, Klasse, Raum, Start/Ende, erlaubte Tools, Regeln)?
31. Soll es geplante Exams und spontane „Sofort-Exams“ geben?
32. Dürfen sich Exams derselben Klasse zeitlich überschneiden?
33. Was bedeutet „Exam löschen“ fachlich: hart löschen oder archivieren/soft-delete?
34. Wer darf Exams löschen?
35. Müssen Löschungen revisionssicher protokolliert werden?
36. Braucht ihr Vorlagen (Templates) für wiederkehrende Prüfungen?
## 6) Live-Überwachung (Bildschirm)
37. Soll der Stream als Video-Stream oder als periodische Screenshots umgesetzt werden?
38. Welche Mindestqualität wird benötigt (Auflösung, FPS, Lesbarkeit von Code)?
39. Wie hoch darf die End-to-End-Latenz maximal sein?
40. Muss Multi-Monitor bei Schülern unterstützt werden?
41. Falls ja: alle Monitore oder nur primärer Monitor?
42. Muss Audio erfasst werden?
43. Soll die Lehrkraft einzelne Schüler „anpinnen“/hervorheben können?
44. Soll die Lehrkraft auf Schüler-PCs fernsteuern dürfen oder nur ansehen/zoomen?
45. Wie viele Schüler-Bildschirme sollen gleichzeitig sichtbar sein (typische und maximale Klassengröße)?
46. Braucht ihr Volltextsuche/Filter im Live-Grid (nach Name, Alarmstatus, Klasse)?
47. Sollen Verbindungsstatus und Paketverlust pro Client sichtbar sein?
## 7) Dateisystem-/Code-Überwachung
48. Welche Ordner dürfen überwacht werden (genaue Pfade/Pattern je OS)?
49. Sollen nur bestimmte Dateitypen überwacht werden (z. B. `.py`, `.java`, `.js`, `.txt`, `.md`)?
50. Soll bei Dateiänderungen der **volle Inhalt**, nur Diffs oder nur Metadaten gespeichert werden?
51. In welchem Intervall sollen Dateistände gesichert werden (Echtzeit, alle x Sekunden, bei Save-Event)?
52. Soll Versionierung ähnlich „Timeline“ mit Zeitstempel pro Datei verfügbar sein?
53. Müssen gelöschte Dateien für die Nachschau rekonstruierbar bleiben?
54. Wie groß darf ein einzelnes Dateiartefakt maximal sein?
55. Sollen Binärdateien (z. B. PDFs, Bilder) unterstützt werden?
## 8) Erkennung von unerlaubter Nutzung
56. Welche Signale dürfen zur Erkennung verwendet werden: Fenster-/Prozessnamen, aktive URL, Zwischenablage, Tastatur-/Mausmuster, OCR auf Screen, Netzwerkziele?
57. Welche Signale sind aus Datenschutz-/Rechtsgründen **verboten**?
58. Sollen bekannte AI-Dienste über eine gepflegte Liste erkannt werden (Domains, Apps, Prozesse)?
59. Soll die Erkennung regelbasiert starten oder ist ML/Heuristik gewünscht?
60. Wie soll ein Treffer bewertet werden (Info, Warnung, schwerer Verstoß)?
61. Braucht ihr einen „Confidence Score“ pro Vorfall?
62. Soll bei Verdacht automatisch ein Marker in Video/Timeline gesetzt werden?
63. Soll bei Verdacht ein Live-Popup an Lehrkraft erscheinen oder reicht Ereignisliste?
64. Soll der Schüler bei Verstoß lokal eine Warnmeldung sehen?
65. Sollen Lehrkräfte Vorfälle manuell bestätigen/entkräften können (Review-Workflow)?
## 9) Alarme und Benachrichtigungen
66. Welche Alarmtypen braucht ihr zwingend (Dienst aus, Verbindung weg, Exam-Regelverstoß, AI-Verdacht, Ordner nicht erreichbar)?
67. Welche Reaktionszeit ist für Alarme gefordert?
68. Sollen Alarme quittiert werden können?
69. Braucht ihr Eskalationsregeln (z. B. nach x Minuten an IT/Admin)?
70. Sollen Alarme zusätzlich per E-Mail/Teams/Slack gesendet werden?
## 10) Nachträgliche Analyse (Playback/Forensik)
71. Welche Wiedergabefunktionen sind nötig (Play/Pause, 2x/4x, Sprung zu Alarmen, Bild-für-Bild)?
72. Soll die Timeline Screen-Events und Datei-Events synchron anzeigen?
73. Müssen Notizen/Kommentare der Lehrkraft im Nachhinein speicherbar sein?
74. Soll ein Prüfungsbericht exportierbar sein (PDF/CSV/JSON)?
75. Welche Inhalte müssen in einen Bericht (Verstöße, Zeitpunkte, Screenshots, Dateiverlauf)?
76. Soll Rohmaterial exportierbar sein (Video-Dateien) oder nur interne Ansicht?
## 11) Datenschutz, Recht, Compliance
77. In welchem Rechtsrahmen arbeitet ihr (z. B. DSGVO + nationale Schulgesetze/Bundeslandvorgaben)?
78. Liegt bereits eine Datenschutz-Folgenabschätzung vor?
79. Welche Rechtsgrundlage für Verarbeitung ist vorgesehen (Einwilligung, öffentliches Interesse, gesetzliche Pflicht)?
80. Welche Informationspflichten gegenüber Schülern/Erziehungsberechtigten sind vorgegeben?
81. Müssen Daten verschlüsselt gespeichert werden (at-rest) und übertragen (in-transit)?
82. Wer darf auf Rohdaten zugreifen?
83. Wie lange müssen Daten aufbewahrt werden (Videos, Dateiversionen, Logs, Alarme)?
84. Gibt es unterschiedliche Aufbewahrungsfristen je Datentyp?
85. Muss eine automatische Löschung nach Frist umgesetzt werden?
86. Müssen alle Zugriffe/Aktionen revisionssicher auditiert werden?
87. Gibt es Anforderungen zu Datenminimierung/Pseudonymisierung?
## 12) Sicherheit
88. Wie authentifizieren sich Clients am Server (Gerätezertifikat, Token, Benutzerlogin)?
89. Wie authentifizieren sich Lehrkräfte (lokale Accounts, SSO, AD/LDAP, Microsoft 365)?
90. Ist 2FA für Lehrkräfte erforderlich?
91. Müssen Rollenrechte fein granular pro Klasse/Exam konfigurierbar sein?
92. Welche Bedrohungen sind kritisch (Manipulation des Daemons, Replay, Mitschnitt-Abgriff, Insider)?
93. Soll der Daemon gegen Beenden/Tampering gehärtet werden? Wenn ja, in welchem Ausmaß?
94. Braucht ihr Integritätsprüfungen der Client-Software (Signatur/Hash-Check)?
## 13) Performance und Skalierung
95. Wie viele Klassen gleichzeitig maximal?
96. Wie viele Schüler insgesamt gleichzeitig maximal?
97. Wie viele Lehrkräfte nutzen parallel das System?
98. Welche Zielwerte gelten für CPU/RAM/Netzlast auf Schüler-PCs?
99. Welcher Speicherbedarf ist pro Exam akzeptabel?
100. Gibt es Budgetgrenzen für Server/Storage/Bandbreite?
## 14) UI/UX-Anforderungen
101. Bevorzugt ihr eine Webanwendung, Desktop-App oder beides für Lehrkräfte?
102. Welche Kernansichten braucht die Lehrkraft-Oberfläche (Dashboard, Live-Grid, Timeline, Reports, Admin)?
103. Welche Sprache(n) muss die UI unterstützen?
104. Gibt es Barrierefreiheitsanforderungen?
105. Soll die UI auf Tablets nutzbar sein?
## 15) Integrationen und Datenimport/-export
106. Gibt es bestehende Systeme zur Klassen-/Schülerverwaltung, die integriert werden müssen?
107. Welche Exportformate werden benötigt (CSV, PDF, MP4, JSON)?
108. Braucht ihr eine API für Drittanwendungen?
109. Wenn ja: nur intern oder öffentlich dokumentiert?
## 16) Betrieb, Logging, Support
110. Welche Logs werden benötigt (Client, Server, Security, Audit)?
111. Wer betreibt das System im Alltag (Lehrerteam, IT-Abteilung, externer Dienstleister)?
112. Welche Monitoring-/Alerting-Lösung existiert bereits?
113. Welche Support-Prozesse braucht ihr (Ticketing, Fehlerklassen, SLA)?
114. Soll es einen „Prüfungsmodus-Selbsttest“ vor Exam-Start geben (Kamera/Screen/Ordner/Verbindung ok)?
## 17) Teststrategie und Abnahme
115. Welche Abnahmekriterien muss die erste Version erfüllen?
116. Sind Lasttests mit realistischen Klassengrößen verpflichtend?
117. Sind Sicherheitstests/Penetrationstests verpflichtend?
118. Wer nimmt fachlich ab (einzelne Lehrkraft, Fachgruppe, IT-Leitung)?
119. In welcher Form soll die finale Spezifikation vorliegen (z. B. Markdown mit User Stories + Akzeptanzkriterien + Nicht-Funktionale Anforderungen)?
## 18) Priorisierung
120. Welche 5 Funktionen sind **Muss** für v1?
121. Welche Funktionen sind **Soll** (v1.1/v2)?
122. Welche Funktionen sind **Kann** (später/optional)?