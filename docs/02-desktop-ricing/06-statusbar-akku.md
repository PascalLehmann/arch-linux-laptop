# Statusbar-Modul: Akku-Anzeige (UPower)

- **Maschine / Hostname:** thinkpad
- **Kategorie:** 02-Ricing
- **Status:** In Einrichtung
- **Letztes Update:** 2026-10-18
- **Verwandte Dokumentation:** [04-quickshell.md](04-quickshell.md) (Basis-Bar & 3-Zonen-Layout), [07-statusbar-powerbutton.md](07-statusbar-powerbutton.md), [README.md](../../README.md)

---

## 1. Übersicht, Architektur & Zweck
- **Was ist das?** Ein Icon+Prozent-Anzeige-Modul in der rechten Zone der Quickshell-Bar (siehe [04-quickshell.md](04-quickshell.md), Abschnitt 5), das den aktuellen Akku-Ladezustand dieses Laptops live anzeigt. Technisch bindet Quickshell dafür **nicht** direkt `/sys/class/power_supply/` ein, sondern den D-Bus-Systemdienst **UPower** (`upower.service`) über ein eigenes, mitgeliefertes QML-Service-Modul: `import Quickshell.Services.UPower`. Dieses Modul stellt ein Singleton-Objekt `UPower` bereit mit den Properties `devices` (Liste aller erkannten Geräte), `onBattery` (bool, läuft das System gerade im Akku-Betrieb) und `displayDevice` — Letzteres ist das für uns relevante Objekt: ein aggregiertes `UPowerDevice`, das exakt dem entspricht, was auch normale Desktop-Umgebungen (GNOME, KDE) für ihre Akku-Anzeige verwenden, unabhängig davon, wie viele einzelne Batterie-Geräte das System tatsächlich meldet.
- **Relevante `UPowerDevice`-Properties (laut offizieller Doku, Version 0.3.2 — siehe Referenzen):**
  - `percentage` (real): Ladezustand in Prozent, äquivalent zu `energy / energyCapacity`.
  - `state` (Enum `UPowerDeviceState`): u. a. `Charging`, `Discharging`, `FullyCharged`, `PendingCharge`, `PendingDischarge`, `Empty`, `Unknown`.
  - `isLaptopBattery` (bool): `true`, wenn `type == Battery && powerSupply == true` — damit lässt sich das Anzeige-Gerät von z. B. einer angeschlossenen Bluetooth-Maus-Batterie unterscheiden.
  - `timeToEmpty` / `timeToFull` (real, Sekunden): Restlaufzeit bis leer bzw. bis voll (je nach `state` ist einer der beiden Werte `0`).
  - `ready` (bool): `true`, sobald die Statistiken tatsächlich abgefragt wurden — **wichtig:** `displayDevice` kann initial zurückgegeben werden, bevor es `ready` ist; jeder Zugriff auf `percentage`/`state` sollte das berücksichtigen, um kurz nach dem Start keine falschen "0%"-Anzeigen zu zeigen.
- **Warum nutzen wir es auf dieser Maschine?** Das ThinkPad P15 Gen 2i (siehe `README.md`, Hardware-Steckbrief) ist ein mobiles Gerät mit internem Akku — eine Ladezustands-Anzeige ist damit ein Kern-Feature jeder Statusbar, nicht optionales Ricing. Da wir bewusst keine fertige Desktop-Umgebung nutzen (siehe [01-hyprland.md](01-hyprland.md)), gibt es ohne dieses Modul **keine** Akku-Anzeige im System.
- **Offizielle Referenzen:**
  - [Quickshell-Doku: `Quickshell.Services.UPower/UPower`](https://quickshell.org/docs/v0.3.2/types/Quickshell.Services.UPower/UPower) (Singleton)
  - [Quickshell-Doku: `Quickshell.Services.UPower/UPowerDevice`](https://quickshell.org/docs/v0.3.2/types/Quickshell.Services.UPower/UPowerDevice) (Properties)
  - [Arch Wiki: UPower](https://wiki.archlinux.org/title/Power_management#UPower)

## 2. Abhängigkeiten & System-Voraussetzungen
- **Pflicht-Pakete:**
  - `quickshell` — bereits installiert (siehe [04-quickshell.md](04-quickshell.md)), bringt das `Quickshell.Services.UPower`-QML-Modul bereits mit (keine separate Installation dieses QML-Moduls nötig).
  - `upower` — der eigentliche D-Bus-Dienst, der die Hardware-Daten aus `/sys/class/power_supply/` ausliest und über D-Bus bereitstellt. **Muss noch live verifiziert werden, ob bereits installiert/aktiv ist** (siehe Schritt 1 im Chat) — ohne laufenden `upower.service` liefert `UPower.displayDevice` keine sinnvollen Werte.
- **Hardware-Voraussetzung:** Interner Akku vorhanden (ThinkPad P15 Gen 2i, laut Hardware-Steckbrief in `README.md`) — `isLaptopBattery` sollte für genau ein Gerät `true` liefern.

## 3. Installation & Flag-Erklärung
- **Status (verifiziert 2026-10-18):** `upower` war bereits installiert und `upower.service` aktiv (`systemctl status upower.service` → `active (running)`, D-Bus-aktiviert, `disabled` im Sinne von "kein expliziter Boot-Autostart" ist hier unproblematisch). Keine weitere Installation nötig.

## 4. System-Eingriffe (Kernel, Treiber, Boot, Berechtigungen)
- *Nicht zutreffend / Keine Einträge* (reiner D-Bus-Zugriff über einen bereits laufenden System-Dienst, kein Kernel-/Treiber-Bezug).

## 5. Konfiguration & Dotfiles (Deep-Dive & GNU Stow)
- **Kein eigenes Stow-Paket:** Dieses Modul ist ausschließlich zusätzlicher QML-Code innerhalb der bereits bestehenden `dotfiles/quickshell/.config/quickshell/shell.qml` (siehe [04-quickshell.md](04-quickshell.md), Abschnitt 5) — kein neuer Pfad, keine neue Datei.
- **Konfigurations-Block (verifiziert 2026-10-18 — innerhalb von `rightSection`, siehe [04-quickshell.md](04-quickshell.md) Abschnitt 5):**
  ```qml
  // Zusätzlicher Import ganz oben in shell.qml, neben "import Quickshell"/"import QtQuick":
  import Quickshell.Services.UPower

  // Als Kind-Element von "rightSection":
  Text {
      id: batteryText
      color: "#ffffff"
      font.pixelSize: 14
      text: {
          var dev = UPower.displayDevice
          if (!dev.ready) return "…"
          var pct = Math.round(dev.percentage * 100)
          var stateLabel = ""
          switch (dev.state) {
              case UPowerDeviceState.Charging:         stateLabel = "Lädt"; break
              case UPowerDeviceState.Discharging:      stateLabel = "Entlädt"; break
              case UPowerDeviceState.FullyCharged:     stateLabel = "Voll"; break
              case UPowerDeviceState.PendingCharge:    stateLabel = "Wartet (Laden)"; break
              case UPowerDeviceState.PendingDischarge: stateLabel = "Wartet (Entladen)"; break
              case UPowerDeviceState.Empty:             stateLabel = "Leer"; break
              default:                                  stateLabel = "Unbekannt"; break
          }
          return pct + "% [" + stateLabel + "]"
      }
  }
  ```
- **Detail-Erklärung (Was/Warum/Nutzen):**
  - `UPower.displayDevice`: Singleton-Zugriff auf das aggregierte Akku-Gerät (siehe Abschnitt 1) — kein manuelles Durchsuchen von `UPower.devices` nach dem richtigen Gerät nötig.
  - `if (!dev.ready) return "…"`: Schutz gegen den in Abschnitt 1 beschriebenen Fall, dass `displayDevice` initial zurückgegeben wird, bevor die D-Bus-Abfrage abgeschlossen ist — ohne diese Prüfung würde kurz nach dem Start fälschlich `0%` erscheinen.
  - `dev.percentage * 100`: **Wichtige, live verifizierte Erkenntnis** (siehe Abschnitt 10) — Quickshells `percentage`-Property liefert einen Bruch zwischen `0` und `1`, nicht die 0–100-Skala des rohen UPower-D-Bus-Protokolls (`upower -i` zeigt `79%`, ohne `* 100` hätte die Bar `1%` gezeigt).
  - `switch (dev.state)` gegen benannte `UPowerDeviceState.*`-Werte statt gegen eine Zahl: Enum-Werte würden bei direkter String-Interpolation nur als Ordinalzahl erscheinen (z. B. `5`) — der symbolische Vergleich ist unabhängig von der internen Deklarationsreihenfolge des Enums und bleibt auch über Quickshell-Versionsgrenzen hinweg lesbar/stabil.
- **Maschinen-Spezifische Werte:** Keine festen Werte — `UPower.displayDevice` ermittelt automatisch das richtige Gerät (`BAT0` auf diesem ThinkPad), unabhängig vom konkreten `native-path`-Namen.

## 6. Ricing, Theming & Desktop-Integration
- *Folgt — insbesondere Icon-Auswahl je `state` (z. B. unterschiedliche Glyphen für Laden/Entladen/Voll) und Farb-Warnung bei niedrigem Ladezustand.*

## 7. Systemd, Autostart & Automatisierung
- **`upower.service`:** Läuft als System-weiter D-Bus-Dienst (kein User-Service), typischerweise über D-Bus-Aktivierung automatisch gestartet, sobald ein Client (hier: Quickshell) eine Anfrage stellt — kein manueller Autostart-Eintrag in Hyprland nötig.

## 8. Dateisystem (z. B. Btrfs), Netzwerk & Sicherheit
- *Nicht zutreffend / Keine Einträge*

## 9. Verifizierung, Diagnose & Cheatsheet
- `systemctl status upower.service` — prüft, ob/dass der Dienst läuft.
- `upower -i $(upower -e | grep BAT)` — zeigt die rohen UPower-Daten des Akku-Geräts direkt auf der Kommandozeile, zum Abgleich mit dem, was in der Bar erscheint.
- **Verifiziert 2026-10-18:** Bar zeigte `79% [Wartet (Laden)]`, `upower -i` zeigte zeitgleich `percentage: 79%` / `state: pending-charge` — Werte stimmen exakt überein. (Nebenbefund: Der Zustand "pending-charge" bei bereits 79% erklärt sich durch die auf diesem Gerät aktiven ThinkPad-Lade-Schwellenwerte `charge-start-threshold: 75%` / `charge-end-threshold: 80%` aus dem `upower -i`-Output — das Laden pausiert bewusst oberhalb von 75%, bis die Marke von 80% für einen neuen Ladezyklus unterschritten wird. Rein informativ, kein Bug.)

## 10. Troubleshooting & Fehler-Historie (Lern-Protokoll)

### [2026-10-18] - Akku-Anzeige zeigt `1%` statt echter `79%`
- **Symptom:** Nach erstem Einbau des Akku-Moduls zeigte die Bar `1%`, während `upower -i` zeitgleich `79%` auswies.
- **Technische Ursache (Root Cause):** Die Quickshell-Property `UPowerDevice.percentage` liefert laut Doku einen Bruch (`energy / energyCapacity`, Bereich 0–1), nicht die 0–100-Skala des rohen UPower-D-Bus-Protokolls. `Math.round(0.79)` ergibt `1` — exakt der beobachtete Fehler.
- **Gescheiterte Ansätze & Lerneffekt:** Keine — der Fehler wurde durch bewussten Abgleich mit `upower -i` als Referenzwert sofort beim ersten Test erkannt, statt die Quickshell-Doku-Beschreibung ungeprüft zu übernehmen. Lerneffekt: Bei neu integrierten externen Daten-Properties immer gegen eine unabhängige Referenzquelle (hier: das CLI-Tool `upower`) verifizieren, bevor man die Anzeige als korrekt annimmt.
- **Finale Lösung:** `dev.percentage * 100` statt `dev.percentage` vor dem Runden (siehe Abschnitt 5).

## 11. Wartung, Updates & Rollback (Saubere Deinstallation)
- **Rollback:** Entsprechenden QML-Block (Akku-`Row`-Kind-Element) aus `shell.qml` entfernen. Kein Paket-Rollback nötig, falls `upower` bereits für andere Zwecke (z. B. Power-Profiles-Daemon-Integration) gebraucht wird — nur bei alleiniger Nutzung für dieses Modul ggf. `sudo pacman -Rns upower` erwägen.
