# Netzwerk-Stack (systemd-networkd + iwd)

- **Maschine / Hostname:** thinkpad
- **Kategorie:** 05-Services
- **Status:** Aktiv & Stabil
- **Letztes Update:** 2026-10-18
- **Verwandte Dokumentation:** [README.md](../../README.md)

---

## 1. Übersicht, Architektur & Zweck
- **Was ist das?** Zwei zusammenspielende Komponenten regeln die Netzwerkanbindung dieser Maschine, **anstelle** des auf Desktop-Distributionen oft üblichen `NetworkManager`:
  - **`iwd`** (*iNet Wireless Daemon*): Von Intel entwickelter, schlanker WLAN-Daemon. Übernimmt die eigentliche WLAN-Verbindungslogik (Scannen, Authentifizierung, Verschlüsselung) — ersetzt den klassischen `wpa_supplicant`.
  - **`systemd-networkd`**: Teil von systemd selbst, übernimmt die IP-Adress-Konfiguration (DHCP-Client bzw. statische Konfiguration) für **alle** Netzwerk-Interfaces (WLAN **und** die kabelgebundene 2,5-GbE-Schnittstelle).
  - Beide sind per `systemctl list-unit-files --state=enabled` als aktiv bestätigt, ebenso `systemd-resolved` (DNS-Auflösung) und `systemd-timesyncd` (Zeit-Synchronisation via NTP).
- **Warum dieser Ansatz auf dieser Maschine?** Schlanker, minimalistischerer Ansatz als `NetworkManager` (kein D-Bus-GUI-Daemon mit grafischem Anspruch), passt zum bisherigen TTY-first/Learning-by-Doing-Ansatz dieses Projekts — direkte Konfigurationsdateien statt grafischer Netzwerk-Verwaltung.
- **Offizielle Referenzen:**
  - [Arch Wiki: iwd](https://wiki.archlinux.org/title/Iwd)
  - [Arch Wiki: systemd-networkd](https://wiki.archlinux.org/title/Systemd-networkd)
  - `man iwd`, `man systemd.network`, `man systemd-resolved`

## 2. Abhängigkeiten & System-Voraussetzungen
- **Pflicht-Pakete:** `iwd` (Version `3.12-2`, bereits installiert). `systemd-networkd`/`systemd-resolved`/`systemd-timesyncd` sind Bestandteil des `systemd`-Basispakets, keine separate Installation nötig.
- **Hardware-Voraussetzung:** Intel Wi-Fi 6E AX210 (Treiber `iwlwifi`, siehe README Hardware-Profil) für WLAN; Intel I225-LM (Treiber `igc`) für die kabelgebundene Schnittstelle `enp11s0`.

## 3. Installation & Flag-Erklärung
- *Bereits installiert und aktiv — keine Installation mehr nötig. Nachträgliche Dokumentation einer bestehenden Konfiguration.*

## 4. System-Eingriffe (Kernel, Treiber, Boot, Berechtigungen)
- **`iwd` (verifiziert 2026-10-18):** `/etc/iwd/` existiert, ist aber **leer** — kein `main.conf` vorhanden, `iwd` läuft komplett mit internen Defaults. WLAN-Zugangsdaten (PSKs) werden von `iwd` nicht hier, sondern verschlüsselt unter `/var/lib/iwd/<SSID>.psk` abgelegt (nicht Teil dieses Repos, siehe Abschnitt 5).
- **`systemd-networkd` (verifiziert 2026-10-18):** Drei `.network`-Dateien in `/etc/systemd/network/`, je eine pro Interface-Typ (`20-ethernet.network`, `20-wlan.network`, `20-wwan.network`) — alle vom 27.09., stammen vermutlich aus den systemd-Upstream-Beispielkonfigurationen (identischer Kommentar-Block verweist auf ein systemd-GitHub-Issue zu Routen-Metriken).

## 5. Konfiguration & Dotfiles (Deep-Dive & GNU Stow)
- **System-Konfigurationsdateien (kein Stow, da außerhalb `~/`):** `/etc/iwd/` (aktuell leer, s. o.), `/etc/systemd/network/*.network`.
- **Konfigurations-Block `20-ethernet.network` (verifiziert 2026-10-18):**
  ```ini
  [Match]
  Type=ether
  Kind=!*          # schließt virtuelle Ethernet-Interfaces (Docker-Bridges etc.) aus

  [Link]
  RequiredForOnline=routable   # Interface muss eine Route haben, um als "online" zu gelten

  [Network]
  DHCP=yes
  MulticastDNS=yes             # mDNS (.local-Namensauflösung im lokalen Netz, z. B. "thinkpad.local")

  [DHCPv4]
  RouteMetric=100               # niedrigste Metrik = höchste Priorität

  [IPv6AcceptRA]
  RouteMetric=100
  ```
  - **Was/Warum/Nutzen:** Die `RouteMetric`-Werte (Ethernet `100` < WLAN `600` < WWAN `700`) sorgen dafür, dass bei mehreren gleichzeitig aktiven Verbindungen (z. B. Kabel UND WLAN eingesteckt) automatisch die kabelgebundene, stabilere Verbindung bevorzugt wird — identische Werte wie NetworkManagers Standard-Priorisierung (laut Kommentar im File bewusst von dort übernommen).
  - `20-wlan.network`/`20-wwan.network` sind strukturell identisch, nur mit `Type=wlan`/`Type=wwan` und den entsprechend höheren `RouteMetric`-Werten (`600`/`700`).
- **Maschinen-Spezifische Werte:** WLAN-Zugangsdaten/PSKs liegen verschlüsselt unter `/var/lib/iwd/` (von `iwd` selbst verwaltet) und sind **nicht** Teil dieses Git-Repositorys — bei einer Neuinstallation müssen WLAN-Netze über `iwctl` manuell neu verbunden werden.

## 6. Ricing, Theming & Desktop-Integration
- *Nicht zutreffend / Keine Einträge*

## 7. Systemd, Autostart & Automatisierung
- `iwd.service`, `systemd-networkd.service`, `systemd-networkd-wait-online.service`, `systemd-resolved.service`, `systemd-timesyncd.service` — alle system-weit `enabled`.

## 8. Dateisystem (z. B. Btrfs), Netzwerk & Sicherheit
- **Aktuelle Netzwerk-Identität (siehe README Abschnitt 2):** WLAN (`wlan0`) im Netz `172.16.0.0/16` aktiv, kabelgebundene Schnittstelle `enp11s0` physisch vorhanden, aber `NO-CARRIER` (nicht angeschlossen).
- **Firewall:** **Keine aktiv** — siehe [04-firewall-nftables.md](04-firewall-nftables.md) und Sicherheitsfund in [01-ssh-server.md](01-ssh-server.md), Abschnitt 10.

## 9. Verifizierung, Diagnose & Cheatsheet
- `iwctl device list` / `iwctl station wlan0 show` — WLAN-Verbindungsstatus über `iwd`s eigenes CLI-Tool.
- `networkctl list` / `networkctl status` — Status aller von `systemd-networkd` verwalteten Interfaces.
- `resolvectl status` — Aktuelle DNS-Konfiguration.

## 10. Troubleshooting & Fehler-Historie (Lern-Protokoll)
- *Noch keine Einträge.*

## 11. Wartung, Updates & Rollback (Saubere Deinstallation)
- *Wird nach Live-Prüfung ergänzt.*
