# Tor Browser (torbrowser-launcher)

- **Maschine / Hostname:** thinkpad
- **Kategorie:** 04-Apps
- **Status:** Aktiv & Stabil
- **Letztes Update:** 2026-10-18
- **Verwandte Dokumentation:** [02-browser-vivaldi.md](02-browser-vivaldi.md), [03-browser-zen.md](03-browser-zen.md), [04-firewall-nftables.md](../05-system-services/04-firewall-nftables.md), [README.md](../../README.md)

---

## 1. Übersicht, Architektur & Zweck
- **Was ist das?** `torbrowser-launcher` ist **nicht** der Tor Browser selbst, sondern ein kleines offizielles Launcher-Programm: Es lädt beim ersten Start das aktuelle, vom Tor-Projekt signierte Tor-Browser-Bundle herunter, **verifiziert dessen GPG-Signatur**, entpackt es nach `~/.local/share/torbrowser/` und startet/aktualisiert es bei jedem weiteren Aufruf. Der eigentliche Tor Browser ist wiederum ein Firefox-Fork (Firefox-ESR-Basis), der jede Verbindung durch das **Tor-Netzwerk** (drei verschlüsselte Relay-Hops: Entry/Guard-, Middle-, Exit-Node) routet und zusätzliche Anti-Fingerprinting-Maßnahmen (einheitliche Fenstergröße, deaktivierte/isolierte APIs) mitbringt.
- **Warum nutzen wir es auf dieser Maschine?** Dritter Browser speziell für anonymisiertes/privates Surfen — bewusst getrennt von den Alltags-Browsern Vivaldi und Zen Browser, um Tracking-Vektoren (Cookies, Fingerprinting, IP-Zuordnung) klar zu isolieren.
- **Wichtiger Sicherheits-Hinweis:** Der `torbrowser-launcher` selbst **ist nicht der Sicherheitsmechanismus** — die eigentliche Anonymisierung leistet der heruntergeladene Tor Browser über das Tor-Netzwerk. Der Launcher ist "nur" der vertrauenswürdige, signaturprüfende Verteilweg dafür.
- **Offizielle Referenzen:**
  - [Arch Wiki: Tor](https://wiki.archlinux.org/title/Tor)
  - [torbrowser-launcher-Paketseite](https://archlinux.org/packages/extra/x86_64/torbrowser-launcher/)
  - [Tor Project – offizielle Seite](https://www.torproject.org/)

## 2. Abhängigkeiten & System-Voraussetzungen
- **Pflicht-Paket:** `torbrowser-launcher` — liegt im offiziellen Repo (nach dem `community`→`extra`-Zusammenschluss von 2023 unter `extra`), **kein AUR-Helper nötig**.
- **Korrektur gegenüber Erst-Planung (verifiziert 2026-10-18):** `tor` (der System-Tor-Daemon) wird von `torbrowser-launcher` tatsächlich als **Pflicht-Abhängigkeit** gezogen, nicht nur als `optdepend` — `pacman` hat es automatisch mitinstalliert. Grund: Der Launcher selbst nutzt den System-`tor`-Prozess bzw. dessen SOCKS-Proxy für die Option "Download über das Tor-Netzwerk" beim Beziehen des Browser-Bundles (zusätzlicher Schutz gegen Netzwerk-Zensur/-Überwachung schon beim Download). Der eigentliche Tor Browser bringt für den laufenden Browser-Betrieb trotzdem sein eigenes, gekapseltes `tor`-Binary mit — der System-`tor`-Service muss dafür **nicht** aktiv/laufend sein (`systemctl status tor` prüfen: standardmäßig nicht enabled).
- **System-Eingriff durch die Installation:** Das Paket `tor` hat über einen Pacman-Hook automatisch einen System-User/-Gruppe `tor` (UID/GID 43) angelegt — Standard-Verfahren für Systemdienste, die mit eigenen, eingeschränkten Rechten laufen sollen (Separation of Privileges), statt als `root` oder der eigene User.
- **Optionale Pakete (`optdepends`), bewusst NICHT installiert:**
  - `torsocks` (für `torify`) — würde beliebige andere Kommandozeilen-Programme zwingen, ihren Traffic durch Tor zu routen; nicht unser Anwendungsfall (nur der Browser selbst soll anonymisiert werden).
  - `apparmor` — zusätzliches Sandboxing-Profil für den Launcher; aktuell nicht Teil unseres Security-Setups auf dieser Maschine.
- **Hardware-/System-Voraussetzung:** Keine besonderen hardwarespezifischen Anforderungen. Relevanter Hinweis für diese Maschine: Die geplante `nftables`-Firewall (siehe [04-firewall-nftables.md](../05-system-services/04-firewall-nftables.md), aktuell Status "Geplant") darf ausgehende TCP-Verbindungen zu beliebigen Ports nicht pauschal blockieren, sonst kann der Tor Browser keine Verbindung zu den (sich ständig ändernden) Tor-Relays aufbauen.

## 3. Installation & Flag-Erklärung
```bash
sudo pacman -S --needed torbrowser-launcher
```
- `-S`: Installiert aus dem synchronisierten `extra`-Repo.
- `--needed`: Überspringt die Installation, falls bereits in aktueller Version vorhanden.
- **Erster Start danach manuell im Terminal oder App-Launcher:** `torbrowser-launcher` (lädt beim allerersten Aufruf das eigentliche Browser-Bundle herunter und verifiziert es — erfordert aktive Internetverbindung).

## 4. System-Eingriffe (Kernel, Treiber, Boot, Berechtigungen)
- **System-User/-Gruppe `tor` (UID/GID 43):** Automatisch durch einen Pacman-Hook des `tor`-Pakets angelegt (siehe Abschnitt 2). Technischer Hintergrund: Würde der `tor`-Systemdienst als `root` laufen, hätte ein kompromittierter Tor-Prozess vollen Systemzugriff — der eigene, rechte-eingeschränkte User begrenzt den Schaden im Fall einer Sicherheitslücke auf das, was der `tor`-User selbst darf (klassisches Linux-Prinzip der geringsten Rechte).
- **Kein aktivierter Systemd-Service:** Das Paket installiert die `tor.service`-Unit, aktiviert sie aber nicht automatisch (`systemctl is-enabled tor` → `disabled`). Für unseren Anwendungsfall (nur Tor Browser, kein systemweiter SOCKS-Proxy) bleibt das bewusst so.

## 5. Konfiguration & Dotfiles (Deep-Dive & GNU Stow)
- Konfiguration des Launchers liegt unter `~/.config/torbrowser/`, das heruntergeladene Browser-Bundle unter `~/.local/share/torbrowser/`. Keine Stow-Verwaltung geplant — bewusst als reiner "Vanilla"-Anonymisierungs-Browser ohne Personalisierung/Tracking-Profil belassen (jede individuelle Anpassung verkleinert die Anonymitätsmenge/den "Fingerprint", den man mit anderen Tor-Nutzern teilt).

## 6. Ricing, Theming & Desktop-Integration
- **Bewusst keine Anpassung.** Das Tor-Projekt rät ausdrücklich davon ab, den Tor Browser optisch/funktional zu individualisieren (Theme, Erweiterungen, Schriftarten) — jede Abweichung vom Standard-Erscheinungsbild macht diese eine Installation im Vergleich zu allen anderen Tor-Browser-Nutzern weltweit eindeutiger identifizierbar (Browser-Fingerprinting).

## 7. Systemd, Autostart & Automatisierung
- *Nicht zutreffend / Keine Einträge* — kein Autostart, rein manueller, bewusster Start bei Bedarf.

## 8. Dateisystem (z. B. Btrfs), Netzwerk & Sicherheit
- **Netzwerk:** Baut beim Start einen eigenen, in den Browser integrierten `tor`-Prozess auf, der über zufällig gewählte Relays aus dem öffentlichen Tor-Verzeichnis eine mehrfach verschlüsselte Verbindung aufbaut (siehe Abschnitt 1). Benötigt uneingeschränkten ausgehenden TCP-Zugriff (siehe Abschnitt 2, Hinweis zur künftigen `nftables`-Firewall).
- **Sicherheit:** Signatur-Verifizierung des Bundles via GPG ist der zentrale Schutzmechanismus des Launchers gegen manipulierte Downloads — **niemals** die GPG-Prüfung umgehen, falls der Launcher sie als fehlgeschlagen meldet.

## 9. Verifizierung, Diagnose & Cheatsheet
- `torbrowser-launcher --version` — installierte Launcher-Version prüfen.
- Nach dem ersten Start: In der Tor-Browser-Adressleiste `about:tor` aufrufen — zeigt an, ob erfolgreich eine Verbindung zum Tor-Netzwerk aufgebaut wurde ("Congratulations. This browser is configured to use Tor.").
- **Verifiziert 2026-10-18:** Erster Start erfolgreich — Bundle `tor-browser-linux-x86_64-15.0.25.tar.xz` heruntergeladen, GPG-Signatur geprüft, entpackt nach `~/.local/share/torbrowser/tbb/x86_64/tor-browser/`, Browser-Fenster sichtbar gestartet. Die im Log auftauchenden `qt.qpa.wayland.textinput`-Zeilen sind harmlose Qt6-Wayland-Debug-Warnungen ohne Funktionseinschränkung.

## 10. Troubleshooting & Fehler-Historie (Lern-Protokoll)
- *Nicht zutreffend / Keine Einträge*

## 11. Wartung, Updates & Rollback (Saubere Deinstallation)
- **Wartung:** Der Launcher selbst wird über `pacman -Syu` aktuell gehalten; das eigentliche Browser-Bundle aktualisiert sich beim Start eigenständig (eigener, vom System-`pacman` unabhängiger Update-Mechanismus mit eigener Signaturprüfung).
- **Vollständiger Rollback:** `sudo pacman -Rns torbrowser-launcher` sowie manuell `rm -rf ~/.config/torbrowser ~/.local/share/torbrowser` für das heruntergeladene Bundle und Profil-Reste.
