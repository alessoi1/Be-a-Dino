# Dino-Modelle: von Blender ins Spiel

Bis echte Modelle da sind, baut der Server Platzhalter aus Parts (`src/shared/Config/DinoLooks.luau`).
Sobald in `assets/models/` ein passendes Modell liegt, wird es ohne Codeänderung benutzt.

## So findet das Spiel ein Modell

- Rojo legt den Inhalt von `assets/models/` nach `ServerStorage/Models`.
- Der `AppearanceService` sucht dort ein **Model**, das genauso heißt wie die Stufen-ID aus `src/shared/Config/Dinos.luau`: `compy`, `raptor`, `stego`, `trex`. Beispiel: `assets/models/raptor.rbxm`.
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
| Dreiecke | höchstens 1500 | von Hand in Blender, zur Laufzeit nicht zuverlässig messbar |
| Texturen | höchstens 512 × 512 | von Hand |

## Weg von Blender nach `.rbxm`

1. In Blender modellieren (Low-Poly), Maßstab so, dass der Dino zur Compy-Figur in Größe 1 passt, Ausrichtung `-Z` nach vorne, Anwenden von Skalierung und Rotation.
2. Als FBX exportieren.
3. In Roblox Studio über den Asset Manager importieren (Mesh wird dabei in Roblox hochgeladen und bekommt eine Asset-ID). Die Meshes gehören dem Konto oder der Gruppe, die hochlädt.
4. In Studio ein `Model` daraus machen, benennen (Stufen-ID), Pivot setzen, im Explorer rechtsklicken, „Speichern in Datei“ und als `.rbxm` unter `assets/models/<stufe>.rbxm` ablegen.
5. Mit `rojo serve` oder `rojo build` testen. Im Output erscheint beim Wechsel kein `model rejected`.

## Offene Punkte

- Lauf-Animation: Noch nichts vorgesehen. Die Dinos gleiten starr, bis es Rigs und Animationen gibt.
- Die Kollisionsform bleibt die der Roblox-Figur (schmal, hochkant), auch bei langen Dinos.
- Roblox prüft hochgeladene Meshes (Moderation). Das gehört in den Zeitplan vor einem Test mit echten Modellen.
