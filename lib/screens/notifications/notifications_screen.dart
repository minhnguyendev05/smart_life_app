import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_notification.dart';
import '../../providers/notification_provider.dart';
import '../../utils/formatters.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _icon(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.deadline:
        return Icons.event_busy_outlined;
      case NotificationCategory.study:
        return Icons.menu_book_outlined;
      case NotificationCategory.finance:
        return Icons.warning_amber_rounded;
      case NotificationCategory.weather:
        return Icons.cloud_outlined;
      case NotificationCategory.system:
        return Icons.notifications_active_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo thông minh'),
        actions: [
          TextButton(
            onPressed: provider.markAllRead,
            child: const Text('Đánh dấu đã đọc'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (provider.notifications.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Text('Không có thông báo nào.'),
              ),
            ),
          ...provider.notifications.map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Icon(_icon(item.category)),
                title: Text(item.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${item.body}\n${Formatters.dayTime(item.createdAt)}'),
                    const SizedBox(height: 6),
                    Text(
                      'Điểm ưu tiên: ${provider.relevanceScoreOf(item.id).toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Thông báo hữu ích',
                      icon: const Icon(Icons.thumb_up_alt_outlined, size: 20),
                      onPressed: () {
                        provider.rateNotification(id: item.id, useful: true);
                      },
                    ),
                    IconButton(
                      tooltip: 'Thông báo chưa hữu ích',
                      icon: const Icon(Icons.thumb_down_alt_outlined, size: 20),
                      onPressed: () {
                        provider.rateNotification(id: item.id, useful: false);
                      },
                    ),
                    if (!item.read)
                      const Icon(Icons.circle, size: 10, color: Colors.red),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
