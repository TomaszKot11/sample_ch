Die Aufgabe

Wir haben eine Delivery Condition, die bestimmt, wie lange die Lieferzeit ist. Sie ist entweder auf dem Article oder auf dem Product definiert und unterscheidet sich, je nachdem wohin (in welches Land) der Artikel geliefert wird.

Implementiere eine Method auf dem Product welche ein Land (country) erhält als Parameter und  dann folgende Beschreibung zurück gibt:

"delivery description X bis Y Tage"  bzw. "delivery description from X to Y days"

Article => SKU aus dem ERP
Product => Product Page in the E-Commerce

Wenn die Delivery Condition auf dem Product und auf dem Article vorhanden ist, dann soll die des Product verwendet werden.