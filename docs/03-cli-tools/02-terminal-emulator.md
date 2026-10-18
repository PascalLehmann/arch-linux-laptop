# Terminal-Emulator (Kitty & Ghostty, Testphase)

- **Maschine / Hostname:** thinkpad
- **Kategorie:** 03-CLI
- **Status:** In Einrichtung
- **Letztes Update:** 2026-10-18
- **Verwandte Dokumentation:** [01-hyprland.md](../02-desktop-ricing/01-hyprland.md), [README.md](../../README.md)

---

## 1. Übersicht, Architektur & Zweck
- **Was ist das?** Ein Terminal-Emulator stellt die grafische Fensterfläche bereit, in der eine Shell (z. B. `bash`) läuft — er selbst führt keine Befehle aus, sondern rendert Text, verarbeitet Tastatureingaben und leitet sie an die darunterliegende Shell weiter. Beide hier betrachteten Kandidaten sind **GPU-beschleunigt** (rendern über OpenGL/Metal-artige Backends statt reiner CPU-Software-Rasterung) und **Wayland-nativ**.
  - **Kitty:** Etabliert, sehr konfigurierbar (eigene `kitty.conf`-Syntax), unterstützt eigene Erweiterungen wie das *Kitty Graphics Protocol* (Bilder direkt im Terminal).
  - **Ghostty:** Jünger, Fokus auf native Performance und sehr geringe Latenz, nutzt teilweise andere Konfigurationsphilosophie (einfachere Textdatei-Syntax).
- **Warum zwei parallel?** Architektur-Entscheidung laut Roadmap (README) war "Kitty **oder** Ghostty — Entscheidung folgt im jeweiligen Konzept-Schritt". Du hast dich entschieden, beide zu installieren und im echten Alltag unter Hyprland zu vergleichen, bevor eine endgültige Wahl (und damit das Stow-Dotfile-Paket) für eines von beiden getroffen wird.
- **Offizielle Referenzen:**
  - [Kitty-Dokumentation](https://sw.kovidgoyal.net/kitty/)
  - [Ghostty-Dokumentation](https://ghostty.org/docs)
  - [Arch Wiki: Kitty](https://wiki.archlinux.org/title/Kitty)

## 2. Abhängigkeiten & System-Voraussetzungen
- **Pflicht-Pakete (live verifiziert 2026-10-18):** `kitty` (`extra`, 0.49.2-1), `ghostty` (`extra`, 1.3.1-2).
- **Optionale Pakete:** `ghostty-shell-integration` (Shell-Hooks für Prompt-Markierung/OSC-Sequenzen), `ghostty-terminfo` (Terminfo-Datenbank-Eintrag, wichtig für korrekte Terminal-Fähigkeits-Erkennung auf entfernten Systemen per SSH) — **beide empfehlenswert**, da wir bereits einen aktiven SSH-Server betreiben (siehe [01-ssh-server.md](../05-system-services/01-ssh-server.md)) und `ghostty-terminfo` Darstellungsfehler bei SSH-Sessions von/zu dieser Maschine vermeidet. `ghostty-nautilus` ist GNOME-spezifisch und für uns nicht relevant.
- **Hardware-Voraussetzung:** GPU-Beschleunigung über die Intel-iGPU (primäre Render-GPU, siehe [01-hyprland.md](../02-desktop-ricing/01-hyprland.md)).

## 3. Installation & Flag-Erklärung
- Siehe Sammel-Installationsbefehl in [01-hyprland.md](../02-desktop-ricing/01-hyprland.md), Abschnitt 3.

## 4. System-Eingriffe (Kernel, Treiber, Boot, Berechtigungen)
- *Nicht zutreffend / Keine Einträge*

## 5. Konfiguration & Dotfiles (Deep-Dive & GNU Stow)
- **Geplante Stow-Pakete (von dir manuell anzulegen, sobald die Entscheidung gefallen ist):**
  - `dotfiles/kitty/.config/kitty/kitty.conf`
  - `dotfiles/ghostty/.config/ghostty/config`
- *Konkrete Konfigurationsinhalte folgen, sobald du mit beiden experimentiert hast.*

## 6. Ricing, Theming & Desktop-Integration
- *Folgt — Farbschema-Abstimmung mit dem restlichen Hyprland-Theming, sobald eines der beiden final gewählt ist.*

## 7. Systemd, Autostart & Automatisierung
- *Nicht zutreffend / Keine Einträge*

## 8. Dateisystem (z. B. Btrfs), Netzwerk & Sicherheit
- *Nicht zutreffend / Keine Einträge*

## 9. Verifizierung, Diagnose & Cheatsheet
- `kitty --version` / `ghostty --version` — installierte Versionen prüfen.

## 10. Troubleshooting & Fehler-Historie (Lern-Protokoll)
- *Noch keine Einträge.*

## 11. Wartung, Updates & Rollback (Saubere Deinstallation)
- **Entscheidung ausstehend:** Sobald du dich für einen der beiden entschieden hast, wird der jeweils andere hier vermerkt und per `sudo pacman -Rns <paket>` wieder entfernt, um die Testphase sauber abzuschließen.
