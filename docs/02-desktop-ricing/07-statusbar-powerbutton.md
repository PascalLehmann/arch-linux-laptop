# Statusbar-Modul: Power-Button (Sleep/Logout/Reboot/Shutdown)

- **Maschine / Hostname:** thinkpad
- **Kategorie:** 02-Ricing
- **Status:** In Einrichtung
- **Letztes Update:** 2026-10-18
- **Verwandte Dokumentation:** [04-quickshell.md](04-quickshell.md) (Basis-Bar & 3-Zonen-Layout), [06-statusbar-akku.md](06-statusbar-akku.md), [01-hyprland.md](01-hyprland.md), [README.md](../../README.md)

---

## 1. Übersicht, Architektur & Zweck
- **Was ist das?** Ein einzelnes Icon (Power-Symbol) in der rechten Zone der Quickshell-Bar (siehe [04-quickshell.md](04-quickshell.md), Abschnitt 5), das beim Anklicken ein kleines Popup-Menü mit vier Aktionen öffnet: **Sleep** (Suspend-to-RAM), **Logout** (Hyprland-Session beenden), **Reboot** und **Shutdown**. Technisch bestehen dafür zwei Bausteine:
  1. **`PopupWindow`** (Quickshell-eigener Typ, `import Quickshell`): Im Gegensatz zu einem normalen QML-`Rectangle`, das innerhalb der `PanelWindow` gezeichnet würde (und dort an der festen Bar-Höhe von 32px abgeschnitten wäre — ein Layer-Shell-Fenster unter Wayland kann nicht "über seine eigene Fenstergröße hinaus" zeichnen), ist ein `PopupWindow` eine **eigenständige, zweite Layer-Shell-Oberfläche**, die relativ zu einem Anker-Element (hier: dem Power-Button) positioniert wird, über die Property `anchor` (Typ `PopupAnchor`). So kann das Menü unterhalb des Buttons sichtbar "aus der Bar herausklappen", ohne die 32px-Höhe der Haupt-Bar zu sprengen.
  2. **`Process`** (`import Quickshell.Io`): Startet die eigentlichen Befehle (`systemctl suspend`, `systemctl reboot`, `systemctl poweroff`, `hyprctl dispatch exit`) als externe Prozesse. Wichtig: `Process.command` ist eine Liste einzelner Argument-Strings (`["systemctl", "suspend"]`), der Befehl läuft **nicht** über eine Shell (`/bin/sh -c "..."`) — es gibt also keine Shell-Expansion/Quoting-Fallstricke, aber auch keine Pipes/Verkettungen ohne Weiteres.
- **Warum diese vier Aktionen genau so?**
  - *Sleep* → `systemctl suspend`: Versetzt das System in ACPI S3 (Suspend-to-RAM) — RAM bleibt mit minimaler Stromversorgung erhalten, alles andere wird abgeschaltet; schnelles Aufwachen, aber Akku wird trotzdem langsam entladen.
  - *Logout* → `hyprctl dispatch exit`: Beendet gezielt den laufenden Hyprland-Compositor-Prozess der aktuellen Session (IPC-Befehl an den Compositor selbst), wodurch SDDM automatisch wieder den Greeter anzeigt (siehe [05-sddm-theme-clockwork.md](05-sddm-theme-clockwork.md)) — **kein** `systemctl`-Befehl, weil Logout kein System-, sondern ein reiner Compositor/Session-Vorgang ist.
  - *Reboot* → `systemctl reboot`.
  - *Shutdown* → `systemctl poweroff`.
  - Alle drei `systemctl`-Befehle lösen (wie bereits in [05-sddm-theme-clockwork.md](05-sddm-theme-clockwork.md), Abschnitt 10 dokumentiert) das Beenden der aktuellen grafischen Session aus — das ist hier **gewolltes** Verhalten, kein Fehler.
- **Offizielle Referenzen:**
  - [Quickshell-Doku: `Quickshell/PopupWindow`](https://quickshell.org/docs/v0.3.2/types/Quickshell/PopupWindow)
  - [Quickshell-Doku: `Quickshell/PopupAnchor`](https://quickshell.org/docs/v0.3.2/types/Quickshell/PopupAnchor)
  - [Quickshell-Doku: `Quickshell.Io/Process`](https://quickshell.org/docs/v0.3.2/types/Quickshell.Io/Process)
  - [Hyprland-Wiki: `hyprctl dispatch`](https://wiki.hypr.land/Configuring/Dispatchers/) (`exit`)
  - `man systemctl` (Abschnitte `suspend`, `reboot`, `poweroff`)

## 2. Abhängigkeiten & System-Voraussetzungen
- **Pflicht-Pakete:** Keine zusätzlichen — `quickshell` (bereits installiert) bringt `PopupWindow`/`Process` mit, `hyprctl` kommt mit Hyprland, `systemctl` mit systemd (Basis-System).
- **Berechtigungen:** `systemctl suspend/reboot/poweroff` erfordern normalerweise **keine** Root-Rechte für den eingeloggten User (policykit-Regeln von systemd-logind erlauben das für aktive, lokale Sessions standardmäßig) — falls das auf dieser Maschine abweicht, wird das in Abschnitt 10 nachgetragen.

## 3. Installation & Flag-Erklärung
- *Nicht zutreffend* — reine QML-Konfiguration, keine Paket-Installation.

## 4. System-Eingriffe (Kernel, Treiber, Boot, Berechtigungen)
- *Nicht zutreffend / Keine Einträge*

## 5. Konfiguration & Dotfiles (Deep-Dive & GNU Stow)
- **Kein eigenes Stow-Paket:** Wie das Akku-Modul ([06-statusbar-akku.md](06-statusbar-akku.md)) reiner QML-Zusatz in der bestehenden `dotfiles/quickshell/.config/quickshell/shell.qml`.
- **Konfigurations-Block:** *Folgt nach Umsetzung von Schritt 1 (3-Zonen-Layout) und dem Akku-Modul.*

## 6. Ricing, Theming & Desktop-Integration
- *Folgt — Icon-Gestaltung des Power-Buttons und visuelles Design des Popup-Menüs (Hintergrundfarbe, Abstände, Hover-Effekte der vier Aktionen).*

## 7. Systemd, Autostart & Automatisierung
- *Nicht zutreffend / Keine Einträge* (löst Systemd-Aktionen aus, ist aber selbst kein Systemd-Dienst).

## 8. Dateisystem (z. B. Btrfs), Netzwerk & Sicherheit
- *Nicht zutreffend / Keine Einträge*

## 9. Verifizierung, Diagnose & Cheatsheet
- *Folgt nach Implementierung — insbesondere Einzel-Test jeder der vier Aktionen (Sleep/Logout zuerst, da wiederherstellbar; Reboot/Shutdown bewusst zuletzt).*

## 10. Troubleshooting & Fehler-Historie (Lern-Protokoll)
- *Nicht zutreffend / Keine Einträge*

## 11. Wartung, Updates & Rollback (Saubere Deinstallation)
- **Rollback:** Entsprechenden QML-Block (Power-Button + `PopupWindow`) aus `shell.qml` entfernen.
