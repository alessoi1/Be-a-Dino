# Offene Punkte

Von Hand pflegen. Erledigtes mit `[x]` abhaken.

## Zuerst

- [x] Offene Fragen in `docs/KONZEPT.md` beantwortet und unter „Entscheidungen“ eingetragen.
- [x] Repo auf GitHub, CI grün auf Ubuntu, Windows und macOS.
- [ ] Branch-Schutz für `main` einschalten und prüfen (GitHub, Settings, Branches: Pull Request und grüne CI verlangen, `docs/SETUP.md`).
- [ ] **Studio-Testrunde** nach `docs/STUDIO-TEST.md`: Schnelltest, dann alle Abschnitte in `docs/TESTLISTE.md`, Fehler als `fix/...`-Branches beheben.
- [ ] Echter Handy-Test (Leistung, Touch, Layout).
- [ ] Developer Products anlegen und Kauf testen (`docs/MONETARISIERUNG.md`).
- [ ] Balance mit mehreren Spielern (Futter, Punkte pro Stufe, Fressen, Sprint, Arena-Größe).
- [ ] Richtlinienprüfung vor dem Start (`docs/MONETARISIERUNG.md`, Abschnitt Checkliste).

## Roadmap (siehe Konzept)

- [x] 1 Reine Logik mit Tests: `Growth` (Punkte zu Größe und Stufe), `EatRules` (wer wen fressen darf), `FoodSpawn` (Nachwuchs).
- [x] 2 Arena (Code fertig, Studio-Test offen, siehe docs/TESTLISTE.md), Spawn, Bewegung (Mobile-Joystick), Kamera.
- [x] 3 Futter fressen und wachsen (Code fertig, Studio-Test offen, siehe docs/TESTLISTE.md).
- [x] 4 Stufenwechsel mit Platzhalter-Modellen (Code fertig, Studio-Test offen, Pipeline in docs/MODELLE.md).
- [x] 5 Fressen zwischen Spielern, Schutzzeit, Respawn (Code fertig, Studio-Test offen, siehe docs/TESTLISTE.md).
- [x] 6 Oberfläche und Handy-Test (Code fertig, Studio- und Gerätetest offen, siehe docs/TESTLISTE.md).
- [x] 7 Speichern, Skins, Monetarisierung (nach Rückfrage und Prüfung der Roblox-Regeln):
  - [x] 7a Speichern: ProfileStore, Profilformat mit Migrationen, Collection und Bestwert (Code fertig, Studio-Test offen)
  - [x] 7b Collection-Menü (Code fertig, Studio-Test offen)
  - [x] 7c Skins (ein kostenloser pro Dino; Code fertig, Studio-Test offen)
  - [x] 7d Shop (bezahlte Skins, ProcessReceipt; Code fertig, Produkte und Studio-Test offen, siehe docs/MONETARISIERUNG.md)

## Ausbau (siehe `docs/KONZEPT.md`, Abschnitt Ausbau)

- [ ] L1 Lobby (Spielkreis, Kreise für Shop, Dinodex, Booster)
- [ ] L2 Große Zahlen, neues Wachstum, Münzen
- [ ] L3 50 Dinos (Platzhalter), Freischalten durch Größe
- [ ] L4 Todes-Bildschirm (Zur Lobby, Rache mit Kopfgeld)
- [ ] L5 Autofarm
- [ ] L6 Globale Ranglisten in der Lobby
- [ ] L7 Varianten (Glowing, Gold, Shadow, Rainbow) und Eier mit Münzen
- [ ] L8 Bezahltes (Wiederbeleben, Tränke, eventuell Glückseier), nach Richtlinienprüfung

## Hinweise

- Studio-Tests als Checkliste in `docs/TESTLISTE.md` führen (Datei bei Bedarf anlegen, Muster: `docs/TESTLISTE.md` in Glimmer Deep).
