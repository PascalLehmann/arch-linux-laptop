# CUPS (Druckerverwaltung)

- **Maschine / Hostname:** thinkpad
- **Kategorie:** 05-Services
- **Status:** Aktiv & Stabil
- **Letztes Update:** 2026-10-18
- **Verwandte Dokumentation:** [README.md](../../README.md)

---

## 1. Übersicht, Architektur & Zweck
- **Was ist das?** `CUPS` (*Common Unix Printing System*) ist der Standard-Druckdienst unter Linux. Er läuft als Hintergrund-Daemon (`cupsd`), der Druckaufträge entgegennimmt, über Treiber/PPD-Dateien (*PostScript Printer Description*) in das jeweilige Drucker-Format konvertiert und an lokale (USB) oder Netzwerk-Drucker weiterleitet. `ghostscript` wird als PostScript-/PDF-Interpreter für die Konvertierung benötigt. `system-config-printer` ist eine grafische Verwaltungsoberfläche, `cups-pk-helper` eine Polkit-Integration (erlaubt unprivilegierten Usern über eine Berechtigungsabfrage Drucker-Einstellungen zu ändern, ohne direkt root-Rechte zu benötigen).
- **Warum nutzen wir es auf dieser Maschine?** `cups.service`/`cups.socket`/`cups.path` sind bereits aktiv — die Maschine ist also bereits druckfähig vorbereitet, auch wenn aktuell kein Grafik-Stack zur Bedienung von `system-config-printer` vorhanden ist (folgt mit Hyprland).
- **Offizielle Referenzen:**
  - [Arch Wiki: CUPS](https://wiki.archlinux.org/title/CUPS)
  - [CUPS-Dokumentation (OpenPrinting)](https://openprinting.github.io/cups/)

## 2. Abhängigkeiten & System-Voraussetzungen
- **Pflicht-Pakete:** `cups` (2:2.4.20-1), `cups-pk-helper` (0.2.7-2), `system-config-printer` (1.5.18-7), `ghostscript` (10.08.0-1) — alle bereits installiert.
- **Hardware-Voraussetzung:** Keine spezifische — abhängig vom tatsächlich angeschlossenen/genutzten Drucker (aktuell keiner bekannt/eingerichtet).

## 3. Installation & Flag-Erklärung
- *Bereits installiert und aktiv — keine Installation mehr nötig.*

## 4. System-Eingriffe (Kernel, Treiber, Boot, Berechtigungen)
- **Gruppenmitgliedschaft:** Normale Druckerverwaltung über die Gruppe `sys` oder `lp` (abhängig von CUPS-Policy) — wird bei Bedarf (sobald ein konkreter Drucker eingerichtet wird) live verifiziert.

## 5. Konfiguration & Dotfiles (Deep-Dive & GNU Stow)
- **System-Konfigurationsdatei (kein Stow):** `/etc/cups/cupsd.conf` — läuft mit Datei-Defaults.
- **Druckziele (verifiziert 2026-10-18 via `lpstat -p`):** `lpstat: Keine Druckziele hinzugefügt.` — Der Dienst selbst läuft korrekt, es ist aber aktuell **kein einziger Drucker konfiguriert**. Erwartungsgemäßer Zustand, kein Fehler — wird nachgeholt, sobald tatsächlich ein Drucker angeschlossen/eingerichtet wird (dann voraussichtlich über `system-config-printer`, sobald die Hyprland-Session steht).

## 6. Ricing, Theming & Desktop-Integration
- *Folgt, sobald `system-config-printer` über Hyprland tatsächlich genutzt wird (GUI-Anwendung, Kategorie 04-Apps).*

## 7. Systemd, Autostart & Automatisierung
- `cups.service` (Haupt-Daemon), `cups.socket` (Socket-Aktivierung — startet `cupsd` erst bei Bedarf, statt dauerhaft im Hintergrund zu laufen), `cups.path` (überwacht Verzeichnisänderungen, um bei Bedarf neu zu starten) — alle `enabled`.

## 8. Dateisystem (z. B. Btrfs), Netzwerk & Sicherheit
- **Netzwerk:** CUPS kann auch Netzwerkdrucker/IPP-Freigaben bedienen — aktueller Freigabe-Status noch nicht verifiziert.

## 9. Verifizierung, Diagnose & Cheatsheet
- `lpstat -p` — Zeigt konfigurierte Drucker und deren Status.
- `systemctl status cups.service` — Laufzeitstatus.
- Web-UI: `http://localhost:631` (CUPS bringt eine eigene lokale Verwaltungsoberfläche mit, auch ohne Desktop nutzbar).

## 10. Troubleshooting & Fehler-Historie (Lern-Protokoll)
- *Keine Fehler — der Dienst lief bereits korrekt (nur ohne konfigurierte Drucker), als wir ihn im Rahmen der nachträglichen Dokumentation entdeckt haben.*

## 11. Wartung, Updates & Rollback (Saubere Deinstallation)
- **Vollständiger Rollback:** `sudo systemctl disable --now cups.service cups.socket cups.path`, danach `sudo pacman -Rns cups cups-pk-helper system-config-printer`. **Hinweis:** `ghostscript` wird häufig auch von anderen Programmen (PDF-Verarbeitung) benötigt — vor dem Entfernen mit `pacman -Qi ghostscript` prüfen, ob noch etwas anderes davon abhängt.
