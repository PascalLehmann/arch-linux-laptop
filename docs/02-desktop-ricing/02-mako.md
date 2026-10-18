# Mako (Notification-Daemon)

- **Maschine / Hostname:** thinkpad
- **Kategorie:** 02-Ricing
- **Status:** Aktiv & Stabil
- **Letztes Update:** 2026-10-18
- **Verwandte Dokumentation:** [01-hyprland.md](01-hyprland.md), [README.md](../../README.md)

---

## 1. Übersicht, Architektur & Zweck
- **Was ist das?** `mako` implementiert das `org.freedesktop.Notifications`-D-Bus-Interface (den Standard-Benachrichtigungsmechanismus unter Linux) speziell für Wayland-Compositors. Anwendungen senden Benachrichtigungen über D-Bus, `mako` zeigt sie als kleines Popup-Fenster an (über das `wlr-layer-shell`-Wayland-Protokoll, mit dem Compositor-unabhängige Overlay-Fenster wie Notifications/Statusbars dargestellt werden können — exakt das Protokoll, das auch Hyprland unterstützt).
- **Warum nutzen wir es auf dieser Maschine?** Leichtgewichtige, auf Hyprland/wlroots-artige Compositors zugeschnittene Alternative zu schwereren Desktop-Umgebungs-Benachrichtigungs-Daemons (z. B. aus GNOME/KDE).
- **Offizielle Referenzen:**
  - [Mako GitHub-Repository](https://github.com/emersion/mako)
  - [Arch Wiki: Desktop notifications](https://wiki.archlinux.org/title/Desktop_notifications)
  - `man mako`, `man makoctl`

## 2. Abhängigkeiten & System-Voraussetzungen
- **Pflicht-Pakete:** `mako` (`extra`, 1.11.0-1).
- **System-Voraussetzung:** Ein laufender D-Bus-Session-Bus (automatisch durch systemd-User-Session vorhanden) und ein `wlr-layer-shell`-fähiger Compositor (Hyprland erfüllt das).

## 3. Installation & Flag-Erklärung
- Siehe Sammel-Installationsbefehl in [01-hyprland.md](01-hyprland.md), Abschnitt 3.

## 4. System-Eingriffe (Kernel, Treiber, Boot, Berechtigungen)
- *Nicht zutreffend / Keine Einträge*

## 5. Konfiguration & Dotfiles (Deep-Dive & GNU Stow)
- **Geplantes Stow-Paket:** `dotfiles/mako/.config/mako/config` — Vorlage und Parameter-Erklärung folgen, sobald du die Datei anlegst.

## 6. Ricing, Theming & Desktop-Integration
- *Folgt — Farbschema/Positionierung im Zusammenspiel mit Hyprland-Theming.*

## 7. Systemd, Autostart & Automatisierung
- **Korrigiert (verifiziert 2026-10-18 via `pacman -Ql mako | grep systemd`):** Entgegen der ursprünglichen Annahme in diesem Dokument (siehe Troubleshooting, Abschnitt 10) bringt `mako` einen eigenen systemd-`--user`-Service mit: `/usr/lib/systemd/user/mako.service`. Start erfolgt über `systemctl --user enable --now mako.service`, **nicht** über einen `exec_cmd`-Aufruf in der Hyprland-Config. **Warum funktioniert das, obwohl `mako` eine laufende Wayland-Session braucht?** Der Service wird erst beim ersten tatsächlichen Benachrichtigungs-Bedarf bzw. beim systemd-User-Session-Start aktiv und verbindet sich dann mit dem zu diesem Zeitpunkt bereits über `WAYLAND_DISPLAY` exportierten Compositor-Socket — moderne systemd-User-Sessions importieren die vom Compositor gesetzten Umgebungsvariablen automatisch in die systemd-Manager-Umgebung.

## 8. Dateisystem (z. B. Btrfs), Netzwerk & Sicherheit
- *Nicht zutreffend / Keine Einträge*

## 9. Verifizierung, Diagnose & Cheatsheet
- `notify-send "Test" "Nachricht"` — sendet eine Test-Benachrichtigung (benötigt zusätzlich `libnotify`, separat zu prüfen).
- `makoctl dismiss` / `makoctl mode` — CLI-Steuerung laufender Benachrichtigungen.

## 10. Troubleshooting & Fehler-Historie (Lern-Protokoll)

### [2026-10-18] - Falsche Annahme: "mako läuft nur über Hyprland-exec-once, nicht über Systemd"
- **Symptom / Befund:** Beim ersten Entwurf dieses Dokuments wurde ohne Live-Prüfung angenommen, `mako` müsse wie `quickshell` über `exec-once`/`hl.exec_cmd` in der Hyprland-Config gestartet werden.
- **Technische Ursache (Root Cause):** Reine Verallgemeinerung aus "braucht laufende Wayland-Session" ohne zu prüfen, ob das Paket selbst bereits eine systemd-Lösung mitbringt. `pacman -Ql mako | grep systemd` zeigte, dass `mako.service` bereits vom Paket mitgeliefert wird.
- **Lerneffekt:** Exakt die gleiche Lektion wie schon beim NVIDIA-Paketnamen-Vorfall — **immer live verifizieren statt aus allgemeinem Vorwissen zu verallgemeinern**, besonders bei der Frage "hat dieses Paket schon eine fertige Autostart-Lösung mitgebracht?" (`pacman -Ql <paket> | grep systemd` ist dafür ein zuverlässiger Schnelltest).
- **Finale Lösung:** Siehe korrigierter Abschnitt 7 — Start über `systemctl --user enable --now mako.service`. **Verifiziert 2026-10-18:** `systemctl --user status mako.service` → `active (running)`.

## 11. Wartung, Updates & Rollback (Saubere Deinstallation)
- **Vollständiger Rollback:** `exec-once`-Zeile aus `hyprland.conf` entfernen, danach `sudo pacman -Rns mako`.
