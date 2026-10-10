# Studio-Testliste

Von Hand pflegen. Alles hier ist nur in Roblox Studio prüfbar (`rojo serve`, im Plugin „Connect“, dann Play).
Zum Prüfen auf dem Handy: Studio Test-Tab, Geräte-Emulator.

Vorbereitung, Reihenfolge und Fehlerberichte stehen in `docs/STUDIO-TEST.md`.

**Seit der Lobby (Ausbau L1) startet jeder Spieler in der Lobby.** Für alle Tests mit Arena zuerst in den grünen Play-Kreis stellen (2 Sekunden). Dinodex, Skins und Shop öffnen nur über ihre Kreise in der Lobby, die Taste `G` (Debug) wirkt nur in der Arena.

**Seit L2 (große Zahlen) sind die Stufen weit auseinander** (Compy ab 0, Raptor ab 1K, Stego ab 1M, T-Rex ab 1B). Die Zahlen in den älteren Abschnitten dieser Datei („50 Punkte“, „+25“) stammen aus der Zeit davor: Ein Druck auf `G` gibt jetzt 25 % der Strecke bis zur nächsten Stufe, und das Futter ist auf höheren Stufen mehr wert.

## Schritt 2: Arena, Bewegung, Sprint, Kamera

Stand: noch nicht in Studio getestet.

- [ ] Output zeigt beim Start `server started`, `arena built`, `started` für PlayerState, ArenaService und MovementService, ohne Fehler.
- [ ] Arena erscheint (Boden, vier Wände), Spieler spawnt innerhalb der Wände (Log `spawned`).
- [ ] Man kommt nicht aus der Arena heraus. Springen ist ausgeschaltet.
- [ ] Neuer Spawn nach Reset der Figur (zum Beispiel `Humanoid.Health = 0` in der Konsole) setzt wieder an einen zufälligen Ort, ohne `movement rejected` im Log.
- [ ] WASD und Joystick (Emulator Handy) bewegen die Figur flüssig.
- [ ] Sprint-Button (halten) und Linke Umschalttaste: Tempo steigt, die Leiste sinkt, nach Loslassen und einer Sekunde Pause füllt sie sich wieder.
- [ ] Bei leerer Leiste endet der Sprint, erneuter Start erst ab dem Mindestwert.
- [ ] Sprint-Button sitzt unten rechts in der Ecke (Abstand `BUTTON_MARGIN` in `SprintControl`) und ist gut erreichbar. Im Handy-Emulator ist der Springen-Button von Roblox weg (Log `jump button hidden`). Steht stattdessen `jump button not found`, überlappen sich beide, dann bitte melden.
- [ ] Tempo-Check: in der Konsole (Server) die Figur weit versetzen (`HumanoidRootPart.CFrame += Vector3.new(100, 0, 0)`). Sie wird zurückgesetzt, das Log zeigt `movement rejected` (höchstens alle 5 Sekunden).
- [ ] Debug-Taste `G` (nur Studio) gibt Punkte: Bei 50 wird die Figur größer (Log `stage changed`), die Kamera rückt sanft weiter weg.
- [ ] Nach dem Wachsen versinkt die Figur nicht im Boden und fällt nicht durch.
- [ ] Teststart mit mehreren Spielern (Test-Tab, 2 bis 3 Spieler): jeder hat eigene Ausdauer und Größe.
- [ ] Auf einem Live-Server (nicht Studio) gibt es keinen `DebugGrow`-Remote und kein `studio debug helper`-Log.

## Schritt 3: Futter fressen und wachsen

Stand: noch nicht in Studio getestet.

- [ ] Output zeigt `food placed` mit `count = 450`, kein `food config invalid`.
- [ ] Futter liegt verteilt in der Arena, innerhalb der Wände, in drei Größen und Farben (viele kleine, wenige große).
- [ ] Beim Drüberlaufen verschwindet das Futter, und die Anzeige oben zählt die Punkte hoch.
- [ ] Nach etwa 8 Sekunden erscheint das Futter an einer neuen Stelle.
- [ ] Bei 50 Punkten wird aus Compy ein Raptor (Log `stage changed`, Anzeige und Figur größer, Kamera weiter weg). Die Leiste springt zurück auf 0 und füllt sich zur nächsten Stufe.
- [ ] Aufnahmeradius fühlt sich passend an: auch als größerer Dino wird nicht zu viel oder zu wenig eingesammelt.
- [ ] Nach Reset der Figur (`Humanoid.Health = 0`) zeigt die Anzeige wieder Compy mit 0 Punkten.
- [ ] Mehrere Spieler (Test-Tab): jeder sammelt eigene Punkte, ein Stück bekommt nur einer.
- [ ] Handy-Emulator: Anzeige oben lesbar, verdeckt nicht den Joystick oder Sprint-Button.
- [ ] Performance: Bei 450 Teilen bleibt die Bildrate stabil (Studio Stats, `Shift+F3`). Auf einem echten Handy testen, falls möglich. Bei Rucklern `count` in `Config/Food` senken.
- [ ] Taste `G` (nur Studio) funktioniert weiter.

## Schritt 4: Dino-Modelle und Stufenwechsel

Stand: noch nicht in Studio getestet.

- [ ] Output zeigt `AppearanceService` `started`, kein `dino looks invalid`.
- [ ] Beim Start siehst du einen kleinen grünen Compy statt der Roblox-Figur (kein Kopf, keine Kleidung, keine Gesichtszüge sichtbar, keine Lebensanzeige).
- [ ] Die Füße des Dinos stehen auf dem Boden (nicht darüber, nicht darin). Falls nicht: Offsets in `Config/DinoLooks` anpassen.
- [ ] Die Blickrichtung stimmt: Der Kopf zeigt in Laufrichtung vorwärts.
- [ ] Bei 50 Punkten (Futter oder Taste `G`) wird aus Compy ein oranger Raptor, begleitet von einer Wolke. Weiter über Stego (blaugrau mit Rückenplatten) zum roten T-Rex.
- [ ] Jede Stufe sieht in der richtigen Größe aus (kein Dino versinkt oder schwebt), die Kamera passt sich an.
- [ ] Nach Reset der Figur (`Humanoid.Health = 0`) erscheint wieder der Compy.
- [ ] Andere Spieler (Test-Tab, 2 Spieler) sehen deinen Dino ebenfalls als Dino, nicht als Roblox-Figur.
- [ ] Prüfe, dass `StarterPlayer.LoadCharacterAppearance` im Explorer auf `false` steht. Ist es `true`, hat der Code trotzdem Avatarteile versteckt, aber es flackert eventuell kurz.
- [ ] Mit einem Test-Modell (`assets/models/compy.rbxm`, zum Beispiel aus 2 Parts) wird dieses statt des Platzhalters benutzt. Ein Modell mit Skript oder zu vielen Teilen wird abgelehnt (`model rejected` im Log) und der Platzhalter erscheint.

## Schritt 5: Fressen, Schutzzeit, Respawn

Stand: noch nicht in Studio getestet. Zum Testen mindestens 2 Spieler im Test-Tab, Taste `G` (nur Studio) gibt Punkte.

- [ ] Output zeigt `started` für `PlayerCollision` und `EatingService`, kein `collision setup failed`.
- [ ] Spieler laufen durcheinander hindurch (keine Kollision), stoßen aber an Wände und Boden.
- [ ] Die Figur wächst beim Fressen sichtbar mit den Punkten (nicht nur beim Stufenwechsel), ohne Ruckeln und ohne im Boden zu versinken. Kamera und Futter-Aufnahmeradius wachsen mit.
- [ ] Gleiche Größe: kein Fressen. Ab etwa 20 % mehr Größe frisst der größere Dino den kleineren, wenn er nah genug ist (Log `player eaten` mit beiden Größen und dem Abstand).
- [ ] Beim Gefressenwerden verschwindet der Dino sofort mit einer Wolke, keine Leiche bleibt liegen, und der Fresser bekommt die halben Opferpunkte.
- [ ] Beide sehen die Meldung („You ate … (+N)“ und „… ate you“), nur eine zur selben Zeit.
- [ ] Nach etwa 3 Sekunden erscheint das Opfer als Compy mit 0 Punkten an einem Ort, der möglichst weit von den anderen liegt.
- [ ] Während der 4 Sekunden Schutzzeit leuchtet der Dino weiß, und er kann nicht gefressen werden. Danach nicht mehr.
- [ ] Wer im selben Moment von zwei Größeren erreicht wird, wird nur einmal gefressen (kein doppelter Punkteabzug oder Fehler im Log).
- [ ] Reichweite fühlt sich fair an: Ein kleiner Dino kann mit Sprint entkommen (Raptor Tempo 22, Compy Sprint 30).
- [ ] Zeitquelle: Futter wächst weiter nach etwa 8 Sekunden nach, Ausdauer und Sprint verhalten sich wie vorher (Umstellung auf `ServerClock`).
- [ ] Bei weniger als 2 Spielern passiert nichts, keine Fehler im Log.

## Schritt 6: Oberfläche, Bestenliste, Handy-Test

Stand: noch nicht in Studio getestet. Zum Testen den Geräte-Emulator im Test-Tab benutzen (Gerät wählen, Hoch- und Querformat) und mindestens 2 Spieler.

Allgemein:
- [ ] Output zeigt `core gui adjusted`. Die eingebaute Roblox-Spielerliste und der Rucksack sind weg, der Chat ist da.
- [ ] Die Schrift ist rund (Fredoka) und überall gleich.
- [ ] Nichts liegt unter dem Roblox-Menüband oben, unter einer Notch oder der Gesten-Leiste (Geräte mit Notch im Emulator wählen).

Inhalte:
- [ ] **Status links oben:** Dino-Name und Punkte, darunter „N points to Raptor · ×1.0“ und eine Leiste. Beim Fressen und Wachsen aktualisiert sich alles. Auf der letzten Stufe steht „Biggest dino!“.
- [ ] **Bestenliste rechts oben:** Zeigt höchstens 5 Spieler nach Punkten, mit Rang und Name. Die eigene Zeile ist farbig. Liegt man nicht in den Top 5, steht die eigene Zeile unten mit dem echten Rang. Aktualisiert sich etwa alle 0,5 Sekunden.
- [ ] **Stufen-Meldung:** Beim Aufstieg erscheint „Du bist jetzt ein Raptor!“ in der oberen Mitte, nicht beim Neustart nach dem Gefressenwerden.
- [ ] **Fress-Meldung:** wie in Schritt 5, nur eine Meldung zur selben Zeit.
- [ ] **Neustart-Countdown:** Nach dem Gefressenwerden steht „Respawn in 3“, dann 2, 1 in der Bildmitte und verschwindet beim Respawn.

Geräte (Emulator, jeweils Hoch- und Querformat):
- [ ] Kleines Android 360 × 640
- [ ] iPhone SE 375 × 667
- [ ] iPhone 14 390 × 844
- [ ] Tablet 768 × 1024

Pro Gerät prüfen:
- [ ] Status und Bestenliste überlappen sich nicht (bei 360 Breite ist es knapp).
- [ ] Der Sprint-Button ist mindestens 72 Pixel groß, gut mit dem Daumen erreichbar und verdeckt nicht den Roblox-Joystick oder die Springen-Taste.
- [ ] Alle Texte sind gut lesbar (mindestens 14 Pixel).
- [ ] Die Meldungen verdecken das Spielfeld nicht zu sehr.
- [ ] Beim Drehen des Geräts passt sich alles an.

Nicht im Emulator prüfbar: Touch-Gefühl, Leistung auf einem echten Handy und die tatsächlichen sicheren Ränder. Das bitte einmal auf einem echten Gerät testen.

## Schritt 7a: Speichern

Stand: noch nicht in Studio getestet. Voraussetzungen, die du selbst einstellen musst:
- Das Place ist in Roblox veröffentlicht (File, Publish to Roblox).
- In den Spieleinstellungen unter Security ist „Enable Studio Access to API Services“ eingeschaltet.
- `wally install` wurde ausgeführt, dann `rojo serve`.

Ablauf:
- [ ] Output zeigt `Data started`, dann beim Betreten `loading profile` und `profile loaded` mit `status = new`.
- [ ] Ohne die oben genannten Einstellungen: `player plays as guest, nothing is saved` im Log, die Meldung „Your progress is not being saved right now.“ erscheint, das Spiel läuft normal weiter.
- [ ] Eine Stufe erreichen (Taste `G`): Log `dino reached`. Spiel beenden, wieder starten: `profile loaded` mit `status = loaded`.
- [ ] Der Bestwert bleibt nach dem Neustart erhalten und sinkt nicht, wenn man eine schlechtere Runde spielt (im Profil prüfen, etwa mit einem Test in der Befehlsleiste, bis das Collection-Menü da ist).
- [ ] Gefressenwerden löscht die erreichten Dinos nicht (nur die laufende Runde ist weg).
- [ ] Zwei Studio-Sitzungen mit demselben Konto: die ältere meldet `profile session ended` und wird mit der Meldung abgemeldet.
- [ ] Beim Verlassen: `saving and releasing profile` im Log, kein Fehler.
- [ ] `ProfileStore error` oder `overwritten by foreign data` im Log bedeutet ein Problem und ist zu melden.

## Schritt 7b: Collection-Menü

Stand: noch nicht in Studio getestet. Zum Speichern gelten die Voraussetzungen aus Schritt 7a (veröffentlichtes Place, Studio-API-Zugriff).

- [ ] Links unter dem Statusfeld sitzt ein runder Button „Dinos“, mindestens 52 Pixel groß und nicht über dem Statusfeld oder der Bestenliste.
- [ ] Tippen öffnet das Fenster „Collection“ in der Bildmitte, erneutes Tippen oder die X-Taste schließt es. Das Spiel läuft weiter.
- [ ] Am Anfang ist nur der Compy farbig, die anderen drei sind grau mit „???“ und „Reach 50 / 200 / 600 points“. Oben steht „1 of 4 dinos“.
- [ ] Mit Taste `G` auf Raptor wachsen: Die Karte wird sofort farbig, „2 von 4 Dinos“. Das Fenster aktualisiert sich auch, wenn es offen ist.
- [ ] Der Bestwert steigt beim Sammeln und bleibt nach dem Gefressenwerden stehen.
- [ ] Nach dem Gefressenwerden bleiben die erreichten Dinos in der Sammlung.
- [ ] Spiel beenden und neu starten: Sammlung und Bestwert sind wieder da (nur mit Speichern, siehe 7a).
- [ ] Gastmodus (zum Beispiel ohne Studio-API-Zugriff): Das Fenster zeigt „Not saved“, der Fortschritt der laufenden Sitzung ist trotzdem sichtbar.
- [ ] Die Karten sind lesbar, der Bereich scrollt bei kleinen Bildschirmen. Geräte wie in Schritt 6 (360 × 640, 375 × 667, 390 × 844, Tablet, jeweils Hoch- und Querformat).
- [ ] Das Fenster verdeckt nicht den Joystick und den Sprint-Button zu sehr (kann man mit dem Daumen am Rand weiterspielen).

## Schritt 7c: Skins

Stand: noch nicht in Studio getestet. Zum Speichern gelten die Voraussetzungen aus Schritt 7a. Das Profil wird mit diesem Schritt auf Version 2 migriert: Ein bereits gespeichertes Profil aus 7a sollte beim nächsten Laden `status = migrated` im Log zeigen und danach normal funktionieren.

- [ ] Output zeigt `SkinService started`, kein `skin config invalid`.
- [ ] Sammlung öffnen und auf eine erreichte Dino-Karte tippen: Es erscheint die Skin-Liste mit dem Dino-Namen als Titel und einer Zurück-Taste (`<`). Nicht erreichte Karten reagieren nicht.
- [ ] Beim Compy: „Default“ (Equipped) und „Mint“ (Locked: reach the Raptor). Bezahlte Skins (Berry, Midnight, Volcano, Frost) sind nicht zu sehen.
- [ ] Raptor erreichen (Taste `G`): „Mint“ wird zu „Equip“. Tippen wechselt zu Mint, der Compy-Platzhalter ändert die Farbe (wenn man gerade Compy ist, sofort sichtbar), die Zeile zeigt „Equipped“, und „Default“ wieder „Equip“.
- [ ] Als Raptor: Der Compy-Skin ist weiterhin wählbar, ändert aber nicht den aktuellen Raptor. Beim nächsten Neustart als Compy erscheint der gewählte Compy-Skin.
- [ ] Nach einem Stufenwechsel hat der neue Dino den dort gewählten Skin.
- [ ] Die anderen Spieler sehen den gewählten Skin (Test-Tab mit 2 Spielern).
- [ ] „Sunset“ (Stego erreichen), „Moss“ (T-Rex erreichen) und „Gold“ (Bestwert 1000 Punkte) bleiben bis dahin gesperrt, mit der passenden Bedingung als Text.
- [ ] Skins ändern kein Tempo, keine Größe und kein Fressverhalten.
- [ ] Spiel beenden und neu starten: Der gewählte Skin ist wieder da (nur mit Speichern, siehe 7a). Als Gast gilt die Wahl nur für die Sitzung.
- [ ] Schnelles Tippen auf „Equip“ erzeugt keine Fehler. Im Log erscheinen höchstens `remote call rejected`-Zeilen mit `rate_limited`, höchstens alle 5 Sekunden pro Grund.
- [ ] Skin-Liste auf kleinen Geräten (360 × 640, Querformat): Zeilen lesbar, Status-Text bricht um, die Liste scrollt, die Zeilen sind gut zu treffen.

## Schritt 7d: Shop

Stand: noch nicht in Studio getestet. Voraussetzungen und Ablauf der Produktanlage stehen in `docs/MONETARISIERUNG.md`. Ohne Produkt-IDs in `Config/Skins.luau` (alle `0`) bleiben die bezahlten Skins unsichtbar, dann gibt es nichts zu kaufen.

Vorbereitung:
- [ ] Place veröffentlicht, Studio-API-Zugriff an (siehe 7a), vier Developer Products mit 1 Robux angelegt, die IDs in `Config/Skins.luau` eingetragen.
- [ ] Output zeigt `Receipts started` und `handler registered skins`, kein `skin config invalid`.

Test (nimm zuerst ein Konto, bei dem 1 Robux nichts ausmacht, und sieh dir im Dialog den Preis an):
- [ ] In der Sammlung bei einem erreichten Dino erscheint der bezahlte Skin mit „View offer“. Bezahlte Skins mit ID 0 sind nicht zu sehen.
- [ ] Tippen öffnet den Roblox-Kaufdialog mit dem richtigen Namen und Preis. Der Dialog öffnet sich nicht von selbst, und schnelles Doppeltippen öffnet ihn nur einmal.
- [ ] Abbrechen: nichts passiert, kein Fehler, der Skin bleibt „View offer“.
- [ ] Kaufen: Im Log `receipt processed` (Spieler, Produkt, Beleg, `outcome = granted`), danach erscheint „New skin: …“, die Zeile zeigt „Equip“ und der Skin lässt sich ausrüsten.
- [ ] Spiel beenden und neu starten: Der Skin ist noch da (nur mit Speichern).
- [ ] Kein Kaufknopf als Gast: Ohne Speichern steht „Not available without saving“, und es öffnet sich kein Dialog.
- [ ] Kurz nach dem Betreten (Profil lädt noch) ist der Kaufknopf gesperrt und wird mit dem Laden freigeschaltet.
- [ ] Beleg bleibt offen, wenn der Spieler vor dem Vergeben geht (`receipt for an absent player`), und wird beim nächsten Betreten vergeben.
- [ ] Zweiter Beleg für denselben Skin vergibt nicht doppelt (`outcome = duplicate`), wird aber bestätigt.
- [ ] Skins ändern kein Tempo, keine Größe und kein Fressverhalten (Werte vor und nach dem Kauf vergleichen).
- [ ] Kaufdialog und Texte sind auf kleinen Geräten gut zu bedienen (360 × 640, Querformat).

## Oase in der Mitte

Stand: noch nicht in Studio getestet. Am besten mit mehreren Spielern.

- [ ] Output zeigt `food placed` mit `count = 450` und `oasis = 80`, kein `food config invalid`.
- [ ] In der Mitte der Arena liegt eine runde blaue Fläche (Radius 60), darüber eine dünne leuchtende Säule, die man aus der ganzen Arena sieht. Man läuft ohne Stufe oder Hängenbleiben darüber.
- [ ] Die Fläche flackert nicht (kein Überlappen mit dem Boden).
- [ ] In der Oase liegt deutlich dichter Futter, mit mehr mittleren (gelben) und großen (roten) Stücken. Außerhalb liegt wie vorher überwiegend kleines grünes Futter. Außerhalb der Oase liegt kein Futter in der Fläche.
- [ ] Gefressenes Futter in der Oase kommt wieder in der Oase nach (nach etwa 8 Sekunden), außen kommt es wieder außen nach.
- [ ] Wachstum in der Oase ist spürbar schneller. Notiere grob, wie lange man dort bis zum Raptor und zum Stego braucht.
- [ ] Spieler erscheinen nie in der Oase und nicht unmittelbar daneben (mehrmals zurücksetzen und beobachten).
- [ ] Mit mehreren Spielern: Treffen sich die Spieler wirklich in der Mitte? Ist es für kleine Dinos zu gefährlich oder gerade richtig? (Notizen für die Balance: Radius, Anzahl und Gewichte stehen in `Config/Food`.)

## Ausbau L1: Lobby

Stand: noch nicht in Studio getestet. Die Lobby ändert den Ablauf aller anderen Tests (siehe Hinweis am Anfang dieser Datei).

Start und Lobby:
- [ ] Output zeigt `LobbyService started` und `lobby built zones=4`, kein `lobby config invalid`.
- [ ] Beim Betreten stehst du auf einer Plattform hoch über der Arena (100 Studs), mit einem gläsernen Geländer ringsum. Du blickst über das Geländer auf die Arena und die Oase. Du kannst nicht hinunterfallen.
- [ ] Vier leuchtende Kreise mit schwebenden Schildern: PLAY (grün, Mitte), SHOP (gelb, links), DINODEX (blau, unten) und BOOSTERS (lila, rechts). Du erscheinst nie in einem Kreis.
- [ ] Unten steht „Step into a glowing circle“. Oben links, oben rechts und die Sprint-Taste (Arena-Oberfläche) sind in der Lobby **nicht** zu sehen.
- [ ] Die Kreise flackern nicht (keine Überlappung mit dem Boden).

Kreise:
- [ ] **Shop** und **Boosters**: Im Kreis öffnet sich ein Fenster mit „Coming soon“, beim Verlassen schließt es sich.
- [ ] **Dinodex**: Im Kreis öffnet sich die Sammlung mit den Karten und Skins (wie vorher). Mit dem X schließt man sie, beim erneuten Betreten öffnet sie sich wieder. Ohne Kreis ist sie nicht erreichbar.
- [ ] **Play**: Im Kreis erscheint „Entering the arena in 2“, dann 1. Wer vorher hinausgeht, bricht ab.

Arena betreten und zurück:
- [ ] Nach den 2 Sekunden stehst du in der Arena (an einem zufälligen Ort, nicht in der Oase, möglichst weit von anderen), du bist der kleine Compy mit weißem Schutz-Leuchten (4 Sekunden). Status, Bestenliste und Sprint-Taste erscheinen, der Lobby-Hinweis verschwindet. Im Log: `entered the arena`.
- [ ] Oben im Bestenlistenfeld stehen nur Spieler aus der Arena, nicht die aus der Lobby.
- [ ] Taste `G` gibt Punkte, aber nur in der Arena.
- [ ] Unten Mitte steht der Knopf „Lobby“. Tippen startet „Leaving in 5 (tap to cancel)“. Nochmal tippen bricht ab. Läuft die Zeit ab, bist du wieder in der Lobby, klein und mit 0 Punkten. Im Log: `back in the lobby`.
- [ ] Der Bestwert und die erreichten Dinos bleiben nach dem Zurückgehen erhalten (Dinodex prüfen).
- [ ] Gefressen werden: „Respawn in 3“, danach bist du in der **Lobby** (nicht in der Arena).
- [ ] Mit zwei Spielern: Ein Spieler in der Lobby kann nicht gefressen werden und frisst nichts. Der Spieler im Kreis sieht den anderen unten in der Arena.
- [ ] Mehr als 24 Spieler gleichzeitig lassen sich nur mit Konfigurationsänderung testen: In `Config/Lobby` `maxPlaying = 1` setzen, mit zwei Spielern testen. Der zweite sieht im Kreis „Arena full, please wait“ und kommt nicht hinein, bis der erste geht.
- [ ] Teleport hinauf und hinunter wird nicht als Tempo-Hack zurückgesetzt (kein `movement rejected` im Log).
- [ ] Sprint-Taste unten rechts, der Springen-Button des Handys ist ausgeblendet (wie im Fix davor).

## Ausbau L2: Große Zahlen, Wachstum, Münzen

Stand: noch nicht in Studio getestet. Alle Werte sind Startwerte (`Config/Dinos`, `Config/Coins`, `Config/Progress`).

Zahlen:
- [ ] Die Größe zeigt kurze Zahlen: „Compy · 340 size“, später „1.23K“, „12.3K“, „1.23M“ (nicht 1234 oder 1234567). Die Bestenliste in der Arena zeigt dieselben kurzen Zahlen.
- [ ] Die Zeile darunter zeigt „… size to Raptor · ×1.0“ mit kurzer Zahl, auf der letzten Stufe „Biggest dino!“.
- [ ] Futter bringt auf der ersten Stufe etwa 17 (klein), 51 (mittel) und 170 (groß). Nach dem Aufstieg zum Raptor sind es zehntausende (16.5K, 49.6K, 165K).
- [ ] **Tempo:** Zähle grob die Futterstücke bis zum Raptor. Erwartet sind etwa 40 außerhalb der Oase und etwa 17 in der Oase. Notiere, wie lange das dauert und ob es sich gut anfühlt.
- [ ] Dasselbe für Raptor zu Stego und Stego zu T-Rex (jeweils etwa gleich viele Stücke).
- [ ] Taste `G`: Jeder Druck bringt 25 % der Strecke bis zur nächsten Stufe (vier Drücke = nächste Stufe).
- [ ] Die Figur wächst weiter fließend zwischen den Stufen, die Fortschrittsleiste füllt sich gleichmäßig pro Stück.
- [ ] Fressen: Wer einen Spieler frisst, bekommt die Hälfte von dessen Größe. Die Meldung zeigt „You ate Anna (+1.5K)“ mit kurzer Zahl.
- [ ] Dinodex: „Best size: 12.3K“ und bei gesperrten Karten „Reach 1K size“ (kurze Zahlen). Skin „Gold“ (T-Rex): „Locked: best size 5B“.

Münzen:
- [ ] Oben links steht ein Zähler „Coins 0“. In der Arena sitzt er direkt unter dem Statusfeld und überlappt es nicht, in der Lobby in der Ecke.
- [ ] Bei jedem Aufstieg steigt der Zähler: Raptor +10, Stego +15, T-Rex +20 (Log `coins earned`). Springt man mehrere Stufen auf einmal, zählen die übersprungenen mit.
- [ ] Nach dem Zurücksetzen und erneutem Aufsteigen gibt es wieder Münzen. Münzen gehen beim Gefressenwerden nicht verloren.
- [ ] Spiel beenden und neu starten: Die Münzen sind wieder da (nur mit Speichern, siehe 7a). Das Profil aus früheren Tests wird auf Version 3 migriert (Log `status = migrated`).
- [ ] Gastmodus: Münzen zählen für die Sitzung und gehen danach verloren.

## Ausbau L3: 50 Dinos

Stand: noch nicht in Studio getestet. Zum schnellen Durchgehen: Taste `H` (nur Studio, nur Arena) springt zum nächsten Dino, `G` bringt 25 % der Strecke.

Aussehen (am besten alle 50 einmal durchgehen):
- [ ] Output zeigt keine Fehler wie `dino looks invalid` oder `no look for stage`.
- [ ] Bei jedem Sprung (`H`) wechselt der Dino sein Aussehen (Wolke, neue Form oder Farbe). Die Formen: kleine Läufer, aufrechte Raubsaurier, Entenschnabel-Saurier mit Kamm, Gepanzerte mit Rückenplatten, Gehörnte mit Halskrause und Langhälse.
- [ ] **Die Füße stehen bei jedem Dino auf dem Boden** (nicht darüber, nicht darin), auch bei den hohen Langhälsen und beim Gepanzerten (niedrige Beine).
- [ ] Nachbarn sehen verschieden aus (Form, Größe oder Farbe), keiner sieht kaputt aus (schwebende Teile, Teile die ineinander verschwinden).
- [ ] Die Figur wächst von Compy bis Titanosaur spürbar bis etwa 8-fach, die Kamera rückt weiter weg und der Dino bleibt im Bild.
- [ ] Der Neustart nach dem Gefressenwerden bringt wieder den kleinen Compy.

Zahlen und Tempo:
- [ ] Die Namen sind kurz und passen in die Karten und in das Statusfeld (längster: „Patagotitan“, „Dreadnought“, „Titanosaur“).
- [ ] Futter bringt auf jeder Stufe etwa gleich viele Stücke bis zur nächsten (Stichprobe bei den Stufen 5, 20 und 40).
- [ ] Das Tempo sinkt spürbar von 22 auf 18, ohne dass sich große Dinos zu träge anfühlen. Sprint funktioniert weiter.
- [ ] Fressen: Ein Dino frisst nur deutlich größere Opfer (etwa 4 bis 5 Stufen größer). Notiere, ob es zu selten oder zu oft passiert (`eatRatio` in `Config/Arena`).

Dinodex:
- [ ] Zeigt 50 Karten in zwei Spalten, oben „N of 50 dinos“, erreichte farbig mit Namen, die anderen als „???“ mit „Reach 1.54K size“ und so weiter. Scrollen geht flüssig (auch auf dem Handy-Emulator, 360 × 640).
- [ ] Beim Erreichen eines Dinos wird die Karte freigeschaltet (nach `H` sofort sichtbar).
- [ ] Ein Tipp auf einen Dino ohne Skins zeigt „No skins for this dino yet“. Compy, Raptor, Stego und T-Rex zeigen ihre Skins wie vorher.
- [ ] Alte Spielstände mit den Dinos `compy`, `raptor`, `stego`, `trex` bleiben erhalten.

## Ausbau L4: Todes-Bildschirm, Kopfgeld, Münzen fürs Fressen

Stand: noch nicht in Studio getestet. Am besten mit zwei Spielern (Test-Tab, Players: 2). Mit `H` oder `G` wächst ein Spieler schnell, bis er den anderen fressen kann.

Todes-Bildschirm:
- [ ] Wer gefressen wird, sieht ein Fenster „You were eaten by Anna“ mit „Closing in 15“, das herunterzählt. Es erscheint sofort und bleibt über den Neustart in der Lobby hinweg stehen (auch während „Respawn in 3“).
- [ ] Drei Zeilen: „Revive at your size (soon)“ und „Bounty on Anna (soon)“ sind ausgegraut und tun nichts, „Back to lobby“ (grün) schließt das Fenster sofort.
- [ ] Nach 15 Sekunden verschwindet das Fenster von selbst. Das Fenster erscheint nicht, wenn man nicht gefressen wurde (zum Beispiel beim „Lobby“-Knopf).
- [ ] Betritt man die Arena wieder (Play-Kreis), ist das Fenster weg.
- [ ] Das Fenster ist auf dem Handy-Emulator (360 × 640) gut lesbar, der grüne Knopf ist gut zu treffen und verdeckt nicht den Joystick.

Münzen fürs Fressen:
- [ ] Wer einen Spieler frisst, bekommt die Meldung „You ate Anna (+1.5K size, +30 coins)“ und der Münzzähler steigt um die Stufennummer des Opfers (Stufe 30 gibt 30 Münzen). Log `player eaten` zeigt `coins`.
- [ ] Die Münzen bleiben nach dem Neustart erhalten (nur mit Speichern, siehe 7a).

Kopfgeld (zum Testen mit der Taste `B` in der Arena, im echten Spiel kommt das Setzen mit Robux in L8):
- [ ] Taste `B` setzt ein Kopfgeld auf alle anderen Spieler in der Arena. Über ihnen erscheint ein Schild „BOUNTY ×3“ (leuchtend gelb), das alle sehen, auch durch Wände und aus der Ferne (bis etwa 400 Studs). Das Schild sitzt über dem Kopf und wächst bei größeren Dinos mit.
- [ ] Wer den Markierten frisst, sieht „Bounty! You ate Anna (+1.5K size, +90 coins)“ (dreifach) und bekommt 3-mal so viele Münzen. Das Schild ist weg.
- [ ] Ein zweites `B` auf denselben Spieler verlängert nur die Zeit und verdoppelt nichts.
- [ ] Das Kopfgeld endet nach 120 Sekunden (Schild verschwindet, Log `bounty ended`), wenn der Markierte in die Lobby geht, die Runde verlässt oder gefressen wird.
- [ ] Der Markierte wird nicht gewarnt: Das ist offen (eine Meldung „Anna put a bounty on you“ kommt mit dem Setzen in L8).
