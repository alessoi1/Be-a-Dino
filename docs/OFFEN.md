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
  - [x] 7c Skins (später durch die Varianten aus L7a ersetzt)
  - [x] 7d Beleg-Dienst (`ProcessReceipt`; die bezahlten Skins entfielen, der Dienst bleibt für L8, siehe docs/MONETARISIERUNG.md)

## Ausbau (siehe `docs/KONZEPT.md`, Abschnitt Ausbau)

- [x] L1 Lobby (Spielkreis, Kreise für Shop, Dinodex, Booster; Code fertig, Studio-Test offen)
- [x] L2 Große Zahlen, neues Wachstum, Münzen (Code fertig, Studio-Test offen)
- [x] L3 50 Dinos (Platzhalter), Freischalten durch Größe (Code fertig, Studio-Test offen)
- [x] L4 Todes-Bildschirm (Zur Lobby; Revive und Kopfgeld als Robux-Knöpfe kommen in L8; Code fertig, Studio-Test offen)
- [x] L5 Autofarm (Code fertig, Studio-Test offen; das Laufen per `MoveTo` ist der unsichere Teil, siehe docs/TESTLISTE.md)
- [x] L6 Globale Ranglisten in der Lobby (Code fertig, Studio-Test offen)
- [x] L7a Varianten (Glowing, Gold, Shadow, Rainbow) für alle 50 Dinos, ersetzen die Skins (Code fertig, Studio-Test offen)
- [x] L7b Eier mit Münzen (Shop-Kreis, Chancen in Prozent, Doppelte geben Münzen zurück)
- [x] L8 Bezahltes (Wiederbeleben, Kopfgeld, vier Tränke; Glückseier entfallen; Code fertig, alle Kauftests in Studio offen)
- [x] L9 Bots: füllen die Arena bis acht Dinos auf, der kleinste geht pro eintretendem Spieler; fressen und werden gefressen (Code fertig, Studio-Test offen, Abschnitt Bots in `docs/TESTLISTE.md`)
- [ ] Dino-Optik (kantiges Low-Poly, Filmfarben, Blender-Formen mit Lauf-Animation): alle sechs Formen sind fertig und eingebaut (`docs/MODELLE.md`); offen sind Handytest (Leistung mit vielen animierten Dinos), Varianten (Gold, Shadow, Rainbow) auf den neuen Formen ansehen, Feinschliff einzelner Formen, danach Arena, Lobby und Oberfläche im selben Stil.

## Hinweise

## Kuppel und Dschungel (Version 3, siehe `docs/KONZEPT.md`)

- [x] K1 Kollision (Bäume, Felsen, Stämme blockieren; Gleiten; Ausweichen für Bots und Autofarm)
- [x] K2 Runde Arena unter Glaskuppel (alles auf Radius umgestellt; Code fertig, Studio-Test offen, siehe docs/TESTLISTE.md)
- [x] K3 Lobby seitlich an der Kuppel mit Sichtfenster (Code fertig, Studio-Test offen, siehe docs/TESTLISTE.md)
- [x] K4 Name und Size über dem Kopf (Spieler und Bots; Code fertig, Studio-Test offen, siehe docs/TESTLISTE.md)
- [x] K5 UI und Icons: K5a Icons (Platzhalter-Symbole, echte Bilder liefert der Spielentwickler, siehe docs/ICONS.md), K5b Hauptmenü-Leiste in der Lobby und Bots in der Bestenliste (Code fertig, Studio-Test offen); ein Size-Icon pro Zeile der Bestenliste ist nicht gebaut
- [x] K6 Futtermodelle je Größe, Feedback beim Fressen (Code fertig mit Platzhalterformen, echte Meshes und Sound-ID offen; Studio-Test offen, siehe docs/TESTLISTE.md)
- [x] K7 Dino-Modelle und Animationen: sechs Blender-Formen mit Laufen waren schon da; neu Idle, Fressen und Körperwippen (Code fertig, Studio-Test offen); eigener Kopf für echtes Beißen offen
- [x] K8 Dschungel-Feinschliff (Teiche, Engstellen aus Felspaaren, Deckung aus Pflanzengruppen, Lianen; Code fertig, Studio-Test offen, siehe docs/TESTLISTE.md)
- Entfallen laut Entscheidung vom 13. Oktober 2026: Health, Bite, Hunger, Nahrungstyp je Dino.

- Studio-Tests als Checkliste in `docs/TESTLISTE.md` führen (Datei bei Bedarf anlegen, Muster: `docs/TESTLISTE.md` in Glimmer Deep).
