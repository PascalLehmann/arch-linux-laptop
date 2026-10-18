# thinkpad — System-Repository

Zentrales Maschinen-Dashboard für den dedizierten Arch-Linux-Laptop **`thinkpad`** (Lenovo ThinkPad P15 Gen 2i). Dieses Repository bildet exakt diese eine Maschine vollständig ab — Hardware-Profil, Dokumentation aller Systemeingriffe (`docs/`) und GNU-Stow-Dotfile-Pakete (`dotfiles/`). Der vollständige Lern- und Dokumentations-Workflow ist in [`CLAUDE.md`](./CLAUDE.md) festgelegt.

---

## 1. Maschinen-Steckbrief & Hardware-Spezifikationen

| Kategorie | Detail |
|---|---|
| **Hostname** | `thinkpad` |
| **System-Rolle** | Laptop (mobile Workstation, Einzelplatzsystem) |
| **Gerätemodell** | Lenovo ThinkPad P15 Gen 2i (Hardware-SKU `LENOVO_MT_20YR_BU_Think_FM`) |
| **Firmware (BIOS/UEFI)** | `N37ET62W` (Version 1.98) |
| **Distribution** | Arch Linux (Rolling Release) |
| **Kernel** | Linux 7.2.11-arch1-1 (x86-64) |
| **CPU** | Intel Core i7-11850H ("Tiger Lake-H", 11. Generation) — 8 Kerne / 16 Threads @ 2,50 GHz Basis-Takt |
| **RAM** | 62 GiB (≈ 64 GB verbaut) |
| **Swap** | 4 GiB **zram** (komprimiertes RAM-basiertes Swap, kein klassischer Swap auf SSD) |
| **iGPU** | Intel UHD Graphics (TigerLake-H GT1) — Treiber `i915` (Kernel-Module `i915`, `xe`) |
| **dGPU** | NVIDIA T1200 Laptop GPU (TU117GLM) — aktuell nur offener Platzhalter-Treiber `nouveau` geladen, **proprietärer Treiber noch nicht eingerichtet** (→ nächster Einrichtungsschritt) |
| **Grafik-Topologie** | Hybrid-Grafik / Optimus (iGPU + dGPU parallel vorhanden) |
| **WLAN** | Intel Wi-Fi 6E AX210 (802.11ax, 2x2, "Typhoon Peak") — Treiber `iwlwifi` |
| **LAN** | Intel Ethernet Controller I225-LM (2,5 GbE) — Treiber `igc` |
| **Audio** | Intel 500-Series HD Audio (SOF-Stack, Treiber `sof-audio-pci-intel-tgl`) + NVIDIA HDMI/DP-Audio (`snd_hda_intel`) |
| **Card-Reader** | Realtek RTS525A (SD-Kartenleser) — Treiber `rtsx_pci` |
| **Anschlüsse** | 2× Thunderbolt 4 (Intel TGL-H Controller) |
| **Display** | Internes eDP-Panel (aktuell einziger `connected`-DRM-Connector; exakte Auflösung/Hz folgt nach Grafiktreiber-/Compositor-Einrichtung) |

### Storage-Layout & Dateisystem

Drei physische NVMe-SSDs, alle mit **Btrfs** formatiert:

| PCI-Adresse | Hersteller / Modell | Device-Node | Partition(en) | Rolle |
|---|---|---|---|---|
| `04:00.0` | KIOXIA XG7 | `nvme1n1` | `nvme1n1p1` (Btrfs, Label `Projekte`) | Daten-Laufwerk für Projekte |
| `05:00.0` | Kingston NV3 (SM2268XT2, DRAM-less) | `nvme2n1` | `nvme2n1p1` (vfat/FAT32, `/boot`), `nvme2n1p2` (Btrfs) | **System-/Boot-Disk** |
| `06:00.0` | Sandisk WD_BLACK SN7100 (DRAM-less) | `nvme0n1` | `nvme0n1p1` (Btrfs, Label `data`) | Daten-Laufwerk |

**Btrfs-Subvolume-Layout auf der System-Disk** (`nvme2n1p2`, Top-Level-ID 5), bereits nach dem gängigen Snapper-Schema angelegt:

```text
@                      → gemountet als /
@home                  → gemountet als /home
@log                   → gemountet als /var/log
@pkg                   → gemountet als /var/cache/pacman/pkg
.snapshots             → Snapper-Snapshots des Root-Subvolumes (@)
@home/.snapshots       → Snapper-Snapshots des Home-Subvolumes (@home)
```

- **Warum getrennte Subvolumes für `@log` und `@pkg`?** Beides sind Verzeichnisse mit hoher Schreib-/Änderungsfrequenz (Logs, Paket-Cache). Werden sie *nicht* vom Root-Subvolume `@` getrennt, bläht jeder Snapshot von `@` diese sich ständig ändernden Daten unnötig mit auf und erschwert Rollbacks (ein Rollback von `@` auf einen alten Snapshot würde sonst auch Logs/Cache zurücksetzen, was unerwünscht ist).
- **Warum ein eigenes Subvolume für `@home`?** Trennt die User-Daten vom System-Root. Ein Rollback des Systems (`@`) auf einen älteren Snapshot (z. B. nach einem fehlgeschlagenen Update) betrifft dann **nicht** die persönlichen Dateien im Home-Verzeichnis.
- Genaue Mount-Optionen (`compress=zstd`, `noatime`, etc.) und das vollständige Snapper-/Pacman-Hook-Setup werden dokumentiert, sobald wir das Thema `00-base-system` (Partitionierung & Btrfs) formal in einer eigenen `.md`-Datei aufarbeiten.

## 2. Netzwerk & Schnittstellen zu anderen eigenen Systemen

- **Aktuelle Netzwerk-Identität:** `thinkpad` ist aktuell ausschließlich über WLAN (`wlan0`, Intel AX210) im lokalen Netz `172.16.0.0/16` eingebunden. Die kabelgebundene 2,5-GbE-Schnittstelle (`enp11s0`) ist physisch vorhanden, aber derzeit nicht verbunden (`NO-CARRIER`).
- **Verbindungen zu anderen eigenen Maschinen (Homeserver, Zweit-PC, etc.):** *Noch nicht eingerichtet / Geplant.* Sobald SSH-Zugänge, NFS-Mounts, WireGuard-Tunnel oder ein Reverse-Proxy zu weiteren eigenen Systemen eingerichtet werden, wird diese Sektion inkl. der zugehörigen `.md`-Doku in `docs/05-system-services/` ergänzt.

## 3. Master-Modul-Index (Status-Tabelle)

| # | Kategorie | Komponente | Dokumentation | Status | Stow-Paket? | Letztes Update |
|---|---|---|---|---|---|---|
| 1 | 00-Base | Claude Code CLI & TTY-Bootstrap | [01-claude-code-tty-bootstrap.md](docs/00-base-system/01-claude-code-tty-bootstrap.md) | ✅ Aktiv & Stabil | Nein | 2026-10-18 |
| 2 | 00-Base | Git- & GNU-Stow-Grundlagen (Repo-Handbuch) | [how-to-use-git-and-stow.md](docs/00-base-system/how-to-use-git-and-stow.md) | ✅ Aktiv & Stabil | Nein | 2026-10-18 |
| 3 | 00-Base | Partitionierung, Btrfs-Subvolumes & Bootloader | *(noch nicht angelegt)* | ⏳ Geplant | Nein | — |
| 3b | 00-Base | Tastatur-Layout der virtuellen Konsole (vconsole) | [02-tastatur-layout-vconsole.md](docs/00-base-system/02-tastatur-layout-vconsole.md) | 🔧 In Einrichtung | Nein | 2026-10-18 |
| 3c | 00-Base | Snapper (Btrfs-Snapshot-Automatisierung) | [03-snapper-btrfs-snapshots.md](docs/00-base-system/03-snapper-btrfs-snapshots.md) | ✅ Aktiv & Stabil | Nein | 2026-10-18 |
| 4 | 01-Hardware/Treiber | Proprietärer NVIDIA-Treiber (Optimus/PRIME, T1200) | [nvidia-prime-hybrid-grafik.md](docs/01-drivers-hardware/nvidia-prime-hybrid-grafik.md) | 🔧 In Einrichtung | Nein | 2026-10-18 |
| 4b | 01-Hardware/Treiber | Bluetooth (BlueZ-Stack) | [bluetooth.md](docs/01-drivers-hardware/bluetooth.md) | ✅ Aktiv & Stabil | Nein | 2026-10-18 |
| 4c | 01-Hardware/Treiber | Audio-Stack (PipeWire) | [audio-pipewire.md](docs/01-drivers-hardware/audio-pipewire.md) | 🔧 In Einrichtung | Nein | 2026-10-18 |
| 4d | 01-Hardware/Treiber | Power-Profiles-Daemon | [power-profiles-daemon.md](docs/01-drivers-hardware/power-profiles-daemon.md) | ✅ Aktiv & Stabil | Nein | 2026-10-18 |
| 5 | 02-Ricing | Hyprland (Wayland-Compositor) | [01-hyprland.md](docs/02-desktop-ricing/01-hyprland.md) | 🔧 In Einrichtung | Nein | 2026-10-18 |
| 6 | 03-CLI | Terminal-Emulator (Kitty & Ghostty, Testphase) | [02-terminal-emulator.md](docs/03-cli-tools/02-terminal-emulator.md) | 🔧 In Einrichtung | Nein | 2026-10-18 |
| 6b | 03-CLI | Neovim (Terminal-Texteditor) | [01-neovim.md](docs/03-cli-tools/01-neovim.md) | ⏳ Geplant | Nein | 2026-10-18 |
| 5b | 02-Ricing | Mako (Notification-Daemon) | [02-mako.md](docs/02-desktop-ricing/02-mako.md) | 🔧 In Einrichtung | Nein | 2026-10-18 |
| 5c | 02-Ricing | Hyprlauncher (App-Launcher) | [03-hyprlauncher.md](docs/02-desktop-ricing/03-hyprlauncher.md) | 🔧 In Einrichtung | Nein | 2026-10-18 |
| 5d | 02-Ricing | Quickshell (Desktop-Shell-Toolkit) | [04-quickshell.md](docs/02-desktop-ricing/04-quickshell.md) | ✅ Aktiv & Stabil | Ja | 2026-10-18 |
| 7 | 04-Apps | Visual Studio Code | *(noch nicht angelegt)* | ⏳ Geplant | Nein | — |
| 7b | 04-Apps | Dolphin (Dateimanager) | [01-dolphin.md](docs/04-applications/01-dolphin.md) | 🔧 In Einrichtung | Nein | 2026-10-18 |
| 8 | 05-Services | OpenSSH-Server (Fernzugriff) | [01-ssh-server.md](docs/05-system-services/01-ssh-server.md) | 🔧 In Einrichtung | Nein | 2026-10-18 |
| 9 | 05-Services | Netzwerk-Stack (systemd-networkd + iwd) | [02-netzwerk-stack.md](docs/05-system-services/02-netzwerk-stack.md) | ✅ Aktiv & Stabil | Nein | 2026-10-18 |
| 10 | 05-Services | CUPS (Druckerverwaltung) | [03-cups-druckerverwaltung.md](docs/05-system-services/03-cups-druckerverwaltung.md) | ✅ Aktiv & Stabil | Nein | 2026-10-18 |
| 11 | 05-Services | Firewall (nftables) | [04-firewall-nftables.md](docs/05-system-services/04-firewall-nftables.md) | ⏳ Geplant | Nein | 2026-10-18 |

**Status-Legende:** ⏳ `Geplant` → Thema erfasst, noch nicht begonnen · 🔧 `In Einrichtung` → Phase 1–4 unseres 5-Phasen-Zyklus laufen · ✅ `Aktiv & Stabil` → verifiziert und abgeschlossen · 🗑️ `Veraltet/Ersetzt` → durch neuere Lösung abgelöst.

### Nächste Schritte (Roadmap zur grafischen Oberfläche)

Gemäß Vereinbarung arbeiten wir uns in dieser Reihenfolge zur grafischen Oberfläche vor:

1. **NVIDIA-Grafiktreiber** (proprietär, Hybrid-Grafik-Konfiguration für iGPU+dGPU)
2. **Hyprland** (Wayland-Compositor)
3. **Terminal-Emulator** (Kitty oder Ghostty — Entscheidung folgt im jeweiligen Konzept-Schritt)
4. **Visual Studio Code**

## 4. Disaster Recovery / Bare-Metal Restore Guide

> **Hinweis:** Dieses System existierte bereits vor Beginn der KI-gestützten Dokumentation (Btrfs-Layout und Snapper-Snapshots sind bereits vorhanden). Die folgende Checkliste wird **progressiv vervollständigt**, sobald die jeweilige `.md`-Datei für jeden Schritt final den Status `Aktiv & Stabil` erreicht. Aktuell dient sie als verbindliches Gerüst für die Reihenfolge.

Chronologische Reihenfolge zur vollständigen Wiederherstellung dieser Maschine auf einer leeren Festplatte:

1. ⏳ **Partitionierung & Dateisystem:** EFI-Partition (FAT32, `/boot`) + Btrfs mit Subvolumes `@`, `@home`, `@log`, `@pkg` anlegen (exaktes Layout siehe Abschnitt 1 oben). *(Doku folgt)*
2. ⏳ **Basis-System & Bootloader:** `pacstrap`, `fstab`, Bootloader-Installation und -Konfiguration. *(Doku folgt)*
3. ✅ **Git, GNU Stow & Claude Code CLI Bootstrap:** [01-claude-code-tty-bootstrap.md](docs/00-base-system/01-claude-code-tty-bootstrap.md) + [how-to-use-git-and-stow.md](docs/00-base-system/how-to-use-git-and-stow.md) — Repository klonen, Claude Code CLI einrichten, Dokumentations-Workflow starten.
4. ⏳ **Grafiktreiber (NVIDIA Hybrid-Grafik):** *(Doku folgt)*
5. ⏳ **Hyprland (Compositor) & Ricing:** *(Doku folgt)*
6. ⏳ **CLI-Tools (Shell, Terminal-Emulator, Editor):** *(Doku folgt)*
7. ⏳ **GUI-Anwendungen (u. a. VS Code):** *(Doku folgt)*
8. ⏳ **System-Services (Netzwerk, SSH, Firewall, Backups):** *(Doku folgt)*

Jeder abgeschlossene Schritt wird hier verlinkt und der Status-Haken (✅) gesetzt, sobald die zugehörige `.md`-Datei den Status `Aktiv & Stabil` trägt.

---

*Dieses Dashboard wird bei jedem abgeschlossenen oder neu begonnenen Einrichtungsschritt gemäß unserem 5-Phasen-Workflow (siehe `CLAUDE.md`) aktualisiert.*
