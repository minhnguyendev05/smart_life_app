part of 'finance_screen.dart';

enum _CategoryManagerTab { expense, income }

class _CategoryVisualItem {
  const _CategoryVisualItem({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

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
      color: Color(0xFFF48A1C),
      categories: ['Chợ, siêu thị', 'Ăn uống', 'Di chuyển'],
    ),
    _CategoryGroup(
      title: 'Chi phí phát sinh',
      icon: Icons.layers_outlined,
      color: Color(0xFFF3BF17),
      categories: ['Mua sắm', 'Giải trí', 'Làm đẹp', 'Sức khỏe', 'Từ thiện'],
    ),
    _CategoryGroup(
      title: 'Chi phí cố định',
      icon: Icons.home_work_outlined,
      color: Color(0xFF2C82E8),
      categories: ['Hóa đơn', 'Nhà cửa', 'Người thân'],
    ),
    _CategoryGroup(
      title: 'Đầu tư - tiết kiệm',
      icon: Icons.savings_outlined,
      color: Color(0xFF2EC7AF),
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

  static const List<Color> _fallbackTilePalette = [
    Color(0xFFF7B39D),
    Color(0xFFC6C1F4),
    Color(0xFF8ADBCB),
    Color(0xFFF3D47A),
    Color(0xFF9CCCF6),
    Color(0xFFF3ABD0),
    Color(0xFF9AD9D3),
    Color(0xFFBDB4F8),
  ];

  _CategoryManagerTab _tab = _CategoryManagerTab.expense;

  Future<void> _openCreateCategoryFlow({
    required TransactionType initialType,
  }) async {
    final provider = context.read<FinanceProvider>();
    final custom = provider.customCategories;

    final usedExpense = custom
        .where((item) => item.type == TransactionType.expense)
        .map((item) => item.icon)
        .toSet()
        .toList();
    final usedIncome = custom
        .where((item) => item.type == TransactionType.income)
        .map((item) => item.icon)
        .toSet()
        .toList();

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

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Đã tạo danh mục "${model.name}"')),
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

  List<_CategoryVisualItem> _resolvedIncomeItems(List<FinanceCategory> custom) {
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

    final lookup = _customLookup(custom, TransactionType.income);
    return names
        .map(
          (name) => _visualForCategory(
            name: name,
            customLookup: lookup,
            fallbackIconResolver: widget.iconForIncomeCategory,
          ),
        )
        .toList();
  }

  _CategoryVisualItem _visualForCategory({
    required String name,
    required Map<String, FinanceCategory> customLookup,
    required IconData Function(String category) fallbackIconResolver,
  }) {
    final custom = customLookup[name.trim().toLowerCase()];
    if (custom != null) {
      return _CategoryVisualItem(
        label: name,
        icon: custom.icon,
        color: custom.color,
      );
    }

    return _CategoryVisualItem(
      label: name,
      icon: fallbackIconResolver(name),
      color: _fallbackTileColor(name),
    );
  }

  Color _fallbackTileColor(String name) {
    final seed = name.toLowerCase().hashCode & 0x7fffffff;
    return _fallbackTilePalette[seed % _fallbackTilePalette.length];
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
                name: name,
                customLookup: expenseLookup,
                fallbackIconResolver: widget.iconForExpenseCategory,
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
        );
      }).toList(),
    );
  }

  Widget _buildIncomeBody(List<FinanceCategory> custom) {
    final items = _resolvedIncomeItems(custom);
    return _CategoryManagerSectionCard(margin: EdgeInsets.zero, items: items);
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
      appBar: AppBar(
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
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFBD8EA),
                FinanceColors.appBarTint,
                Color(0xFFF4F3F8),
              ],
            ),
          ),
        ),
        title: const Text(
          'Quản lý danh mục',
          style: TextStyle(
            color: FinanceColors.textStrong,
            fontWeight: FontWeight.w900,
            fontSize: 41 / 1.2,
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
                  child: VerticalDivider(
                    color: Color(0xFFD5D2DC),
                    thickness: 1,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.home_outlined, color: Color(0xFF4F4F58)),
              ],
            ),
          ),
        ],
      ),
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
  });

  final EdgeInsetsGeometry margin;
  final String? title;
  final Color titleColor;
  final IconData? icon;
  final Color headerColor;
  final Color headerBorderColor;
  final List<_CategoryVisualItem> items;

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
              return _CategoryManagerGridTile(item: item);
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryManagerGridTile extends StatelessWidget {
  const _CategoryManagerGridTile({required this.item});

  final _CategoryVisualItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(item.icon, size: 42, color: item.color),
        const SizedBox(height: 10),
        SizedBox(
          height: 42,
          child: Center(
            child: Text(
              item.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF8A8A92),
                fontSize: 20 / 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
