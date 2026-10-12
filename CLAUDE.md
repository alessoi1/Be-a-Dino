# Be a Dino (Arbeitstitel)

Roblox-Spiel in Luau: Kleine Arena (wie Agar.io oder Be Fish). Der Spieler ist ein kleiner Dino, frisst Futter, das auf der Karte verteilt ist, wird größer und wird bei bestimmten Größen zum nächsten Dino. Größere Spieler können kleinere fressen.
Das ausführliche Konzept steht in `docs/KONZEPT.md`. Bei Widersprüchen zwischen diesem File und dem Konzept: nachfragen, nicht raten.

## Zusammenarbeit

- Antworte auf Deutsch. Code, Kommentare, Variablennamen und Commit-Messages sind Englisch. Texte, die Spieler sehen, stehen in `src/shared/Strings.luau` (Englisch, damit das Spiel international verständlich ist).
- Arbeite in kleinen Schritten: erst kurzer Plan mit Dateiliste, dann Umsetzung. Eine Funktion pro Branch.
- Schreibe Tests zuerst für Wachstum, Stufenwechsel, Fressregeln (wer wen fressen darf), Futter-Nachwuchs und Respawn (später Käufe).
- Frage nach, bevor du Werte (Größen, Tempo, Schwellen), Datenformate oder Monetarisierung änderst.
- Sage offen, wenn etwas nur in Roblox Studio getestet werden kann. Behaupte nie, etwas laufe, wenn du es nicht ausgeführt hast.

## Plattform: Mac und Windows

Das Projekt wird auf Mac und Windows bearbeitet. Deshalb:
- Nur plattformneutrale Befehle und Skripte. Keine bash-only-Skripte; Hilfsskripte bevorzugt in Luau (Lune) oder Python.
- Relative Pfade mit `/`. Keine absoluten Pfade im Repo.
- Zeilenenden sind LF (`.gitattributes`: `* text=auto eol=lf`). Ändere das nicht.
- Dateinamen konsequent in der gleichen Schreibweise (macOS ist standardmäßig nicht case-sensitive, CI und Linux schon).
- Keine Datei darf von der Plattform abhängen (kein `.DS_Store`, kein `Thumbs.db` im Repo).

## Befehle

```
rokit install                    # Werkzeuge aus rokit.toml installieren
wally install                    # Pakete aus wally.toml (ServerPackages, nicht im Git; vor rojo build nötig)
rojo serve                       # Live-Sync nach Studio (im Rojo-Plugin "Connect")
mkdir build                      # einmalig (Rojo legt den Ordner nicht an, er ist nicht im Git)
rojo build -o build/BeDino.rbxl
stylua src tests tools           # formatieren (Prüfung: stylua --check src tests tools)
selene generate-roblox-std       # einmalig, erzeugt roblox.yml (nicht im Git)
selene src tests tools           # Lint
lune run tools/GenerateStages    # gibt die 50 Stufenzeilen für Config/Dinos aus (Balance neu rechnen)
lune run tests/run               # Tests
```

Sobald ein Paket gebraucht wird (zum Beispiel ProfileStore für Spielstände): `wally.toml` anlegen, `wally install`, `ServerPackages` in `default.project.json` eintragen und den Schritt in `.github/workflows/ci.yml` ergänzen. Neue Abhängigkeiten nur nach Rückfrage.

Vor jedem Commit: `stylua --check`, `selene`, Tests. Schlägt etwas fehl, erst beheben. Neue Spec-Dateien in `tests/run.luau` eintragen.

## Projektstruktur

- `src/server` wird zu ServerScriptService (Dienste, zum Beispiel: Arena, Food, Growth, Eating, Respawn; später Data, Shop).
- `src/client` wird zu StarterPlayerScripts (UI, Eingabe, Kamera, Effekte, keine Spielwerte).
- `src/shared` wird zu ReplicatedStorage (Config, Typen, Strings, reine Hilfsfunktionen, `Log`, `Remotes`).
- `tests/` Tests, `assets/models/` exportierte `.rbxm`, `docs/` Konzept und Entscheidungen.
- Rojo-Dateien: `Name.server.luau`, `Name.client.luau`, ModuleScripts als `Name.luau`, Ordner mit `init.luau`.
- Bearbeite Skripte nur im Repo, nie direkt in Studio (sonst überschreibt Rojo sie). Fasse die `.rbxl`-Datei nicht an.

## Luau-Regeln

- Jede Datei beginnt mit `--!strict`. Typen für Funktionen und Daten angeben.
- Keine globalen Variablen. Keine veralteten Funktionen: `task.wait`, `task.spawn`, `task.delay` statt `wait`, `spawn`, `delay`.
- Alle Spielwerte (Größen, Tempo, Schwellen, Futtermenge, Zeiten) liegen in `src/shared/Config/`. Keine magischen Zahlen im Code.
- Dienste sind Module mit klarer Schnittstelle. Kleine Funktionen, früh zurückkehren, Fehler abfangen und loggen, nicht verschlucken.
- Reine Logik (Wachstum, Stufen, Fressregeln, Futter-Nachwuchs) so schreiben, dass sie ohne Studio testbar ist (keine Roblox-Dienste direkt darin).
- Viele kleine Dinge (Futter) nicht als Hunderte `Touched`-Ereignisse lösen: Der Server prüft Abstände in einem Takt und hält Futter in einer Datenstruktur; Teile nach Möglichkeit wiederverwenden (Pool) statt ständig neu zu erzeugen.

## Logging und Debugging

Alles wird mit Logs versehen, damit Fehler leicht nachvollziehbar sind.
- Geloggt wird nur über `src/shared/Log.luau` (`local log = Log.new("Dienstname")`). Kein loses `print` oder `warn` im Spielcode.
- Level: `debug` (hochfrequent, standardmäßig aus), `info` (normale Ereignisse), `warn` (abgelehnte Eingaben, unerwartete aber behandelte Fälle), `error` (Fehler, die eine Aktion abbrechen).
- Jeder Dienst loggt Start, Spieler betreten/verlassen, Stufenwechsel, Gefressenwerden (Opfer, Täter, Größen), Respawns und jeden abgefangenen Fehler.
- Jeder Remote-Handler loggt abgelehnte Aufrufe (Remote, Spieler, Grund) auf `warn`, begrenzt über `RejectLimiter`.
- Kontext als Tabelle mitgeben (`log.warn("eat rejected", { userId = id, reason = "too_far" })`), nicht in den Text bauen. Spieler nur über `UserId` identifizieren.
- Reine Logik loggt nicht selbst; der aufrufende Dienst loggt das Ergebnis und Fehler.
- Keine Schlüssel, Tokens oder persönliche Daten in Logs. Hochfrequente Ereignisse (jedes gefressene Futter) nur auf `debug`.
- Jeder `pcall` loggt den Fehler mit Kontext, bevor er behandelt wird.

## Server-Autorität und Sicherheit (harte Regeln)

- Der Server entscheidet über Größe, Futteraufnahme, Fressen zwischen Spielern, Stufenwechsel, Respawn und Käufe. Der Client sendet nur Absichten (Bewegungsrichtung, Aktion), nie Größen oder Treffer.
- Jeder RemoteEvent/RemoteFunction-Handler prüft Typ, Wertebereich, Berechtigung und Cooldown. Ratenlimit pro Spieler.
- Fressen: Abstand, Größenverhältnis und Schutzzeit prüft nur der Server aus den Werten im Server-Zustand, nie aus Clientangaben. Bewegung: Tempo und Position serverseitig plausibilisieren (Teleport- und Speed-Hacks abfangen).
- Zeitwerte nur aus der Serverzeit (`os.time()` im Server).
- Vertraue nie Daten aus `RemoteEvent`-Argumenten, Attributen oder Instanzen, die der Client verändern kann.
- Keine Skripte oder Modelle aus der Roblox-Toolbox übernehmen. Eigene oder geprüfte Assets nur.
- Keine Schlüssel, Tokens oder Open-Cloud-Keys im Repo oder in Chat-Ausgaben.

## Spielerdaten (sobald gespeichert wird)

- Erst nur im Speicher (Größe, Stufe pro Runde). Gespeichert wird, was über die Runde hinaus bleibt (zum Beispiel freigeschaltete Dinos, Skins, Bestwerte): nur über einen DataService mit ProfileStore, kein direkter DataStore-Zugriff im Spielcode.
- Das Profil hat eine `version`-Nummer. Jede Änderung am Format bekommt eine Migration und einen Test.
- Muster und Code dafür liegen im Projekt Glimmer Deep (`DataService`, `Migrations`, `ProfileData`), siehe `docs/MITNEHMEN.md`.

## Roblox-Regeln und Monetarisierung

- Käufe nur über `MarketplaceService`. `ProcessReceipt` bestätigt erst nach erfolgreichem Speichern und ist idempotent.
- Zufallsobjekte gegen Robux (zum Beispiel Eier mit zufälligem Dino): alle Chancen als Prozent anzeigen, für eingeschränkte Spieler per `PolicyService` (`ArePaidRandomItemsRestricted`) ausblenden. Im Zweifel gar keine bezahlten Zufallsobjekte.
- Skins sind frei kaufbar und ändern keine Werte.
- Bezahlte Vorteile im PvP (Wiederbeleben in gleicher Größe, Tränke) hat der Spielentwickler am 10. Oktober 2026 ausdrücklich freigegeben (siehe `docs/KONZEPT.md`, Ausbau). Sie werden erst ganz am Ende gebaut, nach Prüfung der dann aktuellen Roblox-Richtlinien, und jeder weitere bezahlte Vorteil braucht wieder eine Rückfrage. Das gilt nicht für Skins und Varianten, die Werte nie ändern.
- Münzen gibt es nur durch Spielen, nie gegen Robux. Glückseier gegen Robux sind noch nicht entschieden; falls sie gebaut werden, gelten die Regeln für bezahlte Zufallsobjekte oben ohne Ausnahme (alle Chancen als Prozent, auch die erhöhten, `PolicyService`, kein Handel mit den Ergebnissen).
- PvP-Darstellung altersgerecht: kein Blut, keine realistische Gewalt (Dino „verschwindet“ mit Effekt).
- Kauftexte neutral („View offer“), nie drängend („Last chance“).
- Die Regeln ändern sich. Vor Launch gegen die aktuelle Roblox-Dokumentation prüfen (Abschnitt Roblox-Regeln in `docs/KONZEPT.md`).

## Mobile zuerst

Die meisten Spieler dieser Art Spiel sitzen am Handy: große Buttons, Joystick-Steuerung, wenige Meldungen gleichzeitig, schlanke Modelle, wenige Teile in der Arena. UI immer auf Handy-Größe prüfen.

## Git

- Branches: `feature/kurzer-name`, `fix/kurzer-name`. Kein direkter Push auf `main`, kein Force-Push.
- Commit-Messages Englisch, kurz im Imperativ („Add growth rules and tests“). Kleine, einzelne Commits. Nur ausdrücklich genannte Dateien mit `git add <Pfad>` (nie `git add -A`).
- Nicht ins Repo: `Packages/`, `ServerPackages/`, `build/`, `.env`, Schlüssel, lokale Studio-Dateien.
- Lösche oder verschiebe keine Dateien außerhalb des Projektordners. Keine neuen Abhängigkeiten ohne Rückfrage.

## Fertig heißt

Code formatiert, Lint sauber, Tests grün, Regeln oben eingehalten, kurze Notiz, was geändert wurde und was nur in Studio zu prüfen ist.

## Aktueller Stand

(Von Hand pflegen.) Die Roadmap-Schritte 1 bis 7 und der Ausbau L1 bis L8 (Lobby, große Zahlen und Münzen, 50 Dinos, Todes-Bildschirm mit Kopfgeld, Autofarm, globale Ranglisten, Varianten, Eier, bezahlte Angebote) sind im Code fertig, aber alles mit Roblox-Diensten ist noch nie in Studio gelaufen (Checklisten in `docs/TESTLISTE.md`, Anleitung in `docs/STUDIO-TEST.md`). Offen: alle Studio-Tests, auch die Kauftests (siehe `docs/MONETARISIERUNG.md`). Entscheidungen stehen in `docs/KONZEPT.md`, offene Punkte in `docs/OFFEN.md`.
