# SDDM-Theme "Clockwork" (qylock)

- **Maschine / Hostname:** thinkpad
- **Kategorie:** 02-Ricing
- **Status:** In Einrichtung
- **Letztes Update:** 2026-10-18
- **Verwandte Dokumentation:** [01-hyprland.md](01-hyprland.md) (Architektur-Entscheidung SDDM als Login-Manager, Abschnitt 1), [README.md](../../README.md)

---

## 1. Übersicht, Architektur & Zweck
- **Was ist das?** [`qylock`](https://github.com/Darkkal44/qylock) ist eine GPL-3.0-lizenzierte Sammlung mehrerer fertiger **SDDM-Login-Themes** (zusätzlich auch Quickshell-Lockscreen-Setups, die wir hier nicht nutzen). **"Clockwork"** ist eines der darin enthaltenen Einzel-Themes (Schriftart *Orbitron*, animierter Video-Hintergrund). Technisch ist ein SDDM-Theme ein eigenständiges QML-Projekt (gleiche deklarative UI-Sprache wie bei unserer [Quickshell](04-quickshell.md)-Konfiguration) unter `/usr/share/sddm/themes/<theme-name>/`, das SDDM beim Start des grafischen Greeters anhand des Schlüssels `Theme=<theme-name>` in `/etc/sddm.conf` (bzw. einer Datei in `/etc/sddm.conf.d/`) lädt — eine reine Austausch-Komponente, keine Änderung an SDDM selbst oder an Hyprland.
- **Warum nutzen wir es auf dieser Maschine?** Rein kosmetisches Ricing-Ziel: Der SDDM-Standard-Greeter (Theme `breeze`, Teil des `sddm`-Pakets) wird durch ein optisch passenderes, individuell gestaltetes Theme ersetzt, bevor überhaupt eine Hyprland-Session startet. Ordnet sich in die allgemeine Ricing-Linie des Projekts ein (siehe [04-quickshell.md](04-quickshell.md)).
- **Installations-Mechanismus (Besonderheit gegenüber unseren bisherigen Themen/Tools):** `qylock` liefert kein einzeln kopierbares Theme-Verzeichnis, sondern ein **interaktives Installations-Skript** (`sddm.sh`) im Repository-Root, das nach Auswahl des gewünschten Themes (hier: Clockwork) die passenden Dateien selbst nach `/usr/share/sddm/themes/` kopiert und `/etc/sddm.conf.d/` entsprechend einträgt. Das Repository selbst ist **nicht** Teil dieses Maschinen-Repos (`arch-linux-laptop`) — es wird nur temporär an beliebiger Stelle (z. B. `~/Downloads/`) geklont, das Skript ausgeführt, und anschließend kann der Klon wieder gelöscht werden.
- **Abweichender Verzeichnisname (verifiziert 2026-10-18):** Das Skript legt das Theme unter dem internen Codenamen `/usr/share/sddm/themes/orbital/` an — **nicht** unter `clockwork`. Die `metadata.desktop` im Theme-Ordner weist zur Bestätigung `Name=clockwork` / `Description=Orbital - Clockwork` aus. Aktiviert wird es über `/etc/sddm.conf.d/theme.conf` mit dem Eintrag `Current=orbital`. Wichtig für Abschnitt 11 (Rollback) und jede künftige Suche im System: Pfade und `grep`-Suchen müssen auf `orbital` zielen, nicht auf `clockwork`.
- **Offizielle Referenzen:**
  - [qylock GitHub-Repository](https://github.com/Darkkal44/qylock)
  - [Arch Wiki: SDDM](https://wiki.archlinux.org/title/SDDM)

## 2. Abhängigkeiten & System-Voraussetzungen
- **Pflicht-Pakete — live verifiziert 2026-10-18 (`pacman -Qs`/`pacman -Ss`):**
  - `qt6-declarative`, `qt6-5compat`, `qt6-svg`, `qt6-multimedia`, `qt6-multimedia-ffmpeg`: **Alle bereits installiert** (Qt6-Laufzeit, großteils schon durch die SDDM/Hyprland- bzw. Dolphin-Installation mitgebracht, siehe [01-hyprland.md](01-hyprland.md) Abschnitt 3) — keine weitere Aktion nötig.
  - `gst-plugins-base`, `gst-plugins-good`, `gst-plugins-bad`, `gst-plugins-ugly`: **Fehlten vollständig.** Nur die davon zu unterscheidenden Laufzeitbibliotheken `gst-plugins-base-libs`/`gst-plugins-bad-libs` waren bereits installiert (von anderen Programmen gegen gelinkte Shared Libraries) — die eigentlichen Plugin-Pakete mit den GStreamer-Elementen (Decoder/Demuxer) fehlten. Nachinstalliert via `sudo pacman -S --needed gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly`.
- **Optionale Pakete:** `fzf` — laut Repo nur für die interaktive Auswahl im Installations-Skript selbst relevant, kein Laufzeit-Bestandteil des Themes.
- **Hardware-Voraussetzung (maschinen-spezifisch zu beobachten):** Clockwork spielt einen Video-Hintergrund (`bg.mp4`) ab, dessen Decodierung über den Qt6Multimedia/GStreamer-Stack läuft. Auf dieser Maschine rendert der SDDM-Greeter auf dem Display, auf dem er erscheint — beim internen Panel (`eDP-1`) ist das die Intel-iGPU (siehe [nvidia-prime-hybrid-grafik.md](../01-drivers-hardware/nvidia-prime-hybrid-grafik.md), Hybrid-Grafik-Topologie). Potenzielle Ruckler/Performance der Video-Wiedergabe auf dem Login-Bildschirm sind daher ein Punkt für die Verifizierung in Abschnitt 9, sobald das Theme läuft.

## 3. Installation & Flag-Erklärung
- **Status (verifiziert 2026-10-18):** Installation wurde bereits durchgeführt — `/usr/share/sddm/themes/orbital/` existiert, `/etc/sddm.conf.d/theme.conf` setzt `Current=orbital` korrekt. Die ursprünglich geplante Schritt-für-Schritt-Begleitung im Chat (Klonen, `sddm.sh`, Menü-Auswahl) ist damit faktisch abgeschlossen; eine nachträgliche Rekonstruktion der genauen Befehlsfolge steht noch aus und sollte hier ergänzt werden, sobald sie aus deiner Shell-History/Erinnerung rekonstruiert ist (für die Disaster-Recovery-Reproduzierbarkeit in der README).

## 4. System-Eingriffe (Kernel, Treiber, Boot, Berechtigungen)
- *Nicht zutreffend / Keine Einträge* (reines Greeter-Theme, kein Kernel-/Treiber-Bezug).

## 5. Konfiguration & Dotfiles (Deep-Dive & GNU Stow)
- **Kein GNU-Stow-Paket:** Analog zur NVIDIA-`modprobe`-Konfiguration ([nvidia-prime-hybrid-grafik.md](../01-drivers-hardware/nvidia-prime-hybrid-grafik.md), Abschnitt 5) liegen die Theme-Dateien (`/usr/share/sddm/themes/clockwork/`) und die SDDM-Konfiguration (`/etc/sddm.conf.d/*.conf`, Schlüssel `Theme=`) systemweit außerhalb von `~/` — GNU Stow ist dafür architektonisch nicht vorgesehen. Unterschied zur NVIDIA-Config: Hier legt nicht der User die Datei händisch an, sondern das `sddm.sh`-Installations-Skript — wird nach erfolgreicher Installation hier dokumentiert (exakter `Theme=`-Wert, ggf. angepasste Theme-Optionen), damit der Schritt im Disaster-Recovery-Fall (README Abschnitt 4) reproduzierbar bleibt, auch ohne dass die Dateien selbst versioniert sind.
- **Konfigurations-Block:** *Folgt, sobald das Theme installiert und der exakte `sddm.conf.d`-Eintrag bekannt ist.*

## 6. Ricing, Theming & Desktop-Integration
- *Folgt nach Installation — insbesondere Farbschema-/Options-Abstimmung des Clockwork-Themes, falls vom Installations-Skript angeboten.*

## 7. Systemd, Autostart & Automatisierung
- *Nicht zutreffend / Keine Einträge* (SDDM selbst läuft bereits als `sddm.service`, siehe [01-hyprland.md](01-hyprland.md) Abschnitt 7 — das Theme ändert nichts an dessen Autostart-Verhalten).

## 8. Dateisystem (z. B. Btrfs), Netzwerk & Sicherheit
- *Nicht zutreffend / Keine Einträge*

## 9. Verifizierung, Diagnose & Cheatsheet
- *Folgt nach Installation — insbesondere visueller Test des Greeters (`sddm.conf`-Theme korrekt gesetzt?) und Beobachtung der Video-Hintergrund-Performance (siehe Abschnitt 2).*

## 10. Troubleshooting & Fehler-Historie (Lern-Protokoll)
### [2026-10-18] - UI-Texte bleiben nach Login/Logout komplett auf Englisch
- **Symptom / Fehlermeldung:** Nach vollständigem Logout und erneutem Login am SDDM-Greeter erscheinen sämtliche UI-Texte des Themes ("Reboot", "Shutdown", "ENTER KEY", "WAITING FOR KEY", "ACCESS DENIED", "Session", "USER") weiterhin ausschließlich auf Englisch, obwohl die System-Locale korrekt auf Deutsch steht (`/etc/locale.conf` → `LANG=de_DE.UTF-8`, verifiziert via `localectl status`).
- **Technische Ursache (Root Cause):**
  - Das tatsächlich installierte Theme-Verzeichnis heißt `/usr/share/sddm/themes/orbital/` (nicht `clockwork`) — `metadata.desktop` weist `Name=clockwork` / `Description=Orbital - Clockwork` aus; das `sddm.sh`-Installationsskript des `qylock`-Repos benennt den Zielordner intern nach dem Codenamen `orbital`, nicht nach dem im Menü sichtbaren Theme-Namen. Aktiviert ist es korrekt über `/etc/sddm.conf.d/theme.conf` (`[Theme]` / `Current=orbital`).
  - Alle sichtbaren UI-Beschriftungen sind in `Main.qml` als reine String-Literale hart codiert, u. a.:
    - Zeile 232: `label: "Reboot"`
    - Zeile 234: `label: "Shutdown"`
    - Zeile 230: Fallback `"Session"`
    - Zeile 264: Fallback `"USER"`
    - Zeile 275: `text: "WAITING FOR KEY"`
    - Zeile 286: `text: "ENTER KEY"`
    - Zeile 311: `errText.text = "ACCESS DENIED"`
  - Qt stellt für genau diesen Zweck das Internationalisierungs-System über `qsTr("Text")` (zur Laufzeit per `.qm`-Übersetzungsdatei ersetzbar) zur Verfügung. Eine Suche (`grep -r "qsTr\|i18n\|Locale\|LANG"`) über den gesamten Theme-Ordner ergibt **keinen einzigen Treffer** — das Theme nutzt diesen Mechanismus nirgends. Die einzige tatsächlich locale-abhängige Stelle ist die Datums-/Wochentagsanzeige der Uhr (`Qt.formatDate(new Date(), "dddd")`, Zeile 217 bzw. `"dd MMM yyyy"`, Zeile 216), die über Qt's `QLocale::system()` läuft und sich automatisch an `LANG` orientiert — vorausgesetzt, der `sddm`-Greeter-Prozess erbt diese Umgebungsvariable tatsächlich.
  - Fazit: Es handelt sich **nicht** um einen Konfigurationsfehler (Locale ist korrekt gesetzt), sondern um eine fest im Quellcode des Themes verankerte Sprachwahl des Autors, die durch keine System-Einstellung beeinflusst werden kann.
- **Gescheiterte Ansätze & Lerneffekt:** Keine Locale-Anpassung (`/etc/locale.conf`, `localectl`) kann dieses Verhalten beheben, da die Strings nicht über Qt's Übersetzungs-API geladen werden — Zeitverschwendung wäre es, hier an System-Locale-Einstellungen zu drehen, solange `qsTr()` im Theme-Code fehlt. Lerneffekt: Qt/QML-Lokalisierung ist **opt-in pro String** (`qsTr(...)`) und kein automatisches System-Feature, das jede Qt-Anwendung "kostenlos" bekommt.
- **Finale Lösung:** Da `Main.qml` eine System-Datei außerhalb dieses Repos ist (`/usr/share/sddm/themes/orbital/`), nimmt die AI laut Berechtigungs-Matrix dort **keine Bearbeitung** vor. Manuelle Lösung für den User: Datei mit Root-Rechten öffnen (z. B. `sudoedit /usr/share/sddm/themes/orbital/Main.qml`) und die oben gelisteten String-Literale direkt durch deutsche Begriffe ersetzen. Da die Datei außerhalb von `dotfiles/` liegt und von `pacman`/dem Installationsskript verwaltet wird, sollte diese manuelle Änderung zusätzlich hier in Abschnitt 5 als Patch dokumentiert werden, sobald sie vollständig durchgeführt wurde (Gefahr: geht bei Theme-Updates/Neuinstallation wieder verloren).
- **Zwischenstand (2026-10-18, manuelle Übersetzung durch User, Review durch AI auf Tippfehler):**
  - Zeile 275 `"WAITING FOR KEY"` → `"WARTE AUF EINGABE"` — korrekt übernommen.
  - Zeile 286 `"ENTER KEY"` → `"PASSOWRT EINGABE"` — **Tippfehler** (Buchstaben vertauscht, korrekt wäre `"PASSWORT EINGABE"`), noch zu korrigieren.
  - Noch unübersetzt (Original-Englisch): Zeile 230 Fallback `"Session"`, Zeile 232 `"Reboot"`, Zeile 234 `"Shutdown"`, Zeile 264 Fallback `"USER"`, Zeile 311 `"ACCESS DENIED"`.

### [2026-10-18] - Wochentage in der Uhr-Anzeige bleiben trotz korrekter System-Locale englisch
- **Symptom / Fehlermeldung:** Die Datums-/Wochentagsanzeige der Clockwork-Uhr (`Qt.formatDate(new Date(), "dddd")` in `Main.qml`, Zeile 217) zeigt weiterhin englische Wochentagsnamen (z. B. "MONDAY" statt "MONTAG"), obwohl `/etc/locale.conf` korrekt `LANG=de_DE.UTF-8` gesetzt hat und `locale -a` die Locale `de_DE.utf8` als generiert ausweist. Dies ist technisch unabhängig vom in diesem Dokument zuerst behandelten Problem der hartcodierten englischen Button-Labels (siehe Eintrag oben) — hier geht es um eine tatsächlich locale-abhängige Qt-Funktion, die trotzdem Englisch anzeigt.
- **Technische Ursache (Root Cause):** Verifiziert über `journalctl -u sddm -b`: Der eigentliche Greeter-Prozess (`sddm-greeter-qt6`) wird vom `sddm-helper` über eine **eigene PAM-Login-Session für den System-User `sddm` (uid 966)** gestartet (`pam_unix(sddm-greeter:session): session opened for user sddm by (uid=0)`) — nicht für den User `pascal`. Diese PAM-Session erbt **nicht automatisch** die systemweite `/etc/locale.conf`; `systemctl show-environment` zeigt zwar `LANG=de_DE.UTF-8` im Default-Environment von PID 1, aber dieser Wert wird nicht an die separate `sddm`-PAM-Session durchgereicht. SDDM sieht dafür in `/usr/lib/sddm/sddm.conf.d/default.conf` extra den Schlüssel `[General]`/`GreeterEnvironment=` vor ("Comma-separated list of environment variables to be set") — Standardwert: **leer**. Ohne diesen Eintrag startet `sddm-greeter-qt6` faktisch in der POSIX/"C"-Locale, wodurch `QLocale::system()` (von `Qt.formatDate` intern genutzt) auf englische Wochentags-/Monatsnamen zurückfällt.
- **Gescheiterte Ansätze & Lerneffekt:** Die ursprüngliche Annahme (siehe Troubleshooting-Eintrag oben, Abschnitt "Root Cause", Punkt 1) war, dass die Datumsanzeige automatisch die korrekte System-Locale übernimmt, *sofern* der Greeter-Prozess `LANG` erbt. Das war die richtige Diagnose der Mechanik, aber die falsche Annahme war, dass dieses Erben automatisch passiert — tatsächlich tut es das nicht, weil der Greeter unter einem eigenen System-User mit eigener, von `/etc/locale.conf` isolierter PAM-Session läuft. Lerneffekt: System-Dienste, die unter einem dedizierten System-User (hier `sddm`) laufen, erben nicht automatisch die interaktive Locale des eingeloggten Users oder gar die von `/etc/locale.conf` — jede locale-abhängige Komponente in einer solchen isolierten Session braucht eine explizite, dienstspezifische Env-Weitergabe.
- **Finale Lösung:** Neue Datei `/etc/sddm.conf.d/locale.conf` (System-Config außerhalb dieses Repos, manuell vom User anzulegen) mit:
  ```ini
  [General]
  GreeterEnvironment=LANG=de_DE.UTF-8,LC_TIME=de_DE.UTF-8
  ```
  `LANG` setzt die Basis-Locale für den Greeter-Prozess; `LC_TIME` zusätzlich explizit für Datums-/Zeitformatierung (robuster gegen Qt-interne Prioritätsreihenfolgen zwischen `LC_ALL`/`LC_TIME`/`LANG`). Mehrere Variablen werden kommagetrennt, ohne Leerzeichen, übergeben.
  **Wichtig:** SDDM liest seine Konfiguration nur beim Start des `sddm.service`-Daemons neu, nicht bei jedem einzelnen Greeter-Aufruf — ein reines Ausloggen reicht zum Testen nicht aus. Nötig ist `sudo systemctl restart sddm` oder ein Reboot.
  - **Korrektur (2026-10-18, nach realem Test):** Die ursprüngliche Annahme oben ("ein Service-Restart sollte eine bereits laufende Sitzung daher nicht beenden") war **falsch** und wurde live widerlegt — siehe eigener Troubleshooting-Eintrag unten ("`systemctl restart sddm` beendet entgegen Erwartung die aktive Sitzung").
  - **Bestätigung der Diagnose durch reinen Logout-Test (2026-10-18):** Vor dem geplanten `systemctl restart sddm` wurde zunächst nur ganz normal ausgeloggt (kein Service-Neustart, kein Reboot). Ergebnis am Greeter: Datum erschien weiterhin als `18 OCT 2026`, Wochentag als `SUNDAY` — beides unverändert Englisch. Das ist **kein neuer Fehler**, sondern exakt die oben dokumentierte Erwartung: `/etc/sddm.conf.d/locale.conf` wurde zwar angelegt, aber da SDDM seine Konfiguration nur beim Start des `sddm.service`-Daemons neu einliest, greift `GreeterEnvironment=LANG=de_DE.UTF-8,LC_TIME=de_DE.UTF-8` erst nach `sudo systemctl restart sddm` oder einem Reboot. Zusätzliche Bestätigung des Root Cause: Auch die Monatsabkürzung (`OCT` statt `OKT`) blieb Englisch — `Qt.formatDate` zieht Wochentags- **und** Monatsnamen aus derselben `LC_TIME`-Locale, beide Symptome haben also denselben, bereits identifizierten Ursprung (Config noch nicht aktiv geladen).

### [2026-10-18] - `systemctl restart sddm` beendet entgegen Erwartung die aktive Sitzung
- **Symptom / Fehlermeldung:** Nach `sudo systemctl restart sddm` (zum Testen der neuen `GreeterEnvironment`-Einstellung, siehe Eintrag oben) wurde die aktuell laufende Hyprland-Sitzung sofort beendet — erneuter Login am Greeter war nötig. `sudo systemctl status sddm` direkt danach zeigte den Dienst korrekt als `active (running)` mit frischer Start-Zeit, keine Fehlermeldung im Log; `journalctl` zeigte lediglich den normalen Auth-/Session-Start-Ablauf nach dem erneuten Einloggen (`pam_unix(sddm:session): session opened for user pascal ...`, `Session started true`).
- **Technische Ursache (Root Cause):** `sudo systemctl status sddm` zeigte die CGroup-Struktur: `/system.slice/sddm.service` enthält sowohl den `sddm`-Hauptprozess (PID 1439) als auch den Xorg-Prozess des Greeters (PID 1476, `vt2`) als direkte Kindprozesse. Systemd-Services terminieren beim Stop (impliziert bei `restart`) standardmäßig über `KillMode=control-group` **alle** Prozesse innerhalb ihrer eigenen CGroup — nicht nur den Hauptprozess. Da `sddm-helper` die eigentliche Wayland/Hyprland-User-Session über `/usr/share/sddm/scripts/wayland-session` letztlich innerhalb dieses Prozessbaums anstößt, reißt ein Neustart des Daemons die komplette CGroup und damit auch die laufende grafische Sitzung mit in den Tod — unabhängig davon, dass die Session selbst Wayland (Hyprland) statt X11 nutzt. Der X11-Server, den man im Log sieht, gehört ausschließlich zum Greeter-Bildschirm.
- **Gescheiterte Ansätze & Lerneffekt:** Die vorherige Annahme (siehe Lösungs-Eintrag oben, letzter Satz) war, ein Service-Restart würde eine bereits laufende Sitzung nicht beenden, weil Hyprland "auf einem eigenen VT" läuft. Das ist zwar technisch richtig (eigenes VT), aber irrelevant für die Frage, ob der Prozess getötet wird — entscheidend ist die CGroup-Zugehörigkeit, nicht das VT. Lerneffekt: Bei systemd-Diensten mit `KillMode=control-group` (Default) muss man die komplette Prozess-Abstammung prüfen (`systemctl status <dienst>` zeigt das CGroup-Baumdiagramm), nicht nur "auf welchem VT/Display läuft was" – alles, was im selben Cgroup-Baum hängt, stirbt mit dem Dienst.
- **Finale Lösung:** Kein Bug, kein Handlungsbedarf — das Verhalten ist für diesen Anwendungsfall (Config-Test) sogar gewünscht, da man den Greeter-Bildschirm ohnehin neu sehen will. Für künftige Tests von `sddm`-Config-Änderungen gilt daher: **Offene Arbeiten vorher speichern**, der Neustart beendet garantiert die aktive Sitzung. Alternative ohne Session-Verlust: Änderungen vor dem nächsten regulären Reboot/Logout "ansammeln" und dann in einem Zug testen, statt für jede einzelne Config-Anpassung einen separaten Service-Restart auszulösen.

### [2026-10-18] - Datum/Wochentag trotz nachweislich korrektem `GreeterEnvironment` weiterhin englisch
- **Symptom / Fehlermeldung:** Trotz korrekt gesetzter `GreeterEnvironment=LANG=de_DE.UTF-8,LC_TIME=de_DE.UTF-8` (siehe Eintrag oben) und vollständigem Reboot zeigte die Uhr im Greeter weiterhin `SUNDAY`/`OCT` statt `SONNTAG`/`OKT`.
- **Technische Ursache (Root Cause):** Schrittweise empirisch ausgeschlossen:
  1. `sudo cat /proc/<PID-von-sddm-greeter-qt6>/environ | grep -iE '^(LANG|LC_)'` zeigte `LANG=de_DE.UTF-8` und `LC_TIME=de_DE.UTF-8` korrekt im Environment des laufenden Greeter-Prozesses — die Config-Weitergabe war also nie das Problem.
  2. Ein Isolationstest mit `qml6` (reines Qt6/QML, ganz ohne SDDM) unter identischem Environment zeigte: `Qt.locale().name` lieferte korrekt `de_DE`, aber `Qt.formatDate(new Date(), "dddd")` lieferte trotzdem `Sunday`. `Qt.locale().toString(new Date(), "dddd")` lieferte dagegen korrekt `Sonntag`.
  - **Fazit:** Die globale QML-Funktion `Qt.formatDate(date, format)` nutzt bei einem freien Format-String (statt eines `Qt::DateFormat`-Enums) **intern eine feste Locale**, unabhängig vom System-/Default-Locale — sie ignoriert `Qt.locale()`. Für lokalisierte Monats-/Wochentagsnamen mit eigenem Formatmuster muss stattdessen explizit `Qt.locale().toString(date, format)` verwendet werden. Dieses Verhalten ist unabhängig von SDDM, `GreeterEnvironment` oder System-Locale-Generierung — ein reines Qt6/QML-API-Detail.
- **Gescheiterte Ansätze & Lerneffekt:** Die naheliegende Annahme war, ein korrekt gesetztes Prozess-Environment reiche für jede Qt-Locale-abhängige Funktion automatisch aus. Lerneffekt: Bei QML-Funktionen mit einem optionalen Locale-Parameter (hier implizit über `Qt.formatDate` vs. explizit über `Qt.locale().toString()`) immer genau prüfen, welche der beiden Varianten tatsächlich die aktive Locale verwendet — nicht von der Doku-Kurzbeschreibung allein ausgehen, sondern isoliert (hier: via `qml6`, losgelöst von SDDM) empirisch verifizieren.
- **Finale Lösung (Patch für `Main.qml`, Zeilen 216–217 — Datei liegt außerhalb des Repos unter `/usr/share/sddm/themes/orbital/Main.qml`, daher hier zur Nachvollziehbarkeit dokumentiert):**
  ```qml
  // Vorher (Zeile 216):
  Text { text: Qt.formatDate(new Date(), "dd MMM yyyy").toUpperCase(); ... }
  // Nachher:
  Text { text: Qt.locale().toString(new Date(), "dd MMM yyyy").toUpperCase(); ... }

  // Vorher (Zeile 217):
  Text { text: Qt.formatDate(new Date(), "dddd").toUpperCase(); ... }
  // Nachher:
  Text { text: Qt.locale().toString(new Date(), "dddd").toUpperCase(); ... }
  ```
  Anwendung via `sudoedit /usr/share/sddm/themes/orbital/Main.qml`. Test erfordert nur einen normalen Logout (kein `systemctl restart sddm` nötig, siehe Begründung im Eintrag oben zu `KillMode=control-group`), da die QML-Datei bei jedem Greeter-Start frisch neu geladen wird.
  - **Status (Stand Ende der heutigen Session):** Fix isoliert via `qml6`-Testdatei verifiziert (`Sonntag` statt `Sunday`), der Patch an der echten `Main.qml` wurde dir als exakte Anleitung übergeben — die Bestätigung am realen Greeter-Bildschirm nach Logout steht noch aus und wird beim nächsten Mal nachgetragen, bevor diese Doku auf `Aktiv & Stabil` gesetzt wird.

## 11. Wartung, Updates & Rollback (Saubere Deinstallation)
- *Wird nach Installation ergänzt — voraussichtlich: `Theme=` in `/etc/sddm.conf.d/` zurück auf `breeze` setzen, Theme-Verzeichnis unter `/usr/share/sddm/themes/clockwork/` manuell löschen.*
