# Lokale Einrichtung (Mac und Windows)

Alle Befehle laufen im Terminal (Mac: Terminal, Windows: PowerShell) im Projektordner.

## 1. Voraussetzungen

- **Git:** Mac: `git --version` (bietet bei Bedarf die Installation an). Windows: Git for Windows von https://git-scm.com.
- **Roblox Studio:** von https://create.roblox.com herunterladen und anmelden.
- **Rokit** (verwaltet Rojo, Lune, StyLua, Selene, Wally): Release laut https://github.com/rojo-rbx/rokit herunterladen, `rokit self-install` ausführen, Terminal neu öffnen.
- **Claude Code:** https://code.claude.com/docs/en/quickstart
- **GitHub-CLI** (`gh`, https://cli.github.com) und einmal `gh auth login`, damit Claude Code Pull Requests anlegen kann.

## 2. Neues Repo anlegen

1. Auf GitHub ein neues, leeres Repo erstellen (zum Beispiel `Be-Dino`), lokal klonen.
2. Den Inhalt von `export/be-dinosaur/` aus dem Glimmer-Deep-Ordner in das neue Repo kopieren (inklusive der versteckten Dateien `.github`, `.gitignore`, `.gitattributes`).
3. Im neuen Repo:
   ```
   rokit install
   selene generate-roblox-std
   stylua --check src tests
   selene src tests
   lune run tests/run
   mkdir build
   rojo build -o build/BeDino.rbxl
   ```
   Erwartet: alles ohne Fehler, Lune meldet am Ende `N passed, 0 failed`.
4. Ersten Commit auf einem Branch machen, pushen, PR öffnen und die CI prüfen. Danach unter GitHub, Settings, Branches den Schutz für `main` einschalten (Pull Request und grüne CI verlangen).

## 3. Mit Roblox Studio verbinden

1. `rojo plugin install` ausführen, Studio neu starten.
2. In Studio ein neues Baseplate-Place anlegen (außerhalb des Repos speichern) und darin die Baseplate und die Spawn-Platte löschen: Sie liegen auf derselben Höhe wie der Boden der Arena und würden flackern (der Server entfernt sie beim Start auch selbst). Skripte kommen nur über Rojo.
3. Im Projektordner `rojo serve` starten, in Studio im Reiter Plugins im Rojo-Fenster **Connect** drücken.
4. View, **Output** öffnen, Play (F5) drücken. Erwartet: `[BeDino][Main] server started` und `[BeDino][Client] client started`.

## 4. Mit Claude Code arbeiten

```
cd Be-Dino
claude
```

Claude Code liest `CLAUDE.md` automatisch. Als Erstes `docs/KONZEPT.md`, Abschnitt Offene Fragen, durchgehen und Entscheidungen eintragen.

## Wenn etwas nicht klappt

| Symptom | Ursache und Lösung |
| --- | --- |
| `Infinite yield possible on 'ReplicatedStorage:WaitForChild("Shared")'` | Rojo ist nicht verbunden (`rojo serve` läuft nicht oder Connect fehlt). |
| Rojo meldet eine Versionsabweichung | `rojo plugin install` erneut ausführen, Studio neu starten. |
| `selene` meldet, dass die Standardbibliothek fehlt | `selene generate-roblox-std` ausführen. |
