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

- Eine runde, flache Arena unter einer Glaskuppel (ursprünglich ein Quadrat, seit K2 rund), später mehrere Zonen oder Hindernisse zum Verstecken.
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

**L1 Lobby (entschieden):** Plattform 140 × 140 Studs, 100 Studs über dem Arena-Boden, mittig über der Oase, mit gläsernem Geländer. Vier Kreise: Play (Radius 12, 2 Sekunden Warten), Shop, Dinodex und Boosters (Radius 7, öffnen sofort ihr Fenster). Höchstens 24 Spieler gleichzeitig in der Arena. In der Arena bringt ein „Lobby“-Knopf nach 5 Sekunden zurück (tippen bricht ab). Wer gefressen wird, landet nach dem Neustart-Countdown in der Lobby. Dinodex und Skin-Liste gibt es nur noch über den Kreis in der Lobby. Shop und Boosters sind vorerst „Coming soon“-Fenster. Die Werte stehen in `Config/Lobby`.

**L2 Große Zahlen (entschieden):** Die Zahl, die der Spieler sieht, heißt **Size** und wird kurz geschrieben (K, M, B, T, Qa, Qi, danach `1.2e21`). Der Futterwert wächst mit der Stufe (Futtereinheit pro Stufe), damit jede Stufe etwa 40 Futterstücke außerhalb der Oase braucht (erlaubt sind 20 bis 80, ein Test prüft das). Für die 4 vorhandenen Dinos gilt bis L3: Compy ab 0, Raptor ab 1K, Stego ab 1M, T-Rex ab 1B. Die 50 Dinos aus L3 laufen dann gleichmäßig von 1K bis 1T. **Münzen:** `5 × Stufennummer` für jede neu erreichte Stufe (übersprungene zählen), in jeder Runde neu verdienbar, gespeichert im Profil (Version 3), nie für Robux. Der goldene T-Rex-Skin braucht 5B Bestwert. Die Debug-Taste `G` gibt 25 % der Strecke bis zur nächsten Stufe.

**L3 50 Dinos (entschieden):** 50 Dinos von klein bis riesig, die Namen sind echte Dinosaurier in kurzer Form, grob nach Größe geordnet (die vier alten `compy`, `raptor`, `stego`, `trex` bleiben dabei; die Liste steht in `tools/GenerateStages.luau` und `Strings.dinos`). Die Schwellen wachsen gleichmäßig von 1K (zweiter Dino) bis 1T (letzter), die Figur wächst von 1 auf 8, das Tempo fällt von 22 auf 18, jede Stufe braucht etwa 40 Futterstücke. Die Fressregel bleibt (1,2-mal so groß), das heißt bei 50 Stufen etwa 4 bis 5 Stufen größer; `eatRatio` ist der erste Regler, falls es zu selten zum Fressen kommt. Aussehen: Platzhalter aus sechs Körperformen (runner, biped, duckbill, armored, horned, longneck) mit Länge, Höhe, Merkmal und zwei Farben pro Dino, bis es echte Modelle gibt. Freigeschaltet wird, wer einen Dino erreicht (Dinodex). **Skins:** Nur die vier alten Dinos behalten ihre Skins, die anderen 46 haben vorerst keine. In L7 ersetzen die Varianten (Glowing, Gold, Shadow, Rainbow) für alle Dinos den heutigen Skin-Mechanismus.

**L4 Todes-Bildschirm (entschieden):** Wer gefressen wird, sieht 15 Sekunden lang ein Fenster mit drei Auswahlen: **Revive at your size** (Robux), **Kopfgeld auf den Killer** (Robux) und **Back to lobby** (gratis). Die beiden bezahlten Auswahlen sind ausgegraut („soon“) und kommen in L8 mit dem Bezahlen und der Richtlinienprüfung. Das **Kopfgeld** ersetzt die frühere Idee „Revenge mit Neustart“: Der Gefressene setzt es auf den Killer. Der Markierte trägt ein Schild „BOUNTY ×3“ über dem Kopf, das alle sehen. Wer ihn frisst, bekommt **3-mal so viele Münzen wie sonst**. Es gibt höchstens ein Kopfgeld pro Ziel (erneutes Setzen verlängert nur die Zeit von 120 Sekunden), und es endet, wenn der Markierte gefressen wird, in die Lobby geht oder die Runde verlässt. **Neu: Münzen fürs Fressen** eines Spielers: Stufennummer des Opfers × 1 (Stufe 30 gibt 30, mit Kopfgeld 90). Zum Testen setzt in Studio die Taste `B` ein Kopfgeld auf alle anderen Spieler in der Arena. Werte in `Config/Death`, `Config/Bounty`, `Config/Coins`.

**L5 Autofarm (entschieden):** Ein gratis Knopf „Auto“ über dem Sprint-Button (am PC auch die Taste `F`) lässt den Dino in der Arena selbst Futter sammeln. Der **Server entscheidet**, ob er an ist (nur in der Arena, höchstens 10 Minuten, dann einmal neu tippen, Ende bei Tod, Lobby und neuer Runde); das **Laufen macht der Client**, wie bei jedem Spieler, und alle Serverregeln (Tempoprüfung, Futteraufnahme, Münzen) gelten unverändert. Der Autofarm läuft zum Futter mit dem besten Verhältnis aus Wert und Entfernung und **flieht vor größeren Spielern**, die ihn fressen könnten (Fressregel 1,2-mal so groß); er sprintet nicht und frisst keine Spieler. Wer selbst steuert, übernimmt sofort. **Autofarm-Zeit zählt für die Spielzeit** (Rangliste in L6), Größe und Münzen sind dieselben wie beim normalen Spielen. Werte in `Config/AutoFarm`.

**L6 Globale Ranglisten (entschieden):** Drei Tafeln an der Nordwand der Lobby zeigen die Top 10 aller Spieler: **Most kills** (gefressene Spieler insgesamt), **Biggest size** (größte je erreichte Größe, das ist der Bestwert) und **Longest playtime** (Zeit **in der Arena** insgesamt, Autofarm zählt mit). Auf den Tafeln stehen Roblox-Benutzernamen. Jede Liste ist ein eigener OrderedDataStore (ProfileStore ist dafür nicht gedacht); die Wahrheit liegt im Profil (Version 4: `kills`, `playSeconds`), der Dienst schreibt nur Kopien, alle 120 Sekunden pro Spieler und beim Verlassen, und liest alle 120 Sekunden neu. Nur Spieler mit geladenem Profil kommen auf die Listen, nie Gäste. In Studio hängt an den Speichernamen `_Studio`, damit Tests die echten Listen nicht berühren. Werte in `Config/Leaderboards`.

**L7 Varianten und Eier (entschieden):** Jeder der 50 Dinos hat neben dem normalen Aussehen vier Varianten: **Glowing** (häufig, Neon und heller), **Gold** (Metall in Gold), **Shadow** (fast schwarz mit lila Akzenten) und **Rainbow** (am seltensten, Farben wechseln im Kreis, auf dem Client nur für die 8 nächsten Dinos in höchstens 150 Studs). Varianten ändern nie Werte. Man bekommt sie aus **Eiern**, die man mit **Münzen** kauft (200 Münzen, Chancen Glowing 70 %, Gold 22 %, Shadow 6 %, Rainbow 2 %, alle Chancen werden in Prozent angezeigt). Ein Ei gibt eine zufällige Variante für einen zufälligen **bereits erreichten** Dino; ein Doppeltes gibt 50 % der Münzen zurück. **Die Skins aus 7c entfallen** (Profil Version 5 mit Migration, die bezahlten Skins wurden nie verkauft). Gebaut in zwei Branches: L7a die Varianten (Daten, Aussehen, Auswahl im Dinodex, Rainbow-Effekt, Studio-Taste `V`), L7b die Eier im Shop-Kreis (Server würfelt und bucht, speichert vor der Anzeige; Eier nur in der Lobby und mit geladenem Profil, 1 s Pause). Werte in `Config/Variants` und `Config/Eggs`.

**Roadmap Ausbau:**

1. **L1 Lobby:** Lobby über der Arena, Spielkreis, Kreise für Shop, Dinodex und Booster, Spielzustand Lobby oder Spiel.
2. **L2 Große Zahlen und Fortschritt:** neues Wachstum und Futterwert, Anzeige K/M/B/T, Münzen.
3. **L3 50 Dinos:** Platzhalter, Freischalten durch Größe.
4. **L4 Todes-Bildschirm** mit Zur Lobby (gratis), Rache (Kopfgeld) und später den bezahlten Knöpfen.
5. **L5 Autofarm.**
6. **L6 Globale Ranglisten** (Kills, größte Größe, Spielzeit) auf Tafeln in der Lobby.
7. **L7 Varianten und Eier** mit Münzen.
8. **L8 Bezahltes (gebaut):** Wiederbeleben in gleicher Größe, Kopfgeld auf den Killer und vier Tränke (Wachstum, Münzen, Tempo, Schutz) über Developer Products; Glückseier gegen Robux werden nicht gebaut. Ein gekauftes Revive oder Kopfgeld wird als gespeicherter Anspruch im Profil (Version 6) geführt und sofort genutzt, wenn das Todes-Fenster offen ist, sonst beim nächsten Tod. Tränke laufen nur in der Arena. Werte und Produkte in `Config/Offers`, Regeln in `docs/MONETARISIERUNG.md`.

## Kuppel und Dschungel (Version 3, 13. Oktober 2026)

Der Spielentwickler hat eine Feature-Liste zu Futter, Arena, Lobby, Modellen, Namen, Bots, UI und Kollision vorgelegt. Hier steht, was davon schon da ist, was neu kommt und was entfällt.

**Entscheidungen (13. Oktober 2026):**

- **Kein Health-/Bite-/Hunger-System.** Gefressen wird wie bei Agar.io: Wer die Fressregel erfüllt (1,2-mal so groß, Abstand klein) und den anderen berührt, frisst ihn sofort. Es gibt keine Lebensbalken, keine Bisse mit Schaden, keinen Hunger und kein Verhungern. Damit entfallen aus der Liste: Health, Bite, Hunger-/Heilungsbalken, „Nahrungstyp je Dino“ (Fleisch-/Pflanzenfresser) und die Werte „Health“ und „Bite“ pro Dino. Der Grund fürs Fressen ist immer derselbe: **Wachstum**.
- **Ein Futtertyp für alle:** Jeder Dino frisst dasselbe Futter und wächst durch Berühren. Die Futtermodelle sind nur Optik und zeigen die **Größe/den Wert** des Stücks (heute: klein, mittel, groß in `Config/Food`). Pro Größe gibt es mehrere Modelle (zum Beispiel klein: Beere und Farn, mittel: Frucht, groß: Fleischkeule oder Fisch). Die Werte ändern sich dadurch nicht.
- **Dino auswählen heißt nur ansehen:** In der Lobby kann man Dinos ansehen (Dinodex) und die Variante wählen. Gespielt wird weiter immer ab Compy (Entscheidung „Neustart ausnahmslos“ bleibt).
- **Modelle:** Ich baue Modelle und Animationen über die Blender-Anbindung, die UI-Icons liefert der Spielentwickler (Bilder oder Asset-IDs). Bis dahin bleiben Platzhalter, wie bei den Dino-Formen heute.

**Abgleich mit dem Stand:**

| Bereich | Schon da | Neu | Entfällt |
| --- | --- | --- | --- |
| Essen | Futter-Pool, drei Größen, Oase, Aufnahme per Server-Takt | Eigene Futtermodelle je Größe, Feedback beim Fressen (Partikel, Sound, kurzer Happs), Hinweis, wofür man frisst (Wachstum) | Nahrungstyp je Dino, Hunger/Heilung |
| Arena | Quadrat 500 × 500 (seit K2 rund, siehe unten), Mauern, Dschungel-Szenerie (Bäume, Palmen, Felsen, Baumstämme, Wasserloch) | Runde Arena unter Glaskuppel mit Streben, Dschungel ausbauen (Farne, Lianen, Wasser, Deckung, Engstellen) | |
| Lobby | Plattform 140 × 140 schwebend 100 Studs über der Mitte, Kreise für Play/Shop/Dex/Boosters | Lobby **seitlich an der Kuppel**, Sichtfenster in die Arena, gleicher Forschungsstation-Stil | schwebende Lobby über der Arena |
| Dinos | 50 Dinos aus 6 Platzhalterformen mit Laufanimation (Teile bewegen) | Eigenes Modell je Dino, Animationen Laufen, Idle, Fressen (statt Beißen), Verschwinden (statt Tod) | Health und Bite je Dino |
| Namen | Bots haben zufällige Namen (Liste plus Nummer) | Name und Size über dem Kopf (Spieler und Bots), skaliert mit Dino-Größe und Entfernung | |
| Bots | Bots fressen Futter, Spieler und andere Bots, respawnen nach 5 s, keine Teams | Neuer Name beim Respawn (optional, klein), Ausweichen vor Hindernissen | |
| Kampf/Respawn | Gleiche Regeln für alle, Fresser bekommt Punkte, Spawn weit von anderen, Schutzzeit | Spawnpunkte auf der runden Fläche (gleiche Logik) | |
| UI | Status, Sprint, Autofarm, Münzen, Todes-Fenster, Lobby-Fenster in einem Theme (`UiTheme`) | Icons für Stamina, Sprint, Size, Münzen, Autofarm; Hauptmenü, Scoreboard mit Icons | Icons für Health, Hunger, Bite |
| Kollision | Spieler und Bots gehen durcheinander durch, Boden und Mauer sind fest, Szenerie ist **nicht fest** | Bäume, Felsen, Stämme und Kuppelwand blockieren, Hüllen passend zur Größe, Gleiten statt Hängenbleiben | |

**Technische Folgen, die man leicht übersieht:**

- **Runde Arena:** Heute ist alles quadratisch gedacht (Spawn, Futterverteilung, Szenerie-Platzierung, Bot- und Autofarm-Wandabstand, Oase). Eine Kreisform braucht dort überall „Abstand zum Rand“ als Radiusprüfung. Das ist reine Logik und wird mit Tests abgedeckt.
- **Größe der Kuppel:** Der größte Dino hat Größe 8. Als Startwert schlage ich **Durchmesser 600 Studs** vor (Fläche etwa 283.000 statt 250.000 Quadrat-Studs heute), damit die Futterdichte vergleichbar bleibt. Wird beim Testen angepasst.
- **Kollision und Bewegung:** Bäume blockieren per vereinfachter Hülle (Zylinder oder Quader), nicht per Mesh. Der Spieler läuft über Humanoid-Physik und gleitet an glatten Hüllen entlang. Die **Bots** laufen heute geradeaus per `MoveTo` und der **Autofarm** ebenso. Beide müssen Hindernissen ausweichen, sonst bleiben sie an Bäumen hängen. Plan: einfache Lenkung (seitlich ausweichen, Hindernisse aus der Szenerie-Liste), ohne Pfadfindung, solange es reicht. Der Server prüft Tempo und Position weiter wie bisher (`MoveCheck`).
- **Handy:** Glaskuppel ohne echte Spiegelung (halbtransparent, Streben als wenige Teile), Reflexion nur angedeutet. Bäume und Felsen als schlanke Modelle, Kollision unsichtbar und einfach. Alles an Teilezahl und Frame-Zeit auf dem Handy prüfen.
- **Namensschilder:** Ein `BillboardGui` pro Dino ist bei 24 Spielern plus Bots in Ordnung, wenn Größe und Sichtweite begrenzt sind (nur nahe Dinos, aktualisiert im Takt).
- **Animationen:** Heute bewegt `DinoAnim` Körperteile. Idle, Fressen und Verschwinden bauen darauf auf, bis echte Rigs mit `Motor6D` und Animationsdateien bereit sind. Ob echte Rigs für alle 50 Dinos gebaut werden, ist offen.

**Reihenfolge (jeder Schritt ein Branch mit Plan, wie bisher):**

1. **K1 Kollision:** Hüllen für Bäume, Felsen, Stämme, Wasserrand; Gleiten; Ausweichen für Bots und Autofarm; Tests für die Lenkung.
2. **K2 Runde Arena und Kuppel:** Kreisboden, runde Wand, Glaskuppel mit Streben, alles auf Radius umgestellt (Spawn, Futter, Szenerie, Bots, Autofarm, Oase). Werte in `Config/Arena`.
3. **K3 Lobby an der Kuppel:** Lobby seitlich, Sichtfenster, Kreise im Stil der Forschungsstation, Ranglisten-Tafeln mitziehen, Spielkreis führt in die Arena.
4. **K4 Namen:** Name und Size über dem Kopf, Skalierung nach Größe und Entfernung, Respawn-Name für Bots.
5. **K5 UI und Icons:** Icon-Satz für Stamina, Sprint, Size, Münzen, Autofarm; Hauptmenü, Scoreboard.
6. **K6 Futter:** Futtermodelle je Größe, Feedback beim Fressen, Hinweis „Eat to grow“.
7. **K7 Dino-Modelle und Animationen:** Blender-Modelle und Animationen, zuerst eine Körperform als Test, dann die übrigen.
**K2 Runde Arena und Kuppel (gebaut, 13. Oktober 2026):** Der Boden ist eine Kreisscheibe mit **Radius 300** (600 Studs Durchmesser), die Wand ein Ring aus 64 geraden Stücken (`Config/Arena`: `radius`, `wallSegments`). Alles, was vorher ein Quadrat war, ist ein Kreis: Futter, Spawn, Szenerie (Props, Flecken, Pfade, Felsen an der Wand), Bots und Autofarm (Fliehen und Wandern bleiben im Kreis). `Arena.size` gibt es nicht mehr. **Futter:** 510 statt 450 Stücke, damit die Dichte gleich bleibt (die Fläche ist etwa 13 % größer). **Kuppel:** Eine durchsichtige Halbkugel (nur von außen zu sehen, von innen zeichnet Roblox sie nicht) und ein Gerüst aus 12 Rippen und 5 Ringen aus geraden Balken (`DomeShape`, `DomeService`, `Config/Dome`), nur Optik ohne Kollision (rund 280 Teile). Die schwebende Lobby steht bis K3 unverändert in der Kuppel. Die Werte sind Startwerte.

**K3 Lobby an der Kuppel (gebaut, 13. Oktober 2026):** Die Lobby steht nicht mehr über der Arena, sondern **südlich (+Z) neben der Kuppel auf dem Boden** (Plattform 140 × 140, Mitte bei z = 350; ein Streifen von 24 Studs liegt verdeckt unter der Wand, damit zwischen der runden Wand und der geraden Plattformkante kein Loch bleibt). Vier der 64 Wandstücke genau gegenüber der Lobby sind **Glas** (das Sichtfenster, etwa 120 Studs breit, nicht begehbar), davor stehen keine Felsen. Der Lobby-Boden ist aus Metall im Stil des Kuppelgerüsts, Geländer aus Glas an West, Ost und Süd. Die Ranglisten-Tafeln hängen an der Südseite (hinter den Spielern, die zum Fenster schauen). Spielkreise, Dinodex, Shop und Boosters bleiben wie bisher, ihre Koordinaten in `Config/Lobby` sind jetzt relativ zur Plattformmitte. Der Spielkreis bringt weiter per Teleport in die Arena. Fehler aus K2 behoben: Der Lobby-Spawn nutzte die Futter-Positionsfunktion, die seit K2 eine Kreisscheibe liefert, und hätte daneben gespawnt.

**K4 Namen (gebaut, 13. Oktober 2026):** Über jedem Dino in der Arena steht ein Schild mit **Name** (oben) und **Size** (unten, kurz geschrieben wie K, M, B). Die Roblox-Namen sind abgeschaltet. Das Schild entsteht nur auf dem Gerät des Spielers (nichts wird repliziert) und liest die Spielerwerte `Points` und `Scale` (bei Bots Attribut `Points` am Modell und den Anzeigenamen des Humanoids). Es ist ein Billboard mit Größe in Studs: Es wird mit der Entfernung kleiner wie alles andere und wächst mit dem Dino (Breite mal Skalierung hoch 0,7, damit es nicht riesig wird), schwebt mit der Größe höher und ist bei Riesen weiter zu sehen (120 + 40 mal Skalierung Studs, die letzten 30 % blenden aus). Der eigene Name ist gelb, die anderen weiß; Spieler in der Lobby haben kein Schild. Das Kopfgeld-Schild schwebt jetzt über dem Namensschild. **Bots** bekommen beim Respawn einen **neuen zufälligen Namen** (`renameOnRespawn` in `Config/Bots`). Werte in `Config/NameTags`, Logik in `NameTag` (getestet).

8. **K8 Dschungel-Feinschliff:** Farne, Lianen, Wasser, Deckung und Engstellen, Spielbarkeit für Kleine und Große (mit Messdaten aus Studio).

## Weiterhin offen

- Kuppel (V3): Durchmesser (Vorschlag 600 Studs), Zahl der echten Rigs für die 50 Dinos (alle einzeln oder pro Körperform mit Variation), Stil der Icons, Lage der Lobby (Seite der Kuppel, Höhe) und ob sie weiter 24 Spieler fasst.

- Skins und Shop (7c, 7d): Richtlinien für Developer Products und Altersgruppen vor 7d nochmals gegen die aktuelle Roblox-Dokumentation prüfen. Die Produkte legt der Spielentwickler im Creator Hub an.
- Sprint: Verbrauch, Aufladerate, ob man beim Sprinten fressen darf (Werte beim Testen).
