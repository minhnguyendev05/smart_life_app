import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/marketplace_provider.dart';
import '../chat/chat_screen.dart';
import 'marketplace_item_detail_screen.dart';
import '../../utils/formatters.dart';
import '../../widgets/ui_states.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final ScrollController _scrollController = ScrollController();
  int _visibleCount = 10;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 220) {
        setState(() {
          _visibleCount += 8;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MarketplaceProvider>();
    final items = provider.items.take(_visibleCount).toList();
    final hasMore = provider.items.length > items.length;

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Marketplace sinh viên',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.tonalIcon(
            onPressed: () => _showPostProduct(context),
            icon: const Icon(Icons.add_business_outlined),
            label: Text(
              provider.canPostListings
                  ? 'Đăng sản phẩm'
                  : 'Chỉ admin được đăng',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.shopping_cart_checkout_outlined),
            title: Text('Giỏ hàng: ${provider.cart.length} sản phẩm'),
            subtitle: Text('Tổng: ${Formatters.currency(provider.cartTotal)}'),
            trailing: FilledButton.tonal(
              onPressed: provider.cart.isEmpty
                  ? null
                  : () => _showCheckout(context),
              child: const Text('Đặt hàng'),
            ),
          ),
        ),
        if (provider.orders.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(top: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lịch sử đơn hàng',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ...provider.orders
                      .take(3)
                      .map(
                        (o) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Đơn ${o.id.substring(4)} • ${o.items.length} sản phẩm',
                                    ),
                                  ),
                                  Text(Formatters.currency(o.total)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: o.items.map((item) {
                                  final reviewed = o.reviews.containsKey(
                                    item.id,
                                  );
                                  return OutlinedButton(
                                    onPressed: reviewed
                                        ? null
                                        : () => _showReviewSheet(
                                            context,
                                            orderId: o.id,
                                            item: item,
                                          ),
                                    child: Text(
                                      reviewed
                                          ? 'Đã đánh giá ${item.title}'
                                          : 'Đánh giá ${item.title}',
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        if (provider.items.isEmpty)
          const EmptyStateCard(
            title: 'Chưa có sản phẩm',
            message: 'Hãy đăng sản phẩm đầu tiên cho cộng đồng sinh viên.',
            icon: Icons.store_mall_directory_outlined,
          ),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              tween: Tween(begin: 0.97, end: 1),
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Card(
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MarketplaceItemDetailScreen(
                          item: item,
                          rating: provider.itemRating(item.id, item.rating),
                        ),
                      ),
                    );
                  },
                  leading: Hero(
                    tag: 'market-item-${item.id}',
                    child: const CircleAvatar(
                      child: Icon(Icons.storefront_outlined),
                    ),
                  ),
                  title: Text(item.title),
                  subtitle: Text(
                    '${item.seller} • Đánh giá ${provider.itemRating(item.id, item.rating).toStringAsFixed(1)}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'cart') {
                        provider.addToCart(item);
                      }
                      if (value == 'chat') {
                        final roomId = provider.sellerRoomId(item);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              initialRoomId: roomId,
                              title: 'Chat ${item.seller}',
                              initialDraft: 'Hỏi về sản phẩm: ${item.title}',
                            ),
                          ),
                        );
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'cart',
                        child: Text(
                          'Thêm vào giỏ - ${Formatters.currency(item.price)}',
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'chat',
                        child: Text('Chat với người bán'),
                      ),
                    ],
                    child: const Icon(Icons.more_horiz),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 10),
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _visibleCount += 8;
                });
              },
              icon: const Icon(Icons.expand_more_outlined),
              label: const Text('Tải thêm sản phẩm'),
            ),
          ),
      ],
    );
  }

  Future<void> _showCheckout(BuildContext context) async {
    final provider = context.read<MarketplaceProvider>();
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Xác nhận đặt hàng',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              ...provider.cart.map(
                (e) => Text('• ${e.title} - ${Formatters.currency(e.price)}'),
              ),
              const SizedBox(height: 10),
              Text('Tổng cộng: ${Formatters.currency(provider.cartTotal)}'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: provider.processingPayment
                      ? null
                      : () async {
                          final order = await provider.placeOrder();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                order == null
                                    ? (provider.lastPaymentMessage ??
                                          'Đặt hàng thất bại.')
                                    : (provider.lastPaymentMessage ??
                                          'Đặt hàng thành công.'),
                              ),
                            ),
                          );
                          if (order == null) return;
                          Navigator.pop(ctx);
                        },
                  child: Text(
                    provider.processingPayment
                        ? 'Đang thanh toán...'
                        : 'Đặt hàng ngay',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showReviewSheet(
    BuildContext context, {
    required String orderId,
    required MarketplaceItem item,
  }) async {
    final provider = context.read<MarketplaceProvider>();
    final commentCtrl = TextEditingController();
    var rating = 5;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đánh giá ${item.title}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: rating,
                    decoration: const InputDecoration(labelText: 'Số sao'),
                    items: [1, 2, 3, 4, 5]
                        .map(
                          (e) =>
                              DropdownMenuItem(value: e, child: Text('$e sao')),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setModalState(() => rating = v);
                      }
                    },
                  ),
                  TextField(
                    controller: commentCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Nhận xét'),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        provider.addReview(
                          orderId: orderId,
                          itemId: item.id,
                          rating: rating,
                          comment: commentCtrl.text,
                        );
                        Navigator.pop(ctx);
                      },
                      child: const Text('Gửi đánh giá'),
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

  Future<void> _showPostProduct(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chỉ admin được đăng sản phẩm mới.')),
      );
      return;
    }

    final provider = context.read<MarketplaceProvider>();
    final titleCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final sellerCtrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Tên sản phẩm'),
              ),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Giá bán'),
              ),
              TextField(
                controller: sellerCtrl,
                decoration: const InputDecoration(labelText: 'Tên người bán'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final price = double.tryParse(priceCtrl.text.trim());
                    if (titleCtrl.text.trim().isEmpty || price == null) {
                      return;
                    }
                    final success = provider.addListing(
                      title: titleCtrl.text,
                      price: price,
                      seller: sellerCtrl.text,
                    );
                    if (!success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bạn không có quyền đăng sản phẩm.'),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text('Đăng sản phẩm'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
