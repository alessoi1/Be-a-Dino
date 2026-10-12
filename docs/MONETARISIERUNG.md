# Monetarisierung

Stand: Oktober 2026. Die Regeln von Roblox ändern sich. Vor dem Start gegen die aktuelle Dokumentation prüfen (siehe Checkliste unten).

## Was es bisher gibt und was nicht

- **Noch nichts wird verkauft.** Die bezahlten Skins aus Schritt 7c und 7d gibt es nicht mehr: Die Varianten (Glowing, Gold, Shadow, Rainbow) ersetzen sie und kommen **mit Münzen aus Eiern**, nicht mit Robux. Münzen gibt es nur durch Spielen, nie gegen Robux.
- Der `ReceiptService` (genau ein `ProcessReceipt`, bestätigt erst nach dem Speichern) hat seit **L8** einen Handler im `OfferService` für die sechs Produkte (IDs in `Config/Offers`). Ohne Handler bleibt jeder Beleg offen (`NotProcessedYet`), und Roblox stellt ihn später wieder zu.

## Was in L8 verkauft werden soll (noch nicht gebaut)

Vom Spielentwickler am 10. Oktober 2026 ausdrücklich freigegeben, siehe `docs/KONZEPT.md` (Ausbau) und `CLAUDE.md`:

- **Wiederbeleben in gleicher Größe** nach dem Gefressenwerden (Robux).
- **Kopfgeld auf den Killer setzen** (Robux). Wer den Markierten frisst, bekommt 3-mal so viele Münzen.
- **Tränke** (Booster), die man gegen Robux kauft.
- **Eventuell Glückseier** gegen Robux mit höheren Chancen auf seltene Varianten. Das sind bezahlte Zufallsobjekte (alle Chancen als Prozent, `PolicyService`, kein Handel mit den Ergebnissen). Noch nicht entschieden.

Vor dem Bau von L8 gilt: aktuelle Roblox-Richtlinien prüfen, die Produkte im Creator Hub anlegen und jeden weiteren bezahlten Vorteil erneut mit dem Spielentwickler abstimmen.

## Entscheidungen für L8 (12. Oktober 2026)

- **Ein Branch** für alles: Wiederbeleben, Kopfgeld und Tränke.
- **Tränke:** Wachstums-Trank, Münzen-Trank, Tempo-Trank und Schutz-Trank, alle zeitlich begrenzt und nur in der Arena wirksam. Tempo- und Schutz-Trank wirken direkt im PvP und sind damit die stärksten bezahlten Vorteile; sie sind vom Spielentwickler freigegeben, die genauen Werte stehen aber noch aus (siehe Plan).
- **Glückseier gegen Robux werden nicht gebaut.** Damit entfallen die Pflichten für bezahlte Zufallsobjekte. Eier bleiben nur mit Münzen (Münzen gibt es nie gegen Robux). Ein Trank darf die Chancen im Ei nie verändern, sonst wäre es ein „Odds-Booster“ mit Pflichten.

### Werte (Vorschläge, vom Spielentwickler am 12. Oktober 2026 übernommen, noch Startwerte)

- Wachstums-Trank: 2× Punkte vom Futter, 10 Minuten. Münzen-Trank: 2× Münzen, 10 Minuten.
- Tempo-Trank: +15 % Tempo, 10 Minuten. Schutz-Trank: +5 Sekunden Schutzzeit nach dem Start.
- Revive: gleiche Größe und Stufe, sichere Startstelle, normale Schutzzeit danach, nur im 15-Sekunden-Fenster nach dem Gefressenwerden.
- Kopfgeld auf den Killer: Münzen ×3 für den, der ihn frisst (wie schon im Gerüst).

### Developer Products, die im Creator Hub anzulegen sind (6 Stück, zum Testen je 1 Robux)

| Name im Creator Hub | Zweck |
| --- | --- |
| Revive | Wiederbeleben in gleicher Größe |
| Bounty | Kopfgeld auf den Killer |
| Growth Potion | 2× Punkte, 10 Minuten |
| Coin Potion | 2× Münzen, 10 Minuten |
| Speed Potion | +15 % Tempo, 10 Minuten |
| Shield Potion | +5 s Schutzzeit |

Alle sechs ohne Listung im Shop anlegen (nur im Spiel verkaufen).

## Richtlinienprüfung (Roblox-Dokumentation, 12. Oktober 2026 gelesen)

- **Developer Products:** `ProcessReceipt` genau einmal in einem Server-Skript, `PurchaseGranted` erst nach dem Vergeben, sonst `NotProcessedYet`. `PromptProductPurchase(player, productId)` wird auf der Seite noch ohne Warnung als der Weg zum Auslösen genannt, vom Client nach einem Tipp. Roblox speichert keinen Kaufverlauf pro Spieler; das Merken (Idempotenz) liegt bei uns. Produkte nicht im Shop listen (nur im Spiel verkaufen). Verkauf zwischen Spielen ist seit 30. Mai 2026 abgeschaltet.
- **Bezahlte Zufallsobjekte** (nur relevant, falls Glückseier doch kommen): alle Chancen als Prozent, Summe genau 100 %, vor dem Kauf; `ArePaidRandomItemsRestricted` per `PolicyService` pro Spieler prüfen und dann Ersatzweg anbieten oder ausblenden; kein Handel mit den Ergebnissen. Zufall, der nur durch Spielen oder mit Münzen (nie mit Robux gekauft) entsteht, braucht keine Offenlegung.
- Weiterhin offen und von einem Menschen zu lesen: die Community Standards und Nutzungsbedingungen zu Druck-Praktiken und Ausgaben von Minderjährigen (siehe unten).

## Wie ein Kauf ablaufen soll

1. Der Spieler tippt auf ein Angebot („View offer“). Den Preis zeigt Roblox im Kaufdialog, er steht nicht im Spiel. Das geht nur, wenn das Profil geladen ist (Attribut `DataReady`), und höchstens alle paar Sekunden. Gäste können nicht kaufen.
2. Roblox ruft `ProcessReceipt` auf dem Server auf (`ReceiptService.luau`). Ein Handler pro Produktart prüft Spieler, Produkt und Profil, vergibt die Ware im Profil und speichert sofort.
3. **Erst danach** bestätigt der Server den Beleg (`PurchaseGranted`). Schlägt etwas fehl oder ist der Spieler weg, bleibt der Beleg offen (`NotProcessedYet`).
4. Das Vergeben muss **idempotent** sein: Ein zweiter Beleg für dasselbe Produkt ändert nichts. Wird der Beleg nach dem Speichern, aber vor der Bestätigung unterbrochen, bestätigt der nächste Aufruf ohne zweites Vergeben.

## Produkte anlegen (Creator Hub), wenn L8 gebaut wird

1. Place veröffentlichen.
2. Creator Hub → dein Spiel → Monetization → Developer Products → neues Produkt.
3. Name, Beschreibung, Icon (höchstens 512 × 512 Pixel, wird rund angezeigt) und Preis (1 Robux bis 1 Milliarde).
4. Für den Test: **Preis 1 Robux**. Den echten Preis später im Creator Hub ändern, im Code steht kein Preis.
5. Menü „⋯“ am Produkt → **Copy Asset ID**.
6. Die ID in die Config des jeweiligen Angebots eintragen. Die IDs sind keine Geheimnisse, aber Schlüssel oder Tokens gehören nie ins Repo.

Die Produkte werden vorerst **nicht** in der Roblox-Store-Ansicht gelistet (Monetization → Shop), nur im Spiel verkauft. Listet man sie, prüft Roblox den Belegcode laufend und blendet fehlerhafte Produkte dort aus.

## Regeln im Spiel (aus `CLAUDE.md`)

- Kauftexte neutral („View offer“), nie drängend („Last chance“), keine Zähler und keine Zeitlimits.
- Der Kaufdialog öffnet sich nur nach bewusstem Tippen, nie automatisch.
- Varianten ändern nie Werte, nur das Aussehen. Bezahlte Vorteile im PvP sind nur die oben genannten und nur nach Rückfrage.
- Münzen nie gegen Robux.
- Zufallsobjekte gegen Robux nur mit allen Chancen als Prozent (auch den erhöhten), Ausblenden oder kostenlosem Weg für eingeschränkte Konten per `PolicyService` (`ArePaidRandomItemsRestricted`) und ohne Handel mit den Ergebnissen.
- PvP altersgerecht (Wolke statt Blut), siehe `docs/KONZEPT.md`.

## Checkliste vor dem Start

- [ ] Aktuelle Roblox **Community Standards** und **Nutzungsbedingungen** gelesen (Abschnitte zu Monetarisierung, Kindern und Jugendlichen). Das habe ich nicht abschließend prüfen können, siehe unten.
- [ ] Altersangaben im Fragebogen (Experience Guidelines) korrekt.
- [ ] Alle Produkte angelegt, Namen, Beschreibungen und Icons angemessen, echte Preise gesetzt.
- [ ] Kauftest mit jedem Produkt: Dialog erscheint, die Ware kommt an, nach Neustart des Spiels ist sie noch da, ein zweiter Beleg vergibt nichts doppelt.
- [ ] Gast-Test (ohne Speichern): kein Kaufknopf.
- [ ] Beleg bleibt offen, wenn der Spieler vor dem Speichern geht, und wird beim Wiedereintritt vergeben.
- [ ] `PromptProductPurchase` funktioniert in der aktuellen Studio-Version. Auf der Referenzseite ist die Methode als veraltet markiert, ohne einen Nachfolger zu nennen. Der Aufruf soll an einer einzigen Stelle stehen und leicht austauschbar sein.
- [ ] Rückerstattungen und Support: Roblox meldet Rückerstattungen nicht automatisch. Entscheiden, wie damit umgegangen wird.

## Was ich nicht prüfen konnte

- Offizielle Roblox-Regeln zu Druck-Praktiken im Spiel und zu Ausgaben von Minderjährigen. Eine Suche hat nur eine Studie der Universität Sydney (März 2026) zu täuschenden Kauf-Praktiken gefunden, aber keinen Regeltext von Roblox. Die Seiten selbst muss ein Mensch lesen.
- Ob ein Kauf in Studio echte Robux kostet. Vor dem ersten Test im Dialog ansehen und das 1-Robux-Produkt nehmen.
- Ob `BindReceiptHandler` (neuere Alternative zu `ProcessReceipt`) Vorteile hat. Für ein einziges Produktmodell reicht `ProcessReceipt`.

## Quellen

- [Developer Products](https://create.roblox.com/docs/production/monetization/developer-products)
- [ProcessReceipt und BindReceiptHandler](https://create.roblox.com/docs/reference/engine/classes/MarketplaceService/ProcessReceipt)
- [MarketplaceService](https://create.roblox.com/docs/reference/engine/classes/MarketplaceService)
- [Paid random items](https://create.roblox.com/docs/production/monetization/paid-random-items)
