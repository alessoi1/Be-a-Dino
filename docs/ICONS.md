# Icons

Die Oberfläche zeigt seit K5 Icons (Config: `src/shared/Config/Icons.luau`). Solange ein Icon kein Bild hat (`assetId = 0`), erscheint stattdessen ein Symbolzeichen, damit alles auch ohne Bilder funktioniert. Die Symbole sind nur ein Notbehelf und sehen auf jedem Gerät etwas anders aus.

## Bilder, die gebraucht werden

| Name in der Config | Wo | Bedeutung |
| --- | --- | --- |
| `size` | Statusfeld links oben | Size (Punkte) des Dinos |
| `coin` | Münzzähler | Münzen |
| `sprint` | Sprint-Knopf | Sprint |
| `stamina` | Ausdauerleiste unten | Ausdauer |
| `autofarm` | Autofarm-Knopf | Autofarm |
| `leaderboard` | Titel der Bestenliste | Rangliste |
| `lobby` | „Lobby“-Knopf in der Arena | zurück zur Lobby |

Für Health, Hunger und Bite gibt es keine Icons, die Systeme entfallen (siehe `docs/KONZEPT.md`).

## Format

- PNG, quadratisch (zum Beispiel 256 × 256), **weiße Form auf durchsichtigem Grund**. Die Farbe kommt aus der Config (`color`), das Bild wird damit eingefärbt. Bunte Bilder funktionieren auch, dann `color` auf Weiß (255, 255, 255) setzen.
- Klare, dicke Formen, die auch bei 24 Pixeln lesbar sind (Handy zuerst).
- Ein einheitlicher Stil (gleiche Strichstärke, gleiche Ecken) für alle sieben.

## Einbauen

1. Bild im Creator Hub hochladen (Assets, Images) und die Asset-ID kopieren (die Zahl).
2. In `src/shared/Config/Icons.luau` bei dem Icon `assetId = 0` durch die Zahl ersetzen.
3. In Studio prüfen: das Bild erscheint statt des Symbols. Wird nichts angezeigt, ist die ID falsch oder das Bild noch nicht freigegeben (Moderation dauert manchmal).

Uploads und Asset-IDs macht der Spielentwickler; keine Schlüssel oder Tokens ins Repo.

## Stand 14. Oktober 2026: Symbole für Kinder

Die Oberfläche arbeitet bildlastig: Fast alle Texte sind durch bunte Emoji-Symbole (`glyph` in `Config/Icons`) ersetzt oder ergänzt, damit Kinder sie ohne Lesen verstehen (Sprint- und Autofarm-Knopf nur Symbol, Todes-Fenster mit drei grossen Bild-Knöpfen, Futter-Zähler und Münzen mit Symbol). Emoji behalten ihre eigenen Farben, `color` ändert sie nicht. Neue Symbole: `eaten`, `food`, `next`, `offer`, `locked`, `ate`, `party`, `timer`, `on`, `step` und `potion_<id>` je Trank. Echte Bilder ersetzen sie wie oben beschrieben über `assetId`; dann `color` auf Weiß setzen, wenn das Bild bunt ist.
