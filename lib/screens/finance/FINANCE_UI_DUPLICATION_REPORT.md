# Finance UI Duplication Report

Updated: 2026-04-09
Scope: only `lib/screens/finance` module

## 0) Refactor Progress Tracker

Status snapshot: 2026-04-09 (wave 7)

- [x] AppBar unification completed: finance screens now share one strict appbar component (`FinanceGradientAppBar`).
- [~] `FinanceSheetScaffold` extracted and adopted in high-duplicate sheets.
  - Current usage count: 23 callsites (plus 1 component definition).
  - Migrated files: `finance_transaction_entry_screen.dart`, `finance_category_manager_screen.dart`, `finance_classify_transactions_screen.dart`, `finance_module_screen.dart`, `finance_recurring_flow_screens.dart`, `finance_budget_screens.dart`, `finance_screen.dart`.
  - Additional wave 3 migrations: create-category sheets (parent picker, icon picker), recurring reminder pickers, and overview time filter sheet.
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
- [ ] Full migration of all remaining bottom-sheet wrappers to `FinanceSheetScaffold`.

Quick metrics after wave 7:
- `FinanceCategoryChoiceTile`: 7 direct callsites (+ 1 internal use in `FinanceCategoryGroupCard`, + 1 definition)
- `FinanceCategoryGroupCard`: 3 direct callsites (+ 1 definition)
- Remaining duplicate local category picker tile classes: 0
- Remaining `Color(0xFFF4F3F8)` / `Color(0xFFF7F6FB)` / `Color(0xFFD8D7DD)` literals in finance Dart files: 9
- Remaining `Color(0xFFE6E2EC)` literals in finance Dart files: 10

Wave 7 deltas (vs wave 6):
- `showModalBottomSheet<`: 22 -> 25 (new filter/month/category sheets added)
- AppBar duplicate signatures reduced significantly: `leadingWidth: 58` now 1, `gradient: LinearGradient(` now 2
- Hardcoded `Color(0x...)` reduced: 871 -> 818
- Shared token usage improved: `FinanceColors.` 341 -> 346

## 1) Snapshot

- Total Dart files scanned: 11
- Existing reuse inventory file: `lib/screens/finance/FINANCE_REUSE_INVENTORY.md`
- Current status: there is already partial reuse (`finance_shared_widgets.dart` + `finance_styles.dart`), but many medium-sized UI shells are still rewritten in each flow.

## 2) Quantitative Metrics (module-level)

### 2.1 Reuse/duplication pattern counts

| Pattern | Total Occurrences | Files Involved | Notes |
|---|---:|---:|---|
| `showModalBottomSheet<` | 25 | 7 | Same sheet scaffold appears frequently with small variations |
| `FinanceModalSheetHeader(` | 8 | 4 | Header is shared, but sheet body/shell is still duplicated |
| `leadingWidth: 58` | 1 | 1 | Mostly consolidated into shared appbar |
| `gradient: LinearGradient(` | 2 | 2 | Mostly consolidated into shared appbar |
| `FinanceBottomBarSurface(` | 8 | 5 | Reuse is good here |
| `FinancePrimaryActionButton(` | 14 | 6 | Reuse is good for primary action |
| `FinanceOutlineActionButton(` | 6 | 3 | Reuse improving (create/filter actions migrated) |
| `FinanceCurvedDualTabBar(` | 5 | 4 | Shared tab exists but not used consistently |

### 2.2 Style consistency indicators

| Metric | Count | Files |
|---|---:|---:|
| Hardcoded color literals (`Color(0x...)`) | 818 | 11 |
| Shared color tokens (`FinanceColors.`) | 346 | 11 |
| `BorderRadius.circular(...)` usages | 277 | 11 |
| Explicit `color: Colors.white` surfaces | 110 | 10 |

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

### Cluster E: Icon picker UI body duplicated (now consistent visually but still duplicated in logic)

Current duplicate bodies:
- Create category icon picker in transaction entry
- Edit category icon picker in category manager

Representative locations:
- `finance_transaction_entry_screen.dart:2693`
- `finance_category_manager_screen.dart:740`

Inconsistency risk:
- Future change to one picker can miss the other (layout, filtering, disabled/used icon behavior).

## 4) Reuse Progress (already good)

These are positive and should remain the baseline:
- `FinancePrimaryActionButton`
- `FinanceBottomBarSurface`
- `FinanceModalSheetHeader`
- `FinanceOptionTile`
- `FinanceSectionHeader`
- `FinanceCurvedDualTabBar` (partially adopted)

## 5) Prioritized Refactor Backlog (Finance-only)

### P0 (highest impact)

1. Extract `FinanceSheetScaffold`
- Wrap common sheet shell: safe area, rounded top container, optional fixed/header, scroll body, optional footer.
- Expected immediate dedupe target: most of 25 sheet callsites.

2. Extract shared icon-picker sheet body
- Consolidate create/edit category icon pickers into one reusable body + selection policy callback.
- Target: `finance_transaction_entry_screen.dart` + `finance_category_manager_screen.dart`.

3. Full migration of remaining sheets to `FinanceSheetScaffold`
- Prioritize month/time filter and recurring action sheets still carrying custom wrappers.

### P1 (next)

4. Consolidate tab controls
- Prefer `FinanceCurvedDualTabBar` or create a unified `FinanceTopTabBar` with style variants (`underline`, `pill`).

5. Extract `FinanceSurfaceCard`
- One standard card shell for `Colors.white + border + radius + padding` pattern.

6. Finalize AppBar migration tails
- Replace remaining custom gradient block(s) with shared appbar variants to finish cluster A.

### P2 (cleanup)

6. Move repeated literal colors/radius values into `finance_styles.dart`
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

1. `FinanceSheetScaffold` (complete remaining 25 wrappers)
2. Shared icon-picker sheet body
3. `FinanceSurfaceCard`
4. Tab unification (`FinanceTopTabBar` or full migration to `FinanceCurvedDualTabBar`)
5. AppBar residual cleanup

---

Data source method:
- Direct scan of all files in `lib/screens/finance`
- Pattern counts by `rg` (ripgrep)
- Manual inspection of representative duplicated UI blocks
