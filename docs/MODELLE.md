# Dino-Modelle: von Blender ins Spiel

Reihenfolge, in der der Server das Aussehen eines Dinos wählt:

1. Ein fertiges Modell in `assets/models/<stufe>.rbxm` (siehe unten), falls vorhanden.
2. Die **echte Form** aus Blender (Abschnitt „Die echten Formen“), falls für die Körperform des Dinos schon eine Vorlage existiert.
3. Sonst der Platzhalter aus Parts (`src/shared/Config/DinoLooks.luau`).

## Die echten Formen (Blender)

Stil: kantiges Low-Poly (flach schattiert, große Flächen, wie die Quaternius-Dinos) mit realistischen Proportionen und natürlichen Filmfarben. Das spart Dreiecke (der Läufer hat 774) und sieht auf dem Handy klar aus. Es gibt sechs Körperformen (`runner`, `biped`, `duckbill`, `armored`, `horned`, `longneck`). Eine Form ist **ein** Satz Meshes; jeder Dino, der sie nutzt, bekommt seine eigenen Farben (aus seinem Plan in `Config/DinoLooks` oder aus `Config/DinoMeshes`). Fertig ist bisher nur `runner` (Compy, Raptor und alle Dinos mit dieser Form).

Eine Form besteht aus Teilen: den Hautteilen (**Body** und die beweglichen Teile, zum Beispiel **Tail**, **LegLeft**, **LegRight**; die Zeichnung steckt als Vertex-Farben im Mesh: dunkle Streifen, hellerer Bauch), **Accent** (Zähne, Stacheln, Krallen), **Eyes** (immer bernsteinfarben) und **Dark** (Pupillen, Mundlinie, Nüstern; fast schwarz). Haut und Accent nehmen die Farben des Dinos und der Varianten an, Eyes und Dark bleiben immer gleich.

### Laufen (Animation)

Die beweglichen Teile hängen mit einem Motor6D am festen Körper (`root` der Vorlage in `Config/DinoMeshes`; `limb` und `joint` pro Teil). Der Client (`DinoAnimator`) dreht die Gelenke nach `DinoAnim`: die Beine schwingen gegeneinander, der Schwanz pendelt, und die Schrittlänge hängt vom Tempo und der Größe ab, damit die Füße nicht rutschen. Im Stand pendelt nur der Schwanz leicht. Die Werte stehen in `Config/Animation`. Das läuft nur auf dem Client, nur nahe an der Kamera (`maxDistance`), und der Server wird nicht belastet. Die Winkel werden in `PreSimulation` geschrieben: Der Animator des Charakters setzt jedes Bild alle Gelenke gerade, danach gelten unsere Werte. Dinos mit Platzhalter-Look haben keine Gelenke und bleiben starr.

### Neue Form bauen

1. `tools/blender/dinos.py` in Blender ausführen (zum Beispiel über die MCP-Verbindung mit `exec`), `build("<form>")` baut die Meshes, `preview(...)` rendert Bilder, `export_fbx("<form>", "assets/blender/<form>.fbx")` schreibt die FBX-Datei. Der Export dreht das Modell um 180 Grad und skaliert mit 0,01: Roblox behält die Blender-Richtung (Blender +Y wird Roblox +Z) und liest Blender-Einheiten als Zentimeter. `dump_parts("<form>", pfad)` schreibt die Geometrie und die Mitte jedes Teils als JSON (Mitte = Versatz im Spiel; ein späterer Direkt-Upload aus Studio könnte darauf aufbauen, `AssetService:CreateAssetAsync` ist aber noch „not available yet").
2. In Studio: Asset Manager, **Bulk Import**, die FBX-Datei wählen (von Hand: aus Claudes Verbindung heraus geht es nicht, siehe oben). Es entsteht ein Model mit einem MeshPart pro Teil, die Meshes werden in das Konto hochgeladen (Moderation abwarten).
3. Prüfen: Größe passt zur Figur (der Läufer ist 9,46 Studs lang), die Füße stehen 3 Studs unter dem Pivot, die Augen liegen bei −Z.
4. Mesh-IDs, Größen und Versatz jedes Teils (Mitte des Teils relativ zum Pivot) in `Config/DinoMeshes` eintragen, bei beweglichen Teilen auch `limb` und `joint` (Gelenk relativ zur Figurmitte; bei der Hüfte des Läufers (±0,66, −1,1, 0,8), beim Schwanzansatz (0, −1,1, 1,6)). Das Studio-Beispiel:
   `local pivot = model:GetPivot(); print(pivot:PointToObjectSpace(part.Position), part.Size, part.MeshId)`.
5. Das Testmodell im Workspace wieder löschen (es gehört nicht ins Spiel).

Der `AppearanceService` lädt die Meshes beim Start mit `AssetService:CreateMeshPartAsync` und klont sie pro Dino. Schlägt das Laden fehl (falsche ID, keine Berechtigung), steht `mesh not loaded` im Log und die Dinos behalten ihren Platzhalter.

## So findet das Spiel ein Modell

- Rojo legt den Inhalt von `assets/models/` nach `ServerStorage/Models`.
- Der `AppearanceService` sucht dort ein **Model**, das genauso heißt wie die Stufen-ID aus `src/shared/Config/Dinos.luau`: eine der **50 Dino-IDs** aus `src/shared/Config/Dinos.luau` (von klein nach groß: `compy`, `dromaeo`, `raptor`, `troodon`, `oviraptor`, `coelo`, `deino`, `gallimimus`, `pachy`, `dilopho`, `iguano`, `para`, `proto`, `ankylo`, `stego`, `allo`, `cerato`, `carno`, `trike`, `edmonto`, `theri`, `baryonyx`, `utah`, `alberto`, `styraco`, `kentro`, `euoplo`, `maia`, `lambeo`, `diplo`, `camara`, `apato`, `brachio`, `mamenchi`, `trex`, `spino`, `giganoto`, `carcharo`, `mapu`, `acro`, `toro`, `sauropelta`, `shantungo`, `super`, `sauropo`, `dreadnought`, `argentino`, `patagotitan`, `puerta`, `titanosaur`). Beispiel: `assets/models/raptor.rbxm`. Bis ein Modell da ist, baut der Server den Platzhalter aus dem Körperplan in `Config/DinoLooks` (sechs Formen, siehe `src/shared/DinoBody.luau`).
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

## Offene Punkte

- Lauf-Animation: Noch nichts vorgesehen. Die Dinos gleiten starr, bis es Rigs und Animationen gibt.
- Die Kollisionsform bleibt die der Roblox-Figur (schmal, hochkant), auch bei langen Dinos.
- Roblox prüft hochgeladene Meshes (Moderation). Das gehört in den Zeitplan vor einem Test mit echten Modellen.
