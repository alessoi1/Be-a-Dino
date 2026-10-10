# Konzept: Be a Dino (Arbeitstitel)

Entwurf, Stand 10. Oktober 2026. Alles hier ist ein Vorschlag, bis es unter „Entscheidungen“ bestätigt ist.

## Idee in einem Satz

Eine kleine Arena: Du bist ein winziger Dino, frisst Futter, wächst, wirst bei bestimmten Größen zu einem neuen Dino und kannst kleinere Spieler fressen, während du selbst nicht gefressen werden willst.

## Spielschleife

1. Spawn als kleinster Dino (kurze Schutzzeit).
2. Futter fressen (verteilt auf der Karte) und dadurch Wachstumspunkte sammeln.
3. Die Figur wird sichtbar größer. An festen Schwellen wird sie zum nächsten Dino (anderes Modell, anderes Tempo).
4. Größere Spieler können kleinere fressen (mit Größenvorsprung). Das gibt einen Teil der Punkte des Opfers.
5. Gefressen werden: Respawn. Was vom Fortschritt bleibt, steht unter „Offene Fragen“.
6. Ziel: der größte Dino sein, alle Dinos sammeln (Fortschritt über Runden hinaus), Bestenliste.

## Dino-Stufen (Platzhalter, in `Config/Dinos`)

| Stufe | Dino | ab Punkten | Größe | Tempo |
| --- | --- | --- | --- | --- |
| 1 | Compy | 0 | 1 | 20 |
| 2 | Raptor | 50 | 1,8 | 22 |
| 3 | Stego | 200 | 3 | 18 |
| 4 | T-Rex | 600 | 5 | 20 |

Größere Dinos sind stärker, aber nicht zwingend schneller, damit Kleine entkommen können. Werte werden beim Testen ausbalanciert.

## Arena

- Eine quadratische, flache Arena mit Begrenzung, später mehrere Zonen oder Hindernisse zum Verstecken.
- Futter ist über die Karte verteilt und wächst nach. Größere Futterarten geben mehr Punkte.
- Kleine Karte, damit sich Spieler oft begegnen (Agar.io-Prinzip). Spielerzahl pro Server wird in Studio gemessen.

## Regeln für Fressen (Entwurf)

- Ein Spieler darf einen anderen fressen, wenn seine Größe mindestens `eatRatio` mal so groß ist (Start: 1,2) und der Abstand klein genug ist.
- Nach dem Respawn ist der Spieler kurz geschützt (`spawnProtectionSeconds`).
- Der Fresser bekommt einen Teil der Punkte des Opfers (Anteil in der Config).
- Alles entscheidet der Server (siehe CLAUDE.md).

## Technik-Überblick

| Dienst | Aufgabe |
| --- | --- |
| ArenaService | Arena aufbauen, Spieler spawnen und zurücksetzen |
| FoodService | Futter verteilen, Aufnahme prüfen, Nachwuchs |
| GrowthService | Punkte, Größe und Stufenwechsel (reine Logik in `Growth`) |
| EatingService | Fressen zwischen Spielern prüfen und ausführen |
| (später) DataService | Freigeschaltete Dinos, Skins, Bestwerte speichern |
| (später) ShopService | Skins, Booster nach Rückfrage |

Reine Logik zuerst mit Tests: `Growth` (Punkte zu Größe und Stufe), `EatRules` (wer wen darf), `FoodSpawn` (Nachwuchs).

## Roadmap

1. Reine Logik mit Tests: Wachstum, Stufen, Fressregeln.
2. Arena mit Spawn, Bewegung (Mobile-Joystick) und Kamera, die mit der Größe mitwächst.
3. Futter fressen und wachsen (nur Server-Logik plus einfache Anzeige).
4. Stufenwechsel mit einfachen Platzhalter-Modellen aus Parts.
5. Fressen zwischen Spielern, Schutzzeit, Respawn.
6. Oberfläche: Größenanzeige, Bestenliste, Handy-Test.
7. Speichern (freigeschaltete Dinos), Skins, erste Monetarisierung nach Prüfung der Regeln.

## Roblox-Regeln (vor Launch prüfen)

- Richtlinien zu PvP und Gewaltdarstellung (altersgerecht, kein Blut).
- Bezahlte Zufallsobjekte nur mit Chancenanzeige und Einschränkung per `PolicyService` (oder ganz weglassen).
- Kein Vorteil im PvP gegen Robux ohne sorgfältige Prüfung.
- Kinder- und Jugendschutz, Altersfreigabe im Fragebogen korrekt ausfüllen.

## Offene Fragen (bitte klären)

1. **Modelle:** Eigene Dino-Modelle (Blender) oder zunächst einfache Blockformen aus Parts? (Toolbox ist tabu.)
2. **Fortschritt bei Tod:** Wird man als kleinster Dino neu geboren, oder bleibt die erreichte Stufe teilweise erhalten? Das bestimmt, wie hart das Spiel ist.
3. **Persistenz:** Was wird über Runden hinaus gespeichert (freigeschaltete Dinos, Skins, Bestwerte)?
4. **Spielerzahl und Kartengröße:** Zielwert pro Server (Vorschlag: 12 bis 24).
5. **Monetarisierung:** Nur Skins, oder auch Booster (Futter-Booster, Tempo)? Boosts im PvP sind heikel.
6. **Steuerung:** Nur Bewegung, oder auch eine Aktion (Sprint, Biss)?
7. **Name und Look:** Stil (Low-Poly, niedlich), Arbeitstitel, Farben.

## Entscheidungen

(Noch keine. Hier eintragen, was bestätigt ist, mit Datum.)
