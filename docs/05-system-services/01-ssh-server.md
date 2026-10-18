# OpenSSH-Server (Fernzugriff)

- **Maschine / Hostname:** thinkpad
- **Kategorie:** 05-Services
- **Status:** In Einrichtung
- **Letztes Update:** 2026-10-18
- **Verwandte Dokumentation:** [README.md](../../README.md)

---

## 1. Übersicht, Architektur & Zweck
- **Was ist das?** OpenSSH stellt zwei Komponenten bereit: den **SSH-Client** (`ssh`, für ausgehende Verbindungen zu anderen Maschinen) und den **SSH-Server** (`sshd`, nimmt eingehende, verschlüsselte Fernzugriffs-Verbindungen entgegen). Die Kommunikation läuft über das SSH-Protokoll (Transport-Layer-Verschlüsselung + Authentifizierung, standardmäßig Port 22/TCP).
- **Warum nutzen wir es auf dieser Maschine?** `sshd.service` ist bereits aktiv (per `systemctl list-unit-files --state=enabled` verifiziert) — der Laptop kann also bereits jetzt von anderen eigenen Geräten im Netzwerk per SSH erreicht werden (z. B. für Fernwartung, Datei-Transfer via `scp`/`rsync`, oder späteren Zugriff vom Homeserver aus). Dieser Fund macht eine **sicherheitsrelevante Live-Prüfung der tatsächlichen Konfiguration zwingend** (Abschnitt 4), bevor der Status auf "Aktiv & Stabil" gesetzt werden kann.
- **Offizielle Referenzen:**
  - [Arch Wiki: OpenSSH](https://wiki.archlinux.org/title/OpenSSH)
  - `man sshd_config`, `man sshd`, `man ssh_config`

## 2. Abhängigkeiten & System-Voraussetzungen
- **Pflicht-Pakete:** `openssh` (Version `10.6p1-2`, bereits installiert — enthält sowohl Client als auch Server-Binary `sshd`).
- **Optionale Pakete (`optdepends`):** *Folgt nach Live-Prüfung (z. B. `libfido2` für Hardware-Security-Keys, falls gewünscht).*
- **Hardware- & System-Voraussetzungen:** Host-Schlüsselpaare bereits vorhanden unter `/etc/ssh/` (ECDSA, Ed25519, ML-DSA44-Hybrid, RSA — per `ls -la /etc/ssh/` verifiziert, erzeugt am 18.10. durch den `sshd-keygen`-Hook bei der Erstinstallation).

## 3. Installation & Flag-Erklärung
- *Bereits installiert und `sshd.service` bereits aktiviert — kein Installationsschritt mehr nötig.* Dieses Dokument dient der **nachträglichen** Dokumentation einer bereits laufenden Konfiguration (vgl. Disclaimer in der [README](../../README.md), Abschnitt 4).

## 4. System-Eingriffe (Kernel, Treiber, Boot, Berechtigungen)
- **Effektive Konfiguration (verifiziert 2026-10-18 via `sudo sshd -T`):**
  - `Port 22` — Standard-Port, nicht geändert.
  - `PermitRootLogin prohibit-password` — `root` darf sich **nur** per Public-Key einloggen, **nicht** per Passwort. Guter Sicherheits-Default.
  - `PubkeyAuthentication yes` — Public-Key-Login ist aktiviert.
  - `PasswordAuthentication yes` — ⚠️ **Passwort-Login ist für alle Benutzer erlaubt**, nicht nur Public-Key-Only. In Kombination mit dem Fund in Abschnitt 8 (keine aktive Firewall) ein offener Härtungspunkt — siehe Troubleshooting (Abschnitt 10) und Diskussion mit dem User.
  - `X11Forwarding no` — X11-Forwarding deaktiviert (reduziert Angriffsfläche, ohnehin für unseren Wayland/Hyprland-Workflow irrelevant).
  - `KbdInteractiveAuthentication no`, `UsePAM yes`, `PrintMotd no` — Arch-Linux-Standardwerte aus `/etc/ssh/sshd_config.d/99-archlinux.conf`.
- **Drop-in-Konfigurationen in `/etc/ssh/sshd_config.d/`:**
  - `20-systemd-userdb.conf` (Symlink auf `/usr/lib/systemd/sshd_config.d/...`, systemd-Paket-Standard): Setzt `AuthorizedKeysCommand /usr/bin/userdbctl ssh-authorized-keys %u` — erlaubt es, autorisierte SSH-Keys auch über systemd-`userdb`-Records (nicht nur die klassische `~/.ssh/authorized_keys`-Datei) aufzulösen. Reine Arch-Systemd-Integration, keine manuelle Anpassung.
  - `99-archlinux.conf` (Arch-Paket-Standard): Siehe oben.

## 5. Konfiguration & Dotfiles (Deep-Dive & GNU Stow)
- **System-Konfigurationsdatei:** `/etc/ssh/sshd_config` (+ Drop-ins unter `/etc/ssh/sshd_config.d/`, siehe Abschnitt 4). *Kein* Stow-Paket, da System-weite Konfiguration außerhalb von `~/`.
- **Konfigurations-Block:** Die Haupt-`sshd_config` selbst enthält aktuell keine von dir vorgenommenen Anpassungen — alle sicherheitsrelevanten effektiven Werte (Abschnitt 4) stammen aus den beiden Drop-in-Dateien bzw. den `sshd`-internen Defaults.
- **Maschinen-Spezifische Werte:** Die Host-Keys unter `/etc/ssh/` sind **pro Maschine einzigartig** und dürfen **niemals** zwischen Maschinen-Repos kopiert werden (jede Maschine muss eigene Host-Keys generieren — sonst ließe sich eine Maschine für die andere ausgeben, *Host-Key-Spoofing*-Risiko).

## 6. Ricing, Theming & Desktop-Integration
- *Nicht zutreffend / Keine Einträge*

## 7. Systemd, Autostart & Automatisierung
- **`sshd.service`:** System-weiter systemd-Service (nicht `--user`), läuft als root (benötigt, um auf privilegierte Host-Keys zuzugreifen und für neue Verbindungen beliebige User-Sessions zu starten). Bereits `enabled` (startet automatisch bei jedem Boot).

## 8. Dateisystem (z. B. Btrfs), Netzwerk & Sicherheit
- **Netzwerk:** Port 22/TCP, erreichbar über jedes Interface aus dem lokalen Netz `172.16.0.0/16` (siehe README, Abschnitt 2).
- **⚠️ Sicherheitsfund (verifiziert 2026-10-18):** `nftables`/`iptables` sind zwar als Pakete installiert (siehe [04-firewall-nftables.md](04-firewall-nftables.md)), aber `sudo nft list ruleset` liefert eine **komplett leere Ausgabe** — es existiert aktuell **keine einzige aktive Firewall-Regel** auf dieser Maschine. Der SSH-Server ist damit uneingeschränkt aus dem gesamten lokalen Netz erreichbar, und zusätzlich ist `PasswordAuthentication yes` aktiv (siehe Abschnitt 4) — zwei sich gegenseitig verschärfende offene Punkte. Details und Härtungsoptionen siehe Abschnitt 10 und [04-firewall-nftables.md](04-firewall-nftables.md).
- **Status bleibt bewusst auf "In Einrichtung"**, bis diese Punkte mit dir besprochen und ggf. gehärtet sind.

## 9. Verifizierung, Diagnose & Cheatsheet
- `sudo systemctl status sshd.service` — Laufzeitstatus des Servers.
- `sudo sshd -T` — Gibt die **tatsächlich wirksame** Konfiguration aus (alle Defaults + Overrides aufgelöst) — zuverlässiger als das reine Lesen der `sshd_config`-Datei, da Drop-ins und interne Defaults mit einfließen.
- `ss -tlnp | grep ssh` — Zeigt, auf welchem Port/Interface der Server tatsächlich lauscht.

## 10. Troubleshooting & Fehler-Historie (Lern-Protokoll)

### [2026-10-18] - Sicherheitsfund: SSH offen erreichbar, Passwort-Login erlaubt, keine Firewall aktiv
- **Symptom / Befund:** Im Rahmen der nachträglichen Dokumentation (dieses System existierte bereits vor Beginn der KI-gestützten Doku) zeigte `sudo sshd -T`, dass `PasswordAuthentication yes` aktiv ist, und `sudo nft list ruleset` lieferte eine leere Ausgabe trotz installierter `nftables`/`iptables`-Pakete.
- **Technische Ursache:** Kein Root-Cause im Sinne eines Fehlers — schlicht der Standard-Zustand nach Arch-Linux-Basisinstallation: `sshd` aktiviert Passwort-Login per Default, und `nftables`/`iptables` werden zwar oft als Abhängigkeit anderer Pakete mitinstalliert, aber **niemals automatisch mit Regeln befüllt** — das ist immer ein expliziter, manueller Einrichtungsschritt.
- **Risikobewertung:** Das lokale Netz `172.16.0.0/16` (siehe README Abschnitt 2) ist vermutlich ein vertrauenswürdiges Heimnetz, dennoch bedeutet die Kombination "jeder im Netz kann SSH erreichen" + "Passwort reicht zur Anmeldung" + "keine Firewall filtert zusätzlich" ein unnötig großes Angriffsfenster (z. B. bei einem kompromittierten IoT-Gerät im selben Netz, Brute-Force-Versuche).
- **Finale Lösung:** *Noch offen — wird mit dem User besprochen (mögliche Optionen: `PasswordAuthentication no` + ausschließlich Public-Key-Login; Basis-`nftables`-Regelsatz mit expliziter Freigabe nur für Port 22 aus dem lokalen Subnetz; siehe [04-firewall-nftables.md](04-firewall-nftables.md)).*

## 11. Wartung, Updates & Rollback (Saubere Deinstallation)
- *Wird nach Live-Prüfung ergänzt.*
