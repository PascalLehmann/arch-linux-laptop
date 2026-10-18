# Zen Browser

- **Maschine / Hostname:** thinkpad
- **Kategorie:** 04-Apps
- **Status:** Aktiv & Stabil
- **Letztes Update:** 2026-10-18
- **Verwandte Dokumentation:** [04-yay-aur-helper.md](../00-base-system/04-yay-aur-helper.md), [02-browser-vivaldi.md](02-browser-vivaldi.md), [04-browser-tor.md](04-browser-tor.md), [README.md](../../README.md)

---

## 1. Übersicht, Architektur & Zweck
- **Was ist das?** Zen Browser ist ein Firefox-**Fork** — basiert also auf der **Gecko-Engine** und der Firefox-Codebasis, bringt aber ein eigenständiges, stark überarbeitetes UI (vertikale Tabs, Workspaces/Arbeitsbereiche, eingebautes Split-View, Glassmorphism-Theming) sowie einige vorinstallierte Komfort-Erweiterungen mit.
- **Warum nutzen wir es auf dieser Maschine?** Haupt-Browser auf Gecko-Basis (Ergänzung zu Vivaldi auf Blink-Basis, siehe [02-browser-vivaldi.md](02-browser-vivaldi.md)) — Workspaces/vertikale Tabs passen zum Ricing-/Produktivitäts-Anspruch dieses Setups.
- **Offizielle Referenzen:**
  - [Zen Browser Projektseite](https://zen-browser.app/)
  - [AUR-Paket `zen-browser-bin`](https://aur.archlinux.org/packages/zen-browser-bin)

## 2. Abhängigkeiten & System-Voraussetzungen
- **Pflicht-Paket (AUR, nicht in offiziellen Repos!):** `zen-browser-bin` — ein **Binär-Paket** (fertig kompilierte Firefox-Fork-Binaries vom Zen-Projekt, kein lokaler Build aus Quellcode). Benötigt zwingend einen AUR-Helper, siehe [04-yay-aur-helper.md](../00-base-system/04-yay-aur-helper.md) — **muss vor Zen Browser eingerichtet sein.**
- **Namens-Hinweis:** Im AUR existieren mehrere Varianten (`zen-browser-bin` = stabiler Release-Build, `zen-browser-twilight-bin`/`zen-browser-git` = Beta-/Nightly-Kanäle). Wir installieren bewusst **`zen-browser-bin`** (Stable) für ein alltagstaugliches, nicht-experimentelles Setup.
- **Hardware-Bezug:** Wie bei Vivaldi (siehe [02-browser-vivaldi.md](02-browser-vivaldi.md), Abschnitt 2) läuft die Grafik-Beschleunigung aktuell über die Intel-iGPU, solange der proprietäre NVIDIA-Treiber noch nicht final eingerichtet ist.

## 3. Installation & Flag-Erklärung
```bash
yay -S zen-browser-bin
```
- `-S`: `yay`s Sync-Modus — identisch zu `pacman -S`, sucht aber zusätzlich im AUR, falls das Paket nicht in `core`/`extra`/`multilib` gefunden wird.
- **Vor der Bestätigung:** `yay` zeigt dir das `PKGBUILD` zur Durchsicht an (bzw. fragt, ob du es ansehen willst) — siehe [04-yay-aur-helper.md](../00-base-system/04-yay-aur-helper.md), Abschnitt 9, zur Begründung, warum das bei jedem (neuen) AUR-Paket Pflicht ist.

## 4. System-Eingriffe (Kernel, Treiber, Boot, Berechtigungen)
- *Nicht zutreffend / Keine Einträge*

## 5. Konfiguration & Dotfiles (Deep-Dive & GNU Stow)
- Profil liegt unter `~/.zen/` (Firefox-typische `profiles.ini`-Struktur, abweichend vom Standard-Firefox-Pfad `~/.mozilla/firefox/`). Wird ergänzt, falls wir `user.js`/Workspace-Konfiguration später unter Stow verwalten wollen.

## 6. Ricing, Theming & Desktop-Integration
- Eingebaute Theming-Engine (Farbverläufe, "Zen Mods"-Community-Themes) — unabhängig vom System-Theme. Details folgen nach erstem Start und Entscheidung, ob wir Community-Mods einsetzen.

## 7. Systemd, Autostart & Automatisierung
- *Nicht zutreffend / Keine Einträge* — kein Autostart gewünscht, manueller Start über den App-Launcher.

## 8. Dateisystem (z. B. Btrfs), Netzwerk & Sicherheit
- *Nicht zutreffend / Keine Einträge*

## 9. Verifizierung, Diagnose & Cheatsheet
- `zen-browser --version` — installierte Version prüfen (Binary-Name kann je nach Paket-Build leicht abweichen, ggf. `pacman -Ql zen-browser-bin | grep bin/` zur Kontrolle des tatsächlichen Executable-Namens).
- `about:support` (in der Adressleiste) — Gecko-Version, Grafik-Backend (z. B. WebRender-Status) und geladene Profile einsehen.
- **Verifiziert 2026-10-18:** Installation via `yay -S zen-browser-bin` erfolgreich durchgelaufen.

## 10. Troubleshooting & Fehler-Historie (Lern-Protokoll)
- *Nicht zutreffend / Keine Einträge*

## 11. Wartung, Updates & Rollback (Saubere Deinstallation)
- **Wartung:** Updates laufen über `yay -Syu` (nicht reines `pacman -Syu`, da AUR-Paket — `pacman` allein prüft AUR-Pakete nicht auf neue Versionen!). Laut AUR-Kommentaren wird `zen-browser-bin` stündlich automatisiert aktualisiert, sobald Zen ein neues Release veröffentlicht — ein `yay -Syu` sollte also regelmäßig erfolgen, um nicht zurückzufallen.
- **Vollständiger Rollback:** `yay -Rns zen-browser-bin` sowie manuell `rm -rf ~/.zen ~/.cache/zen` für Profil-/Cache-Reste.
