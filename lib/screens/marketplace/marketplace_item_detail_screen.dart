import 'package:flutter/material.dart';

import '../../providers/marketplace_provider.dart';
import '../../utils/formatters.dart';

class MarketplaceItemDetailScreen extends StatelessWidget {
  const MarketplaceItemDetailScreen({
    super.key,
    required this.item,
    required this.rating,
  });

  final MarketplaceItem item;
  final double rating;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(item.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Hero(
                tag: 'market-item-${item.id}',
                child: CircleAvatar(
                  radius: 44,
                  child: const Icon(Icons.storefront_outlined, size: 36),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              item.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('Người bán: ${item.seller}'),
            const SizedBox(height: 6),
            Text('Đánh giá: ${rating.toStringAsFixed(1)} / 5'),
            const SizedBox(height: 6),
            Text(
              'Giá: ${Formatters.currency(item.price)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Mô tả nhanh',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Sản phẩm dành cho sinh viên, giao dịch linh hoạt trong nội bộ trường/lớp. '
              'Bạn có thể chat trực tiếp với seller để hỏi tình trạng và thương lượng giá.',
            ),
          ],
        ),
      ),
    );
  }
}
