# Bluetooth (BlueZ-Stack)

- **Maschine / Hostname:** thinkpad
- **Kategorie:** 01-Hardware/Treiber
- **Status:** Aktiv & Stabil
- **Letztes Update:** 2026-10-18
- **Verwandte Dokumentation:** [README.md](../../README.md)

---

## 1. Übersicht, Architektur & Zweck
- **Was ist das?** `BlueZ` ist der offizielle Linux-Kernel-Bluetooth-Protokollstack im Userspace (der Kernel selbst bringt nur die Low-Level-Treiber für den Bluetooth-Funk-Chip mit). `bluez` liefert die D-Bus-API und Kernlogik, `bluez-utils` die CLI-Werkzeuge (`bluetoothctl` u. a.).
- **Warum nutzen wir es auf dieser Maschine?** `bluetooth.service` ist bereits aktiv — die Maschine kann sich bereits jetzt mit Bluetooth-Geräten (Kopfhörer, Maus, Tastatur) koppeln. Das Bluetooth-Modul ist Teil des Intel Wi-Fi 6E AX210 Combo-Chips (siehe README Hardware-Profil — WLAN und Bluetooth laufen oft über denselben Chip mit gemeinsamer Antenne).
- **Offizielle Referenzen:**
  - [Arch Wiki: Bluetooth](https://wiki.archlinux.org/title/Bluetooth)
  - `man bluetoothctl`, `man bluetoothd`

## 2. Abhängigkeiten & System-Voraussetzungen
- **Pflicht-Pakete:** `bluez` (5.87-2, Kernlogik + D-Bus-Daemon `bluetoothd`), `bluez-utils` (5.87-2, CLI-Tools inkl. `bluetoothctl`) — beide bereits installiert.
- **Hardware-Voraussetzung:** Bluetooth-Funktion des Intel AX210 Combo-Chips (siehe README, WLAN-Zeile — exakte Bluetooth-Chip-Revision wird bei der Live-Prüfung über `bluetoothctl show` verifiziert).

## 3. Installation & Flag-Erklärung
- *Bereits installiert und aktiv — keine Installation mehr nötig.*

## 4. System-Eingriffe (Kernel, Treiber, Boot, Berechtigungen)
- **Controller-Status (verifiziert 2026-10-18 via `bluetoothctl show`):** Controller `00:93:37:1E:F7:CA` erkannt, Name/Alias `thinkpad`, `Powered: yes`, `PowerState: on`, `Discoverable: no`, `Pairable: no`. Rollen: `central` + `peripheral`. Unterstützt BLE-Erweiterungen (`SupportedSecondaryChannels: 1M/2M/Coded`, `HardwareOffload`).
  - **Was bedeutet `Discoverable: no` / `Pairable: no`?** Sicherer Default-Zustand: Das Gerät sendet sich nicht aktiv als koppelbar an die Umgebung — ein neues Gerät kann nur gekoppelt werden, wenn du aktiv `bluetoothctl discoverable on`/`pairable on` ausführst (oder ein GUI-Tool das für dich tut). Verhindert ungewollte Kopplungsversuche durch fremde Geräte in Reichweite.
- **rfkill-Status (verifiziert 2026-10-18):** Drei Funk-Schalter erkannt: `tpacpi_bluetooth_sw` (ThinkPad-ACPI-spezifischer Soft-Switch für Bluetooth, vom Lenovo-eigenen `thinkpad_acpi`-Kernelmodul bereitgestellt), `hci0` (der eigentliche Bluetooth-Controller) und `phy0` (WLAN) — alle drei `Soft blocked: no`, `Hard blocked: no` (nichts blockiert, Funk ist aktiv nutzbar).

## 5. Konfiguration & Dotfiles (Deep-Dive & GNU Stow)
- **System-Konfigurationsdatei (kein Stow):** `/etc/bluetooth/main.conf` — läuft mit Datei-Defaults, keine manuellen Anpassungen vorhanden/nötig.
- **Nutzer-seitige gekoppelte Geräte:** Werden aktuell NICHT geprüft (Datenschutz — Geräte-Pairings sind pro Maschine individuell und nicht Teil der Dokumentation, nur die Dienst-Konfiguration selbst).

## 6. Ricing, Theming & Desktop-Integration
- *Folgt, sobald ein Bluetooth-GUI-Applet (z. B. `blueman` oder eine Waybar-Integration) im Rahmen des Hyprland-Ricings eingerichtet wird.*

## 7. Systemd, Autostart & Automatisierung
- `bluetooth.service` — system-weit `enabled`, startet `bluetoothd` beim Boot.

## 8. Dateisystem (z. B. Btrfs), Netzwerk & Sicherheit
- *Nicht zutreffend / Keine Einträge*

## 9. Verifizierung, Diagnose & Cheatsheet
- `bluetoothctl show` — Zeigt Controller-Status (Powered, Discoverable, Pairable) und Adapter-Informationen.
- `rfkill list` — Zeigt, ob Bluetooth (oder WLAN) per Hardware-/Software-Schalter blockiert ist.
- `bluetoothctl scan on` / `bluetoothctl pair <MAC>` — neues Gerät suchen und koppeln (Alltags-Workflow über CLI, bis ein GUI-Applet eingerichtet ist).

## 10. Troubleshooting & Fehler-Historie (Lern-Protokoll)
- *Keine Fehler — Bluetooth lief bereits korrekt, als wir es im Rahmen der nachträglichen Dokumentation entdeckt haben.*

## 11. Wartung, Updates & Rollback (Saubere Deinstallation)
- **Vollständiger Rollback:** `sudo systemctl disable --now bluetooth.service`, danach `sudo pacman -Rns bluez bluez-utils`.
