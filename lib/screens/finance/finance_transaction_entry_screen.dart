import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/finance_category.dart';
import '../../models/finance_transaction.dart';
import '../../providers/finance_provider.dart';
import '../../providers/sync_provider.dart';
import '../../services/receipt_ocr_service.dart';
import '../../utils/formatters.dart';
import 'finance_screen.dart';
import 'finance_shared_widgets.dart';
import 'finance_styles.dart';

class FinanceTransactionEntryScreen extends StatefulWidget {
  const FinanceTransactionEntryScreen({
    super.key,
    required this.expenseCategories,
    required this.incomeCategories,
    required this.iconForExpenseCategory,
    required this.iconForIncomeCategory,
  });

  final List<String> expenseCategories;
  final List<String> incomeCategories;
  final IconData Function(String) iconForExpenseCategory;
  final IconData Function(String) iconForIncomeCategory;

  @override
  State<FinanceTransactionEntryScreen> createState() =>
      FinanceTransactionEntryScreenState();
}

enum FinanceRecurrenceOption { none, daily, weekly, monthly, yearly }

class FinanceRecurrenceResult {
  const FinanceRecurrenceResult({required this.option, required this.endDate});

  final FinanceRecurrenceOption option;
  final DateTime? endDate;
}

class FinanceCategoryGroup {
  const FinanceCategoryGroup({
    required this.title,
    required this.icon,
    required this.color,
    required this.categories,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> categories;
}

class FinanceCustomCategoryItem {
  const FinanceCustomCategoryItem({
    required this.type,
    required this.name,
    required this.group,
    required this.icon,
    required this.color,
  });

  final TransactionType type;
  final String name;
  final String group;
  final IconData icon;
  final Color color;
}

class FinanceParentCategoryOption {
  const FinanceParentCategoryOption({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final IconData icon;
  final Color color;
}

class FinanceCreateCategoryResult {
  const FinanceCreateCategoryResult({
    required this.type,
    required this.name,
    required this.group,
    required this.icon,
    required this.color,
  });

  final TransactionType type;
  final String name;
  final String group;
  final IconData icon;
  final Color color;
}

class FinanceTransactionEntryScreenState extends State<FinanceTransactionEntryScreen> {
  static const Color _accentPink = FinanceColors.accentPrimary;
  static const Color _borderColor = FinanceColors.borderSoft;
  static const String _fundingSourceOtherSmartLifeId =
      FinanceTransaction.defaultFundingSourceId;

  static String normalizeFundingSourceId(String sourceId) {
    return FinanceTransaction.normalizeFundingSourceId(sourceId);
  }

  static const List<String> _quickExpenseCategories = [
    'Ăn uống',
    'Mua sắm',
    'Người thân',
  ];
  static const List<String> _quickIncomeCategories = [
    'Kinh doanh',
    'Lương',
    'Thưởng',
  ];
  static const List<FinanceCategoryGroup> _expenseCategoryGroups = [
    FinanceCategoryGroup(
      title: 'Chi tiêu - sinh hoạt',
      icon: Icons.receipt_long_outlined,
      color: Color(0xFFFFB251),
      categories: ['Chợ, siêu thị', 'Ăn uống', 'Di chuyển'],
    ),
    FinanceCategoryGroup(
      title: 'Chi phí phát sinh',
      icon: Icons.layers_outlined,
      color: Color(0xFFFFB251),
      categories: ['Mua sắm', 'Giải trí', 'Làm đẹp', 'Sức khỏe', 'Từ thiện'],
    ),
    FinanceCategoryGroup(
      title: 'Chi phí cố định',
      icon: Icons.home_work_outlined,
      color: Color(0xFF58A5FF),
      categories: ['Hóa đơn', 'Nhà cửa', 'Người thân'],
    ),
    FinanceCategoryGroup(
      title: 'Đầu tư - tiết kiệm',
      icon: Icons.savings_outlined,
      color: Color(0xFF46C7B8),
      categories: ['Đầu tư', 'Học tập'],
    ),
    FinanceCategoryGroup(
      title: 'Khác',
      icon: Icons.grid_view_rounded,
      color: Color(0xFF8E8EA0),
      categories: ['Khác'],
    ),
  ];
  static const List<FinanceCategoryGroup> _incomeCategoryGroups = [
    FinanceCategoryGroup(
      title: 'Thu nhập',
      icon: Icons.payments_outlined,
      color: Color(0xFFFF8A5B),
      categories: ['Kinh doanh', 'Lương', 'Thưởng', 'Khác'],
    ),
  ];

  static const List<FinanceParentCategoryOption> _expenseParentOptions = [
    FinanceParentCategoryOption(
      title: 'Chi tiêu - sinh hoạt',
      icon: Icons.receipt_long_outlined,
      color: Color(0xFFF6AB3D),
    ),
    FinanceParentCategoryOption(
      title: 'Chi phí phát sinh',
      icon: Icons.layers_outlined,
      color: Color(0xFFF2C252),
    ),
    FinanceParentCategoryOption(
      title: 'Chi phí cố định',
      icon: Icons.home_work_outlined,
      color: Color(0xFFF5B254),
    ),
    FinanceParentCategoryOption(
      title: 'Đầu tư - tiết kiệm',
      icon: Icons.savings_outlined,
      color: Color(0xFF70D7BD),
    ),
    FinanceParentCategoryOption(
      title: 'Khác',
      icon: Icons.grid_view_rounded,
      color: Color(0xFFA5A5B6),
    ),
  ];

  static const List<IconData> _expenseCreateCategoryIcons = [
    Icons.apartment_rounded,
    Icons.favorite_rounded,
    Icons.grid_view_rounded,
    Icons.desktop_mac_rounded,
    Icons.airplane_ticket_rounded,
    Icons.local_cafe_rounded,
    Icons.checkroom_rounded,
    Icons.menu_book_rounded,
    Icons.pets_rounded,
    Icons.fitness_center_rounded,
    Icons.shopping_cart_rounded,
    Icons.baby_changing_station_rounded,
    Icons.theater_comedy_rounded,
    Icons.sports_bar_rounded,
    Icons.business_center_rounded,
    Icons.bakery_dining_rounded,
    Icons.directions_car_filled_rounded,
    Icons.school_rounded,
    Icons.water_drop_rounded,
    Icons.shopping_basket_rounded,
    Icons.smoking_rooms_rounded,
    Icons.toys_rounded,
    Icons.public_rounded,
    Icons.volunteer_activism_rounded,
    Icons.emoji_food_beverage_rounded,
    Icons.payments_rounded,
    Icons.home_rounded,
    Icons.handshake_rounded,
    Icons.movie_creation_outlined,
    Icons.health_and_safety_rounded,
    Icons.lightbulb_outline_rounded,
    Icons.local_gas_station_rounded,
    Icons.receipt_long_rounded,
    Icons.propane_tank_rounded,
    Icons.spa_rounded,
    Icons.inventory_2_rounded,
    Icons.home_repair_service_rounded,
    Icons.tv_rounded,
    Icons.savings_rounded,
    Icons.content_cut_rounded,
    Icons.restaurant_rounded,
    Icons.flight_rounded,
    Icons.two_wheeler_rounded,
    Icons.home_work_rounded,
    Icons.location_city_rounded,
    Icons.shield_outlined,
    Icons.directions_car_rounded,
    Icons.local_hospital_rounded,
    Icons.local_parking_rounded,
    Icons.phone_in_talk_rounded,
    Icons.child_friendly_rounded,
    Icons.waving_hand_rounded,
    Icons.shopping_bag_rounded,
    Icons.train_rounded,
    Icons.chair_alt_rounded,
    Icons.description_rounded,
    Icons.headphones_rounded,
    Icons.laptop_mac_rounded,
    Icons.weekend_rounded,
    Icons.electric_bolt_rounded,
    Icons.monitor_heart_rounded,
    Icons.card_giftcard_rounded,
    Icons.trending_up_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.settings_rounded,
    Icons.sports_basketball_rounded,
    Icons.dry_cleaning_rounded,
    Icons.soup_kitchen_rounded,
    Icons.medical_services_rounded,
    Icons.groups_rounded,
    Icons.local_bar_rounded,
    Icons.person_rounded,
  ];

  static const List<IconData> _incomeCreateCategoryIcons = [
    Icons.sports_esports_rounded,
    Icons.price_change_rounded,
    Icons.card_giftcard_rounded,
    Icons.receipt_long_rounded,
    Icons.payments_outlined,
    Icons.people_alt_rounded,
    Icons.discount_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.credit_card_rounded,
    Icons.swap_horiz_rounded,
    Icons.volunteer_activism_rounded,
    Icons.account_balance_rounded,
    Icons.payments_rounded,
    Icons.sports_bar_rounded,
    Icons.savings_rounded,
    Icons.trending_up_rounded,
    Icons.point_of_sale_rounded,
    Icons.attach_money_rounded,
    Icons.restaurant_rounded,
    Icons.arrow_circle_down_rounded,
    Icons.house_rounded,
    Icons.shopping_bag_rounded,
    Icons.directions_car_filled_rounded,
    Icons.groups_rounded,
    Icons.home_rounded,
    Icons.currency_bitcoin_rounded,
    Icons.token_rounded,
  ];

  static const List<Color> _createIconPalette = [
    Color(0xFFF6AB3D),
    Color(0xFFF27D95),
    Color(0xFF8ABAFD),
    Color(0xFF63D2B5),
    Color(0xFFA79BFF),
    Color(0xFFFF8A5B),
    Color(0xFFF5C954),
    Color(0xFF6AD6C0),
    Color(0xFF58A5FF),
    Color(0xFFFF6D7A),
  ];

  static List<FinanceCategoryGroup> get expenseCategoryGroups =>
      _expenseCategoryGroups;
  static List<FinanceCategoryGroup> get incomeCategoryGroups =>
      _incomeCategoryGroups;
  static List<FinanceParentCategoryOption> get expenseParentOptions =>
      _expenseParentOptions;
  static List<IconData> get expenseCreateCategoryIcons =>
      _expenseCreateCategoryIcons;
  static List<IconData> get incomeCreateCategoryIcons =>
      _incomeCreateCategoryIcons;
  static List<Color> get createIconPalette => _createIconPalette;

  final TextEditingController _amountController = TextEditingController(
    text: '0đ',
  );
  final FocusNode _amountFocusNode = FocusNode();
  final TextEditingController _noteController = TextEditingController();
  final ReceiptOcrService _ocrService = ReceiptOcrService();
  final List<FinanceCustomCategoryItem> _customCategories = [];
  final List<IconData> _createdExpenseIcons = [];
  final List<IconData> _createdIncomeIcons = [];
  final List<String> _expenseQuickQueue = List<String>.from(
    _quickExpenseCategories,
  );
  final List<String> _incomeQuickQueue = List<String>.from(
    _quickIncomeCategories,
  );

  bool _imageMode = false;
  bool _isProcessingOcr = false;
  TransactionType _type = TransactionType.expense;
  String? _selectedCategory;
  String _selectedFundingSourceId = _fundingSourceOtherSmartLifeId;
  String? _titleOverride;
  DateTime _selectedDate = DateTime.now();
  FinanceRecurrenceOption _recurrence = FinanceRecurrenceOption.none;
  DateTime? _recurrenceEndDate;

  @override
  void initState() {
    super.initState();
    _selectedCategory = _quickCategories.first;
    _amountFocusNode.addListener(_onAmountFocusChanged);
    _hydrateCustomCategoriesFromStorage();
  }

  @override
  void dispose() {
    _amountFocusNode.removeListener(_onAmountFocusChanged);
    _amountFocusNode.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onAmountFocusChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _hydrateCustomCategoriesFromStorage() {
    final stored = context.read<FinanceProvider>().customCategories;
    if (stored.isEmpty) {
      return;
    }

    for (final category in stored) {
      _registerRestoredCategory(category);
    }
  }

  void _registerRestoredCategory(FinanceCategory category) {
    _customCategories.removeWhere(
      (item) =>
          item.type == category.type &&
          item.name.toLowerCase() == category.name.toLowerCase(),
    );
    _customCategories.add(
      FinanceCustomCategoryItem(
        type: category.type,
        name: category.name,
        group: category.group,
        icon: category.icon,
        color: category.color,
      ),
    );

    final createdIconQueue = category.type == TransactionType.expense
        ? _createdExpenseIcons
        : _createdIncomeIcons;
    if (!createdIconQueue.contains(category.icon)) {
      createdIconQueue.add(category.icon);
    }
  }

  FinanceCategory _toFinanceCategoryModel(FinanceCreateCategoryResult result) {
    final normalizedName = result.name.trim();
    return FinanceCategory(
      id: FinanceCategory.buildStableId(
        type: result.type,
        name: normalizedName,
      ),
      type: result.type,
      name: normalizedName,
      group: result.group,
      iconCodePoint: result.icon.codePoint,
      iconFontFamily: result.icon.fontFamily,
      iconFontPackage: result.icon.fontPackage,
      iconMatchTextDirection: result.icon.matchTextDirection,
      colorValue: result.color.toARGB32(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _persistCreatedCategory(FinanceCreateCategoryResult result) async {
    final model = _toFinanceCategoryModel(result);
    await context.read<FinanceProvider>().addOrUpdateCustomCategory(model);
    if (!mounted) {
      return;
    }
    context.read<SyncProvider>().queueAction(
      entity: 'finance_category',
      entityId: model.id,
      payload: {'operation': 'upsert', 'category': model.toMap()},
    );
  }

  List<String> get _quickCategories =>
      _type == TransactionType.expense ? _expenseQuickQueue : _incomeQuickQueue;

  List<String> _quickQueueForType(TransactionType type) {
    return type == TransactionType.expense
        ? _expenseQuickQueue
        : _incomeQuickQueue;
  }

  int _quickQueueLimitForType(TransactionType type) {
    return type == TransactionType.expense
        ? _quickExpenseCategories.length
        : _quickIncomeCategories.length;
  }

  bool _isSameCategory(String? a, String? b) {
    if (a == null || b == null) {
      return false;
    }
    return a.trim().toLowerCase() == b.trim().toLowerCase();
  }

  void _pinCategoryToQuickFront(String category, {TransactionType? type}) {
    final normalized = category.trim();
    if (normalized.isEmpty) {
      return;
    }

    final targetType = type ?? _type;
    final queue = _quickQueueForType(targetType);
    queue.removeWhere((item) => item.toLowerCase() == normalized.toLowerCase());
    queue.insert(0, normalized);

    final limit = _quickQueueLimitForType(targetType);
    if (queue.length > limit) {
      queue.removeRange(limit, queue.length);
    }
  }

  FinanceFundingSourceOption get _selectedFundingSource {
    final selectedId = normalizeFundingSourceId(_selectedFundingSourceId);
    return FinanceFundingSourceCatalog.findByNormalizedId(selectedId) ??
        FinanceFundingSourceCatalog.options.first;
  }

  List<FinanceCategoryGroup> _groupsByType(TransactionType type) {
    final baseGroups = type == TransactionType.expense
        ? _expenseCategoryGroups
        : _incomeCategoryGroups;
    final groups = baseGroups
        .map(
          (group) => FinanceCategoryGroup(
            title: group.title,
            icon: group.icon,
            color: group.color,
            categories: List<String>.from(group.categories),
          ),
        )
        .toList();

    final custom = _customCategories
        .where((item) => item.type == type)
        .toList(growable: false);
    for (final item in custom) {
      final groupIndex = groups.indexWhere(
        (group) => group.title == item.group,
      );
      if (groupIndex < 0) {
        groups.add(
          FinanceCategoryGroup(
            title: item.group,
            icon: item.icon,
            color: item.color,
            categories: [item.name],
          ),
        );
        continue;
      }

      if (!groups[groupIndex].categories.contains(item.name)) {
        groups[groupIndex] = FinanceCategoryGroup(
          title: groups[groupIndex].title,
          icon: groups[groupIndex].icon,
          color: groups[groupIndex].color,
          categories: [...groups[groupIndex].categories, item.name],
        );
      }
    }

    return groups;
  }

  List<String> _flattenGroups(List<FinanceCategoryGroup> groups) {
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

  FinanceCustomCategoryItem? _findCustomCategory(
    String category,
    TransactionType type,
  ) {
    for (final item in _customCategories) {
      if (item.type == type && item.name == category) {
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

    final isExpense = type == TransactionType.expense;
    return FinanceCategoryVisualCatalog.iconFor(
      category,
      isExpense: isExpense,
      fallbackIcon: isExpense
          ? widget.iconForExpenseCategory(category)
          : widget.iconForIncomeCategory(category),
    );
  }

  IconData _iconForCategory(String category) {
    return _iconForCategoryWithType(category, _type);
  }

  Color _iconColorForCategoryWithType(String category, TransactionType type) {
    final custom = _findCustomCategory(category, type);
    if (custom != null) {
      return custom.color;
    }

    final isExpense = type == TransactionType.expense;
    return FinanceCategoryVisualCatalog.colorFor(
      category,
      isExpense: isExpense,
      fallbackColor: isExpense
          ? const Color(0xFF47C7A8)
          : const Color(0xFF8F7CFF),
    );
  }

  Color _iconColorForCategory(String category) {
    return _iconColorForCategoryWithType(category, _type);
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

  void _applyAmountSuggestion(double amount) {
    final formatted = _inputMoney(amount);
    _amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    setState(() {});
  }

  bool _showAmountSuggestions(BuildContext context) {
    final platform = Theme.of(context).platform;
    final isMobile =
        platform == TargetPlatform.android || platform == TargetPlatform.iOS;
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return isMobile &&
        !_imageMode &&
        keyboardVisible &&
        _amountFocusNode.hasFocus;
  }

  List<double> _dynamicAmountSuggestions() {
    final digits = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final base = int.tryParse(digits) ?? 0;
    if (base <= 0) {
      return const [100000, 1000000, 10000000];
    }

    final values = <double>[];
    for (final factor in [1000, 10000, 100000]) {
      final value = (base * factor).toDouble();
      if (!values.contains(value)) {
        values.add(value);
      }
    }
    return values;
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

  String _dateLabel() {
    final now = DateTime.now();
    final normalizedNow = DateTime(now.year, now.month, now.day);
    final normalizedSelected = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final dd = _selectedDate.day.toString().padLeft(2, '0');
    final mm = _selectedDate.month.toString().padLeft(2, '0');
    final label = '$dd/$mm/${_selectedDate.year}';
    if (normalizedSelected == normalizedNow) {
      return 'Hôm nay, $label';
    }
    return label;
  }

  Future<void> _selectDate() async {
    final picked = await _showDatePickerSheet(
      title: 'Chọn ngày giao dịch',
      initialDate: _selectedDate,
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _selectedDate = picked;
    });
  }

  String _formatShortDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd/$mm/${date.year}';
  }

  String get _recurrenceLabel {
    return _recurrenceLabelFor(_recurrence);
  }

  String _recurrenceLabelFor(FinanceRecurrenceOption option) {
    switch (option) {
      case FinanceRecurrenceOption.none:
        return 'Không lặp lại';
      case FinanceRecurrenceOption.daily:
        return 'Hàng ngày';
      case FinanceRecurrenceOption.weekly:
        return 'Hàng tuần';
      case FinanceRecurrenceOption.monthly:
        return 'Hàng tháng';
      case FinanceRecurrenceOption.yearly:
        return 'Hàng năm';
    }
  }

  Future<void> _openCategoryPicker() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final searchController = TextEditingController();
        var query = '';

        List<FinanceCategoryGroup> filteredGroups(String value) {
          final trimmed = value.trim().toLowerCase();
          final groups = _groupsByType(_type);
          if (trimmed.isEmpty) {
            return groups;
          }
          final results = <FinanceCategoryGroup>[];
          for (final group in groups) {
            final matches = group.categories
                .where((item) => item.toLowerCase().contains(trimmed))
                .toList();
            if (matches.isNotEmpty) {
              results.add(
                FinanceCategoryGroup(
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
            return FinanceSheetScaffold(
              heightFactor: 0.82,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 10, 8),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Chọn danh mục',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: FinanceColors.textStrong,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, size: 30),
                          color: FinanceColors.sheetCloseIcon,
                        ),
                      ],
                    ),
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
                                color: FinanceColors.textMuted,
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
                              _pinCategoryToQuickFront(
                                created.name,
                                type: created.type,
                              );
                            });
                            await _persistCreatedCategory(created);
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
                            side: const BorderSide(color: _borderColor),
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
                              return FinanceCategoryGroupSection(
                                group: group,
                                selectedCategory: _selectedCategory,
                                iconForCategory: _iconForCategory,
                                iconColorForCategory: _iconColorForCategory,
                                onSelect: (category) {
                                  Navigator.pop(ctx, category);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result == null) {
      return;
    }

    if (_isSameCategory(_selectedCategory, result)) {
      return;
    }

    setState(() {
      _selectedCategory = result;
      _pinCategoryToQuickFront(result);
    });
  }

  void _registerCreatedCategory(FinanceCreateCategoryResult result) {
    _customCategories.removeWhere(
      (item) =>
          item.type == result.type &&
          item.name.toLowerCase() == result.name.toLowerCase(),
    );
    _customCategories.add(
      FinanceCustomCategoryItem(
        type: result.type,
        name: result.name,
        group: result.group,
        icon: result.icon,
        color: result.color,
      ),
    );
    final createdIconQueue = result.type == TransactionType.expense
        ? _createdExpenseIcons
        : _createdIncomeIcons;
    createdIconQueue.remove(result.icon);
    createdIconQueue.insert(0, result.icon);
  }

  List<IconData> _usedIconsForType(TransactionType type) {
    final used = <IconData>[];

    void addUsedIcon(IconData icon) {
      if (!used.contains(icon)) {
        used.add(icon);
      }
    }

    final createdIconQueue = type == TransactionType.expense
        ? _createdExpenseIcons
        : _createdIncomeIcons;
    for (final icon in createdIconQueue) {
      addUsedIcon(icon);
    }

    final groups = _groupsByType(type);
    for (final group in groups) {
      for (final category in group.categories) {
        final icon = _iconForCategoryWithType(category, type);
        addUsedIcon(icon);
      }
    }
    final limit = type == TransactionType.expense ? 18 : 8;
    if (used.length <= limit) {
      return used;
    }
    return used.take(limit).toList();
  }

  Future<FinanceCreateCategoryResult?> _openCreateCategoryScreen({
    required TransactionType initialType,
  }) async {
    return Navigator.of(context).push<FinanceCreateCategoryResult>(
      MaterialPageRoute<FinanceCreateCategoryResult>(
        builder: (_) => FinanceCreateCategoryScreen(
          initialType: initialType,
          parentOptions: _expenseParentOptions,
          expenseIcons: _expenseCreateCategoryIcons,
          incomeIcons: _incomeCreateCategoryIcons,
          usedExpenseIcons: _usedIconsForType(TransactionType.expense),
          usedIncomeIcons: _usedIconsForType(TransactionType.income),
          iconPalette: _createIconPalette,
        ),
      ),
    );
  }

  Future<void> _openFundingSourcePicker() async {
    final selectedId = await showFinanceFundingSourcePicker(
      context: context,
      selectedSourceId: _selectedFundingSourceId,
      headerStyle: FinanceFundingSourcePickerHeaderStyle.legacy,
    );

    if (selectedId == null) {
      return;
    }
    setState(() {
      _selectedFundingSourceId = normalizeFundingSourceId(selectedId);
    });
  }

  Future<void> _openRecurrenceSheet() async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final result = await showModalBottomSheet<FinanceRecurrenceResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        var tempOption = _recurrence;
        var tempEndDate = _recurrenceEndDate;
        if (tempEndDate != null) {
          final normalized = DateTime(
            tempEndDate.year,
            tempEndDate.month,
            tempEndDate.day,
          );
          if (normalized.isBefore(todayDate)) {
            tempEndDate = todayDate;
          }
        }

        return StatefulBuilder(
          builder: (context, setModalState) {
            final isRepeat = tempOption != FinanceRecurrenceOption.none;
            final endLabel = tempEndDate == null
                ? 'Không bao giờ'
                : _formatShortDate(tempEndDate!);
            return FinanceSheetScaffold(
              heightFactor: 0.72,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 10, 12),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Tần suất lặp lại',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: FinanceColors.textStrong,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, size: 30),
                          color: FinanceColors.sheetCloseIcon,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                            border: Border.all(color: _borderColor),
                          ),
                          child: Column(
                            children: [
                              FinanceRecurrenceOptionTile(
                                label: 'Không lặp lại',
                                selected: tempOption == FinanceRecurrenceOption.none,
                                onTap: () => setModalState(() {
                                  tempOption = FinanceRecurrenceOption.none;
                                  tempEndDate = null;
                                }),
                                isFirst: true,
                              ),
                              FinanceRecurrenceDivider(),
                              FinanceRecurrenceOptionTile(
                                label: 'Hàng ngày',
                                selected: tempOption == FinanceRecurrenceOption.daily,
                                onTap: () => setModalState(() {
                                  tempOption = FinanceRecurrenceOption.daily;
                                }),
                              ),
                              FinanceRecurrenceDivider(),
                              FinanceRecurrenceOptionTile(
                                label: 'Hàng tuần',
                                selected:
                                    tempOption == FinanceRecurrenceOption.weekly,
                                onTap: () => setModalState(() {
                                  tempOption = FinanceRecurrenceOption.weekly;
                                }),
                              ),
                              FinanceRecurrenceDivider(),
                              FinanceRecurrenceOptionTile(
                                label: 'Hàng tháng',
                                selected:
                                    tempOption == FinanceRecurrenceOption.monthly,
                                onTap: () => setModalState(() {
                                  tempOption = FinanceRecurrenceOption.monthly;
                                }),
                              ),
                              FinanceRecurrenceDivider(),
                              FinanceRecurrenceOptionTile(
                                label: 'Hàng năm',
                                selected:
                                    tempOption == FinanceRecurrenceOption.yearly,
                                onTap: () => setModalState(() {
                                  tempOption = FinanceRecurrenceOption.yearly;
                                }),
                                isLast: true,
                              ),
                            ],
                          ),
                        ),
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
                        FinanceSelectRow(
                          enabled: isRepeat,
                          onTap: () async {
                            if (!isRepeat) {
                              return;
                            }
                            final picked = await _showDatePickerSheet(
                              title: 'Chọn ngày kết thúc',
                              initialDate: tempEndDate ?? DateTime.now(),
                              minimumDate: todayDate,
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
                        if (isRepeat) ...[
                          const SizedBox(height: 18),
                          Text(
                            'SmartLife sẽ nhắc bạn ${_recurrenceLabelFor(tempOption).toLowerCase()}',
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
                      onPressed: () => Navigator.pop(
                        ctx,
                        FinanceRecurrenceResult(
                          option: tempOption,
                          endDate: tempOption == FinanceRecurrenceOption.none
                              ? null
                              : tempEndDate,
                        ),
                      ),
                    ),
                  ),
                ],
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
      _recurrence = result.option;
      _recurrenceEndDate = result.option == FinanceRecurrenceOption.none
          ? null
          : result.endDate;
    });
  }

  Future<DateTime?> _showDatePickerSheet({
    required String title,
    required DateTime initialDate,
    DateTime? minimumDate,
  }) async {
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
            final monthLabel =
                'Tháng ${displayMonth.month}/${displayMonth.year}';
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
            return FinanceSheetScaffold(
              heightFactor: 0.64,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 10, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Center(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: FinanceColors.textStrong,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, size: 30),
                          color: FinanceColors.sheetCloseIcon,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: FinanceColors.panelBorder),
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
                                FinanceWeekdayLabel(text: 'T2'),
                                FinanceWeekdayLabel(text: 'T3'),
                                FinanceWeekdayLabel(text: 'T4'),
                                FinanceWeekdayLabel(text: 'T5'),
                                FinanceWeekdayLabel(text: 'T6'),
                                FinanceWeekdayLabel(text: 'T7', isWeekend: true),
                                FinanceWeekdayLabel(text: 'CN', isWeekend: true),
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
            );
          },
        );
      },
    );
  }

  bool get _canSubmit {
    return _parseAmount(_amountController.text) > 0 &&
        _selectedCategory != null;
  }

  void _submit() {
    if (!_canSubmit) {
      return;
    }
    final category = _selectedCategory ?? _quickCategories.first;
    final amount = _parseAmount(_amountController.text);
    final title = (_titleOverride ?? category).trim();
    final note = _noteController.text.trim();
    final fundingSource = _selectedFundingSource;
    final categoryIcon = _iconForCategory(category);
    final categoryIconColor = _iconColorForCategory(category);
    final tx = FinanceTransaction(
      id: 'trx-${DateTime.now().microsecondsSinceEpoch}',
      title: title.isEmpty ? category : title,
      amount: amount,
      category: category,
      type: _type,
      createdAt: _selectedDate,
      note: note.isEmpty ? null : note,
      fundingSourceId: fundingSource.id,
      fundingSourceLabel: fundingSource.label,
      categoryIconCodePoint: categoryIcon.codePoint,
      categoryIconFontFamily: categoryIcon.fontFamily,
      categoryIconFontPackage: categoryIcon.fontPackage,
      categoryIconMatchTextDirection: categoryIcon.matchTextDirection,
      categoryIconColorValue: categoryIconColor.toARGB32(),
    );
    context.read<FinanceProvider>().addTransaction(tx);
    context.read<SyncProvider>().queueAction(
      entity: 'finance',
      entityId: tx.id,
      payload: {'operation': 'upsert', 'transaction': tx.toMap()},
    );
    Navigator.of(context).pop();
  }

  void _switchEntryMode(bool imageMode) {
    FocusScope.of(context).unfocus();
    setState(() {
      _imageMode = imageMode;
    });
  }

  void _switchType(TransactionType type) {
    if (_type == type) {
      return;
    }

    FocusScope.of(context).unfocus();
    _amountController.value = const TextEditingValue(
      text: '0đ',
      selection: TextSelection.collapsed(offset: 2),
    );
    _noteController.clear();

    setState(() {
      _type = type;
      final quick = _quickCategories;
      _selectedCategory = quick.isEmpty ? null : quick.first;
      _selectedFundingSourceId = _fundingSourceOtherSmartLifeId;
      _titleOverride = null;
      _selectedDate = DateTime.now();
      _recurrence = FinanceRecurrenceOption.none;
      _recurrenceEndDate = null;
    });
  }

  String _resolveCategory(String raw, TransactionType type) {
    final normalized = raw.trim().toLowerCase();
    final options = type == TransactionType.expense
        ? _flattenGroups(_groupsByType(TransactionType.expense))
        : _flattenGroups(_groupsByType(TransactionType.income));
    final quickFallback = type == TransactionType.expense
        ? _quickExpenseCategories.first
        : _quickIncomeCategories.first;
    final fallback = options.contains(quickFallback)
        ? quickFallback
        : options.first;
    if (normalized.isEmpty) {
      return fallback;
    }
    for (final option in options) {
      if (option.toLowerCase() == normalized) {
        return option;
      }
    }
    if (type == TransactionType.expense) {
      if (normalized.contains('ăn') ||
          normalized.contains('uong') ||
          normalized.contains('uống')) {
        return options.contains('Ăn uống') ? 'Ăn uống' : fallback;
      }
      if (normalized.contains('mua') || normalized.contains('shop')) {
        return options.contains('Mua sắm') ? 'Mua sắm' : fallback;
      }
      if (normalized.contains('người thân') ||
          normalized.contains('gia đình') ||
          normalized.contains('gia dinh')) {
        return options.contains('Người thân') ? 'Người thân' : fallback;
      }
    } else {
      if (normalized.contains('kinh doanh') ||
          normalized.contains('ban') ||
          normalized.contains('bán')) {
        return options.contains('Kinh doanh') ? 'Kinh doanh' : fallback;
      }
      if (normalized.contains('luong') || normalized.contains('lương')) {
        return options.contains('Lương') ? 'Lương' : fallback;
      }
      if (normalized.contains('thuong') || normalized.contains('thưởng')) {
        return options.contains('Thưởng') ? 'Thưởng' : fallback;
      }
    }
    return fallback;
  }

  Future<void> _pickReceiptImage() async {
    if (_isProcessingOcr) {
      return;
    }
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) {
      return;
    }
    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      return;
    }
    setState(() {
      _isProcessingOcr = true;
    });
    final result = await _ocrService.parseReceipt(
      imageBytes: bytes,
      filename: file.name,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _isProcessingOcr = false;
    });
    if (result == null) {
      _showHint(
        'OCR không trả về dữ liệu. Kiểm tra OCR_API_KEY hoặc thử ảnh rõ hơn.',
      );
      return;
    }

    final category = _resolveCategory(result.category, TransactionType.expense);
    setState(() {
      _imageMode = false;
      _type = TransactionType.expense;
      _selectedCategory = category;
      _titleOverride = result.title;
      _amountController.text = _inputMoney(result.amount);
      _noteController.text =
          'OCR: ${result.rawText.substring(0, result.rawText.length > 200 ? 200 : result.rawText.length)}';
    });
    _showHint('Đã nhận dữ liệu từ ảnh, kiểm tra lại trước khi lưu.');
  }

  void _showHint(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final actionLabel = _imageMode
        ? 'Chọn ảnh ngay'
        : _type == TransactionType.expense
        ? 'Thêm giao dịch chi'
        : 'Thêm giao dịch thu';
    final canSubmit = _imageMode ? !_isProcessingOcr : _canSubmit;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4F9),
      appBar: const FinanceGradientAppBar(title: 'Ghi chép GD'),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildEntryTabs(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                child: Column(
                  children: [
                    if (!_imageMode) const SizedBox(height: 2),
                    _imageMode ? _buildImageEntry() : _buildManualEntry(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: FinanceBottomBarSurface(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_showAmountSuggestions(context))
                  FinanceMoneySuggestionChips(
                    suggestions: _dynamicAmountSuggestions(),
                    onSelected: _applyAmountSuggestion,
                    topPadding: 0,
                    expanded: true,
                  ),
                if (_showAmountSuggestions(context)) const SizedBox(height: 10),
                FinancePrimaryActionButton(
                  label: actionLabel,
                  onPressed: canSubmit
                      ? (_imageMode ? _pickReceiptImage : _submit)
                      : null,
                  isLoading: _isProcessingOcr && _imageMode,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEntryTabs() {
    return Container(
      padding: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: Row(
        children: [
          _EntryTopTab(
            icon: Icons.note_add_outlined,
            label: 'Nhập thủ công',
            active: !_imageMode,
            onTap: () => _switchEntryMode(false),
          ),
          _EntryTopTab(
            icon: Icons.auto_fix_high_outlined,
            label: 'Nhập bằng ảnh',
            active: _imageMode,
            onTap: () => _switchEntryMode(true),
          ),
        ],
      ),
    );
  }

  Widget _buildManualEntry() {
    final selectedSource = _selectedFundingSource;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTypeToggle(),
          const SizedBox(height: 16),
          _FieldLabel(label: 'Số tiền', requiredMark: true),
          FinanceInputContainer(
            child: TextField(
              controller: _amountController,
              focusNode: _amountFocusNode,
              keyboardType: TextInputType.number,
              onChanged: _handleAmountChanged,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: FinanceColors.textStrong,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _FieldLabel(label: 'Danh mục', requiredMark: true),
          _buildCategoryGrid(),
          const SizedBox(height: 12),
          _FieldLabel(label: 'Ngày giao dịch', requiredMark: true),
          FinanceSelectRow(
            onTap: _selectDate,
            leading: const SizedBox.shrink(),
            title: Text(
              _dateLabel(),
              style: const TextStyle(
                fontSize: 18,
                color: FinanceColors.textStrong,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: const Icon(
              Icons.calendar_today_outlined,
              color: FinanceColors.textStrong,
            ),
          ),
          const SizedBox(height: 12),
          _FieldLabel(label: 'Tần suất lặp lại'),
          FinanceSelectRow(
            onTap: _openRecurrenceSheet,
            leading: const SizedBox.shrink(),
            title: Text(
              _recurrenceLabel,
              style: const TextStyle(
                fontSize: 18,
                color: FinanceColors.textStrong,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: const Icon(
              Icons.expand_more,
              color: FinanceColors.textStrong,
            ),
          ),
          const SizedBox(height: 12),
          _FieldLabel(label: 'Nguồn tiền', requiredMark: true),
          FinanceSelectRow(
            onTap: _openFundingSourcePicker,
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selectedSource.iconBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(selectedSource.icon, color: selectedSource.iconColor),
            ),
            title: Text(
              selectedSource.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                color: FinanceColors.textStrong,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: const Icon(
              Icons.expand_more,
              color: FinanceColors.textStrong,
            ),
          ),
          const SizedBox(height: 12),
          _FieldLabel(label: 'Ghi chú'),
          FinanceInputContainer(
            child: TextField(
              controller: _noteController,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: FinanceColors.textStrong,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: 'Nhập mô tả giao dịch',
                hintStyle: TextStyle(
                  color: Color(0xFFB2B2BA),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageEntry() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderColor),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thêm giao dịch hàng loạt từ ảnh',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: FinanceColors.textStrong,
                ),
              ),
              const SizedBox(height: 6),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6F6F78),
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(text: 'Chọn tối đa 3 ảnh chụp màn hình '),
                    TextSpan(
                      text: 'Lịch sử',
                      style: TextStyle(
                        color: Color(0xFF2F7DFF),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(text: ' hoặc '),
                    TextSpan(
                      text: 'Kết quả',
                      style: TextStyle(
                        color: Color(0xFF2F7DFF),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(text: ' giao dịch ngân hàng, Grab, Shopee...'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.9,
          children: const [
            _ImageGuideCard(
              title: 'Lịch sử giao dịch',
              status: _GuideStatus.ok,
            ),
            _ImageGuideCard(
              title: 'Kết quả giao dịch',
              status: _GuideStatus.ok,
            ),
            _ImageGuideCard(title: 'Ảnh QR', status: _GuideStatus.bad),
            _ImageGuideCard(title: 'Ảnh mờ', status: _GuideStatus.bad),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeToggle() {
    return FinanceCurvedDualTabBar(
      leftIcon: Icons.trending_down_rounded,
      leftLabel: 'Chi tiêu',
      rightIcon: Icons.trending_up_rounded,
      rightLabel: 'Thu nhập',
      selectedIndex: _type == TransactionType.expense ? 0 : 1,
      onChanged: (index) => _switchType(
        index == 0 ? TransactionType.expense : TransactionType.income,
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final displayQuick = List<String>.from(_quickCategories);

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
          final selected =
              category.toLowerCase() == (_selectedCategory ?? '').toLowerCase();
          final iconColor = _iconColorForCategory(category);
          return FinanceCategoryChoiceTile(
            label: category,
            icon: _iconForCategory(category),
            selected: selected,
            unselectedIconColor: iconColor,
            selectedIconColor: iconColor,
            showSelectedIconBadge: false,
            onTap: selected
                ? null
                : () => setState(() {
                    _selectedCategory = category;
                  }),
          );
        }

        return FinanceCategoryChoiceTile(
          label: otherActionLabel,
          icon: otherActionIcon,
          selected: false,
          onTap: _openCategoryPicker,
          iconSize: 22,
          backgroundColor: Colors.transparent,
          selectedBackgroundColor: Colors.transparent,
          unselectedBorderColor: Colors.transparent,
          selectedBorderColor: Colors.transparent,
          borderWidth: 0,
          selectedBorderWidth: 0,
          showSelectedIconBadge: false,
          unselectedIconColor: _accentPink,
          unselectedLabelColor: FinanceColors.textStrong,
          unselectedLabelWeight: FontWeight.w800,
        );
      },
    );
  }
}

class _EntryTopTab extends StatelessWidget {
  const _EntryTopTab({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 26,
                color: active
                    ? FinanceColors.accentPrimary
                    : FinanceColors.textStrong,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: active
                      ? FinanceColors.accentPrimary
                      : FinanceColors.textStrong,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 2.5,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: active
                      ? FinanceColors.accentPrimary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.requiredMark = false});

  final String label;
  final bool requiredMark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF9A9AA2),
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
    );
  }
}

class FinanceInputContainer extends StatelessWidget {
  const FinanceInputContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E2EC)),
      ),
      child: child,
    );
  }
}

class FinanceSelectRow extends StatelessWidget {
  const FinanceSelectRow({
    super.key,
    required this.leading,
    required this.title,
    required this.trailing,
    this.onTap,
    this.enabled = true,
  });

  final Widget leading;
  final Widget title;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final borderColor = enabled
        ? const Color(0xFFE6E2EC)
        : const Color(0xFFE0DEE6);
    final bgColor = enabled ? Colors.white : const Color(0xFFF4F3F8);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: enabled ? 1 : 0.6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                leading,
                if (leading is! SizedBox) const SizedBox(width: 10),
                Expanded(child: title),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FinanceCreateCategoryScreen extends StatefulWidget {
  const FinanceCreateCategoryScreen({
    super.key,
    required this.initialType,
    required this.parentOptions,
    required this.expenseIcons,
    required this.incomeIcons,
    required this.usedExpenseIcons,
    required this.usedIncomeIcons,
    required this.iconPalette,
  });

  final TransactionType initialType;
  final List<FinanceParentCategoryOption> parentOptions;
  final List<IconData> expenseIcons;
  final List<IconData> incomeIcons;
  final List<IconData> usedExpenseIcons;
  final List<IconData> usedIncomeIcons;
  final List<Color> iconPalette;

  @override
  State<FinanceCreateCategoryScreen> createState() => _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends State<FinanceCreateCategoryScreen> {
  static const Color _accentPink = FinanceColors.accentPrimary;

  final TextEditingController _nameController = TextEditingController();

  late TransactionType _type;
  String? _selectedParent;
  late IconData _selectedIcon;
  late Color _selectedIconColor;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _selectedParent = null;
    _selectedIcon = _defaultIconForType(_type);
    _selectedIconColor = _colorForIcon(_selectedIcon, _type);
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    setState(() {});
  }

  List<IconData> _iconPoolFor(TransactionType type) {
    return type == TransactionType.expense
        ? widget.expenseIcons
        : widget.incomeIcons;
  }

  List<IconData> _usedIconPoolFor(TransactionType type) {
    return type == TransactionType.expense
        ? widget.usedExpenseIcons
        : widget.usedIncomeIcons;
  }

  IconData _defaultIconForType(TransactionType type) {
    final iconPool = _iconPoolFor(type);
    final usedIcons = _usedIconPoolFor(type);
    for (final icon in iconPool) {
      if (!usedIcons.contains(icon)) {
        return icon;
      }
    }
    return iconPool.first;
  }

  Color _colorForIcon(IconData icon, TransactionType type) {
    final icons = _iconPoolFor(type);
    final index = icons.indexOf(icon);
    final resolvedIndex = index < 0 ? 0 : index;
    return widget.iconPalette[resolvedIndex % widget.iconPalette.length];
  }

  bool get _canConfirm {
    final hasName = _nameController.text.trim().isNotEmpty;
    if (!hasName) {
      return false;
    }
    if (_type == TransactionType.expense) {
      return _selectedParent != null;
    }
    return true;
  }

  void _switchType(TransactionType nextType) {
    if (nextType == _type) {
      return;
    }
    setState(() {
      _type = nextType;
      final iconPool = _iconPoolFor(nextType);
      final usedIcons = _usedIconPoolFor(nextType);
      final selectedIconAvailable =
          iconPool.contains(_selectedIcon) &&
          !usedIcons.contains(_selectedIcon);
      if (!selectedIconAvailable) {
        _selectedIcon = _defaultIconForType(nextType);
        _selectedIconColor = _colorForIcon(_selectedIcon, nextType);
      }
    });
  }

  Future<void> _openParentPicker() async {
    if (_type != TransactionType.expense) {
      return;
    }

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FinanceSheetScaffold(
          heightFactor: 0.5,
          showHandle: false,
          child: Column(
            children: [
              FinanceModalSheetHeader(
                title: 'Chọn danh mục cha',
                onClose: () => Navigator.pop(ctx),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: widget.parentOptions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final option = widget.parentOptions[index];
                    return _ParentCategoryRadioTile(
                      option: option,
                      selected: _selectedParent == option.title,
                      onTap: () => Navigator.pop(ctx, option.title),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected == null) {
      return;
    }
    setState(() {
      _selectedParent = selected;
    });
  }

  Future<void> _openIconPicker() async {
    final selectedIcon = await showFinanceCategoryIconPicker(
      context: context,
      type: _type,
      iconPool: _iconPoolFor(_type),
      usedIcons: _usedIconPoolFor(_type),
      selectedIcon: _selectedIcon,
      colorForIcon: (icon) => _colorForIcon(icon, _type),
      emptyUsedLabel: 'Chưa có biểu tượng nào được dùng.',
    );

    if (selectedIcon == null) {
      return;
    }
    setState(() {
      _selectedIcon = selectedIcon;
      _selectedIconColor = _colorForIcon(selectedIcon, _type);
    });
  }

  void _confirm() {
    if (!_canConfirm) {
      return;
    }
    Navigator.of(context).pop(
      FinanceCreateCategoryResult(
        type: _type,
        name: _nameController.text.trim(),
        group: _type == TransactionType.expense
            ? (_selectedParent ?? widget.parentOptions.first.title)
            : 'Thu nhập',
        icon: _selectedIcon,
        color: _selectedIconColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = _nameController.text.trim().length;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F3F8),
      appBar: const FinanceGradientAppBar(title: 'Tạo danh mục'),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: FinanceColors.borderSoft),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: FinanceCurvedDualTabBar(
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
                ),
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 116,
                        height: 116,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF3F2F7),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: _selectedIconColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _selectedIcon,
                            color: _selectedIconColor,
                            size: 34,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _openIconPicker,
                        child: const Text(
                          'Đổi biểu tượng',
                          style: TextStyle(
                            color: _accentPink,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: FinanceLabeledFormField(
                    label: 'Tên danh mục ($count/30)',
                    requiredMark: true,
                    child: SizedBox(
                      height: 30,
                      child: TextField(
                        controller: _nameController,
                        maxLength: 30,
                        textAlignVertical: TextAlignVertical.center,
                        buildCounter:
                            (
                              context, {
                              required int currentLength,
                              required bool isFocused,
                              required int? maxLength,
                            }) => const SizedBox.shrink(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: FinanceColors.textStrong,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          hintText: 'Nhập tên',
                          hintStyle: TextStyle(
                            color: Color(0xFFB2B2BA),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_type == TransactionType.expense) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: FinanceLabeledFormField(
                      label: 'Thuộc danh mục',
                      requiredMark: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _openParentPicker,
                        child: SizedBox(
                          height: 30,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedParent ?? 'Chọn',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _selectedParent == null
                                        ? const Color(0xFF888893)
                                        : FinanceColors.textStrong,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: FinanceColors.textStrong,
                                size: 28,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: FinanceBottomBarSurface(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: FinancePrimaryActionButton(
              label: 'Xác nhận',
              onPressed: _canConfirm ? _confirm : null,
            ),
          ),
        ),
      ),
    );
  }
}

class FinanceLabeledFormField extends StatelessWidget {
  const FinanceLabeledFormField({
    super.key,
    required this.label,
    this.requiredMark = false,
    required this.child,
  });

  final String label;
  final bool requiredMark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6E2EC)),
          ),
          child: child,
        ),
        Positioned(
          left: 12,
          top: 0,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 17 / 1.2,
                  color: Color(0xFF666670),
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
          ),
        ),
      ],
    );
  }
}

class _ParentCategoryRadioTile extends StatelessWidget {
  const _ParentCategoryRadioTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final FinanceParentCategoryOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? const Color(0xFFF3B9D7)
                  : const Color(0xFFE6E2EC),
            ),
          ),
          child: Row(
            children: [
              Icon(option.icon, color: option.color, size: 34),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  option.title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: FinanceColors.textStrong,
                  ),
                ),
              ),
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? FinanceColors.accentPrimary
                        : const Color(0xFF3D3D45),
                    width: selected ? 2.2 : 1.8,
                  ),
                ),
                child: selected
                    ? Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: FinanceColors.accentPrimary,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FinanceIconOptionTile extends StatelessWidget {
  const FinanceIconOptionTile({
    super.key,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFEFF8) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? const Color(0xFFF59ACE) : Colors.transparent,
              width: 1.6,
            ),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
      ),
    );
  }
}

class FinanceUsedIconTile extends StatelessWidget {
  const FinanceUsedIconTile({super.key, required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.34,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}

enum _GuideStatus { ok, bad }

class _ImageGuideCard extends StatelessWidget {
  const _ImageGuideCard({required this.title, required this.status});

  final String title;
  final _GuideStatus status;

  @override
  Widget build(BuildContext context) {
    final isOk = status == _GuideStatus.ok;
    final bgColor = isOk ? const Color(0xFFEAF8EF) : const Color(0xFFFFF1EA);
    final badgeColor = isOk ? const Color(0xFF2CBF67) : const Color(0xFFFF5B27);
    final badgeIcon = isOk ? Icons.check : Icons.close;
    final isQr = title.toLowerCase().contains('qr');
    final previewAccent = isOk
        ? const Color(0xFF2CBF67)
        : const Color(0xFFFF5B27);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6E2EC)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Icon(badgeIcon, size: 16, color: Colors.white),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 86,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: previewAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          isOk
                              ? Icons.image_outlined
                              : (isQr
                                    ? Icons.qr_code_2_rounded
                                    : Icons.blur_on),
                          color: previewAccent,
                        ),
                      ),
                      if (isOk) ...[
                        const SizedBox(height: 8),
                        Container(
                          height: 6,
                          width: 84,
                          decoration: BoxDecoration(
                            color: FinanceColors.borderSoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: FinanceColors.textStrong,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FinanceCategoryGroupSection extends StatelessWidget {
  const FinanceCategoryGroupSection({
    super.key,
    required this.group,
    required this.selectedCategory,
    required this.iconForCategory,
    required this.onSelect,
    this.iconColorForCategory,
    this.enabled = true,
  });

  final FinanceCategoryGroup group;
  final String? selectedCategory;
  final IconData Function(String) iconForCategory;
  final Color Function(String category)? iconColorForCategory;
  final ValueChanged<String> onSelect;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FinanceCategoryGroupCard(
      title: group.title,
      icon: group.icon,
      color: group.color,
      categories: group.categories,
      selectedCategory: selectedCategory,
      iconForCategory: iconForCategory,
      iconColorForCategory: iconColorForCategory,
      onSelect: onSelect,
      enabled: enabled,
    );
  }
}

class FinanceRecurrenceOptionTile extends StatelessWidget {
  const FinanceRecurrenceOptionTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(16) : Radius.zero,
      bottom: isLast ? const Radius.circular(16) : Radius.zero,
    );
    return FinanceOptionTile(
      onTap: onTap,
      selected: selected,
      borderRadius: radius,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      backgroundColor: Colors.transparent,
      selectedBackgroundColor: const Color(0xFFFFF1F8),
      borderColor: Colors.transparent,
      selectedBorderColor: const Color(0xFFF59ACE),
      selectedBorderWidth: 1.4,
      child: SizedBox(
        height: 54,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: FinanceColors.textStrong,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? FinanceColors.accentPrimary
                      : FinanceColors.textStrong,
                  width: 2,
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
            ),
          ],
        ),
      ),
    );
  }
}

class FinanceRecurrenceDivider extends StatelessWidget {
  const FinanceRecurrenceDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFEAE6EE));
  }
}

class FinanceWeekdayLabel extends StatelessWidget {
  const FinanceWeekdayLabel({
    super.key,
    required this.text,
    this.isWeekend = false,
  });

  final String text;
  final bool isWeekend;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isWeekend
                ? const Color(0xFFFF4D5A)
                : FinanceColors.textStrong,
          ),
        ),
      ),
    );
  }
}

class FinanceCategoryPeriodPoint {
  const FinanceCategoryPeriodPoint({
    required this.label,
    required this.amount,
    required this.start,
    required this.end,
  });

  final String label;
  final double amount;
  final DateTime start;
  final DateTime end;
}

class FinanceTopReceiverAggregate {
  const FinanceTopReceiverAggregate({
    required this.name,
    required this.total,
    required this.count,
    required this.icon,
    required this.iconColor,
  });

  final String name;
  final double total;
  final int count;
  final IconData icon;
  final Color iconColor;
}

class FinanceCategoryHistoryChart extends StatelessWidget {
  const FinanceCategoryHistoryChart({
    super.key,
    required this.points,
    required this.average,
    required this.hideAmounts,
    required this.highlightColor,
    required this.caption,
    this.referenceLineValue,
    this.referenceLineColor,
    this.selectedIndex = -1,
    this.onSelectIndex,
    this.captionFooter,
  });

  final List<FinanceCategoryPeriodPoint> points;
  final double average;
  final bool hideAmounts;
  final Color highlightColor;
  final String caption;
  final double? referenceLineValue;
  final Color? referenceLineColor;
  final int selectedIndex;
  final ValueChanged<int>? onSelectIndex;
  final Widget? captionFooter;

  @override
  Widget build(BuildContext context) {
    return FinanceStandardBarChart(
      points: points
          .map(
            (point) => FinanceStandardBarChartPoint(
              label: point.label,
              amount: point.amount,
            ),
          )
          .toList(),
      average: average,
      hideAmounts: hideAmounts,
      caption: caption,
      referenceLineValue: referenceLineValue,
      referenceLineColor: referenceLineColor,
      selectedIndex: selectedIndex,
      onSelectIndex: onSelectIndex,
      captionFooter: captionFooter,
    );
  }
}

class FinanceBudgetTxnFilterChip extends StatelessWidget {
  const FinanceBudgetTxnFilterChip({
    super.key,
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FinanceOptionTile(
      onTap: onTap,
      selected: active,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      borderRadius: BorderRadius.circular(14),
      borderColor: FinanceColors.border,
      selectedBorderColor: const Color(0xFFF05DB2),
      selectedBorderWidth: 1.4,
      selectedBackgroundColor: const Color(0xFFFFE1F2),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: active
                ? FinanceColors.accentPrimary
                : const Color(0xFF33333B),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: active
                  ? FinanceColors.accentPrimary
                  : const Color(0xFF33333B),
              fontSize: 19 / 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class FinanceCategoryLegend extends StatelessWidget {
  const FinanceCategoryLegend({
    super.key,
    required this.color,
    required this.percent,
    required this.label,
    required this.icon,
  });

  final Color color;
  final String percent;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              percent,
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6E6E77),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class FinanceTimeRangeChip extends StatelessWidget {
  const FinanceTimeRangeChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFEDF7) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? const Color(0xFFF59ACE) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 18,
                color: selected
                    ? FinanceColors.accentSecondary
                    : const Color(0xFF3A3A42),
                fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FinanceTimeMonthChip extends StatelessWidget {
  const FinanceTimeMonthChip({
    super.key,
    required this.label,
    required this.selected,
    required this.disabled,
    this.onTap,
  });

  final String label;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: selected ? FinanceColors.accentPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : disabled
                    ? const Color(0xFFC6C6CE)
                    : const Color(0xFF404048),
                fontSize: 18,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FinanceUtilitySheetEntry {
  const FinanceUtilitySheetEntry({
    required this.action,
    required this.icon,
    required this.label,
  });

  final FinanceUtilityAction action;
  final IconData icon;
  final String label;
}

class FinanceUtilitySheetItem extends StatelessWidget {
  const FinanceUtilitySheetItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.compact = false,
    this.badge,
    this.badgeWidth,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool compact;
  final String? badge;
  final double? badgeWidth;

  @override
  Widget build(BuildContext context) {
    final iconBoxSize = compact ? 52.0 : 58.0;
    final iconSize = compact ? 28.0 : 31.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: compact ? 2 : 4,
            horizontal: compact ? 1 : 2,
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: iconBoxSize,
                    height: iconBoxSize,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF8FA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      icon,
                      color: const Color(0xFF22C6C3),
                      size: iconSize,
                    ),
                  ),
                  if (badge != null)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        height: 26,
                        width: badgeWidth,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3C50),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: compact ? 6 : 8),
              SizedBox(
                height: compact ? 34 : 40,
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      height: 1.18,
                      color: const Color(0xFF55555E),
                      fontSize: compact ? 14 : 16,
                      fontWeight: FontWeight.w500,
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
}

class FinanceCategorySlice {
  const FinanceCategorySlice({
    required this.name,
    required this.amount,
    required this.color,
  });

  final String name;
  final double amount;
  final Color color;
}
