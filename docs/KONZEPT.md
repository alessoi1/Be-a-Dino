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

| Stufe | Dino | ab Punkten | Größe (zu Beginn der Stufe) | Tempo |
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

Stand 10. Oktober 2026:

- **Fortschritt bei Tod:** Neustart als kleinster Dino (Compy). Die Punkte-Beteiligung des Fressers bleibt wie oben.
- **Modelle:** Eigene Blender-Modelle (`assets/models/`, `.rbxm`) von Anfang an. Folge: Für Roadmap-Schritt 2 bis 3 reichen Platzhalter-Parts, die Logik hängt nicht vom Modell ab. Die Modell-Pipeline (Größe, Polygonzahl für Mobile) muss vor Schritt 4 stehen.
- **Steuerung:** Bewegung plus Sprint. Sprint braucht Ausdauer oder Cooldown (Werte in `Config`), und der Server plausibilisiert Tempo inklusive Sprint.
- **Spielerzahl:** 12 bis 24 pro Server.
- **Persistenz:** Freigeschaltete Dinos werden gespeichert (DataService mit ProfileStore, Profil mit `version`). Das zieht Paket-Setup (`wally.toml`) nach vorn, nur nach Rückfrage.

Ergänzt am selben Tag:

- **Neustart ausnahmslos:** Wer gefressen wird, startet immer als Compy, egal welche Stufe vorher erreicht war. Freigeschaltete Dinos geben keinen Start-Vorteil.
- **Freischalten:** Ein Dino gilt als freigeschaltet, sobald er einmal erreicht wurde. Nutzen: eine Collection-Ansicht, in der Spieler sehen, welche Dinos sie bereits erreicht haben (bestätigt). Skins und Skin-Auswahl sind ebenfalls geplant, ohne Werte. Beides wird bei Schritt 7 nochmals geprüft.
- **Sprint:** Ausdauerleiste (Halten-Button auf Mobile), Tempofaktor circa 1,5 (Platzhalter in `Config`). Server verwaltet Ausdauer und plausibilisiert Tempo.
- **Monetarisierung:** Skins plus Futter-Booster. Booster dürfen nur das Futter-Wachstum betreffen, nie Tempo oder Fressen. Laut CLAUDE.md erst nach Rückfrage und Prüfung der aktuellen Roblox-Richtlinien umsetzen. Zeitlich nach Schritt 7.
- **Look:** Niedlich Low-Poly, Arbeitstitel „Be a Dino“ bleibt vorerst.

Ergänzt zu Schritt 5 (Fressen):

- **Größe wächst fließend:** Zwischen den Stufenwerten in `Config/Dinos` wächst die Größe mit den Punkten (Spalte „Größe“ ist die Größe zu Beginn der Stufe). Auf der letzten Stufe bleibt sie gleich. Dadurch kann man auch innerhalb einer Stufe gefressen werden.
- **Keine Kollision zwischen Spielern:** Spieler laufen durcheinander hindurch, damit ein großer Dino einen kleinen erreicht. Boden und Wände bleiben fest.
- **Respawn:** 3 Sekunden nach dem Gefressenwerden, dann vier Sekunden Schutz. Der Spawnpunkt ist von mehreren Zufallsorten der, der am weitesten von anderen Spielern entfernt liegt.
- **Gefressenwerden:** Der Dino verschwindet mit einer Wolke (keine Leiche). Beide Beteiligten sehen kurz eine Meldung.

Ergänzt zu Schritt 7 (Speichern, Skins, Shop):

- **Aufteilung:** 7a Speichern, 7b Collection-Menü, 7c Skins, 7d Shop. Jeder Teil ist ein eigener Branch und PR.
- **Speichern:** ProfileStore über Wally (`lm-loleris/profilestore@1.0.3`, genehmigt). Gespeichert werden erreichte Dinos und der Bestwert; später Skins und Kaufbelege. Die laufende Runde wird nicht gespeichert.
- **Ladefehler:** Der Spieler spielt als Gast (ohne Speichern, Shop gesperrt) und sieht einen Hinweis. Kein Kick, außer wenn der Spielstand auf einem anderen Server geöffnet wurde.
- **Futter-Booster:** Weggelassen. Erst nach Spieltests und neuer Richtlinienprüfung entscheiden (indirekter PvP-Vorteil gegen Robux).
- **Skins:** Pro Dino ein kostenloser Skin (durch Erreichen einer Stufe) und ein bezahlter (Developer Product). Skins ändern keine Werte. Namen und Farben werden von mir vorgeschlagen und von dir geändert.
- **Keine bezahlten Zufallsobjekte.**
- **Skins (7c):** Standard, ein freispielbarer und ein bezahlter Skin pro Dino. Freigespielt wird durch Erreichen der nächsten Stufe (Compy: Raptor, Raptor: Stego, Stego: T-Rex) und beim T-Rex durch einen Bestwert von 1000 Punkten (Platzhalter). Gewählt wird pro Dino und gilt für jede erreichte Karte. Der Wechsel passiert sofort ohne Bestätigung. Bezahlte Skins bleiben bis 7d unsichtbar (`productId = 0`).

Ergänzt zu Schritt 7d (Shop):

- **Kaufweg:** Developer Products, `ProcessReceipt` (nur ein Beleg-Handler, bestätigt erst nach dem Speichern). Der Kaufdialog kommt direkt vom Client, es gibt keinen `BuySkin`-Remote. Die Vergabe ist von selbst idempotent (`ownedSkins` ist eine Menge), es gibt keinen Beleg-Verlauf im Profil.
- **Texte:** „View offer“, kein Preis im Spiel. Gäste und Spieler, deren Profil noch lädt, können nicht kaufen.
- **Nicht listen:** Die Produkte werden vorerst nur im Spiel verkauft, nicht in der Roblox-Store-Ansicht.
- Details, Checkliste und offene Prüfungen stehen in `docs/MONETARISIERUNG.md`.

Ergänzt nach dem ersten Studio-Test (10. Oktober 2026):

- **Arena größer:** 500 × 500 Studs statt 400 × 400 (für 12 bis 24 Spieler), dazu 450 statt 300 Futterstücke, damit die Futterdichte gleich bleibt. Beides ist ein Startwert und wird mit mehreren Spielern und auf einem echten Handy noch angepasst (mehr Futterteile kosten Leistung).

Ergänzt: Oase in der Mitte (10. Oktober 2026):

- **Treffpunkt:** In der Mitte der Arena liegt die „Oase“ (Radius 60 Studs, 80 der 450 Futterstücke) mit dichterem und besserem Futter (Gewichte klein 40, mittel 40, groß 20, außen 85 / 12 / 3). Eine blaue Fläche und eine Leuchtsäule zeigen, wo sie liegt. Dort treffen sich die Spieler, und größere fressen kleinere.
- **Spawn:** Niemand erscheint in der Oase oder bis 20 Studs daneben.
- Alle Werte sind Startwerte und werden mit mehreren Spielern abgestimmt (`Config/Food`, Block `zones.center`).

Ergänzt: Sprache im Spiel (10. Oktober 2026):

- **Englisch:** Alle Texte, die Spieler sehen, sind englisch (`src/shared/Strings.luau`), damit das Spiel international verständlich ist. Die Projektdokumentation und die Zusammenarbeit bleiben deutsch. Zahlen werden mit Punkt geschrieben (zum Beispiel ×1.4). Weitere Sprachen später über eine Übersetzungstabelle möglich.

## Ausbau (Version 2, 10. Oktober 2026)

Nach dem erfolgreichen ersten Studio-Test (Schritte 2 bis 7, Oase, Baseplate-Fix, englische Texte) wünscht sich der Spielentwickler einen großen Ausbau. Alles hier ist beschlossen, die Umsetzung kommt in kleinen Schritten mit je einem Plan.

**Wünsche:**

1. **Todes-Bildschirm** mit drei Auswahlen: Wiederbeleben in gleicher Größe (Robux), Rache (Robux) und Zur Lobby (gratis).
2. **Autofarm:** Button über dem Sprint-Button, gratis, sammelt automatisch Punkte.
3. **Booster-Reiter:** verschiedene Tränke zum Kaufen (Robux).
4. **Lobby:** Wer das Spiel betritt, landet in einer Lobby über der Arena, sieht auf das Spielfeld herab und betritt einen Spielkreis, um mitzuspielen.
5. **Shop** als eigener Kreis in der Lobby (Skins, später mehr).
6. **Dinodex** (die heutige Sammlung) und **Booster** ebenfalls als Kreise in der Lobby.
7. **Globale Ranglisten** in der Lobby aller Spieler: meiste Kills, größte jemals erreichte Größe, längste Spielzeit.
8. **Etwa 50 Dinos.**
9. Dinos werden freigeschaltet, wenn man größer wird.
10. **Varianten** jedes Dinos: Glowing, Gold, Shadow, Rainbow. Man bekommt sie über **Eier**, die man mit **Münzen** kauft. Münzen verdient man, wenn man als Dino größer wird.
11. **Große Zahlen** bei der Größe (der erste Dino etwa 0 bis 1000, danach immer weiter bis in die Billionen), weil das attraktiver wirkt.

**Entscheidungen:**

- **Reihenfolge:** Zuerst alles Gratis (Lobby, große Zahlen und 50 Dinos, Todes-Bildschirm, Autofarm, globale Ranglisten, Varianten und Eier), das Bezahlte ganz am Ende.
- **Rache:** Der Killer wird für alle sichtbar markiert (Kopfgeld). Wer ihn frisst, bekommt Münzen. Der Rächer startet klein, kein direkter PvP-Vorteil.
- **Bezahlte Vorteile:** Wiederbeleben in gleicher Größe und Tränke sind erlaubt und werden als letzter Schritt gebaut, nach Prüfung der dann aktuellen Roblox-Richtlinien. Die frühere Regel „kein bezahlter PvP-Vorteil“ und die Entscheidung gegen Booster sind damit ersetzt (siehe `CLAUDE.md`). Skins und Varianten ändern weiterhin keine Werte.
- **Münzen:** Nur durch Spielen verdienbar, nie mit Robux kaufbar.
- **Glückseier gegen Robux** (erhöhte Chancen auf gute Aussehen): vielleicht, noch nicht entschieden. Wären bezahlte Zufallsobjekte mit allen Pflichten (Chancen in Prozent, `PolicyService`, kein Handel).
- **Beim Planen noch zu klären** (pro Schritt): Zahlenwörter international (K, M, B, T …), Platzhalter-Dinos für die 50 Dinos (erzeugt, bis echte Modelle da sind), Verhältnis von Varianten zu den heutigen Skins, Autofarm gegen AFK-Missbrauch (zählt Autofarm für „längste Spielzeit“?), Größe der Lobby und Verhalten beim Verlassen der Arena.

**Roadmap Ausbau:**

1. **L1 Lobby:** Lobby über der Arena, Spielkreis, Kreise für Shop, Dinodex und Booster, Spielzustand Lobby oder Spiel.
2. **L2 Große Zahlen und Fortschritt:** neues Wachstum und Futterwert, Anzeige K/M/B/T, Münzen.
3. **L3 50 Dinos:** Platzhalter, Freischalten durch Größe.
4. **L4 Todes-Bildschirm** mit Zur Lobby (gratis), Rache (Kopfgeld) und später den bezahlten Knöpfen.
5. **L5 Autofarm.**
6. **L6 Globale Ranglisten** (Kills, größte Größe, Spielzeit) auf Tafeln in der Lobby.
7. **L7 Varianten und Eier** mit Münzen.
8. **L8 Bezahltes:** Wiederbeleben, Tränke, eventuell Glückseier, nach Richtlinienprüfung (`docs/MONETARISIERUNG.md`).

## Weiterhin offen

- Skins und Shop (7c, 7d): Richtlinien für Developer Products und Altersgruppen vor 7d nochmals gegen die aktuelle Roblox-Dokumentation prüfen. Die Produkte legt der Spielentwickler im Creator Hub an.
- Sprint: Verbrauch, Aufladerate, ob man beim Sprinten fressen darf (Werte beim Testen).
