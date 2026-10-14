# Studio-Testliste

Von Hand pflegen. Alles hier ist nur in Roblox Studio prüfbar (`rojo serve`, im Plugin „Connect“, dann Play).
Zum Prüfen auf dem Handy: Studio Test-Tab, Geräte-Emulator.

Vorbereitung, Reihenfolge und Fehlerberichte stehen in `docs/STUDIO-TEST.md`.

**Seit der Lobby (Ausbau L1) startet jeder Spieler in der Lobby.** Für alle Tests mit Arena zuerst in den grünen Play-Kreis stellen (2 Sekunden). Dinodex und Shop öffnen nur über ihre Kreise in der Lobby, die Taste `G` (Debug) wirkt nur in der Arena.

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

## Schritt 7c und 7d (Skins, Shop): entfallen

Die Skins und der Skin-Shop wurden durch die Varianten ersetzt (siehe „Ausbau L7a“ unten). Der Beleg-Dienst bleibt für L8, siehe `docs/MONETARISIERUNG.md`.

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
- [ ] Beim Betreten stehst du (seit K3) auf einer Plattform auf dem Boden, südlich neben der Kuppel, mit gläsernem Geländer an drei Seiten. Du blickst durch das Sichtfenster in die Arena. Du kannst nicht hinunterfallen.
- [ ] Vier leuchtende Kreise mit schwebenden Schildern: PLAY (grün, Mitte), SHOP (gelb, links), DINODEX (blau, unten) und BOOSTERS (lila, rechts). Du erscheinst nie in einem Kreis.
- [ ] Unten steht „Step into a glowing circle“. Oben links, oben rechts und die Sprint-Taste (Arena-Oberfläche) sind in der Lobby **nicht** zu sehen.
- [ ] Die Kreise flackern nicht (keine Überlappung mit dem Boden).

Kreise:
- [ ] **Shop** und **Boosters**: Im Kreis öffnet sich ein Fenster mit „Coming soon“, beim Verlassen schließt es sich.
- [ ] **Dinodex**: Im Kreis öffnet sich die Sammlung mit den Karten und, nach einem Tipp auf einen Dino, seinen Varianten. Mit dem X schließt man sie, beim erneuten Betreten öffnet sie sich wieder. Ohne Kreis ist sie nicht erreichbar.
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
- [ ] Dinodex: „Best size: 12.3K“ und bei gesperrten Karten „Reach 1K size“ (kurze Zahlen).

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
- [ ] Ein Tipp auf einen erreichten Dino zeigt seine Varianten (siehe „Ausbau L7a“).
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

## Ausbau L5: Autofarm

Stand: noch nicht in Studio getestet. **Der unsicherste Teil ist das Laufen:** Roblox' eingebaute Steuerung kann den Laufbefehl des Skripts überschreiben. Bewegt sich der Dino bei eingeschaltetem Autofarm gar nicht oder ruckelt, bitte genau das melden, es gibt einen Plan B (die eingebaute Steuerung währenddessen ausschalten).

Knopf und Schalter:
- [ ] In der Arena sitzt ein runder Knopf „Auto“ direkt **über dem Sprint-Button**, rechts bündig, und überlappt weder ihn noch den Rand. In der Lobby ist er nicht zu sehen.
- [ ] Tippen schaltet ein: Der Knopf wird grün und zeigt „Auto ON“ in zwei Zeilen. Nochmal tippen schaltet aus. Am PC schaltet die Taste `F` ebenfalls.
- [ ] Im Log: `autofarm started` und `autofarm stopped` mit dem Grund (`player`, `time_over`, `reset`, `round`).

Verhalten:
- [ ] Eingeschaltet läuft der Dino von selbst zu Futter und sammelt es auf. Punkte und Münzen steigen wie beim normalen Spielen.
- [ ] Große Futterstücke (gelb, rot) werden bevorzugt, auch wenn sie etwas weiter weg liegen. Es läuft nicht stur zum nächstliegenden kleinen Stück.
- [ ] Mit einem zweiten, **größeren** Spieler (Test-Tab, `H` drücken): Kommt er nahe (etwa seine Fressreichweite plus 25 Studs), läuft der Autofarm-Dino in die Gegenrichtung, ohne gegen die Wand zu laufen. Futter in der Nähe des Größeren lässt er aus.
- [ ] Ein **kleinerer** Spieler stört nicht.
- [ ] Er bleibt stehen, wenn kein sicheres Futter da ist (zum Beispiel wenn überall ein Größerer ist).
- [ ] **Selbst steuern** (WASD oder Touch-Stick) übernimmt sofort, der Autofarm schaltet sich aus.
- [ ] Nach etwa 10 Minuten schaltet er sich selbst aus (zum Testen `maxSessionSeconds` in `Config/AutoFarm` auf 20 setzen). Danach geht Einschalten sofort wieder.
- [ ] Stirbt der Dino, geht in die Lobby oder betritt die Arena neu, ist der Autofarm aus.
- [ ] Die Tempo-Prüfung des Servers setzt den Dino nicht zurück (kein `movement rejected` im Log), auch nicht beim Sprinten von Hand und wieder Einschalten.
- [ ] Mehrere Spieler gleichzeitig mit Autofarm: Es entstehen keine Fehler im Log, das Spiel läuft flüssig (450 Futterstücke werden alle 0,2 s gelesen).
- [ ] Handy-Emulator (360 × 640): Knopf gut zu treffen, nicht über dem Joystick, die Zahl des Sprint-Knopfs bleibt lesbar.

## Ausbau L6: Globale Ranglisten

Stand: noch nicht in Studio getestet. Voraussetzungen wie bei 7a: veröffentlichtes Place und „Enable Studio Access to API Services“. In Studio nutzt der Dienst eigene Speicher mit Anhang `_Studio` (die echten Listen bleiben unberührt). **Zum schnellen Testen** in `Config/Leaderboards` `writeSeconds` und `readSeconds` auf 10 setzen.

Tafeln:
- [ ] Output zeigt `LeaderboardService started studio=true`, kein `board store not available`.
- [ ] An der Südseite der Lobby (gegenüber vom Fenster, seit K3) hängen drei Tafeln nebeneinander: „Most kills“, „Biggest size“, „Longest playtime“. Sie sind gut lesbar, stehen nicht im Weg (man läuft hindurch), überlappen nicht das Geländer, und nichts flackert.
- [ ] Zuerst steht „Loading...“, danach „No entries yet“ (noch niemand drauf) oder die Einträge. Bei Fehlern („Unavailable“) steht im Log `board read failed`.

Zählen und Eintragen:
- [ ] Einen Spieler fressen (zwei Spieler im Test-Tab, `H` drücken): Der Fresser hat danach 1 Kill (Log auf `debug`: `kill counted`).
- [ ] Zeit in der Arena zählt, in der Lobby nicht. Etwa 2 Minuten in der Arena bleiben reichen für einen Eintrag „2m“.
- [ ] Nach höchstens zwei Schreib- und Leseintervallen steht der eigene Name auf den Tafeln: bei Kills die Anzahl, bei Size die kurze Zahl (zum Beispiel „1.23K“) und bei Playtime die Zeit („2m“, „1h 5m“).
- [ ] Autofarm-Zeit zählt zur Spielzeit.
- [ ] Gäste (ohne Speichern) stehen nie auf den Tafeln.
- [ ] Beim Verlassen wird der letzte Stand noch geschrieben (Log `board number written` auf `debug`, oder neu starten und die Tafel prüfen).
- [ ] Nach einem Neustart sind Kills und Spielzeit wieder da (Profil Version 4, bestehende Profile werden mit `status = migrated` geladen).
- [ ] Mit zwei Spielern stehen beide auf den Tafeln, richtig sortiert (höchster Wert oben), mit ihren Roblox-Benutzernamen.
- [ ] Kurzzeitiger Ausfall des Speichers (zum Beispiel API-Zugriff ausschalten): Die Tafeln bleiben stehen, das Spiel läuft weiter, im Log stehen Warnungen, aber keine Fehlerflut.

## Ausbau L7a: Varianten

Stand: noch nicht in Studio getestet. Zum Testen: in der Arena Taste `V` (nur Studio) gibt eine noch nicht besessene Variante des Dinos, der du gerade bist, und zeigt sie sofort. Taste `H` springt zum nächsten Dino. Das Profil wird auf **Version 5** migriert (die Skin-Felder entfallen, Log `status = migrated`).

Aussehen (am besten bei mehreren Dinos mit `H` prüfen):
- [ ] Output zeigt `VariantService started dinos=50 variants=4`, kein `variant config invalid`.
- [ ] **Glowing:** Der Dino leuchtet (Neon) und ist heller als normal.
- [ ] **Gold:** Der Dino ist golden und glänzt (Metall), auch an den Akzentteilen (Kamm, Klauen, Platten).
- [ ] **Shadow:** Der Dino ist fast schwarz, die Akzentteile sind lila.
- [ ] **Rainbow:** Die Farben wechseln fließend im Kreis (jedes Teil hat eine andere Farbe). Bei mehr als 8 Rainbow-Dinos in der Nähe bewegen sich nur die nächsten 8, die anderen stehen in den Anfangsfarben. Weiter als 150 Studs weg bewegt sich nichts. Das Spiel bleibt auf dem Handy-Emulator flüssig.
- [ ] Die Variante gilt auch für andere Spieler (zwei Spieler im Test-Tab).
- [ ] Ein Wechsel der Variante baut den Dino sofort neu auf (ohne Wolke), Größe und Position bleiben gleich. Kein anderer Wert ändert sich (Tempo, Größe, Fressen).

Dinodex:
- [ ] Ein Tipp auf einen erreichten Dino zeigt fünf Zeilen: „Normal“ und „Glowing“, „Gold“, „Shadow“, „Rainbow“, jeweils mit zwei Farbpunkten als Vorschau. Besessene sind „Equip“, gesperrte zeigen „Find it in eggs“, die gerade gezeigte „Equipped“.
- [ ] „Equip“ wechselt die Variante (sichtbar am Dino, wenn man genau dieser Dino ist), „Normal“ bringt das alte Aussehen zurück.
- [ ] Unter „Best size“ steht „Variants: N of 200 (tap a dino)“ und zählt hoch, wenn man Varianten bekommt. Gäste sehen „Not saved“.
- [ ] Neustart als Compy nach dem Gefressenwerden: Der Compy trägt seine gewählte Variante wieder. Nach einem Stufenwechsel trägt der neue Dino die dort gewählte Variante.
- [ ] Spiel beenden und neu starten: Besitz und Auswahl sind wieder da (nur mit Speichern, siehe 7a).
- [ ] Schnelles Tippen auf „Equip“ erzeugt keine Fehler, im Log höchstens `remote call rejected` mit `rate_limited` (höchstens alle 5 Sekunden).

## Ausbau L7b: Eier im Shop

Stand: noch nicht in Studio getestet. Zum Testen brauchst du Münzen (Taste `H` springt zum nächsten Dino und gibt Münzen) und ein geladenes Profil (kein Gastmodus, Place veröffentlicht, Studio-Zugriff auf API-Dienste an).

- [ ] Output zeigt `EggService started price=200`, kein `egg config invalid`.
- [ ] Im Shop-Kreis erscheint das Fenster „Dino egg“ mit Preis, Münzstand und vier Chancen in Prozent (70, 22, 6, 2), zusammen 100.
- [ ] Mit weniger als 200 Münzen steht auf dem Knopf „Not enough coins“ und er tut nichts.
- [ ] Mit genug Münzen: „Open egg“ bucht 200 Münzen ab, nach kurzem Warten steht dort „Variante Dino!“ und „New!“. Die Variante ist im Dinodex als „Equip“ verfügbar.
- [ ] Ein Doppeltes zeigt „You already had it (+100 coins back)“, netto kostet es 100 Münzen.
- [ ] Es kommen nur bereits erreichte Dinos heraus (im Dinodex prüfen).
- [ ] Mehrfaches schnelles Tippen öffnet nur ein Ei pro Tipp, im Log höchstens `remote call rejected` mit `rate_limited` oder `busy`.
- [ ] Im Gastmodus steht „Your progress must be saved to open eggs.“, es werden keine Münzen abgebucht.
- [ ] Nach Neustart sind Münzen und Varianten wie nach dem Ei (Log `egg opened`, danach Speichern).
- [ ] Das Fenster erscheint nur im Shop-Kreis und lässt sich auf 360 px Breite ganz bedienen.

## Ausbau L8: Bezahlte Angebote

Stand: noch nicht in Studio getestet. Die sechs Developer Products (IDs in `src/shared/Config/Offers.luau`) stehen mit 1 Robux im Creator Hub. **Vor dem ersten Kauf im Kaufdialog nachsehen, ob Studio echte Robux abbucht** (Dialog zeigt den Preis). Zum Testen: Place veröffentlicht, Studio-Zugriff auf API-Dienste an, Profil geladen (kein Gastmodus). Das Profil wird auf **Version 6** migriert.

Start:
- [ ] Output zeigt `OfferService started potions=4`, kein `offer config invalid`, `Receipts handler registered name=offers`.
- [ ] Profil: Log `status = migrated` (von 5 auf 6), danach `loaded`.

Revive:
- [ ] In der Arena gefressen werden, im Todes-Fenster „Revive at your size / View offer“ antippen: Der Kaufdialog öffnet sich. Nach dem Kauf wird der Spieler wieder in die Arena gesetzt, mit **denselben Punkten und demselben Dino**, mit Schutz (weißer Schimmer), Meldung „You are back!“. Log `offer granted`, `credit used`, `revived`.
- [ ] Kauf **nach** Ablauf der 15 Sekunden: Das Revive ist gespeichert; beim nächsten Tod steht „Revive at your size (saved: 1)“, ein Tipp nutzt es ohne neuen Kauf.
- [ ] Arena voll beim Revive: Meldung „Revive not possible now…“, das Revive bleibt gespeichert, das Fenster geht wieder auf.
- [ ] Derselbe Beleg zweimal (Spiel mitten im Kauf beenden, neu starten): Nur ein Revive, Log `repeated receipt ignored`.
- [ ] Das Fenster schließt sich nach der Wahl, „Back to lobby“ geht weiter.

Kopfgeld:
- [ ] „Bounty on <Name>“ antippen und kaufen: Der Killer bekommt das „BOUNTY ×3“-Schild, wer ihn frisst, bekommt dreimal so viele Münzen. Meldung „Bounty placed on …“.
- [ ] Ist der Killer nicht mehr in der Arena, bleibt das Kopfgeld gespeichert („Bounty on … (saved: 1)“).

Tränke (Booster-Kreis):
- [ ] Das Fenster zeigt vier Tränke mit Wirkung und Dauer („10m in the arena“). „View offer“ öffnet den Kaufdialog. Gäste und Spieler ohne geladenes Profil sehen graue Knöpfe und den Hinweis „Your progress must be saved…“.
- [ ] Nach dem Kauf zeigt das Fenster „10m left“, Meldung „<Name> potion added“. Die Zeit läuft **nur in der Arena** herunter (in der Lobby bleibt sie stehen); in der Arena zeigt die kleine Liste unter dem Münzzähler die Restzeit.
- [ ] **Growth:** Futter gibt doppelt so viele Punkte (Fressen von Spielern nicht). **Coin:** Münzen für neue Stufen und fürs Fressen doppelt. **Speed:** der Dino ist spürbar etwa 15 % schneller, ohne dass der Server ihn zurückzieht (kein „rubberband“). **Shield:** nach dem Start in der Arena halten die Schutzzeit und der weiße Schimmer 5 Sekunden länger (9 statt 4).
- [ ] Zwei Tränke derselben Art zählen die Zeit zusammen, bis höchstens 60 Minuten; darüber steht „Full“.
- [ ] Ende der Zeit: Meldung „<Name> potion ended“, die Wirkung ist weg.
- [ ] Nach Neustart ist die Restzeit noch da.

## Bots

Stand: noch nicht in Studio getestet. Werte in `src/shared/Config/Bots.luau` (Startwerte, noch nicht balanciert). Die Bots sind Modelle aus einem Humanoid auf einem unsichtbaren Wurzelteil, **ob das Laufen und das Skalieren so funktioniert, zeigt erst Studio.**

Start und Anzahl:
- [ ] Output zeigt `BotService started fillTo=8` und acht Mal `bot spawned`; im Workspace gibt es den Ordner `Bots` mit den Modellen.
- [ ] Die Bots stehen auf dem Boden (nicht in der Luft oder im Boden), sehen aus wie Dinos (Platzhalter) und tragen Namen aus `Strings.botNames`.
- [ ] Ein Spieler in der Lobby ändert nichts. Betritt der erste Spieler die Arena, geht ein Bot (Log `bot removed reason=player_entered`, Wolke), der kleinste zuerst. Mit sieben Spielern in der Arena bleibt ein Bot, mit acht keiner.
- [ ] Verlässt ein Spieler die Arena, kommt nach etwa einer Sekunde ein Bot nach.

Verhalten:
- [ ] Bots laufen zum Futter und werden größer (Log `bot stage changed`), bleiben aber bei Stufe 6 stehen (`maxStageIndex`).
- [ ] Bots laufen vor größeren Dinos weg, jagen kleinere und laufen nicht in die Wände. Bots sind langsamer als ein Spieler derselben Stufe (Sprint holt sie nicht ein, ohne ihn kommt man nicht weg).
- [ ] Eine eigene Schutzzeit von 4 Sekunden nach dem Auftauchen: in dieser Zeit lässt sich ein Bot nicht fressen und wird nicht gejagt.

Fressen:
- [ ] Ein ausreichend großer Spieler frisst einen Bot: Bot verschwindet mit Wolke, Meldung „You ate <Name>“ mit Punkten und Münzen, Kill zählt in der Statistik. Der Bot kommt nach 5 Sekunden kleiner zurück (Log `bot eaten`).
- [ ] Ein Bot frisst einen Spieler: Todes-Fenster mit dem Bot-Namen; „Bounty“ ist grau mit „No bounty on bots“; Revive und „Back to lobby“ funktionieren wie sonst. Log `death offer opened killer=bot`.
- [ ] Bots fressen sich auch untereinander (Log `player eaten` mit `victimBot=true eaterBot=true`).
- [ ] Spieler spawnen nicht direkt neben einem Bot.
- [ ] Keine Fehler im Output (`bot tick failed`, `bot lost its body`, `adding a bot failed`).
- [ ] Mit mehreren Spielern prüfen, ob die Server-Leistung gut bleibt (kein Ruckeln durch Bots).

## K1 Kollision

Stand: noch nicht in Studio getestet. Werte in `src/shared/Config/Collision.luau` und die Spalte `collider` in `src/shared/Config/Scenery.luau` (Startwerte). Reine Logik (`Avoidance`) ist mit Tests abgedeckt, **ob Humanoid-Physik, Hüllen und Ausweichen zusammenpassen, zeigt erst Studio.**

Vorbereitung: `showColliders = true` in `Config/Collision` setzen, damit die Hüllen als rote, halbtransparente Formen sichtbar sind. Danach wieder auf `false`.
- [ ] Output zeigt `SceneryService colliders built count=…` (Bäume, Palmen, große und kleine Felsen, Stämme; keine Büsche und Farne). Im Workspace gibt es `Colliders` unter `Scenery`.
- [ ] Die roten Formen sitzen mittig auf Stamm und Fels (nicht daneben, nicht zu groß). Passen sie nicht, `collider` pro Prop in `Config/Scenery` anpassen (bei den echten Meshes können die Größen abweichen).
- [ ] Der Spieler läuft nicht durch Bäume, Palmen, Felsen und Stämme. Er **gleitet** an ihnen entlang, auch bei schräger Annäherung, und bleibt nicht hängen (mit Compy und mit einem großen Dino prüfen, zum Beispiel per Debug-Taste `G`).
- [ ] Büsche und Farne lassen sich durchlaufen (Deckung). Die Wasserstelle und der Steinring sind weiter begehbar.
- [ ] Die Kamera springt nicht vor Bäumen und Felsen heran (die Hüllen sind für die Kamera unsichtbar).
- [ ] Ein sehr großer Dino (Größe 8) steigt nicht auf kleine Felsen oder Stämme; sieht das komisch aus, die Höhe in `collider` erhöhen.
- [ ] Niemand erscheint (Spawn, Bots) in einer Hülle oder eingeklemmt zwischen zwei Hüllen.
- [ ] **Bots:** Sie laufen um Bäume und Felsen herum, statt daran hängen zu bleiben (Bot beobachten, der Futter hinter einem Baum anläuft). Keine Bots, die minutenlang an einer Stelle stehen.
- [ ] **Autofarm:** Mit eingeschaltetem „Auto“ läuft der Dino um Bäume und Felsen herum, auch zu Futter direkt hinter einem Baum und bei der Flucht. Output zeigt einmal `AutoFarmControl obstacles read count=…`.
- [ ] Keine Fehler im Output, und der Server-Tempoprüfer (`MoveCheck`) zieht niemanden zurück, der an einer Hülle entlanggleitet.

## K2 Runde Arena und Kuppel

Stand: noch nicht in Studio getestet. Werte in `src/shared/Config/Arena.luau` (`radius`, `wallSegments`), `Config/Dome.luau` und `Config/Food.luau` (`count`). Reine Logik (`DomeShape`, Kreis-Platzierung) ist mit Tests abgedeckt, **die Optik und die Kollision zeigen erst Studio.**

Boden und Wand:
- [ ] Output zeigt `ArenaService arena built radius=300 walls=64`, `DomeService dome built` und `colliders built`. Im Workspace: `Arena` mit `Floor`, `Walls` (64 Teile), `Dome` und `Scenery`.
- [ ] Der Boden ist rund (Durchmesser 600), ohne Spalt und ohne Flackern. Die graue Baseplate ist weg.
- [ ] Die Wand ist rund und geschlossen: Man läuft ringsum an der Wand entlang und **gleitet** daran, ohne an den Ecken der Wandstücke hängen zu bleiben und ohne durch Lücken zu fallen (mit Compy und einem großen Dino).
- [ ] Die Felsen vor der Wand stehen rundherum, drehen sich mit der Wand mit und ragen nicht durch sie.

Kuppel:
- [ ] Von innen sieht man das Gerüst (Rippen und Ringe) mit dem Glas dazwischen (seit P3). Die Rippen stören die Sicht nicht und flackern nicht.
- [ ] Von außen (im Studio-Fenster herauszoomen) ist die Kuppel eine leicht getönte Glasschale mit dem Gerüst.
- [ ] Die Lobby (seit K3 südlich neben der Kuppel) ist sichtbar und nicht verdeckt.
- [ ] Bildrate auf einem echten Handy (Rippen etwa 280 Teile, dazu 72 Glasplatten seit P3): Wenn es ruckelt, in `Config/Dome` `ribs`, `ribSegments` oder die Ringe verringern.

Platzierung im Kreis:
- [ ] Futter liegt gleichmäßig über der ganzen Scheibe, nicht an der Wand zusammengedrängt, und nicht außerhalb (nichts hinter der Wand). Die Oase in der Mitte ist unverändert.
- [ ] Bäume, Felsen, Pfade und Flecken liegen nur innerhalb des Kreises; Pfade enden vor der Wand.
- [ ] Niemand erscheint in oder hinter der Wand (mehrfach neu starten, auch Bots).
- [ ] Bots und Autofarm laufen nicht in die Wand und bleiben nicht an der Rundung hängen (Flucht an der Wand entlang beobachten).
- [ ] Die Futtermenge fühlt sich gleich dicht an wie vorher (510 Stücke). Wenn nicht, `count` anpassen.

## K3 Lobby an der Kuppel

Stand: noch nicht in Studio getestet. Werte in `src/shared/Config/Lobby.luau` (Lage, `northInset`, `height`) und `Config/Arena.luau` (`windowSegments`, `windowAngleDegrees`, `windowTransparency`). **Die Lage und die Optik zeigen erst Studio.**

Lage und Boden:
- [ ] Output zeigt `LobbyService lobby built` und keine `lobby config invalid`-Meldung. Beim Betreten (und nach dem Gefressenwerden) erscheinst du **auf der Lobby-Plattform südlich der Kuppel**, nie in der Arena, in der Luft oder im Leeren.
- [ ] Zwischen der runden Wand und der Plattformkante ist **kein Loch** (an den Ecken der Plattform entlanglaufen und hinunterschauen). Der Boden flackert nicht dort, wo Arena- und Lobbyboden sich überlappen.
- [ ] Das Geländer steht an West, Ost und Süd; die Seitengeländer enden an der Wand und ragen nicht in die Arena.

Sichtfenster:
- [ ] In der Wand ist ein Fenster aus vier Glasstücken (etwa 120 Studs breit), genau gegenüber der Lobby. Man sieht von der Lobby aus in die Arena (Oase, Bäume, Dinos, Bots), und man kann **nicht** hindurchlaufen.
- [ ] Vor dem Fenster stehen keine Wandfelsen. Der Glaston ist angenehm (nicht zu dunkel, nicht zu spiegelnd). Die Durchsichtigkeit lässt sich in `windowTransparency` ändern.
- [ ] Aus der Arena sieht man durch das Fenster die Lobby und die Spieler dort.

Bedienung:
- [ ] Die vier Kreise (PLAY, SHOP, DINODEX, BOOSTERS) funktionieren wie vorher; PLAY bringt dich in die Arena (Teleport), „Lobby“ und das Todes-Fenster bringen dich zurück auf die Plattform.
- [ ] Die drei Ranglisten-Tafeln hängen an der Südseite und sind von der Mitte aus lesbar, sie verdecken die Sicht zum Fenster nicht.
- [ ] Die Kamera in der Lobby ist angenehm (kein Springen an der Kuppel oder am Geländer).

## K4 Namen über dem Kopf

Stand: noch nicht in Studio getestet. Werte in `src/shared/Config/NameTags.luau` und `Config/Bots.luau` (`renameOnRespawn`). **Die Optik und die Lesbarkeit zeigen erst Studio und das Handy.**

- [ ] Über jedem Dino in der Arena (eigener, andere Spieler, Bots) steht ein Schild: oben der Name, darunter die Size (zum Beispiel „12.3K“). Der **Roblox-Name** über dem Kopf ist weg. Der eigene Name ist gelb.
- [ ] Die Size auf dem Schild stimmt mit der Anzeige links oben überein und wächst beim Fressen mit (kleine Verzögerung bis etwa 0,2 s ist normal).
- [ ] Das Schild wächst mit dem Dino und schwebt höher, bleibt aber lesbar (bei Größe 8 nicht riesig, bei Größe 1 nicht winzig). Mit der Entfernung wird es kleiner, am Ende der Reichweite blendet es aus.
- [ ] Ein großer Dino ist von weiter weg lesbar als ein kleiner. Ein Schild verschwindet, wenn der Dino weit weg ist (Reichweite 120 plus 40 mal Skalierung Studs).
- [ ] Spieler in der Lobby haben kein Schild; beim Betreten der Arena erscheint es.
- [ ] Bots haben Namen aus der Liste. Wird ein Bot gefressen, kommt er nach 5 Sekunden mit **neuem Namen** zurück (Log `bot renamed` auf `debug`).
- [ ] Das „BOUNTY ×3“-Schild eines Markierten schwebt **über** dem Namensschild und überdeckt es nicht.
- [ ] Auf dem Handy: Schilder gut lesbar, keine Ruckler mit vielen Dinos in der Nähe (Name-Updates laufen etwa 5-mal pro Sekunde).
- [ ] Keine Fehler im Output (`name tag refresh failed`).

## K5a Icons

Stand: noch nicht in Studio getestet. Werte in `src/shared/Config/Icons.luau`. **Ob die Symbolzeichen auf allen Geräten erscheinen und wie die Anordnung auf dem Handy wirkt, zeigt erst Studio.**

- [ ] **Statusfeld** links oben: links neben dem Dino-Namen steht das Size-Icon; der Titel lautet „Compy · 12.3K“ (ohne das Wort „size“) und wird nicht abgeschnitten.
- [ ] **Münzzähler:** ein Münz-Icon links, daneben nur die Zahl (zum Beispiel „1.2K“).
- [ ] **Sprint-Knopf:** zeigt ein Icon statt des Wortes „Sprint“; Antippen und Halten funktioniert wie vorher (auch mit dem Finger auf dem Icon).
- [ ] **Ausdauerleiste:** links neben der Leiste steht das Ausdauer-Icon, es überlappt die Leiste nicht.
- [ ] **Autofarm-Knopf:** ein Icon; wenn an, wird der Knopf grün und unten steht klein „ON“; Antippen schaltet um.
- [ ] **Bestenliste** rechts oben: ein Stern-Icon vor dem Titel „Leaderboard“.
- [ ] **„Lobby“-Knopf** (in der Arena unten): ein Haus-Icon links vom Text, der Text ist nicht abgeschnitten, auch beim Countdown „Leaving in 5…“.
- [ ] Die Symbolzeichen werden auf Handy und PC angezeigt (nicht als leeres Kästchen). Falls nicht, die echten Bilder einbauen (`docs/ICONS.md`) oder das Zeichen in `Config/Icons` ändern.
- [ ] Nichts überlappt auf dem Handy-Emulator (360 × 640 und ein Gerät mit Notch).

## K6 Futter

Stand: noch nicht in Studio getestet. Werte in `src/shared/Config/Food.luau` (`variants`) und `Config/FoodEffects.luau`. **Das Aussehen, die Partikel und die Leistung zeigen erst Studio und das Handy.**

Aussehen:
- [ ] Das Futter sieht abwechslungsreich aus: kleine Stücke als Beeren (rot), Blätter (grün, flach) und Samen (gelb), mittlere als Früchte (orange), Melonen (grün) und Pilze (hell), große als Fleisch (rot-braun), Fische (blau) und Eier (hell). Die Größen bleiben klein, mittel, groß erkennbar.
- [ ] Die Stücke liegen auf dem Boden schwebend wie vorher (nicht im Boden, nicht zu hoch) und sind zufällig gedreht.
- [ ] Wachstum und Münzen ändern sich nicht gegenüber vorher: ein Stück gleicher Größe gibt immer gleich viel, egal welches Aussehen.
- [ ] Output ohne Fehler (`food config invalid`, `food kind without a look`).

Feedback:
- [ ] Beim Fressen steigt ein kleiner Partikelschwarm in der Farbe des Stücks auf; bei großem Futter sind es mehr Teilchen. Das gilt auch, wenn **andere** oder Bots in der Nähe fressen.
- [ ] Weit weg (über 80 Studs) gibt es keinen Effekt. Bei vielen Essenden gleichzeitig ruckelt nichts (maximal 20 Effekte pro Sekunde).
- [ ] Am Rundenanfang steht oben in der Mitte „Eat the food to grow!“; der Hinweis verschwindet nach dem ersten gefressenen Stück oder nach 8 Sekunden und kommt in der nächsten Runde wieder.
- [ ] Ohne Sound-ID bleibt es still, mit Sound-ID klingt es nicht nervig (Lautstärke und Tonhöhe in `Config/FoodEffects`).
- [ ] Auf dem Handy: gute Bildrate mit Futter-Teilen (510 Teile mit je einem Mesh-Anhang) und Partikeln.

## K7a Idle, Fressen und Körperwippen

Stand: noch nicht in Studio getestet. Werte in `src/shared/Config/Animation.luau`. Nur echte Formen (Meshes) bewegen sich; Dinos mit Platzhalter-Look bleiben starr. **Ob die Gelenke zusammenhalten und wie es aussieht, zeigt erst Studio.**

- [ ] Der Dino ist am Spielstart (Compy) **genau so gebaut wie vorher**: Körper, Beine und Schwanz sitzen an der richtigen Stelle, nichts verschoben oder verdreht (das neue Gelenk `body` ersetzt die Schweißnaht).
- [ ] Im Stand atmet der Körper ganz leicht (hebt und senkt sich), der Schwanz pendelt wie vorher. Die Füße bleiben dabei nicht deutlich im Boden stecken oder schweben.
- [ ] Beim Laufen wippt der Körper leicht im Schritt und lehnt sich minimal nach vorn; die Beine laufen wie vorher.
- [ ] Beim Fressen nickt der Dino kurz nach unten (Kopf runter, Schwanz leicht hoch) und duckt sich ein wenig. Auch Bots und andere Spieler in der Nähe nicken, wenn sie fressen. Viele schnelle Bisse hintereinander zittern nicht.
- [ ] Das gilt bei kleinen und bei großen Dinos (Größe 8: das Nicken ist nicht zu stark, kein Verschwinden im Boden). Falls doch, `eatPitch`, `eatDip` und `breathLift` verkleinern.
- [ ] Weit weg (über 140 Studs) bewegen sich die Dinos nicht (spart Leistung); beim Näherkommen beginnt es wieder ohne Zucken.
- [ ] Nach einem Stufenwechsel (neues Modell, Wolke) funktioniert alles weiter; auch nach dem Wechsel der Variante im Dinodex.
- [ ] Keine Fehler im Output (`animation failed`, `animation config invalid`).
- [ ] Auf dem Handy bleibt die Bildrate mit mehreren Dinos in der Nähe gut.

## K8 Dschungel-Feinschliff

Stand: noch nicht in Studio getestet. Werte in `src/shared/Config/Scenery.luau` (`ponds`, `gates`, `clusters`, `vines`). **Die Optik, die echte Durchgangsbreite der Felstore und die Leistung zeigen erst Studio und das Handy.**

- [ ] Output zeigt `ponds built count=4`, `gates placed count=8`, `cover placed clusters=6`, `vines built`. Kein `not every prop found room` (sonst die Anzahl in `Config/Scenery` senken).
- [ ] **Teiche:** vier flache Teiche mit Sandufer, begehbar (man läuft hindurch, ohne zu schweben oder einzusinken), ohne Flackern auf Pfaden und Flecken. Nichts steht im Wasser.
- [ ] **Felstore:** Zwischen je zwei großen Felsen ist eine Lücke. Mit **Compy (Größe 1)** kommt man durch die engen (7 Studs) und mittleren Tore, mit einem **großen Dino** nur durch die weiten (20 Studs) und gar nicht durch die engen. Bleibt ein Dino dazwischen hängen oder ist die Lücke zu eng/zu weit, `gaps` anpassen.
- [ ] Die Tore blockieren nicht die Wege zur Oase oder zur Wand (man kann überall hin gelangen). Nichts steht in einer Lücke.
- [ ] **Bots und Autofarm** laufen um die Felsen herum und bleiben an den Toren nicht hängen.
- [ ] **Deckung:** Gruppen aus Büschen und Farnen, in denen man (optisch) verschwinden kann; sie sind begehbar. Der Dino ist darin nicht unsichtbar (Namensschild bleibt).
- [ ] **Lianen:** Vom Gerüst der Kuppel hängen grüne Lianen mit Blattkugel herab, rund um die Arena, **nicht** vor dem Sichtfenster; sie stören die Sicht nicht und hängen nicht schief durch die Wandfelsen.
- [ ] Insgesamt wirkt die Arena abwechslungsreich, nicht überladen; es gibt Engstellen und Deckung für Kleine, aber auch freie Flächen für große Dinos.
- [ ] Auf dem Handy: gute Bildrate (etwa 150 Teile mehr als vorher). Wenn nötig `vines.count`, `clusters.count` oder `gates.count` senken.

## K5b Menü-Leiste und Bots in der Bestenliste

Stand: noch nicht in Studio getestet. Werte in `src/shared/Config/Menu.luau`. **Das Layout auf dem Handy zeigt erst Studio.**

Menü-Leiste:
- [ ] In der Lobby stehen am rechten Rand, in der Mitte, drei Knöpfe übereinander: SHOP, DINODEX, BOOSTERS, mit Icon und Beschriftung. In der Arena und im Todes-Fenster sind sie nicht zu sehen.
- [ ] Ein Tipp auf SHOP öffnet das Eier-Fenster (ohne im Kreis zu stehen), der Knopf wird orange. Ein zweiter Tipp schließt es. Ein Tipp auf DINODEX wechselt zum Dinodex, auf BOOSTERS zu den Tränken.
- [ ] Alle drei Fenster haben oben rechts ein X, das sie schließt (auch das Dinodex wie bisher). Nach dem X ist der Knopf wieder grau.
- [ ] Steht man in einem Kreis, öffnet sich weiter automatisch das Fenster; verlässt man ihn, geht es zu. Kreis und Leiste stören sich nicht (kein Flackern, kein doppeltes Fenster).
- [ ] Beim Betreten der Arena sind alle Fenster zu; zurück in der Lobby sind sie auch zu.
- [ ] Die Knöpfe sind auf dem Handy groß genug, liegen nicht über dem Joystick und verdecken die Hinweise („Step into a glowing circle“) nicht. Eier öffnen und Tränke ansehen funktionieren aus der Leiste heraus wie im Kreis.

Bestenliste:
- [ ] Die Bots stehen mit ihrem Namen in der Liste rechts oben (mit den Spielern gemischt, nach Size sortiert). Die eigene Zeile bleibt gelb.
- [ ] Die Size der Bots steigt in der Liste mit (kleine Verzögerung), und ein gefressener Bot rutscht nach unten oder verschwindet bis zum Respawn. Ein neuer Bot-Name erscheint nach dem Respawn.
- [ ] Verlässt ein Bot die Arena (ein Spieler tritt ein), verschwindet er aus der Liste.

## P1 Fress-Reichweite und Autofarm-Steuerung

Stand: noch nicht in Studio getestet. Wert: `eatReachFactor` in `src/shared/Config/Arena.luau` (2,2).

- [ ] Ein größerer Dino (mindestens 1,2-mal so groß) frisst einen kleineren, sobald die Körper sich berühren: Läuft man mit einem größeren Dino in einen kleineren Bot, wird der Bot gefressen; läuft man als kleinerer in einen größeren Bot, ist man gefressen. Man kann nicht mehr „durch“ einen Bot laufen, der einen fressen dürfte.
- [ ] Gleich große Dinos (unter 1,2-mal) berühren sich ohne Folgen; die Schutzzeit (4 Sekunden nach dem Start) schützt weiter.
- [ ] Die Reichweite wirkt weder zu weit (gefressen, obwohl noch Abstand ist) noch zu knapp. Wenn nicht, `eatReachFactor` ändern (zum Beispiel 1,8 oder 2,6).
- [ ] **Autofarm:** Mit eingeschaltetem „Auto“ übernimmt man durch Steuern (Tasten, Stick) sofort und der Autofarm geht aus. Im Log steht kein `controls not found` mehr.
- [ ] Der Autofarm-Dino flieht weiter vor größeren Dinos, rechtzeitig vor der neuen Reichweite.

## P2 UI-Überarbeitung

Stand: noch nicht in Studio getestet. Werte in `src/client/UiTheme.luau`, `src/shared/Config/NameTags.luau`. **Das Aussehen und das Layout auf dem Handy zeigen erst Studio.** Der neue Stil: kräftige Knöpfe mit dicker dunkler Umrandung, Wort unter dem Icon, blaue Felder mit hellem Rand.

- [ ] **Sprint-Knopf** (unten rechts): orange, mit Blitz-Icon und dem Wort „Sprint“ darunter; man erkennt ohne Hover, was er tut. Halten funktioniert wie vorher (auch mit dem Finger).
- [ ] **Autofarm-Knopf** (über dem Sprint-Knopf): rot mit Icon und „Auto Farm“; wenn an, wird er grün und zeigt oben rechts ein „ON“. Antippen und die Taste F schalten um.
- [ ] **„Lobby“-Knopf** (nur in der Arena): blau, **unter dem Statusfeld** links oben, mit Haus-Icon. Er ist nicht mehr unten in der Mitte. Beim Antippen läuft „Leaving in 5…“ im Knopf herunter, nochmal tippen bricht ab.
- [ ] Der **Münzzähler** und die **Trank-Liste** sitzen darunter und überlappen nichts (in der Arena: Status, Lobby-Knopf, Münzen, Tränke; in der Lobby: Münzen in der Ecke).
- [ ] Die **Bestenliste** sitzt ganz oben in der rechten Ecke (am Bildschirmrand, nicht unter einer Leiste) und überlappt den Autofarm-Knopf nicht.
- [ ] Das **Namensschild** schwebt direkt über dem Kopf des Dinos (nicht weit darüber), auch bei Langhälsen und großen Dinos; es überdeckt den Kopf nicht und schwankt nicht auffällig beim Fressen. Das Kopfgeld-Schild sitzt darüber.
- [ ] Die **Menü-Leiste** in der Lobby hat denselben Stil (blaue Knöpfe, aktiver Knopf orange).
- [ ] Die Felder (Status, Bestenliste, Fenster) sind lesbar, die Texte haben eine dunkle Umrandung.
- [ ] Auf dem Handy (360 × 640 und mit Notch): nichts überlappt, alle Knöpfe sind groß genug.

## P3 Kuppel mit echtem Glas

Stand: noch nicht in Studio getestet. Werte in `src/shared/Config/Dome.luau` (`glass`). **Die Optik zeigt erst Studio und das Handy.**

- [ ] Output zeigt `DomeService dome built beams=278 panels=72`.
- [ ] **Von innen** ist zwischen den Rippen und Ringen jetzt Glas zu sehen (leicht bläulich, durchsichtig), die Kuppel wirkt geschlossen und nicht mehr wie ein nacktes Gerüst. Man sieht durch das Glas weiter Himmel, Sonne und Wolken.
- [ ] **Von außen** (herauszoomen, oder von der Lobby aus) sieht man die Kuppel als Glasschale mit Gerüst; durch das Sichtfenster in der Wand sieht man weiter in die Arena.
- [ ] Zwischen den Platten sind keine hellen Spalten und keine dunklen Streifen; die Platten flackern nicht (kein Z-Fighting) und die Überlappungen sind nicht auffällig dunkler.
- [ ] Die Glasplatten stören die Kamera und das Fressen nicht (keine Kollision, die Kamera zoomt nicht heran).
- [ ] Auf dem Handy: gute Bildrate; viel durchsichtiges Glas kostet Leistung. Falls es ruckelt: `transparency` höher setzen oder `ribs` und `ringElevations` verkleinern (weniger Platten).
- [ ] Wenn das Glas zu dunkel oder zu milchig wirkt: `transparency` (höher = klarer) und `color` in `Config/Dome` anpassen.

## P4 Lobby als Forschungsstation und mehr Landschaft

Stand: im Studio-Start ohne Fehler gelaufen (Log: `lobby station built parts=93`, `props built total=182`), die Optik ist noch nicht angesehen. Werte in `src/shared/Config/LobbyDecor.luau` und `Config/Scenery.luau`.

Lobby:
- [ ] Die Lobby wirkt wie eine Forschungsstation: Dach mit Glasstreifen, Säulen, Rückwand mit dem Schild „DINO RESEARCH STATION“, niedrige Seitenwände, Lampen, Bänke vor dem Fenster, Pflanzkübel, das Skelett und ein Ring um den Spielkreis. Nichts steht schief, im Boden oder in der Luft.
- [ ] Das **Sichtfenster** zur Arena ist frei (das Dach und die Bänke verdecken es nicht), und man sieht von den Bänken aus in die Arena.
- [ ] Die Ranglisten-Tafeln hängen vor der Rückwand, gut lesbar, und das Schild darüber ist nicht abgeschnitten.
- [ ] Man erscheint nie in einer Bank, einem Kübel, einer Säule oder dem Skelett (mehrfach neu starten und zurück in die Lobby gehen). Die Kreise (PLAY, SHOP, DINODEX, BOOSTERS) sind frei erreichbar.
- [ ] Die Lampen leuchten schön, aber nicht zu grell; auf dem Handy bleibt die Bildrate gut (4 Lichter, etwa 93 Teile).
- [ ] Von der Lobby aus sieht man die Kuppel mit Glas und Gerüst und über der Station den Himmel durch den Glasstreifen.

Arena:
- [ ] Riesenpilze (rote Kappe, heller Stiel), Kristalle (türkis, durchscheinend), Riesen-Rippen, Ruinen (drei Säulen und ein Block) und Baumstümpfe sehen gut aus, stehen auf dem Boden und nicht in Teichen oder Toren. Sie sind nicht zu viele oder zu wenige (Anzahlen in `Config/Scenery`).
- [ ] Pilze, Kristalle, Ruinen und Stümpfe blockieren (mit Gleiten), die Rippen sind begehbar. Bots und Autofarm laufen darum herum.
- [ ] Die Arena wirkt abwechslungsreicher; die Bildrate auf dem Handy bleibt gut (Teile im Workspace insgesamt etwa 1.770).

Autofarm-Steuerung:
- [ ] Im Log steht kein `controls not found`; wer bei eingeschalteter Autofarm steuert (Tasten oder Stick), übernimmt, und die Autofarm geht aus.

## P5 Futtermodelle

Stand: im Playtest geprüft (Bild: Beeren pink, Fisch blau mit orangem Schwanz, Samen gelb, Blätter grün, Pilz orange mit hellem Stiel, alle neun Meshes geladen, 460 MeshParts); der Rest ist noch nicht angesehen.

- [ ] Beere, Blatt, Samen, Frucht, Melone, Pilz, Fleisch, Fisch und Ei erscheinen als kleine Modelle statt als Kugeln und Formen. Jedes sieht aus wie sein Name, auch aus der Entfernung.
- [ ] Die **Farben** sind die gemalten (rote Beere, grünes Blatt, orange Frucht, gestreifte Melone, oranger Pilz mit hellen Flecken, rote Keule, blauer Fisch, helles Ei). Zeigt ein Stück nur Weiß oder Grau, zeigt der `SpecialMesh` die Vertex-Farben nicht: melden.
- [ ] Die Größen passen zu klein, mittel und groß (große Stücke deutlich größer), nichts steckt im Boden, nichts schwebt zu hoch; der Fisch und die Keule zeigen in verschiedene Richtungen (zufällig gedreht).
- [ ] Wachstum und Münzen sind unverändert; die Partikel beim Fressen haben weiter die Farbe des Stücks.
- [ ] Auf dem Handy bleibt die Bildrate gut (510 Stücke mit je einem kleinen Mesh).

## P6 Kinder-Oberfläche und Bindungs-Funktionen (14. Oktober 2026)

Stand: im Code fertig, Tests der reinen Logik grün; nichts davon in Studio angesehen. Werte in `Config/Daily`, `Config/Quests`, `Config/Combo`, `Config/Frenzy`.

Oberfläche für Kinder:
- [ ] Die Emoji-Symbole erscheinen bunt (nicht als graue Kästchen) auf Handy und PC: Münze, Essen, Pfeil, Lobby-Haus, Geschenk, Flamme, Sanduhr. Fehlt eines, in `Config/Icons` ein anderes Zeichen wählen oder ein Bild nehmen (`docs/ICONS.md`).
- [ ] Sprint- und Autofarm-Knopf zeigen nur ein Symbol und sind gross genug für Kinderfinger; der „An“-Haken erscheint bei Autofarm.
- [ ] Todes-Fenster: rötlich abgedunkelter Hintergrund, schwindliges Gesicht, drei grosse Kacheln (Herz = Wiederbeleben, Ziel = Kopfgeld, Haus = Lobby). Warenkorb-Symbol oder „x2“ bei gespeicherten, Schloss wenn nicht möglich. Alle drei Kacheln passen auf ein kleines Handy.
- [ ] Statusfeld, Münzen, Tränke, Ei-Fenster, Booster-Fenster, Collection und Meldungen zeigen Symbole mit Zahlen; kein Text ist abgeschnitten.

Tägliches Geschenk:
- [ ] Beim ersten Betreten der Lobby am Tag erscheint das Geschenk-Fenster mit sieben Tagen; Tag 1 ist hervorgehoben. „Claim“ gibt die Münzen (Meldung „Daily gift“), das Fenster schliesst sich.
- [ ] Zweites Mal am selben Tag: kein Fenster. Am nächsten Tag (Uhr verstellen geht nur im Studio-Server: `os.time`) Streak-Tag 2; nach einem verpassten Tag wieder Tag 1; nach Tag 7 beginnt es von vorn.
- [ ] Nach dem Neustart des Spiels ist der Stand gespeichert (Münzen und Streak). Gäste (ohne Speichern) bekommen kein Geschenk.

Tagesaufgaben:
- [ ] In der Lobby steht links in der Mitte der Klemmbrett-Knopf; er öffnet drei Aufgaben mit Symbol, Name, Balken und Münzen-Knopf.
- [ ] Fortschritt zählt: Futter fressen, Spieler fressen, Dinos wachsen, Kombo, Spielzeit. Sobald das Ziel erreicht ist, wird der Münzen-Knopf gelb und am Klemmbrett erscheint ein Geschenk-Zeichen. Abholen gibt die Münzen genau einmal.
- [ ] Am nächsten Tag gibt es neue Aufgaben mit leerem Fortschritt.

Kombo und Futter-Rausch:
- [ ] Wer Futter in kurzer Folge frisst, sieht ab 3 eine Flamme mit „x3 … x10“, die bei jedem Stück kurz aufspringt (stärker alle 10). Nach drei Sekunden ohne Futter verschwindet sie. Es gibt keine Extra-Punkte.
- [ ] Etwa 90 Sekunden nach dem Serverstart erscheint oben das orange Banner „Food frenzy x2“ mit Countdown (45 Sekunden): in dieser Zeit gibt Futter doppelte Punkte, danach 240 Sekunden Ruhe. Das Banner überdeckt nichts Wichtiges auf dem Handy (Statusfeld links, Bestenliste rechts, Kombo und Meldung darunter).
