# Studio-Testrunde: Anleitung

Der gesamte Roblox-Code (Schritte 2 bis 7) wurde bisher nur geschrieben und mit Lune geprüft, nie in Roblox Studio ausgeführt. Diese Anleitung führt durch die erste Testrunde. Die Einzelpunkte stehen in `docs/TESTLISTE.md`.

Zeitbedarf: etwa 20 Minuten für den Schnelltest, etwa 2 Stunden für alles.

## 1. Einmalige Vorbereitung

Alle Befehle im Terminal im Projektordner.

1. **Werkzeuge und Pakete:**
   ```
   rokit install
   wally install
   ```
   `wally install` legt den Ordner `ServerPackages` an (nicht im Git). Ohne ihn lässt sich das Projekt nicht synchronisieren oder bauen.
2. **Rojo-Plugin für Studio:**
   ```
   rojo plugin install
   ```
   Danach Studio neu starten.
3. **Ein leeres Place anlegen:** In Studio ein neues Baseplate-Place erstellen und **außerhalb des Repos** speichern. Lösche darin am besten die Baseplate und die Spawn-Platte, die Arena baut das Spiel selbst. Bleiben sie stehen, entfernt der Server sie beim Start (Log `template part removed`), sonst würde der graue Boden durch den grünen flackern. Skripte kommen nur über Rojo, bearbeite sie nie in Studio.
4. **Place veröffentlichen** (File → Publish to Roblox). Ohne Veröffentlichung gibt es kein Speichern und keine Käufe.
5. **Studio-Zugriff auf Dienste erlauben:** Home → Game Settings → Security → „Enable Studio Access to API Services“ einschalten. Ohne das spielt jeder im Gastmodus (siehe `docs/TESTLISTE.md`, Schritt 7a).
6. **Rojo starten und verbinden:**
   ```
   rojo serve
   ```
   In Studio im Reiter Plugins das Rojo-Fenster öffnen und **Connect** drücken.
7. **Output öffnen:** View → Output. Im Filterfeld `BeDino` eintippen, dann siehst du nur die Zeilen des Spiels (alle anfangen mit `[BeDino]`).

## 2. Der erste Start (Play, F5)

Erwartet im Output, ohne rote Fehlerzeilen (Reihenfolge ähnlich):

Server:
```
[BeDino][Main] server started
[BeDino][PlayerState] started
[BeDino][Data] started profileVersion=2 store=BeDinoProfiles
[BeDino][CollectionService] started
[BeDino][ArenaService] arena built ...
[BeDino][ArenaService] started
[BeDino][AppearanceService] started
[BeDino][Receipts] started
[BeDino][Receipts] handler registered name=skins
[BeDino][SkinService] started
[BeDino][MovementService] started
[BeDino][LobbyService] lobby built ...
[BeDino][LobbyService] started
[BeDino][FoodService] food placed count=450 oasis=80
[BeDino][FoodService] started
[BeDino][PlayerCollision] started
[BeDino][EatingService] started
[BeDino][DebugService] studio debug helper is active
```
Dann für deinen Spieler:
```
[BeDino][Data] loading profile ...
[BeDino][Data] profile loaded status=new userId=... version=2
[BeDino][PlayerState] state started mode=lobby ...
```
Client:
```
[BeDino][Client] client started
[BeDino][CoreGuiSetup] core gui adjusted
```

**Gastmodus statt `profile loaded`:** Steht stattdessen `player plays as guest, nothing is saved`, ist das Place nicht veröffentlicht oder der API-Zugriff aus (Schritt 1.4 und 1.5). Das Spiel läuft trotzdem weiter.

## 3. Schnelltest (etwa 20 Minuten)

Mit einem Spieler. Ziel: Läuft das Grundspiel überhaupt?

1. Du stehst in einer Lobby auf einer Plattform hoch über der Arena und blickst auf die Arena herab. Vier leuchtende Kreise: PLAY (grün, Mitte), SHOP, DINODEX, BOOSTERS.
2. In den **PLAY-Kreis** stellen und 2 Sekunden warten. Du landest als kleiner grüner Compy mit weißem Schutz in der grünen Arena. Futter liegt verteilt, oben links das Statusfeld, oben rechts die Bestenliste.
3. Laufen mit WASD, mit Shift sprinten. Die Ausdauerleiste unten sinkt und lädt wieder auf.
4. Futter einsammeln: Punkte steigen, das Futter kommt nach etwa 8 Sekunden an anderer Stelle wieder.
5. Taste `G` drücken (nur in Studio und nur in der Arena): Jeder Druck bringt 25 % der Strecke bis zur nächsten Stufe, nach vier Drücken wird der Dino größer und zum orangen Raptor, mit einer Wolke.
6. Unten auf „Lobby“ tippen und 5 Sekunden warten: Du bist wieder in der Lobby, klein und mit 0 Punkten.
7. In den **DINODEX-Kreis** stellen: Die Sammlung öffnet sich, der Raptor ist freigeschaltet.

Wenn einer dieser Punkte nicht klappt: Das ist der erste Fehler, den du mir melden solltest (siehe Abschnitt 7). Danach lohnt es sich nicht, weiterzutesten.

## 4. Empfohlene Reihenfolge für den vollen Test

Jeweils den passenden Abschnitt in `docs/TESTLISTE.md` abarbeiten und Häkchen setzen:

| Reihenfolge | Abschnitt | Besonderheit |
| --- | --- | --- |
| 1 | Schritt 2: Arena, Bewegung, Sprint, Kamera | ein Spieler |
| 2 | Schritt 3: Futter | ein Spieler |
| 3 | Schritt 4: Dino-Modelle | ein Spieler |
| 4 | Schritt 7a: Speichern | veröffentlichtes Place nötig |
| 5 | Schritt 5: Fressen | **zwei Spieler** (siehe Abschnitt 5) |
| 6 | Schritt 6: Oberfläche | Geräte-Emulator (siehe Abschnitt 5) |
| 7 | Schritt 7b: Sammlung, 7c: Skins | nach 7a |
| 8 | Schritt 7d: Shop | erst nach dem Anlegen der Produkte, `docs/MONETARISIERUNG.md` |

Tipp: Die Schritte 5 und 7d sind am heikelsten. Nimm dir dafür Zeit.

## 5. Mehrspieler und Handy-Emulator

**Zwei Spieler:** Reiter Test → Clients and Servers → **Players: 2** → Start. Es öffnen sich zwei Client-Fenster und ein Server.
- Fressen testen: Im ersten Fenster `G` mehrmals drücken (zum Beispiel 5-mal, dann bist du schon Raptor und deutlich größer). Im zweiten Fenster als Compy stehen bleiben. Der Raptor muss nah an den Compy laufen. Erwartung: Der Compy verschwindet mit einer Wolke, nach etwa 3 Sekunden erscheint er wieder (4 Sekunden weißes Leuchten als Schutz), und beide sehen kurz eine Meldung.
- Schutzzeit: Direkt nach dem Respawn darf der Raptor den Compy nicht fressen.
- Skins: Im zweiten Fenster einen Skin wählen und im ersten prüfen, ob er sichtbar ist.

**Handy-Emulator:** Im laufenden Test im Reiter Test das Gerätemenü (Emulation) öffnen und ein Gerät wählen (360 × 640, 375 × 667, 390 × 844, ein Tablet, dann gedreht). Joystick, Sprint-Button, Status, Bestenliste, „Dinos“-Button und Fenster müssen sich vertragen. Touch-Gefühl und Leistung musst du zusätzlich auf einem echten Handy prüfen.

## 6. Nützliche Befehle (Befehlsleiste)

View → Command Bar. Während das Spiel läuft, lässt sich oben im Test-Reiter zwischen **Server** und **Client** umschalten. Die meisten Befehle gehören auf den **Server**.

```lua
-- Figur des ersten Spielers zurücksetzen (Neustart als Compy)
game.Players:GetPlayers()[1].Character.Humanoid.Health = 0

-- Teleport-Test: Der Server muss die Figur zurücksetzen, im Log steht "movement rejected"
game.Players:GetPlayers()[1].Character.HumanoidRootPart.CFrame += Vector3.new(100, 0, 0)

-- Alle Attribute des Spielers ansehen (Punkte, Stufe, Sammlung, Skins ...)
for name, value in game.Players:GetPlayers()[1]:GetAttributes() do print(name, value) end

-- Debug-Zeilen im Log einschalten (sehr gesprächig: jedes gefressene Futter)
require(game.ReplicatedStorage.Shared.Log).setDebugEnabled(true)
```

Der Server-Umschalter oder die Befehle können in deiner Studio-Version anders heißen. Wenn ein Befehl nicht geht, sag mir kurz, was passiert.

## 7. Fehler melden

Das brauche ich für jeden Fehler (je knapper, desto besser):

1. **Welcher Punkt** aus `docs/TESTLISTE.md` (oder Schritt in dieser Anleitung).
2. **Was du erwartet hast** und **was passiert ist**.
3. **Output-Zeilen:** Im Output alle roten und gelben Zeilen kopieren (Rechtsklick → Copy). Rote Zeilen von Roblox selbst enthalten oft Skriptname und Zeilennummer, das ist besonders wertvoll. Filter `BeDino` zeigt die Spiel-Zeilen, ohne Filter siehst du auch die Roblox-Fehler.
4. **Client oder Server:** Steht der Fehler im Server-Output oder im Client-Output?
5. Falls sichtbar: ein **Screenshot**.
6. Falls Handy-Emulator: das gewählte Gerät.

Ein Fehler pro Meldung. Reihenfolge nach Schwere: Absturz oder gar nichts sichtbar, dann falsches Verhalten, dann Optik.

## 8. Typische Probleme

| Symptom | Ursache und Lösung |
| --- | --- |
| `Infinite yield possible on 'ReplicatedStorage:WaitForChild("Shared")'` | Rojo ist nicht verbunden (`rojo serve` läuft nicht oder Connect fehlt). |
| `ServerPackages` oder `ProfileStore` nicht gefunden | `wally install` fehlt oder wurde nach dem Verbinden gemacht. Ausführen, Rojo neu starten, wieder verbinden. |
| Rojo meldet eine Versionsabweichung | `rojo plugin install` erneut, Studio neu starten. |
| `player plays as guest` | Place nicht veröffentlicht oder „Enable Studio Access to API Services“ aus (Schritt 1.4 und 1.5). |
| `HTTP 403` / `API Services rejected` im Output | wie oben, oder das Place gehört einem anderen Konto. |
| Alte Skripte laufen weiter | Du hast ein Skript in Studio geändert. Skripte nur im Repo bearbeiten, in Studio das Place neu laden. |
| Skript-Warnungen (orange/blaue Wellenlinien) im Editor | Typwarnungen von Studio. Melde sie, wenn sie zu einem echten Fehler führen, ansonsten nur kurz erwähnen. |

## 9. Was besonders wahrscheinlich Probleme macht

Das sind Stellen, an denen ich mir nicht sicher bin, ob Roblox sich so verhält. Achte dort besonders darauf.

1. **Figur unsichtbar, Dino sichtbar:** `StarterPlayer.LoadCharacterAppearance = false` plus Transparenz. Siehst du noch Kopf oder Kleidung der Roblox-Figur?
2. **Füße am Boden:** Die Offsets der Platzhalter-Dinos sind geschätzt (Schritt 4). Schweben oder versinken die Dinos? Nach dem Wachsen (Skalierung `ScaleTo`) auch?
3. **Kollision zwischen Spielern:** Laufen zwei Spieler wirklich durcheinander hindurch (`PlayerCollision`)?
4. **Gefressen werden:** Verschwindet der Dino sauber, keine Leiche, kein Ragdoll (`BreakJointsOnDeath = false`), Respawn nach etwa 3 Sekunden?
5. **Schutz-Leuchten (`Highlight`)** nach dem Respawn sichtbar?
6. **Schrift:** `FredokaOne` wird wirklich gezeigt (runde Schrift)?
7. **Layout bei 360 Pixel Breite:** Status links und Bestenliste rechts überlappen sich knapp nicht?
8. **Speichern:** Wird beim zweiten Start wirklich geladen (`status = loaded`)? Und ein Profil aus Schritt 7a wird beim Laden auf Version 2 migriert (`status = migrated`).
9. **Kaufdialog:** `PromptProductPurchase` ist auf der Roblox-Seite als veraltet markiert. Funktioniert der Dialog? Wird ein Beleg bestätigt (`receipt processed`)?
10. **Leistung:** Läuft es mit 450 Futterteilen flüssig (Stats mit Shift+F3)?
11. **Kamera:** Der Zoom folgt der Größe, ohne zu ruckeln oder zu springen.

## 10. Nach dem Test

- Setze in `docs/TESTLISTE.md` die Häkchen bei allem, was funktioniert, und schreibe bei Fehlern einen kurzen Satz dazu.
- Schick mir die Fehlerberichte (Abschnitt 7). Ich behebe sie in kleinen Branches (`fix/kurzer-name`), jeweils mit einem Test, wo es geht.
- Danach: Balance (Werte), echter Handy-Test, Produkte anlegen und die Richtlinienprüfung vor dem Start.
