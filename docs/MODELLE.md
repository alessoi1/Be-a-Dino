# Dino-Modelle: von Blender ins Spiel

Reihenfolge, in der der Server das Aussehen eines Dinos wählt:

1. Ein fertiges Modell in `assets/models/<stufe>.rbxm` (siehe unten), falls vorhanden.
2. Die **echte Form** aus Blender (Abschnitt „Die echten Formen“), falls für die Körperform des Dinos schon eine Vorlage existiert.
3. Sonst der Platzhalter aus Parts (`src/shared/Config/DinoLooks.luau`).

## Die echten Formen (Blender)

Stil: kantiges Low-Poly (flach schattiert, große Flächen, wie die Quaternius-Dinos) mit realistischen Proportionen und natürlichen Filmfarben. Das spart Dreiecke (der Läufer hat 774) und sieht auf dem Handy klar aus. Es gibt sechs Körperformen (`runner`, `biped`, `duckbill`, `armored`, `horned`, `longneck`). Eine Form ist **ein** Satz Meshes; jeder Dino, der sie nutzt, bekommt seine eigenen Farben (aus seinem Plan in `Config/DinoLooks` oder aus `Config/DinoMeshes`). Alle sechs Formen sind fertig, damit hat jedes der 50 Dinos eine echte Form (ein Test in `tests/specs/DinoMesh.spec.luau` prüft das).

Eine Form besteht aus Teilen: den Hautteilen (**Body** und die beweglichen Teile, zum Beispiel **Tail**, **LegLeft**, **LegRight**; die Zeichnung steckt als Vertex-Farben im Mesh: dunkle Streifen, hellerer Bauch), **Accent** (Zähne, Stacheln, Krallen), **Eyes** (immer bernsteinfarben) und **Dark** (Pupillen, Mundlinie, Nüstern; fast schwarz). Haut und Accent nehmen die Farben des Dinos und der Varianten an, Eyes und Dark bleiben immer gleich.

### Farben

Jede Form hat eine eigene **Farbfamilie** (Läufer olivgrün und sandbraun, biped rotbraun, duckbill blaugrün mit orangem Kamm, armored steingrau, horned sandorange, longneck blaugrau), damit man die Art schon an der Farbe erkennt. Ein Dino nimmt einen der vier Töne seiner Familie (`families` in `Config/DinoLooks`). Die Blender-Vorschau benutzt den ersten Ton jeder Familie (`SKINS` in `tools/blender/dinos.py`); das Modell selbst ist farbneutral, ein neuer Ton braucht also keinen neuen Import.

### Laufen (Animation)

Die beweglichen Teile hängen mit einem Motor6D am festen Körper (`root` der Vorlage in `Config/DinoMeshes`; `limb` und `joint` pro Teil). Der Client (`DinoAnimator`) dreht die Gelenke nach `DinoAnim`: die Beine schwingen gegeneinander (Zweibeiner `legLeft` und `legRight`; Vierbeiner im Passgang: vorne links mit hinten rechts, vorne rechts mit hinten links), der Schwanz pendelt, und die Schrittlänge hängt vom Tempo und der Größe ab, damit die Füße nicht rutschen. Im Stand pendelt nur der Schwanz leicht. Die Werte stehen in `Config/Animation`. Das läuft nur auf dem Client, nur nahe an der Kamera (`maxDistance`), und der Server wird nicht belastet. Die Winkel werden in `PreSimulation` geschrieben: Der Animator des Charakters setzt jedes Bild alle Gelenke gerade, danach gelten unsere Werte. Dinos mit Platzhalter-Look haben keine Gelenke und bleiben starr.

### Idle, Fressen und Verschwinden

Zusätzlich zu den Gliedern bewegt der Client den **ganzen Körper** über ein Gelenk `body` (ein Motor6D statt der Schweißnaht, am Mittelpunkt der Figur; nur bei echten Formen, Platzhalter bleiben starr):
- **Idle:** Im Stand hebt und senkt sich der Körper langsam wie beim Atmen (`breathLift`), dazu pendelt der Schwanz wie bisher.
- **Laufen:** Der Körper wippt pro Schritt zweimal (`bobLift`) und lehnt sich leicht nach vorn (`walkLean`).
- **Fressen („Happs“):** Wenn in der Nähe eines Dinos (`eatReach` Studs je Größe) ein Futterstück verschwindet, nickt er kurz nach unten und duckt sich (`eatPitch`, `eatDip`, `eatSeconds`). Das gilt für Spieler und Bots. Schnelle Bisse starten die Bewegung erst ab ihrer Mitte neu, damit nichts zittert.
- **Verschwinden:** Wird ein Dino gefressen, löst er sich wie bisher in einer Wolke auf (Partikel, `playCloud`); eine eigene Todes-Animation gibt es nicht (kein Blut, siehe CLAUDE.md).
Alles ist reine Optik auf dem Client, der Server ändert nur die Verbindung (Motor6D `body`). Eine echte Beiß-Animation mit beweglichem Kopf braucht ein eigenes Kopfteil im Mesh (heute steckt der Kopf im Körperteil); das wäre ein Umbau der sechs Blender-Formen.

### Neue Form bauen

1. `tools/blender/dinos.py` in Blender ausführen (zum Beispiel über die MCP-Verbindung mit `exec`), `build("<form>")` baut die Meshes, `preview(...)` rendert Bilder, `export_fbx("<form>", "assets/blender/<form>.fbx")` schreibt die FBX-Datei. Der Export dreht das Modell um 180 Grad und skaliert mit 0,01: Roblox behält die Blender-Richtung (Blender +Y wird Roblox +Z) und liest Blender-Einheiten als Zentimeter. `dump_parts("<form>", pfad)` schreibt die Geometrie und die Mitte jedes Teils als JSON (Mitte = Versatz im Spiel; ein späterer Direkt-Upload aus Studio könnte darauf aufbauen, `AssetService:CreateAssetAsync` ist aber noch „not available yet").
2. In Studio: Asset Manager, **Bulk Import**, die FBX-Datei wählen (von Hand: aus Claudes Verbindung heraus geht es nicht, siehe oben). Es entsteht ein Model mit einem MeshPart pro Teil, die Meshes werden in das Konto hochgeladen (Moderation abwarten).
3. Prüfen: Größe passt zur Figur (der Läufer ist 9,46 Studs lang), die Füße stehen 3 Studs unter dem Pivot, die Augen liegen bei −Z.
4. Mesh-IDs, Größen und Versatz jedes Teils (Mitte des Teils relativ zum Pivot) in `Config/DinoMeshes` eintragen (am einfachsten in Studio mit einem Skript als fertigen Text ausgeben lassen und danach gegen die Importe prüfen), bei beweglichen Teilen auch `limb` und `joint` (Gelenk relativ zur Figurmitte; bei der Hüfte des Läufers (±0,66, −1,1, 0,8), beim Schwanzansatz (0, −1,1, 1,6)). Das Studio-Beispiel:
   `local pivot = model:GetPivot(); print(pivot:PointToObjectSpace(part.Position), part.Size, part.MeshId)`.
5. Das Testmodell im Workspace wieder löschen (es gehört nicht ins Spiel).

Der `AppearanceService` lädt die Meshes beim Start mit `AssetService:CreateMeshPartAsync` und klont sie pro Dino. Alle Teile aller Formen laden gleichzeitig und jede Form ist einzeln freigegeben, sobald sie da ist (52 Meshes nacheinander dauerten länger als die Wartezeit und blockierten den Start). Wer in der Zwischenzeit einen Platzhalter bekam, bekommt danach die echte Form; Bots warten nicht auf ihr Aussehen. Schlägt das Laden fehl (falsche ID, keine Berechtigung), steht `mesh not loaded` im Log und die Dinos behalten ihren Platzhalter.

## So findet das Spiel ein Modell

- Rojo legt den Inhalt von `assets/models/` nach `ServerStorage/Models`.
- Der `AppearanceService` sucht dort ein **Model**, das genauso heißt wie die Stufen-ID aus `src/shared/Config/Dinos.luau`: eine der **35 Dino-IDs** aus `src/shared/Config/Dinos.luau` (von klein nach groß: `compy`, `dromaeo`, `raptor`, `troodon`, `oviraptor`, `coelo`, `deino`, `gallimimus`, `pachy`, `dilopho`, `iguano`, `para`, `proto`, `ankylo`, `stego`, `allo`, `cerato`, `carno`, `trike`, `edmonto`, `theri`, `baryonyx`, `utah`, `alberto`, `styraco`, `kentro`, `euoplo`, `maia`, `lambeo`, `diplo`, `camara`, `apato`, `brachio`, `mamenchi`, `trex`). Beispiel: `assets/models/raptor.rbxm`. Bis ein Modell da ist, baut der Server den Platzhalter aus dem Körperplan in `Config/DinoLooks` (sechs Formen, siehe `src/shared/DinoBody.luau`).
- Besteht das Modell die Prüfung nicht (Fehler im Log `model rejected`), nimmt der Server den Platzhalter.

## Regeln für ein Modell

- Ein `Model` mit allen Teilen als `MeshPart` oder `Part`, Name = Stufen-ID.
- **Pivot** (Ursprung des Modells) auf der Figurmitte setzen. Das ist die Mitte der Roblox-Figur, etwa 3 Studs über dem Boden.
- Blickrichtung wie in Roblox: Vorne ist `-Z`.
- Die Füße stehen 3 Studs unter dem Pivot (Höhe der Figur-Füße bei Größe 1). Das Spiel skaliert das Modell danach mit der Stufe (siehe `scale` in `Config/Dinos`). Ein Dino wird also **in Größe 1** gebaut, nicht in Endgröße.
- Alle Teile unverankert zu lassen reicht, das Spiel verschweißt sie, schaltet Kollision aus und macht sie gewichtslos.
- Verboten: Skripte, Sounds im Modell.

## Budget pro Dino (Handy zuerst)

| Was | Grenze | Wer prüft |
| --- | --- | --- |
| Teile (Parts und MeshParts) | höchstens 12 | Server beim Laden (`maxParts` in `Config/DinoLooks`) |
| Dreiecke | höchstens 3000 (der kantige Läufer hat 774) | von Hand in Blender, zur Laufzeit nicht zuverlässig messbar |
| Texturen | höchstens 512 × 512 | von Hand |

## Weg von Blender nach `.rbxm`

1. In Blender modellieren (Low-Poly), Maßstab so, dass der Dino zur Compy-Figur in Größe 1 passt, Ausrichtung `-Z` nach vorne, Anwenden von Skalierung und Rotation.
2. Als FBX exportieren.
3. In Roblox Studio über den Asset Manager importieren (Mesh wird dabei in Roblox hochgeladen und bekommt eine Asset-ID). Die Meshes gehören dem Konto oder der Gruppe, die hochlädt.
4. In Studio ein `Model` daraus machen, benennen (Stufen-ID), Pivot setzen, im Explorer rechtsklicken, „Speichern in Datei“ und als `.rbxm` unter `assets/models/<stufe>.rbxm` ablegen.
5. Mit `rojo serve` oder `rojo build` testen. Im Output erscheint beim Wechsel kein `model rejected`.

## Varianten und echte Modelle

Die Varianten (Glowing, Gold, Shadow, Rainbow, siehe `src/shared/Config/Variants.luau`) färben und beschichten bisher nur die Platzhalter (Rollen `body` und `accent` pro Teil, Material pro Variante). Ein echtes Modell wird noch nicht verändert: Es erscheint immer mit seinen eigenen Farben und ohne Rainbow-Animation. Wie Varianten bei echten Modellen funktionieren (zum Beispiel ein anderes Material und eine Tönung auf den MeshParts, oder Textur-Varianten im Modell), legen wir fest, sobald die ersten echten Modelle da sind. Varianten dürfen dabei nie Hitbox, Größe oder Werte ändern.

## Futter

Jede Futtergröße (klein, mittel, groß; `src/shared/Config/Food.luau`) hat mehrere Aussehen (`variants`). Bis ein Mesh eingetragen ist, wird eine einfache Form gezeichnet (`shape`: ball, block, cylinder, wedge) in der Farbe des Aussehens. Ein echtes Modell einbauen:

Die neun Modelle gibt es schon: `tools/blender/food.py` baut sie in Blender (Beere, Blatt, Samen, Frucht, Melone, Pilz, Fleischkeule, Fisch, Ei; kantig und mit Vertex-Farben bemalt, 20 bis 80 Dreiecke, Mittelpunkt in der Mitte, etwa 1 Stud groß), und `assets/blender/food.fbx` ist der Export. Ein Satz Anleitung für Blender steht oben in der Datei (`build_food()`, `food_lineup(pfad)`, `export_food(pfad)`). Einbauen:
1. In Roblox Studio im Asset Manager **Bulk Import** und `assets/blender/food.fbx` wählen. Es entsteht ein Model mit neun MeshParts (`food_Berry`, `food_Leaf`, `food_Seed`, `food_Fruit`, `food_Melon`, `food_Mushroom`, `food_Meat`, `food_Fish`, `food_Egg`); die Meshes werden hochgeladen (Moderation abwarten).
2. Die **Mesh-ID** jedes MeshParts kopieren (Eigenschaft `MeshId`, nur die Zahl).
3. In `src/shared/Config/Food.luau` bei dem Aussehen mit dem passenden Namen (`berry`, `leaf`, ...) `meshId = 0` durch die Zahl ersetzen. `meshScale` bleibt `1,1,1`; ist ein Mesh zu groß oder zu klein, den Wert dort ändern.
4. In Studio prüfen: Das Stück sieht richtig aus (Farben wie gemalt, nicht im Boden, nicht zu groß oder zu klein).

Eingetragen sind die neun IDs seit dem 13. Oktober 2026. Das Futter ist mit Mesh ein **MeshPart** (ein `SpecialMesh` zeigte die gemalten Vertex-Farben nicht, nur Weiß): Beim Start lädt der Server jedes Mesh einmal (`AssetService:CreateMeshPartAsync`) und klont es; es gibt einen Pool pro Aussehen, damit ein Stück sein Mesh nie wechseln muss. Aussehen ohne `meshId` oder mit einem Ladefehler (Log `food mesh not loaded`) bleiben die einfachen Formen. Das importierte Model `Workspace.food` aus Studio wird nicht mehr gebraucht und sollte gelöscht werden (es gehört nicht ins Spiel).

**Sound:** Für den Fress-Ton eine Roblox-Sound-ID („rbxassetid://…“) bei `soundId` in `Config/FoodEffects` eintragen (nur eigene oder geprüfte Sounds, kein Toolbox-Ungeprüftes). Ohne ID bleibt es still.

## Offene Punkte

- Lauf-Animation: Noch nichts vorgesehen. Die Dinos gleiten starr, bis es Rigs und Animationen gibt.
- Die Kollisionsform bleibt die der Roblox-Figur (schmal, hochkant), auch bei langen Dinos.
- Roblox prüft hochgeladene Meshes (Moderation). Das gehört in den Zeitplan vor einem Test mit echten Modellen.
