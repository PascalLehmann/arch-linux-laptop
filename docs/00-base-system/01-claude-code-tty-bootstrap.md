# Claude Code CLI & Initial-Bootstrap (Arch TTY Setup)

- **Maschine / Hostname:** [Wird beim Onboarding ausgefüllt]
- **Kategorie:** 00-Base
- **Status:** Aktiv & Stabil
- **Letztes Update:** 2026-10-18
- **Verwandte Dokumentation:** [README.md](../../README.md), [how-to-use-git-and-stow.md](./how-to-use-git-and-stow.md)

---

## 1. Übersicht, Architektur & Zweck
- **Was ist das?** Diese Dokumentation beschreibt den allerersten Bootstrap-Prozess auf einer frisch installierten, rein konsolenbasierten Arch Linux Umgebung (*TTY / TeleTYpewriter*) ohne grafische Oberfläche (kein Wayland/X11, kein Browser). Sie umfasst die Einrichtung einer isolierten Node.js-Umgebung im User-Space, die Installation des `claude-code` CLI-Agenten, das Klonen dieses System-Repositorys sowie den Headless-OAuth-Login.
- **Warum nutzen wir es auf dieser Maschine?** Bevor ein Compositor (wie Hyprland), ein Terminal-Emulator (wie Kitty) und eine IDE (wie VS Code) eingerichtet sind, benötigen wir den KI-Architekten bereits direkt in der Linux-Konsole (`TTY`), um ab dem ersten Grafiktreiber und Basispaket unseren strikten Dokumentations- und Lern-Workflow einzuhalten.
- **Offizielle Referenzen:**
  - [Arch Wiki: Pacman](https://wiki.archlinux.org/title/Pacman)
  - [Arch Wiki: Node.js / npm](https://wiki.archlinux.org/title/Node.js#Allow_user-wide_installations)
  - [Anthropic Claude Code Dokumentation](https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/overview)

## 2. Abhängigkeiten & System-Voraussetzungen
- **Pflicht-Pakete:** (Offizielle Arch Linux Repositories `core` und `extra`)
  - `git`: Verteilte Versionsverwaltung zum Klonen und Pflegen unseres System-Repositorys.
  - `nodejs`: JavaScript-Laufzeitumgebung (V8-Engine), die als Basis für das Claude Code CLI benötigt wird.
  - `npm`: Der *Node Package Manager*, über den das Paket `@anthropic-ai/claude-code` bezogen wird.
  - `stow`: Symlink-Farm-Manager (*GNU Stow*) zur späteren Verwaltung unserer Dotfiles nach Branchenstandard.
- **Optionale Pakete (`optdepends`):**
  - *Keine für diesen Bootstrap-Schritt erforderlich.*
- **Hardware- & System-Voraussetzungen:**
  - Laufendes Arch Linux Grundsystem mit aktiver Netzwerkverbindung (LAN via `systemd-networkd`/`dhcpcd` oder WLAN via `iwd`/`nmcli`).
  - Eingerichteter Standard-User mit `sudo`-Berechtigung (Mitglied der Gruppe `wheel`).
  - Ein Zweitgerät (z. B. Smartphone mit Kamera/Texterkennung) zur Durchführung des OAuth-Logins ohne lokalen Browser.

## 3. Installation & Flag-Erklärung

### 3.1 Basis-Pakete über Pacman installieren
```bash
sudo pacman -Syu --needed git nodejs npm stow
```
- **Aufschlüsselung der Parameter:**
  - `sudo`: Führt den nachfolgenden Befehl mit administrativen Rechten (*Root*) aus, da Systempakete in geschützte Verzeichnisse (`/usr`, `/var`) installiert werden.
  - `pacman`: Der native Paketmanager von Arch Linux.
  - `-S` *(Sync)*: Weist Pacman an, Pakete aus den entfernten (Remote) Repositories zu synchronisieren und zu installieren.
  - `-y` *(Refresh)*: Lädt eine frische Kopie der Master-Paketdatenbanken vom konfigurierten Arch-Mirror-Server herunter.
  - `-u` *(Sysupgrade)*: Vergleicht alle lokal installierten Pakete mit der neuen Datenbank und aktualisiert veraltete Pakete. *(WICHTIG: Unter Arch Linux werden niemals Teil-Updates via `-Sy <paket>` durchgeführt, sondern immer ein vollständiges `-Syu`, um Inkompatibilitäten bei geteilten Systembibliotheken / Shared Libraries zu verhindern).*
  - `--needed`: Prüft vorab, ob eines der genannten Pakete bereits in der aktuellsten Version installiert ist, und überspringt dieses (verhindert unnötige Re-Installationen).

### 3.2 Claude Code CLI über NPM im User-Space installieren
*(WICHTIG: Erst ausführen, nachdem die NPM-Konfiguration aus Abschnitt 5 abgeschlossen wurde!)*
```bash
npm install -g @anthropic-ai/claude-code
```
- **Aufschlüsselung der Parameter:**
  - `npm install`: Lädt ein Paket aus der offiziellen NPM-Registry herunter und installiert es inklusive seiner Abhängigkeiten.
  - `-g` *(global)*: Installiert das Paket nicht nur für ein einzelnes Programmierprojekt im aktuellen Ordner, sondern stellt das ausführbare Programm (`claude`) systemweit für den aktuellen Benutzer bereit. Durch unsere Anpassung in *Abschnitt 5* landet dies sicher in `~/.npm-global` statt im Root-Dateisystem.

## 4. System-Eingriffe (Kernel, Treiber, Boot, Berechtigungen)
- *Nicht zutreffend / Keine Einträge* (Es werden bewusst keine Root-Rechte für NPM vergeben, um das System sauber zu halten).

## 5. Konfiguration & Dotfiles (Deep-Dive & GNU Stow)

### 5.1 Warum NPM im User-Space konfiguriert werden muss (Technischer Hintergrund)
Standardmäßig versucht `npm install -g` Pakete in das Systemverzeichnis `/usr/lib/node_modules` zu schreiben, wofür `sudo`-Rechte nötig wären. Unter Arch Linux darf ein sprachspezifischer Paketmanager (`npm`, `pip`, `cargo`) **niemals mit `sudo`** ausgeführt werden: Er würde Dateien am System-Paketmanager `pacman` vorbei direkt in `/usr` ablegen. Wenn später ein offizielles Arch-Paket dieselbe Datei mitbringt, bricht `pacman` das System-Update mit dem Fehler `file exists in filesystem` ab. Zudem stellt das Ausführen von fremden NPM-Installationsskripten als Root ein erhebliches Sicherheitsrisiko dar.

### 5.2 Einrichtung des globalen NPM-Ordners im Home-Verzeichnis
```bash
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
```
- **Detail-Erklärung der Befehle & Parameter (Was, Warum, Nutzen):**
  - `mkdir -p ~/.npm-global`: Erstellt das versteckte Verzeichnis `.npm-global` im eigenen Home-Ordner (`~/`). Das Flag `-p` *(parents)* legt bei Bedarf fehlende übergeordnete Ordner an und unterdrückt Fehlermeldungen, falls der Ordner bereits existiert.
  - `npm config set prefix '~/.npm-global'`: Schreibt die Einstellung `prefix=~/.npm-global` in die benutzereigene Datei `~/.npmrc`. **Nutzen:** Alle globalen NPM-Pakete und deren ausführbare Startskripte (Binaries) werden ab sofort sauber isoliert unter `~/.npm-global/bin` abgelegt – komplett ohne Root-Rechte.

### 5.3 Anpassung der Umgebungsvariable `PATH`
Damit die Shell (aktuell `bash`) den Befehl `claude` findet, muss das neue Verzeichnis in den Suchpfad (`PATH`) aufgenommen werden:
```bash
echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```
- **Detail-Erklärung der Parameter (Was, Warum, Nutzen):**
  - `export PATH="$HOME/.npm-global/bin:$PATH"`: Setzt die Umgebungsvariable `PATH` neu, indem unser eigener Ordner `~/.npm-global/bin` **vor** (`:`) den bestehenden Systempfad (`$PATH`) gehängt wird. Linux durchsucht diese Ordner von links nach rechts, wenn man einen Befehl eintippt.
  - `>> ~/.bashrc`: Der Operator `>>` *(Append)* hängt die Textzeile sicher an das Ende der Datei `~/.bashrc` an (Vorsicht: Ein einzelnes `>` würde die gesamte Datei überschreiben!).
  - `source ~/.bashrc`: Liest die geänderte Konfigurationsdatei sofort in die aktuell laufende Terminal-Sitzung ein, sodass kein Logout/Login nötig ist.
- **Maschinen-Spezifische Werte:** Keine – diese Konfiguration nutzt die dynamische Variable `$HOME` und ist auf jeder Linux-Maschine identisch nutzbar.
- **Stow-Befehl:** Zu diesem frühen Zeitpunkt wird die `.bashrc` noch direkt bearbeitet. Sobald wir unsere finale Shell (z. B. `bash` oder `zsh`) als eigenes Modul einrichten, wird die `.bashrc` und `.npmrc` sauber in `dotfiles/shell/` überführt und per `stow` verlinkt.

## 6. Ricing, Theming & Desktop-Integration
- *Nicht zutreffend / Keine Einträge* (Reines TTY-Konsolen-Setup; beim ersten Start von `claude` wird lediglich das Standard-Farbschema für dunkle Terminals gewählt).

## 7. Systemd, Autostart & Automatisierung
- *Nicht zutreffend / Keine Einträge* (`claude` wird interaktiv bei Bedarf im Terminal gestartet und läuft nicht als Hintergrund-Daemon).

## 8. Dateisystem (z. B. Btrfs), Netzwerk & Sicherheit
- **Storage & Snapshots:** Der Ordner `~/.npm-global` sowie der spätere Konfigurationsordner `~/.claude` liegen im Home-Subvolume (`@home`). Bei einem späteren Btrfs-Rollout auf dem Root-Dateisystem (`@`) bleiben das Repository und die Claude-Installation im User-Space unangetastet.
- **Netzwerk, Firewall & Security:**
  - Für `git clone` über HTTPS bei einem privaten GitHub-Repository akzeptiert GitHub kein normales Account-Passwort mehr. Es muss zwingend ein **Personal Access Token (PAT)** als Passwort eingegeben werden.
  - `claude` kommuniziert ausgehend über HTTPS (Port 443) mit den Servern von Anthropic (`api.anthropic.com` / `claude.ai`). Es müssen keine eingehenden Ports in der Firewall geöffnet werden.

## 9. Verifizierung, Diagnose & Cheatsheet

### 9.1 Funktionsprüfung der Installation
```bash
which claude
claude --version
```
- **Erwarteter Output:**
  - `which claude` zeigt den exakten Pfad an, unter dem das Programm gefunden wurde – hier muss `/home/<dein-user>/.npm-global/bin/claude` erscheinen.
  - `claude --version` gibt die installierte Versionsnummer ohne Fehlermeldung aus.

### 9.2 Repository klonen & `CLAUDE.md` vorbereiten
```bash
git clone [https://github.com/](https://github.com/)<DEIN-USER>/<DEIN-REPO>.git ~/arch-system-repo
cd ~/arch-system-repo
```
- **Wichtiger Check für den System-Prompt:** Claude Code sucht beim Start im aktuellen Arbeitsverzeichnis automatisch nach einer Datei namens **`CLAUDE.md`** und lädt diese als oberste System-Instruktion. Falls die Datei im Repo noch anders heißt, wird sie mit Git umbenannt:
  ```bash
  git mv <alter-dateiname.md> CLAUDE.md
  ```
  - `git mv`: Benennt die Datei im Dateisystem um und teilt Git diese Änderung gleichzeitig für den nächsten Commit mit.

### 9.3 Headless-Login mit der Claude Subscription (Pro / Max) im TTY
Starte den Agenten im Repository-Ordner:
```bash
claude
```
1. **Login-Modus wählen:** Wähle beim ersten Start (oder über den Befehl `/login`) die Option für die **Claude Pro / Max Subscription** (OAuth über `claude.ai`, **nicht** Console/API-Billing).
2. **Umgehung des fehlenden Browsers im TTY:** Da im nackten TTY kein Browser geöffnet werden kann, gibt Claude Code eine lange **Autorisierungs-URL** auf dem Bildschirm aus und wartet auf einen Bestätigungscode.
3. **Autorisierung via Smartphone:**
   - Öffne die Kamera-App / Google Lens auf dem Smartphone, richte sie auf den Monitor und erfasse die angezeigte URL per Texterkennung (erspart das manuelle Abtippen).
   - Öffne den Link auf dem Smartphone, logge dich in deinen `claude.ai`-Account ein und bestätige mit **Authorize**.
   - Die Webseite zeigt nun einen kurzen **Authentication Code** an.
   - Tippe diesen Code im Arch-TTY in das Eingabefeld von Claude Code ein und bestätige mit `Enter`.
4. **Vertrauensstellung:** Bestätige die Frage, ob Claude den Dateien in `~/arch-system-repo` vertrauen darf, mit **Yes**. Damit ist die `CLAUDE.md` aktiv geladen.

### 9.4 Der allererste Prompt zur Projekt-Initialisierung
Kopiere oder tippe folgenden Initial-Prompt in Claude Code ein, um den 5-Phasen-Workflow zu starten:

```text
Lass uns das Projekt initialisieren. Bitte lies die CLAUDE.md vollständig ein und halte dich ab sofort strikt an alle dort definierten Gesetze (insbesondere: KEINE Terminal-Befehle selbst ausführen, nur .md Dateien in docs/ und die README.md schreiben!). 

Wir befinden uns aktuell noch im reinen Arch Linux TTY (ohne Desktop/GUI). Unser erstes Etappenziel ist:
1. Führe jetzt Schritt A des Onboardings (System-Discovery) mit mir durch: Sag mir, welche Diagnose-Befehle ich im zweiten TTY ausführen soll, um dir meine Hardware-Daten zu liefern.
2. Erstelle danach Schritt B (README.md und docs/00-base-system/how-to-use-git-and-stow.md) und binde diese Bootstrap-Doku (docs/00-base-system/01-claude-code-tty-bootstrap.md) direkt in die Status-Tabelle der README.md ein.
3. Danach richten wir Schritt für Schritt Grafiktreiber, Hyprland, Kitty und VS Code ein, damit wir in die grafische Oberfläche wechseln können.
```

### 9.5 Alltags-Cheatsheet für die Arbeit im Dual-TTY (ohne GUI)
Solange noch kein grafischer Window-Manager läuft, nutzen wir mehrere virtuelle Konsolen (*TTYs*) parallel:
- **`Alt + F1` (oder `Strg + Alt + F1`):** Wechselt auf **`TTY1`** -> Hier bleibt **Claude Code** dauerhaft geöffnet.
- **`Alt + F2` (oder `Strg + Alt + F2`):** Wechselt auf **`TTY2`** -> Hier loggst du dich ein zweites Mal ein und führst die Befehle aus, die Claude dir auf `TTY1` vorgibt.
- **Trick gegen langes Abtippen von Logs/Outputs im TTY:**
  Leite lange Ausgaben (wie Hardware-Listen oder Fehlermeldungen) auf `TTY2` einfach mit dem `>` Operator in eine temporäre Datei im Repo um:
  ```bash
  lspci -k > ~/arch-system-repo/temp-output.txt
  ```
  Sage Claude danach auf `TTY1`: *"Lies bitte die Datei `temp-output.txt` im Repo aus, um den Output zu analysieren."* Danach löschst du die Datei auf `TTY2` wieder mit `rm ~/arch-system-repo/temp-output.txt`.

## 10. Troubleshooting & Fehler-Historie (Lern-Protokoll)

### [2026-10-18] - `bash: claude: command not found` nach NPM-Installation
- **Symptom / Fehlermeldung:** Nach erfolgreichem `npm install -g @anthropic-ai/claude-code` meldet die Shell beim Aufruf von `claude`, dass der Befehl nicht gefunden wurde.
- **Technische Ursache (Root Cause):** Die Shell sucht ausführbare Programme ausschließlich in den Verzeichnissen, die in der Umgebungsvariable `$PATH` hinterlegt sind. Das benutzerdefinierte Verzeichnis `~/.npm-global/bin` ist im Standard-Arch-System dort noch nicht eingetragen, oder die `.bashrc` wurde nach dem Eintragen noch nicht neu eingelesen (oder man nutzt `zsh` statt `bash`).
- **Gescheiterte Ansätze & Lerneffekt:** Ein erneutes Ausführen von `npm install -g ...` ändert nichts am Suchpfad der Shell.
- **Finale Lösung:** Prüfen mit `echo $PATH`, ob `/home/<user>/.npm-global/bin` enthalten ist. Falls nicht, sicherstellen, dass die Export-Zeile in der Startdatei der aktiven Shell (`~/.bashrc` bzw. `~/.zshrc`) steht, und diese mit `source ~/.bashrc` aktivieren.

## 11. Wartung, Updates & Rollback (Saubere Deinstallation)
- **Wartung & Updates:**
  - Die Systempakete (`git`, `nodejs`, `npm`, `stow`) werden regulär über `sudo pacman -Syu` aktualisiert.
  - Claude Code selbst besitzt einen integrierten Updater (`claude update`) oder kann über `npm update -g @anthropic-ai/claude-code` aktualisiert werden.
- **Vollständiger Rollback:**
  1. Claude Code global aus dem User-Space deinstallieren:
     ```bash
     npm uninstall -g @anthropic-ai/claude-code
     ```
  2. Globale NPM-Ordner und Authentifizierungsdaten löschen:
     ```bash
     rm -rf ~/.npm-global ~/.npmrc ~/.claude ~/.claude.json
     ```
  3. Die Zeile `export PATH="$HOME/.npm-global/bin:$PATH"` wieder aus der `~/.bashrc` entfernen.
