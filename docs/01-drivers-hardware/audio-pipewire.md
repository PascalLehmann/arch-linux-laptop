# Audio-Stack (PipeWire)

- **Maschine / Hostname:** thinkpad
- **Kategorie:** 01-Hardware/Treiber
- **Status:** In Einrichtung
- **Letztes Update:** 2026-10-18
- **Verwandte Dokumentation:** [README.md](../../README.md)

---

## 1. Übersicht, Architektur & Zweck
- **Was ist das?** `PipeWire` ist der moderne Audio- (und Video-)Server unter Linux, der sowohl den klassischen `PulseAudio` als auch `JACK` (Pro-Audio-Routing) ersetzt. Er sitzt zwischen den Kernel-Audio-Treibern (`ALSA`, *Advanced Linux Sound Architecture* — die Kernel-Schnittstelle zur Hardware) und den Anwendungen, und übernimmt Mischung, Routing und Geräte-Verwaltung. `wireplumber` ist die Session-/Policy-Verwaltung darüber (entscheidet z. B., welches Gerät Standard-Ausgabe ist, verwaltet automatische Verbindungen). Die Kompatibilitäts-Shims `pipewire-alsa`, `pipewire-jack`, `pipewire-pulse` lassen Programme, die nur klassisches ALSA/JACK/PulseAudio kennen, transparent über PipeWire laufen.
- **Warum nutzen wir es auf dieser Maschine?** Bereits aktiv als User-Services (`wireplumber.service`, `pipewire.socket`, `pipewire-pulse.socket`) — der vollständige Audio-Stack läuft, bevor überhaupt ein Desktop/Compositor vorhanden ist. Passt zur Hardware (siehe README): Intel SOF-Audio-Stack (`sof-audio-pci-intel-tgl`) für die internen Lautsprecher/Mikrofon, plus NVIDIA-HDMI/DP-Audio für externe Displays.
- **Offizielle Referenzen:**
  - [Arch Wiki: PipeWire](https://wiki.archlinux.org/title/PipeWire)
  - [PipeWire-Dokumentation](https://docs.pipewire.org/)

## 2. Abhängigkeiten & System-Voraussetzungen
- **Pflicht-Pakete:** `pipewire`, `pipewire-alsa`, `pipewire-jack`, `pipewire-pulse`, `wireplumber`, `libpulse`, `gst-plugin-pipewire` (GStreamer-Integration), `sof-firmware` (Firmware-Blobs für den Intel SOF-DSP) — alle bereits installiert.
- **Hardware-Voraussetzung:** Intel 500-Series HD Audio (SOF-Stack) + NVIDIA HDMI/DP-Audio (siehe README Hardware-Profil).

## 3. Installation & Flag-Erklärung
- *Bereits installiert und aktiv — keine Installation mehr nötig.*

## 4. System-Eingriffe (Kernel, Treiber, Boot, Berechtigungen)
- **Gruppenmitgliedschaft:** Klassisch wäre die Gruppe `audio` relevant — bei PipeWire mit `systemd --user`-Services meist nicht mehr zwingend nötig (läuft im User-Kontext). Wird live verifiziert.

## 5. Konfiguration & Dotfiles (Deep-Dive & GNU Stow)
- **Aktuell keine manuellen Anpassungen bekannt** (kein `~/.config/pipewire` oder `~/.config/wireplumber` bisher geprüft) — läuft mit Standard-Konfiguration aus `/usr/share/pipewire/` bzw. `/usr/share/wireplumber/`. Wird bei Bedarf (z. B. spezifisches Sample-Rate-/Latenz-Tuning) ergänzt.

## 6. Ricing, Theming & Desktop-Integration
- *Folgt, sobald eine Lautstärke-Kontrolle (z. B. in Waybar) im Rahmen des Hyprland-Ricings eingerichtet wird.*

## 7. Systemd, Autostart & Automatisierung
- **User-Services (nicht system-weit!):** `wireplumber.service`, `pipewire.socket`, `pipewire-pulse.socket`, `p11-kit-server.socket` — laufen über `systemd --user`, d. h. erst nach dem Login eines Benutzers, nicht bereits beim System-Boot. **Technischer Hintergrund:** Audio ist eine pro-Benutzer-Ressource (jeder eingeloggte User bekommt seine eigene PipeWire-Instanz), daher `--user`-Scope statt system-weitem Service.

## 8. Dateisystem (z. B. Btrfs), Netzwerk & Sicherheit
- *Nicht zutreffend / Keine Einträge*

## 9. Verifizierung, Diagnose & Cheatsheet
- `wpctl status` — WirePlumber-CLI, zeigt alle Audio-/Video-Geräte, Standard-Sink/-Source, aktuelle Lautstärke.
- `pactl info` — Zeigt, dass der (emulierte) PulseAudio-Server tatsächlich von PipeWire bereitgestellt wird (`Server Name: PulseAudio (on PipeWire ...)`).
- `systemctl --user status wireplumber.service` — Laufzeitstatus.

## 10. Troubleshooting & Fehler-Historie (Lern-Protokoll)

### [2026-10-18] - `wpctl status` zeigt keine Audio-Geräte (leere Sinks/Sources/Devices)
- **Symptom / Befund:** `wpctl status` läuft fehlerfrei und zeigt den PipeWire-Server samt laufender Clients (`wpctl`, `WirePlumber`), aber die Abschnitte `Audio → Devices/Sinks/Sources` und `Video → Devices/Sinks/Sources` sind **komplett leer** — keine internen Lautsprecher, kein Mikrofon erkannt, obwohl laut README-Hardware-Profil ein Intel-SOF-Audio-Chip (`sof-audio-pci-intel-tgl`) vorhanden ist und `sof-firmware` installiert ist.
- **Zusätzlicher Befund:** Beim Start trat wiederholt `RTKit error: org.freedesktop.DBus.Error.ServiceUnknown` auf — der `rtkit`-Daemon (RealtimeKit, vergibt Echtzeit-Priorität an Audio-Threads für störungsfreie Wiedergabe) ist **nicht installiert** (kein `rtkit` in `pacman -Qe`/Abhängigkeitsbaum). PipeWire fällt dadurch auf niedrigere, nicht-echtzeitfähige Thread-Priorität zurück (`using 1` statt der eigentlich gewünschten höheren Priorität) — ein Performance-/Stabilitäts-Nachteil bei Audio unter Last, aber **nicht** die Ursache für die fehlenden Geräte selbst.
- **Technische Ursache (Root Cause) — noch nicht abschließend geklärt:** Mögliche Hypothesen, die wir noch nicht geprüft haben:
  1. Die Diagnose wurde direkt auf der TTY ausgeführt, ohne dass die `sof-audio-pci-intel-tgl`-Kernelmodule tatsächlich geladen sind (`lsmod | grep snd` noch nicht geprüft).
  2. `/proc/asound/cards` könnte zeigen, ob ALSA überhaupt eine Soundkarte sieht — falls dort nichts erscheint, ist es ein Kernel-/Firmware-Problem, nicht PipeWire selbst.
  3. Mangelnde `systemd-logind`-Seat-Zuweisung in der aktuellen TTY-Session (ohne volle grafische Session könnte PipeWire/WirePlumber noch nicht alle Geräte-Rechte erhalten haben).
- **Gescheiterte Ansätze & Lerneffekt:** Noch keine Lösungsversuche unternommen — wird nach dem Hyprland/SDDM-Login erneut geprüft, da eine vollständige grafische Session ggf. die fehlende Seat-Zuweisung (Hypothese 3) von selbst behebt.
- **Finale Lösung:** *Noch offen.* Nächster Diagnose-Schritt (nach dem Desktop-Login): `lsmod | grep snd`, `cat /proc/asound/cards`, `wpctl status` erneut ausführen. `rtkit` kann unabhängig davon jederzeit nachinstalliert werden (`sudo pacman -S --needed rtkit`, danach `sudo systemctl enable --now rtkit-daemon.service`).

## 11. Wartung, Updates & Rollback (Saubere Deinstallation)
- *Wird nach Live-Prüfung ergänzt.*
