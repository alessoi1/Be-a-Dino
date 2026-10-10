# Studio-Testliste

Von Hand pflegen. Alles hier ist nur in Roblox Studio prüfbar (`rojo serve`, im Plugin „Connect“, dann Play).
Zum Prüfen auf dem Handy: Studio Test-Tab, Geräte-Emulator.

## Schritt 2: Arena, Bewegung, Sprint, Kamera

Stand: noch nicht in Studio getestet.

- [ ] Output zeigt beim Start `server started`, `arena built`, `started` für PlayerState, ArenaService und MovementService, ohne Fehler.
- [ ] Arena erscheint (Boden, vier Wände), Spieler spawnt innerhalb der Wände (Log `spawned`).
- [ ] Man kommt nicht aus der Arena heraus. Springen ist ausgeschaltet.
- [ ] Neuer Spawn nach Reset der Figur (zum Beispiel `Humanoid.Health = 0` in der Konsole) setzt wieder an einen zufälligen Ort, ohne `movement rejected` im Log.
- [ ] WASD und Joystick (Emulator Handy) bewegen die Figur flüssig.
- [ ] Sprint-Button (halten) und Linke Umschalttaste: Tempo steigt, die Leiste sinkt, nach Loslassen und einer Sekunde Pause füllt sie sich wieder.
- [ ] Bei leerer Leiste endet der Sprint, erneuter Start erst ab dem Mindestwert.
- [ ] Sprint-Button gut erreichbar und nicht verdeckt vom Springen-Button des Handys (Position `BUTTON_LIFT` in `SprintControl` anpassen, falls nötig).
- [ ] Tempo-Check: in der Konsole (Server) die Figur weit versetzen (`HumanoidRootPart.CFrame += Vector3.new(100, 0, 0)`). Sie wird zurückgesetzt, das Log zeigt `movement rejected` (höchstens alle 5 Sekunden).
- [ ] Debug-Taste `G` (nur Studio) gibt Punkte: Bei 50 wird die Figur größer (Log `stage changed`), die Kamera rückt sanft weiter weg.
- [ ] Nach dem Wachsen versinkt die Figur nicht im Boden und fällt nicht durch.
- [ ] Teststart mit mehreren Spielern (Test-Tab, 2 bis 3 Spieler): jeder hat eigene Ausdauer und Größe.
- [ ] Auf einem Live-Server (nicht Studio) gibt es keinen `DebugGrow`-Remote und kein `studio debug helper`-Log.

## Schritt 3: Futter fressen und wachsen

Stand: noch nicht in Studio getestet.

- [ ] Output zeigt `food placed` mit `count = 300`, kein `food config invalid`.
- [ ] Futter liegt verteilt in der Arena, innerhalb der Wände, in drei Größen und Farben (viele kleine, wenige große).
- [ ] Beim Drüberlaufen verschwindet das Futter, und die Anzeige oben zählt die Punkte hoch.
- [ ] Nach etwa 8 Sekunden erscheint das Futter an einer neuen Stelle.
- [ ] Bei 50 Punkten wird aus Compy ein Raptor (Log `stage changed`, Anzeige und Figur größer, Kamera weiter weg). Die Leiste springt zurück auf 0 und füllt sich zur nächsten Stufe.
- [ ] Aufnahmeradius fühlt sich passend an: auch als größerer Dino wird nicht zu viel oder zu wenig eingesammelt.
- [ ] Nach Reset der Figur (`Humanoid.Health = 0`) zeigt die Anzeige wieder Compy mit 0 Punkten.
- [ ] Mehrere Spieler (Test-Tab): jeder sammelt eigene Punkte, ein Stück bekommt nur einer.
- [ ] Handy-Emulator: Anzeige oben lesbar, verdeckt nicht den Joystick oder Sprint-Button.
- [ ] Performance: Bei 300 Teilen bleibt die Bildrate stabil (Studio Stats, `Shift+F3`). Auf einem echten Handy testen, falls möglich. Bei Rucklern `count` in `Config/Food` senken.
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
- [ ] Beide sehen die Meldung („Du hast … gefressen (+N)“ und „… hat dich gefressen“), nur eine zur selben Zeit.
- [ ] Nach etwa 3 Sekunden erscheint das Opfer als Compy mit 0 Punkten an einem Ort, der möglichst weit von den anderen liegt.
- [ ] Während der 4 Sekunden Schutzzeit leuchtet der Dino weiß, und er kann nicht gefressen werden. Danach nicht mehr.
- [ ] Wer im selben Moment von zwei Größeren erreicht wird, wird nur einmal gefressen (kein doppelter Punkteabzug oder Fehler im Log).
- [ ] Reichweite fühlt sich fair an: Ein kleiner Dino kann mit Sprint entkommen (Raptor Tempo 22, Compy Sprint 30).
- [ ] Zeitquelle: Futter wächst weiter nach etwa 8 Sekunden nach, Ausdauer und Sprint verhalten sich wie vorher (Umstellung auf `ServerClock`).
- [ ] Bei weniger als 2 Spielern passiert nichts, keine Fehler im Log.
