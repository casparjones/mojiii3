# Sales Agent 3: Revenue-Projektionen & Monetarisierungsplan

## Match3 Emoji Puzzle Game (Flutter, Cross-Platform)

**Erstellt:** 2026-03-27
**Basis:** Indie-Game-Benchmarks 2024-2026, Sensor Tower, data.ai, GameAnalytics Reports

---

## 1. Revenue-Modell-Vergleich

### 1.1 Uebersicht der Modelle

| Modell | Einstiegshuerde | Typischer ARPU (Lifetime) | Conversion Rate | Skalierbarkeit | Komplexitaet |
|--------|----------------|---------------------------|-----------------|----------------|--------------|
| Kostenlos + Spenden | Keine | 0,01 - 0,05 EUR | 0,1 - 0,5% | Sehr gering | Minimal |
| Freemium + Cosmetic DLC | Keine | 0,15 - 0,60 EUR | 2 - 5% | Mittel | Mittel |
| Einmalzahlung (2-5 EUR) | Hoch | 2,00 - 5,00 EUR (bei Kauf) | n/a (nur Kaeufer) | Gering | Minimal |
| Free + Rewarded Ads | Keine | 0,05 - 0,20 EUR | 15 - 30% sehen Ads | Mittel | Gering |
| Hybrid (Free + Ads + IAP) | Keine | 0,20 - 0,80 EUR | Kombiniert | Hoch | Hoch |

### 1.2 Detailanalyse pro Modell

#### A) Komplett kostenlos + Spenden

| Kennzahl | Wert |
|----------|------|
| Spendenquote | 0,1 - 0,5% der Nutzer |
| Durchschnittliche Spende | 2 - 5 EUR |
| ARPU | 0,01 - 0,025 EUR |
| Vorteil | Maximale Downloads, gute Reviews |
| Nachteil | Kaum Einnahmen, nicht nachhaltig |

**Bewertung:** Nur geeignet als Portfolio-Projekt oder fuer Open-Source-Reputation. Fuer nachhaltige Monetarisierung ungeeignet.

#### B) Freemium mit Cosmetic DLC

Typische Cosmetic-Items fuer ein Match3-Emoji-Game:

| Item-Kategorie | Preis | Erwartete Conversion |
|----------------|-------|---------------------|
| Emoji-Theme-Packs (z.B. Halloween, Fruechte, Tiere) | 0,99 - 1,99 EUR | 2 - 4% |
| Hintergrund-Themes | 0,99 EUR | 1 - 2% |
| Board-Styles / Animationen | 1,99 - 2,99 EUR | 0,5 - 1,5% |
| "Supporter Pack" Bundle | 4,99 EUR | 0,5 - 1% |
| Premium-Emoji-Set (exklusiv) | 2,99 EUR | 1 - 2% |

| Kennzahl | Wert |
|----------|------|
| Zahlende Nutzer | 2 - 5% |
| Durchschnittlicher IAP | 1,50 - 3,00 EUR |
| ARPU (alle Nutzer) | 0,15 - 0,60 EUR |
| Vorteil | Fair, gute Reviews, kein Pay-to-Win |
| Nachteil | Benoetigt Content-Pipeline |

#### C) Einmalzahlung (2-5 EUR)

| Kennzahl | Wert |
|----------|------|
| Typischer Preis Indie-Puzzle | 1,99 - 3,99 EUR |
| Download-Reduktion vs. Free | 90 - 95% weniger Downloads |
| ARPU (bei Kaeufern) | 1,39 - 2,79 EUR (nach Store-Cut 30%) |
| Vorteil | Einfach, kein Tracking, kein Backend |
| Nachteil | Massiv weniger Nutzer, kein wiederkehrender Umsatz |

**Hinweis:** Bei bezahlten Puzzle-Games auf Mobile erwarten Nutzer hohe Qualitaet und viel Content. Die Konkurrenz mit kostenlosen Match3-Games (Candy Crush etc.) ist brutal.

#### D) Free + Optionale Rewarded Ads

| Kennzahl | Wert |
|----------|------|
| Ad-Engagement-Rate | 15 - 30% der Nutzer sehen freiwillig Ads |
| eCPM Rewarded Video (DE/DACH) | 8 - 15 EUR |
| eCPM Rewarded Video (Global) | 3 - 8 EUR |
| Ads pro Nutzer pro Tag | 2 - 5 Views |
| ARPU (monatlich) | 0,05 - 0,20 EUR |
| Vorteil | Nutzerfreundlich, einfach zu implementieren |
| Nachteil | Benoetigt Ad-SDK (AdMob etc.), Datenschutz-Aufwand |

Typische Rewarded-Ad-Anlaesse im Match3:
- Extra-Zuege nach Game Over
- Hinweis auf moeglichen Zug
- Taeglicher Bonus-Booster
- Doppelte Punkte fuer ein Spiel

#### E) Hybrid-Modell (Free + Ads + IAP)

| Kennzahl | Wert |
|----------|------|
| ARPU kombiniert | 0,20 - 0,80 EUR |
| Ad-Anteil am Revenue | 40 - 60% |
| IAP-Anteil am Revenue | 40 - 60% |
| Vorteil | Maximiert Revenue, diversifiziert Einnahmen |
| Nachteil | Komplexeste Implementierung, Balance schwierig |

**Wichtig:** "Remove Ads"-IAP fuer 2,99 - 4,99 EUR ist ein bewaehrtes Hybrid-Element. Conversion dafuer liegt bei 1 - 3%.

---

## 2. Umsatzprognosen

### 2.1 Annahmen

| Parameter | Wert |
|-----------|------|
| Plattformen | Android + iOS + Web |
| Retention D1 | 35% (Indie-Benchmark) |
| Retention D7 | 15% |
| Retention D30 | 5% |
| Durchschnittliche Sessions/Tag | 2,5 |
| Durchschnittliche Nutzungsdauer | 8 Min/Session |
| Store-Gebuehr | 30% (Apple/Google) |

### 2.2 Szenario: Konservativ (1.000 Downloads/Monat)

Typisch fuer: Organisches Wachstum ohne Marketing, keine Store-Features.

#### Monatliche Active Users (MAU) nach 6 Monaten: ca. 800

| Modell | Monatl. Brutto-Umsatz | Nach Store-Cut (netto) | Jaehrlich (netto) |
|--------|----------------------|----------------------|-------------------|
| Spenden | 1 - 5 EUR | 0,70 - 3,50 EUR | 8 - 42 EUR |
| Cosmetic IAP | 15 - 50 EUR | 10 - 35 EUR | 120 - 420 EUR |
| Einmalzahlung 2,99 EUR | 150 - 300 EUR* | 105 - 210 EUR | 1.260 - 2.520 EUR |
| Rewarded Ads | 5 - 20 EUR | 5 - 20 EUR** | 60 - 240 EUR |
| Hybrid (Ads + IAP) | 20 - 60 EUR | 15 - 45 EUR | 180 - 540 EUR |

*Bei Einmalzahlung nur ca. 50-100 Downloads/Monat statt 1.000
**Ads werden nicht ueber Store abgerechnet

**Fazit Konservativ:** Kein Modell deckt nennenswerte Kosten. Einmalzahlung hat absolut den hoechsten Netto-Ertrag, aber die wenigsten Nutzer.

### 2.3 Szenario: Realistisch (10.000 Downloads/Monat)

Typisch fuer: Gutes ASO, einige positive Reviews, kleine Marketing-Massnahmen.

#### MAU nach 6 Monaten: ca. 6.000 - 8.000

| Modell | Monatl. Brutto-Umsatz | Nach Store-Cut (netto) | Jaehrlich (netto) |
|--------|----------------------|----------------------|-------------------|
| Spenden | 10 - 50 EUR | 7 - 35 EUR | 84 - 420 EUR |
| Cosmetic IAP | 150 - 500 EUR | 105 - 350 EUR | 1.260 - 4.200 EUR |
| Einmalzahlung 2,99 EUR | 750 - 1.500 EUR* | 525 - 1.050 EUR | 6.300 - 12.600 EUR |
| Rewarded Ads | 80 - 250 EUR | 80 - 250 EUR | 960 - 3.000 EUR |
| Hybrid (Ads + IAP) | 250 - 700 EUR | 200 - 550 EUR | 2.400 - 6.600 EUR |

*Bei Einmalzahlung nur ca. 500-1.000 Downloads/Monat

### 2.4 Szenario: Optimistisch (100.000 Downloads/Monat)

Typisch fuer: Store-Feature, viraler Moment, erfolgreiche Paid-UA-Kampagne.

#### MAU nach 6 Monaten: ca. 50.000 - 80.000

| Modell | Monatl. Brutto-Umsatz | Nach Store-Cut (netto) | Jaehrlich (netto) |
|--------|----------------------|----------------------|-------------------|
| Spenden | 100 - 500 EUR | 70 - 350 EUR | 840 - 4.200 EUR |
| Cosmetic IAP | 2.000 - 8.000 EUR | 1.400 - 5.600 EUR | 16.800 - 67.200 EUR |
| Einmalzahlung 2,99 EUR | 7.500 - 15.000 EUR* | 5.250 - 10.500 EUR | 63.000 - 126.000 EUR |
| Rewarded Ads | 1.000 - 4.000 EUR | 1.000 - 4.000 EUR | 12.000 - 48.000 EUR |
| Hybrid (Ads + IAP) | 3.000 - 10.000 EUR | 2.400 - 8.000 EUR | 28.800 - 96.000 EUR |

*Bei Einmalzahlung nur ca. 5.000-10.000 Downloads/Monat

### 2.5 Zusammenfassung: Jaehrlicher Netto-Umsatz

| Modell | Konservativ | Realistisch | Optimistisch |
|--------|-------------|-------------|--------------|
| Spenden | 8 - 42 EUR | 84 - 420 EUR | 840 - 4.200 EUR |
| Cosmetic IAP | 120 - 420 EUR | 1.260 - 4.200 EUR | 16.800 - 67.200 EUR |
| Einmalzahlung | 1.260 - 2.520 EUR | 6.300 - 12.600 EUR | 63.000 - 126.000 EUR |
| Rewarded Ads | 60 - 240 EUR | 960 - 3.000 EUR | 12.000 - 48.000 EUR |
| **Hybrid** | **180 - 540 EUR** | **2.400 - 6.600 EUR** | **28.800 - 96.000 EUR** |

---

## 3. Kostenanalyse

### 3.1 Einmalige Kosten (Setup)

| Posten | Kosten | Anmerkung |
|--------|--------|-----------|
| Apple Developer Account | 99 EUR/Jahr | Pflicht fuer iOS |
| Google Play Developer | 25 EUR (einmalig) | Pflicht fuer Android |
| Domain fuer Website/Datenschutz | 10 - 15 EUR/Jahr | z.B. fuer Impressum |
| App-Icons / Store-Assets | 0 - 200 EUR | Selbst oder Fiverr |
| Entwicklungszeit (Opportunitaet) | 2.000 - 5.000 EUR | 200-500h bei Hobby-Projekt |
| **Gesamt Setup** | **ca. 135 - 340 EUR** | ohne Opportunitaetskosten |

### 3.2 Laufende Kosten (monatlich)

| Posten | Kosten/Monat | Anmerkung |
|--------|-------------|-----------|
| Apple Developer Account | 8,25 EUR | 99 EUR/12 |
| Server/Backend | 0 EUR | Kein Server noetig bei reinem Offline-Game |
| Firebase (falls Analytics) | 0 EUR | Free Tier reicht fuer < 100k MAU |
| AdMob-Integration | 0 EUR | Kostenlos, Einnahmen stattdessen |
| Content-Erstellung (Themes) | 0 - 50 EUR | Eigenleistung oder Assets |
| **Gesamt laufend** | **ca. 8 - 60 EUR/Monat** | |

### 3.3 Optionale Marketing-Kosten

| Kanal | Kosten | Erwarteter CPI (Cost per Install) |
|-------|--------|----------------------------------|
| Organisch (ASO) | 0 EUR | 0 EUR |
| Social Media (organisch) | 0 EUR (Zeitaufwand) | 0 EUR |
| Reddit/Discord Community | 0 EUR (Zeitaufwand) | 0 EUR |
| Google Ads (UAC) | 100 - 500 EUR/Monat | 0,30 - 1,50 EUR (Casual Games DE) |
| Apple Search Ads | 100 - 500 EUR/Monat | 0,80 - 2,00 EUR |
| TikTok/Instagram Ads | 200 - 1.000 EUR/Monat | 0,20 - 0,80 EUR |
| Influencer (Mikro) | 50 - 200 EUR pro Post | Stark variabel |

### 3.4 Break-Even-Analyse

| Szenario | Fixkosten Jahr 1 | Benoetigter Umsatz/Monat | Erreichbar mit Hybrid-Modell? |
|----------|-------------------|--------------------------|------------------------------|
| Minimal (kein Marketing) | ca. 230 EUR | 19 EUR | Ja, ab ca. 2.000 Downloads/Monat |
| Mit kleinem Marketing | ca. 3.800 EUR | 317 EUR | Ja, ab ca. 15.000 Downloads/Monat |
| Vollkosten (inkl. Arbeitszeit) | ca. 15.000 EUR | 1.250 EUR | Nur im optimistischen Szenario |

---

## 4. Empfohlene Monetarisierungsstrategie

### Phase 1: Launch (Monat 1-3)

**Modell: Kostenlos + Rewarded Ads**

| Element | Details |
|---------|---------|
| Preis | Kostenlos |
| Monetarisierung | Nur optionale Rewarded Video Ads |
| Ad-Anlaesse | Extra-Zuege, Hint, taeglicher Bonus |
| Ziel | Maximale Downloads, Bewertungen sammeln, Retention messen |
| Erwarteter ARPU | 0,05 - 0,10 EUR |
| Tech-Aufwand | Gering (google_mobile_ads Flutter-Package) |

**Begruendung:** In Phase 1 geht es um Traktion und Daten. Rewarded Ads sind schnell implementiert, stoeren nicht und liefern erste Einnahmen. Keine IAP-Komplexitaet noetig.

**Konkrete Massnahmen:**
- AdMob-Konto einrichten
- 3-4 Rewarded-Ad-Placements einbauen
- Firebase Analytics fuer Retention-Tracking
- ASO optimieren (Keywords, Screenshots, Beschreibung)
- Bewertungs-Prompt nach Level 10 einbauen

### Phase 2: Growth (Monat 4-9)

**Modell: Hybrid (Rewarded Ads + Cosmetic IAP + Remove-Ads-IAP)**

| Element | Details |
|---------|---------|
| Preis | Weiterhin kostenlos |
| Neue Monetarisierung | Cosmetic IAP-Shop + "Remove Ads" Option |
| IAP-Items | 3-5 Emoji-Theme-Packs (je 0,99-1,99 EUR) |
| Remove Ads | 3,99 EUR (einmalig) |
| Ziel | Zahlende Nutzer konvertieren, ARPU steigern |
| Erwarteter ARPU | 0,15 - 0,40 EUR |
| Tech-Aufwand | Mittel (in_app_purchase Flutter-Package) |

**Begruendung:** Mit genuegend Nutzerdaten kann man IAP gezielt optimieren. Cosmetic Items sind fair und erzeugen keine negativen Reviews. "Remove Ads" ist der einfachste IAP mit hoechster Akzeptanz.

**Konkrete Massnahmen:**
- In-App-Purchase-System implementieren
- 3-5 Emoji-Theme-Packs erstellen
- "Ad-Free" Premium-Option einbauen
- A/B-Testing fuer Preispunkte
- Saisonale Themes (Weihnachten, Ostern, Halloween)
- Push-Notifications fuer neue Themes (optional)

### Phase 3: Mature (Monat 10+)

**Modell: Vollstaendiges Hybrid mit Abo-Option**

| Element | Details |
|---------|---------|
| Preis | Weiterhin kostenlos |
| Neue Monetarisierung | Optionales "VIP"-Abo |
| Abo-Preis | 1,99 EUR/Monat oder 9,99 EUR/Jahr |
| Abo-Inhalt | Alle Themes, keine Ads, exklusive Levels, Statistiken |
| Ziel | Recurring Revenue, Whale-Monetarisierung |
| Erwarteter ARPU | 0,30 - 0,80 EUR |
| Tech-Aufwand | Hoch (RevenueCat oder eigenes Abo-System) |

**Begruendung:** Abos liefern planbaren, wiederkehrenden Umsatz. Apple/Google bevorzugen Abo-Apps im Ranking. Ab Monat 10 sollte genuegend Content vorhanden sein, um ein Abo zu rechtfertigen.

**Konkrete Massnahmen:**
- RevenueCat-Integration (vereinfacht Abo-Management)
- VIP-Bereich mit exklusiven Features
- Regelmaessige Content-Updates (mindestens monatlich)
- Community-Features (Leaderboards)
- Kleine UA-Kampagnen starten, wenn Unit Economics stimmen

### Phasen-Uebersicht: Revenue-Entwicklung (Realistisches Szenario)

```
Monat  | Downloads | MAU   | Modell        | Netto-Umsatz/Monat
-------|-----------|-------|---------------|-------------------
1      | 2.000     | 700   | Ads only      | 5 - 15 EUR
2      | 3.000     | 1.200 | Ads only      | 10 - 25 EUR
3      | 5.000     | 2.000 | Ads only      | 15 - 40 EUR
4      | 7.000     | 3.500 | Ads + IAP     | 50 - 150 EUR
5      | 8.000     | 4.500 | Ads + IAP     | 80 - 200 EUR
6      | 10.000    | 6.000 | Ads + IAP     | 120 - 350 EUR
9      | 12.000    | 8.000 | Ads + IAP     | 200 - 550 EUR
12     | 15.000    | 10.000| Hybrid + Abo  | 400 - 1.000 EUR
18     | 15.000    | 12.000| Hybrid + Abo  | 600 - 1.500 EUR
24     | 15.000    | 15.000| Hybrid + Abo  | 800 - 2.000 EUR
```

**Kumulierter Netto-Umsatz nach 24 Monaten (realistisch):** ca. 4.000 - 12.000 EUR

---

## 5. Wichtige KPIs zum Tracken

| KPI | Zielwert | Tool |
|-----|----------|------|
| D1 Retention | > 35% | Firebase Analytics |
| D7 Retention | > 15% | Firebase Analytics |
| D30 Retention | > 5% | Firebase Analytics |
| IAP Conversion Rate | > 2% | Store Console |
| ARPU (monatlich) | > 0,20 EUR | Eigene Berechnung |
| ARPPU (zahlende Nutzer) | > 3,00 EUR | Store Console |
| Ad eCPM | > 8 EUR (DACH) | AdMob Dashboard |
| Session-Laenge | > 6 Min | Firebase Analytics |
| Sessions/Tag | > 2 | Firebase Analytics |
| Store-Bewertung | > 4,2 Sterne | Store Console |
| CPI (bei Paid UA) | < 0,50 EUR | Ad Network Dashboard |

---

## 6. Risiken und Mitigationen

| Risiko | Wahrscheinlichkeit | Impact | Mitigation |
|--------|-------------------|--------|------------|
| Zu wenige Downloads | Hoch | Hoch | ASO-Fokus, Cross-Promotion, Reddit/TikTok |
| Niedrige Retention | Mittel | Hoch | Mehr Level, taegliche Challenges, Progression |
| Ad-Revenue unter Erwartung | Mittel | Mittel | Mehr Ad-Placements, Mediation (mehrere Netzwerke) |
| Negative Reviews wegen Ads | Gering | Mittel | Nur Rewarded (optionale) Ads, nie Interstitials |
| App-Store-Ablehnung | Gering | Hoch | Guidelines frueh pruefen, keine Emoji-Trademark-Verletzung |
| Datenschutz-Probleme (DSGVO) | Mittel | Hoch | Consent-Dialog, kein Tracking ohne Zustimmung |

---

## 7. Fazit und Top-Empfehlung

### Empfohlenes Modell: Gestufter Hybrid-Ansatz

1. **Start mit Rewarded Ads only** -- minimaler Aufwand, maximale Downloads
2. **Nach 3 Monaten Cosmetic IAP + Remove Ads** -- Revenue-Boost ohne Pay-to-Win
3. **Nach 9 Monaten optionales Abo** -- wiederkehrender Umsatz fuer Nachhaltigkeit

### Realistische Erwartung fuer ein Solo-Indie-Projekt

| Zeitraum | Erwarteter Netto-Umsatz | Bewertung |
|----------|------------------------|-----------|
| Jahr 1 | 500 - 3.000 EUR | Deckt laufende Kosten, nicht Arbeitszeit |
| Jahr 2 | 2.000 - 8.000 EUR | Kleines Nebeneinkommen moeglich |
| Jahr 3+ | 3.000 - 15.000 EUR/Jahr | Nachhaltig bei stabiler Nutzerbasis |

**Ehrliche Einschaetzung:** Ein Solo-Indie-Match3-Game wird mit hoher Wahrscheinlichkeit kein Vollzeit-Einkommen generieren. Der Markt ist extrem kompetitiv (Candy Crush, Royal Match etc. mit Millionen-Budgets). Der realistische Outcome ist ein lohnendes Nebenprojekt mit 200-1.000 EUR/Monat nach 12-18 Monaten -- vorausgesetzt, das Spiel hat eine solide Retention und wird aktiv gepflegt.

**Der groesste Hebel ist nicht das Monetarisierungsmodell, sondern die Retention.** Ein Spiel mit 40% D1-Retention und nur Rewarded Ads verdient mehr als eines mit 20% D1-Retention und perfektem IAP-System.
