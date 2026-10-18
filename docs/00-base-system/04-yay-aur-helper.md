# yay (AUR-Helper)

- **Maschine / Hostname:** thinkpad
- **Kategorie:** 00-Base
- **Status:** Aktiv & Stabil
- **Letztes Update:** 2026-10-18
- **Verwandte Dokumentation:** [how-to-use-git-and-stow.md](how-to-use-git-and-stow.md), [02-browser-vivaldi.md](../04-applications/02-browser-vivaldi.md), [03-browser-zen.md](../04-applications/03-browser-zen.md), [README.md](../../README.md)

---

## 1. Übersicht, Architektur & Zweck
- **Was ist das?** `yay` ("Yet Another Yogurt") ist ein **AUR-Helper** — ein Wrapper um `pacman` und `makepkg`, der das **Arch User Repository (AUR)** zugänglich macht. Das AUR ist kein Binär-Repository wie `core`/`extra`, sondern eine riesige, von der Community gepflegte Sammlung von **`PKGBUILD`-Dateien** (Bauanleitungen/Shell-Skripte). `yay` automatisiert den sonst manuellen Drei-Schritt-Prozess: AUR-Git-Repo klonen → `PKGBUILD` mit `makepkg` zu einem echten `pacman`-Paket (`.pkg.tar.zst`) bauen → mit `pacman -U` installieren. Zusätzlich kann `yay` wie `pacman` auch offizielle Repo-Pakete verwalten (ein echter Drop-in-Wrapper), und es löst AUR-Abhängigkeiten rekursiv auf (inkl. verschachtelter AUR-Pakete, die selbst wieder AUR-Pakete benötigen).
- **Warum nutzen wir es auf dieser Maschine?** Mehrere Programme, die wir einsetzen wollen (z. B. `zen-browser-bin`), existieren **ausschließlich im AUR**, nicht in den offiziellen Repos (`core`/`extra`/`multilib`). Ohne AUR-Helper müsste jedes dieser Pakete händisch via `git clone` + `makepkg -si` gebaut werden — machbar, aber bei häufigeren AUR-Updates unpraktisch. `yay` ist (neben `paru`, das in Rust statt Go geschrieben ist) der de-facto Standard-AUR-Helper in der Arch-Community.
- **Wichtige Abgrenzung (kein offizieller Bestandteil von Arch!):** Das AUR ist **ungeprüfter, von Nutzern eingereichter Code** — es gibt keine Qualitätskontrolle durch die Arch-Entwickler wie bei `core`/`extra`. Jedes `PKGBUILD` ist im Kern ein Shell-Skript, das mit den Rechten des aufrufenden Users (bzw. während `makepkg` teils auch mit `root`-Rechten für die Installationsphase) ausgeführt wird. **Vor jeder Installation eines neuen AUR-Pakets prüfen wir das `PKGBUILD` manuell**, bevor es gebaut wird (siehe Abschnitt 9).
- **Offizielle Referenzen:**
  - [Arch Wiki: AUR helpers](https://wiki.archlinux.org/title/AUR_helpers)
  - [Arch Wiki: makepkg](https://wiki.archlinux.org/title/Makepkg)
  - [yay GitHub-Repository](https://github.com/Jguer/yay)

## 2. Abhängigkeiten & System-Voraussetzungen
- **Pflicht-Pakete (offizielle Repos, `extra`):**
  - `git` — zum Klonen des AUR-Git-Repos von `yay` selbst (Bootstrapping-Henne-Ei-Problem: `yay` kommt nicht aus dem AUR-Helper, sondern wird einmalig manuell gebaut).
  - `base-devel` (Paket-**Gruppe**, nicht einzelnes Paket) — enthält u. a. `fakeroot`, `binutils`, `gcc`, `make`, `patch`: die komplette Standard-Toolchain, die `makepkg` zum Kompilieren/Verpacken jedes beliebigen AUR-Pakets benötigt.
- **Optionale Pakete (`optdepends`):** Keine zusätzlichen für `yay` selbst — reine Laufzeit-Abhängigkeiten sind mit `git`/`base-devel` bereits abgedeckt.
- **Hardware- & System-Voraussetzungen:** Keine hardwarespezifischen Anforderungen auf dieser Maschine. Einzige Voraussetzung: Ein Nicht-root-User mit funktionierendem `sudo`-Zugriff (nötig, da `makepkg` **niemals als root** laufen darf — die Installationsphase am Ende ruft intern `sudo pacman -U` auf).

## 3. Installation & Flag-Erklärung
- **Schritt 1 — Voraussetzungen installieren:**
  ```bash
  sudo pacman -S --needed git base-devel
  ```
  - `-S`: Synchronisiert mit den konfigurierten Repos und installiert das/die angegebenen Pakete.
  - `--needed`: Überspringt Pakete, die bereits in der aktuellen Version installiert sind (verhindert unnötige Neuinstallationen/Downgrades, falls `git` oder Teile von `base-devel` schon vorhanden sind).
- **Schritt 2 — `yay`-Quellen klonen:**
  ```bash
  git clone https://aur.archlinux.org/yay.git
  cd yay
  ```
  - Klont das AUR-Git-Repo von `yay` — enthält **nur** das `PKGBUILD` und ggf. Patches, **keinen** vorkompilierten Binärcode.
- **Schritt 3 — PKGBUILD prüfen (siehe Abschnitt 9 für die Begründung, warum das Pflicht ist):**
  ```bash
  less PKGBUILD
  ```
- **Schritt 4 — Bauen & Installieren:**
  ```bash
  makepkg -si
  ```
  - `makepkg`: Liest das lokale `PKGBUILD`, lädt die im `source`-Array definierten Quellen herunter, baut daraus ein `pacman`-kompatibles Paket.
  - `-s` (`--syncdeps`): Löst Build- und Laufzeit-Abhängigkeiten automatisch über `pacman` auf und installiert sie vorab.
  - `-i` (`--install`): Installiert das fertig gebaute Paket direkt im Anschluss via `pacman -U`, statt nur die `.pkg.tar.zst`-Datei im aktuellen Verzeichnis liegen zu lassen.

## 4. System-Eingriffe (Kernel, Treiber, Boot, Berechtigungen)
- *Nicht zutreffend / Keine Einträge*

## 5. Konfiguration & Dotfiles (Deep-Dive & GNU Stow)
- *Nicht zutreffend / Keine Einträge* — `yay` besitzt zwar eine optionale Konfigurationsdatei (`~/.config/yay/config.json`), diese wird aber nicht verändert; Standardverhalten ist für unsere Zwecke ausreichend.

## 6. Ricing, Theming & Desktop-Integration
- *Nicht zutreffend / Keine Einträge*

## 7. Systemd, Autostart & Automatisierung
- *Nicht zutreffend / Keine Einträge*

## 8. Dateisystem (z. B. Btrfs), Netzwerk & Sicherheit
- **Netzwerk & Sicherheit:** `yay` lädt Quellcode/Binärdateien von AUR-Maintainern über das Internet herunter und baut daraus lokal ausführbaren Code — das ist der zentrale Sicherheits-Unterschied zu `core`/`extra` (dort signieren Arch-Entwickler die fertigen Binärpakete kryptografisch, im AUR gibt es diese Signatur-Kette nicht). Jedes `PKGBUILD` daher vor dem ersten Bauen lesen (siehe Abschnitt 9).
- **Btrfs:** Build-Verzeichnisse von `makepkg` landen standardmäßig im aktuellen Arbeitsverzeichnis (z. B. `~/yay/`) bzw. bei AUR-Helpern typischerweise in einem Cache-Unterordner — keine Besonderheiten für Snapshots/CoW auf dieser Maschine.

## 9. Verifizierung, Diagnose & Cheatsheet
- **Funktionsprüfung:** `yay --version` — zeigt die installierte `yay`-Version; bestätigt, dass der Build erfolgreich war und der Wrapper im `PATH` liegt.
- **Verifiziert 2026-10-18:** `yay --version` → `yay v13.0.1 - libalpm v16.0.1`. Build via `git clone` + `makepkg -si` erfolgreich, kein manuelles Eingreifen nötig.
- **Sicherheits-Cheatsheet (vor jedem neuen AUR-Paket):**
  1. `PKGBUILD` lesen (`yay -G <paket>` lädt es ohne Bau herunter, oder direkt in der von `yay` angezeigten Vorschau bestätigen).
  2. Prüfen: Wer ist der Maintainer? Wie viele Votes/Popularity auf der AUR-Webseite (`aur.archlinux.org/packages/<paket>`)? Gibt es aktuelle Kommentare zu Problemen/Kompromittierungen?
  3. Erst nach positiver Prüfung mit `y` bestätigen.
- **Alltags-Cheatsheet:**
  - `yay -Syu` — System **inkl. AUR-Paketen** komplett aktualisieren (Drop-in-Ersatz für `pacman -Syu`, prüft zusätzlich alle installierten AUR-Pakete auf neue Versionen).
  - `yay -S <paket>` — Paket installieren (sucht automatisch erst in offiziellen Repos, dann im AUR).
  - `yay -Ss <suchbegriff>` — Paketsuche über offizielle Repos **und** AUR gleichzeitig.
  - `yay -Qm` — Zeigt alle **aus dem AUR** installierten Pakete (nützlich, um den Überblick zu behalten, was offiziell und was AUR-Herkunft ist).

## 10. Troubleshooting & Fehler-Historie (Lern-Protokoll)
- *Nicht zutreffend / Keine Einträge*

## 11. Wartung, Updates & Rollback (Saubere Deinstallation)
- **Wartung:** `yay` selbst wird über sich selbst aktuell gehalten (`yay -Syu` aktualisiert auch `yay`, sobald es als AUR-Paket erkannt wird). Bei AUR-Paketen generell: Nach größeren `glibc`/Toolchain-Updates kann ein `--rebuild` einzelner AUR-Pakete nötig werden, falls diese gegen alte Bibliotheksversionen gelinkt wurden.
- **Vollständiger Rollback:** `sudo pacman -Rns yay` (entfernt `yay` und dessen nicht mehr benötigte Abhängigkeiten; `git`/`base-devel` bleiben i. d. R. sinnvollerweise installiert, da andere Build-Workflows sie weiter benötigen könnten — bewusst nicht automatisch mitentfernt).
