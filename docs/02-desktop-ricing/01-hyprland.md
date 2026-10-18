# Hyprland (Wayland-Compositor)

- **Maschine / Hostname:** thinkpad
- **Kategorie:** 02-Ricing
- **Status:** In Einrichtung
- **Letztes Update:** 2026-10-18
- **Verwandte Dokumentation:** [nvidia-prime-hybrid-grafik.md](../01-drivers-hardware/nvidia-prime-hybrid-grafik.md), [README.md](../../README.md)

---

## 1. Übersicht, Architektur & Zweck
- **Was ist das?** Hyprland ist ein eigenständiger, dynamisch kachelnder (*dynamic tiling*) Wayland-Compositor. Anders als bei klassischen Desktop-Umgebungen (GNOME, KDE) oder dem alten X11-Modell (X-Server + separater Window-Manager) übernimmt Hyprland als ein einziger Prozess sowohl die Rolle des Display-Servers (Umsetzung des Wayland-Protokolls) als auch die des Fenster-/Layout-Managers. Er kommuniziert direkt mit dem Kernel-**DRM/KMS**-Subsystem (*Direct Rendering Manager* / *Kernel Mode Setting*) für Bildausgabe und GPU-Puffer-Verwaltung sowie über **libinput** mit Tastatur/Touchpad. Für klassische X11-Anwendungen (die kein natives Wayland sprechen) läuft bei Bedarf **XWayland** als Kompatibilitätsschicht mit.
- **Warum nutzen wir es auf dieser Maschine?** Wir verlassen damit die reine TTY-Textkonsole und bekommen erstmals eine grafische Oberfläche. Hyprland ist performant, stark animierbar/anpassbar (klassisches "Ricing"-Ziel) und unterstützt moderne Compositor-Features (Blur, Animationen, Tiling) nativ über Wayland statt über X11-Kompatibilitätshacks.
  - **Besonderheit unserer Hardware:** Muxlose Hybrid-Grafik (siehe [nvidia-prime-hybrid-grafik.md](../01-drivers-hardware/nvidia-prime-hybrid-grafik.md), Abschnitt 2) — das interne eDP-Panel hängt fest an der Intel-iGPU, die NVIDIA-dGPU hat keinen eigenen Display-Ausgang. Hyprland muss daher die iGPU als primäre Render-/Anzeige-GPU verwenden; die dGPU bleibt nur für PRIME-Render-Offload einzelner Prozesse (`prime-run ...`) relevant. Das ist ein bekannter Spezialfall bei Wayland-Compositors auf NVIDIA-Optimus-Systemen und erfordert ggf. zusätzliche Umgebungsvariablen/Konfiguration (wird in Abschnitt 4/5 live verifiziert, sobald wir dort stehen).
- **Architektur-Entscheidung — Session-Start (2026-10-18):** Wir verlassen damit erstmals den reinen TTY-Login-Ansatz der bisherigen Einrichtung. Entschieden wurde ein **Display-/Login-Manager (SDDM — Simple Desktop Display Manager)** statt eines manuellen Starts per TTY-Login + Befehl. SDDM läuft als eigener systemd-Service (`sddm.service`), zeigt nach dem Boot einen grafischen Login-Bildschirm und startet darüber die gewählte Session (hier: Hyprland, über eine `.desktop`-Session-Datei, die vom `hyprland`-Paket mitgeliefert wird). Vorteil: saubere Trennung zwischen Login-Vorgang und Compositor-Start, Benutzerauswahl/Autologin-Option, kein manuelles `exec`/Shell-Scripting für den Session-Start nötig.
- **Offizielle Referenzen:**
  - [Hyprland Wiki](https://wiki.hyprland.org/)
  - [Arch Wiki: Hyprland](https://wiki.archlinux.org/title/Hyprland)
  - [Hyprland GitHub-Repository](https://github.com/hyprwm/Hyprland)
  - `man hyprland`, `man hyprland.conf` (nach Installation verfügbar)

## 2. Abhängigkeiten & System-Voraussetzungen
- **Pflicht-Pakete (live verifiziert 2026-10-18 via `pacman -Ss`):**
  - `hyprland` (`extra`, 0.56.2-4): Der Compositor selbst.
  - `xdg-desktop-portal-hyprland` (`extra`, 1.4.1-2): Hyprland-spezifische Implementierung der Desktop-Portale (Datei-Öffnen-Dialoge, Screen-Sharing, etc. für sandboxed/Flatpak-ähnliche Apps). Zieht `xdg-desktop-portal` (`extra`, 1.22.1-2, das generische Portal-Framework) automatisch als Abhängigkeit mit.
  - `sddm` (`extra`, 0.21.0-7): Der in Abschnitt 1 festgelegte Login-Manager (laut Paketbeschreibung "QML based X11 **and Wayland** display manager" — unterstützt also nativ Wayland-Sessions wie Hyprland, nicht nur X11).
- **Zusätzlich jetzt mitinstalliert (2026-10-18, auf deinen Wunsch vorgezogen):**
  - `hyprpolkitagent` (`extra`, 0.2.0-1): Polkit-Authentifizierungs-Agent — nötig, damit grafische Programme (z. B. `system-config-printer`, siehe [03-cups-druckerverwaltung.md](../05-system-services/03-cups-druckerverwaltung.md)) Admin-Rechte über einen Passwort-**Dialog** statt über ein Terminal abfragen können. **Technischer Hintergrund:** Polkit (*PolicyKit*) selbst ist nur der Kernel-/D-Bus-seitige Mechanismus zur Autorisierungs-Entscheidung — er braucht aber zwingend einen laufenden **Authentication Agent**, der die eigentliche Passwort-Abfrage grafisch darstellt. Ohne diesen Agent würden privilegierte Aktionen aus GUI-Programmen schlicht fehlschlagen, ohne dass der User überhaupt zur Passworteingabe aufgefordert wird. Start erfolgt wie bei `mako`/`quickshell` über `exec-once` in `hyprland.conf` (siehe Abschnitt 7).
  - `wl-clipboard` (`extra`, 1:2.3.0-1): Stellt die CLI-Werkzeuge `wl-copy`/`wl-paste` für die Wayland-Zwischenablage bereit (das Wayland-Zwischenablage-Protokoll kennt kein zentrales "Clipboard-Manager"-Programm wie X11 — jede Anwendung muss das `wlr-data-control`-Protokoll direkt ansprechen; `wl-clipboard` macht das aus Skripten/der Kommandozeile heraus nutzbar, z. B. für Screenshot-Pipelines oder Copy-Paste-Keybindings).
- **Optionale Pakete (`optdepends`) — bewusst noch NICHT installiert, erst im Ricing-/Autostart-Schritt (Abschnitt 6/7):**
  - `hypridle` / `hyprlock`: Idle-Daemon bzw. GPU-beschleunigter Screen-Locker. Für den ersten funktionalen Test der Session nicht erforderlich.
  - `hyprpaper`: Wallpaper-Daemon — rein kosmetisch, gehört ins Ricing-Kapitel.
  - `hyprshot`: Screenshot-Werkzeug — praktisch, aber kein Blocker für die erste lauffähige Session.
  - `nwg-panel` / `nwg-dock-hyprland`: Statusbar/Dock-Alternativen — mit der Entscheidung für `quickshell` (siehe [04-quickshell.md](04-quickshell.md)) voraussichtlich nicht mehr benötigt.
- **Hardware- & System-Voraussetzungen:**
  - NVIDIA-Treiber-Grundlage bereits vorhanden: `nvidia-drm.modeset=1` aktiv, `nvidia-open`-Kernelmodul lädt (siehe NVIDIA-Doku, Status *aktiv*, PRIME-Offload-Funktionstest aktuell **zurückgestellt**).
  - Intel-iGPU-Treiber (`i915`) lädt bereits als Standard-Kernelmodul (siehe README, Hardware-Profil).
  - Wayland-Session-Grundlagen (`wayland-protocols`, `xdg-desktop-portal`-Implementierung für Screen-Sharing/Dateidialoge etc.) — Details folgen bei der Paket-Verifizierung.

## 3. Installation & Flag-Erklärung

**Schritt 1 — Compositor, Portal und Login-Manager:**
```bash
sudo pacman -S --needed hyprland xdg-desktop-portal-hyprland sddm
```
- **Aufschlüsselung der Parameter:** `-S` (Sync — installiert Pakete aus den synchronisierten Repository-Datenbanken), `--needed` (überspringt Pakete, die in exakt dieser Version bereits installiert sind, statt sie neu zu entpacken — identische Bedeutung wie bereits im [Git/Stow-Guide](../00-base-system/how-to-use-git-and-stow.md) und in der NVIDIA-Doku erklärt).
- **Ergebnis (verifiziert 2026-10-18):** Installation fehlerfrei durchgelaufen (64 Pakete insgesamt inkl. Abhängigkeiten, ~103 MiB Download, keine Dateikonflikte, keine `.pacnew`-Hinweise). Bemerkenswerte mitinstallierte Abhängigkeiten:
  - `aquamarine`: Hyprlands eigene Rendering-/Backend-Bibliothek (Nachfolger des ursprünglich genutzten `wlroots`-Ansatzes) — übernimmt die direkte DRM/KMS- und `libinput`-Kommunikation.
  - `seatd` + neue Systemgruppe `seat` (GID 967): *Seat-Management-Daemon* — verwaltet, welcher (angemeldete) Benutzer aktuell exklusiven Zugriff auf Eingabegeräte/GPU hat. Notwendig, damit Hyprland als normaler User (ohne root) auf `/dev/input/*` und die DRM-Devices zugreifen darf.
  - `xorg-xwayland`: XWayland-Kompatibilitätsschicht für klassische X11-Anwendungen innerhalb der Wayland-Session.
  - `qt6-base`/`qt6-declarative`: Benötigt für SDDMs QML-basierten Greeter (Login-Bildschirm).
  - Neuer Systembenutzer `sddm` (UID/GID 966, Gruppe `sddm`): Dedizierter, unprivilegierter Account, unter dem der SDDM-Greeter-Prozess läuft (Sicherheitsprinzip: Login-Bildschirm läuft nicht als root).
  - **Nicht installierte, aber für später relevante `optdepends`:** `grim`/`slurp` (werden von `xdg-desktop-portal-hyprland` für den Screenshot-Portal-Mechanismus benötigt — nachinstallieren, sobald Screenshots/Screen-Sharing gebraucht werden).

**Schritt 2 — Basis-Werkzeuge für eine nutzbare Session (2026-10-18, auf deinen Wunsch vorgezogen, bevor der erste Login-Test erfolgt):**
```bash
sudo pacman -S --needed hyprpolkitagent kitty ghostty mako hyprlauncher dolphin quickshell wl-clipboard
```
- **Paketliste im Detail:** siehe jeweils [02-mako.md](02-mako.md), [03-hyprlauncher.md](03-hyprlauncher.md), [04-quickshell.md](04-quickshell.md), [02-terminal-emulator.md](../03-cli-tools/02-terminal-emulator.md), [01-dolphin.md](../04-applications/01-dolphin.md) sowie Abschnitt 2 oben (`hyprpolkitagent`, `wl-clipboard`).
- **Hinweis zu `dolphin`:** Zieht als KDE-Anwendung einen größeren Satz an Qt6/KDE-Frameworks-Abhängigkeiten nach sich — Download-Größe entsprechend höher als bei den übrigen, schlanken Hyprland-nativen Tools.
- **Ergebnis (verifiziert 2026-10-18):** Installation fehlerfrei durchgelaufen — **176 Pakete**, 161,84 MiB Download, 698,62 MiB installierte Größe, keine Dateikonflikte.
  - **Interaktive Rückfrage während der Installation:** `pacman` fragte nach einem Anbieter für `qt6-multimedia-backend` (zwei virtuelle Paket-Provider: `qt6-multimedia-ffmpeg` oder `qt6-multimedia-gstreamer`) — mit der Voreinstellung `1` (FFmpeg-Backend) bestätigt. **Was bedeutet das?** Mehrere Pakete können dieselbe "virtuelle" Abhängigkeit erfüllen; `pacman` kann nicht automatisch entscheiden, welches du willst, und fragt nach. FFmpeg ist die funktionsreichere, gebräuchlichere Wahl für Video-/Audio-Decodierung in Qt-Anwendungen.
  - **Warum 176 Pakete für scheinbar 8 Programme?** Haupttreiber ist `dolphin`: Als KDE-Anwendung zieht es das komplette **KDE-Frameworks-6**-Fundament (`kio`, `kconfig`, `kirigami`, `baloo`, `solid`, etc.), die **Qt6-Multimedia-Stack** (inkl. kompletter `ffmpeg`-Codec-Sammlung für Video-Thumbnails), **Samba/CIFS-Unterstützung** (`smbclient`, `cifs-utils` — Netzwerkfreigaben-Browsing in Dolphins Dateidialogen) und **`udisks2`/`libblockdev`** (Disk-/Partitions-Verwaltung, u. a. für automatisches Einbinden von USB-Sticks/SD-Karten) nach sich. Das ist der Preis für einen vollwertigen, "batteries-included" Dateimanager gegenüber einem minimalistischen CLI-Tool.
  - **Bemerkenswerte neue Hintergrund-Funktionalität:** `baloo` ist KDEs Datei-Indexierungsdienst (durchsucht und indiziert Dateiinhalte im Hintergrund für Dolphins Schnellsuche) — läuft als User-Service, sobald Dolphin das erste Mal gestartet wird; bei Bedarf (z. B. Performance-Bedenken auf der SSD) später über `balooctl disable` deaktivierbar.
  - **Pacman-Hook ausgelöst:** `(8/12) Updating linux initcpios...` lief automatisch mit (Standard-Pacman-Hook, reagiert auf bestimmte Paket-Trigger) — unproblematisch, lediglich ein erneuter `mkinitcpio`-Lauf ohne inhaltliche Änderung an unserer NVIDIA-Konfiguration.

**Schritt 3 — SDDM als systemd-Service aktivieren und sofort starten (sobald Schritt 1+2 erfolgreich sind):**
```bash
sudo systemctl enable --now sddm.service
```
- **Aufschlüsselung:** `enable` erzeugt einen Symlink vom Service in `/etc/systemd/system/display-manager.service` (bzw. in das passende Target-`.wants`-Verzeichnis), sodass `sddm.service` bei jedem Boot automatisch nach Erreichen des `graphical.target` gestartet wird. `--now` startet den Service zusätzlich sofort, ohne auf den nächsten Neustart zu warten.

## 4. System-Eingriffe (Kernel, Treiber, Boot, Berechtigungen)
- *Folgt, sobald die Hybrid-Grafik-Konfiguration für Hyprland (vgl. Abschnitt 1) konkret anstehen.*

## 5. Konfiguration & Dotfiles (Deep-Dive & GNU Stow)
- **Korrigiert (2026-10-18):** Diese Hyprland-Version generiert bei Erststart automatisch `~/.config/hypr/hyprland.lua` (**Lua-Syntax**, nicht die ursprünglich angenommene klassische `hyprland.conf`-Syntax — siehe Troubleshooting Abschnitt 10). Die Datei enthält bereits sinnvoll vorbelegte Variablen (`terminal = "kitty"`, `fileManager = "dolphin"`, `menu = "hyprlauncher"` — von Hyprland selbst anhand der installierten Pakete erkannt) sowie Standard-Keybindings.
- **Geplantes Stow-Paket:** `dotfiles/hyprland/.config/hypr/hyprland.lua` — wird von dir manuell angelegt, sobald du die autogenerierte Datei aus `~/.config/hypr/` in die Repo-Struktur überführst. Vollständiger, kommentierter Inhalt wird hier dokumentiert, sobald die Datei stabil ist.

## 6. Ricing, Theming & Desktop-Integration
- *Folgt in späteren Schritten (Statusbar, Notification-Daemon, App-Launcher, Farbschema).*

## 7. Systemd, Autostart & Automatisierung
- **Wichtiger Fund (2026-10-18):** Diese Hyprland-Version (`0.56.2`) nutzt eine **Lua-basierte Konfiguration** (`hyprland.lua`, autogeneriert bei Erststart nach `~/.config/hypr/`), **nicht** die klassische `hyprland.conf`-Syntax (ursprüngliche Doku-Annahme in Abschnitt 5 war veraltet — siehe Troubleshooting, Abschnitt 10). Autostart-Befehle laufen dort über `hl.exec_cmd("...")` innerhalb eines `hl.on("hyprland.start", function () ... end)`-Blocks.
- **Nach Hyprland-Start fehlende Begleitprozesse (2026-10-18):** Hyprlands interner Start-Check meldete `hyprpolkitagent` und `xdg-desktop-portal-hyprland` als fehlend (installiert, aber nicht laufend). Live-Prüfung via `pacman -Ql <paket> | grep systemd` ergab:
  - `hyprpolkitagent.service`, `xdg-desktop-portal-hyprland.service`, `mako.service` — **alle drei bringen einen eigenen systemd-`--user`-Service mit** → Start über `systemctl --user enable --now <service>`, **nicht** über die Lua-Autostart-Sektion.
  - `quickshell` — **kein** systemd-Service vorhanden → muss über `hl.exec_cmd("quickshell")` in der Lua-Autostart-Sektion gestartet werden (einzige verbleibende Komponente, die diesen Weg tatsächlich braucht).
- **`sddm.service`:** System-weiter systemd-Service, startet den Login-Manager beim Boot (siehe Abschnitt 3, Schritt 3).

## 8. Dateisystem (z. B. Btrfs), Netzwerk & Sicherheit
- *Nicht zutreffend / Keine Einträge*

## 9. Verifizierung, Diagnose & Cheatsheet
- **Erster SDDM/Hyprland-Login (verifiziert 2026-10-18):** Erfolgreich — SDDM-Greeter erschien grafisch, Hyprland als Session wählbar, Login funktioniert.
- **Begleitprozesse (verifiziert 2026-10-18 via `systemctl --user status ...`):**
  - `hyprpolkitagent.service` → `active (running)`, Polkit-Agent erfolgreich "für Session 5" registriert.
  - `mako.service` → `active (running)`.
  - `xdg-desktop-portal-hyprland.service` → `active (running)` (Typ `static`, kein `enable` nötig/möglich — normal für D-Bus-nahe Portal-Services). Log zeigt `[screencopy] init successful` — Screenshot-/Screen-Sharing-Grundlage funktioniert bereits.
- **Cheatsheet:**
  - `systemctl --user status <service>` — Laufzeitstatus der drei Begleit-Services.
  - `hyprctl systeminfo` — Allgemeine Hyprland-Laufzeitinformationen.
- **Noch offen:** `quickshell` läuft noch nicht automatisch (kein systemd-Service, siehe Abschnitt 7) — Lua-Autostart-Eintrag in `hyprland.lua` steht noch aus.

## 10. Troubleshooting & Fehler-Historie (Lern-Protokoll)

### [2026-10-18] - Falsche Annahme: klassische `hyprland.conf`-Syntax statt Lua
- **Symptom / Befund:** Dieses Dokument ging ursprünglich (Abschnitt 5) von der klassischen `hyprland.conf`-Textsyntax aus. Nach dem ersten erfolgreichen SDDM-Login zeigte `ls -la ~/.config/hypr/`, dass Hyprland stattdessen automatisch eine `hyprland.lua` angelegt hatte.
- **Technische Ursache (Root Cause):** Hyprland `0.56.2` nutzt bereits die neuere, Lua-basierte Konfiguration (`lua54` wurde deshalb bereits als Abhängigkeit mitinstalliert, siehe Abschnitt 3 — ein Hinweis, der uns vorab hätte auffallen können). Reine Wissens-Veralterung unsererseits, kein Systemfehler.
- **Lerneffekt:** Erneut die gleiche Lektion wie beim NVIDIA-Paketnamen- und beim Mako-Systemd-Vorfall: Software-Projekte (besonders so aktive wie Hyprland) ändern grundlegende Mechanismen schneller, als allgemeines Vorwissen aktuell bleibt — nach jedem größeren Versionssprung die tatsächlich vorliegende Config-Datei zuerst ansehen, bevor man Syntax-Annahmen dokumentiert.
- **Finale Lösung:** Dokumentation in Abschnitt 5 und 7 korrigiert, Lua-Syntax (`hl.exec_cmd`, `hl.on("hyprland.start", ...)`) durchgängig verwendet.

### [2026-10-18] - Hyprland meldet `hyprpolkitagent` und `xdg-desktop-portal-hyprland` als fehlend
- **Symptom / Fehlermeldung:** Direkt nach dem ersten erfolgreichen Hyprland-Start (über SDDM) zeigte Hyprlands interner Start-Check Warnungen, dass `hyprpolkitagent` und `xdg-desktop-portal-hyprland` fehlen würden — obwohl beide Pakete nachweislich installiert waren (siehe Abschnitt 2).
- **Technische Ursache (Root Cause):** "Fehlend" bezog sich auf den **laufenden Prozess**, nicht auf das installierte Paket. Beide Programme müssen aktiv gestartet werden; die frisch autogenerierte `hyprland.lua` enthält den Autostart-Block nur als auskommentierte Vorlage (siehe Abschnitt 5).
- **Finale Lösung:** Live-Prüfung ergab, dass beide (plus `mako`) eigene systemd-`--user`-Services mitbringen — siehe Abschnitt 7 für die korrekte, finale Lösung über `systemctl --user enable --now`.

## 11. Wartung, Updates & Rollback (Saubere Deinstallation)
- *Wird nach Installation ergänzt.*
