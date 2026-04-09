# Finance UI Duplication Report

Updated: 2026-04-09
Scope: only `lib/screens/finance` module

## 0) Refactor Progress Tracker

Status snapshot: 2026-04-09 (wave 14)

- [x] AppBar unification completed: finance screens now share one strict appbar component (`FinanceGradientAppBar`).
- [x] `FinanceSheetScaffold` extracted and adopted module-wide.
  - Current usage count: 23 callsites (plus 1 component definition).
  - Migrated files: `finance_transaction_entry_screen.dart`, `finance_category_manager_screen.dart`, `finance_classify_transactions_screen.dart`, `finance_module_screen.dart`, `finance_recurring_flow_screens.dart`, `finance_budget_screens.dart`, `finance_screen.dart`.
  - Additional wave 12 migrations: overview add-action sheet + quick add-transaction sheet now use shared scaffold.
- [x] Category display/picker baseline unified.
  - Chosen standard: quick category tile from transaction entry.
  - New shared components: `FinanceCategoryChoiceTile` + `FinanceCategoryGroupCard`.
  - Migrated usage: quick selectors in `finance_transaction_entry_screen.dart` + `finance_recurring_flow_screens.dart`; classify income grid in `finance_classify_transactions_screen.dart`.
  - `finance_classify_transactions_screen.dart` now reuses shared `_CategoryGroupSection` (backed by `FinanceCategoryGroupCard`) for expense groups.
  - Removed duplicate local picker tiles: `_FinanceCategoryChoiceTile`, `_CategoryOptionTile`.
- [x] UI sample alignment for category display/picker applied.
  - Quick category display: selected tile keeps same footprint (no phình), uses border/background emphasis, and action tile `Khác` rendered borderless.
  - Category picker groups: switched to full-width colored header strip + grid body with borderless unselected items and highlighted selected state.
  - Category icon colors now map per category in transaction/recurring/classify pickers to match visual sample.
- [x] Category icon-color system unified across finance.
  - Added centralized `FinanceCategoryVisualCatalog` in `finance_styles.dart` to resolve both icon and color by category.
  - Mapped key screens to the same source of truth: overview (`finance_screen.dart`), entry (`finance_transaction_entry_screen.dart`), recurring (`finance_recurring_flow_screens.dart`), classify (`finance_classify_transactions_screen.dart`), and manager (`finance_category_manager_screen.dart`).
  - Removed selected category "phình" effect in quick grids: selected state now keeps same tile footprint and uses border emphasis.
- [~] Hardcoded sheet style cleanup started with new tokens in `finance_styles.dart`:
  - `sheetBackground`, `sheetBackgroundSoft`, `sheetDragHandle`, `sheetCloseIcon`, `sheetDivider`, `panelBorder`, `sheetTop`.
  - `FinanceModalSheetHeader` now consumes these tokens.
- [x] Shared sheet footer action row extracted and adopted in finance sheet flows.
  - New shared component: `FinanceSheetDualActionRow` in `finance_shared_widgets.dart`.
  - Migrated callsites: calendar month picker (`finance_module_screen.dart`), budget edit footer states (`finance_budget_screens.dart`), and overview time-filter footer (`finance_screen.dart`).
- [x] Silent catch cleanup for finance module cloud/load flows.
  - Replaced finance-related `catch (_) {}` blocks with debug-only logs while preserving local-first fallbacks.
  - Updated files: `firestore_finance_category_service.dart`, `finance_module_screen.dart`, `finance_provider.dart`.
- [x] Shared icon-picker sheet body extracted.
  - New shared helper: `showFinanceCategoryIconPicker(...)` in `finance_screen.dart`.
  - Migrated flows: create-category (`finance_transaction_entry_screen.dart`) and edit-category (`finance_category_manager_screen.dart`).
  - Result: duplicated icon-picker body removed from both screens.
- [x] Funding source normalization unified.
  - Canonical normalization now lives in `FinanceTransaction.normalizeFundingSourceId(...)` and is reused across recurring flow + entry flow.
  - Legacy alias compatibility handled in one place.
- [x] Funding source visual resolver deduplicated.
  - Removed local recurring resolver duplication; recurring detail now reuses `FinanceFundingSourceVisualResolver` from shared widgets.
- [x] Reusable finance surface card extracted.
  - New shared shell: `FinanceSurfaceCard` in `finance_shared_widgets.dart`.
  - Applied to transaction-detail card, recurring-detail card, and detail action-row container.
- [x] Transaction classification update path simplified.
  - `FinanceProvider.updateTransactionClassification(...)` now uses `FinanceTransaction.copyWith(...)` with `clearCategoryIconSnapshot`.
- [x] Funding-source option catalog unified.
  - New shared catalog: `FinanceFundingSourceCatalog` + `FinanceFundingSourceOption` in `finance_shared_widgets.dart`.
  - Entry and recurring flows now use the same option source; recurring no longer couples to entry state's private funding list implementation.
- [x] Funding-source lookup internals optimized.
  - Added map-backed O(1) lookup and `findByNormalizedId(...)` to avoid repeated normalization/linear scan at hot call sites.
- [x] Full migration of all remaining bottom-sheet wrappers to `FinanceSheetScaffold`.

Quick metrics after wave 8:
- `FinanceCategoryChoiceTile`: 7 direct callsites (+ 1 internal use in `FinanceCategoryGroupCard`, + 1 definition)
- `FinanceCategoryGroupCard`: 3 direct callsites (+ 1 definition)
- Remaining duplicate local category picker tile classes: 0
- Remaining `Color(0xFFF4F3F8)` / `Color(0xFFF7F6FB)` / `Color(0xFFD8D7DD)` literals in finance Dart files: 9
- Remaining `Color(0xFFE6E2EC)` literals in finance Dart files: 10

Wave 8 deltas (vs wave 7):
- `showModalBottomSheet<`: 25 -> 24
- `FinanceModalSheetHeader(`: 8 -> 7
- Hardcoded `Color(0x...)`: 818 -> 817
- Shared icon-picker helper references: 0 -> 3 (`finance_screen.dart`, `finance_transaction_entry_screen.dart`, `finance_category_manager_screen.dart`)

Wave 9 qualitative deltas:
- Canonical funding-source normalization + defaults are now centralized in model layer for better compatibility.
- Repeated finance detail card shell is abstracted by `FinanceSurfaceCard` to reduce UI boilerplate.
- Recurring detail flow no longer depends on a duplicated local funding visual mapping helper.

Wave 10 qualitative deltas:
- Funding-source UI data moved to a shared catalog to prevent drift between entry and recurring screens.
- Added regression test coverage for funding-source catalog alias compatibility.

Wave 11 qualitative deltas:
- Funding-source resolution path now uses normalized-ID map lookup for cleaner intent and lower lookup overhead.

Wave 12 qualitative deltas:
- Standardized the final legacy bottom-sheet wrappers in `finance_screen.dart` to `FinanceSheetScaffold`.
- Bottom-sheet shell consistency is now complete across all `showModalBottomSheet` callsites in finance module.

Wave 13 qualitative deltas:
- Added reusable footer action pair component (`FinanceSheetDualActionRow`) to replace repeated outline+primary button rows.
- Migrated month-picker and budget-edit sheet footers to shared action-row, reducing repeated button-layout boilerplate.

Wave 14 qualitative deltas:
- Migrated overview time-filter footer to `FinanceSheetDualActionRow` for full shared footer-row coverage in key finance sheets.
- Removed silent `catch (_) {}` usage in finance-related flows and replaced with debug-only logging for safer diagnostics.

## 1) Snapshot

- Total Dart files scanned: 11
- Existing reuse inventory file: `lib/screens/finance/FINANCE_REUSE_INVENTORY.md`
- Current status: there is already partial reuse (`finance_shared_widgets.dart` + `finance_styles.dart`), but many medium-sized UI shells are still rewritten in each flow.

## 2) Quantitative Metrics (module-level)

### 2.1 Reuse/duplication pattern counts

| Pattern | Total Occurrences | Files Involved | Notes |
|---|---:|---:|---|
| `showModalBottomSheet<` | 23 | 6 | All callsites now share the same base sheet scaffold |
| `FinanceModalSheetHeader(` | 7 | 4 | Header is shared, but sheet body/shell is still duplicated |
| `leadingWidth: 58` | 1 | 1 | Mostly consolidated into shared appbar |
| `gradient: LinearGradient(` | 2 | 2 | Mostly consolidated into shared appbar |
| `FinanceSheetDualActionRow(` | 5 | 4 | Shared footer action pair adopted across month/budget/time-filter flows |
| `FinanceBottomBarSurface(` | 8 | 5 | Reuse is good here |
| `FinancePrimaryActionButton(` | 12 | 5 | Primary CTA usage remains shared, with some rows now abstracted |
| `FinanceOutlineActionButton(` | 4 | 3 | Direct outline-button usage reduced via shared dual-action rows |
| `FinanceCurvedDualTabBar(` | 5 | 4 | Shared tab exists but not used consistently |
| `showFinanceCategoryIconPicker(` | 3 | 3 | New shared icon-picker helper adopted in create/edit flows |

### 2.2 Style consistency indicators

| Metric | Count | Files |
|---|---:|---:|
| Hardcoded color literals (`Color(0x...)`) | 786 | 11 |
| Shared color tokens (`FinanceColors.`) | 341 | 11 |
| `BorderRadius.circular(...)` usages | 274 | 11 |
| Explicit `color: Colors.white` surfaces | 99 | 10 |

Interpretation:
- Shared tokens/components are being used, but hardcoded visual literals are still much more frequent.
- "White card + border + radius" is heavily repeated and still not abstracted as one reusable shell.

## 3) Main Duplication Clusters

### Cluster A: Custom AppBar shell (mostly resolved)

Repeated structure:
- Circular back button container
- `leadingWidth: 58`
- pink-tint `LinearGradient` in `flexibleSpace`
- right-side utility action capsule

Representative locations:
- `finance_shared_widgets.dart:96`
- `finance_classify_transactions_screen.dart:945`

Inconsistency risk:
- Residual custom gradient/header code can diverge from shared appbar over time.

### Cluster B: Bottom sheet scaffold duplicated

Repeated structure:
- `showModalBottomSheet`
- `backgroundColor: Colors.transparent`
- `SafeArea(top: false)`
- container with `Color(0xFFF4F3F8)` + top radius 26
- optional `FinanceModalSheetHeader`

Representative locations:
- `finance_transaction_entry_screen.dart:776`
- `finance_transaction_entry_screen.dart:1047`
- `finance_transaction_entry_screen.dart:2700`
- `finance_recurring_flow_screens.dart:2299`
- `finance_module_screen.dart:572`
- `finance_budget_screens.dart:959`
- `finance_screen.dart:2143`

Inconsistency risk:
- Different paddings, heights, and close interactions across sheets for similar UX patterns.

### Cluster C: Category group card/grid rewritten in 3 variants

Variants:
- `_CategoryManagerSectionCard` (manager)
- `_CategoryGroupSection` (transaction entry)
- `_ExpenseCategoryGroups` + `_FinanceCategoryChoiceTile` (classify)

Representative locations:
- `finance_category_manager_screen.dart:1388`
- `finance_transaction_entry_screen.dart:3383`
- `finance_classify_transactions_screen.dart:1401`
- `finance_classify_transactions_screen.dart:1503`

Inconsistency risk:
- Different tile sizes, selection visuals, spacing, and text scaling for effectively the same category-selection concept.

### Cluster D: Top tab controls split into multiple implementations

Variants:
- Shared: `FinanceCurvedDualTabBar`
- Custom: `_CategoryManagerTypeTab`, `_EntryTopTab`, `_RecurringTopTab`

Representative locations:
- `finance_shared_widgets.dart:323`
- `finance_category_manager_screen.dart:1328`
- `finance_transaction_entry_screen.dart:2300`
- `finance_module_screen.dart:3132`

Inconsistency risk:
- Interaction states (selected underline, ripple behavior, typography) diverge between screens.

### Cluster E: Icon picker UI body (resolved in wave 8)

Resolution summary:
- Shared helper `showFinanceCategoryIconPicker(...)` now owns the sheet body.
- Create/edit category flows only pass pool/used/selected inputs and icon-color resolver.

Representative locations:
- `finance_screen.dart`
- `finance_transaction_entry_screen.dart`
- `finance_category_manager_screen.dart`

Residual risk:
- Low. Future tweaks should be done in one helper instead of 2 separate screens.

## 4) Reuse Progress (already good)

These are positive and should remain the baseline:
- `FinancePrimaryActionButton`
- `FinanceBottomBarSurface`
- `FinanceModalSheetHeader`
- `FinanceOptionTile`
- `FinanceSectionHeader`
- `FinanceCurvedDualTabBar` (partially adopted)

## 5) Prioritized Refactor Backlog (Finance-only)

### P1 (next)

1. Consolidate tab controls
- Prefer `FinanceCurvedDualTabBar` or create a unified `FinanceTopTabBar` with style variants (`underline`, `pill`).

2. Extract `FinanceSurfaceCard`
- One standard card shell for `Colors.white + border + radius + padding` pattern.

3. Finalize AppBar migration tails
- Replace remaining custom gradient block(s) with shared appbar variants to finish cluster A.

### P2 (cleanup)

4. Move repeated literal colors/radius values into `finance_styles.dart`
- Focus on literals appearing in 3+ places first.

## 6) Practical Rule Proposal (to prevent re-duplication)

- New Finance screen rule:
  1. If a pattern appears in 2 screens, extract now.
  2. If a pattern appears 1 time but likely to be reused (sheet/appbar/category-grid), create shared wrapper first.
  3. No new hardcoded color/radius unless truly feature-specific.

- PR checklist additions:
  - "Did I reuse existing component from `finance_shared_widgets.dart`?"
  - "Did I introduce a new duplicated sheet/appbar/card shell?"
  - "Can this visual token move to `finance_styles.dart`?"

## 7) Suggested next extraction order (low-risk rollout)

1. `FinanceSurfaceCard`
2. Tab unification (`FinanceTopTabBar` or full migration to `FinanceCurvedDualTabBar`)
3. AppBar residual cleanup
4. Literal token migration in `finance_styles.dart`

---

Data source method:
- Direct scan of all files in `lib/screens/finance`
- Pattern counts by `rg` (ripgrep)
- Manual inspection of representative duplicated UI blocks
