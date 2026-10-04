# FuelZone – Checkliste bis zum App Store

Stand: 04.10.2026 (nach dem Redesign „Race Instrument“)

## ✅ Im Code erledigt

- [x] Redesign Light/Dark, Dynamic Type, VoiceOver-Labels, native Tab-Bar
- [x] Snack-Planer trifft die Ziele (Packliste, Fuel Track, Soll vs. Ist)
- [x] iCloud-Sync über CloudKit (private DB), Migration alter Daten
- [x] Pro-Status nur aus StoreKit, Paywall mit Rechtslinks und Abo-Hinweis
- [x] Datenschutz & Nutzungsbedingungen (DE/EN) in `docs/privacy.md`, `docs/terms.md`
- [x] Privacy Manifest (UserDefaults, ungefährer Standort), Berechtigungstexte DE/EN
- [x] Keine ungenutzten Capabilities (Push entfernt)
- [x] Unit- und UI-Tests grün

## 🔶 Deine Schritte

1. **GitHub Pages aktivieren**: Repo → *Settings → Pages* → Branch `main`, Ordner `/docs`. Danach prüfen:
   - https://marcellomerico.github.io/FuelZone/privacy/
   - https://marcellomerico.github.io/FuelZone/terms/
2. **Apple Developer Program** (99 USD/Jahr), **App Store Connect**: App anlegen, Verträge, Bank, Steuern, ggf. *Small Business Program* (15 %).
3. **Abos anlegen** in einer Gruppe „FuelZone Pro“:
   `com.mmerico.FuelZone.pro.monthly` (3,99 €), `com.mmerico.FuelZone.pro.yearly` (24,99 €), Lokalisierungen DE/EN.
4. **CloudKit-Schema** in der CloudKit-Konsole von *Development* nach *Production* deployen (Record Type `FuelZoneItem`, Zone `FuelZone`), sobald ein Debug-Build einmal synchronisiert hat.
5. **Support-Adresse** `support@fuelzone.app` einrichten (oder in `AppLegalLinks.swift` ändern).
6. **App-Privacy-Angaben** in App Store Connect: *Standort (ungefähr) – App-Funktionalität, nicht verknüpft, kein Tracking*. Sonst keine Datenerhebung.
7. **Test auf echtem iPhone** (iCloud-Sync zwischen zwei Geräten, Kauf mit Sandbox-Account, Barcode-Scan, Standort).
8. **TestFlight** → Screenshots (6,9″ und 6,5″) → Einreichung.

## Optional danach

- [ ] Teilen als Bild (Fuel-Track-Karte), Widget/Lock-Screen-Plan
- [ ] HealthKit / Strava / Garmin (Einheiten vorausfüllen)
- [ ] App-Store-Texte und Promo-Material
