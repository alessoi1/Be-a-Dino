# Monetarisierung

Stand: Oktober 2026. Die Regeln von Roblox ändern sich. Vor dem Start gegen die aktuelle Dokumentation prüfen (siehe Checkliste unten).

## Was verkauft wird

- **Bezahlte Skins**, einer pro Dino (Berry, Midnight, Volcano, Frost). Sie ändern nur Farben, nie Größe, Tempo oder Fressen.
- Verkauft als **Developer Products** über `MarketplaceService`. Kein Game Pass, keine Abos.
- **Nicht** verkauft: Booster oder andere Werte-Vorteile, bezahlte Zufallsobjekte (Eier, Lootboxen). Beides ist bewusst ausgeschlossen (siehe `CLAUDE.md` und `docs/KONZEPT.md`).

## Wie ein Kauf abläuft

1. In der Sammlung steht bei einem bezahlten Skin „View offer“. Der Preis steht nicht im Spiel, er steht im Dialog von Roblox.
2. Tippen öffnet den Dialog (`SkinList.luau`). Das geht nur, wenn das Profil geladen ist (Attribut `DataReady`), und höchstens alle 2 Sekunden. Gäste sehen „Not available without saving“.
3. Nach dem Bezahlen ruft Roblox `ProcessReceipt` auf dem Server auf (`ReceiptService.luau`). Der Server nimmt das Profil des Spielers, vergibt den Skin über `Purchases.grant` (im Profil: `ownedSkins`) und speichert sofort.
4. **Erst danach** bestätigt der Server den Beleg (`PurchaseGranted`). Schlägt etwas fehl oder ist der Spieler weg, bleibt der Beleg offen (`NotProcessedYet`), und Roblox stellt ihn später wieder zu.
5. Der Spieler sieht „New skin: …“ und kann ihn ausrüsten.

**Idempotent:** Ein zweiter Beleg für dasselbe Produkt ändert nichts, `ownedSkins` ist eine Menge. Wird der Beleg nach dem Speichern, aber vor der Bestätigung unterbrochen, bestätigt der nächste Aufruf ohne zweites Vergeben.

## Produkte anlegen (Creator Hub)

1. Place veröffentlichen.
2. Creator Hub → dein Spiel → Monetization → Developer Products → neues Produkt.
3. Name, Beschreibung, Icon (höchstens 512 × 512 Pixel, wird rund angezeigt) und Preis (1 Robux bis 1 Milliarde).
4. Für den Test: **Preis 1 Robux**. Den echten Preis später im Creator Hub ändern, im Code steht kein Preis.
5. Menü „⋯“ am Produkt → **Copy Asset ID**.
6. Die ID in `src/shared/Config/Skins.luau` beim passenden Skin bei `productId` eintragen. Solange dort `0` steht, ist der Skin unsichtbar und nicht kaufbar. Jede ID darf nur bei einem Skin stehen (die Config prüft das).

Die IDs sind keine Geheimnisse. Trotzdem gehören keine Schlüssel oder Tokens ins Repo.

## Nicht listen

Die Produkte werden vorerst **nicht** in der Roblox-Store-Ansicht gelistet (Monetization → Shop), nur im Spiel verkauft. Listet man sie, prüft Roblox den Belegcode laufend und blendet fehlerhafte Produkte dort aus.

## Regeln im Spiel (aus `CLAUDE.md`)

- Kauftexte neutral („View offer“), nie drängend („Last chance“), keine Zähler und keine Zeitlimits.
- Der Kaufdialog öffnet sich nur nach bewusstem Tippen, nie automatisch.
- Kein Vorteil im PvP gegen Robux. Skins ändern keine Werte (der Code, der Werte berechnet, liest keine Skin-Daten).
- Keine bezahlten Zufallsobjekte. Falls es sie je gibt: alle Chancen als Prozent anzeigen (Summe 100 %) und für eingeschränkte Konten per `PolicyService` (`ArePaidRandomItemsRestricted`) ausblenden oder einen kostenlosen Weg anbieten.
- PvP altersgerecht (Wolke statt Blut), siehe `docs/KONZEPT.md`.

## Checkliste vor dem Start

- [ ] Aktuelle Roblox **Community Standards** und **Nutzungsbedingungen** gelesen (Abschnitte zu Monetarisierung, Kindern und Jugendlichen). Das habe ich nicht abschließend prüfen können, siehe unten.
- [ ] Altersangaben im Fragebogen (Experience Guidelines) korrekt.
- [ ] Alle vier Produkte angelegt, Namen, Beschreibungen und Icons angemessen, echte Preise gesetzt.
- [ ] Kauftest mit jedem Produkt: Dialog erscheint, Skin kommt an, nach Neustart des Spiels ist er noch da, ein zweiter Beleg vergibt nichts doppelt.
- [ ] Gast-Test (ohne Speichern): kein Kaufknopf.
- [ ] Beleg bleibt offen, wenn der Spieler vor dem Speichern geht, und wird beim Wiedereintritt vergeben.
- [ ] `PromptProductPurchase` funktioniert in der aktuellen Studio-Version. Auf der Referenzseite ist die Methode als veraltet markiert, ohne einen Nachfolger zu nennen. Der Aufruf ist an einer Stelle (`SkinList.luau`, `promptPurchase`) und leicht auszutauschen.
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
