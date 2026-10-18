# NVIDIA Proprietärer Treiber & PRIME Render Offload (Hybrid-Grafik)

- **Maschine / Hostname:** thinkpad
- **Kategorie:** 01-Hardware/Treiber
- **Status:** In Einrichtung
- **Letztes Update:** 2026-10-18
- **Verwandte Dokumentation:** [README.md](../../README.md)

---

## 1. Übersicht, Architektur & Zweck
- **Was ist das?** Einrichtung des proprietären NVIDIA-Grafiktreibers für die verbaute NVIDIA T1200 Laptop GPU (Turing-Architektur, Chip `TU117GLM`) im Zusammenspiel mit der Intel UHD Graphics (iGPU, TigerLake-H GT1). Das System nutzt eine **Hybrid-Grafik-Topologie** (Optimus-artig): Die Intel-iGPU bleibt für die Bildausgabe des internen Displays zuständig, die NVIDIA-dGPU wird per **PRIME Render Offload** nur bei Bedarf für einzelne, rechenintensive Prozesse aktiviert und kann im Leerlauf über *Runtime D3 (RTD3) Power Management* komplett abgeschaltet werden (wichtig für Akkulaufzeit).
- **Warum nutzen wir es auf dieser Maschine?** Der aktuell automatisch geladene Open-Source-Treiber `nouveau` unterstützt kein *Reclocking* der GPU (dynamisches Hochtakten je nach Last) und bleibt dauerhaft im niedrigsten Energiesparzustand stecken — für produktive GPU-Last (CUDA, Rendering) sowie eine performante Wayland/Hyprland-Session (unser nächstes großes Etappenziel) ist das nicht praxistauglich.
- **Architektur-Entscheidung — Kernel-Modul (revidiert am 2026-10-18):**
  - Ursprünglich war das klassische, vollständig *closed-source* Kernelmodul `nvidia` vorgesehen. Eine Live-Prüfung der Repositories (`pacman -Ss nvidia`) ergab jedoch: **Das Paket `nvidia` (und `nvidia-dkms`) existiert im `extra`-Repository nicht mehr.** NVIDIA/Arch haben das klassische proprietäre Kernelmodul für aktuelle GPU-Generationen (inkl. Turing, wie unsere T1200) vollständig durch die quelloffenen Kernel-Module abgelöst.
  - **Finale Entscheidung:** Wir verwenden **`nvidia-open`** (vorkompiliertes, quelloffenes Kernelmodul; nur der Userspace-Treiber-Anteil über `nvidia-utils` bleibt proprietär). Da unser Kernel-Paket exakt `linux` heißt (siehe Verifizierung unten), ist die vorkompilierte Variante korrekt — **nicht** `nvidia-open-dkms` (nur für Nicht-Standard-Kernel wie `linux-zen`) und **nicht** `nvidia-open-lts` (nur für `linux-lts`).
  - Zusätzlich nutzen wir das offizielle Paket **`nvidia-prime`**, das die PRIME-Render-Offload-Konfiguration und das `prime-run`-Hilfswerkzeug direkt mitbringt, statt eigene Wrapper-Skripte von Hand zu bauen.
- **Offizielle Referenzen:**
  - [Arch Wiki: NVIDIA](https://wiki.archlinux.org/title/NVIDIA)
  - [Arch Wiki: PRIME](https://wiki.archlinux.org/title/PRIME)
  - [Arch Wiki: Hybrid graphics](https://wiki.archlinux.org/title/Hybrid_graphics)
  - [NVIDIA Open GPU Kernel Modules (GitHub)](https://github.com/NVIDIA/open-gpu-kernel-modules)

## 2. Abhängigkeiten & System-Voraussetzungen
- **Pflicht-Pakete:**
  - `nvidia-open`: Enthält das quelloffene Kernelmodul (`nvidia.ko` / `nvidia-drm.ko` / `nvidia-modeset.ko` / `nvidia-uvm.ko`), das der Linux-Kernel lädt, um mit der GPU-Hardware zu kommunizieren. Vorkompiliert passend zum Standard-Kernel-Paket `linux`.
  - `nvidia-utils`: Proprietäre Userspace-Bibliotheken (OpenGL-, Vulkan-, VDPAU-Implementierung) sowie das CLI-Tool `nvidia-smi` zur Diagnose. **Wichtig:** Das Kernelmodul ist offen, der Userspace-Treiber bleibt weiterhin closed-source.
  - `nvidia-prime`: Offizielles NVIDIA-Werkzeug zur Konfiguration von PRIME Render Offload, inkl. des Kommandos `prime-run <programm>`, um ein einzelnes Programm gezielt auf der dGPU auszuführen.
  - `linux-headers`: Kernel-Header-Dateien, die als Build-Absicherung für das vorkompilierte Kernelmodul-Paket benötigt werden (zwingend bei `-dkms`-Varianten; bei der vorkompilierten `nvidia-open`-Variante als Absicherung empfohlen).
  - `nvidia-settings`: Grafisches Konfigurationswerkzeug (erst relevant, sobald eine GUI läuft).
- **Optionale Pakete (`optdepends`):**
  - `lib32-nvidia-utils`: 32-Bit-Treiberbibliotheken, nur relevant falls später 32-Bit-Anwendungen (z. B. über Steam/Wine) GPU-Beschleunigung benötigen.
  - `opencl-nvidia`: OpenCL-Compute-Unterstützung, nur bei Bedarf für entsprechende Anwendungen.
- **Hardware- & System-Voraussetzungen:**
  - **Muxless-Hybrid-Grafik bestätigt (2026-10-18):** `sudo cat /sys/kernel/debug/vgaswitcheroo/switch` zeigt die Intel-iGPU (`1:IGD:*:Pwr:0000:00:02.0`) als aktiven, dauerhaft bestromten Ausgabepfad für das interne Display; die NVIDIA-dGPU (`0:DIS: :DynOff:0000:01:00.0`) sowie ihre HDMI/DP-Audio-Funktion (`2:DIS-Audio: :DynOff:0000:01:00.1`) sind im Leerlauf bereits erfolgreich per Runtime-Power-Management (*RTD3*) abgeschaltet (`DynOff`). Kein physischer Display-Mux vorhanden → **PRIME Render Offload** ist der korrekte Ansatz.
  - **Kernel-Paket bestätigt (2026-10-18):** `pacman -Qs "^linux$"` listet das Paket `linux` (Standard-Kernel, `7.2.11.arch1-1`), kein `-lts`/`-zen`/`-hardened`-Derivat → die **vorkompilierte** Paketvariante `nvidia` ist korrekt (kein `nvidia-dkms` nötig), da sie von Pacman automatisch synchron mit jedem `linux`-Kernel-Update mitaktualisiert wird.
  - Kernel-Parameter `nvidia-drm.modeset=1` wird für volle KMS-Integration (*Kernel Mode Setting*, insb. für spätere Wayland-Nutzung unter Hyprland zwingend) benötigt — Details folgen in Abschnitt 4.
  - Gruppenmitgliedschaft nicht erforderlich (anders als z. B. bei manchen Video-Gruppen-Patterns); PRIME-Offload erfolgt pro Prozess über Umgebungsvariablen, nicht über Berechtigungsgruppen.

## 3. Installation & Flag-Erklärung

**a) Vollständiges Sysupgrade (vorab, zur Absicherung konsistenter Bibliotheksversionen):**
```bash
sudo pacman -Syu
```

**b) NVIDIA-Treiber-Pakete installieren:**
```bash
sudo pacman -S --needed nvidia-open nvidia-utils nvidia-prime linux-headers
```
- **Aufschlüsselung der Parameter:** siehe `-S`/`--needed`-Erklärung im [Git/Stow-Guide](./../00-base-system/how-to-use-git-and-stow.md) bzw. in der [Bootstrap-Doku](./../00-base-system/01-claude-code-tty-bootstrap.md), Abschnitt 3.1 — identische Bedeutung.
- **Paket-Details:** siehe Abschnitt 2 ("Pflicht-Pakete") oben.
- **Ergebnis (2026-10-18):** Beide Befehle erfolgreich durchgelaufen. Das quelloffene Kernelmodul `nvidia-open` samt proprietärer Userspace-Treiber (`nvidia-utils`) ist installiert, aber **noch nicht aktiv** — dafür fehlen noch die Kernel-Integration (Abschnitt 4: `mkinitcpio`-Module, Kernel-Parameter) und ein Neustart.

## 4. System-Eingriffe (Kernel, Treiber, Boot, Berechtigungen)
- **Kernel-Parameter `nvidia-drm.modeset=1` (aktiv, verifiziert 2026-10-18):** In der Kernel-Commandline (`/etc/kernel/cmdline`, eingebettet in die Unified Kernel Image unter `/boot/EFI/Linux/arch-linux.efi`, geladen über Limine) gesetzt. Verifiziert über `sudo dmesg | grep -i nvidia` → `Command line: ... nvidia-drm.modeset=1`.
  - **Technischer Hintergrund:** Aktiviert *Kernel Mode Setting* (KMS) direkt im `nvidia-drm`-Kernelmodul statt im Userspace (klassischer X-Server-Ansatz). Ohne diesen Parameter bleibt der DRM-Knoten (`/dev/dri/cardX`) der NVIDIA-GPU ohne Mode-Setting-Fähigkeiten — spätere Wayland-Compositors (Hyprland, unser nächstes Etappenziel) benötigen das zwingend, da Wayland ausschließlich über das DRM/KMS-Subsystem mit der GPU kommuniziert und keinen X-Server-Fallback besitzt.
- **Modul-Ladevorgang (verifiziert über `sudo dmesg | grep -i nvidia`):**
  - `nvidia: module verification failed: signature and/or required key missing - tainting kernel` — Das `nvidia`-Kernelmodul ist nicht kryptografisch signiert. Das ist bei proprietären/Out-of-Tree-Modulen ohne eigenes Secure-Boot-MOK-Signing normal und setzt lediglich das Kernel-interne „Tainted"-Flag (relevant nur für Kernel-Crash-Diagnosen via `ksymoops`/Bugreports). Kein Funktionsfehler — das Modul lädt trotzdem erfolgreich (`NVRM: loading NVIDIA UNIX Open Kernel Module ... 615.78.08`).
  - `nvidia 0000:01:00.0: [drm] Cannot find any crtc or sizes` — Erwartetes Verhalten bei **muxloser Hybrid-Grafik**: Die dGPU hat keinen eigenen Display-Ausgang am internen Panel (das übernimmt ausschließlich die iGPU), weshalb `nvidia-drm` keinen CRTC (die Scanout-/Display-Timing-Engine der GPU) findet. Für PRIME Render Offload ist das der korrekte Zustand, kein Fehler.
- **Runtime D3 Power Management (RTD3) — erfolgreich konfiguriert (final verifiziert 2026-10-18):**
  - Diagnose (`cat /proc/driver/nvidia/gpus/0000:01:00.0/power`) zeigte zunächst `Runtime D3 status: Disabled by default`, obwohl der Modul-Parameter `NVreg_DynamicPowerManagement` mit Wert `3` (*Default/Auto* — der Treiber soll selbst erkennen, ob RTD3 von der Plattform unterstützt wird) geladen war.
  - `sudo dmesg | grep -iE "_PR3|power resource|d3cold|RTD3"` zeigte, dass die ACPI-Firmware des Lenovo-BIOS sehr wohl Power-Resource-Objekte für die PCIe-Graphics-Root-Ports bereitstellt (u. a. `\_SB_.PC00.PEG0.PG00: New power resource` — vermutlich der Root-Port, an dem die dGPU `0000:01:00.0` hängt) sowie generelle `D3cold`-Fähigkeit für das GPU-PCI-Device selbst (`pci 0000:01:00.0: PME# supported from D0 D3hot D3cold`).
  - **Finale Lösung:** `/etc/modprobe.d/nvidia-pm.conf` mit `NVreg_DynamicPowerManagement=0x02` (erzwingt *Fine-grained* RTD3 statt des Auto-Modus) angelegt, danach `sudo mkinitcpio -p linux` ausgeführt (damit der `kms`-Hook den neuen Modprobe-Parameter in das Unified Kernel Image einbettet) und neu gestartet. Ergebnis nach dem Neustart: `cat /sys/module/nvidia/parameters/NVreg_DynamicPowerManagement` → `2`, `cat /proc/driver/nvidia/gpus/0000:01:00.0/power` → `Runtime D3 status: Enabled (fine-grained)`. Details zum vorherigen Fehlversuch (Datei fehlte vor dem ersten Neustart) siehe Abschnitt 10.

## 5. Konfiguration & Dotfiles (Deep-Dive & GNU Stow)
- **Manuelle Dateistruktur für GNU Stow:** *Nicht zutreffend für diesen Schritt* — die folgende Konfiguration liegt unter `/etc/modprobe.d/` und ist damit eine **system-weite** Konfiguration, kein User-Dotfile unter `~/.config`. GNU Stow verwaltet ausschließlich Symlinks innerhalb des Home-Verzeichnisses (`dotfiles/<paket>/.config/...` → `~/.config/...`) und ist für `/etc/`-Dateien architektonisch nicht vorgesehen. Diese Datei wird daher **direkt in `/etc/` angelegt**, nicht über `dotfiles/`.
- **System-Konfigurationsdatei (von dir manuell anzulegen):** `/etc/modprobe.d/nvidia-pm.conf`
- **Konfigurations-Block (Vorlage zur manuellen Übernahme):**
  ```
  # Erzwingt Fine-Grained Runtime D3 Power Management (RTD3) für die NVIDIA-dGPU,
  # statt dem treiber-internen Auto-Erkennungsmodus (Default=3) zu vertrauen.
  options nvidia NVreg_DynamicPowerManagement=0x02
  ```
- **Detail-Erklärung der Parameter (Was, Warum, Nutzen):**
  - `options nvidia ...`: modprobe-Syntax, um dem `nvidia`-Kernelmodul beim Laden Parameter zu übergeben (äquivalent zu einem Kernel-Commandline-Parameter wie `nvidia-drm.modeset=1`, nur eben treiberintern statt über die Kernel-Commandline gesteuert).
  - `NVreg_DynamicPowerManagement=0x02`: Erzwingt explizit *Fine-grained* RTD3 statt des Auto-Modus `3`, der auf dieser Maschine trotz vorhandener ACPI-D3cold-Unterstützung (siehe Abschnitt 4) zu `Disabled` führte. **Nutzen:** Im Leerlauf (kein PRIME-Offload-Prozess aktiv) schaltet sich die dGPU komplett ab (D3cold) → spürbare Akkulaufzeit-Ersparnis auf einem mobilen Gerät, ohne beim aktiven Rendern (`prime-run <programm>`) Performance einzubüßen, da die GPU dann automatisch wieder aufwacht.
- **Maschinen-Spezifische Werte:** Keine — der Parameter ist treiberseitig generisch und nicht an eine bestimmte PCI-ID oder Monitor-Konfiguration gebunden. Bei Übernahme in ein anderes Maschinen-Repo ist nur relevant, ob die Ziel-Hardware überhaupt ACPI-D3cold-Unterstützung besitzt (siehe Abschnitt 4 — dort pro Maschine neu verifizieren).
- **Stow-Befehl:** *Nicht zutreffend* — kein Stow-Paket, da System-Datei in `/etc/` (siehe oben).
- **Ablauf nach Anlage der Datei (abgeschlossen, verifiziert 2026-10-18):** Da unsere `HOOKS`-Zeile `kms` enthält, war ein **`mkinitcpio`-Rebuild zwingend nötig**, bevor ein Neustart aussagekräftig testen konnte. Grund: Laut [Arch Wiki (mkinitcpio, Abschnitt „kms hook")](https://wiki.archlinux.org/title/Mkinitcpio) erkennt dieser Hook beim Bauen des Images automatisch die *aktuell geladenen* GPU-Treiber (hier: `nvidia`/`nvidia_drm`/`nvidia_modeset`/`nvidia_uvm`) und bettet sie samt des zu diesem Zeitpunkt gültigen Standes von `/etc/modprobe.d/` direkt in das Initramfs/UKI ein — damit schon vor dem eigentlichen Root-Mount ein funktionierendes KMS für unseren Boot-Splash (`--splash ...bmp`, siehe `linux.preset` in Abschnitt 4) zur Verfügung steht. Jede spätere Änderung an `/etc/modprobe.d/` (wie unsere `nvidia-pm.conf`) wird von einem *bereits gebauten* Image schlicht nicht mehr gesehen, bis es neu erzeugt wird. Durchlaufene Reihenfolge: 1) Datei angelegt → 2) `sudo mkinitcpio -p linux` → 3) Neustart → 4) Verifizierung in Abschnitt 9 bestätigt Erfolg.

## 6. Ricing, Theming & Desktop-Integration
- *Nicht zutreffend / Keine Einträge* (reine Treiber-Ebene; Integration in Hyprland folgt im eigenen Hyprland-Dokument).

## 7. Systemd, Autostart & Automatisierung
- *Wird in einem der nächsten Schritte ergänzt (u. a. mögliche `nvidia-suspend`/`nvidia-hibernate`/`nvidia-resume` Systemd-Units für Suspend/Resume-Stabilität).*

## 8. Dateisystem (z. B. Btrfs), Netzwerk & Sicherheit
- *Nicht zutreffend / Keine Einträge*

## 9. Verifizierung, Diagnose & Cheatsheet
- **Funktionsprüfung & Diagnose (Baseline, verifiziert 2026-10-18 nach Neustart):**
  - `lsmod | grep nvidia` → `nvidia`, `nvidia_drm`, `nvidia_modeset`, `nvidia_uvm` sind geladen.
  - `nvidia-smi` → Treiber erkennt die GPU korrekt:
    ```
    NVIDIA-SMI 615.78.08   KMD Version: 615.78.08   CUDA UMD Version: 13.4
    GPU 0: NVIDIA T1200 Laptop GPU — Pwr: 3W / 35W Cap, 39°C, 0% Util, Persistence-M: Off
    ```
    - **Wie liest man das?** `Persistence-M: Off` ist auf einem Optimus-Laptop der gewünschte Zustand (*Persistence Mode* würde die GPU dauerhaft initialisiert halten und RTD3 verhindern). `Pwr:Usage/Cap` zeigt aktuellen Verbrauch (3 W) vs. maximales Power-Budget (35 W) — 3 W im Leerlauf ist für eine noch *nicht* schlafende GPU (RTD3 noch nicht final konfiguriert) ein plausibler Idle-Wert.
  - `sudo dmesg | grep -i nvidia` → vollständige Analyse der Boot-Meldungen siehe Abschnitt 4.
- **Funktionsprüfung RTD3 (final, verifiziert 2026-10-18 nach zweitem Neustart):**
  - `cat /sys/module/nvidia/parameters/NVreg_DynamicPowerManagement` → `2` (Fine-grained, statt Default `3`) — der Modprobe-Parameter aus `nvidia-pm.conf` greift jetzt korrekt.
  - `sudo cat /proc/driver/nvidia/gpus/0000:01:00.0/power` → `Runtime D3 status: Enabled (fine-grained)`. Zusätzliche Zeilen in dieser Diagnose-Datei:
    - `Video Memory: Active` — der VRAM-Inhalt der dGPU ist aktuell noch gehalten (plausibel kurz nach dem Boot, bevor die GPU erstmals in den Leerlauf geht).
    - `S0ix Power Management: Status: Disabled` (`Platform Support: Not Supported`) — dieses Notebook-Plattform-Feature (tiefer Suspend-to-Idle-Zustand) wird vom Lenovo-BIOS für die dGPU nicht angeboten; irrelevant für RTD3 selbst, betrifft nur System-Suspend (siehe Abschnitt 7).
    - `Notebook Dynamic Boost: Supported` — Lenovo-spezifisches Power-Sharing zwischen CPU und GPU unter Last; rein informativ, keine manuelle Konfiguration nötig.
  - **Wie liest man `Enabled (fine-grained)`?** Die GPU darf nun eigenständig, pro PCI-Funktion, in den Energiesparzustand `D3cold` wechseln, sobald kein Prozess mehr über `prime-run` auf ihr aktiv ist — nicht erst beim System-Suspend wie zuvor.
- **Alltags-Cheatsheet:**
  - `nvidia-smi` — Schnellcheck: Treiber-/Firmware-Version, GPU-Temperatur, Leistungsaufnahme, laufende Prozesse auf der dGPU.
  - `prime-run <programm>` — Startet `<programm>` explizit auf der dGPU statt der iGPU (z. B. `prime-run glxinfo | grep "OpenGL renderer"`).
  - `cat /proc/driver/nvidia/gpus/0000:01:00.0/power` — RTD3-Status der dGPU prüfen (`Runtime D3 status: Enabled`/`Disabled`).

## 10. Troubleshooting & Fehler-Historie (Lern-Protokoll)

### [2026-10-18] - `error: target not found: nvidia` bei der Installation
- **Symptom / Fehlermeldung:** `sudo pacman -S --needed nvidia nvidia-utils linux-headers` bricht mit `error: target not found: nvidia` ab, bevor überhaupt etwas installiert wird.
- **Technische Ursache (Root Cause):** `pacman -Ss nvidia` auf den frisch synchronisierten Datenbanken bestätigte: Das Paket `nvidia` (und `nvidia-dkms`) existiert im `extra`-Repository schlicht nicht mehr. NVIDIA/Arch haben das klassische, vollständig closed-source Kernelmodul für aktuelle GPU-Generationen (inkl. Turing-Chips wie unsere T1200) vollständig durch die quelloffenen Kernel-Module (`nvidia-open` / `nvidia-open-dkms` / `nvidia-open-lts`) abgelöst — kein lokales Datenbank-/Sync-Problem, sondern eine reale Repository-Umstellung.
- **Gescheiterte Ansätze & Lerneffekt:** Die ursprüngliche Architektur-Entscheidung für das klassische proprietäre Kernelmodul (siehe Abschnitt 1) war zum Zeitpunkt der Entscheidung bereits durch die Repository-Realität überholt. **Lerneffekt:** Vor einer finalen Paket-Entscheidung immer zuerst per `pacman -Ss <name>` verifizieren, ob der erwartete Paketname aktuell überhaupt noch existiert, statt sich allein auf allgemeines Hintergrundwissen zu verlassen — Arch-Repositories (Rolling Release) ändern sich kontinuierlich.
- **Finale Lösung:** Umstieg auf `nvidia-open` (vorkompiliert, passend zum Standard-Kernel-Paket `linux`) + `nvidia-utils` + `nvidia-prime` + `linux-headers`. Siehe aktualisierte Architektur-Entscheidung in Abschnitt 1 und Paketliste in Abschnitt 2.

### [2026-10-18] - RTD3-Parameter bleibt nach Neustart bei `3` (Default) statt `2`
- **Symptom / Fehlermeldung:** Nach dem in Abschnitt 5 angekündigten Neustart zeigt `cat /sys/module/nvidia/parameters/NVreg_DynamicPowerManagement` weiterhin `3`, und `cat /proc/driver/nvidia/gpus/0000:01:00.0/power` weiterhin `Runtime D3 status: Disabled by default`. `sudo dmesg | grep -iE "_PR3|power resource|d3cold|RTD3|nvidia"` zeigt keine neuen RTD3-bezogenen Meldungen gegenüber dem Vorzustand.
- **Technische Ursache (Root Cause):** `stat -c '%y  %n' /etc/modprobe.d/nvidia-pm.conf /boot/EFI/Linux/arch-linux.efi` ergab: **`/etc/modprobe.d/nvidia-pm.conf` existiert überhaupt nicht** (`Datei oder Verzeichnis nicht gefunden`). Der in Abschnitt 5 dokumentierte Konfigurationsschritt wurde vor dem Neustart schlicht nicht ausgeführt bzw. ist nicht erhalten geblieben — das `nvidia`-Modul lädt deshalb korrekt mit seinem eingebauten Default (`3`), da kein abweichender Parameter übergeben wurde.
- **Gescheiterte Ansätze & Lerneffekt:** Ursprüngliche Arbeitshypothese war ein zu alt gebautes Boot-Image (siehe korrigierte Erklärung zum `kms`-Hook in Abschnitt 5) — diese Hypothese ist technisch weiterhin relevant für den *nächsten* Rebuild-Schritt, war aber in diesem konkreten Fall nicht die Ursache, da die Datei gar nicht erst existierte. **Lerneffekt:** Vor einem Neustart, der einen `/etc/`-Konfigurationsschritt testen soll, immer zuerst mit `cat`/`stat` auf die tatsächlich angelegte Datei selbst gegenprüfen, statt sich auf die reine Erinnerung zu verlassen, den Schritt ausgeführt zu haben — besonders bei Mehrfach-Reboot-Sessions, in denen leicht ein Teilschritt übersprungen wird.
- **Finale Lösung:** Datei tatsächlich angelegt → `mkinitcpio -p linux` → Neustart → Re-Verifizierung in Abschnitt 9 bestätigt: `NVreg_DynamicPowerManagement` lädt jetzt mit `2`, RTD3-Status `Enabled (fine-grained)`.

### [2026-10-18] - `error: target not found: noconfirm` bei `pacman -Syu --noconfirm`
- **Symptom / Fehlermeldung:** `sudo pacman -Syu --noconfirm 2>&1` lädt zwar die Datenbanken (`core`, `extra`) erfolgreich herunter, bricht aber mit `Fehler: Ziel nicht gefunden: noconfirm` ab, bevor der eigentliche Sysupgrade-Teil (`-u`) ausgeführt wird.
- **Technische Ursache (Root Cause):** Pacman hat den String `noconfirm` als **Paketnamen** interpretiert statt als Teil des Flags `--noconfirm`. Das deutet darauf hin, dass beim Kopieren des Befehls aus dem Chat in das Terminal der doppelte ASCII-Bindestrich (`--`) durch ein optisch ähnliches Unicode-Zeichen (z. B. einen Gedankenstrich `—`) ersetzt wurde — die Shell erkennt den String dann nicht mehr als Options-Präfix, sondern als weiteres Installations-Ziel.
- **Gescheiterte Ansätze & Lerneffekt:** Copy-Paste von Befehlen mit `--doppel-flags` aus Chat-Oberflächen ist nicht 100 % zuverlässig. **Lerneffekt:** Bei Fehlern wie `target not found: <offensichtlich-kein-paketname>` immer zuerst auf versteckte Zeichenkodierungs-Probleme beim Copy-Paste prüfen, bevor man eine komplexere Ursache vermutet.
- **Finale Lösung:** Datenbanken waren durch den Teil-Lauf bereits aktuell synchronisiert (ausreichend für die nachfolgende Paketsuche). Für den vollständigen Sysupgrade wird der Befehl ohne das `--noconfirm`-Flag erneut interaktiv ausgeführt (siehe nächster Schritt im Chat).

## 11. Wartung, Updates & Rollback (Saubere Deinstallation)
- *Wird nach Installation ergänzt.*
