# Quickshell (Desktop-Shell-Toolkit)

- **Maschine / Hostname:** thinkpad
- **Kategorie:** 02-Ricing
- **Status:** Aktiv & Stabil
- **Letztes Update:** 2026-10-18
- **Verwandte Dokumentation:** [01-hyprland.md](01-hyprland.md), [README.md](../../README.md)

---

## 1. Übersicht, Architektur & Zweck
- **Was ist das?** `Quickshell` ist kein fertiges Produkt (wie z. B. Waybar), sondern ein **Toolkit** zum Selberbauen von Desktop-Shell-Komponenten (Statusbar, Widgets, Benachrichtigungs-Overlays, Lock-Screens) mittels **QtQuick/QML** — derselben deklarativen UI-Beschreibungssprache, die auch SDDM für seinen Greeter nutzt (siehe [01-hyprland.md](01-hyprland.md), Abschnitt 1). Im Gegensatz zu Waybar (fertige Statusbar, nur über JSON-Konfiguration anpassbar) erlaubt Quickshell freie, programmierbare Gestaltung.
- **Warum nutzen wir es auf dieser Maschine?** Deutlich mehr gestalterische Freiheit für das Ricing-Ziel dieses Projekts als eine vorgefertigte Statusbar — Kompromiss: höherer Einarbeitungs-/Konfigurationsaufwand, da im Grunde eigener QML-Code geschrieben wird (oder eine fertige Quickshell-Konfiguration wie `dms-shell`, die wir **nicht** installiert haben, als Referenz studiert wird).
- **Offizielle Referenzen:**
  - [Quickshell-Dokumentation](https://quickshell.outfoxxed.me/)
  - [Quickshell GitHub-Repository](https://github.com/outfoxxed/quickshell)

## 2. Abhängigkeiten & System-Voraussetzungen
- **Pflicht-Pakete:** `quickshell` (`extra`, 0.3.2-1).
- **Verwandtes, NICHT installiertes Paket:** `dms-shell` (fertige Quickshell-basierte Shell mit Material-3-Design) — bewusst nicht gewählt, da wir eine eigene Konfiguration aufbauen wollen (Learning-by-Doing-Ansatz dieses Projekts), kann aber jederzeit als Referenz/Inspiration separat betrachtet werden.
- **System-Voraussetzung:** Qt6-Laufzeitbibliotheken (bereits durch die Hyprland/SDDM-Installation vorhanden, siehe [01-hyprland.md](01-hyprland.md), Abschnitt 3).

## 3. Installation & Flag-Erklärung
- Siehe Sammel-Installationsbefehl in [01-hyprland.md](01-hyprland.md), Abschnitt 3.

## 4. System-Eingriffe (Kernel, Treiber, Boot, Berechtigungen)
- *Nicht zutreffend / Keine Einträge*

## 5. Konfiguration & Dotfiles (Deep-Dive & GNU Stow)
- **Verifiziert 2026-10-18 via `quickshell --help`:** Quickshell sucht seine "default"-Konfiguration exakt unter `$XDG_CONFIG_HOME/quickshell/shell.qml` (also `~/.config/quickshell/shell.qml`, sofern `XDG_CONFIG_HOME` nicht anders gesetzt ist). Fehlermeldung ohne diese Datei: `Could not find "default" config directory or shell.qml in any valid config path.`
- **Manuelle Dateistruktur für GNU Stow (von dir anzulegen):** `dotfiles/quickshell/.config/quickshell/shell.qml` → wird über `stow` nach `~/.config/quickshell/shell.qml` verlinkt.
- **Konfigurations-Block (Minimal-Startvorlage — nur eine Uhr, zum Verifizieren, dass Quickshell grundsätzlich läuft; Statusbar-Inhalte wie Workspaces/Tray/Audio folgen in einem eigenen späteren Ricing-Schritt):**
  ```qml
  import Quickshell   // Stellt die Quickshell-eigenen QML-Typen bereit (ShellRoot, PanelWindow, ...)
  import QtQuick      // Stellt die Qt-Basis-Typen bereit (Text, Timer, ...)

  // ShellRoot ist der Wurzel-Knoten jeder Quickshell-Konfiguration — vergleichbar
  // mit "ApplicationWindow" in normalen Qt-Apps, nur dass hier mehrere eigenständige
  // Fenster (PanelWindows) als Kinder existieren können.
  ShellRoot {

      // PanelWindow erzeugt ein Fenster über das Wayland-Protokoll "wlr-layer-shell"
      // (das gleiche Protokoll, das auch mako für seine Benachrichtigungs-Overlays nutzt,
      // siehe 02-mako.md) — es "klebt" an einer Bildschirmkante, statt ein normales,
      // verschiebbares Fenster zu sein, und Hyprland reserviert dafür automatisch Platz.
      PanelWindow {
          anchors {
              top:   true   // An der oberen Bildschirmkante andocken
              left:  true   // ... über die volle Breite ...
              right: true   // ... bis zur rechten Kante.
          }
          implicitHeight: 32      // Höhe der Bar in Pixeln
          color: "#1e1e2e"        // Hintergrundfarbe (Platzhalter-Dark-Theme, später anpassbar)

          Text {
              id: clockText
              anchors.centerIn: parent
              color: "#ffffff"
              font.pixelSize: 16
              // Erstbefüllung beim Start, bevor der Timer das erste Mal auslöst:
              text: Qt.formatDateTime(new Date(), "ddd, dd.MM.yyyy hh:mm:ss")
          }

          // Qt bringt keinen "lebenden" Uhr-Typ ohne Weiteres mit — ein Timer,
          // der die Textanzeige jede Sekunde neu berechnet, ist der einfachste,
          // von Quickshell-Version unabhängige Weg.
          Timer {
              interval: 1000   // Millisekunden
              running: true
              repeat: true
              onTriggered: clockText.text = Qt.formatDateTime(new Date(), "ddd, dd.MM.yyyy hh:mm:ss")
          }
      }
  }
  ```
- **Detail-Erklärung (Was/Warum/Nutzen):**
  - `ShellRoot`/`PanelWindow`: Quickshell-eigene Typen, siehe Kommentare im Code-Block oben — kein normales Anwendungsfenster, sondern ein Layer-Shell-Overlay, das Hyprland als festen Bar-Bereich behandelt (Fenster werden automatisch darunter angeordnet, nicht darüber gelegt).
  - `anchors { top/left/right: true }` + `implicitHeight`: Ergibt eine klassische, volle Breite einnehmende Top-Bar — das Standardmuster für Statusbars in Wayland-Compositors.
  - **Warum nur eine Uhr zum Start?** Minimal-Test-Vorlage nach dem Prinzip "kleinster lauffähiger Schritt" — bestätigt, dass Quickshell grundsätzlich mit Hyprland zusammenspielt, bevor wir Komplexität (Workspace-Indikator, System-Tray, Lautstärke/Akku via `wpctl`/`upower`) hinzufügen.
- **Maschinen-Spezifische Werte:** Keine in dieser Minimal-Version — bei Erweiterung um Monitor-spezifische Platzierung (z. B. bei mehreren Monitoren) wird das hier ergänzt.
- **Stow-Befehl:** `stow -v -t ~ quickshell` (ausgeführt aus dem `dotfiles/`-Verzeichnis). **Wichtig:** `-t ~` (target) ist zwingend explizit nötig, da Stow ohne diese Angabe standardmäßig in das *Elternverzeichnis von `dotfiles/`* verlinkt (hier `~/arch-linux-laptop/`), **nicht** nach `~/` — siehe [how-to-use-git-and-stow.md](../00-base-system/how-to-use-git-and-stow.md), Abschnitt 6, und der Troubleshooting-Eintrag unten. `-v` (verbose) zeigt dir, welche Symlinks tatsächlich angelegt werden, zur Kontrolle.

## 6. Ricing, Theming & Desktop-Integration
- **Zentrales Ricing-Werkzeug dieses Setups** — Statusbar, ggf. Notification-Overlay (als Alternative/Ergänzung zu `mako`) und weitere Widgets werden hier in eigenen Schritten aufgebaut, sobald Hyprland läuft.

## 7. Systemd, Autostart & Automatisierung
- **Hyprland-Autostart:** Wird wie `mako` über `exec-once = quickshell` in `hyprland.conf` gestartet (gleiche Begründung: Abhängigkeit von der laufenden Wayland-Session).

## 8. Dateisystem (z. B. Btrfs), Netzwerk & Sicherheit
- *Nicht zutreffend / Keine Einträge*

## 9. Verifizierung, Diagnose & Cheatsheet
- `quickshell --version` — installierte Version prüfen.
- **Verifiziert 2026-10-18:** Nach Behebung des Parse-Fehlers (siehe Abschnitt 10) lädt `quickshell` die Konfiguration fehlerfrei (`INFO: Configuration Loaded`) und zeigt die Minimal-Bar mit laufender Uhr sichtbar auf dem Bildschirm an. Autostart über den Lua-Hook `hl.on("hyprland.start", ...)` in `~/.config/hypr/hyprland.lua` ist eingerichtet.
- **Diagnose bei zukünftigen Problemen:** `quickshell` **immer zuerst manuell im Terminal** (innerhalb der laufenden Hyprland-Session) starten, nicht nur über den Autostart — nur so sieht man die Klartext-Fehlermeldung des Parsers/der Config direkt auf stdout/stderr. Log-Datei zusätzlich unter `/run/user/1000/quickshell/by-id/<id>/log.qslog`.

## 10. Troubleshooting & Fehler-Historie (Lern-Protokoll)

### [2026-10-18] - `shell.qml` an falscher Stelle im Stow-Paket abgelegt
- **Symptom:** `quickshell` meldete `Could not find "default" config directory or shell.qml in any valid config path.`, obwohl die Datei bereits angelegt war.
- **Technische Ursache:** Die Datei landete bei der manuellen Anlage auf `dotfiles/quickshell/shell.qml` (direkt im Paket-Root) statt auf `dotfiles/quickshell/.config/quickshell/shell.qml` — der leere `.config/quickshell/`-Unterordner blieb entsprechend leer.
- **Finale Lösung:** Datei per `mv` an die korrekte, verschachtelte Stelle verschoben (siehe Abschnitt 5 für die korrekte Struktur).

### [2026-10-18] - `stow` ohne `-t ~` verlinkt ins Repo-Root statt nach `$HOME`
- **Symptom / Fehlermeldung:** Nach `cd ~/arch-linux-laptop/dotfiles && stow -v quickshell` fehlte `~/.config/quickshell` weiterhin (`ls` → "Datei oder Verzeichnis nicht gefunden"), obwohl `stow` zuvor scheinbar erfolgreich verlinkt hatte.
- **Technische Ursache (Root Cause):** GNU Stow nutzt **standardmäßig das Elternverzeichnis des aktuellen Ordners als Ziel** — hier also `~/arch-linux-laptop/` (das Elternverzeichnis von `dotfiles/`), nicht `~/`. `ls -la ~/arch-linux-laptop/` zeigte tatsächlich zwei fälschlich dort erzeugte Symlinks: `.config -> dotfiles/quickshell/.config` und `shell.qml -> dotfiles/quickshell/shell.qml`.
- **Gescheiterte Ansätze & Lerneffekt:** Der KI-Assistent hatte den Befehl ohne `-t ~` vorgegeben — entgegen der bereits bestehenden, korrekten Dokumentation in [how-to-use-git-and-stow.md](../00-base-system/how-to-use-git-and-stow.md), Abschnitt 6, die dieses exakte Problem bereits beschreibt. **Lerneffekt:** Etablierte Projekt-Dokumentation vor jedem Befehl gegenprüfen, nicht aus dem Gedächtnis improvisieren — besonders bei projektspezifischen Konventionen, die bereits an anderer Stelle im Repo fixiert sind.
- **Finale Lösung:** `stow -D quickshell` (ohne `-t`, um exakt die fälschlich erzeugten Links wieder zu entfernen) gefolgt von `stow -v -t ~ quickshell` (mit explizitem Target). Verifiziert: `LINK: .config/quickshell => ../arch-linux-laptop/dotfiles/quickshell/.config/quickshell`.

### [2026-10-18] - `quickshell`-Autostart crasht beim Hyprland-Start (Qt-Fatal-Error), erst beim manuellen Start sichtbarer Parse-Fehler
- **Symptom / Fehlermeldung:** `quickshell` lief nach dem Hyprland-Start nicht (kein Prozess in `ps`), stattdessen fanden sich mehrere `systemd-coredump`-Einträge für `quickshell` im Journal (Absturz in `QGuiApplicationPrivate::createPlatformIntegration`). Der Coredump-Stacktrace zeigt nur die Absturzstelle, nicht die eigentliche Fehlermeldung. Erst der **manuelle** Start via `quickshell` im Terminal (innerhalb der laufenden Hyprland-Session) lieferte die echte Fehlermeldung auf stdout/stderr:
  ```
  ERROR: Failed to load configuration
  ERROR:   caused by @shell.qml[2:3]: Expected token `{'
  ```
- **Technische Ursache (Root Cause):** In `dotfiles/quickshell/.config/quickshell/shell.qml` stand in **Zeile 1** nur das Wort `qml` — der Sprach-Tag des Markdown-Codeblocks (` ```qml `) aus Abschnitt 5 dieser Doku, der beim manuellen Kopieren versehentlich mit übernommen wurde, während die Backticks selbst wegfielen. QML verlangt, dass `import`-Statements die allerersten Token der Datei sind; durch die zusätzliche Zeile 1 landete `import Quickshell` in Zeile 2 an ungültiger Position, worauf der Parser abbrach.
- **Gescheiterte Ansätze & Lerneffekt:** Der Qt-Fatal-Crash beim Autostart (ohne sichtbare Fehlermeldung im Journal) ist eine Sackgasse, wenn man dort nach der Ursache sucht — Autostart-Prozesse von Hyprland aus haben keinen eigenen, leicht einsehbaren stdout/stderr-Stream. **Lerneffekt:** Bei unklaren Abstürzen von GUI-/Autostart-Programmen immer zuerst **manuell im Terminal starten**, um die Klartext-Fehlerausgabe des Programms direkt zu sehen, statt im System-Journal nach Hinweisen zu suchen. Zusätzlicher Lerneffekt: Beim Kopieren von Code aus Markdown-Codeblöcken in echte Dateien die erste und letzte Zeile (Backtick-Zäune inkl. Sprach-Tag) besonders sorgfältig prüfen.
- **Finale Lösung:** Zeile 1 (`qml`) in `shell.qml` manuell entfernt, sodass die Datei korrekt mit `import Quickshell` beginnt.

## 11. Wartung, Updates & Rollback (Saubere Deinstallation)
- **Vollständiger Rollback:** `exec-once`-Zeile aus `hyprland.conf` entfernen, danach `sudo pacman -Rns quickshell`.
