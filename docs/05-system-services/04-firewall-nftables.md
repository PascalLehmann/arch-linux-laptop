# Firewall (nftables)

- **Maschine / Hostname:** thinkpad
- **Kategorie:** 05-Services
- **Status:** Geplant
- **Letztes Update:** 2026-10-18
- **Verwandte Dokumentation:** [01-ssh-server.md](01-ssh-server.md), [02-netzwerk-stack.md](02-netzwerk-stack.md), [README.md](../../README.md)

---

## 1. Übersicht, Architektur & Zweck
- **Was ist das?** `nftables` ist das aktuelle Linux-Kernel-Firewall-Framework (Nachfolger von `iptables`), das Pakete anhand von Regeln filtert, bevor/nachdem sie den Netzwerk-Stack durchlaufen (Hooks in verschiedenen Phasen: `prerouting`, `input`, `forward`, `output`, `postrouting`). `iptables` ist auf dieser Maschine nur als Kompatibilitäts-Binary vorhanden (nutzt intern dieselbe `nft`-Kernel-Schnittstelle, siehe Paketbeschreibung "using nft interface").
- **Warum ist das hier relevant?** **Sicherheitsfund (2026-10-18):** Beide Pakete (`nftables`, `iptables`) sind zwar installiert, aber `sudo nft list ruleset` liefert eine **komplett leere Ausgabe** — es filtert aktuell **nichts**. Jeder offene Dienst dieser Maschine (aktuell mindestens `sshd` auf Port 22, siehe [01-ssh-server.md](01-ssh-server.md)) ist dadurch ungefiltert aus dem gesamten lokalen Netz `172.16.0.0/16` erreichbar.
- **Offizielle Referenzen:**
  - [Arch Wiki: nftables](https://wiki.archlinux.org/title/Nftables)
  - `man nft`, `man nftables`

## 2. Abhängigkeiten & System-Voraussetzungen
- **Pflicht-Pakete:** `nftables` (1:1.1.7-3), `iptables` (1:1.8.13-1) — beide bereits installiert (vermutlich als Abhängigkeit, nicht explizit — in `pacman -Qe` nicht aufgeführt).
- **Hardware-/System-Voraussetzung:** Keine spezifische — reine Kernel-Netfilter-Funktion.

## 3. Installation & Flag-Erklärung
- *Pakete bereits vorhanden — es fehlt ausschließlich ein tatsächlicher Regelsatz und der aktivierte systemd-Service (`nftables.service` lädt beim Boot eine Regeldatei aus `/etc/nftables.conf`).*

## 4. System-Eingriffe (Kernel, Treiber, Boot, Berechtigungen)
- *Folgt, sobald mit dir gemeinsam ein konkreter Regelsatz entschieden wurde (siehe Diskussion in [01-ssh-server.md](01-ssh-server.md), Abschnitt 10).*

## 5. Konfiguration & Dotfiles (Deep-Dive & GNU Stow)
- **System-Konfigurationsdatei (geplant, kein Stow):** `/etc/nftables.conf`.
- *Noch kein Regelsatz vorhanden — Vorlage folgt, sobald Abschnitt 1-Entscheidung mit dir getroffen ist (z. B. Default-Deny für eingehenden Verkehr + explizite Freigabe für SSH, mDNS, etc.).*

## 6. Ricing, Theming & Desktop-Integration
- *Nicht zutreffend / Keine Einträge*

## 7. Systemd, Autostart & Automatisierung
- `nftables.service` — aktuell **nicht aktiviert** (kein Eintrag in `systemctl list-unit-files --state=enabled`, verifiziert 2026-10-18).

## 8. Dateisystem (z. B. Btrfs), Netzwerk & Sicherheit
- Zentrales Thema dieses Dokuments — siehe Abschnitt 1.

## 9. Verifizierung, Diagnose & Cheatsheet
- `sudo nft list ruleset` — zeigt den aktuell geladenen Regelsatz (aktuell: leer).
- `systemctl status nftables.service` — zeigt, ob der Service überhaupt läuft.

## 10. Troubleshooting & Fehler-Historie (Lern-Protokoll)
- *Siehe [01-ssh-server.md](01-ssh-server.md), Abschnitt 10 für den initialen Sicherheitsfund — wird hier ergänzt, sobald ein Regelsatz implementiert ist.*

## 11. Wartung, Updates & Rollback (Saubere Deinstallation)
- *Wird nach Einrichtung ergänzt.*
