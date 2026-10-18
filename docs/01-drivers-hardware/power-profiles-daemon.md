# Power-Profiles-Daemon (Energieverwaltung)

- **Maschine / Hostname:** thinkpad
- **Kategorie:** 01-Hardware/Treiber
- **Status:** Aktiv & Stabil
- **Letztes Update:** 2026-10-18
- **Verwandte Dokumentation:** [nvidia-prime-hybrid-grafik.md](nvidia-prime-hybrid-grafik.md), [README.md](../../README.md)

---

## 1. Übersicht, Architektur & Zweck
- **Was ist das?** `power-profiles-daemon` ist ein schlanker D-Bus-Dienst, der zwischen vordefinierten System-Energieprofilen umschaltet — typischerweise `power-saver`, `balanced`, `performance`. Er setzt dafür u. a. CPU-Governor/EPP-Werte (*Energy Performance Preference*, Intel-spezifisch) und ggf. Platform-Profile (ACPI `platform_profile`, falls vom Lenovo-BIOS unterstützt).
- **Warum nutzen wir es auf dieser Maschine?** Als mobile Workstation (ThinkPad P15 Gen 2i) ist dynamisches Energiemanagement zwischen Akku- und Netzbetrieb essenziell — besonders im Zusammenspiel mit der NVIDIA-dGPU und ihrem RTD3-Verhalten (siehe [nvidia-prime-hybrid-grafik.md](nvidia-prime-hybrid-grafik.md)).
- **Offizielle Referenzen:**
  - [Arch Wiki: Power management](https://wiki.archlinux.org/title/Power_management)
  - [power-profiles-daemon GitLab (GNOME)](https://gitlab.freedesktop.org/upower/power-profiles-daemon)

## 2. Abhängigkeiten & System-Voraussetzungen
- **Pflicht-Pakete:** `power-profiles-daemon` (0.30-1, bereits installiert).
- **Hardware-Voraussetzung:** Intel Core i7-11850H (TigerLake-H) — EPP-Unterstützung über den `intel_pstate`-CPU-Treiber wird live verifiziert.

## 3. Installation & Flag-Erklärung
- *Bereits installiert und aktiv — keine Installation mehr nötig.*

## 4. System-Eingriffe (Kernel, Treiber, Boot, Berechtigungen)
- **Verifiziert 2026-10-18 via `powerprofilesctl list`:** Drei Profile verfügbar — `performance`, `balanced` (aktuell aktiv, markiert mit `*`), `power-saver`. Alle drei laufen über `CpuDriver: intel_pstate` (Intels eigener CPU-Frequenz-Treiber, löst den generischen `acpi-cpufreq`-Treiber auf Intel-Hardware ab) und `PlatformDriver: platform_profile` (generische ACPI-Schnittstelle, über die das Lenovo-BIOS Firmware-seitige Profile wie Lüfterkurven/Thermik mit beeinflussen kann). Kein Profil ist `Degraded` (d. h. alle funktionieren wie erwartet, keine fehlende Hardware-Unterstützung).

## 5. Konfiguration & Dotfiles (Deep-Dive & GNU Stow)
- *Aktuell keine manuellen Anpassungen bekannt — läuft mit Standard-Konfiguration.*

## 6. Ricing, Theming & Desktop-Integration
- *Folgt, sobald eine Profil-Umschaltung (z. B. in Waybar) im Rahmen des Hyprland-Ricings eingerichtet wird.*

## 7. Systemd, Autostart & Automatisierung
- `power-profiles-daemon.service` — system-weit `enabled`.

## 8. Dateisystem (z. B. Btrfs), Netzwerk & Sicherheit
- *Nicht zutreffend / Keine Einträge*

## 9. Verifizierung, Diagnose & Cheatsheet
- `powerprofilesctl get` / `powerprofilesctl list` — zeigt aktuelles bzw. alle verfügbaren Profile.

## 10. Troubleshooting & Fehler-Historie (Lern-Protokoll)
- *Keine Fehler — der Dienst lief bereits korrekt, als wir ihn im Rahmen der nachträglichen Dokumentation entdeckt haben.*

## 11. Wartung, Updates & Rollback (Saubere Deinstallation)
- **Vollständiger Rollback:** `sudo systemctl disable --now power-profiles-daemon.service`, danach `sudo pacman -Rns power-profiles-daemon`.
