# FuelZone — Produkt-Roadmap & Differenzierung

Stand: Mai 2026 · Zielgruppe: Ausdauersportler (Laufen, Rad, Triathlon, Wandern)

## Was FuelZone heute schon kann

- **Evidenzbasierte KH-Ziele** (30 / 60 / 90 g/h nach Dauer, Intensität, Magen) mit Methodik-Seite und Quellen
- **Session-Planung**: Dauer, Distanz+Pace, Distanz+Zeit, einfache Intensität oder HF-Zonen in **Minuten**
- **Timeline** mit Snack-Vorschlägen, Tausch (Pro), Bibliothek + Barcode (Pro)
- **Flüssigkeit & Natrium** aus Schweiß/Temperatur/Wetter
- **Verlauf**, iCloud-Sync, EN/DE, Freemium (Pro: Zonen, Barcode, Tausch, unbegrenzter Verlauf)

---

## Wettbewerb (Kurzüberblick)

| Produkt | Fokus | Stärke | Schwäche vs. FuelZone |
|--------|--------|--------|------------------------|
| **MAVR** | Ganztägige Ernährung + Training-Sync | Strava/TP/Garmin, KI-Makros, Renntag | Weniger „eine Einheit, ein klarer Fuel-Plan“; Abo-lastig |
| **Cadence Fuel** | Tages-Makros + Ride Mode | Live-Tracking am Lock Screen, Coach-Dashboard | Early Access; weniger HF-Zonen-Minuten-Planung |
| **Endurance Fuel Planner** (Web) | Detaillierter Rechner | Flaschen/Gel-Math, Schweiß | Keine native App, weniger UX |
| **Fuel The Win** | Logging + Training Load | Viele Integrationen, Chat-Logging | General Nutrition, nicht session-first |
| **Generische Rechner** (Blogs, Excel) | g/kg oder fixe Tabellen | Schnell | Oft veraltet (g/kg), keine Snack-Timeline |

---

## Abhebung: Warum FuelZone?

1. **Session-first, nicht Kalorien-App** — Eine Einheit eingeben → sofort KH/Flüssig/Na-Timeline mit Snacks, ohne Wochen-Tracking-Zwang.
2. **Wissenschaft transparent** — Methodik in verständlicher Sprache + Links zu Jeukendrup/Burke (nicht nur eine Zahl ohne Herkunft).
3. **HF-Zonen in Minuten** — Praxisnah („20 Min. in Zone 2“), nicht Prozent-Rechnerei.
4. **Absolute g/h** — Entspricht aktueller Sportmedizin, nicht veraltetem g/kg während der Belastung.
5. **Snack-Bibliothek + Tausch** — Plan ist anpassbar, nicht nur PDF-Tabelle.
6. **iCloud für alle** — Sync nicht hinter Pro (Vertrauen / Wechsel zwischen Geräten).

**Positionierung (Vorschlag):**  
*„Der klare Fuel-Plan für deine nächste Ausdauereinheit — wissenschaftlich fundiert, in Minuten und Gramm, nicht in Excel.“*

---

## Nächste Schritte (priorisiert)

### Kurzfristig (Kleinigkeiten, wie besprochen)

- [ ] **Pro-Paywall bei HF-Zonen**: StoreKit-Kauf direkt in der Paywall, nicht Debug-Toggle in Einstellungen
- [ ] App Store-Produkt + StoreKit-Config im Scheme verknüpfen
- [ ] App-Icon, Launch Screen, Display Name „FuelZone“ in Xcode
- [ ] Verlauf: getauschte Snacks dauerhaft im gespeicherten Plan

### Mittelfristig (UX & Vertrauen)

- [ ] **Live-Aktivität / Lock Screen** (Cadence-ähnlich) — Stunde-für-Stunde-Ziel während der Einheit
- [ ] Export: Timeline als PDF oder Teilen für Wettkampf
- [ ] „Gut trainierter Darm“-Hinweis / optional höheres Cap für tolerante Nutzer
- [ ] Snack-Mix-Hinweis: 2:1 Glucose:Fructose bei >2,5 h visuell in der Timeline
- [ ] Onboarding verkürzen / optional überspringen für Wiederkehrer

### Mittelfristig (Daten & Integration)

- [ ] **Garmin / Apple Health / Strava** — Dauer & HF-Zonen aus letzter Aktivität vorausfüllen (großer Differenzierer vs. statische Rechner)
- [ ] TrainingPeaks- oder Kalender-Import für geplante Workouts
- [ ] CloudKit-Schema in Production deployen

### Langfristig (Produkt)

- [ ] Renntag-Modus (Carb-Loading-Hinweis 48 h vorher — separat von In-Race)
- [ ] Team-/Coach-Ansicht (Cadence hat das; für Vereine interessant)
- [ ] Android-Version nur wenn iOS PMF steht

---

## Was bewusst *nicht* kopieren sollten

- Vollwertiges **Kalorien-Tracking** (MAVR/FTW) — verwässert die Session-Klarheit
- **g/kg während Exercise** als Hauptlogik — wissenschaftlich überholt für KH/h
- Zu viele **Pro-Features hinter Paywall** für Basis-Sicherheit (iCloud bleibt frei)

---

## Qualität & Release

- [ ] TestFlight mit 5–10 Ausdauersportlern (Marathon, Gran Fondo, Trail)
- [ ] App Store Screenshots: Plan → Ergebnis → Timeline → Methodik
- [ ] Datenschutz / Health-Daten (wenn Integrationen kommen)
- [ ] README + GitHub für Open-Source-Teile (Calculator testbar)

---

## Offene Fragen an dich

1. Primär **DE** oder **international** launch?
2. Pro-Preis: monatlich nur oder auch jährlich/Lifetime?
3. Soll die App **offline-first** ohne Account bleiben (nur iCloud Apple-ID)?
