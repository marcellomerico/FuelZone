# FuelZone – Checkliste bis App Store (ohne / mit 99 €)

## ✅ Erledigt im Code (ohne Apple-Gebühr)

- [x] Amber-UI, schwebende Tab-Bar, App-Icon
- [x] Monats- & Jahresabo (StoreKit lokal: `FuelZone.storekit`, 3,99 € / 24,99 €)
- [x] Snack-Tausch im **Verlauf** wird gespeichert
- [x] Plan-Validierung vor Berechnung
- [x] Datenschutz- & AGB-Texte in `docs/legal/` + Links in Einstellungen
- [x] Launch Screen (schwarz)

## 🔶 Wenn du die 99 € hast (Apple Developer Program)

1. [developer.apple.com/programs/enroll](https://developer.apple.com/programs/enroll/) – **99 USD/Jahr**
2. **App Store Connect** → App anlegen → Verträge (Paid Apps) + Bank + Steuern
3. Abos anlegen: `com.mmerico.FuelZone.pro.monthly` (3,99 €), `com.mmerico.FuelZone.pro.yearly` (24,99 €)
4. **Small Business Program** (< 1 Mio. $/Jahr) → 15 % Provision
5. **GitHub Pages** für Datenschutz/AGB aktivieren (siehe unten)
6. TestFlight → Screenshots → Einreichung

## GitHub Pages (kostenlos, vor Einreichung)

1. Repo `FuelZone` auf GitHub  
2. `docs/legal/privacy.md` & `terms.md` nach `docs/` kopieren oder Jekyll  
3. Settings → Pages → Branch `main`, Folder `/docs`  
4. URLs prüfen:  
   - `https://marcellomerico.github.io/FuelZone/privacy`  
   - `https://marcellomerico.github.io/FuelZone/terms`  
5. Falls andere URL → `AppLegalLinks.swift` anpassen

## Optional danach

- [ ] Timeline teilen (PDF)
- [ ] HealthKit / Strava
- [ ] App Store Screenshots & Promo-Text
