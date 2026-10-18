# Hyprlauncher (App-Launcher)

- **Maschine / Hostname:** thinkpad
- **Kategorie:** 02-Ricing
- **Status:** In Einrichtung
- **Letztes Update:** 2026-10-18
- **Verwandte Dokumentation:** [01-hyprland.md](01-hyprland.md), [README.md](../../README.md)

---

## 1. Übersicht, Architektur & Zweck
- **Was ist das?** `hyprlauncher` ist ein Anwendungsstarter/Picker speziell aus dem Hyprland-Ökosystem — liest installierte `.desktop`-Dateien (Standard-Linux-Anwendungsverknüpfungen unter `/usr/share/applications/`) aus und zeigt sie in einer durchsuchbaren Overlay-Liste an (ähnliches Prinzip wie `rofi`/`wofi`, aber gezielt für Hyprland gebaut und über dessen Protokoll-Erweiterungen integriert).
- **Warum nutzen wir es auf dieser Maschine?** Als "Für den Anfang"-Lösung, um Programme ohne Terminal-`exec`-Aufruf starten zu können, sobald die grafische Session steht.
- **Offizielle Referenzen:**
  - [Hyprlauncher (Arch-Paketbeschreibung/Upstream verlinkt im AUR/Repo-Eintrag)](https://wiki.hyprland.org/)

## 2. Abhängigkeiten & System-Voraussetzungen
- **Pflicht-Pakete:** `hyprlauncher` (`extra`, 0.1.6-9).

## 3. Installation & Flag-Erklärung
- Siehe Sammel-Installationsbefehl in [01-hyprland.md](01-hyprland.md), Abschnitt 3.

## 4. System-Eingriffe (Kernel, Treiber, Boot, Berechtigungen)
- *Nicht zutreffend / Keine Einträge*

## 5. Konfiguration & Dotfiles (Deep-Dive & GNU Stow)
- *Folgt, sobald eine Konfigurationsdatei angelegt wird (Pfad wird nach erster Nutzung/Dokumentation durch `man`/`--help` verifiziert).*

## 6. Ricing, Theming & Desktop-Integration
- **Keybinding-Integration:** Wird über eine `bind = ..., exec, hyprlauncher` o. ä. Zeile in `hyprland.conf` an eine Tastenkombination gebunden (Details folgen in der Hyprland-Konfiguration, [01-hyprland.md](01-hyprland.md) Abschnitt 5).

## 7. Systemd, Autostart & Automatisierung
- *Nicht zutreffend* — wird on-demand per Tastenkombination gestartet, kein Autostart nötig.

## 8. Dateisystem (z. B. Btrfs), Netzwerk & Sicherheit
- *Nicht zutreffend / Keine Einträge*

## 9. Verifizierung, Diagnose & Cheatsheet
- `hyprlauncher` (manueller Start im Terminal) — zeigt, ob der Launcher grundsätzlich fehlerfrei startet.

## 10. Troubleshooting & Fehler-Historie (Lern-Protokoll)
- *Noch keine Einträge.*

## 11. Wartung, Updates & Rollback (Saubere Deinstallation)
- **Vollständiger Rollback:** Keybinding aus `hyprland.conf` entfernen, danach `sudo pacman -Rns hyprlauncher`.
