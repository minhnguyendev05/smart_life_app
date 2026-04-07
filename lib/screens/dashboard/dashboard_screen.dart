import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/finance_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/study_provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/smart_suggestion_service.dart';
import '../../services/weather_service.dart';
import '../../services/local_storage_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/ui_states.dart';
import '../chat/chat_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final WeatherService _weatherService;
  late Future<WeatherForecast> _weatherFuture;

  @override
  void initState() {
    super.initState();
    final localStorage = Provider.of<LocalStorageService>(
      context,
      listen: false,
    );
    _weatherService = WeatherService(storage: localStorage);
    _weatherFuture = _weatherService.fetchTodayAndTomorrow();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SmartSuggestionService>().sendSmartAlerts();
    });
  }

  Future<void> _onRefresh() async {
    setState(() {
      _weatherFuture = _weatherService.fetchTodayAndTomorrow();
    });
  }

  @override
  Widget build(BuildContext context) {
    final study = context.watch<StudyProvider>();
    final finance = context.watch<FinanceProvider>();
    final sync = context.watch<SyncProvider>();
    final notice = context.watch<NotificationProvider>();
    final chat = context.watch<ChatProvider>();
    final suggestions = context
        .read<SmartSuggestionService>()
        .buildSuggestions();
    final recentDms = chat.directRooms.take(3).toList();

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Tổng quan hôm nay',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.45,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            children: [
              MetricCard(
                label: 'Điểm năng suất',
                value: '${study.productivityScore}/100',
                icon: Icons.auto_graph,
                color: Colors.teal,
              ),
              MetricCard(
                label: 'Số dư hiện tại',
                value: Formatters.currency(finance.balance),
                icon: Icons.savings_outlined,
                color: Colors.indigo,
              ),
              MetricCard(
                label: 'Thời gian học hôm nay',
                value: '${study.todayStudyMinutes} phút',
                icon: Icons.timer_outlined,
                color: Colors.orange,
              ),
              MetricCard(
                label: 'Deadline sắp tới',
                value:
                    '${study.tasks.where((e) => !e.isOverdue).take(3).length} mục',
                icon: Icons.event_available_outlined,
                color: Colors.redAccent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(
                sync.isOnline ? Icons.cloud_done_outlined : Icons.cloud_off,
              ),
              title: Text(
                sync.isOnline ? 'Chế độ trực tuyến' : 'Chế độ ngoại tuyến',
              ),
              subtitle: Text(
                sync.lastSyncAt == null
                    ? 'Đồng bộ tự động đang bật • Chờ: ${sync.pendingActions} • Xung đột: ${sync.conflictCount}'
                    : 'Đồng bộ gần nhất: ${Formatters.dayTime(sync.lastSyncAt!)} • Chờ: ${sync.pendingActions} • Xung đột: ${sync.conflictCount}',
              ),
              trailing: sync.syncing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      sync.isOnline
                          ? Icons.check_circle_outline
                          : Icons.cloud_off_outlined,
                      color: sync.isOnline ? Colors.green : Colors.grey,
                    ),
            ),
          ),
          const SizedBox(height: 8),
          if (notice.notifications.isNotEmpty)
            Card(
              child: ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: Text(notice.notifications.first.title),
                subtitle: Text(notice.notifications.first.body),
              ),
            ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: FutureBuilder<WeatherForecast>(
                future: _weatherFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingSkeletonCard(lines: 4);
                  }
                  if (snapshot.hasError) {
                    return ErrorStateCard(
                      title: 'Không tải được thời tiết',
                      message: 'Vui lòng thử lại để cập nhật dữ liệu.',
                      onRetry: _onRefresh,
                    );
                  }
                  if (!snapshot.hasData) {
                    return EmptyStateCard(
                      title: 'Chưa có dữ liệu môi trường',
                      message: 'Kéo xuống để tải lại dữ liệu thời tiết.',
                      icon: Icons.cloud_off_outlined,
                    );
                  }
                  final weather = snapshot.data!;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    _emitWeatherNoticeIfNeeded(
                      today: weather.today,
                      tomorrow: weather.tomorrow,
                    );
                    context.read<SmartSuggestionService>().sendSmartAlerts();
                  });
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Môi trường',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text('${weather.today.city} - ${weather.today.summary}'),
                      const SizedBox(height: 6),
                      Text(
                        'Hôm nay: ${weather.today.temperature}°C | AQI: ${weather.today.aqi}',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ngày mai: ${weather.tomorrow.temperature}°C | ${weather.tomorrow.summary}',
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tin nhắn 1-1 gần đây',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (recentDms.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                  'Chưa có DM gần đây. Vào Chat để tạo cuộc trò chuyện 1-1.',
                ),
              ),
            ),
          ...recentDms.map(
            (room) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.alternate_email_outlined),
                  ),
                  title: Text(room.name),
                  subtitle: Text(
                    room.lastMessage.isEmpty
                        ? 'Thành viên: ${room.memberCount}'
                        : '${room.lastMessage}\n${room.lastMessageAt == null ? '' : Formatters.dayTime(room.lastMessageAt!)}',
                  ),
                  isThreeLine: room.lastMessage.isNotEmpty,
                  trailing: room.unreadCount > 0
                      ? Badge(
                          label: Text('${room.unreadCount}'),
                          child: const Icon(Icons.chevron_right),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          initialRoomId: room.id,
                          title: room.name,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gợi ý thông minh',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (suggestions.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Text('Không có gợi ý nào. Bạn đang đi đúng lộ trình.'),
              ),
            ),
          ...suggestions
              .take(3)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.lightbulb_outline),
                      title: Text(item.title),
                      subtitle: Text(item.description),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  void _emitWeatherNoticeIfNeeded({
    required WeatherSnapshot today,
    required WeatherSnapshot tomorrow,
  }) {
    final notice = context.read<NotificationProvider>();
    if (today.aqi >= 4 || today.temperature >= 35) {
      notice.addWeatherNotice(
        title: 'Cảnh báo môi trường hôm nay',
        body: 'AQI/nhiệt độ cao, nên hạn chế ra ngoài giờ nóng.',
      );
    }
    if (tomorrow.summary.toLowerCase().contains('mưa')) {
      notice.addWeatherNotice(
        title: 'Dự báo ngày mai',
        body: 'Có khả năng mưa, nên mang áo mưa/ô.',
      );
    }
  }
}
