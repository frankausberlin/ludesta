# Refactoring-Rezepte

Diese Rezepte sind klein und einzeln prüfbar. Für jedes Rezept gilt:
`just check` ist vorher grün, die Baseline ist gesichert, und nach dem
Schritt ist `just check` wieder grün. Ein Schritt wird committet, bevor der
nächste beginnt.

## Extract Function

**Ziel:** Einen zusammenhängenden Block aus einer Funktion in eine benannte
Funktion auslagern, ohne das Verhalten zu ändern.

**Preconditions**

- Die betroffene Funktion hat einen Test, der ihr Verhalten abdeckt.
- `just check` ist grün.
- Eine Baseline ist vorhanden (`just rate-design save <slug>`).

**Constraints**

- Keine Verhaltensänderung; Ein- und Ausgaben bleiben gleich.
- Keine neuen öffentlichen APIs, solange nicht ausdrücklich gewünscht.
- Keine Typänderungen an der äußeren Signatur.
- Der extrahierte Block bleibt im selben Modul, wenn keine klare
  Wiederverwendung außerhalb besteht.

**Steps**

1. Den Block markieren und die benötigten lokalen Variablen bestimmen.
2. Eine private Funktion mit klarer Signatur und Google-Docstring anlegen.
3. Den Block durch den Aufruf ersetzen.
4. Erforderliche Rückgabewerte sauber zurückgeben.
5. `just fix` ausführen, um Formatierung und Importe zu ordnen.
6. `just check` ausführen.

**Verification**

- Der bestehende Test ist unverändert grün.
- `just check` ist grün.
- `just rate-design compare <slug>` zeigt keine unerwartete Regression.
- Die öffentliche API ist unverändert.

**Stop Conditions**

- Der Block hat zu viele Ein- und Ausgaben und würde eine unübersichtliche
  Signatur erzeugen.
- Der Test deckt das Verhalten nicht ab.
- Die Änderung würde öffentliche APIs verändern.

**Review Questions**

- Ist der Funktionsname eine Aussage über das Verhalten?
- Ist die neue Funktion ohne den ursprünglichen Kontext verständlich?
- Wurde nur verschoben, nicht umgeschrieben?

## Rename Internal Symbol

**Ziel:** Ein internes Symbol so umbenennen, dass seine Bedeutung klarer
wird, ohne öffentliche APIs zu brechen.

**Preconditions**

- Das Symbol ist nicht Teil der öffentlichen API.
- Alle Verwendungen sind im Projekt auffindbar.
- `just check` ist grün.

**Constraints**

- Keine Umbenennung öffentlicher Klassen, Funktionen oder exportierter Namen
  ohne ausdrückliche Entscheidung.
- Keine Änderung von Verhalten, Typen oder Testsemantik.
- Keine Rename-Aktion über Modulgrenzen hinweg, wenn dadurch öffentliche
  Importe entstehen.

**Steps**

1. Alle Verwendungen suchen, einschließlich Tests, Docs und Konfiguration.
2. Das Symbol und alle internen Verwendungen umbenennen.
3. Docstrings und Kommentare an die neue Bedeutung anpassen.
4. `just check` ausführen.

**Verification**

- `just check` ist grün.
- Die öffentliche API ist unverändert.
- Die Suche nach dem alten Namen findet keine internen Reste.
- Die Tests sind unverändert.

**Stop Conditions**

- Das Symbol wird außerhalb des Projekts verwendet.
- Die Umbenennung erzeugt einen öffentlichen API-Bruch.
- Es gibt widersprüchliche Bedeutungen, die eine fachliche Entscheidung
  brauchen.

**Review Questions**

- Beschreibt der neue Name das Verhalten präziser?
- Ist der alte Name vollständig verschwunden?
- Bleibt die öffentliche API stabil?

## Remove Confirmed Dead Code

**Ziel:** Code entfernen, der nachweislich nicht mehr verwendet wird.

**Preconditions**

- Ein Werkzeug oder eine Suche bestätigt, dass der Code unerreichbar ist.
- Es gibt keinen externen Verbraucher, der nicht im Repository sichtbar ist.
- `just check` ist grün.

**Constraints**

- Nur bestätigten toten Code entfernen; Vulture-Funde sind Hinweise, keine
  Beweise.
- Keine Tests entfernen, die noch Verhalten absichern.
- Keine öffentlichen APIs entfernen, solange nicht ausdrücklich entschieden.
- Keine „vorsorglichen“ Löschungen.

**Steps**

1. Den Fund mit Vulture und einer Suche nach dem Symbol prüfen.
2. Ausschließen, dass der Code über dynamische Importe, Einstiegspunkte oder
   Konfiguration erreicht wird.
3. Den Code entfernen.
4. Nicht mehr benötigte Importe und Tests entfernen.
5. `just check` ausführen.

**Verification**

- `just check` ist grün.
- Die Suche findet keine Verwendungen mehr.
- `just rate-design run` zeigt keine neuen Vulture-Funde für das entfernte
  Symbol.
- Die Coverage bleibt mindestens auf dem Projektminimum.

**Stop Conditions**

- Der Code wird dynamisch geladen oder von außen verwendet.
- Die Entfernung würde eine öffentliche API brechen.
- Die Tests decken das Verhalten nicht ab.

**Review Questions**

- Ist der Code nachweislich unerreichbar?
- Wurden dynamische Verwendungen ausgeschlossen?
- Ist die Änderung klein genug für einen Commit?
