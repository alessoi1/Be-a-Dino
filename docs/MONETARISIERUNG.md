# Monetarisierung

Stand: Oktober 2026. Die Regeln von Roblox ändern sich. Vor dem Start gegen die aktuelle Dokumentation prüfen (siehe Checkliste unten).

## Was es bisher gibt und was nicht

- **Noch nichts wird verkauft.** Die bezahlten Skins aus Schritt 7c und 7d gibt es nicht mehr: Die Varianten (Glowing, Gold, Shadow, Rainbow) ersetzen sie und kommen **mit Münzen aus Eiern**, nicht mit Robux. Münzen gibt es nur durch Spielen, nie gegen Robux.
- Der `ReceiptService` (genau ein `ProcessReceipt`, bestätigt erst nach dem Speichern) bleibt als Grundlage für **L8**, hat aber noch keinen Handler. Ohne Handler bleibt jeder Beleg offen (`NotProcessedYet`), und Roblox stellt ihn später wieder zu.

## Was in L8 verkauft werden soll (noch nicht gebaut)

Vom Spielentwickler am 10. Oktober 2026 ausdrücklich freigegeben, siehe `docs/KONZEPT.md` (Ausbau) und `CLAUDE.md`:

- **Wiederbeleben in gleicher Größe** nach dem Gefressenwerden (Robux).
- **Kopfgeld auf den Killer setzen** (Robux). Wer den Markierten frisst, bekommt 3-mal so viele Münzen.
- **Tränke** (Booster), die man gegen Robux kauft.
- **Eventuell Glückseier** gegen Robux mit höheren Chancen auf seltene Varianten. Das sind bezahlte Zufallsobjekte (alle Chancen als Prozent, `PolicyService`, kein Handel mit den Ergebnissen). Noch nicht entschieden.

Vor dem Bau von L8 gilt: aktuelle Roblox-Richtlinien prüfen, die Produkte im Creator Hub anlegen und jeden weiteren bezahlten Vorteil erneut mit dem Spielentwickler abstimmen.

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
