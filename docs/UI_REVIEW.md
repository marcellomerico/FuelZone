# FuelZone – UI/UX Review

**Datum:** 04.10.2026 · **Basis:** 116 Screenshots (alle Screens, Light + Dark, iPhone 17 Simulator, iOS 27), Quellcode `Design/` + `Views/`, gemessene WCAG-Kontraste
**Screenshots:** [docs/screenshots/ui-review/](screenshots/ui-review/) (jeweils links Light, rechts Dark)

Legende: 🔴 kritisch · 🟡 mittel · 🟢 klein

---

## 1. Gesamteindruck

FuelZone wirkt **aufgeräumt und modern**, vor allem im Dark Mode: Amber auf Schwarz hat Charakter und passt zum Thema „Energie“. Die Grundidee ist stark: Eine Einheit eingeben, darunter läuft live eine Vorschau mit g/h, Gels und Natrium mit.

Das größte Problem ist **nicht die Optik, sondern die Struktur**. Die App fühlt sich an wie ein langes Formular mit vielen gleich lauten Elementen:

- **Alles ist Amber.** Auf dem Plan-Screen sind gleichzeitig 7–8 Flächen voll orange: ausgewählte Segmente, „Apply weather“ und „Calculate plan“. Was ist hier die Hauptaktion? Das Auge findet keinen Einstieg.
- **Das Wichtigste liegt unten.** Der Button „Plan berechnen“ und im Ergebnis die Frage „Was esse ich wann?“ liegen jeweils erst nach mehrmaligem Scrollen.
- **Light Mode ist ein Nachgedanke.** Das Design-System heißt im Code wörtlich „Amber dark theme“. Im Light Mode fallen Amber-Texte und Nährwert-Pills auf **1,3–2,0 : 1 Kontrast** (Minimum laut WCAG: 4,5 : 1). Sie sind praktisch unlesbar.

**Kurzurteil:** Dark Mode 7/10, Light Mode 4/10, Bedienbarkeit (UX) 5/10. Die Basis ist gut, aber Informationsarchitektur, Hierarchie und Light-Mode-Farben brauchen einen Neuentwurf, kein Feintuning.

---

## 2. Screen für Screen

### 2.1 Onboarding (7 Schritte) – [Screenshot](screenshots/ui-review/onboarding-1.png)
| Befund | Schwere | Empfehlung |
|---|---|---|
| Der Willkommens-Screen sagt nicht, **was die App für mich tut**. Er besteht aus Icon, Titel und einer Zeile, darunter ist zwei Drittel leer. | 🟡 | Ein Hero mit Nutzenversprechen in 3 Punkten („Gramm pro Stunde statt Raten“, „Zeitplan mit deinen Snacks“, „Wetter & Schweiß berücksichtigt“) und einer Beispiel-Grafik der Timeline. |
| 7 Schritte, jeder Schritt ist eine kleine Karte oben auf einem leeren Screen. | 🟡 | Auf 4 Schritte kürzen: Willkommen → Sport → **„Dein Körper“** (Magen, Schweißmenge und Salz auf einer Seite) → Optional (Name, Gewicht, Max-HF, mit „Überspringen“). |
| Nicht gewählte Optionen sehen **deaktiviert** aus (grau auf grau). Die Auswahl erkennt man nur an einem kleinen Haken rechts. | 🟡 | Die gewählte Zeile bekommt einen Rahmen und einen getönten Hintergrund; jede Option eine kurze Erklärung („Hoch – Salzränder auf Kappe/Shirt“). |
| Beim ausgewählten Sport steht hellorange Schrift auf hellem Pfirsich-Hintergrund, im Light Mode kaum lesbar. | 🔴 | Den neuen `accentText`-Token verwenden (siehe Abschnitt 5). |
| Textfelder für Gewicht und Max-HF haben weder Platzhalter noch Einheit, und eine Hilfe zur Max-HF fehlt („Faustregel 220 − Alter“). | 🟢 | Platzhalter „z. B. 70“ plus ein Einheiten-Suffix im Feld. |
| „Back“ ist ein reiner Text-Link ohne Fläche. | 🟢 | Sekundärer Button-Stil. |

### 2.2 Plan-Screen (Herzstück) – [Screenshot](screenshots/ui-review/plan.png)
| Befund | Schwere | Empfehlung |
|---|---|---|
| **Langes Formular über ca. 3 Bildschirmhöhen.** Sport, Dauer, Intensität und Bedingungen sind gleich gewichtete Karten; der CTA kommt ganz unten. | 🔴 | Den CTA plus die Live-Vorschau als **feste Leiste über der Tab-Bar** anheften. Er ist dann immer sichtbar, und die Zahlen ändern sich live beim Schieben. |
| **Amber überall.** Jedes ausgewählte Segment ist voll orange, genau wie die Haupt-Buttons. Dadurch geht die Hierarchie verloren. | 🔴 | Ausgewählte Segmente **neutral** darstellen (weiße oder graue Pille auf grauer Spur, wie der iOS-Segmented-Control). Amber-Füllung **nur** für die eine Hauptaktion pro Screen. |
| Intensität hat zwei Segment-Reihen untereinander („Simple / HR-Zonen“, darunter „Easy / Moderate / Hard“). Es ist nicht klar, dass die zweite Reihe zur ersten gehört. | 🟡 | Moduswahl als kleiner Umschalter neben der Überschrift („Einfach ⇄ Zonen“), darunter nur die jeweilige Eingabe. |
| Der Bereich „Bedingungen“ ist der größte Block (Ort-Feld, „Wetter übernehmen“, GPS-Button, Temperatur, Bedingungen), obwohl er am wenigsten wichtig ist. | 🟡 | Standardmäßig **eingeklappt** als eine Zeile: „☀️ Mild · Trocken · Ändern“. GPS-Wetter mit einem Tipp; die manuelle Auswahl erst nach dem Aufklappen. |
| Die Dauer zeigt rechts zusätzlich „Duration“ in Grau, was den gewählten Segment-Wert nur wiederholt. | 🟢 | Entfernen. |
| Der Slider reicht nur von 30 bis 300 min, kurze und Ultra-Einheiten gehen nicht. | 🟡 | Stunden:Minuten-Picker oder Slider mit Schnellwahl-Chips (45′, 1 h, 1:30, 2 h, 3 h, 4 h+). |
| Die Sport-Kacheln stehen im 3+2-Raster mit Loch rechts unten. | 🟢 | Horizontale Chip-Reihe (scrollbar) oder ein 5er-Raster mit Icons. Auf dem Plan-Screen reicht ohnehin ein Chip mit dem Standard-Sport. |
| Der Titel der Vorschau-Karte („Your fueling plan“) ist im Light Mode hellorange auf Pfirsich und unlesbar. | 🔴 | Token-Fix. |
| Die Tab-Bar **schwebt ohne Blur-Material**; der Inhalt (Textfeld) ist darunter sichtbar und wirkt angeschnitten. | 🟡 | Native `TabView`. Ab iOS 26 bekommt man die Liquid-Glass-Tab-Bar gratis, inklusive Blur, Barrierefreiheit und Haptik. |

### 2.3 Ergebnis – [Screenshot](screenshots/ui-review/results.png)
| Befund | Schwere | Empfehlung |
|---|---|---|
| Der **erste Bildschirm besteht nur aus 3 großen Zielkarten**. Die eigentliche Antwort („Was esse ich wann?“) liegt darunter. | 🔴 | Die 3 Zielwerte in **eine kompakte Kachelreihe** (KH, Flüssigkeit, Natrium nebeneinander). Darunter sofort **„Packliste“** („5× Gel, 2× Flasche“) und die Timeline. |
| **Widersprüchliche Zahlen:** „Snack plan“ zeigt 76 g gesamt, gelistet sind aber 5× Maurten 320 + 5× Cola (≈ 575 g). Das zerstört Vertrauen. (Ursache ist Bug K1 aus dem Code-Review.) | 🔴 | Gesamtsummen aus den echten Snacks berechnen und **Soll vs. Ist** zeigen („52 g/h geplant · Ziel 47–55“). |
| Die Timeline besteht aus 5 fast identischen Karten, wobei jede Karte 4 Zeilen hat. | 🟡 | Kompakte Zeilen mit **Uhrzeit-Logik**: „0:20 · 1 Gel + 200 ml“. Zusammenfassen, wenn Schritte identisch sind („alle 20 min“). |
| „Min 0–20“ wirkt technisch, „17 g · 200 ml · 100 mg“ steht ohne Beschriftung da, „1.0×“ hat überflüssige Dezimalen. | 🟡 | „0:00–0:20“, Mini-Icons vor den Werten, „1 Gel“ statt „1.0× Maurten Gel 320“. |
| Timeline-Icons sind schwarz bzw. weiß, alle anderen Icons Amber, also inkonsistent. | 🟢 | Datenfarben (KH = Amber, Flüssigkeit = Blau, Natrium = Türkis) durchgängig verwenden. |
| Der Snack-Tausch ist nicht erkennbar; es gibt kein sichtbares Tausch-Symbol und keinen Hinweis. | 🟡 | Ein Tausch-Icon pro Snack-Zeile, als Free-User mit Pro-Badge. |
| Es gibt keinen Weg, den Plan **mitzunehmen** (teilen, Screenshot-Ansicht, Lock-Screen). | 🟢 | Später: Share-Sheet mit kompakter Bild-Karte; das steht auch auf der Roadmap. |

### 2.4 Verlauf – [Screenshot](screenshots/ui-review/history.png)
| Befund | Schwere | Empfehlung |
|---|---|---|
| **Bug:** Die Zeile zeigt „Running · · 90 min“, also einen doppelten Trenner (`history.duration` enthält schon „·“). | 🟡 | String fixen. |
| **Bug:** Die Detailansicht zeigt **keine Snacks** in der Timeline ([Screenshot](screenshots/ui-review/history-detail-snacks.png)). `SessionDetailViewModel.allSnacks` ist nicht `@Published` und wird erst in `onAppear` gesetzt, also rendert die View nicht neu. | 🔴 | Neuer Bug, gehört ins Code-Review (B24). |
| Die Liste ist sehr karg: Datum, Sport, g/h. Man kann Einheiten nicht unterscheiden (z. B. „Langer Lauf“ vs. „Intervalle“). | 🟡 | Titel bzw. Notiz pro Einheit, Gruppierung nach Woche, kleine Kennzahlen (Dauer, g/h, Wetter-Icon). |
| Kein Löschen und kein „Plan wiederverwenden“. | 🟡 | Swipe-Aktionen „Löschen“ und „Erneut planen“. |

### 2.5 Snack-Bibliothek – [Screenshot](screenshots/ui-review/snacks.png)
| Befund | Schwere | Empfehlung |
|---|---|---|
| **28 Snacks, alle mit eingeschaltetem Toggle.** Das Konzept „aktiviert = darf im Plan vorkommen“ erschließt sich nicht. Außerdem verschwindet ein ausgeschalteter Snack (Bug B1). | 🔴 | Umdenken zu **„Meine Snacks“** (was ich wirklich dabeihabe, standardmäßig 3–5 Favoriten) plus **„Katalog“** zum Hinzufügen. Das ist verständlicher und liefert bessere Pläne. |
| Die Nährwert-Pills sind im Light Mode **unlesbar** (1,3–1,8 : 1). | 🔴 | Token-Fix (Abschnitt 5). |
| Es gibt nur 4 Filter-Chips (Alle, Gels, Drinks, Solids); Elektrolyte und Sonstiges fehlen. | 🟢 | Alle Kategorien zeigen oder Suche hinzufügen. |
| Toggles haben kein Accessibility-Label; VoiceOver liest nur „Schalter“. | 🟡 | Label = Snackname. |
| Die Toolbar zeigt zwei Icons in einer Kapsel (Scanner, +); das + ist sehr dominant. | 🟢 | Ein „+“-Menü mit den Optionen „Manuell“ und „Barcode scannen“. |

### 2.6 Einstellungen – [Screenshot](screenshots/ui-review/settings.png)
| Befund | Schwere | Empfehlung |
|---|---|---|
| Die **Pro-Werbekarte dominiert** die Einstellungen (halber Screen, inklusive Rechtstext). | 🟡 | In den Einstellungen nur eine Zeile „FuelZone Pro · Aktiv/Upgrade ›“; Kauf und Rechtstext gehören in die Paywall. |
| „Onboarding wiederholen“ ist der **größte und lauteste Button** auf dem Screen, obwohl er die seltenste Aktion ist. | 🟡 | Als normale Listenzeile. |
| Sprache und Erscheinungsbild sind riesige Segment-Buttons in voller Amber-Farbe. | 🟢 | Native `Form`/`List` mit `Picker` (Menü-Stil). Das spart Platz und fühlt sich iOS-typisch an. |
| „Restore purchases“ ist hellorange auf Pfirsich und unsichtbar (Light). | 🔴 | Token-Fix. |
| Der Debug-Hinweis „For local testing: Xcode → …“ ist nur in Debug-Builds sichtbar. Das ist okay, sollte aber vor Release noch einmal geprüft werden. | 🟢 | – |

### 2.7 Paywall – [Screenshot](screenshots/ui-review/plan-paywall.png)
| Befund | Schwere | Empfehlung |
|---|---|---|
| Die Fehlermeldung „Plans not available“ steht **zweimal** da (als Banner und als Statustext). Dazu kommen „View Pro in Settings“ (sinnlos, man ist ja schon in der Paywall) und „Not now“. | 🟡 | Ein Fehlerzustand, eine Hauptaktion, ein „Später“. |
| Die Feature-Liste ist eine schmale Karte, die nicht die volle Breite nutzt. Die Feature-Icons sind auf **6 pt** geschrumpft und sehen aus wie Punkte bzw. Kreuze. | 🟡 | Volle Breite, Icons in 20–24 pt mit Farbe, pro Feature ein kurzer Nutzensatz. |
| Die Paywall startet im Medium-Detent; dabei ist der Kaufbereich abgeschnitten. | 🟡 | Vollbild oder `.large`; Preise und CTA ohne Scrollen sichtbar. |
| Links zu Datenschutz und AGB fehlen (App-Store-Pflicht, siehe Code-Review). | 🔴 | Fußzeile mit beiden Links. |

### 2.8 Profil – [Screenshot](screenshots/ui-review/profile.png)
| Befund | Schwere | Empfehlung |
|---|---|---|
| Der Screen ist **sehr lang**: 9 einzelne Auswahl-Zeilen für Magen, Schweiß und Salz, jeweils 3 Zeilen untereinander. | 🟡 | Je ein kompakter Segment- oder Menü-Picker pro Eigenschaft, also 3 Zeilen statt 9. |
| Gemischtes Speicherverhalten: Auswahl-Felder wirken sofort, Textfelder erst nach „Save profile“ (Bug B10). | 🟡 | Alles wird sofort gespeichert (iOS-Standard), ohne „Speichern“-Button. |
| Der „Large Title“ ist nur hier und in der Methodik groß, alle anderen Titel sind „inline“. | 🟢 | Einheitlich: Root-Screens mit Large Title, Unterseiten inline. |

### 2.9 Wissenschaft & Methodik – [Screenshot](screenshots/ui-review/methodology.png)
Der stärkste Screen der App: verständlich, gut gegliedert, mit Quellen. Kleinigkeiten: Fließtext in 14 pt Grau ist für lange Texte anstrengend (lieber 15–17 pt in Primärfarbe). Die Stufen-Karten (30/60/90 g/h) könnten als **visuelle Skala** dargestellt werden.

---

## 3. Visuelle Hierarchie

- **Was das Auge zuerst sieht:** die vielen Amber-Flächen, nicht die Hauptaktion oder das Ergebnis. ❌
- **Lesefluss:** Er verläuft gleichförmig von oben nach unten durch gleich große Karten; es gibt keine Kapitel und keine „Hero“-Zahl. Nur die Live-Vorschau (51 g · ≈2 · 300 mg) hat echtes Gewicht, und die liegt ganz unten.
- **Typografie:** Alles in `.medium` mit 11–15 pt, nur Metriken größer. Überschriften (15 pt) und Fließtext (14 pt) unterscheiden sich kaum. Captions mit **12 pt in Grau** tragen viel Information (Untertitel, Erklärungen) und sind zu klein.
- **Weißraum:** Kartenabstände (14 pt) und Innenabstände (14 pt) sind identisch, dadurch verschwimmen die Gruppen. Karten liegen teils in Karten (Paywall, Pro-Card mit Banner).

---

## 4. Konsistenz

| Element | Problem | Empfehlung |
|---|---|---|
| Farben | `Color.accentColor` und `DesignSystem.accent` werden gemischt; `.red`, `.green` und `.orange` sind hartcodiert; Timeline-Icons schwarz, sonst Amber. | Nur semantische Tokens (siehe 5). |
| Eckenradien | 6, 8, 9, 10, 11, 12, 14, 16, 24 pt, also neun verschiedene Werte. | Drei Stufen: 10 (Controls), 16 (Karten), 24 (Sheets/Tab-Bar). |
| Buttons | 5 Stile: PrimaryButtonStyle, eigener Plan-CTA, Text-Link, Pillen-Button „Apply weather“, Kreis-Icon. | Drei Stile: Primary (gefüllt), Secondary (getönt), Tertiary (Text). |
| Titel | Large vs. Inline ohne Regel. | Root = Large, Detail = Inline. |
| Icons | Unterschiedliche Tausch-Icons (`arrow.triangle.2.circlepath` vs. `arrow.triangle.swap`), Feature-Icons auf 6 pt. | Ein Icon-Set, feste Größen. |
| Ergebnis vs. Verlauf | Zwei fast gleiche Screens, die schon auseinanderlaufen. | Eine gemeinsame `PlanView`-Komponente. |
| Sprache | „Plan session“, „Your fueling plan“, „Calculate plan“ und „Results“ werden für dasselbe Konzept verwendet. | Ein Begriff („Plan“) durchgängig. |

---

## 5. Accessibility & Kontrast (gemessen, WCAG 2.1)

| Element | Light | Dark | Soll |
|---|---|---|---|
| Amber-Text auf Karte (Links, „Back“, Titel) | **2,0 : 1** ❌ | 8,5 : 1 ✅ | ≥ 4,5 |
| KH-Pill (hell) | **1,3 : 1** ❌ | 7,9 : 1 ✅ | ≥ 4,5 |
| KH-Pill (mittel) | **1,7 : 1** ❌ | – | ≥ 4,5 |
| Natrium-Pill | **1,8 : 1** ❌ | 6,5 : 1 ✅ | ≥ 4,5 |
| Warn-Icon `accentLight` auf Weiß | **1,6 : 1** ❌ | – | ≥ 3,0 |
| Tertiärtext (Rechtstext, Hinweise) | **1,7 : 1** ❌ | – | ≥ 4,5 |
| Dunkle Schrift auf Amber-Button | 6,5 : 1 ✅ | 6,5 : 1 ✅ | ≥ 4,5 |
| Weiße Schrift auf Amber | 2,2 : 1 ❌ (wird zum Glück nicht genutzt) | | |

Weitere Punkte:
- **Kein Dynamic Type:** Alle Schriften haben feste Größen (`Font.system(size:)`). Nutzer mit größerer Systemschrift bekommen nichts davon.
- **Touch-Ziele:** Die Filter-Chips (ca. 28 pt hoch), „Back“ als reiner Text und der Paywall-Schließen-Button liegen unter **44 pt**.
- **VoiceOver:** Toggles, Stepper und Textfelder haben keine Labels; eigene Tab-Bar und Segmente melden keinen „ausgewählt“-Zustand.
- **Launch-Screen** ist im Light Mode schwarz, dadurch gibt es beim Start einen harten Schwarz-Weiß-Blitz.

---

## 6. Was gut funktioniert ✅

- **Live-Vorschau** während der Eingabe (g/h · Gels · Natrium) ist ein echtes Alleinstellungsmerkmal.
- **Dark Mode** ist stimmig, kontraststark und hat eine eigene Identität (Amber/Schwarz).
- **Ranges statt Scheingenauigkeit** („47–55 g“) wirken ehrlich und wissenschaftlich.
- **Methodik-Seite mit Quellen** schafft Vertrauen; wenige Konkurrenten haben das.
- Die **Snack-Datenbank** mit echten Markenprodukten (Maurten, SiS, PF 30) spricht die Zielgruppe direkt an.
- Durchgängige Karten-Sprache und abgerundete Formen: Die Basis für ein sauberes System ist da.

---

## 7. Vorschlag: neues UI-Konzept

### 7.1 Leitprinzipien
1. **Eine Hauptaktion pro Screen.** Nur sie ist Amber-gefüllt; alles andere ist neutral.
2. **Ergebnis vor Eingabe.** Live-Vorschau und Plan stehen im Zentrum, Formulare treten in den Hintergrund.
3. **Progressive Disclosure.** Die Standardwerte sind gut, Details sind aufklappbar (Wetter, Zonen, Profil).
4. **iOS-nativ, wo möglich.** `TabView`, `List`/`Form`, Segmented `Picker`, Sheets mit Detents. Light/Dark, Dynamic Type, VoiceOver und Liquid Glass kommen so automatisch mit.
5. **Daten haben Farben.** KH = Amber, Flüssigkeit = Blau, Natrium = Türkis, überall gleich.

### 7.2 Farb-Tokens (Light + Dark, Kontrast geprüft)

Basis sind die iOS-System-Farben für Flächen und Text, nur die Akzente sind eigene Farben:

| Token | Light | Dark | Verwendung | Kontrast L / D |
|---|---|---|---|---|
| `background` | System Grouped (#F2F2F7) | Schwarz (#000000) | Screen-Hintergrund | – |
| `surface` | Weiß (#FFFFFF) | #1C1C1E | Karten | – |
| `textPrimary/Secondary` | System `label`/`secondaryLabel` | System | Text | 5,2 / 5,9 ✅ |
| `accentFill` | **#F29A1F** | **#FFB340** | Haupt-Button, aktive Tab | – |
| `onAccent` | #3A2200 | #2B1700 | Text auf Amber | 6,7 / 9,6 ✅ |
| `accentText` | **#A35A00** | **#FFC266** | Links, Amber-Text, Auswahl-Label | 5,2 / 10,7 ✅ |
| `carbs` (Daten) | Text #A35A00 auf 14 % Amber | Text #FFC266 auf 18 % | KH-Werte, Pills | 4,7 / 7,2 ✅ |
| `fluids` (Daten) | Text #0B63C4 auf 12 % Blau | Text #64B5FF auf 18 % | Flüssigkeit | 5,0 / 6,3 ✅ |
| `sodium` (Daten) | Text #0B7069 auf 14 % Türkis | Text #5FD4CB auf 18 % | Natrium | 5,2 / 7,1 ✅ |
| `selection` | Weiß auf Systemgrau-Spur | #3A3A3C auf #1C1C1E | Ausgewählte Segmente (neutral!) | – |
| `warning/success` | System Orange/Grün | System | Banner | – |

Das wichtigste Prinzip: Es gibt **zwei Amber-Töne pro Modus**, einen zum Füllen (hell, mit dunkler Schrift) und einen für Text (im Light Mode dunkel). Das alte `accentLight` verschwindet aus dem Light Mode.

### 7.3 Typografie
SF Pro über **Text Styles** (`.largeTitle`, `.title2`, `.headline`, `.body`, `.subheadline`, `.footnote`) statt fester Größen, damit Dynamic Type automatisch funktioniert. Kennzahlen in `.rounded` + `monospacedDigit` (z. B. 34 pt für „52 g/h“). Fließtext nicht kleiner als `.subheadline` (15 pt).

### 7.4 Neue Screen-Struktur (Konzept)

```
Tab „Plan“                          Tab „Plan“ → Ergebnis
┌────────────────────────────┐      ┌────────────────────────────┐
│ Plan            [Profil ⓘ] │      │ ‹  Langer Lauf · 1:30      │
│ [🏃 Laufen ▾]              │      │ ┌──────┬──────┬──────┐     │
│                            │      │ │ 52   │ 600  │ 300  │     │
│ Dauer         1 h 30 min   │      │ │ g/h  │ ml/h │ mg/h │     │
│ ●━━━━━━━○──────────        │      │ └──────┴──────┴──────┘     │
│ [45′][1h][1:30][2h][3h+]   │      │ Packliste                  │
│                            │      │  ⚡ 3× Maurten 160          │
│ Intensität   Einfach ⇄ Zonen│     │  💧 1× Iso 500 ml           │
│ [ Locker | Mittel | Hart ] │      │ Zeitplan                   │
│                            │      │ 0:20  ⚡1 Gel   💧150 ml  ⇄ │
│ ☀️ 18° Mild · Trocken  ›   │      │ 0:40  💧150 ml           ⇄ │
│                            │      │ 1:00  ⚡1 Gel   💧150 ml  ⇄ │
├────────────────────────────┤      │ …                          │
│ 52 g/h · ≈3 Gels · 300 mg  │      │ [ Teilen ]   [ Gespeichert✓]│
│ [      Plan erstellen     ]│      └────────────────────────────┘
└────────────────────────────┘
   (feste Leiste über Tab-Bar)
```

- **Plan:** Sport als Chip-Menü, Dauer mit Schnellwahl, Intensität mit kleinem Modus-Schalter, Wetter als eine einklappbare Zeile. Unten eine feste Leiste mit Live-Vorschau und dem einzigen Amber-Button.
- **Ergebnis:** Kennzahlen-Reihe in Datenfarben, **Packliste**, kompakter Zeitplan mit Uhrzeiten, Tausch-Icon pro Zeile, Teilen.
- **Snacks:** „Meine Snacks“ (Favoriten, die im Plan genutzt werden) plus Katalog mit Suche; Nährwert-Pills in Datenfarben.
- **Verlauf:** Liste mit Titel, Kennzahlen und Swipe-Aktionen (Löschen, Erneut planen).
- **Einstellungen:** native gruppierte Liste mit Zeilen für Profil, Pro, Sprache, Darstellung, iCloud, Rechtliches und Onboarding.
- **Onboarding:** 4 Schritte, Nutzen-Hero am Anfang, Profil-Schritt optional.
- **Tab-Bar:** native `TabView` (Liquid Glass ab iOS 26, klassisch auf iOS 17/18).

---

## 8. Prioritäten

1. **Farb-Tokens für Light Mode neu** (Abschnitt 7.2). Das ist der größte sichtbare Gewinn bei wenig Aufwand und behebt alle Kontrast-Fehler.
2. **Hierarchie:** Amber nur noch für die Hauptaktion, ausgewählte Segmente neutral, CTA-Leiste mit Live-Vorschau fest unten.
3. **Ergebnis-Screen neu:** kompakte Kennzahlen, Packliste, Zeitplan mit Uhrzeiten (zusammen mit dem SnackComposer-Fix K1).
4. **Native Bausteine:** `TabView`, `List`/`Form` in Einstellungen und Profil, Dynamic Type über Text Styles.
5. **Snack-Konzept** „Meine Snacks + Katalog“, **Onboarding** auf 4 Schritte.
6. Feinschliff: Radien, Button-Stile, Icons, Accessibility-Labels, Launch-Screen.
