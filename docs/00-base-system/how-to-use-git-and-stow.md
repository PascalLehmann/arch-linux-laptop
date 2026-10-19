# Handbuch: Git & GNU Stow für dieses Repository

- **Maschine / Hostname:** thinkpad
- **Kategorie:** 00-Base
- **Status:** Aktiv & Stabil
- **Letztes Update:** 2026-10-19
- **Verwandte Dokumentation:** [README.md](../../README.md), [01-claude-code-tty-bootstrap.md](./01-claude-code-tty-bootstrap.md)

---

> Dieses Dokument ist die zentrale Werkzeug-Referenz für die Verwaltung des gesamten Repositorys und folgt bewusst **nicht** dem 11-Sektionen-Standard-Template unserer sonstigen `docs/`-Dateien (siehe `CLAUDE.md`), da es sich um eine übergeordnete Methoden-Anleitung statt um die Dokumentation eines einzelnen Programms/Treibers handelt.

## Inhaltsverzeichnis

1. [Git-Grundlagen & Architektur](#1-git-grundlagen--architektur)
2. [Die wichtigsten Git-Befehle im Alltag](#2-die-wichtigsten-git-befehle-im-alltag)
3. [Fehlerkorrektur mit Git](#3-fehlerkorrektur-mit-git)
4. [Conventional Commits Standard](#4-conventional-commits-standard)
5. [Migration des Git-Remotes (GitHub → Self-Hosted)](#5-migration-des-git-remotes-github--self-hosted)
6. [GNU Stow Deep-Dive](#6-gnu-stow-deep-dive)
7. [Code-Transfer zwischen Maschinen-Repos](#7-code-transfer-zwischen-maschinen-repos)

---

## 1. Git-Grundlagen & Architektur

Git ist ein *verteiltes Versionskontrollsystem* (**Distributed Version Control System**, DVCS). Anders als bei älteren, zentralisierten Systemen besitzt bei Git **jeder** Klon des Repositorys die komplette Historie — es gibt keinen einzigen "Master-Server", ohne den nichts funktioniert. Für unseren Workflow sind vier Bereiche entscheidend, die man sich als vier aufeinanderfolgende Stationen vorstellen kann, durch die eine Änderung wandert:

```text
┌─────────────────┐    git add    ┌──────────────────┐   git commit   ┌──────────────┐   git push   ┌───────────────┐
│ Working Directory│ ────────────► │  Staging Area     │ ──────────────► │ Local Repo    │ ───────────► │ Remote Repo    │
│  (dein Dateisystem)│              │  (Index)          │                 │ (.git-Ordner) │              │ (z.B. GitHub)  │
└─────────────────┘    git restore └──────────────────┘   git reset     └──────────────┘   git pull   └───────────────┘
      ▲                     --staged                                                                          │
      └──────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

- **Working Directory (Arbeitsverzeichnis):** Der tatsächliche Ordner `~/arch-linux-laptop` auf deiner Festplatte, so wie du ihn im Dateimanager oder Editor siehst. Jede Änderung, die du an einer Datei vornimmst, passiert zuerst hier und ist für Git erstmal nur eine "unverfolgte" (*untracked*) oder "modifizierte" (*modified*) Änderung.
- **Staging Area / Index:** Eine Zwischenablage *innerhalb* von Git (technisch eine einzelne Binärdatei `.git/index`). Hier legst du gezielt fest, **welche** Änderungen beim nächsten Commit tatsächlich gespeichert werden sollen. Das erlaubt es, z. B. nur 2 von 5 geänderten Dateien in einen sauberen, thematisch zusammenhängenden Commit zu packen, während die anderen 3 für einen separaten Commit zurückbleiben.
- **Local Repo (Lokales Repository):** Der verborgene Ordner `.git/` im Projekt-Root. Er enthält die **komplette Historie** aller jemals erstellten Commits als eine Kette von Snapshots, inklusive aller Branches. Ein `git commit` schreibt den Inhalt der Staging Area dauerhaft (lokal) in diese Historie.
- **Remote Repo:** Eine Kopie des Repositorys auf einem entfernten Server (aktuell GitHub, später unser Self-Hosted-Server). Dient als Backup, Synchronisations-Punkt zwischen mehreren Geräten und — falls gewünscht — als Kollaborations-Plattform.

## 2. Die wichtigsten Git-Befehle im Alltag

### `git status`
```bash
git status
```
Zeigt den aktuellen Zustand des Working Directory und der Staging Area: Welche Dateien sind geändert, neu (untracked) oder bereits zum Commit vorgemerkt (staged)? **Dies sollte vor jeder weiteren Git-Aktion dein erster Reflex sein.**

### `git diff`
```bash
git diff            # Zeigt Änderungen im Working Directory, die noch NICHT gestaged sind
git diff --staged   # Zeigt Änderungen, die bereits in der Staging Area liegen (also was beim nächsten Commit gespeichert würde)
```
`diff` zeigt den exakten Zeilen-für-Zeilen-Unterschied (*Delta*) zwischen zwei Zuständen an (Minus-Zeilen = gelöscht, Plus-Zeilen = hinzugefügt).

### `git add`
```bash
git add docs/02-desktop-ricing/hyprland.md   # Eine spezifische Datei stagen
git add docs/                                 # Alle Änderungen in einem Ordner stagen
```
Verschiebt Änderungen aus dem Working Directory in die Staging Area. **Wichtig:** `git add .` oder `git add -A` (alles im gesamten Repo stagen) ist bewusst zu vermeiden — gezieltes, dateiweises Stagen verhindert, dass versehentlich unfertige Dateien oder (im Dotfiles-Kontext besonders kritisch) Dateien mit Zugangsdaten/Secrets mitgecommittet werden.

### `git commit`
```bash
git commit -m "docs(02-ricing): Hyprland Monitor-Konfiguration dokumentiert"
```
Schreibt den aktuellen Inhalt der Staging Area als neuen, unveränderlichen Snapshot in die Historie des Local Repo. `-m` *(message)* übergibt die Commit-Nachricht direkt als Parameter, statt einen Text-Editor zu öffnen.

### `git log`
```bash
git log                     # Vollständige Historie mit Autor, Datum, vollem Hash und Commit-Message
git log --oneline           # Kompakte Ein-Zeilen-Darstellung (kurzer Hash + Message) – guter Überblick
git log --oneline --graph   # Zusätzlich mit ASCII-Grafik der Branch-Verzweigungen
```

### `git push` / `git pull`
```bash
git push origin main   # Lokale Commits auf den Branch 'main' des Remote 'origin' hochladen
git pull origin main    # Commits vom Remote 'origin'/'main' herunterladen und mit dem lokalen Stand zusammenführen
```
- `origin` ist der Standard-Spitzname (*Alias*) für die URL des Remote-Repositorys (siehe Abschnitt 5).
- `git pull` ist technisch eine Kurzform für zwei Befehle in Folge: `git fetch` (neue Commits vom Remote herunterladen, aber noch nicht einmischen) + `git merge` (die heruntergeladenen Commits mit deinem lokalen Branch zusammenführen).

## 3. Fehlerkorrektur mit Git

### `git restore` — Änderungen verwerfen oder unstagen
```bash
git restore --staged <datei>   # Datei aus der Staging Area zurück ins Working Directory nehmen (OHNE den Dateiinhalt zu verändern)
git restore <datei>            # ACHTUNG: Verwirft alle ungespeicherten Änderungen im Working Directory unwiderruflich!
```

### `git reset` — Commits zurücknehmen
```bash
git reset --soft HEAD~1   # Letzten Commit rückgängig machen, Änderungen bleiben GESTAGED erhalten
git reset HEAD~1          # (= --mixed, Standard) Letzten Commit rückgängig machen, Änderungen bleiben im Working Directory, aber UNGESTAGED
git reset --hard HEAD~1   # ACHTUNG: Letzten Commit UND alle zugehörigen Dateiänderungen unwiderruflich löschen
```
- `HEAD` ist ein Zeiger auf den aktuell ausgecheckten Commit; `HEAD~1` bedeutet "ein Commit vor dem aktuellen Stand".
- **`--hard` ist destruktiv** und sollte nur verwendet werden, wenn du dir absolut sicher bist, dass die betroffenen Änderungen nirgendwo mehr gebraucht werden.

### `.gitignore` — Dateien dauerhaft von Git ausschließen
Eine Textdatei im Projekt-Root, in der pro Zeile ein Datei-/Ordner-Muster steht, das Git komplett ignorieren soll (taucht nicht einmal mehr als "untracked" in `git status` auf). Für unser Repo sinnvoll z. B.:
```gitignore
temp-*.txt
*.log
.env
```

## 4. Conventional Commits Standard

Jede Commit-Message folgt dem Schema:
```text
<typ>(<scope>): <kurze, prägnante Beschreibung im Imperativ>
```

| Typ | Bedeutung | Beispiel |
|---|---|---|
| `docs` | Reine Dokumentations-Änderung (unser häufigster Typ, da Claude ausschließlich `.md`-Dateien schreibt) | `docs(01-hardware): NVIDIA PRIME-Setup dokumentiert` |
| `feat` | Eine komplett neue Komponente/Funktionalität wurde eingerichtet | `feat(02-ricing): Hyprland Compositor eingerichtet` |
| `fix` | Korrektur eines Fehlers an einer bereits bestehenden Einrichtung | `fix(03-cli): Kitty-Font-Rendering auf HiDPI korrigiert` |
| `refactor` | Strukturelle Umgestaltung ohne Verhaltensänderung (z. B. Dotfiles neu organisiert) | `refactor(dotfiles): Shell-Konfiguration in eigenes Stow-Paket ausgelagert` |

- **`<scope>`:** Der betroffene Bereich, meist die Doku-Kategorie (`00-base`, `01-hardware`, `02-ricing`, `03-cli`, `04-apps`, `05-services`) oder `dotfiles`/`readme`.
- **Warum dieser Standard?** Eine einheitliche, maschinenlesbare Commit-Historie erlaubt es, später automatisiert Änderungs-Logs (*Changelogs*) zu generieren, und macht beim Durchsuchen der Historie (`git log --oneline`) sofort erkennbar, *was für eine Art* von Änderung jeder Commit enthält, ohne den Diff lesen zu müssen.

## 5. Migration des Git-Remotes (GitHub → Self-Hosted)

Der aktuell konfigurierte Remote-Server lässt sich jederzeit nahtlos wechseln, ohne die lokale Historie zu verlieren:

```bash
git remote -v
```
- Zeigt alle konfigurierten Remotes mit ihrer vollen URL an (`-v` = *verbose*). Standardmäßig existiert nur `origin` mit der GitHub-URL.

```bash
git remote set-url origin https://git.<deine-domain>.tld/<user>/arch-linux-laptop.git
```
- Überschreibt die hinterlegte URL für den Remote-Namen `origin`, **ohne** dass der Alias `origin` selbst umbenannt werden muss. Alle lokalen Branches, die bereits auf `origin` "tracken" (verfolgen), zeigen danach automatisch auf den neuen Server.
- Nach der Umstellung einmalig prüfen mit `git remote -v`, anschließend testen mit `git push origin main` (bzw. `git fetch origin`), ob Authentifizierung und Verbindung zum neuen Server funktionieren.
- **Wichtig:** Die lokale Commit-Historie (`.git/`-Ordner) ist davon komplett unberührt — es wird nur der *Ziel-Server* für zukünftige `push`/`pull`-Vorgänge geändert.

### SSH statt HTTPS für den Remote-Zugriff (bereits für GitHub umgesetzt)

Unabhängig vom Ziel-Server (GitHub oder später Self-Hosted) unterscheidet Git zusätzlich **zwei Transport-Protokolle**, über die eine Remote-URL angesprochen werden kann. Beide sind komplett unabhängig vom eigentlichen Server-Wechsel aus dem vorigen Abschnitt:

| Protokoll | URL-Format | Authentifizierung |
|---|---|---|
| HTTPS | `https://github.com/<user>/<repo>.git` | Benutzername + Personal Access Token (oder Credential-Helper) |
| SSH | `git@github.com:<user>/<repo>.git` | Privater SSH-Key aus `~/.ssh/` |

**Umstellung von HTTPS auf SSH** (genau derselbe Befehl wie bei der Server-Migration — nur ändert sich das Protokoll in der URL, nicht der Server):
```bash
git remote set-url origin git@github.com:<user>/<repo>.git
```

**Verifizierung der SSH-Authentifizierung**, bevor man sich auf einen `push` verlässt:
```bash
ssh -T git@github.com
```
- `-T`: Unterdrückt die Zuweisung eines Pseudo-Terminals, da wir hier keine interaktive Shell auf GitHubs Servern brauchen, sondern lediglich sehen wollen, ob der SSH-Handshake (Schlüssel-Authentifizierung) erfolgreich war.
- Erwartete Ausgabe bei Erfolg: `Hi <username>! You've successfully authenticated, but GitHub does not provide shell access.` — die Fehlermeldung "no shell access" ist hierbei **kein** Problem, sondern exakt das erwartete Verhalten, da GitHub über SSH bewusst nur Git-Operationen, keinen echten Login erlaubt.

**Passphrase-Caching mit `ssh-agent`:** Ist der private Schlüssel (wie empfohlen) zusätzlich mit einer Passphrase verschlüsselt, fragt Git bei *jedem* `push`/`pull`/`fetch` erneut danach. Um die Passphrase nur einmal pro Login-Session einzugeben:
```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_github
```
- `ssh-agent -s`: Startet einen Hintergrund-Prozess (*Daemon*), der entschlüsselte private Schlüssel ausschließlich im Arbeitsspeicher vorhält — die Passphrase selbst wird dabei nirgends auf der Festplatte gespeichert. `-s` lässt den Agent seine Umgebungsvariablen (`SSH_AUTH_SOCK`, `SSH_AGENT_PID`) im Bourne-Shell-Format ausgeben; `eval "$(...)"` übernimmt diese direkt in die aktuelle Shell-Sitzung, damit nachfolgende SSH-Aufrufe den Agent überhaupt finden.
- `ssh-add`: Entschlüsselt den angegebenen Key einmalig (einzige Passphrase-Abfrage) und übergibt den entschlüsselten Schlüssel an den laufenden Agent-Prozess.
- Danach nutzt jeder `git push`/`git pull` in dieser Terminal-Sitzung automatisch den im Agent zwischengespeicherten Schlüssel, ohne erneute Passphrase-Eingabe — bis der Agent-Prozess endet (z. B. beim Logout oder Neustart).

## 6. GNU Stow Deep-Dive

### Funktionsweise: Symlinking
GNU Stow verwaltet Dotfiles nach dem Prinzip der *Symlink-Farm*: Die tatsächlichen Konfigurationsdateien liegen **ausschließlich** im Repository unter `dotfiles/<paket>/`, niemals direkt in `~/`. Stow erstellt stattdessen *symbolische Links* (**Symlinks** — Verweise, die wie Wegweiser auf die echte Datei zeigen) im Home-Verzeichnis, die auf die echten Dateien im Repo verweisen.

**Vorteil:** Das gesamte Dotfiles-Setup bleibt zu 100 % versioniert und portabel. Ändert man eine Config über den Symlink in `~/.config/...`, bearbeitet man in Wirklichkeit direkt die Datei im Git-Repo — jede Änderung kann sofort committed werden.

### Ordnerstruktur-Logik
Stow geht von einem *Ziel-Verzeichnis* (**Target**, standardmäßig das Verzeichnis, aus dem heraus man `stow` aufruft, meist `~/`) und einem *Stow-Verzeichnis* (**Dir**, in unserem Fall `dotfiles/`) aus. Die Ordnerstruktur **innerhalb** eines Pakets muss exakt die Zielstruktur relativ zu `~/` spiegeln:

```text
dotfiles/
└── kitty/                      # Paketname = beliebiger, aber sprechender Name
    └── .config/
        └── kitty/
            └── kitty.conf      # Wird gelinkt zu: ~/.config/kitty/kitty.conf
```

### Die wichtigsten Stow-Befehle

Ausführung immer **aus dem `dotfiles/`-Ordner heraus**:

```bash
cd ~/arch-linux-laptop/dotfiles
stow -v kitty       # Paket verlinken (symlinken)
stow -v -R kitty     # "Restow": Paket erst entlinken, dann neu verlinken (nach Struktur-Änderungen im Paket)
stow -v -D kitty     # Paket entlinken (alle zugehörigen Symlinks entfernen)
```
- `-v` *(verbose)*: Gibt jeden einzelnen Symlink-Vorgang als Textzeile aus, statt stillschweigend zu arbeiten — essenziell, um bei Fehlern zu sehen, welche genaue Datei betroffen war.
- `-R` *(restow)*: Intern nichts anderes als ein `-D` (Entlinken) gefolgt von einem normalen Stow-Vorgang. Nötig, wenn sich die Ordnerstruktur *innerhalb* des Pakets geändert hat (z. B. eine Datei umbenannt wurde) und die alten Symlinks sonst verwaist (*dangling*) im System zurückbleiben würden.
- `-D` *(delete)*: Entfernt ausschließlich die von Stow erzeugten Symlinks. Die Originaldateien im Repository (`dotfiles/<paket>/`) bleiben dabei unangetastet — Stow löscht niemals echte Dateien, sondern nur seine eigenen Verweise.
- **Standard-Ziel:** Ohne weitere Angabe geht Stow davon aus, dass das Zielverzeichnis das *Elternverzeichnis* von `dotfiles/` ist (`~/arch-linux-laptop/dotfiles/../` = `~/arch-linux-laptop/`). Da wir die Symlinks aber tatsächlich im **echten Home-Verzeichnis** (`~`) benötigen, wird stets explizit mit `-t ~` (*target*) gearbeitet:
  ```bash
  stow -v -t ~ kitty
  ```

### Umgang mit Konflikten
Stow verweigert den Link-Vorgang, wenn am Zielort bereits eine **echte** (nicht-symlinke) Datei existiert — etwa die automatisch beim ersten Programmstart generierte Standard-Config. Lösung: Die bestehende echte Datei zunächst in das entsprechende `dotfiles/<paket>/`-Verzeichnis **verschieben** (nicht kopieren, damit keine Duplikate entstehen), erst danach erneut `stow -v -t ~ <paket>` ausführen.

## 7. Code-Transfer zwischen Maschinen-Repos

Da jede Maschine (Desktop, Zweit-PC, Laptop, Server) ihr **eigenes** Repository besitzt, werden bewährte Dotfiles oder Dokus gezielt manuell übertragen statt die Repos zu verschmelzen:

1. Die betreffende Datei (z. B. `dotfiles/kitty/.config/kitty/kitty.conf`) wird aus dem Quell-Repo kopiert und im Ziel-Repo an derselben relativen Stow-Position eingefügt.
2. **Maschinen-spezifische Werte zwingend anpassen** — typischerweise:
   - Monitor-Bezeichnungen und Auflösungen (z. B. in Hyprland-Configs: `DP-1` vs. `eDP-1`, andere Auflösung/Hz)
   - GPU-spezifische Umgebungsvariablen (z. B. NVIDIA-PRIME-Variablen sind auf einem reinen AMD- oder Intel-System ohne Hybrid-Grafik schlicht überflüssig)
   - Lokale IP-Adressen, Hostnamen oder SSH-Host-Aliase
   - Pfade zu maschinenspezifischen Storage-Mounts
3. In der jeweiligen `docs/`-Datei ist unter der Sektion **"Maschinen-Spezifische Werte"** (siehe Standard-Template in `CLAUDE.md`) immer explizit vermerkt, welche Zeilen bei einer Übernahme in ein anderes Repo angepasst werden müssen — dort nachschlagen, bevor eine Config 1:1 übernommen wird.
4. Erst nach Anpassung der maschinenspezifischen Werte: `stow -v -R -t ~ <paket>` im Ziel-Repo ausführen.
