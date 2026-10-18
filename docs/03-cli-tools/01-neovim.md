# Neovim (Terminal-Texteditor)

- **Maschine / Hostname:** thinkpad
- **Kategorie:** 03-CLI
- **Status:** Geplant
- **Letztes Update:** 2026-10-18
- **Verwandte Dokumentation:** [README.md](../../README.md)

---

## 1. Übersicht, Architektur & Zweck
- **Was ist das?** Neovim ist ein Fork des klassischen Vim-Editors mit modernisierter Architektur: asynchrone Plugin-API, native Lua-Konfiguration (statt nur Vimscript) und ein eingebauter **LSP-Client** (*Language Server Protocol* — ermöglicht Autovervollständigung, Fehlerprüfung und Code-Navigation durch externe Sprach-Server, ohne dass der Editor selbst Sprachwissen besitzen muss).
- **Warum nutzen wir es auf dieser Maschine?** Als primärer Terminal-Editor für Konfigurationsdateien (`/etc/`, Dotfiles) im Rahmen unseres "Learning by Doing"-Ansatzes — leichtgewichtig genug für die TTY-Phase, aber auch als vollwertige IDE-Alternative ausbaufähig, sobald die grafische Oberfläche steht.
- **Aktueller Stand (2026-10-18):** Paket `neovim` (Version `0.12.6-1`) ist bereits installiert, **aber noch vollständig unkonfiguriert** — kein `~/.config/nvim`-Verzeichnis vorhanden (per `ls -la ~/.config/nvim` verifiziert). Dieses Dokument wird erst mit echtem Inhalt in Abschnitt 5 gefüllt, sobald du die Konfiguration manuell anlegst.
- **Offizielle Referenzen:**
  - [Neovim Dokumentation](https://neovim.io/doc/)
  - [Arch Wiki: Neovim](https://wiki.archlinux.org/title/Neovim)
  - `man nvim`, `:help` innerhalb des Editors

## 2. Abhängigkeiten & System-Voraussetzungen
- **Pflicht-Pakete:** `neovim` (bereits installiert).
- **Optionale Pakete (`optdepends`):** *Folgt, sobald die Konfiguration (Plugin-Manager, LSP-Server, Treesitter-Parser) tatsächlich angelegt wird.*
- **Hardware- & System-Voraussetzungen:** Keine — reines Userspace-CLI-Programm, keine Kernel-/Treiber-Abhängigkeit.

## 3. Installation & Flag-Erklärung
- *Bereits installiert (siehe Abschnitt 1) — kein weiterer Installationsschritt nötig.*

## 4. System-Eingriffe (Kernel, Treiber, Boot, Berechtigungen)
- *Nicht zutreffend / Keine Einträge*

## 5. Konfiguration & Dotfiles (Deep-Dive & GNU Stow)
- *Noch nicht angelegt.* Sobald du `dotfiles/nvim/.config/nvim/init.lua` (bzw. eine modulare Struktur) manuell erstellst, wird hier die vollständige, kommentierte Vorlage inkl. Parameter-Erklärung ergänzt.

## 6. Ricing, Theming & Desktop-Integration
- *Nicht zutreffend / Keine Einträge*

## 7. Systemd, Autostart & Automatisierung
- *Nicht zutreffend / Keine Einträge*

## 8. Dateisystem (z. B. Btrfs), Netzwerk & Sicherheit
- *Nicht zutreffend / Keine Einträge*

## 9. Verifizierung, Diagnose & Cheatsheet
- `nvim --version` — zeigt installierte Version und Build-Features (LuaJIT-Version, etc.).

## 10. Troubleshooting & Fehler-Historie (Lern-Protokoll)
- *Noch keine Einträge.*

## 11. Wartung, Updates & Rollback (Saubere Deinstallation)
- *Wird nach Konfiguration ergänzt.*
