# FuelZone

**Versorgung, die zu deiner Einheit passt.**  
*Fuel that fits your session.*

FuelZone ist eine iOS-App für Ausdauersportler:innen, die Kohlenhydrate, Flüssigkeit und Natrium für eine geplante Trainingseinheit berechnet und als **Zeitplan mit Snack-Vorschlägen** darstellt.

---

## Features (MVP)

| Bereich | Funktion |
|--------|----------|
| **Onboarding** | Sportart, Magenempfindlichkeit, Schweißrate, Salzgehalt, optional Gewicht & Max-HF |
| **Einheit planen** | Dauer, Distanz+Pace oder Distanz+Zeit; einfache Intensität oder HR-Zonen (Pro) |
| **Berechnung** | g/kg/h nach Zonen, Flüssigkeit (Schweiß × Temperatur), Natrium (mg/L) |
| **Ergebnis** | Bereiche (z. B. 55–70 g/h), Timeline alle 20 Min., Snack-Plan |
| **Snacks** | 23 Standard-Produkte (Gels, Getränke, feste Nahrung, …) |
| **Verlauf** | Gespeicherte Pläne, Detailansicht |
| **Einstellungen** | Sprache (DE/EN), Hell/Dunkel/System, Pro-Toggle (Entwicklung) |
| **Sync** | Profil, Verlauf & Snacks über **iCloud Key-Value Store** (gleiche Apple-ID) |

### FuelZone Pro (geplant / teilweise vorbereitet)

- Herzfrequenz-Zonen-Modus  
- Barcode-Scan & eigene Snacks  
- Snacks in der Timeline tauschen  
- Unbegrenzter Verlauf  

> Im MVP kann Pro zum Testen unter **Einstellungen → FuelZone Pro** aktiviert werden. StoreKit folgt später.

---

## Anforderungen

- **Xcode** 15+ (empfohlen: aktuelle Version mit iOS 17 SDK)
- **iOS 17.0+** (nur iPhone)
- Apple-ID mit **iCloud** für Datensynchronisation
- Für Geräte-Build: Signing mit Bundle-ID `com.mmerico.FuelZone` und iCloud-Capability

---

## Installation & Start

```bash
git clone https://github.com/marcellomerico/FuelZone.git
cd FuelZone   # oder lokaler Ordner NutritionApp
open NutritionApp.xcodeproj
```

1. In Xcode: Target **NutritionApp** → **Signing & Capabilities** → Team wählen.  
2. Simulator wählen (z. B. iPhone 17 Pro) → **Run** (⌘R).  
3. Beim ersten Start erscheint das **Onboarding**, danach die drei Tabs: Plan · Verlauf · Einstellungen.

### Tests ausführen

```bash
xcodebuild test \
  -scheme NutritionApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Oder in Xcode: **Product → Test** (⌘U).  
Die Suite `FuelingCalculatorTests` deckt u. a. kurze Einheiten, 5h-Ultra, Zonen-Mix und Magen-Cap ab.

---

## Architektur

```
MVVM + reine Business-Logik (kein UI in FuelingCalculator)

NutritionApp/
├── Core/           FuelingCalculator, SnackComposer, Lokalisierung
├── Models/         Codable-Domain (UserProfile, SessionSetup, FuelingResult, …)
├── ViewModels/     @Published + ObservableObject
├── Views/          SwiftUI (Onboarding, Session, Results, Snacks, History, Settings)
├── Services/       DataStore (UserDefaults + NSUbiquitousKeyValueStore)
├── Resources/      DefaultSnacks.json
└── en.lproj / de.lproj   Localizable.strings
```

- **Kein SwiftData** – Persistenz über JSON in UserDefaults + iCloud KVS  
- **Lokalisierung:** alle UI-Texte über Keys in `Localizable.strings` (EN + DE)  
- **Design:** `DesignSystem.swift`, Akzentfarbe in `Assets.xcassets` (sportliches Blau)

---

## Kernalgorithmus (Kurzüberblick)

1. **Kohlenhydrate:** `Gewicht × g/kg/h` (einfach oder gewichteter Zonen-Mix) × Dauer-Faktor, begrenzt durch Magen-Cap (max. 90 g/h × Empfindlichkeit).  
2. **Flüssigkeit:** Schweißrate × Temperatur × Wetter.  
3. **Natrium:** Flüssigkeit (L/h) × Salz-Konzentration (mg/L).  
4. **Timeline:** Schritte à 20 Minuten; **SnackComposer** wählt greedily passende Standard-Snacks.

Details und Tests: `NutritionApp/Core/FuelingCalculator.swift`, `NutritionAppTests/FuelingCalculatorTests.swift`.

---

## Konfiguration

| Einstellung | Wert |
|-------------|------|
| Display Name | FuelZone |
| Bundle ID | `com.mmerico.FuelZone` |
| Min. iOS | 17.0 |
| Geräte | iPhone only |
| iCloud Container | `iCloud.com.mmerico.FuelZone` |

---

## Roadmap

- [ ] StoreKit-Abo (Pro)  
- [ ] Barcode-Scanner (Open Food Facts o. ä.)  
- [ ] Snack-Tausch-UI in der Timeline  
- [ ] HealthKit-Import (später)  
- [ ] Apple Watch Companion (später)  
- [ ] README / Screenshots im App Store  

---

## Haftung

FuelZone liefert **allgemeine Sporternährungs-Empfehlungen**, keine medizinische Beratung. Ziele und Zufuhr immer individuell anpassen.

---

## Autor

[Marcello Merico](https://github.com/marcellomerico) · Repository: [github.com/marcellomerico/FuelZone](https://github.com/marcellomerico/FuelZone)
