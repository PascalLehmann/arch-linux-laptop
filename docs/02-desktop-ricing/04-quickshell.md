# Quickshell (Desktop-Shell-Toolkit)

- **Maschine / Hostname:** thinkpad
- **Kategorie:** 02-Ricing
- **Status:** In Einrichtung
- **Letztes Update:** 2026-10-18
- **Verwandte Dokumentation:** [01-hyprland.md](01-hyprland.md), [06-statusbar-akku.md](06-statusbar-akku.md), [07-statusbar-powerbutton.md](07-statusbar-powerbutton.md), [README.md](../../README.md)

---

## 1. Übersicht, Architektur & Zweck
- **Was ist das?** `Quickshell` ist kein fertiges Produkt (wie z. B. Waybar), sondern ein **Toolkit** zum Selberbauen von Desktop-Shell-Komponenten (Statusbar, Widgets, Benachrichtigungs-Overlays, Lock-Screens) mittels **QtQuick/QML** — derselben deklarativen UI-Beschreibungssprache, die auch SDDM für seinen Greeter nutzt (siehe [01-hyprland.md](01-hyprland.md), Abschnitt 1). Im Gegensatz zu Waybar (fertige Statusbar, nur über JSON-Konfiguration anpassbar) erlaubt Quickshell freie, programmierbare Gestaltung.
- **Warum nutzen wir es auf dieser Maschine?** Deutlich mehr gestalterische Freiheit für das Ricing-Ziel dieses Projekts als eine vorgefertigte Statusbar — Kompromiss: höherer Einarbeitungs-/Konfigurationsaufwand, da im Grunde eigener QML-Code geschrieben wird (oder eine fertige Quickshell-Konfiguration wie `dms-shell`, die wir **nicht** installiert haben, als Referenz studiert wird).
- **Offizielle Referenzen:**
  - [Quickshell-Dokumentation](https://quickshell.org/) (Domain seit 2026-10-18 umgezogen; `quickshell.outfoxxed.me` leitet per `301` dorthin weiter)
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
- **Konfigurations-Block (Multi-Monitor-fähige Minimal-Vorlage, korrigiert 2026-10-18 — siehe Troubleshooting Abschnitt 10):**
  ```qml
  import Quickshell   // Stellt die Quickshell-eigenen QML-Typen bereit (ShellRoot, PanelWindow, Variants, ...)
  import QtQuick      // Stellt die Qt-Basis-Typen bereit (Text, Timer, ...)

  // ShellRoot ist der Wurzel-Knoten jeder Quickshell-Konfiguration — vergleichbar
  // mit "ApplicationWindow" in normalen Qt-Apps, nur dass hier mehrere eigenständige
  // Fenster (PanelWindows) als Kinder existieren können.
  ShellRoot {

      // Variants erzeugt/zerstört eine Delegate-Instanz pro Eintrag in "model" —
      // ähnlich einem Repeater, aber für Nicht-Item-Objekte wie PanelWindow.
      // Quickshell.screens ist eine live aktualisierte Liste aller aktuell
      // angeschlossenen Bildschirme: Hängst du einen Monitor an/ab, legt Variants
      // automatisch eine neue PanelWindow an bzw. zerstört die bestehende.
      Variants {
          model: Quickshell.screens

          // Der Delegate braucht eine "modelData"-Property, die Variants pro
          // Instanz mit dem jeweiligen Listen-Eintrag (hier: einem ShellScreen) befüllt.
          PanelWindow {
              id: panel
              required property var modelData

              // screen ist eine Property von QsWindow (Basistyp von PanelWindow) und
              // legt fest, auf welchem Bildschirm genau DIESE Fenster-Instanz erscheint.
              // Ohne diese Zeile würde Quickshell nur einen einzigen Default-Bildschirm
              // bespielen, egal wie viele Monitore angeschlossen sind.
              screen: modelData

              // PanelWindow erzeugt ein Fenster über das Wayland-Protokoll "wlr-layer-shell"
              // (das gleiche Protokoll, das auch mako für seine Benachrichtigungs-Overlays nutzt,
              // siehe 02-mako.md) — es "klebt" an einer Bildschirmkante, statt ein normales,
              // verschiebbares Fenster zu sein, und Hyprland reserviert dafür automatisch Platz.
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
  }
  ```
- **Detail-Erklärung (Was/Warum/Nutzen):**
  - `ShellRoot`/`PanelWindow`: Quickshell-eigene Typen, siehe Kommentare im Code-Block oben — kein normales Anwendungsfenster, sondern ein Layer-Shell-Overlay, das Hyprland als festen Bar-Bereich behandelt (Fenster werden automatisch darunter angeordnet, nicht darüber gelegt).
  - `Variants { model: Quickshell.screens }`: Erzeugt dynamisch eine `PanelWindow`-Instanz pro aktuell angeschlossenem Monitor, statt (wie in der ursprünglichen Minimal-Version) nur ein einziges, fest "irgendwo" platziertes Fenster. Reagiert automatisch auf Hot-Plugging (externen Monitor an-/abstecken), ohne dass Quickshell neu gestartet werden muss.
  - `required property var modelData`: Pflicht-Property, über die `Variants` dem Delegate mitteilt, für welchen konkreten `ShellScreen`-Eintrag diese Instanz gerade erzeugt wird. `required` erzwingt zur Compile-Zeit, dass dieser Wert auch tatsächlich gesetzt wird.
  - `screen: modelData`: Bindet die jeweilige `PanelWindow`-Instanz an genau ihren zugehörigen Bildschirm — **das** fehlende Puzzlestück, das in der ursprünglichen Version zum Bar-auf-externem-Monitor-Problem führte (siehe Troubleshooting Abschnitt 10).
  - `anchors { top/left/right: true }` + `implicitHeight`: Ergibt eine klassische, volle Breite einnehmende Top-Bar — das Standardmuster für Statusbars in Wayland-Compositors, jetzt auf jedem Monitor einzeln angewendet.
  - **Warum weiterhin nur eine Uhr?** *(Historisch — überholt seit dem 3-Zonen-Umbau unten.)* War bis hierhin Minimal-Vorlage nach dem Prinzip "kleinster lauffähiger Schritt", jetzt erweitert um ein echtes Links/Mitte/Rechts-Layout, in das weitere Module (Akku, Power-Button, später Workspace-Indikator, System-Tray) einsortiert werden.

- **Erweiterung 2026-10-18 — 3-Zonen-Modul-Layout (Links/Mitte/Rechts):**
  - **Konzept:** Statt eines einzelnen zentrierten `Text`-Elements bekommt jede `PanelWindow` jetzt drei unabhängige `Row`-Container (`leftSection`, `centerSection`, `rightSection`), die jeweils an einer Kante (links/rechts) bzw. mittig in der Bar verankert sind. Ein `Row` ordnet beliebig viele Kind-Elemente automatisch nebeneinander an (mit festem `spacing` dazwischen) und berechnet seine eigene Breite aus der Summe der Kind-Breiten — genau das Verhalten, das man braucht, um später Module (Akku-Icon, Power-Button, weitere Icons) einfach als zusätzliche Kinder in die gewünschte Zone einzuhängen, ohne jedes Mal Koordinaten neu auszurechnen.
  - **Warum dieser Schritt zuerst, bevor Akku/Power-Button dazukommen?** Ohne diese Grundstruktur müsste jedes neue Icon einzeln mit exakten `anchors`/Pixel-Offsets positioniert werden — bei mehreren Icons nebeneinander (z. B. Akku + Power-Button rechts) wird das schnell unübersichtlich und bricht bei jeder Änderung der Icon-Reihenfolge. Die 3 Zonen sind außerdem die Grundlage für das später geplante GUI-Panel zur freien Modul-Platzierung (siehe [06-statusbar-akku.md](06-statusbar-akku.md) und [07-statusbar-powerbutton.md](07-statusbar-powerbutton.md)): Ein Modul "gehört" dann einfach zu `leftSection`, `centerSection` oder `rightSection`.
  - **Code (ersetzt den bisherigen Inhalt der `PanelWindow` aus der Minimal-Vorlage oben):**
    ```qml
    import Quickshell
    import QtQuick

    ShellRoot {
        Variants {
            model: Quickshell.screens

            PanelWindow {
                id: panel
                required property var modelData
                screen: modelData

                anchors {
                    top:   true
                    left:  true
                    right: true
                }
                implicitHeight: 32
                color: "#1e1e2e"

                // Linke Zone: an der linken Bar-Kante verankert, wächst nach rechts.
                // Aktuell noch leer — Platzhalter für künftige Module (z. B. Workspace-Indikator).
                Row {
                    id: leftSection
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12
                }

                // Mittlere Zone: exakt auf der Bar zentriert (horizontal UND vertikal).
                // Übernimmt die bisherige Uhr unverändert.
                Row {
                    id: centerSection
                    anchors.centerIn: parent
                    spacing: 12

                    Text {
                        id: clockText
                        color: "#ffffff"
                        font.pixelSize: 16
                        text: Qt.formatDateTime(new Date(), "ddd, dd.MM.yyyy hh:mm:ss")
                    }
                }

                // Rechte Zone: an der rechten Bar-Kante verankert, wächst nach links.
                // Hier ziehen in den nächsten Schritten Akku-Anzeige und Power-Button ein.
                Row {
                    id: rightSection
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12
                }

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: clockText.text = Qt.formatDateTime(new Date(), "ddd, dd.MM.yyyy hh:mm:ss")
                }
            }
        }
    }
    ```
  - **Detail-Erklärung (Was/Warum/Nutzen):**
    - `Row { anchors.left/right: parent.left/right; anchors.verticalCenter: parent.verticalCenter }`: Verankert den Container an genau einer Kante der Bar (nicht an beiden wie die bisherige volle-Breite-Bar selbst) und zentriert ihn nur vertikal — die Zone wächst/schrumpft also automatisch in der Breite, je nachdem wie viele/große Kind-Elemente sie aktuell enthält, bleibt aber immer an derselben Kante "festgeklebt".
    - `anchors.leftMargin` / `anchors.rightMargin: 12`: Kleiner Sicherheitsabstand zur Bildschirmkante, rein optisch (sonst würden Icons direkt an der Ecke kleben).
    - `spacing: 12` (im `Row`): Fester Abstand zwischen den künftigen Kind-Elementen einer Zone — vergleichbar mit `gap`/`column-gap` in CSS-Flexbox. Sorgt dafür, dass z. B. Akku-Icon und Power-Button in der rechten Zone nicht aneinanderkleben, ohne dass man bei jedem neuen Modul manuell `anchors.leftMargin` am Nachbar-Element nachjustieren muss.
    - **Reihenfolge bei mehreren Kindern in einer Zone:** Ein `Row` ordnet seine Kinder standardmäßig in Deklarationsreihenfolge von links nach rechts an (`layoutDirection: Qt.LeftToRight`, Default). Bei der *rechten* Zone bedeutet das konkret: Das zuletzt hinzugefügte Kind-Element landet am nächsten zur rechten Bildschirmkante, frühere Kinder rutschen nach links. Wichtig zu wissen, wenn in den nächsten Schritten entschieden wird, ob der Power-Button links oder rechts vom Akku-Icon sitzen soll — die Deklarationsreihenfolge im Code bestimmt das direkt.
  - **Maschinen-Spezifische Werte:** Keine — Zonen-Namen/Margins/Spacing sind reine Gestaltungs-Konstanten, 1:1 auf jedes andere Maschinen-Repo übertragbar.
- **Maschinen-Spezifische Werte:** Keine hartkodierten Monitor-Namen/Auflösungen in dieser Vorlage — die `Variants`/`Quickshell.screens`-Kombination ist bewusst generisch gehalten, damit sie unabhängig von der konkreten Monitor-Anzahl/-Bezeichnung dieser Maschine funktioniert und 1:1 in ein anderes Maschinen-Repo übernommen werden kann.
- **Stow-Befehl:** `stow -v -t ~ quickshell` (ausgeführt aus dem `dotfiles/`-Verzeichnis). **Wichtig:** `-t ~` (target) ist zwingend explizit nötig, da Stow ohne diese Angabe standardmäßig in das *Elternverzeichnis von `dotfiles/`* verlinkt (hier `~/arch-linux-laptop/`), **nicht** nach `~/` — siehe [how-to-use-git-and-stow.md](../00-base-system/how-to-use-git-and-stow.md), Abschnitt 6, und der Troubleshooting-Eintrag unten. `-v` (verbose) zeigt dir, welche Symlinks tatsächlich angelegt werden, zur Kontrolle.

## 6. Ricing, Theming & Desktop-Integration
- **Zentrales Ricing-Werkzeug dieses Setups** — Statusbar, ggf. Notification-Overlay (als Alternative/Ergänzung zu `mako`) und weitere Widgets werden hier in eigenen Schritten aufgebaut, sobald Hyprland läuft.

## 7. Systemd, Autostart & Automatisierung
- **Hyprland-Autostart:** Wird wie `mako` über `exec-once = quickshell` in `hyprland.conf` gestartet (gleiche Begründung: Abhängigkeit von der laufenden Wayland-Session).

## 8. Dateisystem (z. B. Btrfs), Netzwerk & Sicherheit
- *Nicht zutreffend / Keine Einträge*

## 9. Verifizierung, Diagnose & Cheatsheet
- `quickshell --version` — installierte Version prüfen.
- **Verifiziert 2026-10-18:** Nach Behebung des Parse-Fehlers (siehe Abschnitt 10) lädt `quickshell` die Konfiguration fehlerfrei (`INFO: Configuration Loaded`) und zeigt die Minimal-Bar mit laufender Uhr sichtbar auf dem Bildschirm an. Autostart über den Lua-Hook `hl.on("hyprland.start", ...)` in `~/.config/hypr/hyprland.lua` ist eingerichtet und läuft seit dem Boot stabil (siehe Prozess-Diagnose Troubleshooting Abschnitt 10).
- **Multi-Monitor-Verifizierung (2026-10-18, nach Anschluss des externen Monitors):** Mit der um `Variants`/`Quickshell.screens` erweiterten Konfiguration (Abschnitt 5) erscheint die Bar bestätigt auf **beiden** Bildschirmen (`eDP-1` intern und `HDMI-A-1` extern) gleichzeitig.
- **Verifiziert 2026-10-18 (3-Zonen-Layout):** Nach dem Umbau auf `leftSection`/`centerSection`/`rightSection` (Abschnitt 5) erscheint die Uhr weiterhin korrekt mittig — keine optische Regression durch den Architektur-Wechsel. `rightSection` enthält inzwischen die Akku-Anzeige (siehe [06-statusbar-akku.md](06-statusbar-akku.md)); `leftSection` ist aktuell noch ungenutzt.
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

### [2026-10-18] - Bar erscheint nur auf dem internen Panel, nicht auf dem externen Monitor
- **Symptom / Befund:** Nach Anschluss des externen Monitors lief Quickshell laut `ps aux` (PID seit Boot stabil, keine Coredumps, keine Journal-Fehler für den aktuellen Boot) durchgehend fehlerfrei — die Bar war aber ausschließlich auf dem internen `eDP-1`-Panel sichtbar, nicht auf `HDMI-A-1`. Ursprüngliche Fehlannahme während der Diagnose: ein Crash oder ein Autostart-Timing-/Race-Problem (ähnlich dem bereits dokumentierten Vorfall direkt oben) — beides wurde durch `journalctl`/`coredumpctl` widerlegt (keine neuen Einträge im aktuellen Boot).
- **Technische Ursache (Root Cause):** Die ursprüngliche Minimal-`shell.qml` (Abschnitt 5) deklarierte nur eine einzige `PanelWindow` **ohne** gesetzte `screen`-Property. Live-Recherche in der Quickshell-Dokumentation (Version `0.3.2`, siehe Abschnitt 1) bestätigte: `screen` (Typ `ShellScreen`, geerbt vom Basistyp `QsWindow`) legt fest, auf welchem Monitor ein Fenster erscheint — ohne explizite Zuweisung verwendet Quickshell nur einen einzigen Default-Bildschirm. Als nur ein Monitor existierte, fiel das nicht auf; mit zwei Monitoren zeigte sich die Lücke sofort.
- **Gescheiterte Ansätze & Lerneffekt:** Die ersten beiden Diagnoseschritte (Crash-Suche via `coredumpctl`, Timing-Hypothese zum `hyprland.start`-Hook) waren beide plausible, aber falsche erste Spuren — der Prozess lief ja nachweislich einwandfrei. **Lerneffekt:** Bei "Feature fehlt auf einem von mehreren Monitoren" zuerst die Konfigurationslogik auf Monitor-Bezug prüfen, bevor man Crash-/Timing-Diagnosen vertieft — ein laufender, fehlerfreier Prozess kann trotzdem "falsch" konfiguriert sein.
- **Finale Lösung:** `shell.qml` um `Variants { model: Quickshell.screens }` erweitert, das pro angeschlossenem Bildschirm automatisch eine eigene `PanelWindow`-Instanz mit `screen: modelData` erzeugt (vollständiger korrigierter Code-Block siehe Abschnitt 5).

## 11. Wartung, Updates & Rollback (Saubere Deinstallation)
- **Vollständiger Rollback:** `exec-once`-Zeile aus `hyprland.conf` entfernen, danach `sudo pacman -Rns quickshell`.
