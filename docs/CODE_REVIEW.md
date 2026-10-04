# FuelZone – Code Review

**Datum:** 03.10.2026 · **Branch:** `fix/scroll-behavior-ui` (Stand `834d166` + 3 uncommittete Dateien)
**Umfang:** alle 92 Swift-Dateien (~7.200 Zeilen), Tests, `Info.plist`, Entitlements, `PrivacyInfo.xcprivacy`, `FuelZone.storekit`, `Localizable.strings` (DE/EN), `DefaultSnacks.json`, `docs/`

Legende: 🔴 kritisch · 🟠 Bug · 🟡 Code-Qualität / Risiko · 🔵 Kleinigkeit
**✅ bestätigt** = per Test oder im Simulator nachgewiesen · ohne Haken = aus dem Code abgeleitet

---

## 0. Status nach dem Redesign (04.10.2026)

Alle Punkte wurden in den Branches `redesign/phase-0-setup` … `redesign/phase-6-verification` bearbeitet. ✅ = behoben und durch Tests abgesichert, ☑️ = behoben, 🔶 = braucht einen externen Schritt.

| Punkt | Status | Umsetzung |
|---|---|---|
| K1 SnackComposer überplant | ✅ | Neuer Composer nach aufgelaufenen Zielen, halbe Gels, natriumbewusst (`CalculationCoreTests`) |
| K2 iCloud-Datenverlust | ✅ | `UserDataStore` + `CloudSyncService`: ein Datensatz pro Element, „neuer gewinnt“, Löschmarkierungen (`DataLayerTests`) |
| K3 KVS nicht konfiguriert | ✅ | KVS entfernt, nur noch CloudKit |
| K4 Pro gespeichert | ✅ | Pro nur aus StoreKit, Verlauf wird nie gekürzt |
| B1 Snack verschwindet | ✅ | „Mein Kit“ + Katalog |
| B2 altes Ergebnis | ✅ | `calculatePlan()` gibt Ergebnis zurück, löscht alte |
| B3/B4 Onboarding | ✅ | Neustart bei Schritt 1, Profil-ID und Zonen bleiben |
| B5 Validierung | ✅ | `InputParsing` |
| B6 Barcode-Portion | ✅ | Regex-Parser mit Einheiten |
| B7 Barcode doppelt | ✅ | Sperre während der Abfrage + Duplikat-Erkennung |
| B8 Tausch nicht gespeichert | ✅ | `PlanResultViewModel` schreibt in den Verlauf |
| B9 Verlauf löschen | ✅ | Wischen/Kontextmenü |
| B10/B11 Profil-State | ✅ | eine Datenquelle, sofort speichern |
| B12 „Verträglich“ wirkungslos | ✅ | bis ≈ 100 g/h ab 2,5 h |
| B13 Dauergrenzen | ✅ | 10 min – 24 h |
| B14 Profil-Speichern | ☑️ | Profil neu, Eingaben bleiben, Fehler direkt am Feld |
| B15 Standort | ☑️ | wartet auf Erlaubnis, keine hängenden Continuations |
| B16 Geocoder | ☑️ | neuer Geocoder je Anfrage |
| B17 Toggle im Tausch-Sheet | ☑️ | neues Sheet ohne Toggle |
| B18 Snacks verschwinden | ✅ | Snapshot der genutzten Snacks im Ergebnis |
| B19 Menge beim Tausch | ✅ | `FuelPlanEditor` rechnet um |
| B20 Slider 30–300 | ☑️ | 15 min – 8 h + Distanz-Modi |
| B21 Filter-Chips | ☑️ | alle Kategorien + Suche |
| B22 Einheit/Validierung im Editor | ☑️ | Einheiten-Picker, Validierung, Lösch-Bestätigung |
| B23 Barcode-Kategorie | ☑️ | Getränke werden erkannt |
| B24 Detail ohne Snacks | ✅ | gemeinsame Ergebnisansicht |
| B25 doppelter Trenner | ☑️ | neue Verlaufskarten |
| *Neu in Phase 6:* Absturz beim Freigeben von MainActor-Klassen auf iOS 17/18 (isolated-deinit-Shim) | ✅ | `nonisolated deinit` in allen eigenen Klassen; alle Tests auch auf iOS 18.6 grün |
| *Neu in Phase 6:* Dock verdeckt Eingabefelder bei offener Tastatur | ✅ | Dock blendet sich beim Tippen aus, „Fertig“-Taste über der Tastatur |
| Code-Qualität (Duplikate, toter Code, Warnungen) | ☑️ | Ergebnis/Detail zusammengeführt, toter Code entfernt, 0 Compiler-Warnungen |
| Accessibility | ☑️ | Dynamic Type, Labels, 44 pt, „ausgewählt“-Traits |
| Release: Rechtslinks 404 | 🔶 | Seiten liegen unter `docs/privacy.md`/`docs/terms.md` – **GitHub Pages muss noch aktiviert werden** |
| Release: Paywall-Rechtslinks | ✅ | in der Paywall |
| Release: Push-Capability | ☑️ | entfernt |
| Release: Privacy Manifest | ☑️ | ungefährer Standort deklariert |
| Release: App Store Connect | 🔶 | Abos anlegen, TestFlight |

---

## 1. Gesamtbild (Stand vor dem Redesign)

| Bereich | Zustand |
|---|---|
| Build | ✅ baut ohne Fehler (Xcode, iOS 27 SDK). 2 Compiler-Warnungen in `DataStore.swift:58/67` (`#IsolatedConformances`) |
| Unit-Tests | 19 von 20 grün. **1 rot:** `NutritionAppTests.testEnglishLocalizationKeysResolve`, weil der Key `snack.gel.standard` nicht mehr existiert (Test veraltet, die App ist hier nicht kaputt) |
| UI-Tests | Das Target `NutritionAppUITests` ist **nicht im Scheme** und läuft nie mit. Inhalt sind nur Xcode-Vorlagen |
| Berechnungslogik (g/h, Flüssigkeit, Natrium) | sauber, gut getestet, nachvollziehbar dokumentiert |
| **Snack-Plan (Timeline)** | 🔴 **grundlegend falsch**: plant ein Vielfaches der Zielmenge ein (siehe K1) |
| Persistenz / iCloud | 🔴 fehleranfällig: Konflikte werden nicht behandelt, Fehler werden verschluckt, Key-Value-Sync ist nicht konfiguriert |
| Pro / StoreKit | funktioniert grundsätzlich, aber der Pro-Status wird gespeichert und synchronisiert statt jedes Mal aus StoreKit gelesen zu werden |
| Lokalisierung | DE/EN vollständig (346/346 Keys, keine fehlenden Format-Specifier) |
| Architektur | klar gegliedert (Core/Models/Services/ViewModels/Views), aber viel duplizierter Code und State an mehreren Stellen gleichzeitig |
| Accessibility | schwach: feste Schriftgrößen (kein Dynamic Type), Toggles und Textfelder ohne Label |
| App-Store-Reife | **noch nicht**: Links zu Datenschutz und AGB liefern 404, die Paywall hat keine Rechtslinks, ungenutzter Background-Mode |

### Was funktioniert
- Onboarding, Plan-Eingabe (Dauer / Distanz+Pace / Distanz+Zeit), Zonen-Editor, Wetter (Open-Meteo + Geocoding/GPS)
- Berechnung der Bereiche für KH, Flüssigkeit und Natrium inkl. Warnungen (Magen-Cap, Multiple Transportable Carbs, < 30 min)
- Verlauf mit Detailansicht; Snack-Tausch in der Detailansicht wird gespeichert
- Snack-Bibliothek, eigene Snacks mit Foto, Barcode über Open Food Facts
- StoreKit-2-Kauf, Wiederherstellen, Transaction-Listener
- Sprache und Erscheinungsbild umschaltbar, Light/Dark Mode

### Was nicht (richtig) funktioniert – Kurzfassung
1. Die Snack-Timeline schlägt **337 g KH/h statt ~51 g/h** vor (2-h-Einheit, moderat) ✅
2. Ein deaktivierter Standard-Snack **verschwindet** aus der Bibliothek und lässt sich nicht wieder einschalten ✅
3. „Onboarding wiederholen“ startet **beim letzten Schritt** statt bei der Begrüßung ✅
4. Schlägt eine Berechnung fehl, wird das **vorherige Ergebnis erneut gespeichert und angezeigt** ✅
5. Der Barcode-Scanner liest Portionsgrößen falsch („1 Riegel (40 g)“ → 140 g) ✅ und kann **Snacks doppelt anlegen**
6. Der iCloud-Sync kann **neuere lokale Daten überschreiben**; der Key-Value-Store ist ohne Entitlement wirkungslos
7. Ein Snack-Tausch im Ergebnis-Screen wird **nicht im Verlauf gespeichert**
8. Ein Verlauf kann **nicht gelöscht** werden (Funktion existiert, aber es gibt keine UI dafür)
9. Die Option „Magen: tolerant“ **hat keinen Effekt** ✅

---

## 2. Kritisch 🔴

### K1 – SnackComposer plant massiv zu viel ein ✅
[SnackComposer.swift:55-91](../NutritionApp/Core/SnackComposer.swift)

Der Greedy-Algorithmus nimmt pro 20-Minuten-Schritt immer den Snack mit den **meisten** KH (Maurten 320 = 80 g), ohne auf Überschreitung zu prüfen. Zusätzlich wird für Flüssigkeit ein 500-ml-Isogetränk (32,5 g KH) dazugepackt.

Gemessen (`CodeReviewFindingsTests.testSnackComposer_doesNotGrosslyOvershootCarbTarget`):
> 120 min, moderat: **Ziel 47–55 g/h → geplant 337 g/h**, Flüssigkeit **1.500 ml/h statt 540–660 ml/h**

Das ist das Kernfeature der App und gesundheitlich relevant (GI-Probleme, Überwässerung). Der bestehende Test `testSnackComposer_matchesCarbTargetsWithinTolerance` prüft nur die Untergrenze (≥ 70 %), deshalb ist das nie aufgefallen.

Weitere Fehler im selben Code:
- **Mengenlimit greift nicht** ✅: `bestCarbSnack` prüft `$0.quantity >= 2`, aber `add()` legt immer `quantity: 1` an, also ist die Bedingung nie wahr. Gemessen: derselbe Gel 4× in einem Schritt.
- Die Getränke-Flüssigkeit kommt über eine hartcodierte Tabelle `unit.ml500/330/250`. Eigene Getränke mit anderer Einheit zählen als 0 ml.
- Ebenfalls betroffen: [SnackPlanSummaryView.swift:44-52](../NutritionApp/Views/Results/SnackPlanSummaryView.swift). Die „Snack-Plan-Summe“ addiert die **Zielwerte**, nicht den Inhalt der Snacks. Die Überdosierung bleibt dadurch auch in der UI unsichtbar.

**Fix-Idee:** Pro Schritt die Snacks wählen, die das Ziel am besten treffen (kleinster Fehler, mit Obergrenze ≈ Ziel × 1,15). Flüssigkeit über den Getränke-Snack selbst abrechnen und optional auf mehrere Schritte verteilen (z. B. 500 ml über 40–60 min). Den Test um eine Obergrenze ergänzen.

### K2 – iCloud-Sync kann Daten verlieren
[DataStore.swift:22-68](../NutritionApp/Services/DataStore.swift), [CloudKitDataStore.swift:15-34](../NutritionApp/Services/CloudKitDataStore.swift)

- `syncFromCloudKit()` überschreibt UserDefaults und KVS **ungeprüft** mit dem CloudKit-Stand. Es gibt keinen Zeitstempel- oder Versionsvergleich. Szenario: Offline speichern → das CloudKit-Speichern schlägt still fehl (`try?`) → beim nächsten Start überschreibt der alte Cloud-Stand die neuen lokalen Daten.
- `save()` startet bei jedem Speichern einen ungeordneten `Task`. Schnelle Folge-Saves (Snack-Toggles) laufen parallel: Fetch → Save → `serverRecordChanged`, und der Fehler wird mit `try?` verschluckt. In CloudKit bleibt dann ein veralteter Stand liegen.
- `try? await database.record(for:)` behandelt **jeden** Fehler (auch einen Netzwerkfehler) als „Record existiert nicht“ und legt dann einen neuen Record an. Das scheitert, und auch dieser Fehler wird verschluckt.
- `remove(key:)` löscht nicht in CloudKit; der nächste Sync stellt den Wert wieder her (aktuell ungenutzt).

### K3 – iCloud Key-Value-Store ist nicht konfiguriert
[NutritionApp.entitlements](../NutritionApp/NutritionApp.entitlements)

`NSUbiquitousKeyValueStore` braucht das Entitlement `com.apple.developer.ubiquity-kvstore-identifier`, und das fehlt. Der KVS synchronisiert damit nicht, obwohl das README es verspricht.

Wenn man es nachrüstet, entsteht ein neues Problem: KVS hat **1 MB Gesamtlimit**. Der unbegrenzte Pro-Verlauf (jede Session mit kompletter Timeline) überschreitet das. `load()` liest **zuerst den KVS** ([DataStore.swift:23](../NutritionApp/Services/DataStore.swift)); nach einer Quota-Überschreitung würde also ein veralteter Stand gewinnen. Empfehlung: KVS für große Daten (Verlauf, Snacks) nicht verwenden, sondern nur CloudKit (oder SwiftData + CloudKit).

### K4 – Pro-Status wird persistiert und synchronisiert statt abgeleitet
[AppSettings.swift:6](../NutritionApp/Models/AppSettings.swift), [AppState.swift:59-95](../NutritionApp/ViewModels/AppState.swift)

`isProSubscriber` liegt in `AppSettings` und wird in UserDefaults, KVS und CloudKit gespeichert. Folgen:
- Beim Start ist `isProActive` zunächst `false`, und der Sink schreibt sofort `false` in alle Stores. Speichert ein **zahlender Pro-User** in diesem Moment eine Session, kürzt [HistoryViewModel.swift:29-31](../NutritionApp/ViewModels/HistoryViewModel.swift) den Verlauf **dauerhaft auf 10 Einträge**.
- `reloadFromStore()` (nach dem Cloud-Sync) übernimmt `isProSubscriber` aus der Cloud. Ist dort noch `true` gespeichert (abgelaufenes Abo oder Debug-Toggle), bleibt Pro freigeschaltet, bis sich `isProActive` das nächste Mal ändert.
- Der **Debug-Pro-Toggle** schreibt `true` in den gemeinsamen Store. Ein Release-Build auf demselben Account kann das übernehmen.

**Fix-Idee:** Pro ausschließlich aus `SubscriptionManager.isProActive` ableiten (nicht speichern). Die Verlaufskürzung nur in der Anzeige machen, die gespeicherten Daten nie löschen.

---

## 3. Bugs 🟠

| # | Ort | Problem |
|---|---|---|
| B1 ✅ | [SnackViewModel.swift:36-42](../NutritionApp/ViewModels/SnackViewModel.swift) | `allSnacks()` filtert deaktivierte Standard-Snacks heraus, und die Bibliothek nutzt diese Liste. Ein ausgeschalteter Snack **verschwindet** und lässt sich nicht wieder einschalten. Nachgewiesen per Unit- und UI-Test (Screenshot: „GU Energy Gel“ weg). |
| B2 ✅ | [SessionViewModel.swift:127-163](../NutritionApp/ViewModels/SessionViewModel.swift), [SessionSetupView.swift:49-61](../NutritionApp/Views/Session/SessionSetupView.swift) | `lastResult` wird bei einem Fehler nicht zurückgesetzt. `startPlan()` prüft nur `lastResult != nil` und speichert dann das **alte Ergebnis erneut** im Verlauf und navigiert dorthin, obwohl eine Fehlermeldung angezeigt wird. Außerdem gibt es ein Force-Unwrap `lastResult!`. |
| B3 ✅ | [OnboardingViewModel.swift:27](../NutritionApp/ViewModels/OnboardingViewModel.swift), [SettingsView.swift:208-216](../NutritionApp/Views/Settings/SettingsView.swift) | `stepIndex` wird nie zurückgesetzt. „Onboarding wiederholen“ öffnet direkt bei „You're ready!“ (UI-Test-Screenshot). |
| B4 | [AppState.swift:114-120](../NutritionApp/ViewModels/AppState.swift), [OnboardingViewModel.swift:30-43](../NutritionApp/ViewModels/OnboardingViewModel.swift) | `completeOnboarding()` baut ein **neues** `UserProfile`. Beim Wiederholen gehen Profil-ID, `createdAt` und **manuell angepasste HF-Zonen** verloren. |
| B5 ✅ | [OnboardingViewModel.swift:30-43](../NutritionApp/ViewModels/OnboardingViewModel.swift) | Keine Validierung: Max-HF 30 oder Gewicht −5 werden übernommen, die Zonen werden daraus berechnet. `HeartRateZoneCalculator.validMaxHRRange` wird hier nicht genutzt. |
| B6 ✅ | [OpenFoodFactsClient.swift:75-84](../NutritionApp/Services/OpenFoodFactsClient.swift) | Die Portionsgröße wird über „alle Ziffern“ geparst: „1 bar (40 g)“ → **140 g**, „2 x 25 g“ → 225 g. Der `ml`-Zweig ist toter Code (dieselben Ziffern). |
| B7 | [BarcodeScannerView.swift:47-56, 107-132](../NutritionApp/Views/Snacks/BarcodeScannerView.swift) | `didAdd` feuert mehrfach, und es gibt keinen Schutz (`isLoading` wird nicht geprüft, das Scannen läuft weiter). Mehrere parallele Requests können **denselben Snack mehrfach anlegen**. |
| B8 | [ResultsViewModel.swift:67-79](../NutritionApp/ViewModels/ResultsViewModel.swift) | Ein Snack-Tausch direkt im Ergebnis-Screen ändert nur den lokalen State; der bereits gespeicherte Verlaufseintrag bleibt alt. (In der Detailansicht funktioniert es.) |
| B9 | [HistoryViewModel.swift:37-44](../NutritionApp/ViewModels/HistoryViewModel.swift), [HistoryView.swift](../NutritionApp/Views/History/HistoryView.swift) | `delete(at:)` existiert, aber es gibt keine Swipe-to-Delete- oder Löschen-UI. Verlaufseinträge lassen sich nicht entfernen. |
| B10 | [ProfileView.swift:81-110](../NutritionApp/Views/Settings/ProfileView.swift) | Sport und Physiologie binden direkt an `appState.profile` (sofort aktiv, aber nicht gespeichert); Name und Gewicht erst über „Speichern“. Wer ohne Speichern zurückgeht, hat ein gemischtes, ungespeichertes Profil, das beim Neustart verschwindet. Das `SessionViewModel` sieht die Änderungen nicht. |
| B11 | [AppState.swift:85-95](../NutritionApp/ViewModels/AppState.swift), [SessionSetupView.swift:52-53](../NutritionApp/Views/Session/SessionSetupView.swift) | `reloadFromStore()` aktualisiert `sessionViewModel` nicht. `startPlan()` schreibt danach `viewModel.exportedProfile()` (die alte Kopie) zurück und **überschreibt ein per iCloud synchronisiertes Profil**. |
| B12 ✅ | [StomachSensitivity.swift:12-18](../NutritionApp/Models/Enums/StomachSensitivity.swift) | „Tolerant“ = 90 × 1,12 = 100,8 g/h Obergrenze, die Empfehlung ist aber maximal 90. Die Option ist **wirkungslos** (identisch zu „moderat“). |
| B13 ✅ | [FuelingCalculator.swift:22](../NutritionApp/Core/FuelingCalculator.swift), [SessionViewModel.swift:165-184](../NutritionApp/ViewModels/SessionViewModel.swift) | Keine Obergrenze für die Dauer. 100.000 min (Tippfehler bei Distanz/Pace) werden akzeptiert und erzeugen 5.000 Timeline-Schritte. |
| B14 | [ProfileView.swift:341-380](../NutritionApp/Views/Settings/ProfileView.swift) | Bei ungültigen Zonen setzt `saveProfile()` die Eingaben des Users **auf Standard zurück** und speichert nicht. Die Eingaben sind weg, und es erscheint nur eine Fehlermeldung. Das Gewicht wird nicht validiert. Nach dem Speichern gibt es keine Bestätigung. |
| B15 | [LocationAccessService.swift:20-37](../NutritionApp/Services/LocationAccessService.swift) | Bei `.notDetermined` fragt der Code alle 400 ms rekursiv ab, statt auf den Delegate zu warten. Ein zweiter Aufruf überschreibt `continuation`; die erste wird nie aufgelöst (Continuation-Leak, der Task hängt). |
| B16 | [WeatherService.swift:20](../NutritionApp/Services/WeatherService.swift) | Ein gemeinsamer statischer `CLGeocoder`: Parallele Anfragen brechen sich gegenseitig ab. `CLGeocoder` ist ab iOS 26 außerdem deprecated (MapKit `MKGeocodingRequest`). |
| B17 | [FuelZoneUIComponents.swift:245-262](../NutritionApp/Views/Components/FuelZoneUIComponents.swift), [SnackSwapSheet.swift:37](../NutritionApp/Views/Results/SnackSwapSheet.swift) | `FuelZoneSnackRow.showsToggle` wird ignoriert. Im Tausch-Sheet erscheint bei jedem Snack ein **ausgeschalteter, funktionsloser Toggle**. |
| B18 | [ResultsViewModel.swift:18-30](../NutritionApp/ViewModels/ResultsViewModel.swift), [TimelineView.swift:48-52](../NutritionApp/Views/Results/TimelineView.swift) | `snack(for:)` liefert `nil` für deaktivierte oder gelöschte Snacks oder Custom-Snacks ohne Pro. Die Portion wird dann **still ausgeblendet** (auch in alten Verlaufseinträgen). |
| B19 | [ResultsViewModel.swift:76](../NutritionApp/ViewModels/ResultsViewModel.swift) | Beim Tausch bleibt die `quantity` gleich: 2× Gel → 2× 500-ml-Flasche. KH, Natrium und Flüssigkeit werden nicht neu berechnet. |
| B20 | [FuelZoneThemeComponents.swift:151-178](../NutritionApp/Views/Components/FuelZoneThemeComponents.swift) | Der Dauer-Slider geht nur von 30 bis 300 min. Die Logik für Einheiten < 30 min ist im Dauer-Modus unerreichbar; Ultras > 5 h gehen nur über Distanz+Zeit. Ein Wert außerhalb des Bereichs (z. B. 600 aus einem anderen Modus) wird falsch angezeigt. |
| B21 | [FuelZoneThemeComponents.swift:253-261](../NutritionApp/Views/Components/FuelZoneThemeComponents.swift) | Für die Kategorien „Elektrolyte“ und „Sonstiges“ gibt es keinen Filter-Chip. |
| B22 | [EditSnackView.swift:17, 76](../NutritionApp/Views/Snacks/EditSnackView.swift) | Das Feld „Einheit“ zeigt den **rohen Lokalisierungs-Key** `unit.piece` zum Bearbeiten. Negative KH- und Natriumwerte sind erlaubt. Löschen ohne Bestätigung. |
| B24 ✅ | [SessionDetailViewModel.swift:15,27](../NutritionApp/ViewModels/SessionDetailViewModel.swift), [SessionDetailView.swift:23-29](../NutritionApp/Views/History/SessionDetailView.swift) | *Nachtrag aus UI-Review:* Die Verlaufs-Detailansicht zeigt **keine Snacks** in der Timeline. `allSnacks` ist nicht `@Published` und wird erst in `onAppear` gesetzt, also gibt es kein Re-Render (Screenshot `docs/screenshots/ui-review/history-detail-snacks.png`). |
| B25 ✅ | [HistoryView.swift:52-54](../NutritionApp/Views/History/HistoryView.swift), `history.duration` | *Nachtrag:* Doppelter Trenner „Running · · 90 min“. Die View setzt ein `·`, und der String enthält ebenfalls eines. |
| B23 | [BarcodeScannerView.swift:114-124](../NutritionApp/Views/Snacks/BarcodeScannerView.swift) | Gescannte Produkte bekommen immer Kategorie `.other` und Einheit `unit.piece`. Fehlen bei OFF die Nährwerte, wird der Snack still mit 0 g KH angelegt. |

---

## 4. Code-Qualität & Architektur 🟡

**State und Datenfluss**
- Das Profil existiert 3× (`AppState.profile`, `SessionViewModel.profile`, `OnboardingViewModel`), die Settings 5× (in jedem ViewModel eine Kopie, synchronisiert per `configure`/`updateSettings`). Daraus entstehen B10/B11. Besser wäre eine einzige Quelle (`AppState` bzw. ein `ProfileStore`), die die ViewModels lesen.
- `SessionDetailView` erstellt das ViewModel mit `AppSettings()`-Default und patcht es in `onAppear`. Beim ersten Render ist es immer „kein Pro“.
- Alle vier Tabs werden gleichzeitig gerendert ([MainTabView.swift](../NutritionApp/Views/MainTabView.swift), Opacity-Trick). `onAppear` feuert für alle Tabs beim Start, und jede Änderung rendert alle vier Stacks neu.
- `objectWillChange.send()` nach `@Published`-Mutationen ist redundant ([SnackViewModel.swift:111,124,136](../NutritionApp/ViewModels/SnackViewModel.swift)).
- `isCalculating` ist wirkungslos, weil die Berechnung synchron läuft.

**Duplikate (DRY)**
- `ResultsView` ↔ `SessionDetailResultsView`, `FuelTimelineView` ↔ `SessionDetailTimelineView`, `ResultsViewModel` ↔ `SessionDetailViewModel` (`formatRange`, Text-Helper sind identisch). Die Varianten driften schon auseinander (verschiedene Icons, Farben, Accessibility-Labels).
- [SessionViewModel+PlanPreview.swift](../NutritionApp/ViewModels/SessionViewModel+PlanPreview.swift) rechnet die Logik aus `FuelingCalculator` nach (Kopie, mit hartcodierten „22 g pro Gel“).
- `ZoneEditorView` 5× kopierte Stepper-Zeilen statt `ForEach(HeartRateZone.allCases)`.

**Toter Code** (wird nirgends verwendet)
`AddCustomSnackView` (komplette Datei), `PrimaryCTAButton` (komplette Datei), `SnackLibraryState.builtInSnackIDs`, `SessionViewModel.bind(results:)`, `ResultsViewModel.showSnackLibrary`, `ResultsView.showLibrary` (Sheet nie erreichbar), `HeartRateZone.defaultPercentRange`, `HeartRateZoneCalculator.defaultDistribution`, `DesignSystem.groupedBackground/cardBackground`, `DataStore.remove`, `Snack.displayNameKey`, `TimelineStep.labelKey`, `ExerciseCarbGuidelines.DurationTier.localizationKey`, `FuelZoneSnackRow.showsToggle`. Dazu redundante `switch`-Zweige in `Snack.effectivePortionGrams` und `inferredPortionGramsFromUnit`. Der Parameter von `AppSettings.hasAccess(to:)` wird ignoriert.

**Fehlerbehandlung**
- Durchgängig `try?` ohne Logging (DataStore, CloudKit, Fotos, Scanner). Wenn etwas schiefgeht, sieht man es nirgends; hier sollte `os.Logger` genutzt werden.
- Ein unverifizierter Kauf (`.unverified`) wird ohne Rückmeldung ignoriert ([SubscriptionManager.swift:129-134](../NutritionApp/Services/SubscriptionManager.swift)).
- `OpenFoodFactsClient`: kein Timeout, kein eigener `User-Agent` (von OFF verlangt), Barcode wird nicht validiert (ungeprüft in den URL-Pfad eingesetzt).

**Concurrency**
- Swift 5 Language Mode mit `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. Die zwei `#IsolatedConformances`-Warnungen in `DataStore` werden in Swift 6 zu Fehlern.
- `DataStore` ist `@unchecked Sendable`, der Notification-Handler `cloudDidChangeExternally` läuft auf einem beliebigen Thread.

**Performance**
- [SnackLibraryView.swift:80](../NutritionApp/Views/Snacks/SnackLibraryView.swift): `SnackPhotoStore.load()` liest bei **jedem Render für jede Zeile** von der Festplatte (Main Thread). Fotos werden in voller Auflösung gespeichert (12 MP, JPEG 0,85) statt als Thumbnail.
- `SnackPlanSummaryView`: `aggregateTotals()` 3× und `uniqueSnackIDs()` pro Zeile (O(n²)).
- `allSnacks()` sortiert bei jedem Aufruf neu und wird pro Render mehrfach aufgerufen.

**Tests**
- Gut: Calculator, Guidelines und Zonen sind solide getestet.
- Es fehlen: ViewModels, Persistenz und Sync, SnackComposer-Obergrenzen, Open-Food-Facts-Parsing, Migrationen (Codable mit Legacy-Keys).
- Das Test-Target hat Deployment Target **iOS 26.4**, die App **iOS 17.0**. Auf einem iOS-18-Simulator scheitert der Testlauf komplett.
- `NutritionAppUITests` ist nicht im Scheme.

---

## 5. Accessibility, UX, Design 🟡/🔵

- **Kein Dynamic Type:** Alle Schriften in `DesignSystem.Typography` sind `Font.system(size:)` mit festen Größen.
- `Toggle("")` und `Stepper("")` mit `labelsHidden()`, `TextField("")` ohne Label: VoiceOver liest „Schalter“ bzw. „Textfeld“ ohne Kontext.
- Eigene Tab-Bar und Segment-Picker ohne `.isSelected`-Trait.
- Kontrast: helle Amber-Pills (`accentLight` auf hellem Hintergrund, z. B. „21 g carbs“) sind im Light Mode schwer lesbar (Screenshot); das Warn-Icon `accentLight` auf Weiß ebenso.
- Gemischte Farben: `Color.accentColor` vs. `DesignSystem.accent`, hartcodiertes `.red` und `.green`.
- Jeder Klick auf „Plan berechnen“ legt einen neuen Verlaufseintrag an, auch bei Duplikaten.
- Info.plist-Berechtigungstexte gibt es nur auf Englisch (kein `InfoPlist.strings` für DE).
- Die Paywall-Taste „Pro in den Einstellungen ansehen“ ist redundant, weil man in der Paywall selbst kaufen kann.

---

## 6. App Store / Release-Blocker 🔴

1. **Datenschutz- und AGB-Links liefern 404** (`https://marcellomerico.github.io/FuelZone/privacy|terms`, am 03.10.2026 geprüft). GitHub Pages ist nicht aktiv bzw. der Pfad stimmt nicht (`docs/legal/privacy.md` → `/legal/privacy`).
2. **Die Paywall enthält keine Links zu Datenschutz und Nutzungsbedingungen** (Guideline 3.1.2 verlangt sie im Kaufbereich; aktuell nur in den Einstellungen).
3. `UIBackgroundModes: remote-notification` und `aps-environment` sind gesetzt, aber es gibt keine CloudKit-Subscriptions oder Push-Verarbeitung. Ungenutzte Capabilities führen gern zu Rückfragen im Review.
4. `PrivacyInfo.xcprivacy` deklariert keine gesammelten Daten. Standort (für Wetter an Open-Meteo gesendet), Fitness- und Gesundheitsdaten (Gewicht, HF) und Barcode-Abfragen sollten in den App-Privacy-Angaben auftauchen. Der Verlauf speichert zusätzlich Wetter-Koordinaten.
5. Die `FuelZone.storekit`-Datei ist nur lokal. Die Produkte müssen in App Store Connect existieren (laut Checkliste offen).

---

## 7. Kleinigkeiten 🔵

- `L10n.format` nutzt `Locale.current` statt der In-App-Sprache (Zahlenformat).
- `"\(Int(carbs))"` schneidet ab statt zu runden (Timeline-Ziele, z. B. 16,9 → 16).
- `totalFluidsMl` und `totalSodiumMg` sind Einzelwerte, alle anderen Größen Bereiche (inkonsistent).
- Fehlplatzierter Doc-Kommentar: „Keeps zone minutes aligned…“ steht über `applyWeather` ([SessionViewModel.swift:71](../NutritionApp/ViewModels/SessionViewModel.swift)).
- `MARKETING_VERSION` und `CURRENT_PROJECT_VERSION` stehen auf 1.0 / 1. Das Test-Target hat `TARGETED_DEVICE_FAMILY = "1,2"`, die App nur iPhone.
- Uncommittete Änderungen auf dem Branch sind überwiegend Formatierung (swift-format). Die eigentliche Änderung ist `ProfileView`: `ScrollView` statt `FuelZoneScreenScroll`, plus `scrollBounceBehavior` und Layout-Fixes der Zonen-Zeilen. Sie sieht vollständig aus und baut.
- `.vscode/` (SweetPad-Config) ist ungetrackt; sollte entweder in `.gitignore` oder bewusst committet werden.

---

## 8. Neu angelegte Tests (nur hinzugefügt, kein Produktionscode geändert)

| Datei | Zweck |
|---|---|
| `NutritionAppTests/CodeReviewFindingsTests.swift` | 10 Tests. Sie prüfen das **korrekte** Verhalten, ein roter Test bedeutet also einen bestätigten Bug. Ergebnis: **8 rot** (K1 ×2, B1, B2, B5, B6, B12, B13), 2 grün |
| `NutritionAppUITests/CodeReviewUITests.swift` | 3 UI-Tests: Onboarding wiederholen (rot, B3), deaktivierter Snack (rot, B1), Dezimalfeld „10,5“ (grün, kein Bug) |

Zwei Verdachtsfälle wurden **widerlegt**:
- `String(localized: "…")` nutzt korrekt die eigene `L10n`-Extension und damit die In-App-Sprache.
- Dezimaleingaben mit Komma in Textfeldern werden beim Tippen nicht verfälscht.

Die UI-Tests laufen nur mit einem Scheme, das `NutritionAppUITests` enthält. Für diesen Review lief das über ein temporäres User-Scheme, das danach wieder gelöscht wurde.

---

## 9. Empfohlene Reihenfolge

1. **K1** SnackComposer neu (mit Obergrenzen-Tests). Das ist das Kernversprechen der App.
2. **K4 + B-Verlauf** Pro-Status ableiten statt speichern, Verlauf nie physisch kürzen.
3. **K2/K3** Persistenz: KVS raus oder richtig konfigurieren; CloudKit mit Konfliktbehandlung (`savePolicy`, Modifikationsdatum) und Logging. Mittelfristig SwiftData + CloudKit erwägen.
4. **B1–B3, B7, B8, B9** schnelle Bugfixes mit sichtbarer Wirkung.
5. **Release-Blocker** aus Abschnitt 6 (Rechtslinks, Paywall-Links, Capabilities, Privacy).
6. Validierung (B5, B13, B14, B22), dann Aufräumen (toter Code, Duplikate), dann Accessibility (Dynamic Type, Labels).
7. Testinfrastruktur: veralteten Test fixen, Deployment Target des Test-Targets auf 17.0, UI-Tests ins Scheme.
