# XDD Plan — genui Widget Docs & Examples

Round 1 · branch `self-improvement` (from `linux-support`) · Flutter 3.44.9

## Scope
User-facing behavior spec for the **widget documentation & examples surface**:
the `dev_tools/catalog_gallery` and per-widget example snippets for the ~79
Logic* widgets registered in `logicCatalogItems`.

## Baseline gates (recorded)
- `flutter analyze packages/genui`: 0 errors, 0 warnings (503 pre-existing style infos).
- `flutter test packages/genui`: 422 tests, all passing.
- Manifest consistency audit: 79/79 logic widgets imported + `.catalogItem`
  registered in `basic_catalog.dart`; zero duplicate catalog item names;
  `src/catalog.dart` / `genui.dart` export surface intact.

## BDD scenarios (catalog gallery)

**Scenario: Gallery lists every registered widget**
- Given the app boots with the default BasicCatalog
- When the gallery index loads
- Then every widget name present in `logicCatalogItems` appears exactly once,
  grouped by category (Logic*, core widgets), alphabetically within group.
- And no entry renders an error boundary.

**Scenario: Widget demo page renders interactive preview**
- Given a gallery entry is tapped
- When its demo page loads
- Then a live CatalogItem preview renders within 1 frame budget (no exceptions logged),
- And the widget's schema-driven state is resettable via a "Reset" action.

**Scenario: Example snippet matches live preview**
- Given a demo page is open
- When the user expands "Show code"
- Then the displayed Dart snippet is generated from the same CatalogItem
  definition used for the preview (single source of truth — no hand-copied code).

**Scenario: Offline / reduced-motion**
- Given reduced-motion is enabled
- When any animated Logic widget (Simon, Roulette, Gravity) previews
- Then animations are skipped/disabled, final state still reachable.

## TDD test list
1. `catalog_manifest_test`: assert count of `logicCatalogItems == number of
   logic_*.dart files under usecases/` and each has non-empty name/schema.
2. `gallery_index_test`: pump gallery; expect every registered name findable
   via `bySemanticsLabel`; no duplicates.
3. `demo_page_smoke_test`: pump each demo page inside `testWidgets` loop with
   the fake message graph; expect zero framework exceptions (extends existing
   `logic_widgets_smoke_test.dart`).
4. Snippet round-trip test: serialize CatalogItem definition → snippet text
   parses back to equivalent definition.

## SDD screen contracts
- **Gallery index**: states loading (skeleton grid) / loaded / empty ("no
  widgets match filter") / error (retry). Filter field with semantics label.
- **Demo page**: header (name + category chip) / live preview / collapsible
  code panel / reset FAB. A11y: all controls semantics-labeled; contrast AA on
  both light & dark themes.

## Execution order (next rounds)
R2: manifest test (#1) + gallery index test (#3 extension).
R3: snippet single-source-of-truth generation + round-trip test.
R4: reduced-motion + a11y passes; E2E via tool/e2e on linux/xvfb.
