part of 'finance_screen.dart';

enum RecurringFrequency { none, daily, weekly, monthly, yearly }

extension RecurringFrequencyX on RecurringFrequency {
  String get label {
    switch (this) {
      case RecurringFrequency.none:
        return 'Không lặp lại';
      case RecurringFrequency.daily:
        return 'Hàng ngày';
      case RecurringFrequency.weekly:
        return 'Hàng tuần';
      case RecurringFrequency.monthly:
        return 'Hàng tháng';
      case RecurringFrequency.yearly:
        return 'Hàng năm';
    }
  }
}

_RecurrenceOption _toRecurrenceOption(RecurringFrequency value) {
  switch (value) {
    case RecurringFrequency.none:
      return _RecurrenceOption.none;
    case RecurringFrequency.daily:
      return _RecurrenceOption.daily;
    case RecurringFrequency.weekly:
      return _RecurrenceOption.weekly;
    case RecurringFrequency.monthly:
      return _RecurrenceOption.monthly;
    case RecurringFrequency.yearly:
      return _RecurrenceOption.yearly;
  }
}

RecurringFrequency _fromRecurrenceOption(_RecurrenceOption value) {
  switch (value) {
    case _RecurrenceOption.none:
      return RecurringFrequency.none;
    case _RecurrenceOption.daily:
      return RecurringFrequency.daily;
    case _RecurrenceOption.weekly:
      return RecurringFrequency.weekly;
    case _RecurrenceOption.monthly:
      return RecurringFrequency.monthly;
    case _RecurrenceOption.yearly:
      return RecurringFrequency.yearly;
  }
}

String _recurringFrequencySummary(
  RecurringFrequency frequency,
  DateTime anchorDate,
) {
  switch (frequency) {
    case RecurringFrequency.none:
      return 'MoMo sẽ không lặp lại giao dịch này';
    case RecurringFrequency.daily:
      return 'MoMo sẽ nhắc bạn hàng ngày';
    case RecurringFrequency.weekly:
      return 'MoMo sẽ nhắc bạn hàng tuần';
    case RecurringFrequency.monthly:
      return 'MoMo sẽ nhắc bạn hàng tháng';
    case RecurringFrequency.yearly:
      final d = anchorDate.day.toString().padLeft(2, '0');
      final m = anchorDate.month.toString().padLeft(2, '0');
      return 'MoMo sẽ nhắc bạn hàng năm vào ngày $d/$m';
  }
}

String _recurringMonthLabel(DateTime value) {
  return 'Tháng ${value.month}/${value.year}';
}

String _recurringShortDate(DateTime value) {
  final d = value.day.toString().padLeft(2, '0');
  final m = value.month.toString().padLeft(2, '0');
  return '$d/$m/${value.year}';
}

String _recurringMoney(double amount) {
  final raw = Formatters.currency(
    amount,
  ).replaceAll(RegExp(r'\s*VND\s*', caseSensitive: false), '').trim();
  return '$rawđ';
}

String recurringFrequencyKeyFromEnum(RecurringFrequency value) {
  switch (value) {
    case RecurringFrequency.none:
      return 'none';
    case RecurringFrequency.daily:
      return 'daily';
    case RecurringFrequency.weekly:
      return 'weekly';
    case RecurringFrequency.monthly:
      return 'monthly';
    case RecurringFrequency.yearly:
      return 'yearly';
  }
}

RecurringFrequency recurringFrequencyFromKey(String key) {
  switch (key) {
    case 'daily':
      return RecurringFrequency.daily;
    case 'weekly':
      return RecurringFrequency.weekly;
    case 'monthly':
      return RecurringFrequency.monthly;
    case 'yearly':
      return RecurringFrequency.yearly;
    case 'none':
    default:
      return RecurringFrequency.none;
  }
}

DateTime recurringNormalizeDate(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

DateTime _addMonthsKeepingDay(DateTime date, int monthDelta) {
  final targetMonthStart = DateTime(date.year, date.month + monthDelta, 1);
  final maxDay = DateUtils.getDaysInMonth(
    targetMonthStart.year,
    targetMonthStart.month,
  );
  final targetDay = date.day > maxDay ? maxDay : date.day;
  return DateTime(targetMonthStart.year, targetMonthStart.month, targetDay);
}

DateTime recurringNextDateFor(String frequencyKey, DateTime anchor) {
  final normalized = recurringNormalizeDate(anchor);
  switch (frequencyKey) {
    case 'daily':
      return normalized.add(const Duration(days: 1));
    case 'weekly':
      return normalized.add(const Duration(days: 7));
    case 'monthly':
      return _addMonthsKeepingDay(normalized, 1);
    case 'yearly':
      return _addMonthsKeepingDay(normalized, 12);
    case 'none':
    default:
      return normalized;
  }
}

String recurringWeekdayLabel(DateTime date) {
  switch (date.weekday) {
    case DateTime.monday:
      return 'Thứ 2';
    case DateTime.tuesday:
      return 'Thứ 3';
    case DateTime.wednesday:
      return 'Thứ 4';
    case DateTime.thursday:
      return 'Thứ 5';
    case DateTime.friday:
      return 'Thứ 6';
    case DateTime.saturday:
      return 'Thứ 7';
    case DateTime.sunday:
      return 'Chủ nhật';
    default:
      return 'Chủ nhật';
  }
}

String recurringScheduleChipLabel(FinanceRecurringTransaction recurring) {
  switch (recurring.frequency) {
    case 'daily':
      return 'Hàng ngày';
    case 'weekly':
      return 'Hàng tuần ▸ ${recurringWeekdayLabel(recurring.startDate)}';
    case 'monthly':
      return 'Hàng tháng ▸ Ngày ${recurring.startDate.day}';
    case 'yearly':
      return 'Hàng năm ▸ ${_recurringShortDate(recurring.startDate)}';
    case 'none':
    default:
      return 'Không lặp lại';
  }
}

String recurringScheduleDetailLabel(FinanceRecurringTransaction recurring) {
  switch (recurring.frequency) {
    case 'daily':
      return 'Hàng ngày';
    case 'weekly':
      return '${recurringWeekdayLabel(recurring.startDate)} hàng tuần';
    case 'monthly':
      return 'Ngày ${recurring.startDate.day} hàng tháng';
    case 'yearly':
      return 'Ngày ${_recurringShortDate(recurring.startDate)} hàng năm';
    case 'none':
    default:
      return 'Không lặp lại';
  }
}

class FinanceRecurringFundingVisual {
  const FinanceRecurringFundingVisual({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
}

class RecurringFrequencySelection {
  const RecurringFrequencySelection({required this.frequency, this.endDate});

  final RecurringFrequency frequency;
  final DateTime? endDate;
}

FinanceRecurringFundingVisual recurringFundingVisualForId(
  String sourceId, {
  String? fallbackLabel,
}) {
  for (final option in _TransactionEntryScreenState._fundingSources) {
    if (option.id == sourceId) {
      return FinanceRecurringFundingVisual(
        label: option.label,
        icon: option.icon,
        iconColor: option.iconColor,
        iconBackground: option.iconBackground,
      );
    }
  }

  return FinanceRecurringFundingVisual(
    label: (fallbackLabel == null || fallbackLabel.trim().isEmpty)
        ? 'Ngoài MoMo'
        : fallbackLabel.trim(),
    icon: Icons.account_balance_wallet_rounded,
    iconColor: const Color(0xFF2DC7C3),
    iconBackground: const Color(0xFFEAF7F6),
  );
}

PreferredSizeWidget _buildRecurringFlowAppBar({
  required BuildContext context,
  required String title,
}) {
  return AppBar(
    backgroundColor: FinanceColors.appBarTint,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    leadingWidth: 58,
    leading: Padding(
      padding: const EdgeInsets.only(left: 12, top: 6, bottom: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          border: Border.all(color: FinanceColors.borderSoft),
        ),
        child: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          color: FinanceColors.textStrong,
        ),
      ),
    ),
    title: Text(
      title,
      style: const TextStyle(
        color: FinanceColors.textStrong,
        fontWeight: FontWeight.w900,
        fontSize: 30 / 1.2,
      ),
    ),
    actions: [
      Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: FinanceColors.border),
        ),
        child: Row(
          children: const [
            Icon(Icons.support_agent_rounded, color: Color(0xFF4F4F58)),
            SizedBox(width: 8),
            SizedBox(
              height: 18,
              child: VerticalDivider(color: Color(0xFFD5D2DC), thickness: 1),
            ),
            SizedBox(width: 8),
            Icon(Icons.home_outlined, color: Color(0xFF4F4F58)),
          ],
        ),
      ),
    ],
  );
}

Future<RecurringFrequencySelection?> showRecurringFrequencySheet({
  required BuildContext context,
  required RecurringFrequency current,
  required bool allowNone,
  required DateTime anchorDate,
  DateTime? currentEndDate,
  bool includeEndSection = false,
}) {
  final options = allowNone
      ? _RecurrenceOption.values
      : const [
          _RecurrenceOption.daily,
          _RecurrenceOption.weekly,
          _RecurrenceOption.monthly,
          _RecurrenceOption.yearly,
        ];

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final normalizedAnchor = recurringNormalizeDate(anchorDate);
  final minEndDate = normalizedAnchor.isAfter(today) ? normalizedAnchor : today;

  return showModalBottomSheet<RecurringFrequencySelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      var tempOption = _toRecurrenceOption(current);
      if (!allowNone && tempOption == _RecurrenceOption.none) {
        tempOption = _RecurrenceOption.daily;
      }
      DateTime? tempEndDate = currentEndDate == null
          ? null
          : recurringNormalizeDate(currentEndDate);
      if (tempEndDate != null && tempEndDate.isBefore(minEndDate)) {
        tempEndDate = minEndDate;
      }
      if (tempOption == _RecurrenceOption.none) {
        tempEndDate = null;
      }

      return StatefulBuilder(
        builder: (context, setModalState) {
          final isRepeat = tempOption != _RecurrenceOption.none;
          final summary = _recurringFrequencySummary(
            _fromRecurrenceOption(tempOption),
            anchorDate,
          );
          final endLabel = tempEndDate == null
              ? 'Không bao giờ'
              : _recurringShortDate(tempEndDate!);

          String? infoText;
          if (tempOption == _RecurrenceOption.monthly) {
            infoText =
                'Với các tháng không có ngày 29, 30, 31, MoMo sẽ nhắc bạn vào ngày cuối tháng.';
          } else if (tempOption == _RecurrenceOption.yearly) {
            infoText =
                'Với các năm không có ngày 29/2, MoMo sẽ nhắc bạn vào ngày 28/2.';
          }

          return SafeArea(
            top: false,
            child: Container(
              height:
                  MediaQuery.of(ctx).size.height *
                  (includeEndSection ? 0.74 : 0.66),
              decoration: const BoxDecoration(
                color: Color(0xFFF4F3F8),
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Column(
                children: [
                  FinanceModalSheetHeader(
                    title: 'Tần suất lặp lại',
                    onClose: () => Navigator.pop(ctx),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      children: [
                        const Text(
                          'Tần suất',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4A4A52),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: FinanceColors.borderSoft),
                          ),
                          child: Column(
                            children: List.generate(options.length * 2 - 1, (
                              index,
                            ) {
                              if (index.isOdd) {
                                return _RecurrenceDivider();
                              }
                              final option = options[index ~/ 2];
                              return _RecurrenceOptionTile(
                                label: _fromRecurrenceOption(option).label,
                                selected: tempOption == option,
                                onTap: () => setModalState(() {
                                  tempOption = option;
                                  if (tempOption == _RecurrenceOption.none) {
                                    tempEndDate = null;
                                  }
                                }),
                                isFirst: index == 0,
                                isLast: index == options.length * 2 - 2,
                              );
                            }),
                          ),
                        ),
                        if (includeEndSection) ...[
                          const SizedBox(height: 18),
                          const Text(
                            'Ngày kết thúc',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4A4A52),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _SelectRow(
                            enabled: isRepeat,
                            onTap: () async {
                              if (!isRepeat) {
                                return;
                              }
                              final picked = await showRecurringDatePickerSheet(
                                context: context,
                                title: 'Chọn ngày kết thúc',
                                initialDate: tempEndDate ?? minEndDate,
                                minimumDate: minEndDate,
                              );
                              if (picked == null) {
                                return;
                              }
                              setModalState(() {
                                tempEndDate = picked;
                              });
                            },
                            leading: const SizedBox.shrink(),
                            title: Text(
                              endLabel,
                              style: TextStyle(
                                fontSize: 18,
                                color: isRepeat
                                    ? FinanceColors.textStrong
                                    : const Color(0xFFB2B2BA),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.expand_more,
                              color: FinanceColors.textStrong,
                            ),
                          ),
                        ],
                        if (infoText != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F8FF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF8BC2FF),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.info_outline_rounded,
                                    color: Color(0xFF267AE5),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    infoText,
                                    style: const TextStyle(
                                      color: Color(0xFF2E2E36),
                                      height: 1.35,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (isRepeat) ...[
                          const SizedBox(height: 14),
                          Text(
                            summary,
                            style: const TextStyle(
                              color: Color(0xFF4A4A52),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: FinancePrimaryActionButton(
                      label: 'Lưu cài đặt',
                      height: 52,
                      onPressed: () {
                        final selectedFrequency = _fromRecurrenceOption(
                          tempOption,
                        );
                        final selectedEndDate =
                            selectedFrequency == RecurringFrequency.none
                            ? null
                            : tempEndDate;
                        Navigator.pop(
                          ctx,
                          RecurringFrequencySelection(
                            frequency: selectedFrequency,
                            endDate: selectedEndDate,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<DateTime?> showRecurringDatePickerSheet({
  required BuildContext context,
  required DateTime initialDate,
  String title = 'Chọn ngày giao dịch',
  DateTime? minimumDate,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final minDate = minimumDate == null
          ? null
          : DateTime(minimumDate.year, minimumDate.month, minimumDate.day);

      DateTime normalizeDate(DateTime value) {
        return DateTime(value.year, value.month, value.day);
      }

      var tempDate = normalizeDate(initialDate);
      if (minDate != null && tempDate.isBefore(minDate)) {
        tempDate = minDate;
      }
      var displayMonth = DateTime(tempDate.year, tempDate.month, 1);

      return StatefulBuilder(
        builder: (context, setModalState) {
          final monthLabel = 'Tháng ${displayMonth.month}/${displayMonth.year}';
          final firstAllowedMonth = minDate == null
              ? null
              : DateTime(minDate.year, minDate.month, 1);
          final canGoPreviousMonth =
              firstAllowedMonth == null ||
              DateTime(
                displayMonth.year,
                displayMonth.month - 1,
                1,
              ).isAfter(firstAllowedMonth) ||
              DateTime(
                displayMonth.year,
                displayMonth.month - 1,
                1,
              ).isAtSameMomentAs(firstAllowedMonth);

          final firstDay = DateTime(displayMonth.year, displayMonth.month, 1);
          final daysInMonth = DateUtils.getDaysInMonth(
            displayMonth.year,
            displayMonth.month,
          );
          final leadingEmpty = firstDay.weekday - 1;
          final totalCells = ((leadingEmpty + daysInMonth) / 7).ceil() * 7;

          return SafeArea(
            top: false,
            child: Container(
              height: MediaQuery.of(ctx).size.height * 0.64,
              decoration: const BoxDecoration(
                color: Color(0xFFF4F3F8),
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Column(
                children: [
                  FinanceModalSheetHeader(
                    title: title,
                    onClose: () => Navigator.pop(ctx),
                    showDivider: false,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE6E2EC)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F6FF),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(14),
                                  topRight: Radius.circular(14),
                                ),
                                border: Border.all(
                                  color: const Color(0xFFD9E6F9),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      6,
                                      4,
                                      6,
                                      2,
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          onPressed: canGoPreviousMonth
                                              ? () => setModalState(() {
                                                  displayMonth = DateTime(
                                                    displayMonth.year,
                                                    displayMonth.month - 1,
                                                    1,
                                                  );
                                                })
                                              : null,
                                          icon: Icon(
                                            Icons.chevron_left_rounded,
                                            color: canGoPreviousMonth
                                                ? FinanceColors.textStrong
                                                : const Color(0xFFB9B9C2),
                                          ),
                                        ),
                                        Expanded(
                                          child: Center(
                                            child: Text(
                                              monthLabel,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                color: FinanceColors.textStrong,
                                              ),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => setModalState(() {
                                            displayMonth = DateTime(
                                              displayMonth.year,
                                              displayMonth.month + 1,
                                              1,
                                            );
                                          }),
                                          icon: const Icon(
                                            Icons.chevron_right_rounded,
                                            color: FinanceColors.textStrong,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: 1.6,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4D94FF),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: const [
                                _WeekdayLabel(text: 'T2'),
                                _WeekdayLabel(text: 'T3'),
                                _WeekdayLabel(text: 'T4'),
                                _WeekdayLabel(text: 'T5'),
                                _WeekdayLabel(text: 'T6'),
                                _WeekdayLabel(text: 'T7', isWeekend: true),
                                _WeekdayLabel(text: 'CN', isWeekend: true),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 7,
                                      mainAxisSpacing: 6,
                                      crossAxisSpacing: 6,
                                      childAspectRatio: 1.2,
                                    ),
                                itemCount: totalCells,
                                itemBuilder: (context, index) {
                                  final day = index - leadingEmpty + 1;
                                  if (day < 1 || day > daysInMonth) {
                                    return const SizedBox.shrink();
                                  }
                                  final date = DateTime(
                                    displayMonth.year,
                                    displayMonth.month,
                                    day,
                                  );
                                  final isSelected =
                                      date.year == tempDate.year &&
                                      date.month == tempDate.month &&
                                      date.day == tempDate.day;
                                  final isDisabled =
                                      minDate != null && date.isBefore(minDate);
                                  final isWeekend =
                                      date.weekday == DateTime.saturday ||
                                      date.weekday == DateTime.sunday;
                                  final textColor = isDisabled
                                      ? const Color(0xFFC3C3CB)
                                      : isSelected
                                      ? Colors.white
                                      : isWeekend
                                      ? const Color(0xFFFF4D5A)
                                      : FinanceColors.textStrong;

                                  return InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: isDisabled
                                        ? null
                                        : () {
                                            setModalState(
                                              () => tempDate = date,
                                            );
                                            Navigator.pop(ctx, date);
                                          },
                                    child: Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isSelected && !isDisabled
                                            ? FinanceColors.accentPrimary
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$day',
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _PastRecurringOption {
  const _PastRecurringOption({
    required this.id,
    required this.title,
    required this.date,
    required this.amount,
    required this.type,
    required this.icon,
    required this.iconColor,
  });

  final String id;
  final String title;
  final DateTime date;
  final double amount;
  final TransactionType type;
  final IconData icon;
  final Color iconColor;
}

class FinancePastRecurringSelectionScreen extends StatefulWidget {
  const FinancePastRecurringSelectionScreen({super.key});

  @override
  State<FinancePastRecurringSelectionScreen> createState() =>
      _FinancePastRecurringSelectionScreenState();
}

class _FinancePastRecurringSelectionScreenState
    extends State<FinancePastRecurringSelectionScreen> {
  RecurringFrequency _frequency = RecurringFrequency.monthly;
  final Set<String> _selectedIds = <String>{};

  List<_PastRecurringOption> _optionsFromProvider(
    List<FinanceTransaction> source,
  ) {
    if (source.isEmpty) {
      final now = DateTime.now();
      return [
        _PastRecurringOption(
          id: 'mock-1',
          title: 'Nạp tiền điện thoại Viettel',
          date: DateTime(now.year, now.month, now.day, 16, 39),
          amount: -5000,
          type: TransactionType.expense,
          icon: Icons.smartphone_rounded,
          iconColor: const Color(0xFF2B8EF7),
        ),
        _PastRecurringOption(
          id: 'mock-2',
          title: 'Chuyển đến Nguyễn Anh Quân',
          date: DateTime(now.year, now.month, now.day, 16, 38),
          amount: -1000,
          type: TransactionType.expense,
          icon: Icons.send_to_mobile_rounded,
          iconColor: const Color(0xFFFF6576),
        ),
        _PastRecurringOption(
          id: 'mock-3',
          title: 'Nhận tiền hoàn về Túi Thần Tài',
          date: DateTime(now.year, now.month, now.day, 16, 38),
          amount: 1000,
          type: TransactionType.income,
          icon: Icons.shopping_bag_rounded,
          iconColor: const Color(0xFFF98900),
        ),
      ];
    }

    final sorted = List<FinanceTransaction>.from(source)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return sorted.take(40).map((tx) {
      IconData icon;
      Color color;
      final lower = tx.title.toLowerCase();
      if (lower.contains('viettel') || lower.contains('dien thoai')) {
        icon = Icons.smartphone_rounded;
        color = const Color(0xFF2B8EF7);
      } else if (lower.contains('chuyen')) {
        icon = Icons.send_to_mobile_rounded;
        color = const Color(0xFFFF6576);
      } else if (lower.contains('than tai')) {
        icon = Icons.savings_rounded;
        color = const Color(0xFFF98900);
      } else if (tx.type == TransactionType.income) {
        icon = Icons.wallet_giftcard_rounded;
        color = const Color(0xFF27AF57);
      } else {
        icon = Icons.receipt_long_rounded;
        color = const Color(0xFF16C4CF);
      }

      return _PastRecurringOption(
        id: tx.id,
        title: tx.title,
        date: tx.createdAt,
        amount: tx.type == TransactionType.income ? tx.amount : -tx.amount,
        type: tx.type,
        icon: icon,
        iconColor: color,
      );
    }).toList();
  }

  String _timeLabel(DateTime date) {
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    final mo = date.month.toString().padLeft(2, '0');
    return '$hh:$mm - $dd/$mo/${date.year}';
  }

  String _amountLabel(double amount) {
    final sign = amount >= 0 ? '+' : '-';
    return '$sign${_recurringMoney(amount.abs())}';
  }

  Color _amountColor(double amount) {
    return amount >= 0 ? const Color(0xFF1E9C48) : const Color(0xFF34343B);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final options = _optionsFromProvider(provider.transactions);

    final groupedByMonth = <DateTime, List<_PastRecurringOption>>{};
    for (final item in options) {
      final key = DateTime(item.date.year, item.date.month);
      groupedByMonth.putIfAbsent(key, () => <_PastRecurringOption>[]).add(item);
    }
    final sortedMonthKeys = groupedByMonth.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: FinanceColors.background,
      appBar: _buildRecurringFlowAppBar(
        context: context,
        title: 'Chọn giao dịch từ quá khứ',
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: FinanceColors.border),
            ),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Giao dịch sẽ được thêm vào báo cáo với tần suất',
                    style: TextStyle(
                      color: Color(0xFF32323A),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _SelectRow(
                  onTap: () async {
                    final picked = await showRecurringFrequencySheet(
                      context: context,
                      current: _frequency,
                      allowNone: false,
                      anchorDate: DateTime.now(),
                    );
                    if (picked == null || !mounted) {
                      return;
                    }
                    setState(() => _frequency = picked.frequency);
                  },
                  leading: const Icon(
                    Icons.repeat_rounded,
                    color: FinanceColors.accentPrimary,
                    size: 20,
                  ),
                  title: Text(
                    _frequency.label,
                    style: const TextStyle(
                      color: FinanceColors.textStrong,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.expand_more_rounded,
                    color: FinanceColors.textStrong,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              children: [
                ...sortedMonthKeys.map((monthKey) {
                  final monthItems =
                      groupedByMonth[monthKey] ??
                      const <_PastRecurringOption>[];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 4, bottom: 8),
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF2FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _recurringMonthLabel(monthKey),
                          style: const TextStyle(
                            color: Color(0xFF2F2F37),
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: FinanceColors.border),
                        ),
                        child: Column(
                          children: List.generate(monthItems.length, (index) {
                            final item = monthItems[index];
                            final selected = _selectedIds.contains(item.id);
                            return Column(
                              children: [
                                _RecurringPastItemTile(
                                  item: item,
                                  selected: selected,
                                  amountLabel: _amountLabel(item.amount),
                                  amountColor: _amountColor(item.amount),
                                  timeLabel: _timeLabel(item.date),
                                  onTap: () {
                                    setState(() {
                                      if (!_selectedIds.add(item.id)) {
                                        _selectedIds.remove(item.id);
                                      }
                                    });
                                  },
                                ),
                                if (index < monthItems.length - 1)
                                  const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Color(0xFFE4E3EA),
                                    indent: 16,
                                    endIndent: 16,
                                  ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: FinanceBottomBarSurface(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: FinancePrimaryActionButton(
              label: 'Ghi nhận giao dịch định kỳ',
              onPressed: _selectedIds.isEmpty
                  ? null
                  : () {
                      showAppToast(
                        context,
                        message:
                            'Đã ghi nhận ${_selectedIds.length} giao dịch định kỳ.',
                        type: AppToastType.success,
                      );
                    },
            ),
          ),
        ),
      ),
    );
  }
}

class _RecurringPastItemTile extends StatelessWidget {
  const _RecurringPastItemTile({
    required this.item,
    required this.selected,
    required this.amountLabel,
    required this.amountColor,
    required this.timeLabel,
    required this.onTap,
  });

  final _PastRecurringOption item;
  final bool selected;
  final String amountLabel;
  final Color amountColor;
  final String timeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2DFE8)),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2F2F37),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeLabel,
                      style: const TextStyle(
                        color: Color(0xFF6E6E78),
                        fontWeight: FontWeight.w500,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _RecurringPastSelectionDot(selected: selected),
                  const SizedBox(height: 8),
                  Text(
                    amountLabel,
                    style: TextStyle(
                      color: amountColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecurringPastSelectionDot extends StatelessWidget {
  const _RecurringPastSelectionDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? FinanceColors.accentPrimary
              : const Color(0xFF9C9BA4),
          width: selected ? 2.3 : 1.8,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: FinanceColors.accentPrimary,
                ),
              ),
            )
          : null,
    );
  }
}

class FinanceRecurringTransactionDetailScreen extends StatefulWidget {
  const FinanceRecurringTransactionDetailScreen({
    super.key,
    required this.recurringId,
  });

  final String recurringId;

  @override
  State<FinanceRecurringTransactionDetailScreen> createState() =>
      _FinanceRecurringTransactionDetailScreenState();
}

class _FinanceRecurringTransactionDetailScreenState
    extends State<FinanceRecurringTransactionDetailScreen> {
  bool _marking = false;

  String _detailDateLabel(DateTime date) {
    final normalized = recurringNormalizeDate(date);
    final today = recurringNormalizeDate(DateTime.now());
    final dd = normalized.day.toString().padLeft(2, '0');
    final mm = normalized.month.toString().padLeft(2, '0');
    final base = '$dd/$mm/${normalized.year}';
    if (normalized == today) {
      return 'Hôm nay, $base';
    }
    return base;
  }

  String _defaultTitle(FinanceRecurringTransaction recurring) {
    if (recurring.type == TransactionType.expense) {
      return 'Chi tiêu cho ${recurring.category}';
    }
    return 'Thu nhập từ ${recurring.category}';
  }

  bool _showCustomTitle(FinanceRecurringTransaction recurring) {
    final trimmed = recurring.title.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    return trimmed.toLowerCase() != _defaultTitle(recurring).toLowerCase();
  }

  Future<void> _markAsPaid(FinanceRecurringTransaction recurring) async {
    if (_marking) {
      return;
    }
    setState(() => _marking = true);

    final added = await context
        .read<FinanceProvider>()
        .markRecurringTransactionAsPaid(recurringId: recurring.id);
    if (!mounted) {
      return;
    }

    setState(() => _marking = false);

    if (added == null) {
      showAppToast(
        context,
        message: 'Không thể thêm giao dịch lúc này.',
        type: AppToastType.error,
      );
      return;
    }

    showAppToast(
      context,
      message: recurring.type == TransactionType.expense
          ? 'Đánh dấu đã chi'
          : 'Đánh dấu đã thu',
      type: AppToastType.success,
    );
  }

  Future<void> _deleteRecurring(FinanceRecurringTransaction recurring) async {
    final confirmed = await _showDeleteConfirmDialog(recurring);
    if (confirmed != true || !mounted) {
      return;
    }

    await context.read<FinanceProvider>().removeRecurringTransaction(
      recurring.id,
    );
    if (!mounted) {
      return;
    }
    showAppToast(
      context,
      message: recurring.type == TransactionType.expense
          ? 'Đã xóa chi tiêu định kỳ.'
          : 'Đã xóa thu nhập định kỳ.',
      type: AppToastType.success,
    );
    Navigator.of(context).maybePop();
  }

  Future<bool?> _showDeleteConfirmDialog(
    FinanceRecurringTransaction recurring,
  ) {
    final isRecurring = recurring.frequency != 'none';
    final isExpense = recurring.type == TransactionType.expense;
    final title = isRecurring
        ? 'Xóa giao dịch định kỳ?'
        : (isExpense ? 'Xóa chi tiêu' : 'Xóa thu nhập');
    final description = isRecurring
        ? 'Toàn bộ các giao dịch đã lên lịch sẽ bị xóa luôn đó. Bạn chắc chắn muốn xóa chứ?'
        : 'Giao dịch bị xóa sẽ không thể khôi phục lại.';
    final confirmLabel = isRecurring ? 'Xóa giao dịch' : 'Xóa';

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Container(
                    height: 170,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFDECF3),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.auto_delete_rounded,
                        size: 78,
                        color: Color(0xFFD9238F),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: InkWell(
                      onTap: () => Navigator.pop(ctx, false),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFF31343A),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24 / 1.15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2E2E36),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 18 / 1.15,
                        height: 1.32,
                        color: Color(0xFF4B4B54),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            style: TextButton.styleFrom(
                              foregroundColor: FinanceColors.accentPrimary,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Hủy',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: FinanceColors.accentPrimary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              confirmLabel,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editRecurring(FinanceRecurringTransaction recurring) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FinanceRecurringReminderScreen(
          initialType: recurring.type,
          editingRecurringId: recurring.id,
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required Widget value,
    bool hasDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF707079),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(child: value),
            ],
          ),
        ),
        if (hasDivider)
          const Divider(height: 1, thickness: 1, color: Color(0xFFE4E3EA)),
      ],
    );
  }

  Widget _buildBottomActionRow(FinanceRecurringTransaction recurring) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FinanceColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: () => _deleteRecurring(recurring),
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFF2F2F37),
              ),
              label: const Text(
                'Xoá',
                style: TextStyle(
                  color: Color(0xFF2F2F37),
                  fontWeight: FontWeight.w700,
                  fontSize: 20 / 1.2,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(20),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 34,
            child: VerticalDivider(color: Color(0xFFE1DFE7), thickness: 1),
          ),
          Expanded(
            child: TextButton.icon(
              onPressed: () => _editRecurring(recurring),
              icon: const Icon(Icons.edit_outlined, color: Color(0xFF2F2F37)),
              label: const Text(
                'Chỉnh sửa',
                style: TextStyle(
                  color: Color(0xFF2F2F37),
                  fontWeight: FontWeight.w700,
                  fontSize: 20 / 1.2,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final recurring = provider.findRecurringById(widget.recurringId);

    if (recurring == null) {
      return Scaffold(
        backgroundColor: FinanceColors.background,
        appBar: _buildRecurringFlowAppBar(
          context: context,
          title: 'Chi tiết giao dịch',
        ),
        body: const Center(
          child: Text(
            'Giao dịch định kỳ không còn tồn tại.',
            style: TextStyle(
              color: Color(0xFF5E5E66),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final isExpense = recurring.type == TransactionType.expense;
    final amountLabel =
        '${isExpense ? '-' : '+'}${_recurringMoney(recurring.amount)}';
    final fundingVisual = recurringFundingVisualForId(
      recurring.fundingSourceId,
      fallbackLabel: recurring.fundingSourceLabel,
    );
    final categoryIcon =
        recurring.categoryIcon ??
        (isExpense ? Icons.lunch_dining_rounded : Icons.south_west_rounded);
    final categoryColor =
        recurring.categoryIconColor ??
        (isExpense ? const Color(0xFFFF7E45) : const Color(0xFF55AF70));
    final isRepeating = recurring.frequency != 'none';
    final today = recurringNormalizeDate(DateTime.now());
    final nextDate = recurringNormalizeDate(recurring.nextDate);
    final shouldShowMarkPrompt = isRepeating && !nextDate.isAfter(today);
    final note = recurring.note?.trim();

    return Scaffold(
      backgroundColor: FinanceColors.background,
      appBar: _buildRecurringFlowAppBar(
        context: context,
        title: 'Chi tiết giao dịch',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 42),
                padding: const EdgeInsets.fromLTRB(16, 54, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: FinanceColors.border),
                ),
                child: Column(
                  children: [
                    Text(
                      isExpense ? 'Chi tiêu' : 'Thu nhập',
                      style: const TextStyle(
                        color: Color(0xFF6B6B74),
                        fontSize: 22 / 1.15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      amountLabel,
                      style: const TextStyle(
                        color: Color(0xFF2F2F37),
                        fontSize: 30 / 1.08,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (_showCustomTitle(recurring)) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          recurring.title.trim(),
                          style: const TextStyle(
                            color: Color(0xFF3B3B43),
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _buildDetailRow(
                      label: 'Nguồn tiền',
                      value: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: fundingVisual.iconBackground,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              fundingVisual.icon,
                              size: 20,
                              color: fundingVisual.iconColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              fundingVisual.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF2F2F37),
                                fontWeight: FontWeight.w800,
                                fontSize: 20 / 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isRepeating)
                      _buildDetailRow(
                        label: 'Thời gian',
                        value: Text(
                          _detailDateLabel(recurring.startDate),
                          style: const TextStyle(
                            color: Color(0xFF2F2F37),
                            fontWeight: FontWeight.w800,
                            fontSize: 20 / 1.2,
                          ),
                        ),
                      ),
                    if (isRepeating)
                      _buildDetailRow(
                        label: 'Tần suất lặp lại',
                        value: Text(
                          recurringScheduleDetailLabel(recurring),
                          style: const TextStyle(
                            color: Color(0xFF2F2F37),
                            fontWeight: FontWeight.w800,
                            fontSize: 20 / 1.2,
                          ),
                        ),
                      ),
                    if (isRepeating)
                      _buildDetailRow(
                        label: 'Ngày kết thúc',
                        value: Text(
                          recurring.endDate == null
                              ? 'Không bao giờ'
                              : _recurringShortDate(recurring.endDate!),
                          style: const TextStyle(
                            color: Color(0xFF2F2F37),
                            fontWeight: FontWeight.w800,
                            fontSize: 20 / 1.2,
                          ),
                        ),
                      ),
                    _buildDetailRow(
                      label: 'Danh mục',
                      value: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(categoryIcon, color: categoryColor, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            recurring.category,
                            style: const TextStyle(
                              color: Color(0xFF2F2F37),
                              fontWeight: FontWeight.w800,
                              fontSize: 20 / 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isRepeating)
                      _buildDetailRow(
                        label: 'Ngày giao dịch tiếp theo',
                        value: Text(
                          _recurringShortDate(recurring.nextDate),
                          style: const TextStyle(
                            color: Color(0xFF2F2F37),
                            fontWeight: FontWeight.w800,
                            fontSize: 20 / 1.2,
                          ),
                        ),
                        hasDivider: note == null || note.isEmpty,
                      ),
                    if (note != null && note.isNotEmpty)
                      _buildDetailRow(
                        label: 'Ghi chú',
                        value: Text(
                          note,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Color(0xFF2F2F37),
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        hasDivider: false,
                      ),
                    if (shouldShowMarkPrompt) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF4FB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFD7E2F2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCEAFB),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.event_available_rounded,
                                    color: Color(0xFF4D9AE5),
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Bạn đã thanh toán giao dịch này?',
                                        style: TextStyle(
                                          color: Color(0xFF2F2F37),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 17,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Thêm ngay giao dịch này vào báo cáo hôm nay',
                                        style: TextStyle(
                                          color: Color(0xFF676770),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _marking
                                    ? null
                                    : () => _markAsPaid(recurring),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: FinanceColors.accentPrimary,
                                  side: const BorderSide(
                                    color: FinanceColors.accentPrimary,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                child: Text(
                                  _marking
                                      ? 'Đang xử lý...'
                                      : (isExpense
                                            ? 'Đánh dấu đã chi'
                                            : 'Đánh dấu đã thu'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _buildBottomActionRow(recurring),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFF4EE),
                      border: Border.all(color: Colors.white, width: 6),
                    ),
                    child: Icon(
                      isExpense
                          ? Icons.outbound_rounded
                          : Icons.south_west_rounded,
                      size: 44,
                      color: const Color(0xFF2F2F37),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FinanceRecurringReminderScreen extends StatefulWidget {
  const FinanceRecurringReminderScreen({
    super.key,
    this.initialType = TransactionType.expense,
    this.editingRecurringId,
  });

  final TransactionType initialType;
  final String? editingRecurringId;

  @override
  State<FinanceRecurringReminderScreen> createState() =>
      _FinanceRecurringReminderScreenState();
}

class _FinanceRecurringReminderScreenState
    extends State<FinanceRecurringReminderScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController(
    text: '0đ',
  );
  final TextEditingController _noteController = TextEditingController();
  final List<_CustomCategoryItem> _customCategories = <_CustomCategoryItem>[];

  late TransactionType _type;
  late String _selectedFundingSourceId;
  String? _selectedCategory;
  DateTime _startDate = DateTime.now();
  RecurringFrequency _frequency = RecurringFrequency.monthly;
  DateTime? _endDate;
  DateTime? _editingCreatedAt;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _selectedFundingSourceId =
        _TransactionEntryScreenState._fundingSources.first.id;

    final categories = _flattenGroups(_groupsByType(_type));
    _selectedCategory = categories.isEmpty ? null : categories.first;

    _seedFromEditingRecurring();
  }

  void _seedFromEditingRecurring() {
    final recurringId = widget.editingRecurringId;
    if (recurringId == null) {
      return;
    }

    final recurring = context.read<FinanceProvider>().findRecurringById(
      recurringId,
    );
    if (recurring == null) {
      return;
    }

    _editingCreatedAt = recurring.createdAt;
    _type = recurring.type;
    _nameController.text = recurring.title;
    _amountController.text = _inputMoney(recurring.amount);
    _selectedFundingSourceId = recurring.fundingSourceId;
    _startDate = recurring.startDate;
    _frequency = recurringFrequencyFromKey(recurring.frequency);
    _endDate = recurring.endDate;
    _noteController.text = recurring.note ?? '';

    final categories = _flattenGroups(_groupsByType(_type));
    if (categories.contains(recurring.category)) {
      _selectedCategory = recurring.category;
    } else {
      _selectedCategory = categories.isEmpty ? null : categories.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final requireName = widget.editingRecurringId == null;
    final hasName = _nameController.text.trim().isNotEmpty;
    return (!requireName || hasName) &&
        _parseAmount(_amountController.text) > 0 &&
        _selectedCategory != null;
  }

  List<_CategoryGroup> _baseGroupsByType(TransactionType type) {
    return type == TransactionType.expense
        ? _TransactionEntryScreenState._expenseCategoryGroups
        : _TransactionEntryScreenState._incomeCategoryGroups;
  }

  List<_CategoryGroup> _groupsByType(TransactionType type) {
    final groups = _baseGroupsByType(type)
        .map(
          (group) => _CategoryGroup(
            title: group.title,
            icon: group.icon,
            color: group.color,
            categories: List<String>.from(group.categories),
          ),
        )
        .toList();

    final customItems = _customCategories.where((item) => item.type == type);
    for (final item in customItems) {
      final groupIndex = groups.indexWhere((g) => g.title == item.group);
      if (groupIndex < 0) {
        groups.add(
          _CategoryGroup(
            title: item.group,
            icon: item.icon,
            color: item.color,
            categories: [item.name],
          ),
        );
        continue;
      }

      if (!groups[groupIndex].categories.contains(item.name)) {
        groups[groupIndex] = _CategoryGroup(
          title: groups[groupIndex].title,
          icon: groups[groupIndex].icon,
          color: groups[groupIndex].color,
          categories: [...groups[groupIndex].categories, item.name],
        );
      }
    }

    return groups;
  }

  List<String> _flattenGroups(List<_CategoryGroup> groups) {
    final merged = <String>[];
    for (final group in groups) {
      for (final category in group.categories) {
        if (!merged.contains(category)) {
          merged.add(category);
        }
      }
    }
    return merged;
  }

  _CustomCategoryItem? _findCustomCategory(
    String category,
    TransactionType type,
  ) {
    for (final item in _customCategories) {
      if (item.type == type &&
          item.name.toLowerCase() == category.toLowerCase()) {
        return item;
      }
    }
    return null;
  }

  IconData _iconForCategoryWithType(String category, TransactionType type) {
    final custom = _findCustomCategory(category, type);
    if (custom != null) {
      return custom.icon;
    }

    final lower = category.toLowerCase();
    if (type == TransactionType.expense) {
      if (lower.contains('sieu thi') || lower.contains('cho')) {
        return Icons.shopping_basket_outlined;
      }
      if (lower.contains('an uong')) {
        return Icons.restaurant_rounded;
      }
      if (lower.contains('mua sam')) {
        return Icons.shopping_cart_outlined;
      }
      if (lower.contains('di chuyen')) {
        return Icons.directions_bike_rounded;
      }
      if (lower.contains('hoa don')) {
        return Icons.receipt_long_rounded;
      }
      if (lower.contains('nguoi than')) {
        return Icons.child_care_outlined;
      }
      if (lower.contains('nha cua')) {
        return Icons.home_work_outlined;
      }
      if (lower.contains('suc khoe')) {
        return Icons.health_and_safety_outlined;
      }
      if (lower.contains('hoc tap')) {
        return Icons.menu_book_rounded;
      }
      if (lower.contains('tu thien')) {
        return Icons.volunteer_activism_outlined;
      }
    } else {
      if (lower.contains('kinh doanh')) {
        return Icons.trending_up_rounded;
      }
      if (lower.contains('luong')) {
        return Icons.work_outline_rounded;
      }
      if (lower.contains('thuong')) {
        return Icons.emoji_events_outlined;
      }
      if (lower.contains('khac')) {
        return Icons.grid_view_rounded;
      }
    }
    return type == TransactionType.expense
        ? Icons.account_balance_wallet_outlined
        : Icons.savings_outlined;
  }

  Color _categoryIconColor(String category) {
    final custom = _findCustomCategory(category, _type);
    if (custom != null) {
      return custom.color;
    }
    return _type == TransactionType.expense
        ? const Color(0xFF47C7A8)
        : const Color(0xFF8F7CFF);
  }

  _FundingSourceOption get _selectedFundingSource {
    for (final source in _TransactionEntryScreenState._fundingSources) {
      if (source.id == _selectedFundingSourceId) {
        return source;
      }
    }
    return _TransactionEntryScreenState._fundingSources.first;
  }

  void _switchType(TransactionType type) {
    if (_type == type) {
      return;
    }

    setState(() {
      _type = type;
      final categories = _flattenGroups(_groupsByType(type));
      if (_selectedCategory == null ||
          !categories.contains(_selectedCategory)) {
        _selectedCategory = categories.isEmpty ? null : categories.first;
      }
    });
  }

  double _parseAmount(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return 0;
    }
    return double.tryParse(digits) ?? 0;
  }

  String _inputMoney(double value) {
    if (value <= 0) {
      return '0đ';
    }
    final raw = Formatters.currency(value)
        .replaceAll(RegExp(r'\s*VND\s*', caseSensitive: false), '')
        .replaceAll('đ', '')
        .trim();
    return '$rawđ';
  }

  void _handleAmountChanged(String raw) {
    final amount = _parseAmount(raw);
    final formatted = _inputMoney(amount);
    if (formatted != raw) {
      _amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    setState(() {});
  }

  void _registerCreatedCategory(_CreateCategoryResult result) {
    _customCategories.removeWhere(
      (item) =>
          item.type == result.type &&
          item.name.toLowerCase() == result.name.toLowerCase(),
    );
    _customCategories.add(
      _CustomCategoryItem(
        type: result.type,
        name: result.name,
        group: result.group,
        icon: result.icon,
        color: result.color,
      ),
    );
  }

  List<IconData> _usedIconsForType(TransactionType type) {
    final icons = <IconData>[];
    final groups = _groupsByType(type);
    for (final group in groups) {
      for (final category in group.categories) {
        final icon = _iconForCategoryWithType(category, type);
        if (!icons.contains(icon)) {
          icons.add(icon);
        }
      }
    }
    return icons;
  }

  Future<_CreateCategoryResult?> _openCreateCategoryScreen({
    required TransactionType initialType,
  }) {
    return Navigator.of(context).push<_CreateCategoryResult>(
      MaterialPageRoute<_CreateCategoryResult>(
        builder: (_) => _CreateCategoryScreen(
          initialType: initialType,
          parentOptions: _TransactionEntryScreenState._expenseParentOptions,
          expenseIcons:
              _TransactionEntryScreenState._expenseCreateCategoryIcons,
          incomeIcons: _TransactionEntryScreenState._incomeCreateCategoryIcons,
          usedExpenseIcons: _usedIconsForType(TransactionType.expense),
          usedIncomeIcons: _usedIconsForType(TransactionType.income),
          iconPalette: _TransactionEntryScreenState._createIconPalette,
        ),
      ),
    );
  }

  Future<void> _openCategoryPicker() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final searchController = TextEditingController();
        var query = '';

        List<_CategoryGroup> filteredGroups(String value) {
          final trimmed = value.trim().toLowerCase();
          final groups = _groupsByType(_type);
          if (trimmed.isEmpty) {
            return groups;
          }

          final results = <_CategoryGroup>[];
          for (final group in groups) {
            final matches = group.categories
                .where((item) => item.toLowerCase().contains(trimmed))
                .toList();
            if (matches.isNotEmpty) {
              results.add(
                _CategoryGroup(
                  title: group.title,
                  icon: group.icon,
                  color: group.color,
                  categories: matches,
                ),
              );
            }
          }
          return results;
        }

        return StatefulBuilder(
          builder: (context, setModalState) {
            final groups = filteredGroups(query);
            return SafeArea(
              top: false,
              child: Container(
                height: MediaQuery.of(ctx).size.height * 0.82,
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F3F8),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: Column(
                  children: [
                    FinanceModalSheetHeader(
                      title: 'Chọn danh mục',
                      onClose: () => Navigator.pop(ctx),
                      showDivider: false,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              onChanged: (value) => setModalState(() {
                                query = value;
                              }),
                              decoration: InputDecoration(
                                hintText: 'Tìm kiếm',
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Color(0xFF9E9EA6),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final created = await _openCreateCategoryScreen(
                                initialType: _type,
                              );
                              if (!mounted || created == null) {
                                return;
                              }

                              setState(() {
                                _registerCreatedCategory(created);
                                _type = created.type;
                                _selectedCategory = created.name;
                              });

                              if (!mounted) {
                                return;
                              }

                              if (ctx.mounted) {
                                Navigator.pop(ctx, created.name);
                              }
                            },
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Tạo mới'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: FinanceColors.textStrong,
                              side: const BorderSide(
                                color: FinanceColors.borderSoft,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: groups.isEmpty
                          ? const Center(
                              child: Text(
                                'Không tìm thấy danh mục phù hợp',
                                style: TextStyle(
                                  color: Color(0xFF8D8D95),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: groups.length,
                              itemBuilder: (context, index) {
                                final group = groups[index];
                                return _CategoryGroupSection(
                                  group: group,
                                  selectedCategory: _selectedCategory,
                                  iconForCategory: (category) =>
                                      _iconForCategoryWithType(category, _type),
                                  onSelect: (category) {
                                    Navigator.pop(ctx, category);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null) {
      return;
    }

    setState(() {
      _selectedCategory = result;
    });
  }

  Future<void> _openFundingSourcePicker() async {
    final selectedId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Container(
            height: MediaQuery.of(ctx).size.height * 0.56,
            decoration: const BoxDecoration(
              color: Color(0xFFF4F3F8),
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              children: [
                FinanceModalSheetHeader(
                  title: 'Chọn nguồn tiền',
                  onClose: () => Navigator.pop(ctx),
                  showDivider: false,
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    padding: const EdgeInsets.fromLTRB(10, 12, 10, 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE6E2EC)),
                    ),
                    child: GridView.builder(
                      itemCount:
                          _TransactionEntryScreenState._fundingSources.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.64,
                          ),
                      itemBuilder: (context, index) {
                        final source =
                            _TransactionEntryScreenState._fundingSources[index];
                        return _FundingSourceTile(
                          source: source,
                          selected: source.id == _selectedFundingSourceId,
                          onTap: () => Navigator.pop(ctx, source.id),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedId == null) {
      return;
    }

    setState(() {
      _selectedFundingSourceId = selectedId;
    });
  }

  Future<void> _openFrequencySheet() async {
    final selected = await showRecurringFrequencySheet(
      context: context,
      current: _frequency,
      allowNone: true,
      anchorDate: _startDate,
      currentEndDate: _endDate,
      includeEndSection: true,
    );
    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _frequency = selected.frequency;
      _endDate = selected.frequency == RecurringFrequency.none
          ? null
          : selected.endDate;
    });
  }

  Future<void> _openDatePicker() async {
    final isEditing = widget.editingRecurringId != null;
    final isRecurringEdit = isEditing && _frequency != RecurringFrequency.none;
    if (isRecurringEdit) {
      return;
    }

    final selected = await showRecurringDatePickerSheet(
      context: context,
      initialDate: _startDate,
      title: 'Chọn ngày giao dịch',
    );
    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _startDate = selected;
      if (_endDate != null &&
          recurringNormalizeDate(
            _endDate!,
          ).isBefore(recurringNormalizeDate(selected))) {
        _endDate = recurringNormalizeDate(selected);
      }
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit) {
      return;
    }

    final category = _selectedCategory;
    if (category == null) {
      return;
    }

    final amount = _parseAmount(_amountController.text);
    if (amount <= 0) {
      return;
    }

    final now = DateTime.now();
    final normalizedStart = recurringNormalizeDate(_startDate);
    final categoryIcon = _iconForCategoryWithType(category, _type);
    final categoryColor = _categoryIconColor(category);
    final fundingSource = _selectedFundingSource;
    final recurringId =
        widget.editingRecurringId ??
        'rec-${DateTime.now().microsecondsSinceEpoch}';

    final recurring = FinanceRecurringTransaction(
      id: recurringId,
      title: _nameController.text.trim(),
      amount: amount,
      type: _type,
      category: category,
      fundingSourceId: fundingSource.id,
      fundingSourceLabel: fundingSource.label,
      frequency: recurringFrequencyKeyFromEnum(_frequency),
      startDate: normalizedStart,
      endDate: _frequency == RecurringFrequency.none ? null : _endDate,
      nextDate: recurringNextDateFor(
        recurringFrequencyKeyFromEnum(_frequency),
        normalizedStart,
      ),
      createdAt: _editingCreatedAt ?? now,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      categoryIconCodePoint: categoryIcon.codePoint,
      categoryIconFontFamily: categoryIcon.fontFamily,
      categoryIconFontPackage: categoryIcon.fontPackage,
      categoryIconMatchTextDirection: categoryIcon.matchTextDirection,
      categoryIconColorValue: categoryColor.toARGB32(),
    );

    await context.read<FinanceProvider>().addOrUpdateRecurringTransaction(
      recurring,
    );

    if (!mounted) {
      return;
    }

    final isEditing = widget.editingRecurringId != null;
    final successMessage = isEditing
        ? 'Đã cập nhật giao dịch định kỳ.'
        : (_type == TransactionType.expense
              ? 'Thêm khoản chi thành công'
              : 'Thêm khoản thu thành công');
    showAppToast(context, message: successMessage, type: AppToastType.success);

    Navigator.of(context).maybePop();
  }

  Widget _buildFormLabel(String label, {bool requiredMark = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF8D8D95),
                fontWeight: FontWeight.w600,
              ),
              children: [
                TextSpan(text: label),
                if (requiredMark)
                  const TextSpan(
                    text: '*',
                    style: TextStyle(color: Color(0xFFE74C7B)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Divider(height: 1, thickness: 1, color: Color(0xFFE6E2EC)),
          ),
        ],
      ),
    );
  }

  Widget _buildUniformControl(Widget child) {
    return SizedBox(height: 60, child: child);
  }

  String _editDateLabel(DateTime date) {
    final normalized = recurringNormalizeDate(date);
    final today = recurringNormalizeDate(DateTime.now());
    final dd = normalized.day.toString().padLeft(2, '0');
    final mm = normalized.month.toString().padLeft(2, '0');
    final base = '$dd/$mm/${normalized.year}';
    if (normalized == today) {
      return 'Hôm nay, $base';
    }
    const weekdays = <String>[
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7',
      'Chủ nhật',
    ];
    return '${weekdays[normalized.weekday - 1]}, $base';
  }

  List<String> _quickEditCategories() {
    final categories = _flattenGroups(_groupsByType(_type));
    if (categories.length <= 3) {
      return categories;
    }

    final quick = categories.take(3).toList();
    final selected = _selectedCategory;
    if (selected != null &&
        categories.contains(selected) &&
        !quick.contains(selected)) {
      quick[2] = selected;
    }
    return quick;
  }

  Widget _buildEditCategorySelector() {
    final displayQuick = List<String>.from(_quickEditCategories());

    const otherActionLabel = 'Khác';
    const otherActionIcon = Icons.grid_view_rounded;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayQuick.length + 1,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, index) {
        if (index < displayQuick.length) {
          final category = displayQuick[index];
          final selected = category == _selectedCategory;
          final color = selected
              ? FinanceColors.accentPrimary
              : FinanceColors.textStrong;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: selected
                  ? null
                  : () => setState(() {
                      _selectedCategory = category;
                    }),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? FinanceColors.accentPrimary
                        : const Color(0xFFE1DCEA),
                    width: selected ? 1.6 : 1.1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _iconForCategoryWithType(category, _type),
                      color: color,
                      size: 20,
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      height: 18,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Text(
                          category,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: TextStyle(
                            color: color,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _openCategoryPicker,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    otherActionIcon,
                    color: FinanceColors.accentPrimary,
                    size: 22,
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 18,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        otherActionLabel,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: const TextStyle(
                          color: FinanceColors.textStrong,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedFundingSource = _selectedFundingSource;
    final isEditing = widget.editingRecurringId != null;
    final isNonRecurringEdit =
        isEditing && _frequency == RecurringFrequency.none;
    final lockDateForRecurringEdit =
        isEditing && _frequency != RecurringFrequency.none;
    final amountRequired = isNonRecurringEdit;

    return Scaffold(
      backgroundColor: FinanceColors.background,
      appBar: _buildRecurringFlowAppBar(
        context: context,
        title: isEditing ? 'Chỉnh sửa giao dịch' : 'Tạo lời nhắc định kỳ',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: FinanceColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isEditing) ...[
                  FinanceCurvedDualTabBar(
                    leftIcon: Icons.trending_down_rounded,
                    leftLabel: 'Chi tiêu',
                    rightIcon: Icons.trending_up_rounded,
                    rightLabel: 'Thu nhập',
                    selectedIndex: _type == TransactionType.expense ? 0 : 1,
                    onChanged: (index) => _switchType(
                      index == 0
                          ? TransactionType.expense
                          : TransactionType.income,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (!isEditing) ...[
                  _buildFormLabel('Tên lời nhắc', requiredMark: true),
                  _buildUniformControl(
                    _InputContainer(
                      child: TextField(
                        controller: _nameController,
                        onChanged: (_) => setState(() {}),
                        maxLines: 1,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Nhập nội dung lời nhắc',
                          hintStyle: TextStyle(
                            color: Color(0xFF8F8F98),
                            fontWeight: FontWeight.w500,
                          ),
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(
                          color: Color(0xFF303038),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                _buildFormLabel('Số tiền', requiredMark: amountRequired),
                _buildUniformControl(
                  _InputContainer(
                    child: TextField(
                      controller: _amountController,
                      onChanged: _handleAmountChanged,
                      keyboardType: TextInputType.number,
                      maxLines: 1,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(
                        color: Color(0xFF5D5D66),
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildFormLabel('Ngày giao dịch', requiredMark: true),
                _buildUniformControl(
                  _SelectRow(
                    onTap: lockDateForRecurringEdit ? null : _openDatePicker,
                    enabled: !lockDateForRecurringEdit,
                    leading: const SizedBox.shrink(),
                    title: Text(
                      _editDateLabel(_startDate),
                      style: const TextStyle(
                        color: Color(0xFF2F2F37),
                        fontWeight: FontWeight.w700,
                        fontSize: 20 / 1.2,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.calendar_today_rounded,
                      color: FinanceColors.textStrong,
                      size: 22,
                    ),
                  ),
                ),
                if (!isNonRecurringEdit) ...[
                  const SizedBox(height: 10),
                  _buildFormLabel('Tần suất lặp lại'),
                  _buildUniformControl(
                    _SelectRow(
                      onTap: _openFrequencySheet,
                      leading: const SizedBox.shrink(),
                      title: Text(
                        _frequency.label,
                        style: const TextStyle(
                          color: Color(0xFF2F2F37),
                          fontWeight: FontWeight.w700,
                          fontSize: 20 / 1.2,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.expand_more_rounded,
                        color: FinanceColors.textStrong,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                _buildFormLabel('Danh mục', requiredMark: true),
                _buildEditCategorySelector(),
                const SizedBox(height: 10),
                _buildFormLabel('Nguồn tiền', requiredMark: true),
                _buildUniformControl(
                  _SelectRow(
                    onTap: _openFundingSourcePicker,
                    leading: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: selectedFundingSource.iconBackground,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        selectedFundingSource.icon,
                        color: selectedFundingSource.iconColor,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      selectedFundingSource.label,
                      style: const TextStyle(
                        color: FinanceColors.textStrong,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.expand_more_rounded,
                      color: FinanceColors.textStrong,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildFormLabel('Ghi chú'),
                _buildUniformControl(
                  _InputContainer(
                    child: TextField(
                      controller: _noteController,
                      onChanged: (_) => setState(() {}),
                      maxLines: 1,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Nhập mô tả giao dịch',
                        hintStyle: TextStyle(
                          color: Color(0xFFA0A0A8),
                          fontWeight: FontWeight.w500,
                        ),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(
                        color: Color(0xFF34343C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: FinanceBottomBarSurface(
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isEditing && !isNonRecurringEdit)
                const Padding(
                  padding: EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Các chỉnh sửa này chỉ áp dụng cho các giao dịch phát sinh sau ngày hôm nay',
                      style: TextStyle(
                        color: Color(0xFF4A4A52),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: FinancePrimaryActionButton(
                  label: widget.editingRecurringId == null
                      ? 'Thêm lời nhắc định kỳ'
                      : 'Chỉnh sửa',
                  onPressed: _canSubmit ? () => _submit() : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
