# Vivaldi (Browser)

- **Maschine / Hostname:** thinkpad
- **Kategorie:** 04-Apps
- **Status:** Aktiv & Stabil
- **Letztes Update:** 2026-10-18
- **Verwandte Dokumentation:** [nvidia-prime-hybrid-grafik.md](../01-drivers-hardware/nvidia-prime-hybrid-grafik.md), [03-browser-zen.md](03-browser-zen.md), [04-browser-tor.md](04-browser-tor.md), [README.md](../../README.md)

---

## 1. Übersicht, Architektur & Zweck
- **Was ist das?** Vivaldi ist ein proprietärer, auf dem **Chromium-Engine** (Blink-Renderer, V8-JavaScript-Engine) basierender Browser mit stark erweiterbarer, konfigurierbarer Oberfläche (Tab-Stacking, Tab-Tiling, eingebauter Notizblock/RSS-Reader, Maus-Gesten, umfassende Theming-Optionen).
- **Warum nutzen wir es auf dieser Maschine?** Zweit-/Alltags-Browser neben Zen Browser (Firefox-Basis) — bewusste Entscheidung für **zwei unterschiedliche Rendering-Engines** (Blink vs. Gecko) im Alltag, um Kompatibilitätsprobleme einzelner Webseiten umgehen zu können und nicht von einer einzigen Engine abhängig zu sein.
- **Offizielle Referenzen:**
  - [Arch Wiki: Vivaldi](https://wiki.archlinux.org/title/Vivaldi)
  - [Vivaldi-Paketseite (Arch, `extra`)](https://archlinux.org/packages/extra/x86_64/vivaldi/)

## 2. Abhängigkeiten & System-Voraussetzungen
- **Pflicht-Paket:** `vivaldi` — seit einem Umzug aus dem AUR liegt das Paket mittlerweile direkt im offiziellen `extra`-Repo, d. h. **kein AUR-Helper (`yay`) nötig**, reguläres `pacman` reicht.
- **Optionale Pakete (`optdepends`):**
  - `vivaldi-ffmpeg-codecs` (ebenfalls `extra`) — liefert proprietäre Mediencodecs (u. a. H.264/AAC) für die integrierte `ffmpeg`-Bibliothek, die Vivaldi aus Lizenzgründen nicht selbst mitbringen darf. **Installieren wir**, da sonst Video-Wiedergabe auf vielen Seiten (z. B. eingebettete MP4s) fehlschlägt.
- **Hardware-Bezug auf dieser Maschine:** Diese Maschine hat Hybrid-Grafik (Intel-iGPU + NVIDIA-T1200-dGPU, siehe [nvidia-prime-hybrid-grafik.md](../01-drivers-hardware/nvidia-prime-hybrid-grafik.md)) — der proprietäre NVIDIA-Treiber ist dort laut README noch **nicht** final eingerichtet (aktuell `nouveau`). Solange das so ist, läuft Vivaldis Chromium-GPU-Beschleunigung über die Intel-iGPU (Standard-Wayland-Verhalten ohne expliziten `prime-run`-Aufruf). Nach Abschluss der NVIDIA-PRIME-Einrichtung ist zu prüfen, ob/wie Vivaldi gezielt auf die dGPU geschoben werden soll (aktuell nicht relevant).

## 3. Installation & Flag-Erklärung
```bash
sudo pacman -S --needed vivaldi vivaldi-ffmpeg-codecs
```
- `-S`: Installiert aus den synchronisierten Repos (hier `extra`).
- `--needed`: Überspringt bereits in gleicher Version installierte Pakete.

## 4. System-Eingriffe (Kernel, Treiber, Boot, Berechtigungen)
- *Nicht zutreffend / Keine Einträge*

## 5. Konfiguration & Dotfiles (Deep-Dive & GNU Stow)
- Wird ergänzt, sobald du Vivaldi erstmalig gestartet und ggf. manuell angepasst hast (Profil liegt unter `~/.config/vivaldi/`). Folgt in einem späteren Schritt, falls wir die Konfiguration unter Stow verwalten wollen.

## 6. Ricing, Theming & Desktop-Integration
- Vivaldi bringt ein eigenes, sehr umfangreiches internes Theming-System mit (`vivaldi://settings/themes`) — unabhängig vom System-GTK/Qt-Theme. Details folgen nach erstem Start.

## 7. Systemd, Autostart & Automatisierung
- *Nicht zutreffend / Keine Einträge* — kein Autostart gewünscht, wird manuell über den App-Launcher gestartet.

## 8. Dateisystem (z. B. Btrfs), Netzwerk & Sicherheit
- *Nicht zutreffend / Keine Einträge*

## 9. Verifizierung, Diagnose & Cheatsheet
- `vivaldi --version` — installierte Version prüfen.
- `vivaldi://gpu` (in der Adressleiste) — zeigt, welcher Grafik-Treiber/welches Rendering-Backend (Vulkan/GL, Hardware- vs. Software-Beschleunigung) aktuell tatsächlich genutzt wird — wichtig zur Kontrolle auf dieser Hybrid-Grafik-Maschine.
- **Verifiziert 2026-10-18:** Installation via `pacman -S --needed vivaldi vivaldi-ffmpeg-codecs` erfolgreich (`vivaldi-8.2.4133.89-1`, zusätzlich `libxss` als Abhängigkeit mitinstalliert).

## 10. Troubleshooting & Fehler-Historie (Lern-Protokoll)
- *Nicht zutreffend / Keine Einträge*

## 11. Wartung, Updates & Rollback (Saubere Deinstallation)
- **Wartung:** Updates laufen über reguläres `pacman -Syu`, da `vivaldi` offizielles Repo-Paket ist (kein manuelles Update-Skript wie bei Fremd-Repo-Installationen nötig).
- **Vollständiger Rollback:** `sudo pacman -Rns vivaldi vivaldi-ffmpeg-codecs` sowie manuell `rm -rf ~/.config/vivaldi ~/.cache/vivaldi` für Profil-/Cache-Reste.
