# Zweck

Das Perl Skript erzeugt aus einer ASCII-Textdatei eine HTML-Datei, die für den gesamten Text, jeden Paragraphen und jeden Satz verschiedene Formeln zu Berechnung der Lesbarkeit berechnet. Hohe Werte bedeuten in der Regel schwieriger zu lesenden Texte und kleine Werte einfacher zu lesenden Texte.  

# Aufruf

`perl lesbarkeit.pl meintext`

erzeugt aus der Datei `meintext.txt` die Datei `meintext.htm`.

# Installation

Installieren Sie die vier Dateien in einem eignen Verzeichnis. Es wird eine aktuelle Perl-Version und das Perl Module HTML::Template benötigt.

# Inhalt

    lesbarkeit.pl    Perl-Skript
    base.htm         Basis HTML Seite
    abduktion.txt    Testtext aus ILMES (http://wlm.userweb.mwn.de/ilm_a1.htm)
    abduktion.htm    Ergebnis der Lesbarkeitsanalyse 

# Rechtliche Hinweise

* Falls Sie die Ergebnisse der Analysen publizieren wollen, beachten Sie die Urheberechte der verwendeten Texte.
* Die Software steht unter der Apache License, Version 2.0, näheres siehe [LICENCE](LICENCE).