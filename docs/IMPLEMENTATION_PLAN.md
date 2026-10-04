# FuelZone – Umsetzungsplan Redesign + Fixes

**Stand:** 04.10.2026 · **Grundlage:** [CODE_REVIEW.md](CODE_REVIEW.md), [UI_REVIEW.md](UI_REVIEW.md), freigegebenes Canvas „FuelZone Redesign“ (Race Instrument)

Reihenfolge: zuerst die Logik (testgetrieben), dann Daten/State, dann das Design-System, dann die Screens. So steht unter dem neuen UI ein korrekter Kern, und jeder Schritt ist für sich testbar.

---

## Phase 0 – Vorbereitung
- Die offenen Änderungen auf `fix/scroll-behavior-ui` committen; das Redesign ersetzt sie später ohnehin.
- Neuer Branch `redesign/race-instrument`. **Pro Phase ein Commit**, kein Push ohne dein OK.
- Test-Infrastruktur reparieren:
  - Test-Target-Deployment von 26.4 auf 17.0 stellen.
  - `NutritionAppUITests` ins Scheme aufnehmen.
  - Den veralteten Lokalisierungstest fixen.

## Phase 1 – Rechenkern (Tests zuerst)
| Was | Review-Punkt |
|---|---|
| **SnackComposer neu:** Er trifft das Ziel (Obergrenze ca. Ziel × 1,15) und verteilt Flüssigkeit über die Stopps. Die Packliste und Soll-vs.-Ist-Summen kommen aus den echten Snacks. | K1 |
| „Magen tolerant“ bekommt eine Wirkung (z. B. bis 100 g/h bei langen Einheiten), oder die Option wird entfernt; das entscheide ich nach Literatur und dokumentiere es. | B12 |
| Die Dauer bekommt Grenzen (z. B. 10 min – 24 h), Max-HF und Gewicht werden validiert. | B5, B13 |
| Die Plan-Vorschau nutzt den Calculator selbst, ohne Logik-Kopie. | Duplikat |
| Der Open-Food-Facts-Parser liest Portionsgrößen richtig („1 Riegel (40 g)“ → 40 g), dazu User-Agent und Timeout. | B6 |
| Ein Fehlschlag löscht `lastResult`, die Force-Unwraps fallen weg. | B2 |
| Die 8 roten Review-Tests werden grün, dazu kommen neue Tests für Composer-Grenzen, Parser und Validierung. | – |

## Phase 2 – Daten, State, Pro
- **Pro-Status nur aus StoreKit ableiten**, nie speichern. Der Verlauf wird nie physisch gekürzt; Free sieht nur die letzten 10. (K4)
- **Persistenz neu:** Der iCloud-KVS fällt weg. Lokale JSON-Dateien sind die Wahrheit, synchronisiert wird per CloudKit **pro Datensatz** mit Änderungsdatum („neuer gewinnt“). Es gibt Fehler-Logging statt `try?`. (K2, K3)
- **Eine Quelle für Profil und Settings** (AppState) statt Kopien in 5 ViewModels. (B10, B11)
- **Verlauf:** löschen, „Erneut planen“, Snack-Tausch wird gespeichert, die Detailansicht zeigt Snacks. (B8, B9, B24, B25)
- **Snacks:** Aus „aktiviert“ wird „Mein Kit“; deaktivierte Snacks verschwinden nicht mehr. Bestehende Daten werden migriert. (B1)
- **Barcode:** keine Doppel-Snacks mehr, Kategorie und Einheit sinnvoll vorbelegen. (B7, B23)
- **Onboarding-Neustart** beginnt bei Schritt 1 und behält Profil-ID und HF-Zonen. (B3, B4)
- **Standort:** Continuation-Leak und Polling fixen, Geocoding auf das MapKit-API umstellen. (B15, B16)

## Phase 3 – Design-System in SwiftUI
- **Farb-Tokens als Asset-Farben (Light/Dark)** exakt wie auf dem Canvas.
- **Typografie:** SF Pro mit `.fontWidth(.compressed / .expanded)` und Text Styles, **Dynamic Type** funktioniert damit automatisch.
- **Bausteine:**
  - Primär- und Sekundär-Button
  - Tinten-Chips und Tinten-Segmente
  - Daten-Token (Gel, Iso, Salz)
  - große Kennzahl
  - Ziel-Meter (Stufen 30/60/90)
  - **Fuel Track**
  - Glass-Dock mit Live-Vorschau
- **Native `TabView`:** Liquid Glass ab iOS 26, klassisch auf 17/18.
- **Accessibility:** Labels für alle Schalter und Felder, „ausgewählt“-Zustände, Touch-Ziele ≥ 44 pt.

## Phase 4 – Screens nach Mockup
1. **Onboarding:** 4 Schritte, Hero mit Streckenprofil.
2. **Plan:** Sport-Chips, Rennuhr-Dauer mit Schnellwahl, Intensität mit Balken-Kacheln, Wetter als eine Zeile, Dock fest unten. **Zonen-Modus (Pro)** baue ich im selben Stil; er war nicht im Mockup.
3. **Ergebnis:** Kennzahl „im Ziel“, Stufen-Meter, Flüssigkeit/Natrium-Kacheln, Packliste, Fuel Track mit Tausch, Teilen (Text-Zusammenfassung über `ShareLink`).
4. **Snacks:** Mein Kit, Katalog mit Suche und allen Kategorien, Pro-Hinweis; der Editor wird im neuen Stil überarbeitet.
5. **Verlauf:** Karten mit Kennzahlen und Mini-Track, Swipe für „Erneut planen“ und „Löschen“.
6. **Einstellungen:** gruppierte Liste, Pro-Zeile, kompakte Darstellung-Auswahl.
7. **Profil:** kompakte Picker, sofort speichern; der HF-Zonen-Editor bekommt den neuen Stil.
8. **Pro-Paywall:** dunkler Hero, Jahr/Monat, Rechtslinks.
9. **Methodik:** im neuen Stil, Inhalt bleibt.

## Phase 5 – Aufräumen & Release-Hygiene
- Toten Code löschen (`AddCustomSnackView`, `PrimaryCTAButton`, unbenutzte Properties); doppelte Ergebnis- und Verlaufs-Views zu einer Komponente zusammenführen.
- Info.plist-Texte auf Deutsch, ungenutzten Background-Mode und Push entfernen, Launch-Screen hell/dunkel, Privacy Manifest ergänzen.
- `os.Logger` statt verschluckter Fehler; die Swift-6-Concurrency-Warnungen beheben.

## Phase 6 – Prüfen
- **Alle** Unit- und UI-Tests grün, dazu neue UI-Tests für die Hauptabläufe (Onboarding → Plan → Ergebnis → Verlauf).
- Screenshot-Durchlauf Light + Dark auf iPhone 17 (iOS 27) und, falls vorhanden, einem iOS-17/18-Simulator; Vergleich mit dem Canvas.
- `CODE_REVIEW.md` mit Status pro Punkt (behoben / offen) aktualisieren, README-Screenshots erneuern.

---

## Nicht heute (braucht dich oder externe Schritte)
- GitHub Pages für Datenschutz und AGB aktivieren (Links liefern aktuell 404).
- Abos in App Store Connect anlegen, Test auf einem echten Gerät, TestFlight.
- Größere neue Features (Teilen als Bild, HealthKit/Strava).

## Entscheidungen, die ich vorschlage (bitte bestätigen oder ändern)
1. **Persistenz:** pragmatisch mit JSON + CloudKit pro Datensatz (empfohlen; weniger Risiko). Die Alternative SwiftData + CloudKit wäre ein größerer Umbau mit Migrationsrisiko.
2. **Standard-Kit für neue Nutzer:** 4 Snacks (Maurten Gel 160, GU Roctane, Iso 500 ml, Salztablette). Den Rest holt man aus dem Katalog.
3. **„Magen tolerant“:** behalten und wirksam machen, statt die Option zu entfernen.
4. **Commits** pro Phase auf dem neuen Branch, gepusht wird erst nach deinem OK.

**Umfang:** Das ist ein großer Umbau. Ich arbeite die Phasen nacheinander ab und gebe dir nach jeder Phase einen kurzen Zwischenstand mit Testergebnis. Phase 1–3 sind die Grundlage; falls die Zeit heute nicht für alle Screens reicht, sind danach zuerst Plan und Ergebnis fertig.
