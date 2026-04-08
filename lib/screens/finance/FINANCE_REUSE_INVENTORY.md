# Finance Reuse Inventory

Updated: 2026-04-04

## 1) Global style entry

Shared style tokens for Finance now live in:
- `lib/screens/finance/finance_styles.dart`

Available token groups:
- `FinanceColors`: background, surface, border, text, accent colors.
- `FinanceRadius`: common corner radii.
- `FinanceSpacing`: common spacing scale.
- `FinanceDecorations`: reusable card/panel/icon-badge decorations.

Already wired in code:
- `finance_screen.dart`
- `finance_module_screen.dart`
- `finance_budget_screens.dart`
- `finance_transaction_entry_screen.dart`
- `finance_supporting_widgets.dart`
- `finance_shared_widgets.dart`

Core tokens already migrated broadly:
- Accent: `accentPrimary`, `accentSecondary`
- Surfaces/background: `background`, `surface`, `appBarTint`
- Borders: `border`, `borderSoft`
- Text tones: `textPrimary`, `textSecondary`, `textStrong`

## 2) Screens currently in Finance

- `FinanceModuleScreen`: module container with bottom tabs.
- `FinanceScreen`: overview dashboard and analytics.
- `_TransactionEntryScreen`: transaction input flow.
- `_BudgetOverviewScreen`: budget summary.
- `_BudgetCreateScreen`: budget setup flow.
- `_BudgetCategoryScreen`: budget detail by category.
- `_CreateCategoryScreen`: create custom category.

## 3) Widget/Class inventory by file

### `finance_screen.dart`

Core screen/state and helper models:
- `FinanceScreen`
- `_FinanceScreenState`
- `_FinanceRangeWindow`
- `_FinanceTimeFilterResult`
- `_FinanceWeekOption`

Enums:
- `_FinanceTimeRange`
- `_ExpenseBreakdownTab`
- `_DetailTxnTab`
- `_FinanceUtilityAction`

### `finance_supporting_widgets.dart`

Reusable presentational widgets and budget data models:
- `_QuickActionItem`
- `_SummaryAmountCard`
- `_BudgetSpendingCard`
- `_BudgetCreateCard`
- `_ParentCategoryGroup`
- `_BudgetCardInfo`

### `finance_budget_screens.dart`

Budget flow widgets/models:
- `_BudgetOverviewScreen`
- `_BudgetOverviewScreenState`
- `_BudgetHalfGauge`
- `_BudgetHalfGaugePainter`
- `_BudgetCategoryListTile`
- `_BudgetCreateResult`
- `_BudgetCreateSuggestion`
- `_BudgetCreateScreen`
- `_BudgetCreateScreenState`
- `_BudgetCreateCategoryRow`
- `_BudgetCategoryScreen`
- `_BudgetCategoryScreenState`

### `finance_transaction_entry_screen.dart`

Transaction-entry flow widgets/models:
- `_TransactionEntryScreen`
- `_TransactionEntryScreenState`
- `_RecurrenceResult`
- `_CategoryGroup`
- `_CustomCategoryItem`
- `_FundingSourceOption`
- `_ParentCategoryOption`
- `_CreateCategoryResult`
- `_EntryTopTab`
- `_FieldLabel`
- `_InputContainer`
- `_SelectRow`
- `_TypeTabButton`
- `_FundingSourceTile`
- `_CreateCategoryScreen`
- `_CreateCategoryScreenState`
- `_CreateCategoryTypeTab`
- `_LabeledFormField`
- `_ParentCategoryRadioTile`
- `_IconOptionTile`
- `_UsedIconTile`
- `_ImageGuideCard`
- `_CategoryGroupSection`
- `_CategoryOptionTile`
- `_RecurrenceOptionTile`
- `_RecurrenceDivider`
- `_WeekdayLabel`
- `_CategoryPeriodPoint`
- `_TopReceiverAggregate`
- `_CategoryHistoryChart`
- `_DashedHorizontalLine`
- `_BudgetTxnFilterChip`
- `_CategoryLegend`
- `_TimeRangeChip`
- `_TimeMonthChip`
- `_UtilitySheetEntry`
- `_UtilitySheetItem`
- `_CategorySlice`

Enums:
- `_RecurrenceOption`
- `_GuideStatus`

### `finance_module_screen.dart`

Tab-level widgets and shared tab components:
- `FinanceModuleScreen`
- `_FinanceModuleScreenState`
- `_FinanceCalendarTab`
- `_FinanceCalendarTabState`
- `_FinanceRecurringTab`
- `_FinanceMoniTab`
- `_FinanceUtilitiesTab`
- `_FinanceTabContainer`
- `_MonthSwitcher`
- `_InsightMetricCard`
- `_UtilityActionCard`
- `_FinanceEmptyState`
- `_RecurringCandidate`

### `finance_shared_widgets.dart`

Cross-screen reusable building blocks:
- `FinanceSectionHeader`
- `FinanceOptionTile`
- `FinancePrimaryActionButton`
- `FinanceOutlineActionButton`
- `FinanceStandardBarChart`
- `FinanceAdvancedBarChart`

## 4) Repeated style patterns (current status)

Current status after migration:
- High-frequency literals for border/accent/background/text are centralized into `FinanceColors`.
- Repeated bordered white-card patterns started to move to `FinanceDecorations.surfaceCard`.

Remaining literals are mostly domain-specific visual colors (charts, category accents, status colors), not global UI foundation tokens.

## 5) Reuse rules for upcoming changes

- Same screen + same visual pattern: reuse existing widget first, add parameters if needed.
- Different screen: follow UI reference; reuse only when layout/interaction is truly compatible.
- Before adding a new widget, check this inventory to avoid duplicate components.
- If a new visual token appears in 2+ places, move it to `finance_styles.dart`.
- Keep widget names scoped by domain (`Budget*`, `Entry*`, `Utility*`) for discoverability.

## 6) Extraction progress

Completed in step 2:
- `FinanceSectionHeader` has been extracted and applied in Budget screens.
- `FinanceOptionTile` has been extracted and applied in category/recurrence/filter options.
- `FinancePrimaryActionButton` and `FinanceOutlineActionButton` have been extracted and applied in Budget and Transaction Entry actions.

Completed in step 3:
- `FinanceStandardBarChart` has been extracted from Budget detail/create chart style (dashed reference line + blue selected guide line) and now serves as the default reusable column-chart base.
- `FinanceAdvancedBarChart` has been extracted as the fl_chart-based chart base for advanced cases (axis ticks, negative values, extra lines, multi-series customization).

Next suggested extraction:
- `FinanceSurfaceCard` wrapper (white card + border + radius + optional padding)
	This is still repeated in many places and is the next highest-impact extraction.
