part of 'finance_screen.dart';

enum _CategoryManagerTab { expense, income }

class _CategoryVisualItem {
  const _CategoryVisualItem({
    required this.label,
    required this.icon,
    required this.color,
    this.customCategory,
  });

  final String label;
  final IconData icon;
  final Color color;
  final FinanceCategory? customCategory;

  bool get isCustom => customCategory != null;
}

enum _CategoryEditOutcome { updated, deleted }

class _CategoryManagerScreen extends StatefulWidget {
  const _CategoryManagerScreen({
    required this.iconForIncomeCategory,
    required this.iconForExpenseCategory,
  });

  final IconData Function(String category) iconForIncomeCategory;
  final IconData Function(String category) iconForExpenseCategory;

  @override
  State<_CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends State<_CategoryManagerScreen> {
  static const int _maxCustomPerType = 20;

  static const List<_CategoryGroup> _expenseTemplateGroups = [
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
      categories: ['Mua sắm', 'Giải trí', 'Làm đẹp', 'Sức khỏe', 'Từ thiện'],
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
  ];

  static const List<String> _incomeTemplateCategories = [
    'Thu hồi nợ',
    'Kinh doanh',
    'Lợi nhuận',
    'Thưởng',
    'Trợ cấp',
    'Lương',
  ];

  static const Color _incomeTemplateColor = Color(0xFFFF8A5B);

  _CategoryManagerTab _tab = _CategoryManagerTab.expense;

  Future<void> _openCreateCategoryFlow({
    required TransactionType initialType,
  }) async {
    final provider = context.read<FinanceProvider>();
    final custom = provider.customCategories;

    final usedExpense = _usedIconsForType(custom, TransactionType.expense);
    final usedIncome = _usedIconsForType(custom, TransactionType.income);

    final result = await Navigator.of(context).push<_CreateCategoryResult>(
      MaterialPageRoute<_CreateCategoryResult>(
        builder: (_) => _CreateCategoryScreen(
          initialType: initialType,
          parentOptions: _TransactionEntryScreenState._expenseParentOptions,
          expenseIcons:
              _TransactionEntryScreenState._expenseCreateCategoryIcons,
          incomeIcons: _TransactionEntryScreenState._incomeCreateCategoryIcons,
          usedExpenseIcons: usedExpense,
          usedIncomeIcons: usedIncome,
          iconPalette: _TransactionEntryScreenState._createIconPalette,
        ),
      ),
    );

    if (result == null) {
      return;
    }

    final normalizedName = result.name.trim();
    final model = FinanceCategory(
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

    await provider.addOrUpdateCustomCategory(model);
    if (!mounted) {
      return;
    }

    context.read<SyncProvider>().queueAction(
      entity: 'finance_category',
      entityId: model.id,
      payload: {'operation': 'upsert', 'category': model.toMap()},
    );

    showAppToast(
      context,
      message: 'Đã tạo danh mục "${model.name}"',
      type: AppToastType.success,
    );
  }

  Future<void> _openEditCategoryFlow(FinanceCategory category) async {
    final provider = context.read<FinanceProvider>();
    final usedIcons = _usedIconsForType(
      provider.customCategories,
      category.type,
      excludingCustomCategoryId: category.id,
    );

    final result = await Navigator.of(context).push<_CategoryEditOutcome>(
      MaterialPageRoute<_CategoryEditOutcome>(
        builder: (_) => _EditCategoryScreen(
          category: category,
          blockedIcons: usedIcons,
          expenseIcons:
              _TransactionEntryScreenState._expenseCreateCategoryIcons,
          incomeIcons: _TransactionEntryScreenState._incomeCreateCategoryIcons,
          iconPalette: _TransactionEntryScreenState._createIconPalette,
        ),
      ),
    );

    if (!mounted || result != _CategoryEditOutcome.deleted) {
      return;
    }

    showAppToast(
      context,
      message: 'Xoá danh mục thành công',
      type: AppToastType.success,
    );
  }

  Map<String, FinanceCategory> _customLookup(
    List<FinanceCategory> custom,
    TransactionType type,
  ) {
    final map = <String, FinanceCategory>{};
    for (final item in custom.where((entry) => entry.type == type)) {
      map[item.name.trim().toLowerCase()] = item;
    }
    return map;
  }

  List<_CategoryGroup> _resolvedExpenseGroups(List<FinanceCategory> custom) {
    final merged = _expenseTemplateGroups
        .map(
          (group) => _CategoryGroup(
            title: group.title,
            icon: group.icon,
            color: group.color,
            categories: <String>[...group.categories],
          ),
        )
        .toList();

    for (final item in custom.where(
      (entry) => entry.type == TransactionType.expense,
    )) {
      final normalizedGroup = item.group.trim().toLowerCase();
      final index = merged.indexWhere(
        (group) => group.title.trim().toLowerCase() == normalizedGroup,
      );

      if (index < 0) {
        merged.add(
          _CategoryGroup(
            title: item.group.trim().isEmpty ? 'Khác' : item.group.trim(),
            icon: Icons.grid_view_rounded,
            color: const Color(0xFF8E8EA0),
            categories: [item.name],
          ),
        );
        continue;
      }

      final exists = merged[index].categories.any(
        (name) => name.trim().toLowerCase() == item.name.trim().toLowerCase(),
      );
      if (!exists) {
        merged[index].categories.add(item.name);
      }
    }

    return merged.where((group) => group.categories.isNotEmpty).toList();
  }

  List<String> _resolvedIncomeNames(List<FinanceCategory> custom) {
    final names = <String>[..._incomeTemplateCategories];

    for (final item in custom.where(
      (entry) => entry.type == TransactionType.income,
    )) {
      final exists = names.any(
        (name) => name.trim().toLowerCase() == item.name.trim().toLowerCase(),
      );
      if (!exists) {
        names.add(item.name);
      }
    }

    return names;
  }

  List<_CategoryVisualItem> _resolvedIncomeItems(List<FinanceCategory> custom) {
    final names = _resolvedIncomeNames(custom);

    final lookup = _customLookup(custom, TransactionType.income);
    return names
        .map(
          (name) => _visualForCategory(
            type: TransactionType.income,
            name: name,
            customLookup: lookup,
            fallbackColor: _incomeTemplateColor,
          ),
        )
        .toList();
  }

  _CategoryVisualItem _visualForCategory({
    required TransactionType type,
    required String name,
    required Map<String, FinanceCategory> customLookup,
    required Color fallbackColor,
  }) {
    final custom = customLookup[name.trim().toLowerCase()];
    if (custom != null) {
      return _CategoryVisualItem(
        label: name,
        icon: custom.icon,
        color: custom.color,
        customCategory: custom,
      );
    }

    return _CategoryVisualItem(
      label: name,
      icon: _defaultIconForCategory(type: type, name: name),
      color: FinanceCategoryVisualCatalog.colorFor(
        name,
        isExpense: type == TransactionType.expense,
        fallbackColor: fallbackColor,
      ),
    );
  }

  IconData _defaultIconForCategory({
    required TransactionType type,
    required String name,
  }) {
    final isExpense = type == TransactionType.expense;
    return FinanceCategoryVisualCatalog.iconFor(
      name,
      isExpense: isExpense,
      fallbackIcon: isExpense
          ? widget.iconForExpenseCategory(name)
          : widget.iconForIncomeCategory(name),
    );
  }

  List<IconData> _usedIconsForType(
    List<FinanceCategory> custom,
    TransactionType type, {
    String? excludingCustomCategoryId,
  }) {
    final used = <IconData>[];

    void addUsedIcon(IconData icon) {
      if (!used.contains(icon)) {
        used.add(icon);
      }
    }

    final lookup = _customLookup(custom, type);

    for (final item in custom.where(
      (entry) =>
          entry.type == type &&
          (excludingCustomCategoryId == null ||
              entry.id != excludingCustomCategoryId),
    )) {
      addUsedIcon(item.icon);
    }

    if (type == TransactionType.expense) {
      final groups = _resolvedExpenseGroups(custom);
      for (final group in groups) {
        for (final name in group.categories) {
          final customCategory = lookup[name.trim().toLowerCase()];
          if (customCategory != null &&
              customCategory.id == excludingCustomCategoryId) {
            continue;
          }
          addUsedIcon(
            customCategory?.icon ??
                _defaultIconForCategory(type: type, name: name),
          );
        }
      }
    } else {
      for (final name in _resolvedIncomeNames(custom)) {
        final customCategory = lookup[name.trim().toLowerCase()];
        if (customCategory != null &&
            customCategory.id == excludingCustomCategoryId) {
          continue;
        }
        addUsedIcon(
          customCategory?.icon ??
              _defaultIconForCategory(type: type, name: name),
        );
      }
    }

    final limit = type == TransactionType.expense ? 18 : 8;
    if (used.length <= limit) {
      return used;
    }
    return used.take(limit).toList();
  }

  Widget _buildTypeTabs() {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          _CategoryManagerTypeTab(
            label: 'Chi tiêu',
            icon: Icons.outbound_rounded,
            selected: _tab == _CategoryManagerTab.expense,
            onTap: () => setState(() => _tab = _CategoryManagerTab.expense),
          ),
          _CategoryManagerTypeTab(
            label: 'Thu nhập',
            icon: Icons.south_west_rounded,
            selected: _tab == _CategoryManagerTab.income,
            onTap: () => setState(() => _tab = _CategoryManagerTab.income),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateCategoryCard({
    required int customCount,
    required VoidCallback onTap,
  }) {
    final cappedCount = customCount > _maxCustomPerType
        ? _maxCustomPerType
        : customCount;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FinanceColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: FinanceColors.accentPrimary,
                    width: 2.2,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  color: FinanceColors.accentPrimary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'Danh mục mới',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: FinanceColors.accentPrimary,
                          fontSize: 24 / 1.1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '($cappedCount/$_maxCustomPerType)',
                      style: const TextStyle(
                        color: Color(0xFF34343C),
                        fontSize: 21 / 1.1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF515159),
                size: 36,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseBody(List<FinanceCategory> custom) {
    final expenseLookup = _customLookup(custom, TransactionType.expense);
    final groups = _resolvedExpenseGroups(custom);

    return Column(
      children: groups.map((group) {
        final visuals = group.categories
            .map(
              (name) => _visualForCategory(
                type: TransactionType.expense,
                name: name,
                customLookup: expenseLookup,
                fallbackColor: group.color,
              ),
            )
            .toList();

        return _CategoryManagerSectionCard(
          margin: const EdgeInsets.only(bottom: 12),
          title: group.title,
          titleColor: group.color,
          icon: group.icon,
          headerColor: group.color.withValues(alpha: 0.12),
          headerBorderColor: group.color.withValues(alpha: 0.18),
          items: visuals,
          onCustomItemTap: _openEditCategoryFlow,
        );
      }).toList(),
    );
  }

  Widget _buildIncomeBody(List<FinanceCategory> custom) {
    final items = _resolvedIncomeItems(custom);
    return _CategoryManagerSectionCard(
      margin: EdgeInsets.zero,
      items: items,
      onCustomItemTap: _openEditCategoryFlow,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final customCategories = provider.customCategories;
    final currentType = _tab == _CategoryManagerTab.expense
        ? TransactionType.expense
        : TransactionType.income;
    final customCount = customCategories
        .where((entry) => entry.type == currentType)
        .length;

    return Scaffold(
      backgroundColor: FinanceColors.background,
      appBar: const FinanceGradientAppBar(title: 'Quản lý danh mục'),
      body: Column(
        children: [
          _buildTypeTabs(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              children: [
                _buildCreateCategoryCard(
                  customCount: customCount,
                  onTap: () =>
                      _openCreateCategoryFlow(initialType: currentType),
                ),
                const SizedBox(height: 12),
                if (_tab == _CategoryManagerTab.expense)
                  _buildExpenseBody(customCategories)
                else
                  _buildIncomeBody(customCategories),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditCategoryScreen extends StatefulWidget {
  const _EditCategoryScreen({
    required this.category,
    required this.blockedIcons,
    required this.expenseIcons,
    required this.incomeIcons,
    required this.iconPalette,
  });

  final FinanceCategory category;
  final List<IconData> blockedIcons;
  final List<IconData> expenseIcons;
  final List<IconData> incomeIcons;
  final List<Color> iconPalette;

  @override
  State<_EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<_EditCategoryScreen> {
  static const Color _accentPink = FinanceColors.accentPrimary;

  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();

  late IconData _selectedIcon;
  late Color _selectedIconColor;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.category.name;
    _nameController.addListener(_onNameChanged);
    _selectedIcon = widget.category.icon;
    _selectedIconColor = widget.category.color;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _nameFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    setState(() {});
  }

  List<IconData> _iconPoolForType(TransactionType type) {
    return type == TransactionType.expense
        ? widget.expenseIcons
        : widget.incomeIcons;
  }

  Color _colorForIcon(IconData icon) {
    final icons = _iconPoolForType(widget.category.type);
    final index = icons.indexOf(icon);
    final resolvedIndex = index < 0 ? 0 : index;
    return widget.iconPalette[resolvedIndex % widget.iconPalette.length];
  }

  bool get _hasChanges {
    final originalName = widget.category.name.trim();
    final currentName = _nameController.text.trim();
    final iconChanged =
        _selectedIcon.codePoint != widget.category.iconCodePoint ||
        _selectedIcon.fontFamily != widget.category.iconFontFamily ||
        _selectedIcon.fontPackage != widget.category.iconFontPackage ||
        _selectedIcon.matchTextDirection !=
            widget.category.iconMatchTextDirection;
    return currentName != originalName || iconChanged;
  }

  bool get _canUpdate {
    final name = _nameController.text.trim();
    return name.isNotEmpty && name.length <= 30 && _hasChanges;
  }

  _ParentCategoryOption _resolvedParentOption() {
    if (widget.category.type == TransactionType.income) {
      return const _ParentCategoryOption(
        title: 'Thu nhập',
        icon: Icons.payments_outlined,
        color: Color(0xFFFF8A5B),
      );
    }

    for (final option in _TransactionEntryScreenState._expenseParentOptions) {
      if (option.title.trim().toLowerCase() ==
          widget.category.group.trim().toLowerCase()) {
        return option;
      }
    }

    return _ParentCategoryOption(
      title: widget.category.group,
      icon: Icons.grid_view_rounded,
      color: const Color(0xFF8E8EA0),
    );
  }

  Future<void> _openIconPicker() async {
    final iconPool = _iconPoolForType(widget.category.type);
    final usedPool = List<IconData>.from(widget.blockedIcons);
    final availablePool = iconPool
        .where((icon) => !usedPool.contains(icon) || icon == _selectedIcon)
        .toList();

    final selectedIcon = await showModalBottomSheet<IconData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final sheetHeight = widget.category.type == TransactionType.expense
            ? 0.84
            : 0.66;
        return FinanceSheetScaffold(
          heightFactor: sheetHeight,
          showHandle: false,
          child: Column(
            children: [
              FinanceModalSheetHeader(
                title: 'Chọn biểu tượng',
                onClose: () => Navigator.pop(ctx),
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
                          border: Border.all(color: FinanceColors.panelBorder),
                        ),
                        child: availablePool.isEmpty
                            ? const SizedBox(
                                height: 52,
                                child: Center(
                                  child: Text(
                                    'Không còn biểu tượng khả dụng',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: FinanceColors.textMuted,
                                    ),
                                  ),
                                ),
                              )
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: availablePool.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 6,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                      childAspectRatio: 1,
                                    ),
                                itemBuilder: (context, index) {
                                  final icon = availablePool[index];
                                  return _IconOptionTile(
                                    icon: icon,
                                    color: _colorForIcon(icon),
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
                          color: FinanceColors.textStrong,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: FinanceColors.panelBorder),
                        ),
                        child: usedPool.isEmpty
                            ? const SizedBox(
                                height: 52,
                                child: Center(
                                  child: Text(
                                    'Chưa có biểu tượng nào đang dùng',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: FinanceColors.textMuted,
                                    ),
                                  ),
                                ),
                              )
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: usedPool
                                    .map(
                                      (icon) => _UsedIconTile(
                                        icon: icon,
                                        color: _colorForIcon(icon),
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
        );
      },
    );

    if (selectedIcon == null) {
      return;
    }

    setState(() {
      _selectedIcon = selectedIcon;
      _selectedIconColor = _colorForIcon(selectedIcon);
    });
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Xóa danh mục',
                  style: TextStyle(
                    fontSize: 24 / 1.15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2F2F37),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Danh mục này sẽ vẫn hiển thị trên các thống kê và giao dịch đã phân loại.',
                  style: TextStyle(
                    fontSize: 19 / 1.2,
                    height: 1.35,
                    color: Color(0xFF3E3E47),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                          foregroundColor: _accentPink,
                          minimumSize: const Size.fromHeight(52),
                        ),
                        child: const Text(
                          'Xóa',
                          style: TextStyle(
                            fontSize: 20 / 1.1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: FilledButton.styleFrom(
                          backgroundColor: _accentPink,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Đóng',
                          style: TextStyle(
                            fontSize: 20 / 1.1,
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
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    final removed = await context
        .read<FinanceProvider>()
        .removeCustomCategoryById(widget.category.id);
    if (!mounted) {
      return;
    }

    if (!removed) {
      showAppToast(
        context,
        message: 'Không thể xóa danh mục lúc này.',
        type: AppToastType.error,
      );
      return;
    }

    context.read<SyncProvider>().queueAction(
      entity: 'finance_category',
      entityId: widget.category.id,
      payload: const <String, dynamic>{'operation': 'delete'},
    );

    Navigator.of(context).pop(_CategoryEditOutcome.deleted);
  }

  Future<void> _submitUpdate() async {
    if (!_canUpdate) {
      return;
    }

    final provider = context.read<FinanceProvider>();
    final nextName = _nameController.text.trim();
    final hasDuplicateName = provider.customCategories.any(
      (item) =>
          item.type == widget.category.type &&
          item.id != widget.category.id &&
          item.name.trim().toLowerCase() == nextName.toLowerCase(),
    );
    if (hasDuplicateName) {
      showAppToast(
        context,
        message: 'Tên danh mục đã tồn tại.',
        type: AppToastType.error,
      );
      return;
    }

    final updated = widget.category.copyWith(
      name: nextName,
      iconCodePoint: _selectedIcon.codePoint,
      iconFontFamily: _selectedIcon.fontFamily,
      iconFontPackage: _selectedIcon.fontPackage,
      iconMatchTextDirection: _selectedIcon.matchTextDirection,
      colorValue: _selectedIconColor.toARGB32(),
      updatedAt: DateTime.now(),
    );

    await provider.addOrUpdateCustomCategory(updated);
    if (!mounted) {
      return;
    }

    context.read<SyncProvider>().queueAction(
      entity: 'finance_category',
      entityId: updated.id,
      payload: {'operation': 'upsert', 'category': updated.toMap()},
    );

    Navigator.of(context).pop(_CategoryEditOutcome.updated);
  }

  @override
  Widget build(BuildContext context) {
    final count = _nameController.text.trim().length;
    final parentOption = _resolvedParentOption();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F3F8),
      appBar: const FinanceGradientAppBar(title: 'Chỉnh sửa danh mục'),
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
                  child: _LabeledFormField(
                    label: 'Tên danh mục ($count/30)',
                    requiredMark: true,
                    child: SizedBox(
                      height: 30,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              focusNode: _nameFocusNode,
                              autofocus: true,
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
                          if (_nameController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () => _nameController.clear(),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF8E8E95),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: _LabeledFormField(
                    label: 'Thuộc danh mục',
                    requiredMark: true,
                    child: SizedBox(
                      height: 30,
                      child: Opacity(
                        opacity: 0.65,
                        child: Row(
                          children: [
                            Icon(
                              parentOption.icon,
                              color: parentOption.color,
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                parentOption.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: FinanceColors.textStrong,
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
            ),
          ),
        ),
      ),
      bottomNavigationBar: FinanceBottomBarSurface(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _confirmDelete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2F2F37),
                      side: const BorderSide(color: FinanceColors.border),
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Xóa danh mục',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20 / 1.15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FinancePrimaryActionButton(
                    label: 'Cập nhật',
                    onPressed: _canUpdate ? _submitUpdate : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryManagerTypeTab extends StatelessWidget {
  const _CategoryManagerTypeTab({
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
    final color = selected
        ? FinanceColors.accentPrimary
        : const Color(0xFF33333B);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected
                    ? FinanceColors.accentPrimary
                    : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: color),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 22 / 1.1,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w500,
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

class _CategoryManagerSectionCard extends StatelessWidget {
  const _CategoryManagerSectionCard({
    required this.items,
    this.margin = EdgeInsets.zero,
    this.title,
    this.titleColor = const Color(0xFF4A4A53),
    this.icon,
    this.headerColor = const Color(0xFFF2F2F7),
    this.headerBorderColor = const Color(0xFFE8E5EE),
    this.onCustomItemTap,
  });

  final EdgeInsetsGeometry margin;
  final String? title;
  final Color titleColor;
  final IconData? icon;
  final Color headerColor;
  final Color headerBorderColor;
  final List<_CategoryVisualItem> items;
  final ValueChanged<FinanceCategory>? onCustomItemTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FinanceColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                border: Border(bottom: BorderSide(color: headerBorderColor)),
              ),
              child: Row(
                children: [
                  Icon(
                    icon ?? Icons.folder_outlined,
                    color: titleColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title!,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 21 / 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            itemCount: items.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.76,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return _CategoryManagerGridTile(
                item: item,
                onTap: item.customCategory == null || onCustomItemTap == null
                    ? null
                    : () => onCustomItemTap!(item.customCategory!),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryManagerGridTile extends StatelessWidget {
  const _CategoryManagerGridTile({required this.item, this.onTap});

  final _CategoryVisualItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = item.isCustom;
    final baseLabelColor = enabled
        ? const Color(0xFF2F2F37)
        : const Color(0xFF9A9AA3);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Opacity(
                    opacity: enabled ? 1 : 0.45,
                    child: Icon(item.icon, size: 42, color: item.color),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 42,
                    child: Center(
                      child: Text(
                        item.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: baseLabelColor,
                          fontSize: 20 / 1.2,
                          fontWeight: enabled
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (enabled)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F6FB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE4E2EA)),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: Color(0xFF44444D),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
