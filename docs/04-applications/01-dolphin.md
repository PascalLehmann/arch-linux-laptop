# Dolphin (Dateimanager)

- **Maschine / Hostname:** thinkpad
- **Kategorie:** 04-Apps
- **Status:** In Einrichtung
- **Letztes Update:** 2026-10-18
- **Verwandte Dokumentation:** [01-hyprland.md](../02-desktop-ricing/01-hyprland.md), [README.md](../../README.md)

---

## 1. Übersicht, Architektur & Zweck
- **Was ist das?** `Dolphin` ist der grafische Dateimanager des KDE-Plasma-Projekts (`kde-applications`/`kde-system`-Gruppe) — läuft aber eigenständig, **ohne** eine vollständige Plasma-Desktop-Umgebung zu benötigen, und funktioniert daher problemlos innerhalb einer Hyprland-Session.
- **Warum nutzen wir es auf dieser Maschine?** Ausgereifter, funktionsreicher Dateimanager (Tabs, Split-View, Netzwerk-Freigaben-Integration) als grafische Ergänzung zur bisherigen reinen CLI-Dateiverwaltung.
- **Offizielle Referenzen:**
  - [KDE Dolphin-Handbuch](https://docs.kde.org/stable5/en/dolphin/dolphin/)
  - [Arch Wiki: KDE](https://wiki.archlinux.org/title/KDE)

## 2. Abhängigkeiten & System-Voraussetzungen
- **Pflicht-Pakete:** `dolphin` (`extra`, 26.08.2-1) — zieht einen umfangreichen Satz an KDE-Frameworks-/Qt6-Bibliotheken als Abhängigkeiten mit (wird beim Installations-Schritt sichtbar, siehe [01-hyprland.md](../02-desktop-ricing/01-hyprland.md), Abschnitt 3 für das tatsächliche Ergebnis).
- **Hinweis:** Da Dolphin eigentlich für die KDE-Plasma-Umgebung gebaut ist, können manche Komfort-Features (z. B. Thumbnails für bestimmte Dateitypen, Papierkorb-Integration) ohne laufende Plasma-Dienste eingeschränkt sein — wird bei der ersten echten Nutzung verifiziert.

## 3. Installation & Flag-Erklärung
- Siehe Sammel-Installationsbefehl in [01-hyprland.md](../02-desktop-ricing/01-hyprland.md), Abschnitt 3.

## 4. System-Eingriffe (Kernel, Treiber, Boot, Berechtigungen)
- *Nicht zutreffend / Keine Einträge*

## 5. Konfiguration & Dotfiles (Deep-Dive & GNU Stow)
- **Geplantes Stow-Paket:** `dotfiles/dolphin/.config/dolphinrc` (+ ggf. `kdeglobals` für Theming) — wird nach erster Nutzung dokumentiert.

## 6. Ricing, Theming & Desktop-Integration
- *Folgt — Qt-Theming-Abstimmung mit dem restlichen Hyprland-Look.*

## 7. Systemd, Autostart & Automatisierung
- *Nicht zutreffend* — wird on-demand gestartet, kein Autostart.

## 8. Dateisystem (z. B. Btrfs), Netzwerk & Sicherheit
- *Nicht zutreffend / Keine Einträge*

## 9. Verifizierung, Diagnose & Cheatsheet
- `dolphin` (manueller Start im Terminal) — zeigt eventuelle Start-Fehler direkt in der Konsole an.

## 10. Troubleshooting & Fehler-Historie (Lern-Protokoll)
- *Noch keine Einträge.*

## 11. Wartung, Updates & Rollback (Saubere Deinstallation)
- **Vollständiger Rollback:** `sudo pacman -Rns dolphin` (entfernt Dolphin selbst; von anderen Paketen mitbenötigte KDE-Frameworks-Abhängigkeiten bleiben ggf. erhalten, siehe `pacman -Qtd` zum Aufspüren verwaister Pakete).
