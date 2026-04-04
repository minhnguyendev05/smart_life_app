part of 'finance_screen.dart';

class _TransactionEntryScreen extends StatefulWidget {
  const _TransactionEntryScreen({
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
  State<_TransactionEntryScreen> createState() =>
      _TransactionEntryScreenState();
}

enum _RecurrenceOption { none, daily, weekly, monthly, yearly }

class _RecurrenceResult {
  const _RecurrenceResult({required this.option, required this.endDate});

  final _RecurrenceOption option;
  final DateTime? endDate;
}

class _CategoryGroup {
  const _CategoryGroup({
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

class _CustomCategoryItem {
  const _CustomCategoryItem({
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

class _FundingSourceOption {
  const _FundingSourceOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
}

class _ParentCategoryOption {
  const _ParentCategoryOption({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final IconData icon;
  final Color color;
}

class _CreateCategoryResult {
  const _CreateCategoryResult({
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

class _TransactionEntryScreenState extends State<_TransactionEntryScreen> {
  static const Color _accentPink = Color(0xFFF12D9D);
  static const Color _borderColor = Color(0xFFE7E5EC);
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
  static const List<_CategoryGroup> _expenseCategoryGroups = [
    _CategoryGroup(
      title: 'Chi tiêu - sinh hoạt',
      icon: Icons.receipt_long_outlined,
      color: Color(0xFFFFB251),
      categories: ['Chợ, siêu thị', 'Ăn uống', 'Di chuyển'],
    ),
    _CategoryGroup(
      title: 'Chi phí phát sinh',
      icon: Icons.layers_outlined,
      color: Color(0xFFFFB251),
      categories: [
        'Mua sắm',
        'Giải trí',
        'Làm đẹp',
        'Sức khỏe',
        'Từ thiện',
      ],
    ),
    _CategoryGroup(
      title: 'Chi phí cố định',
      icon: Icons.home_work_outlined,
      color: Color(0xFF58A5FF),
      categories: ['Hóa đơn', 'Nhà cửa', 'Người thân'],
    ),
    _CategoryGroup(
      title: 'Đầu tư - tiết kiệm',
      icon: Icons.savings_outlined,
      color: Color(0xFF46C7B8),
      categories: ['Đầu tư', 'Học tập'],
    ),
    _CategoryGroup(
      title: 'Khác',
      icon: Icons.grid_view_rounded,
      color: Color(0xFF8E8EA0),
      categories: ['Khác'],
    ),
  ];
  static const List<_CategoryGroup> _incomeCategoryGroups = [
    _CategoryGroup(
      title: 'Thu nhập',
      icon: Icons.payments_outlined,
      color: Color(0xFFFF8A5B),
      categories: ['Kinh doanh', 'Lương', 'Thưởng', 'Khác'],
    ),
  ];

  static const List<_FundingSourceOption> _fundingSources = [
    _FundingSourceOption(
      id: 'momo',
      label: 'Ví MoMo',
      icon: Icons.account_balance_wallet_rounded,
      iconColor: Color(0xFFFFFFFF),
      iconBackground: Color(0xFFB00078),
    ),
    _FundingSourceOption(
      id: 'than_tai',
      label: 'Túi Thần Tài',
      icon: Icons.savings_rounded,
      iconColor: Color(0xFFFFA300),
      iconBackground: Color(0xFFFFF4D6),
    ),
    _FundingSourceOption(
      id: 'mbbank',
      label: 'MBBank',
      icon: Icons.account_balance_rounded,
      iconColor: Color(0xFF0057B8),
      iconBackground: Color(0xFFEAF2FF),
    ),
    _FundingSourceOption(
      id: 'group_ae',
      label: 'Quỹ Ae mình cũ thế thôi...',
      icon: Icons.groups_rounded,
      iconColor: Color(0xFFF12D9D),
      iconBackground: Color(0xFFFFEDF7),
    ),
    _FundingSourceOption(
      id: 'group_dau',
      label: 'Quỹ Đấu Trường Tri...',
      icon: Icons.groups_rounded,
      iconColor: Color(0xFFF12D9D),
      iconBackground: Color(0xFFFFEDF7),
    ),
    _FundingSourceOption(
      id: 'reward_fund',
      label: 'Quỹ Tiền thưởng',
      icon: Icons.groups_rounded,
      iconColor: Color(0xFFF12D9D),
      iconBackground: Color(0xFFFFEDF7),
    ),
    _FundingSourceOption(
      id: 'group_hi',
      label: 'Quỹ Hi',
      icon: Icons.groups_rounded,
      iconColor: Color(0xFFF12D9D),
      iconBackground: Color(0xFFFFEDF7),
    ),
    _FundingSourceOption(
      id: 'other_momo',
      label: 'Ngoài MoMo',
      icon: Icons.account_balance_wallet_outlined,
      iconColor: Color(0xFF2DC7C3),
      iconBackground: Color(0xFFEAF7F6),
    ),
    _FundingSourceOption(
      id: 'agribank',
      label: 'Agribank',
      icon: Icons.account_balance_outlined,
      iconColor: Color(0xFF08764C),
      iconBackground: Color(0xFFE7F8F0),
    ),
  ];

  static const List<_ParentCategoryOption> _expenseParentOptions = [
    _ParentCategoryOption(
      title: 'Chi tiêu - sinh hoạt',
      icon: Icons.receipt_long_outlined,
      color: Color(0xFFF6AB3D),
    ),
    _ParentCategoryOption(
      title: 'Chi phí phát sinh',
      icon: Icons.layers_outlined,
      color: Color(0xFFF2C252),
    ),
    _ParentCategoryOption(
      title: 'Chi phí cố định',
      icon: Icons.home_work_outlined,
      color: Color(0xFFF5B254),
    ),
    _ParentCategoryOption(
      title: 'Đầu tư - tiết kiệm',
      icon: Icons.savings_outlined,
      color: Color(0xFF70D7BD),
    ),
    _ParentCategoryOption(
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
    Icons.checkroom_rounded,
    Icons.bakery_dining_rounded,
    Icons.directions_car_filled_rounded,
    Icons.school_rounded,
    Icons.water_drop_rounded,
    Icons.shopping_basket_rounded,
    Icons.smoking_rooms_rounded,
    Icons.toys_rounded,
    Icons.bakery_dining_rounded,
    Icons.favorite_rounded,
    Icons.public_rounded,
    Icons.volunteer_activism_rounded,
    Icons.emoji_food_beverage_rounded,
    Icons.payments_rounded,
    Icons.school_rounded,
    Icons.theater_comedy_rounded,
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
    Icons.favorite_rounded,
    Icons.home_repair_service_rounded,
    Icons.tv_rounded,
    Icons.shopping_cart_rounded,
    Icons.volunteer_activism_rounded,
    Icons.savings_rounded,
    Icons.home_rounded,
    Icons.content_cut_rounded,
    Icons.restaurant_rounded,
    Icons.flight_rounded,
    Icons.two_wheeler_rounded,
    Icons.fitness_center_rounded,
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
    Icons.directions_car_rounded,
    Icons.favorite_rounded,
    Icons.description_rounded,
    Icons.toys_rounded,
    Icons.headphones_rounded,
    Icons.laptop_mac_rounded,
    Icons.weekend_rounded,
    Icons.health_and_safety_rounded,
    Icons.electric_bolt_rounded,
    Icons.health_and_safety_rounded,
    Icons.monitor_heart_rounded,
    Icons.card_giftcard_rounded,
    Icons.spa_rounded,
    Icons.menu_book_rounded,
    Icons.card_giftcard_rounded,
    Icons.flight_rounded,
    Icons.trending_up_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.water_drop_rounded,
    Icons.settings_rounded,
    Icons.sports_basketball_rounded,
    Icons.dry_cleaning_rounded,
    Icons.soup_kitchen_rounded,
    Icons.school_rounded,
    Icons.handshake_rounded,
    Icons.medical_services_rounded,
    Icons.groups_rounded,
    Icons.restaurant_rounded,
    Icons.pets_rounded,
    Icons.local_bar_rounded,
    Icons.local_hospital_rounded,
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
    Icons.credit_card_rounded,
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

  final TextEditingController _amountController = TextEditingController(
    text: '0đ',
  );
  final TextEditingController _noteController = TextEditingController();
  final ReceiptOcrService _ocrService = ReceiptOcrService();
  final List<_CustomCategoryItem> _customCategories = [];

  bool _imageMode = false;
  bool _isProcessingOcr = false;
  TransactionType _type = TransactionType.expense;
  String? _selectedCategory;
  String _selectedFundingSourceId = 'other_momo';
  String? _titleOverride;
  DateTime _selectedDate = DateTime.now();
  _RecurrenceOption _recurrence = _RecurrenceOption.none;
  DateTime? _recurrenceEndDate;

  @override
  void initState() {
    super.initState();
    _selectedCategory = _quickCategories.first;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<String> get _quickCategories => _type == TransactionType.expense
      ? _quickExpenseCategories
      : _quickIncomeCategories;

  _FundingSourceOption get _selectedFundingSource {
    for (final source in _fundingSources) {
      if (source.id == _selectedFundingSourceId) {
        return source;
      }
    }
    return _fundingSources.first;
  }

  List<_CategoryGroup> _groupsByType(TransactionType type) {
    final baseGroups = type == TransactionType.expense
        ? _expenseCategoryGroups
        : _incomeCategoryGroups;
    final groups = baseGroups
        .map(
          (group) => _CategoryGroup(
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

    if (type == TransactionType.expense) {
      if (category == 'Chợ, siêu thị') {
        return Icons.shopping_basket_outlined;
      }
      if (category == 'Ăn uống') {
        return Icons.restaurant_rounded;
      }
      if (category == 'Mua sắm') {
        return Icons.shopping_cart_outlined;
      }
      if (category == 'Người thân') {
        return Icons.child_care_outlined;
      }
      if (category == 'Khác') {
        return Icons.grid_view_rounded;
      }
    } else {
      if (category == 'Kinh doanh') {
        return Icons.trending_up_rounded;
      }
      if (category == 'Lương') {
        return Icons.work_outline_rounded;
      }
      if (category == 'Thưởng') {
        return Icons.emoji_events_outlined;
      }
      if (category == 'Khác') {
        return Icons.grid_view_rounded;
      }
    }
    return type == TransactionType.expense
        ? widget.iconForExpenseCategory(category)
        : widget.iconForIncomeCategory(category);
  }

  IconData _iconForCategory(String category) {
    return _iconForCategoryWithType(category, _type);
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

  String _recurrenceLabelFor(_RecurrenceOption option) {
    switch (option) {
      case _RecurrenceOption.none:
        return 'Không lặp lại';
      case _RecurrenceOption.daily:
        return 'Hàng ngày';
      case _RecurrenceOption.weekly:
        return 'Hàng tuần';
      case _RecurrenceOption.monthly:
        return 'Hàng tháng';
      case _RecurrenceOption.yearly:
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
                    const SizedBox(height: 8),
                    Container(
                      width: 52,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8D7DD),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
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
                                  color: Color(0xFF2F2F37),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close_rounded, size: 30),
                            color: const Color(0xFF3D3D45),
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
                              if (ctx.mounted) {
                                Navigator.pop(ctx, created.name);
                              }
                            },
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Tạo mới'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2F2F37),
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
                                return _CategoryGroupSection(
                                  group: group,
                                  selectedCategory: _selectedCategory,
                                  iconForCategory: _iconForCategory,
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
    final used = <IconData>[];
    final groups = _groupsByType(type);
    for (final group in groups) {
      for (final category in group.categories) {
        final icon = _iconForCategoryWithType(category, type);
        if (!used.contains(icon)) {
          used.add(icon);
        }
      }
    }
    final limit = type == TransactionType.expense ? 18 : 8;
    if (used.length <= limit) {
      return used;
    }
    return used.take(limit).toList();
  }

  Future<_CreateCategoryResult?> _openCreateCategoryScreen({
    required TransactionType initialType,
  }) async {
    return Navigator.of(context).push<_CreateCategoryResult>(
      MaterialPageRoute<_CreateCategoryResult>(
        builder: (_) => _CreateCategoryScreen(
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
                const SizedBox(height: 8),
                Container(
                  width: 52,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8D7DD),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 10, 12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Chọn nguồn tiền',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2F2F37),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, size: 36),
                        color: const Color(0xFF3D3D45),
                      ),
                    ],
                  ),
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
                      itemCount: _fundingSources.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.64,
                          ),
                      itemBuilder: (context, index) {
                        final source = _fundingSources[index];
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

  Future<void> _openRecurrenceSheet() async {
    final result = await showModalBottomSheet<_RecurrenceResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        var tempOption = _recurrence;
        var tempEndDate = _recurrenceEndDate;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final isRepeat = tempOption != _RecurrenceOption.none;
            final endLabel = tempEndDate == null
                ? 'Không bao giờ'
                : _formatShortDate(tempEndDate!);
            return SafeArea(
              top: false,
              child: Container(
                height: MediaQuery.of(ctx).size.height * 0.72,
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F3F8),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 52,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8D7DD),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
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
                                  color: Color(0xFF2F2F37),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close_rounded, size: 30),
                            color: const Color(0xFF3D3D45),
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
                                _RecurrenceOptionTile(
                                  label: 'Không lặp lại',
                                  selected:
                                      tempOption == _RecurrenceOption.none,
                                  onTap: () => setModalState(() {
                                    tempOption = _RecurrenceOption.none;
                                    tempEndDate = null;
                                  }),
                                  isFirst: true,
                                ),
                                _RecurrenceDivider(),
                                _RecurrenceOptionTile(
                                  label: 'Hàng ngày',
                                  selected:
                                      tempOption == _RecurrenceOption.daily,
                                  onTap: () => setModalState(() {
                                    tempOption = _RecurrenceOption.daily;
                                  }),
                                ),
                                _RecurrenceDivider(),
                                _RecurrenceOptionTile(
                                  label: 'Hàng tuần',
                                  selected:
                                      tempOption == _RecurrenceOption.weekly,
                                  onTap: () => setModalState(() {
                                    tempOption = _RecurrenceOption.weekly;
                                  }),
                                ),
                                _RecurrenceDivider(),
                                _RecurrenceOptionTile(
                                  label: 'Hàng tháng',
                                  selected:
                                      tempOption == _RecurrenceOption.monthly,
                                  onTap: () => setModalState(() {
                                    tempOption = _RecurrenceOption.monthly;
                                  }),
                                ),
                                _RecurrenceDivider(),
                                _RecurrenceOptionTile(
                                  label: 'Hàng năm',
                                  selected:
                                      tempOption == _RecurrenceOption.yearly,
                                  onTap: () => setModalState(() {
                                    tempOption = _RecurrenceOption.yearly;
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
                          _SelectRow(
                            enabled: isRepeat,
                            onTap: () async {
                              if (!isRepeat) {
                                return;
                              }
                              final picked = await _showDatePickerSheet(
                                title: 'Chọn ngày kết thúc',
                                initialDate: tempEndDate ?? DateTime.now(),
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
                                    ? const Color(0xFF2F2F37)
                                    : const Color(0xFFB2B2BA),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.expand_more,
                              color: Color(0xFF2F2F37),
                            ),
                          ),
                          if (isRepeat) ...[
                            const SizedBox(height: 18),
                            Text(
                              'Momo sẽ nhắc bạn ${_recurrenceLabelFor(tempOption).toLowerCase()}',
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
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: () => Navigator.pop(
                            ctx,
                            _RecurrenceResult(
                              option: tempOption,
                              endDate: tempOption == _RecurrenceOption.none
                                  ? null
                                  : tempEndDate,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: _accentPink,
                            disabledBackgroundColor: const Color(0xFFE2E0E8),
                            disabledForegroundColor: const Color(0xFFAFAFB7),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Lưu cài đặt'),
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

    if (result == null) {
      return;
    }

    setState(() {
      _recurrence = result.option;
      _recurrenceEndDate = result.option == _RecurrenceOption.none
          ? null
          : result.endDate;
    });
  }

  Future<DateTime?> _showDatePickerSheet({
    required String title,
    required DateTime initialDate,
  }) async {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        var tempDate = initialDate;
        var displayMonth = DateTime(initialDate.year, initialDate.month, 1);
        return StatefulBuilder(
          builder: (context, setModalState) {
            final monthLabel =
                'Tháng ${displayMonth.month}/${displayMonth.year}';
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
                    const SizedBox(height: 8),
                    Container(
                      width: 52,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8D7DD),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
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
                                  color: Color(0xFF2F2F37),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close_rounded, size: 30),
                            color: const Color(0xFF3D3D45),
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
                                            onPressed: () => setModalState(() {
                                              displayMonth = DateTime(
                                                displayMonth.year,
                                                displayMonth.month - 1,
                                                1,
                                              );
                                            }),
                                            icon: const Icon(
                                              Icons.chevron_left_rounded,
                                              color: Color(0xFF2F2F37),
                                            ),
                                          ),
                                          Expanded(
                                            child: Center(
                                              child: Text(
                                                monthLabel,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF2F2F37),
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
                                              color: Color(0xFF2F2F37),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      height: 1.6,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4D94FF),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
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
                                    final isWeekend =
                                        date.weekday == DateTime.saturday ||
                                        date.weekday == DateTime.sunday;
                                    final textColor = isSelected
                                        ? Colors.white
                                        : isWeekend
                                        ? const Color(0xFFFF4D5A)
                                        : const Color(0xFF2F2F37);
                                    return InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () {
                                        setModalState(() => tempDate = date);
                                        Navigator.pop(ctx, date);
                                      },
                                      child: Container(
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFFF12D9D)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
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
    final tx = FinanceTransaction(
      id: 'trx-${DateTime.now().microsecondsSinceEpoch}',
      title: title.isEmpty ? category : title,
      amount: amount,
      category: category,
      type: _type,
      createdAt: _selectedDate,
      note: note.isEmpty ? null : note,
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
    setState(() {
      _type = type;
      final quick = _quickCategories;
      if (_selectedCategory == null || !quick.contains(_selectedCategory)) {
        _selectedCategory = quick.first;
      }
    });
  }

  String _resolveCategory(String raw, TransactionType type) {
    final normalized = raw.trim().toLowerCase();
    final options = type == TransactionType.expense
        ? _flattenGroups(_groupsByType(TransactionType.expense))
        : _flattenGroups(_groupsByType(TransactionType.income));
    final quickFallback =
        type == TransactionType.expense
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFBD8EA), Color(0xFFFBE6F2), Color(0xFFF6F4F9)],
            ),
          ),
        ),
        title: const Text(
          'Ghi chép GD',
          style: TextStyle(
            color: Color(0xFF2F2F37),
            fontWeight: FontWeight.w900,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2F2F37)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _borderColor),
            ),
            child: Row(
              children: const [
                Icon(Icons.directions_bus_rounded, color: Color(0xFF4F4F58)),
                SizedBox(width: 8),
                Icon(Icons.home_outlined, color: Color(0xFF4F4F58)),
              ],
            ),
          ),
        ],
      ),
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: canSubmit
                  ? (_imageMode ? _pickReceiptImage : _submit)
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: _accentPink,
                disabledBackgroundColor: const Color(0xFFE2E0E8),
                foregroundColor: Colors.white,
                disabledForegroundColor: const Color(0xFFAFAFB7),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isProcessingOcr && _imageMode
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(actionLabel),
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
          _InputContainer(
            child: TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              onChanged: _handleAmountChanged,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2F2F37),
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
          _SelectRow(
            onTap: _selectDate,
            leading: const SizedBox.shrink(),
            title: Text(
              _dateLabel(),
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF2F2F37),
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: const Icon(
              Icons.calendar_today_outlined,
              color: Color(0xFF2F2F37),
            ),
          ),
          const SizedBox(height: 12),
          _FieldLabel(label: 'Tần suất lặp lại'),
          _SelectRow(
            onTap: _openRecurrenceSheet,
            leading: const SizedBox.shrink(),
            title: Text(
              _recurrenceLabel,
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF2F2F37),
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: const Icon(Icons.expand_more, color: Color(0xFF2F2F37)),
          ),
          const SizedBox(height: 12),
          _FieldLabel(label: 'Nguồn tiền', requiredMark: true),
          _SelectRow(
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
                color: Color(0xFF2F2F37),
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: const Icon(Icons.expand_more, color: Color(0xFF2F2F37)),
          ),
          const SizedBox(height: 12),
          _FieldLabel(label: 'Ghi chú'),
          _InputContainer(
            child: TextField(
              controller: _noteController,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2F2F37),
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
                  color: Color(0xFF2F2F37),
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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3F8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TypeTabButton(
              icon: Icons.trending_down_rounded,
              label: 'Chi tiêu',
              active: _type == TransactionType.expense,
              onTap: () => _switchType(TransactionType.expense),
            ),
          ),
          Expanded(
            child: _TypeTabButton(
              icon: Icons.trending_up_rounded,
              label: 'Thu nhập',
              active: _type == TransactionType.income,
              onTap: () => _switchType(TransactionType.income),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final categories = _quickCategories;
    final selectedOutsideQuick =
        _selectedCategory != null && !categories.contains(_selectedCategory);
    final displayQuick = List<String>.from(categories);
    if (selectedOutsideQuick && displayQuick.isNotEmpty) {
      displayQuick[0] = _selectedCategory!;
    }

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
          final color = selected ? _accentPink : const Color(0xFF2F2F37);
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _selectedCategory = category),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? _accentPink : const Color(0xFFE1DCEA),
                    width: selected ? 1.6 : 1.1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_iconForCategory(category), color: color, size: 20),
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
                  Icon(
                    otherActionIcon,
                    color: _accentPink,
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
                          color: Color(0xFF2F2F37),
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
                    ? const Color(0xFFF12D9D)
                    : const Color(0xFF2F2F37),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: active
                      ? const Color(0xFFF12D9D)
                      : const Color(0xFF2F2F37),
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 2.5,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFF12D9D) : Colors.transparent,
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

class _InputContainer extends StatelessWidget {
  const _InputContainer({required this.child});

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

class _SelectRow extends StatelessWidget {
  const _SelectRow({
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

class _TypeTabButton extends StatelessWidget {
  const _TypeTabButton({
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
    final activeColor = const Color(0xFFF12D9D);
    final inactiveColor = const Color(0xFF2F2F37);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: active
              ? const [
                  BoxShadow(
                    color: Color(0x18000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: active ? const Color(0xFFFFE6F4) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: active ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: active ? activeColor : inactiveColor,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FundingSourceTile extends StatelessWidget {
  const _FundingSourceTile({
    required this.source,
    required this.selected,
    required this.onTap,
  });

  final _FundingSourceOption source;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? const Color(0xFFF59ACE) : Colors.transparent,
              width: 1.8,
            ),
            color: selected ? const Color(0xFFFFF1F8) : Colors.transparent,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: source.iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(source.icon, color: source.iconColor, size: 27),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Text(
                    source.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF2F2F37),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.15,
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

class _CreateCategoryScreen extends StatefulWidget {
  const _CreateCategoryScreen({
    required this.initialType,
    required this.parentOptions,
    required this.expenseIcons,
    required this.incomeIcons,
    required this.usedExpenseIcons,
    required this.usedIncomeIcons,
    required this.iconPalette,
  });

  final TransactionType initialType;
  final List<_ParentCategoryOption> parentOptions;
  final List<IconData> expenseIcons;
  final List<IconData> incomeIcons;
  final List<IconData> usedExpenseIcons;
  final List<IconData> usedIncomeIcons;
  final List<Color> iconPalette;

  @override
  State<_CreateCategoryScreen> createState() => _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends State<_CreateCategoryScreen> {
  static const Color _accentPink = Color(0xFFF12D9D);

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
    _selectedIcon = _iconPoolFor(_type).first;
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
      if (!iconPool.contains(_selectedIcon)) {
        _selectedIcon = iconPool.first;
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
        var tempValue = _selectedParent;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: Container(
                height: MediaQuery.of(ctx).size.height * 0.48,
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F3F8),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 52,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8D7DD),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 10, 12),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Center(
                              child: Text(
                                'Chọn danh mục cha',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF2F2F37),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close_rounded, size: 36),
                            color: const Color(0xFF3D3D45),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: widget.parentOptions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final option = widget.parentOptions[index];
                          return _ParentCategoryRadioTile(
                            option: option,
                            selected: tempValue == option.title,
                            onTap: () => setModalState(() {
                              tempValue = option.title;
                            }),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: tempValue == null
                              ? null
                              : () => Navigator.pop(ctx, tempValue),
                          style: FilledButton.styleFrom(
                            backgroundColor: _accentPink,
                            disabledBackgroundColor: const Color(0xFFE2E0E8),
                            disabledForegroundColor: const Color(0xFFAFAFB7),
                            textStyle: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Xác nhận'),
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

    if (selected == null) {
      return;
    }
    setState(() {
      _selectedParent = selected;
    });
  }

  Future<void> _openIconPicker() async {
    final iconPool = _iconPoolFor(_type);
    final usedPool = _usedIconPoolFor(_type);

    final selectedIcon = await showModalBottomSheet<IconData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final sheetHeight = _type == TransactionType.expense ? 0.84 : 0.66;
        return SafeArea(
          top: false,
          child: Container(
            height: MediaQuery.of(ctx).size.height * sheetHeight,
            decoration: const BoxDecoration(
              color: Color(0xFFF4F3F8),
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 52,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8D7DD),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 10, 12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Chọn biểu tượng',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2F2F37),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, size: 36),
                        color: const Color(0xFF3D3D45),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE6E2EC)),
                          ),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: iconPool.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 6,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 1,
                                ),
                            itemBuilder: (context, index) {
                              final icon = iconPool[index];
                              return _IconOptionTile(
                                icon: icon,
                                color: _colorForIcon(icon, _type),
                                selected: icon == _selectedIcon,
                                onTap: () => Navigator.pop(ctx, icon),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Biểu tượng đang dùng',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2F2F37),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE6E2EC)),
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: usedPool
                                .map(
                                  (icon) => _UsedIconTile(
                                    icon: icon,
                                    color: _colorForIcon(icon, _type),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
      _CreateCategoryResult(
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFBD8EA), Color(0xFFFBE6F2), Color(0xFFF4F3F8)],
            ),
          ),
        ),
        title: const Text(
          'Tạo danh mục',
          style: TextStyle(
            color: Color(0xFF2F2F37),
            fontWeight: FontWeight.w900,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2F2F37)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFE7E5EC)),
            ),
            child: Row(
              children: const [
                Icon(Icons.directions_bus_rounded, color: Color(0xFF4F4F58)),
                SizedBox(width: 8),
                Icon(Icons.home_outlined, color: Color(0xFF4F4F58)),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE7E5EC)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F3F8),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _CreateCategoryTypeTab(
                          icon: Icons.trending_down_rounded,
                          label: 'Chi tiêu',
                          selected: _type == TransactionType.expense,
                          onTap: () => _switchType(TransactionType.expense),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _CreateCategoryTypeTab(
                          icon: Icons.trending_up_rounded,
                          label: 'Thu nhập',
                          selected: _type == TransactionType.income,
                          onTap: () => _switchType(TransactionType.income),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 138,
                        height: 138,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF3F2F7),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: _selectedIconColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _selectedIcon,
                            color: _selectedIconColor,
                            size: 42,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _openIconPicker,
                        child: const Text(
                          'Đổi biểu tượng',
                          style: TextStyle(
                            color: _accentPink,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: _LabeledFormField(
                    label: 'Tên danh mục ($count/30)',
                    requiredMark: true,
                    child: TextField(
                      controller: _nameController,
                      maxLength: 30,
                      buildCounter:
                          (
                            context, {
                            required int currentLength,
                            required bool isFocused,
                            required int? maxLength,
                          }) => const SizedBox.shrink(),
                      style: const TextStyle(
                        fontSize: 22 / 1.2,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2F2F37),
                      ),
                      decoration: const InputDecoration(
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
                if (_type == TransactionType.expense) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: _LabeledFormField(
                      label: 'Thuộc danh mục',
                      requiredMark: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _openParentPicker,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedParent ?? 'Chọn',
                                  style: TextStyle(
                                    fontSize: 22 / 1.2,
                                    color: _selectedParent == null
                                        ? const Color(0xFF888893)
                                        : const Color(0xFF2F2F37),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Color(0xFF2F2F37),
                                size: 32,
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: _canConfirm ? _confirm : null,
              style: FilledButton.styleFrom(
                backgroundColor: _accentPink,
                disabledBackgroundColor: const Color(0xFFE2E0E8),
                disabledForegroundColor: const Color(0xFFAFAFB7),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Xác nhận'),
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateCategoryTypeTab extends StatelessWidget {
  const _CreateCategoryTypeTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? Colors.white : const Color(0xFFF3F2F7),
            borderRadius: BorderRadius.circular(18),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 14,
                      offset: Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 28,
                color: selected
                    ? const Color(0xFFF12D9D)
                    : const Color(0xFF2F2F37),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 20 / 1.2,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected
                      ? const Color(0xFFF12D9D)
                      : const Color(0xFF2F2F37),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabeledFormField extends StatelessWidget {
  const _LabeledFormField({
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

  final _ParentCategoryOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE6E2EC)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: option.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(option.icon, color: option.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option.title,
                  style: const TextStyle(
                    fontSize: 18 / 1.2,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2F2F37),
                  ),
                ),
              ),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? const Color(0xFFF12D9D)
                        : const Color(0xFF2F2F37),
                    width: 2,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF12D9D),
                            shape: BoxShape.circle,
                          ),
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

class _IconOptionTile extends StatelessWidget {
  const _IconOptionTile({
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

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

class _UsedIconTile extends StatelessWidget {
  const _UsedIconTile({required this.icon, required this.color});

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
                            color: const Color(0xFFE7E5EC),
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
                  color: Color(0xFF2F2F37),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryGroupSection extends StatelessWidget {
  const _CategoryGroupSection({
    required this.group,
    required this.selectedCategory,
    required this.iconForCategory,
    required this.onSelect,
  });

  final _CategoryGroup group;
  final String? selectedCategory;
  final IconData Function(String) iconForCategory;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6E2EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: group.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(group.icon, color: group.color, size: 18),
                const SizedBox(width: 8),
                Text(
                  group.title,
                  style: TextStyle(
                    color: group.color,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: group.categories
                .map(
                  (category) => _CategoryOptionTile(
                    label: category,
                    icon: iconForCategory(category),
                    selected: category == selectedCategory,
                    onTap: () => onSelect(category),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _CategoryOptionTile extends StatelessWidget {
  const _CategoryOptionTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFFF12D9D) : const Color(0xFF2F2F37);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 92,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFFF1F8)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFFF12D9D)
                : const Color(0xFFE1DCEA),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 18,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    color: color,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecurrenceOptionTile extends StatelessWidget {
  const _RecurrenceOptionTile({
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
    final highlightRadius = BorderRadius.circular(16);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        overlayColor: MaterialStateProperty.all(Colors.transparent),
        child: Ink(
          child: Stack(
            children: [
              if (selected)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F8),
                        borderRadius: highlightRadius,
                        border: Border.all(
                          color: const Color(0xFFF59ACE),
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: SizedBox(
                  height: 54,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 16,
                            color: const Color(0xFF2F2F37),
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w600,
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
                                ? const Color(0xFFF12D9D)
                                : const Color(0xFF2F2F37),
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
                                    color: Color(0xFFF12D9D),
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ],
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

class _RecurrenceDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFEAE6EE));
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel({required this.text, this.isWeekend = false});

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
                : const Color(0xFF2F2F37),
          ),
        ),
      ),
    );
  }
}

class _CategoryPeriodPoint {
  const _CategoryPeriodPoint({required this.label, required this.amount});

  final String label;
  final double amount;
}

class _TopReceiverAggregate {
  const _TopReceiverAggregate({
    required this.name,
    required this.total,
    required this.count,
    required this.icon,
  });

  final String name;
  final double total;
  final int count;
  final IconData icon;
}

class _CategoryHistoryChart extends StatelessWidget {
  const _CategoryHistoryChart({
    required this.points,
    required this.average,
    required this.hideAmounts,
    required this.highlightColor,
    required this.caption,
    this.referenceLineValue,
    this.referenceLineColor,
  });

  final List<_CategoryPeriodPoint> points;
  final double average;
  final bool hideAmounts;
  final Color highlightColor;
  final String caption;
  final double? referenceLineValue;
  final Color? referenceLineColor;

  String _money(double value) {
    if (hideAmounts) {
      return '******';
    }
    final raw = Formatters.currency(
      value,
    ).replaceAll(RegExp(r'\s*VND\s*', caseSensitive: false), '').trim();
    return '$rawđ';
  }

  @override
  Widget build(BuildContext context) {
    final referenceValue = referenceLineValue ?? average;
    final lineColor = referenceLineColor ?? const Color(0xFFF12D9D);
    final maxValue = [
      referenceValue,
      ...points.map((item) => item.amount),
      1.0,
    ].reduce(math.max);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E3EE)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 210,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const chartHeight = 150.0;
                final avgTop =
                    chartHeight - (referenceValue / maxValue * chartHeight);
                final dashedTop = avgTop.clamp(0.0, chartHeight - 2);
                final labelTop = (avgTop - 18).clamp(0.0, chartHeight - 24);

                return Column(
                  children: [
                    SizedBox(
                      height: chartHeight,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 4,
                            right: 4,
                            top: dashedTop,
                            child: _DashedHorizontalLine(
                              color: lineColor,
                              dashWidth: 10,
                              gapWidth: 6,
                              height: 2,
                            ),
                          ),
                          Positioned(
                            left: 0,
                            top: labelTop,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: lineColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _money(referenceValue),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18 / 1.2,
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(points.length, (index) {
                                final point = points[index];
                                final hasSpending = point.amount > 0;
                                final barHeight = hasSpending
                                    ? (point.amount / maxValue * chartHeight)
                                          .clamp(12.0, chartHeight)
                                          .toDouble()
                                    : 0.0;
                                final selected = index == points.length - 1;

                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: hasSpending
                                          ? Container(
                                              height: barHeight,
                                              decoration: BoxDecoration(
                                                color: selected
                                                    ? highlightColor
                                                    : const Color(0xFFBCD1E6),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                            )
                                          : const SizedBox(height: 0),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(points.length, (index) {
                        final point = points[index];
                        final selected = index == points.length - 1;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              point.label,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: selected
                                    ? const Color(0xFF1A78EE)
                                    : const Color(0xFF4A4A52),
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                fontSize: 18 / 1.2,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _DashedHorizontalLine(
                color: lineColor,
                dashWidth: 7,
                gapWidth: 4,
                height: 2,
                width: 32,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  caption,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6D6D76),
                    fontSize: 18 / 1.2,
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

class _DashedHorizontalLine extends StatelessWidget {
  const _DashedHorizontalLine({
    required this.color,
    required this.dashWidth,
    required this.gapWidth,
    required this.height,
    this.width,
  });

  final Color color;
  final double dashWidth;
  final double gapWidth;
  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    Widget child = LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final dashCount = (totalWidth / (dashWidth + gapWidth)).floor().clamp(
          1,
          1000,
        );

        return Row(
          children: List.generate(dashCount, (index) {
            return Padding(
              padding: EdgeInsets.only(
                right: index == dashCount - 1 ? 0 : gapWidth,
              ),
              child: Container(width: dashWidth, height: height, color: color),
            );
          }),
        );
      },
    );

    if (width != null) {
      child = SizedBox(width: width, child: child);
    }

    return SizedBox(height: height, child: child);
  }
}

class _BudgetTxnFilterChip extends StatelessWidget {
  const _BudgetTxnFilterChip({
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFFFE1F2) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? const Color(0xFFF05DB2) : const Color(0xFFE8E3EE),
              width: active ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: active
                    ? const Color(0xFFF12D9D)
                    : const Color(0xFF33333B),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: active
                      ? const Color(0xFFF12D9D)
                      : const Color(0xFF33333B),
                  fontSize: 19 / 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryLegend extends StatelessWidget {
  const _CategoryLegend({
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

class _TimeRangeChip extends StatelessWidget {
  const _TimeRangeChip({
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
                    ? const Color(0xFFF63FA7)
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

class _TimeMonthChip extends StatelessWidget {
  const _TimeMonthChip({
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
            color: selected ? const Color(0xFFF12D9D) : Colors.transparent,
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

class _UtilitySheetEntry {
  const _UtilitySheetEntry({
    required this.action,
    required this.icon,
    required this.label,
    this.badge,
    this.badgeWidth,
  });

  final _FinanceUtilityAction action;
  final IconData icon;
  final String label;
  final String? badge;
  final double? badgeWidth;
}

class _UtilitySheetItem extends StatelessWidget {
  const _UtilitySheetItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.badgeWidth,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;
  final double? badgeWidth;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF8FA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: const Color(0xFF22C6C3), size: 31),
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
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  height: 1.28,
                  color: Color(0xFF55555E),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategorySlice {
  const _CategorySlice({
    required this.name,
    required this.amount,
    required this.color,
  });

  final String name;
  final double amount;
  final Color color;
}
