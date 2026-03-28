# Recherche: 2D Game Engine Framework fuer Match3

## Ausgangslage

Das Projekt ist ein Flutter-basiertes Match3-Spiel (Emoji Match 3), das bereits funktionsfaehig ist.
Ziel dieser Recherche ist die Evaluation, ob und welches 2D Game Engine Framework
die Weiterentwicklung (Animationen, Partikel, Sprite-Management) verbessern kann.

---

## Engine-Vergleich

### 1. Flame Engine (Flutter)

| Kriterium | Bewertung |
|---|---|
| Integration | Nahtlos -- laeuft direkt in Flutter, kein Rewrite noetig |
| Sprache | Dart (bereits im Projekt verwendet) |
| Lernkurve | Gering fuer Flutter-Entwickler |
| Features | Sprite-System, Animationen, Partikel, Collision Detection, ECS |
| Community | Aktive Flutter-Community, gute Dokumentation |
| Match3-Referenz | "Runes Match 3" -- vollstaendiges Match3-Spiel mit Flame |
| APK-Groesse | Moderater Overhead, da Flutter-Basis bleibt |
| Migration | Schrittweise moeglich (Flame-Widgets in bestehende Flutter-App einbetten) |

**Vorteile:**
- Kein Plattformwechsel -- Dart und Flutter bleiben die Basis
- FlameGame-Widget laesst sich direkt in den Widget-Tree einbetten
- Schrittweise Migration statt Big-Bang-Rewrite
- Flame bietet SpriteComponent, SpriteAnimationComponent, ParticleSystemComponent
- Gut geeignet fuer 2D-Spiele mit Raster-Logik (Match3, Puzzle)

**Nachteile:**
- Performance bei sehr komplexen Szenen nicht auf dem Niveau nativer Game Engines
- Weniger Tooling (kein visueller Level-Editor)

---

### 2. Godot 4

| Kriterium | Bewertung |
|---|---|
| Integration | Keine -- kompletter Rewrite erforderlich |
| Sprache | GDScript, C#, C++ |
| Lernkurve | Mittel (neue Sprache, neues Tooling) |
| Features | Vollstaendige Game Engine mit Editor, Physik, Audio, UI |
| Community | Grosse Open-Source-Community |
| Match3-Referenz | Diverse Tutorials und Open-Source-Projekte |
| APK-Groesse | Ca. 30-40 MB Basis |
| Migration | Kompletter Neubau |

**Vorteile:**
- Bestes Gesamtpaket als eigenstaendige Game Engine
- Visueller Editor fuer Level-Design und Szenen
- Integriertes Audio, Physik, Partikel
- Open Source (MIT-Lizenz)

**Nachteile:**
- Kompletter Rewrite des bestehenden Flutter-Projekts noetig
- Gesamte UI muss neu gebaut werden (Flutter-UI faellt weg)
- Andere Programmiersprache (GDScript oder C#)
- Overkill fuer ein reines Match3-Spiel

---

### 3. Defold

| Kriterium | Bewertung |
|---|---|
| Integration | Keine -- kompletter Rewrite erforderlich |
| Sprache | Lua |
| Lernkurve | Mittel |
| Features | 2D-fokussiert, sehr performant, kleiner Footprint |
| Community | Klein aber spezialisiert |
| Match3-Referenz | Von King gebaut (Candy Crush Saga) -- Match3 ist Kernkompetenz |
| APK-Groesse | Sehr klein (ca. 2-3 MB Basis) -- Branchenbester |
| Migration | Kompletter Neubau |

**Vorteile:**
- Wurde von King (Candy Crush) entwickelt -- Match3 ist im Kern der Engine
- Kleinste APK-Groesse aller Optionen
- Hervorragende 2D-Performance
- Kostenlos ohne Einschraenkungen

**Nachteile:**
- Lua als Sprache -- kein Dart, kein Typsystem
- Kompletter Rewrite noetig
- Kleine westliche Community, weniger deutschsprachige Ressourcen
- Gesamte Flutter-UI und -Logik muesste portiert werden

---

### 4. Phaser.js

| Kriterium | Bewertung |
|---|---|
| Integration | Keine |
| Sprache | JavaScript/TypeScript |
| Plattform | Web-only (Browser) |

**Bewertung:** Nicht geeignet. Phaser ist ein reines Web-Framework und produziert keine native Android/iOS-App.
Fuer ein Projekt, das als APK ausgeliefert wird, ist dies keine Option.

---

### 5. Cocos Creator

| Kriterium | Bewertung |
|---|---|
| Integration | Keine -- kompletter Rewrite erforderlich |
| Sprache | TypeScript |
| Community | Stark in Asien, sehr kleine westliche Community |

**Bewertung:** Funktional geeignet, aber die Community und Dokumentation ausserhalb Asiens
ist zu klein. Support und Tutorials sind ueberwiegend auf Chinesisch.
Keine strategische Wahl fuer ein deutschsprachiges Team.

---

### 6. Unity

| Kriterium | Bewertung |
|---|---|
| Integration | Keine -- kompletter Rewrite erforderlich |
| Sprache | C# |
| Lizenz | Kostenpflichtig ab Umsatzschwelle, Runtime-Fee-Kontroverse |

**Bewertung:** Overkill fuer ein Match3-Spiel. Unity ist eine 3D-Engine mit 2D-Erweiterung.
Der Overhead an Tooling, Build-Zeiten und APK-Groesse steht in keinem Verhaeltnis
zum Nutzen fuer ein 2D-Puzzle-Spiel. Dazu kommt die Lizenz-Unsicherheit nach der
Runtime-Fee-Debatte.

---

## Vergleichsmatrix

| Kriterium | Flame | Godot 4 | Defold | Phaser | Cocos | Unity |
|---|---|---|---|---|---|---|
| Kein Rewrite noetig | Ja | Nein | Nein | Nein | Nein | Nein |
| Flutter-kompatibel | Ja | Nein | Nein | Nein | Nein | Nein |
| Match3-geeignet | Sehr gut | Gut | Sehr gut | Gut | Gut | Gut |
| APK-Groesse | Mittel | Gross | Sehr klein | N/A | Mittel | Gross |
| Lernaufwand | Gering | Mittel | Mittel | Mittel | Mittel | Hoch |
| Community (DE/EN) | Gut | Sehr gut | Klein | Gut | Sehr klein | Gross |
| Kosten | Kostenlos | Kostenlos | Kostenlos | Kostenlos | Kostenlos | Bedingt |

---

## Empfehlung: Flame Engine

**Flame ist die klare Empfehlung fuer dieses Projekt.**

Begruendung:

1. **Kein Rewrite noetig.** Das Projekt ist in Flutter gebaut und funktioniert.
   Flame ist ein Flutter-Package -- es erweitert das Projekt, statt es zu ersetzen.

2. **Gleiche Sprache, gleiches Tooling.** Dart bleibt die Sprache, die IDE bleibt gleich,
   das Build-System bleibt gleich. Kein neues Oekosystem, das gelernt werden muss.

3. **Schrittweise Migration.** Flame-Widgets (GameWidget) koennen in den bestehenden
   Flutter-Widget-Tree eingebettet werden. Es ist nicht noetig, alles auf einmal umzustellen.

4. **Match3-Referenzprojekte existieren.** "Runes Match 3" zeigt, dass Flame fuer genau
   diesen Spieltyp geeignet ist.

5. **Konkrete Verbesserungen gegenueber reinem Flutter:**
   - SpriteComponent statt manueller CustomPaint-Logik
   - SpriteAnimationComponent fuer fluesssige Gem-Animationen
   - ParticleSystemComponent fuer Explosions- und Kombo-Effekte
   - Eingebaute Collision Detection fuer Touch-Interaktion
   - Game Loop mit fixem Timestep fuer konsistente Animationen

---

## Migrationsplan (Flame Engine)

### Phase 1: Flame-Integration und Board-Rendering

**Aufwand:** 2-3 Tage

- `flame` als Dependency in `pubspec.yaml` hinzufuegen
- Neues `FlameGame`-Widget fuer das Spielbrett erstellen
- Board-Rendering von CustomPaint/Widget-Grid auf Flame-Components umstellen
- GameWidget in den bestehenden Flutter-Widget-Tree einbetten
- Flutter-UI (Score, Moves, Menues) bleibt unveraendert

```yaml
dependencies:
  flame: ^1.22.0
```

### Phase 2: Gem-Animationen mit Flame-Sprites

**Aufwand:** 3-4 Tage

- Emoji/Gem-Darstellung auf SpriteComponent oder SpriteAnimationComponent umstellen
- Swap-Animation mit MoveEffect statt Flutter AnimationController
- Fall-Animation (Gems fallen nach) mit SequenceEffect
- Idle-Animationen fuer Gems (leichtes Pulsieren, Glitzern)

### Phase 3: Partikel-Effekte

**Aufwand:** 2-3 Tage

- ParticleSystemComponent fuer Match-Explosionen
- Kombo-Effekte (3er, 4er, 5er Match) mit unterschiedlichen Partikel-Presets
- Screen-Shake bei grossen Kombos
- Konfetti/Sterne bei Level-Abschluss

### Phase 4: Input-System umstellen

**Aufwand:** 1-2 Tage

- Touch-Input von Flutter GestureDetector auf Flame DragCallbacks/TapCallbacks umstellen
- Drag-and-Drop fuer Gem-Swaps ueber Flame-Events
- Visuelles Feedback beim Drag (Gem folgt dem Finger, Highlight der Zielzelle)

### Phase 5: Optimierung und Polish

**Aufwand:** 2-3 Tage

- Sprite-Atlas erstellen (alle Gems in einem Bild, weniger Draw Calls)
- Kamera-System fuer unterschiedliche Boardgroessen
- Feintuning der Animationszeiten
- Performance-Profiling

**Gesamtaufwand geschaetzt: 10-15 Tage**

---

## Risiken und Massnahmen

| Risiko | Wahrscheinlichkeit | Massnahme |
|---|---|---|
| Flame-Version Breaking Changes | Mittel | Auf stabile Version pinnen, Changelog beobachten |
| Performance bei vielen Partikeln | Gering | Partikel-Budget pro Effekt begrenzen |
| Flutter-UI und Flame-Input Konflikte | Mittel | Klare Trennung: Flame nur fuer Board, Flutter fuer UI |
| Lernkurve Flame ECS | Gering | Flame-Tutorials und "Runes Match 3" als Referenz nutzen |

---

## Fazit

Ein Wechsel zu einer externen Game Engine (Godot, Defold, Unity) wuerde einen kompletten
Rewrite bedeuten und ist fuer den aktuellen Stand des Projekts nicht gerechtfertigt.

Flame Engine ist die richtige Wahl: Es erweitert Flutter um Game-Engine-Faehigkeiten,
ohne das bestehende Projekt zu verwerfen. Die Migration kann schrittweise erfolgen,
das Risiko ist gering, und der Nutzen (bessere Animationen, Partikel, Sprite-Management)
ist direkt sichtbar.
