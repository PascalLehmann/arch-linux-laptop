# Snapper (Btrfs-Snapshot-Automatisierung)

- **Maschine / Hostname:** thinkpad
- **Kategorie:** 00-Base
- **Status:** Aktiv & Stabil
- **Letztes Update:** 2026-10-18
- **Verwandte Dokumentation:** [README.md](../../README.md) (Abschnitt 1, Btrfs-Subvolume-Layout)

---

## 1. Übersicht, Architektur & Zweck
- **Was ist das?** `Snapper` verwaltet automatisierte, platzsparende **Btrfs-Snapshots** (nutzt *Copy-on-Write* — beim Snapshot wird nicht der gesamte Datenbestand kopiert, sondern nur ein Zeiger auf den aktuellen Subvolume-Zustand erzeugt; erst bei späteren Änderungen werden die geänderten Blöcke tatsächlich dupliziert). Snapshots erlauben Rollbacks auf einen früheren Systemzustand, z. B. nach einem fehlgeschlagenen Update.
- **Warum nutzen wir es auf dieser Maschine?** Das Btrfs-Subvolume-Layout (`@`, `@home`, `.snapshots`, `@home/.snapshots`, siehe README Abschnitt 1) ist bereits exakt nach dem gängigen Snapper-Schema angelegt, und `snapper-timeline.timer` + `snapper-cleanup.timer` laufen bereits automatisiert — das System erstellt also schon jetzt regelmäßig Snapshots, ohne dass wir das bisher dokumentiert hatten.
- **Offizielle Referenzen:**
  - [Arch Wiki: Snapper](https://wiki.archlinux.org/title/Snapper)
  - [openSUSE Snapper-Dokumentation (Upstream-Projekt)](https://snapper.io/)
  - `man snapper`

## 2. Abhängigkeiten & System-Voraussetzungen
- **Pflicht-Pakete:** `snapper` (0.13.2-1, bereits installiert).
- **Hardware-/System-Voraussetzung:** Btrfs-Dateisystem mit passendem Subvolume-Layout (bereits vorhanden, siehe README Abschnitt 1) — Snapper funktioniert **nicht** auf anderen Dateisystemen wie `ext4`.

## 3. Installation & Flag-Erklärung
- *Bereits installiert und aktiv — keine Installation mehr nötig. Das Subvolume-Layout wurde bereits vor Beginn der KI-gestützten Dokumentation angelegt (siehe Disclaimer in README, Abschnitt 4).*

## 4. System-Eingriffe (Kernel, Treiber, Boot, Berechtigungen)
- **Verifiziert 2026-10-18:** Zwei Snapper-Configs existieren (`snapper list-configs`): `root` → Subvolume `/`, `home` → Subvolume `/home`. Exakt deckungsgleich mit dem in der README (Abschnitt 1) dokumentierten Subvolume-Layout.

## 5. Konfiguration & Dotfiles (Deep-Dive & GNU Stow)
- **System-Konfigurationsdateien (kein Stow):** `/etc/snapper/configs/<name>` (eine Datei pro Snapper-Konfiguration).
- **Inhalt der `root`-Config (verifiziert 2026-10-18, Auszug der wichtigsten Werte):**
  ```
  SUBVOLUME="/"
  FSTYPE="btrfs"
  SPACE_LIMIT="0.5"            # Snapshots dürfen max. 50% des Dateisystem-Platzes belegen
  FREE_LIMIT="0.2"             # mind. 20% freier Platz soll erhalten bleiben
  TIMELINE_CREATE="yes"        # automatische, stündliche Snapshots aktiv
  TIMELINE_CLEANUP="yes"       # automatische Bereinigung alter Timeline-Snapshots aktiv
  TIMELINE_LIMIT_HOURLY="10"   # 10 stündliche Snapshots werden behalten
  TIMELINE_LIMIT_DAILY="10"    # 10 tägliche Snapshots werden behalten
  TIMELINE_LIMIT_WEEKLY="0"    # keine wöchentlichen Snapshots behalten
  TIMELINE_LIMIT_MONTHLY="10"  # 10 monatliche Snapshots werden behalten
  TIMELINE_LIMIT_YEARLY="10"   # 10 jährliche Snapshots werden behalten
  NUMBER_CLEANUP="yes"         # zusätzliche Bereinigung nach reiner Anzahl (unabhängig von Timeline)
  NUMBER_LIMIT="50"            # max. 50 "normale" nummerierte Snapshots insgesamt
  ```
  - **Was/Warum/Nutzen:** Dies sind die **Standard-Werte**, wie sie das Arch-Wiki-Snapper-Setup empfiehlt (keine manuellen Abweichungen erkennbar) — stündliche automatische Snapshots mit abgestufter Aufbewahrung (viele kurzfristige, wenige langfristige) balancieren Rollback-Fähigkeit gegen Speicherplatzverbrauch auf der SSD.
  - **Offener Punkt:** Kein `snap-pac`-Paket installiert (nicht in `pacman -Qe` gefunden) — Snapshots werden **nicht automatisch vor/nach jedem `pacman`-Update** erstellt, nur zeitgesteuert (`TIMELINE_CREATE`). Ein fehlgeschlagenes Update zwischen zwei Timeline-Snapshots wäre damit nicht automatisch durch einen Pre-Update-Snapshot abgesichert — Entscheidung über `snap-pac`-Nachinstallation liegt bei dir.

## 6. Ricing, Theming & Desktop-Integration
- *Nicht zutreffend / Keine Einträge*

## 7. Systemd, Autostart & Automatisierung
- `snapper-timeline.timer`: Löst periodisch (stündlich) die Erstellung eines neuen Snapshots aus.
- `snapper-cleanup.timer`: Löst periodisch die Bereinigung alter Snapshots gemäß Retention-Policy aus.
- Beide system-weit `enabled`.

## 8. Dateisystem (z. B. Btrfs), Netzwerk & Sicherheit
- **Storage & Snapshots:** Direkt zentrales Thema dieses Dokuments — siehe Abschnitt 1 und 4.
- **Pacman-Hook-Integration:** Zu prüfen, ob bereits ein `snap-pac`-artiger Hook existiert, der automatisch vor/nach jedem `pacman`-Update einen Snapshot erstellt (üblicher Begleiter von Snapper, aber in `pacman -Qe` nicht gefunden — vermutlich **nicht** installiert, wird verifiziert).

## 9. Verifizierung, Diagnose & Cheatsheet
- `snapper list-configs` — zeigt alle eingerichteten Snapshot-Konfigurationen.
- `sudo snapper -c root list` — zeigt die tatsächlich existierenden Snapshots für die `root`-Konfiguration.
- `sudo btrfs subvolume list /` — zeigt alle Subvolumes inkl. Snapshot-Subvolumes auf oberster Ebene.

## 10. Troubleshooting & Fehler-Historie (Lern-Protokoll)
- *Keine Fehler — Snapper lief bereits korrekt und automatisiert, als wir es im Rahmen der nachträglichen Dokumentation entdeckt haben.*

## 11. Wartung, Updates & Rollback (Saubere Deinstallation)
- **Wartung:** Gelegentlich `sudo snapper -c root list` prüfen, ob die Cleanup-Timer tatsächlich wie erwartet alte Snapshots entfernen (verhindert, dass `SPACE_LIMIT` erreicht wird).
- **Vollständiger Rollback:** `sudo systemctl disable --now snapper-timeline.timer snapper-cleanup.timer`, danach `sudo pacman -Rns snapper`. **Achtung:** Entfernt nur die Automatisierung — bereits erstellte Snapshot-Subvolumes unter `.snapshots`/`@home/.snapshots` bleiben bestehen und müssen bei Bedarf manuell per `btrfs subvolume delete` entfernt werden.
