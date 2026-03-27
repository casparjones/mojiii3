# Ethische Monetarisierungsmodelle - Match3 Emoji Puzzle Game

**Sales Agent 1 - Recherche & Konzept**
**Stand: 27. Maerz 2026**

---

## Ausgangslage

Unser Spiel ist ein Flutter-basierter Candy-Crush-Klon mit Emoji-Grafik. Es existiert bereits:
- 6 Basis-Gem-Typen (Frucht-Emojis) mit 24 visuellen Edelstein-Varianten
- Ein Shop-System mit Themes (Fruit, Animals, Space) und Power-Ups
- In-Game-Waehrung (Coins), die durch Spielen verdient wird
- Spezialgems (Striped, Bomb, Rainbow)
- Level-System mit Hindernissen

**Grundprinzip:** Kein Pay-to-Win, keine Lootboxen, keine manipulativen Micropayments. Spieler sollen fuer ehrlichen Gegenwert bezahlen.

---

## 1. Einmalzahlung / Premium-Unlock

### Konzept: "Emoji Puzzle Premium"

Das Spiel ist kostenlos spielbar mit einem vollstaendigen Grundumfang (z.B. 50-80 Level, 1 Theme). Der Premium-Unlock schaltet das volle Erlebnis frei.

### Was enthaelt Premium?

| Feature | Free | Premium |
|---|---|---|
| Level | 50 Basis-Level | 200+ Level + regelmaessige Updates |
| Themes | 1 (Fruit) | Alle 8+ Themes inklusive |
| Gem-Varianten | 6 Common | Alle 24 Varianten (Common bis Legendary) |
| Werbung | Optionale Rewarded Ads | Komplett werbefrei |
| Statistiken | Basis-Score | Detaillierte Stats, Bestenlisten |
| Taeglich. Challenge | Nein | Ja, mit exklusiven Belohnungen |
| Level-Editor | Nein | Einfacher Level-Editor |
| Farbschema | Standard | Dark Mode, OLED Mode, Custom-Farben |

### Preisrecherche vergleichbarer Indie-Puzzle-Spiele

| Spiel | Preis | Plattform | Bemerkung |
|---|---|---|---|
| Hue Ball (Puzzle) | 2,99 EUR | iOS/Android | Einmalkauf, kein IAP |
| Simon Tatham's Puzzles | Kostenlos/FOSS | Alle | Donation-basiert |
| Puzzle Retreat | 3,49 EUR | iOS | Premium, keine Ads |
| Triple Town | Free + 3,99 EUR Unlock | iOS/Android | Hybridmodell |
| Threes! | 5,99 EUR | iOS/Android | Vollpreis, keine IAP |
| Mini Metro | 4,99 EUR | Alle | Premium, DLC separat |
| Monument Valley | 4,99 EUR | iOS/Android | Premium mit DLC |
| Good Sudoku | Free + 4,99 EUR/Jahr | iOS | Abo-Variante |

### Empfohlener Preis

**3,99 EUR bis 4,99 EUR einmalig** fuer den Premium-Unlock.

Begruendung:
- Unter der psychologischen 5-EUR-Schwelle
- Vergleichbar mit einem Kaffee - leicht zu rechtfertigen
- Deckt sich mit dem Marktstandard fuer Indie-Puzzle-Spiele
- Hoeher als 2,99 EUR, da wir deutlich mehr Inhalt bieten als ein minimales Puzzle
- Alternativ: **Einfuehrungspreis 2,99 EUR** in den ersten 2 Wochen nach Launch

### Implementierungshinweis

Flutter unterstuetzt In-App-Purchases ueber das `in_app_purchase`-Paket. Ein einzelner "non-consumable" Purchase genuegt.

---

## 2. Cosmetic-Only DLC: Emoji-Theme-Packs

### Konzept

Rein visuelle Aenderungen ohne Gameplay-Vorteil. Jedes Theme-Pack ersetzt die 6 Basis-Emojis durch ein thematisch zusammenhaengendes Set und kann optional Hintergrund und Partikeleffekte anpassen.

### Theme-Pack-Katalog

#### Kern-Themes (zum Launch)

| # | Theme | Emojis | Hintergrund-Idee |
|---|---|---|---|
| 1 | Fruechte (Default) | Apfel Blaubeere Zitrone Orange Traube Erdbeere | Gruener Garten |
| 2 | Tiere | Katze Hund Hase Fuchs Panda Koala | Wald-Wiese |
| 3 | Weltraum | Rakete Mond Stern Komet Planet Sternschnuppe | Dunkler Sternenhimmel |
| 4 | Essen | Pizza Burger Donut Eis Kuchen Pommes | Kuechen-Tisch |
| 5 | Natur | Blume Baum Pilz Blatt Kaktus Sonnenblume | Fruehlingswiese |
| 6 | Ozean | Wal Delfin Krake Fisch Seestern Muschel | Unterwasserwelt |
| 7 | Wetter | Sonne Wolke Regen Blitz Regenbogen Schneeflocke | Himmelsgradient |
| 8 | Musik | Gitarre Klavier Trompete Trommel Mikro Kopfhoerer | Buehne/Konzert |

#### Saisonale Themes (zeitlich begrenzt erhaeltlich, kehren jaehrlich wieder)

| Saison | Theme | Emojis | Verfuegbarkeit |
|---|---|---|---|
| Fruehling | Ostern | Osterhase, Osterei, Kueken, Karotte, Blume, Glocke | Maerz-April |
| Sommer | Strand | Palme, Surfbrett, Wassermelone, Sonnenbrille, Eis, Flip-Flops | Juni-August |
| Herbst | Halloween | Kuerbis, Geist, Fledermaus, Spinne, Suessigkeit, Hexenhut | Oktober |
| Winter | Weihnachten | Weihnachtsbaum, Geschenk, Schneemann, Rentier, Glocke, Stern | Dezember-Januar |
| Bonus | Valentinstag | Herz, Rose, Schokolade, Brief, Ring, Amor | Februar |

### Preismodell fuer Theme-Packs

| Variante | Preis | Inhalt |
|---|---|---|
| Einzelnes Theme | 0,99 EUR | 1 Theme-Pack |
| 3er-Bundle | 1,99 EUR (spart 33%) | 3 Themes nach Wahl |
| Alle-Themes-Bundle | 3,99 EUR (spart 50%+) | Alle aktuellen + zukuenftige Themes |
| Saisonales Theme | 0,99 EUR oder kostenlos durch Spielen | 1 saisonales Theme |

### Besonderheit: Themes durch Spielen freischalten

Jedes Theme kann auch durch In-Game-Coins freigeschaltet werden (bereits im Code angelegt: `shopThemes` mit Coin-Preisen). So haben Spieler immer die Wahl:
- **Bezahlen mit Echtgeld** fuer sofortigen Zugang
- **Erspielen mit Coins** fuer geduldige Spieler

Das bestehende System zeigt bereits Animals (500 Coins) und Space (1000 Coins). Empfehlung: Coin-Preise so balancieren, dass ein Theme nach ca. 3-5 Stunden Spielzeit erspielbar ist.

### Vergleich mit dem Markt

- **Alto's Odyssey:** Kostenlos mit optionalem 4,99 EUR Werbe-Entfernungs-IAP
- **Crossy Road:** Kostenlos, rein kosmetische Figuren fuer 0,99-1,99 EUR
- **Monument Valley 2:** Basis 4,99 EUR, DLC fuer 1,99 EUR
- **Stardew Valley Mobile:** Einmalkauf, kostenlose Content-Updates

Unser Modell ist vergleichbar mit Crossy Road: rein kosmetisch, fair bepreist, auch erspielbar.

---

## 3. Supporter / Donation-Modell

### Konzept: "Unterstuetze den Entwickler"

Ein transparentes Spenden-System, das Spielern erlaubt, freiwillig mehr zu zahlen. Kein Druck, kein Nag-Screen - nur eine nette Option im Menue.

### Wie funktioniert das bei erfolgreichen Indie-Games?

| Spiel/Projekt | Modell | Ergebnis |
|---|---|---|
| **Dwarf Fortress** | 20+ Jahre kostenlos, Donations | Konstantes Einkommen, Steam-Release als Premium brachte Millionen |
| **Celeste** | Vollpreis + "Tip the Dev" in-app | Erfolgreich, Community schaetzt Transparenz |
| **itch.io Spiele** | "Pay what you want" mit Mindestpreis 0 | Durchschnittlich zahlen Spieler 3-5x den Mindestpreis |
| **Mindustry** | Kostenlos auf itch.io, 5,99 auf Steam | Beide Versionen erfolgreich |
| **Lichess** | 100% kostenlos, nur Spenden | 2,5M+ aktive Nutzer, voll spendenfinanziert |

### Empfohlene Supporter-Tiers

| Tier | Preis | Was man bekommt |
|---|---|---|
| Kaffee-Spende | 1,99 EUR | Danke-Nachricht im Spiel, kleines Herz-Badge neben dem Namen |
| Supporter | 4,99 EUR | Exklusives "Supporter"-Badge, Gold-Rahmen um Profilbild, Credits-Erwaehnung |
| Super-Supporter | 9,99 EUR | Alles von Supporter + 1 exklusives Theme ("Regenbogen-Kristalle"), Zugang zu Beta-Versionen |
| Patron | 19,99 EUR | Alles vorherige + Name in den Credits des Spiels, Einfluss auf zukuenftige Themes (Abstimmung) |

### Wichtige Design-Prinzipien

1. **Niemals nerven:** Maximal ein dezenter Hinweis nach Level 20 und dann nie wieder, es sei denn der Spieler sucht die Option aktiv
2. **Transparenz:** Klar kommunizieren wofuer das Geld verwendet wird ("Hilft mir, das Spiel weiterzuentwickeln und werbefrei zu halten")
3. **Supporter-Vorteile sind rein kosmetisch:** Kein Gameplay-Vorteil
4. **Alle Tiers sind einmalige Zahlungen:** Kein Abo, kein wiederkehrender Druck

### Implementierung

- Ein "Unterstuetzen"-Button im Einstellungs-Menue (nicht im Hauptmenue, um Druck zu vermeiden)
- Ueber Flutter `in_app_purchase` als "non-consumable" IAP
- Alternativ: Link zu einer Ko-fi/Buy-Me-A-Coffee-Seite fuer Plattformen, die keinen IAP erlauben

---

## 4. Ad-Supported Free Version

### Konzept: Faire Werbung, die respektiert

Werbung ist die Haupteinnahmequelle fuer kostenlose Spiele, aber sie muss fair implementiert sein.

### Was ist FAIR?

| Praxis | Fair? | Begruendung |
|---|---|---|
| Banner im Hauptmenue | Ja | Stoert nicht beim Spielen |
| Banner waehrend des Spiels | Nein | Stoert Konzentration und Aesthetik |
| Interstitial nach jedem Level | Nein | Zu aggressiv, fuehrt zu Deinstallation |
| Interstitial alle 5-10 Level | Grenzwertig | Akzeptabel wenn kurz und ueberspringbar |
| Rewarded Ad fuer Bonus-Leben | Ja | Spieler entscheidet selbst |
| Rewarded Ad fuer Bonus-Zuege | Ja | Opt-in, fairer Tausch |
| Rewarded Ad fuer Coins | Ja | Beschleunigt Theme-Freischaltung |
| Pre-Roll beim App-Start | Nein | Schlechter erster Eindruck |

### Empfohlenes Werbekonzept

#### 1. Nur Rewarded Ads (bevorzugt)

- **Nach einem verlorenen Level:** "Moechtest du 3 Extra-Zuege? Schau ein kurzes Video." (max. 30 Sekunden)
- **Im Shop:** "Verdiene 50 Coins - schau ein Video" (maximal 5x pro Tag)
- **Taegl. Bonus:** "Verdopple deinen taeglichen Login-Bonus mit einem Video"

Vorteile:
- Spieler hat volle Kontrolle
- Hoehe CPM (Cost per Mille): Rewarded Ads bringen 10-40 EUR CPM vs. 1-3 EUR fuer Banner
- Bessere Spielerbewertungen
- Keine Stoerung des Spielflusses

#### 2. Minimale Banner (Alternative)

- Nur auf dem Hauptmenue-Screen und dem Level-Auswahl-Screen
- Niemals waehrend des Gameplays
- Kleines Banner am unteren Rand (320x50 Standard)
- Verschwindet bei Premium/Supporter-Kauf

#### 3. Werbefreiheit als Premium-Feature

| Option | Preis |
|---|---|
| "Werbung entfernen" als eigenstaendiger IAP | 1,99 EUR |
| Enthalten im Premium-Unlock | 3,99 EUR (s. Punkt 1) |
| Enthalten in jedem Supporter-Tier | ab 1,99 EUR |

### Technische Umsetzung

- Flutter-Paket: `google_mobile_ads` fuer AdMob-Integration
- Mediation empfohlen (AdMob Mediation) fuer bessere Fuellraten
- DSGVO/GDPR: Consent-Dialog vor erster Werbeeinblendung (z.B. ueber `consent_manager`)
- Kinderschutz: Falls das Spiel fuer Kinder vermarktet wird, gelten strengere Regeln (COPPA) - dann sind nur kontextuelle, nicht-personalisierte Anzeigen erlaubt

### Vergleichswerte (Umsatzschaetzung)

Annahmen: 10.000 DAU (Daily Active Users), 30% schauen Rewarded Ads

| Metrik | Wert |
|---|---|
| DAU mit Ads | 3.000 |
| Avg. Ads pro User pro Tag | 2,5 |
| Impressions pro Tag | 7.500 |
| CPM (Rewarded Video) | 15 EUR |
| Tagesumsatz Werbung | ~112 EUR |
| Monatsumsatz Werbung | ~3.375 EUR |

---

## 5. Empfohlenes Gesamtmodell: Hybrid-Ansatz

### Die beste Strategie kombiniert mehrere Modelle:

```
FREE TIER (Basisspiel)
  |
  |-- Rewarded Ads (opt-in, fair)
  |-- 50 Level spielbar
  |-- 1 Theme (Fruechte)
  |-- Coins durch Spielen verdienen
  |-- Themes einzeln mit Coins freispielbar
  |
  +-- PREMIUM UNLOCK (3,99 EUR einmalig)
  |     |-- Alle Level (200+)
  |     |-- Werbefrei
  |     |-- Taegliche Challenges
  |     |-- Level-Editor (Light)
  |     |-- Alle Gem-Varianten sichtbar
  |
  +-- THEME PACKS (0,99 EUR einzeln)
  |     |-- Rein kosmetisch
  |     |-- Auch mit Coins erspielbar
  |     |-- Saisonale Specials
  |
  +-- SUPPORTER TIERS (1,99 - 19,99 EUR)
        |-- Freiwillig
        |-- Kosmetische Belohnungen
        |-- Name in den Credits
```

### Warum dieser Mix funktioniert

1. **Keine Barriere:** Jeder kann sofort kostenlos spielen
2. **Kein Druck:** Werbung ist opt-in, Premium ist optional
3. **Fairer Wert:** Fuer 3,99 EUR bekommt man ein vollstaendiges Spiel
4. **Kein Pay-to-Win:** Nichts Kaufbares gibt einen Gameplay-Vorteil
5. **Mehrere Einnahmequellen:** Nicht abhaengig von einem einzigen Modell
6. **Ethisch vertretbar:** Keine Dark Patterns, keine FOMO-Mechaniken, keine kuenstliche Verknappung

### Geschaetzter Umsatz-Mix (bei Erfolg)

| Quelle | Anteil am Umsatz |
|---|---|
| Premium-Unlock | 40-50% |
| Rewarded Ads | 25-35% |
| Theme-Packs | 10-15% |
| Supporter-Donations | 5-10% |

---

## 6. Was wir NICHT tun (und warum)

| Anti-Pattern | Warum nicht |
|---|---|
| Energie-System / Leben-Timer | Kuenstliche Wartezeit = Frustration = Manipulation |
| Lootboxen / Gacha | Gluecksspiel-Mechanik, in vielen Laendern reguliert |
| Pay-to-Win Power-Ups | Zerstoert Fairness und Spielspass |
| Aggressive Interstitials | Vertreibt Spieler, fuehrt zu 1-Stern-Bewertungen |
| FOMO-basierte Angebote ("Nur noch 2 Stunden!") | Manipulativ, erzeugt kuenstlichen Druck |
| Abonnement-Modell | Fuer ein Puzzle-Spiel unangemessen, Spieler hassen wiederkehrende Kosten fuer Casual Games |
| Consumable IAPs (kaufbare Coins) | Oeffnet die Tuer zu Pay-to-Win und Wal-Abhaengigkeit |

---

## 7. Naechste Schritte

1. **Entscheidung:** Welche Kombination der Modelle implementieren wir zum Launch?
2. **Technisch:** `in_app_purchase`-Paket integrieren und IAP-Produkte definieren
3. **Content:** Mindestens 3-4 Theme-Packs zum Launch fertigstellen (sind teilweise im Code schon angelegt)
4. **Balancing:** Coin-Economy so gestalten, dass Themes in 3-5h erspielbar sind
5. **Legal:** DSGVO-Consent fuer Ads, AGBs fuer IAPs, App-Store-Richtlinien pruefen
6. **A/B-Test:** Premium-Preis 2,99 vs. 3,99 vs. 4,99 testen (sofern genuegend Nutzer)

---

*Erstellt von Sales Agent 1 - Ethische Monetarisierung*
*Alle Preise sind Empfehlungen und sollten vor Launch mit A/B-Tests validiert werden.*
