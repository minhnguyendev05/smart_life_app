# Finance UI Duplication Report

Updated: 2026-04-09
Scope: only `lib/screens/finance` module

## 0) Refactor Progress Tracker

Status snapshot: 2026-04-09 (wave 3)

- [x] AppBar unification completed: finance screens now share one strict appbar component (`FinanceGradientAppBar`).
- [~] `FinanceSheetScaffold` extracted and adopted in high-duplicate sheets.
  - Current usage count: 20 callsites (plus 1 component definition).
  - Migrated files: `finance_transaction_entry_screen.dart`, `finance_category_manager_screen.dart`, `finance_classify_transactions_screen.dart`, `finance_module_screen.dart`, `finance_recurring_flow_screens.dart`, `finance_budget_screens.dart`, `finance_screen.dart`.
  - Additional wave 3 migrations: create-category sheets (parent picker, icon picker), recurring reminder pickers, and overview time filter sheet.
- [~] Hardcoded sheet style cleanup started with new tokens in `finance_styles.dart`:
  - `sheetBackground`, `sheetBackgroundSoft`, `sheetDragHandle`, `sheetCloseIcon`, `sheetDivider`, `panelBorder`, `sheetTop`.
  - `FinanceModalSheetHeader` now consumes these tokens.
- [ ] Full migration of all remaining bottom-sheet wrappers to `FinanceSheetScaffold`.

Quick metrics after wave 3:
- Remaining `Color(0xFFF4F3F8)` / `Color(0xFFF7F6FB)` / `Color(0xFFD8D7DD)` literals in finance Dart files: 9
- Remaining `Color(0xFFE6E2EC)` literals in finance Dart files: 10

## 1) Snapshot

- Total Dart files scanned: 11
- Existing reuse inventory file: `lib/screens/finance/FINANCE_REUSE_INVENTORY.md`
- Current status: there is already partial reuse (`finance_shared_widgets.dart` + `finance_styles.dart`), but many medium-sized UI shells are still rewritten in each flow.

## 2) Quantitative Metrics (module-level)

### 2.1 Reuse/duplication pattern counts

| Pattern | Total Occurrences | Files Involved | Notes |
|---|---:|---:|---|
| `showModalBottomSheet<` | 22 | 7 | Same sheet scaffold appears frequently with small variations |
| `FinanceModalSheetHeader(` | 8 | 4 | Header is shared, but sheet body/shell is still duplicated |
| `leadingWidth: 58` | 4 | 3 | Same custom AppBar leading pattern repeated |
| `gradient: LinearGradient(` | 6 | 4 | Similar top-header gradient logic copied across screens |
| `FinanceBottomBarSurface(` | 8 | 5 | Reuse is good here |
| `FinancePrimaryActionButton(` | 13 | 6 | Reuse is good for primary action |
| `FinanceOutlineActionButton(` | 4 | 2 | Reuse exists but not broadly applied |
| `FinanceCurvedDualTabBar(` | 5 | 4 | Shared tab exists but not used consistently |

### 2.2 Style consistency indicators

| Metric | Count | Files |
|---|---:|---:|
| Hardcoded color literals (`Color(0x...)`) | 871 | 11 |
| Shared color tokens (`FinanceColors.`) | 341 | 11 |
| `BorderRadius.circular(...)` usages | 306 | 11 |
| Explicit `color: Colors.white` surfaces | 130 | 10 |

Interpretation:
- Shared tokens/components are being used, but hardcoded visual literals are still much more frequent.
- "White card + border + radius" is heavily repeated and still not abstracted as one reusable shell.

## 3) Main Duplication Clusters

### Cluster A: Custom AppBar shell duplicated

Repeated structure:
- Circular back button container
- `leadingWidth: 58`
- pink-tint `LinearGradient` in `flexibleSpace`
- right-side utility action capsule

Representative locations:
- `finance_category_manager_screen.dart:541`
- `finance_category_manager_screen.dart:1055`
- `finance_transaction_entry_screen.dart:2848`
- `finance_recurring_flow_screens.dart:259`

Inconsistency risk:
- Small spacing, icon-size, border differences can drift over time.

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
- Expected immediate dedupe target: most of 22 sheet callsites.

2. Extract `FinanceHeroAppBar` (or `FinanceGradientBackAppBar`)
- Encapsulate repeated leading circle-back + gradient + optional action capsule.
- Target: category manager, edit category, create category, recurring detail/reminder flows.

3. Extract `FinanceCategoryGroupCard` + `FinanceCategoryChoiceTile`
- Unify the 3 current category-grid variants under one configurable component.

### P1 (next)

4. Consolidate tab controls
- Prefer `FinanceCurvedDualTabBar` or create a unified `FinanceTopTabBar` with style variants (`underline`, `pill`).

5. Extract `FinanceSurfaceCard`
- One standard card shell for `Colors.white + border + radius + padding` pattern.

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

1. `FinanceSheetScaffold`
2. `FinanceHeroAppBar`
3. `FinanceCategoryGroupCard`
4. `FinanceSurfaceCard`
5. Tab unification (`FinanceTopTabBar` or full migration to `FinanceCurvedDualTabBar`)

---

Data source method:
- Direct scan of all files in `lib/screens/finance`
- Pattern counts by `rg` (ripgrep)
- Manual inspection of representative duplicated UI blocks
