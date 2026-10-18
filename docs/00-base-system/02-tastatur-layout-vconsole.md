# Tastatur-Layout der virtuellen Konsole (vconsole / TTY-Keymap)

- **Maschine / Hostname:** thinkpad
- **Kategorie:** 00-Base
- **Status:** In Einrichtung
- **Letztes Update:** 2026-10-18
- **Verwandte Dokumentation:** [README.md](../../README.md), [nvidia-prime-hybrid-grafik.md](../01-drivers-hardware/nvidia-prime-hybrid-grafik.md)

---

## 1. Übersicht, Architektur & Zweck
- **Was ist das?** Das Tastatur-Layout der **virtuellen Konsole** (*VC Keymap*) bestimmt, welches Zeichen der Kernel/die Konsole an das darüberliegende Programm (z. B. `bash`) sendet, wenn eine bestimmte physische Taste gedrückt wird — **bevor** überhaupt ein grafischer Compositor oder X11/Wayland-Keymaps ins Spiel kommen. Diese Einstellung ist komplett getrennt von späteren GUI-Tastatur-Einstellungen (die wir separat bei der Hyprland-Einrichtung dokumentieren werden) und wird über das Systemd-Tool `systemd-vconsole-setup` beim Boot anhand der Datei `/etc/vconsole.conf` gesetzt.
- **Warum nutzen wir es auf dieser Maschine?** Ohne korrekt gesetztes Layout interpretiert die Konsole physische Tastendrücke nach dem Kernel-Standardlayout (`us`, QWERTY), während das `thinkpad`-Notebook physisch ein **deutsches QWERTZ-Layout** besitzt. Das führt zu vertauschten/falschen Zeichen bei allen nicht-alphanumerischen Tasten (`{`, `}`, `|`, `@`, `[`, `]`, `\`, `~`, teils auch `(`/`)` je nach Tastenkombination) — genau das hat bei uns reproduzierbare Bash-Syntaxfehler (`unexpected token ')'`) beim manuellen Abtippen von Befehlen mit geschweiften Klammern ausgelöst.
- **Offizielle Referenzen:**
  - [Arch Wiki: Keyboard configuration in console](https://wiki.archlinux.org/title/Keyboard_configuration_in_console)
  - [Arch Wiki: Installation guide #Console keymap](https://wiki.archlinux.org/title/Installation_guide#Keyboard)
  - `man vconsole.conf`, `man loadkeys`

## 2. Abhängigkeiten & System-Voraussetzungen
- **Pflicht-Pakete:** Keine zusätzlichen Pakete nötig — `kbd` (enthält `loadkeys`) sowie `systemd-vconsole-setup` sind Bestandteil jeder Basis-Arch-Installation.
- **Optionale Pakete:** *Nicht zutreffend / Keine Einträge*
- **Hardware- & System-Voraussetzungen:** Physische deutsche QWERTZ-Tastatur (intern verbaut im ThinkPad P15 Gen 2i).

## 3. Installation & Flag-Erklärung

### 3.1 Sofort-Test im laufenden System (temporär, nicht dauerhaft)
```bash
loadkeys de-latin1
```
- `loadkeys`: Lädt eine Tastatur-Belegungstabelle (*Keymap*) direkt in den Kernel-Tastaturtreiber der aktuellen Konsolen-Sitzung.
- `de-latin1`: Name der Standard-Keymap-Tabelle für deutsche Tastaturen (Datei liegt unter `/usr/share/kbd/keymaps/.../de-latin1.map.gz`).
- **Wichtig:** Diese Änderung ist **nur für die aktuelle Sitzung** gültig und geht nach einem Neustart wieder verloren — sie dient hier ausschließlich als sofortiger Test, ob `de-latin1` das Problem behebt, bevor wir es dauerhaft konfigurieren.

## 4. System-Eingriffe (Kernel, Treiber, Boot, Berechtigungen)
- **Dauerhafte Konfiguration über `/etc/vconsole.conf`:** Diese Datei wird von `systemd-vconsole-setup` bei jedem Boot gelesen und setzt dort automatisch die Konsolen-Keymap, bevor eine Login-Shell erscheint — manuelles `loadkeys` nach jedem Neustart entfällt dadurch.
- **Technischer Hintergrund:** `systemd-vconsole-setup` ist ein früher Boot-Dienst, der noch vor dem eigentlichen Login ausgeführt wird (ähnlich wie das Setzen der Root-Dateisystem-Mounts). Er liest `/etc/vconsole.conf` und ruft intern denselben Mechanismus wie `loadkeys` auf, aber automatisiert und dauerhaft bei jedem Systemstart.

## 5. Konfiguration & Dotfiles (Deep-Dive & GNU Stow)
- **System-Konfigurationsdatei (manuell von dir anzulegen, NICHT per Stow, da unterhalb `/etc/`):** `/etc/vconsole.conf`

**Konfigurations-Block (Vorlage zur manuellen Übernahme):**
```ini
# /etc/vconsole.conf
# Tastatur-Layout der virtuellen Konsole (TTY) -- unabhängig von GUI-Keymaps!
KEYMAP=de-latin1

# Optional: Zeichensatz der Konsole (meist nicht nötig, da UTF-8 heute Standard ist
# und der Kernel/die Konsole dies in aller Regel automatisch korrekt erkennt)
# FONT=
```

**Detail-Erklärung der Parameter (Was, Warum, Nutzen):**
- `KEYMAP=de-latin1`: Setzt dieselbe Tastatur-Belegungstabelle wie der Sofort-Test in Abschnitt 3.1, aber dauerhaft bei jedem Boot. **Nutzen:** Jeder zukünftige Tastendruck im TTY wird korrekt gemäß dem physisch verbauten deutschen Tastatur-Layout interpretiert — behebt die Ursache der zuvor aufgetretenen Syntaxfehler vollständig und dauerhaft.
- **Maschinen-Spezifische Werte:** Der Wert `de-latin1` ist an das physische Tastatur-Layout des jeweiligen Geräts gebunden (nicht an Hostname/Hardware-Chipsätze) — bei einer Maschine mit US-Tastatur müsste hier stattdessen z. B. `us` stehen. Beim Übertragen dieser Konfiguration in ein anderes Maschinen-Repo immer das dort tatsächlich physisch verbaute Tastatur-Layout prüfen.
- **Stow-Befehl:** *Nicht zutreffend* — `/etc/vconsole.conf` liegt außerhalb von `~/` und wird daher laut unserer Architektur **nicht** über GNU Stow verwaltet, sondern bleibt eine klassische, manuell editierte System-Konfigurationsdatei unter `/etc/`.

## 6. Ricing, Theming & Desktop-Integration
- *Nicht zutreffend / Keine Einträge* (betrifft ausschließlich die reine TTY-Konsole vor jeder GUI; die GUI-seitige Tastatur-Konfiguration für Hyprland/Wayland wird in der jeweiligen Hyprland-Dokumentation separat behandelt, da Wayland-Compositors ihre eigene Keymap-Konfiguration nutzen).

## 7. Systemd, Autostart & Automatisierung
- **Systemd-Service:** `systemd-vconsole-setup.service` (Teil von `systemd` selbst, kein eigenes Unit-File von uns nötig) liest `/etc/vconsole.conf` automatisch bei jedem Boot aus — keine manuelle Aktivierung notwendig.

## 8. Dateisystem (z. B. Btrfs), Netzwerk & Sicherheit
- *Nicht zutreffend / Keine Einträge*

## 9. Verifizierung, Diagnose & Cheatsheet

### 9.1 Funktionsprüfung
```bash
localectl status
```
- In der Ausgabe muss die Zeile `VC Keymap: de-latin1` erscheinen.

### 9.2 Cheatsheet
- `loadkeys de-latin1`: Temporärer Keymap-Wechsel für die aktuelle Sitzung (z. B. zum schnellen Testen).
- `localectl status`: Zeigt sowohl die System-Locale als auch die aktuell aktive VC-Keymap an.

## 10. Troubleshooting & Fehler-Historie (Lern-Protokoll)

### [2026-10-18] - Reproduzierbare Bash-Syntaxfehler (`unexpected token ')'`) bei manuell abgetippten Befehlen
- **Symptom / Fehlermeldung:** Mehrere Diagnose-Befehle mit geschweiften Klammern (`{ ... }`-Gruppierung) scheiterten reproduzierbar mit `syntax error near unexpected token ')'` — sowohl beim Copy-Paste als auch beim manuellen Abtippen.
- **Technische Ursache (Root Cause):** `/etc/vconsole.conf` existierte nicht, die virtuelle Konsole lief seit der Installation mit dem Kernel-Standardlayout (`us`), während physisch eine deutsche QWERTZ-Tastatur verbaut ist. Dadurch erzeugten Tastendrücke für bestimmte Sonderzeichen falsche/vertauschte Zeichen gegenüber dem, was auf dem Bildschirm angezeigt bzw. tatsächlich an die Shell übergeben wurde.
- **Gescheiterte Ansätze & Lerneffekt:** Zunächst wurde ein Copy-Paste-Zeichenkodierungsproblem (Unicode-Gedankenstrich statt `--`) vermutet, da ein ähnlicher Effekt beim `--noconfirm`-Fehler zuvor tatsächlich diese Ursache hatte. Das manuelle Abtippen des Befehls zeigte jedoch denselben Fehler — was Copy-Paste-Probleme endgültig ausschloss und auf die Tastatur-/Konsolen-Ebene selbst verwies. **Lerneffekt:** Bei reproduzierbaren Sonderzeichen-Fehlern, die sowohl beim Einfügen *als auch* beim manuellen Tippen auftreten, liegt die Ursache typischerweise nicht im Text selbst, sondern in der Eingabe-Interpretation (Tastatur-Layout) — ein Basis-System-Check (`localectl status`, `/etc/vconsole.conf`), der eigentlich schon ganz am Anfang der Einrichtung hätte erfolgen müssen.
- **Finale Lösung:** Dauerhafte Konfiguration von `KEYMAP=de-latin1` in `/etc/vconsole.conf` (siehe Abschnitt 5), nach sofortigem Test via `loadkeys de-latin1`.

## 11. Wartung, Updates & Rollback (Saubere Deinstallation)
- **Wartung:** Keine laufende Wartung nötig; die Einstellung bleibt unabhängig von Paket-Updates stabil, da sie keine Pakete, sondern nur eine Konfigurationsdatei betrifft.
- **Vollständiger Rollback:** `/etc/vconsole.conf` löschen oder `KEYMAP=`-Zeile entfernen — die Konsole fällt dann beim nächsten Boot wieder auf das Kernel-Standardlayout (`us`) zurück.
