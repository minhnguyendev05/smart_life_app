import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/notification_provider.dart';
import '../providers/sync_provider.dart';
import '../providers/theme_provider.dart';
import '../services/push_notification_service.dart';
import 'assistant/assistant_screen.dart';
import 'chat/chat_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'finance/finance_module_screen.dart';
import 'map/map_screen.dart';
import 'notes/notes_screen.dart';
import 'notifications/notifications_screen.dart';
import 'profile/profile_screen.dart';
import 'study/study_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tabIndex = 0;
  StreamSubscription<String>? _pushSub;
  StreamSubscription<String>? _openedSub;

  final _tabs = const [DashboardScreen(), StudyScreen(), NotesScreen()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final push = context.read<PushNotificationService>();
      final notificationProvider = context.read<NotificationProvider>();
      await push.initialize();
      if (!mounted) return;
      _pushSub = push.events.listen((message) {
        notificationProvider.addSystemNotice('FCM foreground', message);
      });
      _openedSub = push.openedRoutes.listen(_openRoute);
    });
  }

  @override
  void dispose() {
    _pushSub?.cancel();
    _openedSub?.cancel();
    super.dispose();
  }

  void _openRoute(String route) {
    if (!mounted) return;
    Widget screen;
    switch (route) {
      case 'chat':
        screen = const ChatScreen();
        break;
      case 'study':
        screen = const StudyScreen();
        break;
      case 'finance':
        screen = const FinanceModuleScreen();
        break;
      case 'assistant':
        screen = const AssistantScreen();
        break;
      case 'map':
        screen = const MapScreen();
        break;
      default:
        screen = const NotificationsScreen();
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _openFinanceModule() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FinanceModuleScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncProvider>();
    final notifications = context.watch<NotificationProvider>();
    final effectiveIndex = _tabIndex < _tabs.length ? _tabIndex : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartLife App'),
        actions: [
          IconButton(
            onPressed: _openFinanceModule,
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'Quản lý chi tiêu',
          ),
          IconButton(
            onPressed: () => sync.setOnline(!sync.isOnline),
            icon: Icon(sync.isOnline ? Icons.cloud_done : Icons.cloud_off),
            tooltip: sync.isOnline ? 'Đang online' : 'Đang offline',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
            icon: Badge(
              isLabelVisible: notifications.unreadCount > 0,
              label: Text('${notifications.unreadCount}'),
              child: const Icon(Icons.notifications_none),
            ),
          ),
          IconButton(
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
            icon: const Icon(Icons.dark_mode_outlined),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              const ListTile(
                title: Text(
                  'Tiện ích nâng cao',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('Quản lý chi tiêu'),
                onTap: () {
                  Navigator.pop(context);
                  _openFinanceModule();
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: const Text('Chat & Cộng đồng'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.map_outlined),
                title: const Text('Bản đồ & Định vị'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MapScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.smart_toy_outlined),
                title: const Text('Trợ lý AI'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AssistantScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: const Text('Trung tâm thông báo'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Hồ sơ cá nhân'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _tabs[effectiveIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: effectiveIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Học tập',
          ),
          NavigationDestination(
            icon: Icon(Icons.note_alt_outlined),
            label: 'Ghi chú',
          ),
        ],
      ),
    );
  }
}
