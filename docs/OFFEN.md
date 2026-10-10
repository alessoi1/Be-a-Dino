# Offene Punkte

Von Hand pflegen. Erledigtes mit `[x]` abhaken.

## Zuerst

- [ ] Offene Fragen in `docs/KONZEPT.md` beantworten und unter „Entscheidungen“ eintragen.
- [ ] Neues GitHub-Repo anlegen, Startpaket hineinkopieren, CI grün bekommen, Branch-Schutz für `main` einschalten (`docs/SETUP.md`).

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

## Hinweise

- Studio-Tests als Checkliste in `docs/TESTLISTE.md` führen (Datei bei Bedarf anlegen, Muster: `docs/TESTLISTE.md` in Glimmer Deep).
