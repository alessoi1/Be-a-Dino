# Was aus Glimmer Deep mitgenommen wurde und was später passt

Quelle: das Repo Glimmer Deep (`alessoi1/Glimmer-Deep`). Dieses Startpaket enthält bereits die Dateien unter „Schon im Paket“.

## Schon im Paket

| Datei | Zweck | Anpassung |
| --- | --- | --- |
| `rokit.toml`, `stylua.toml`, `selene.toml`, `.gitattributes`, `.gitignore` | Werkzeug-Versionen, Format, Lint, LF-Zeilenenden | unverändert |
| `.github/workflows/ci.yml` | CI auf Ubuntu, Windows, macOS (Format, Lint, Tests, Rojo-Build) | Wally-Schritt entfernt, Name `BeDino.rbxl` |
| `default.project.json` | Rojo-Projekt | Name, `ServerPackages` entfernt |
| `src/shared/Log.luau` und `tests/specs/Log.spec.luau` | zentrales Logging | Präfix `[BeDino]` |
| `src/server/RejectLimiter.luau` und Spec | Log abgelehnter Remote-Aufrufe, begrenzt | unverändert |
| `src/shared/Remotes.luau` | Remote-Verwaltung | Namensliste leer |
| `tests/Framework.luau`, `tests/run.luau` | Mini-Testframework für Lune | Spec-Liste auf zwei Einträge gekürzt |
| `CLAUDE.md` | Arbeitsregeln für Claude Code | auf das neue Spiel angepasst |

## Bei Bedarf später aus Glimmer Deep kopieren (nicht im Paket)

| Datei in Glimmer Deep | Wann | Hinweis |
| --- | --- | --- |
| `src/server/DataService.luau`, `DataLogic.luau`, `Migrations.luau` | sobald gespeichert wird | ProfileStore über Wally (`lm-loleris/profilestore@1.0.3`, `wally.toml`, `wally.lock`); Profilformat und Migrationen neu schreiben |
| `src/server/ReceiptService.luau`, `ShopService.luau`, `PaidRandomPolicy.luau` | bei Käufen | idempotente Belege, `PolicyService`-Prüfung |
| `src/server/MovementService.luau` | bei Bewegungsprüfung | Muster für serverseitige Plausibilisierung prüfen |
| `docs/SETUP.md` | Einrichtung auf neuem Rechner | Abschnitte zu Rokit, Rojo, Studio; Namen anpassen |
| `docs/OFFEN.md`, `docs/ENTSCHEIDUNGEN.md`, `docs/TESTLISTE.md` | als Muster | Form übernehmen (offene Punkte, Entscheidungen mit Begründung, Studio-Checkliste) |

## Arbeitsweise (bewährt, steht auch in CLAUDE.md)

- Pro Schritt ein Branch, kleine Commits, PR gegen `main`, CI grün, dann Squash-Merge.
- Reine Logik zuerst mit Tests (Lune), Roblox-Dienste dünn halten.
- Studio-Tests als Checkliste in `docs/TESTLISTE.md` führen; Behauptungen über Studio erst nach einem Test.
- Beim Aufsetzen des neuen Repos Branch-Schutz für `main` aktivieren (Pflicht-CI).
