# Flüssigkeit & Natrium – wissenschaftliche Analyse

**Stand:** 04.10.2026 · **Frage:** Sollte sich die empfohlene Flüssigkeitsmenge mit der Intensität ändern?

## Kurzantwort

**Ja.** Die Schweißrate wird in erster Linie von der **Wärmeproduktion** bestimmt, und die steigt mit der Intensität (und der Körpergröße). Hitze, Luftfeuchte und Wind kommen hinzu. Vorher hat FuelZone die Intensität ignoriert: Leicht, Mittel und Hart ergaben bei gleichem Wetter dieselben 600 ml/h. Das ist jetzt korrigiert. Gleichzeitig wird die Trinkmenge **gedeckelt**, weil zu viel Trinken genauso riskant ist wie zu wenig.

## Was die Forschung sagt

| Befund | Quelle |
|---|---|
| Die Schweißrate folgt dem **Verdunstungsbedarf für das Wärmegleichgewicht**, also Wärmeproduktion (Intensität × Körpermasse) minus Wärmeabgabe an die Umgebung. Dieser Wert sagt die Schweißrate besser voraus als die relative Belastung allein. | [Gagnon, Jay & Kenny 2013, J Physiol](https://pmc.ncbi.nlm.nih.gov/articles/PMC3690695/) |
| Schweißraten liegen je nach Intensität, Dauer, Fitness, Hitzeakklimatisierung, Kleidung und Umgebung bei **≈ 0,3–2,4 l/h**. Individuelle Pläne werden empfohlen; die Schweißrate lässt sich über Wiegen vor und nach dem Training bestimmen. | [ACSM Position Stand, Sawka et al. 2007](https://pubmed.ncbi.nlm.nih.gov/17277604/) |
| Als Trinkmenge werden meist **0,4–0,8 l/h** genannt: weniger für leichtere, langsamere Athlet:innen in kühler Umgebung, mehr für größere, schnellere in der Wärme. Ziel ist, den Gewichtsverlust auf < 2 % zu begrenzen, nicht 100 % zu ersetzen. | ACSM 2007; [Joint Position Statement Nutrition & Athletic Performance 2016](https://pubmed.ncbi.nlm.nih.gov/26917108/) |
| **Mehr zu trinken, als man ausschwitzt**, ist die Hauptursache der belastungsassoziierten **Hyponatriämie** (zu wenig Natrium im Blut). Empfohlen wird, nach Durst zu trinken, statt nach festen hohen Mengen. | [Hew-Butler et al. 2015, 3. EAH-Konsensus, BJSM](https://bjsm.bmj.com/content/49/22/1432) |

## Neues Modell in FuelZone

```
Flüssigkeit (ml/h) = Schweißprofil × Temperatur × Wetter × Intensität × Körpergewicht
                     begrenzt auf 300 – 1000 ml/h, gerundet auf 10 ml
Natrium (mg/h)     = Flüssigkeit (l/h) × Salzgehalt des Schweißes (300 / 500 / 700 mg/l)
```

| Faktor | Werte |
|---|---|
| Schweißprofil | niedrig 400 · mittel 600 · hoch 800 ml/h |
| Temperatur | kühl 0,9 · mild 1,0 · warm 1,15 · heiß 1,3 |
| Wetter | trocken 1,0 · feucht 1,05 · windig 1,1 |
| **Intensität (neu)** | leicht 0,85 · mittel 1,0 · hart 1,15 · Zonen gewichtet: Z1 0,8 · Z2 0,9 · Z3 1,0 · Z4 1,1 · Z5 1,2 |
| **Körpergewicht (neu)** | √(Gewicht / 70 kg), begrenzt auf 0,9–1,1 (ohne Angabe 1,0) |
| **Obergrenze (neu)** | 1000 ml/h, mit Hinweis „trink nach Durst, wieg dich vor/nach dem Training“ |

Die Faktoren sind bewusst moderat. Die Intensität verändert die Wärmeproduktion zwar deutlich stärker, aber die **Trinkempfehlung** soll Verluste nur teilweise ersetzen und innerhalb der 0,4–0,8-l/h-Spanne bleiben, die für die meisten gilt.

## Vorher / nachher (Beispiele)

| Profil · Bedingungen · Intensität | Vorher | Nachher |
|---|---|---|
| mittel · mild/trocken · leicht | 600 | **510** |
| mittel · mild/trocken · mittel | 600 | **600** |
| mittel · mild/trocken · hart | 600 | **690** |
| mittel · heiß/feucht · hart | 819 | **940** |
| hoch · heiß/windig · hart · 90 kg | 1144 | **1000** (+ Hinweis) |
| niedrig · kühl · leicht · 55 kg | 360 | **300** |
| mittel · warm · mittel · 85 kg | 690 | **760** |

Natrium ändert sich automatisch mit, weil es an die Flüssigkeit gekoppelt ist.

## Grenzen & nächste Schritte

- Das Modell schätzt. Am genauesten ist eine **gemessene Schweißrate**: Gewicht vor und nach einer Stunde Training plus getrunkene Menge. Ein Eingabefeld „gemessene Schweißrate“ im Profil wäre ein sinnvoller nächster Schritt.
- Der Salzgehalt des Schweißes variiert sehr stark (≈ 200–2000 mg/l). Die drei Stufen sind eine grobe Selbsteinschätzung; ein Schweißtest wäre genauer.
- Hitzeakklimatisierung und Trainingszustand erhöhen die Schweißrate und werden nicht abgefragt.

Code: [`Core/FluidGuidelines.swift`](../NutritionApp/Core/FluidGuidelines.swift) · Tests: [`FluidGuidelinesTests`](../NutritionAppTests/FluidGuidelinesTests.swift)
