import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/app_bootstrap_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/finance_provider.dart';
import 'providers/marketplace_provider.dart';
import 'providers/notes_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/study_provider.dart';
import 'providers/sync_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_shell.dart';
import 'services/ai_assistant_service.dart';
import 'services/cloud_sync_service.dart';
import 'services/firestore_chat_service.dart';
import 'services/firestore_note_service.dart';
import 'services/llm_api_service.dart';
import 'services/local_reminder_service.dart';
import 'services/local_storage_service.dart';
import 'services/payment_gateway_service.dart';
import 'services/push_notification_service.dart';
import 'services/smart_suggestion_service.dart';
import 'services/study_sqlite_service.dart';

class SmartLifeApp extends StatelessWidget {
  const SmartLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider(create: (_) => LocalStorageService()),
        Provider(create: (_) => LlmApiService()),
        Provider(create: (_) => PushNotificationService()),
        Provider(create: (_) => LocalReminderService()),
        Provider(create: (_) => PaymentGatewayService()),
        Provider(create: (_) => CloudSyncService()),
        Provider(create: (_) => FirestoreChatService()),
        Provider(create: (_) => FirestoreNoteService()),
        Provider(create: (_) => StudySqliteService()),
        ChangeNotifierProxyProvider3<
          LocalStorageService,
          LocalReminderService,
          StudySqliteService,
          StudyProvider
        >(
          create: (_) => StudyProvider(),
          update: (_, storage, reminder, sqlite, provider) {
            return provider!
              ..attachSqlite(sqlite)
              ..attachStorage(storage)
              ..attachReminderService(reminder);
          },
        ),
        ChangeNotifierProxyProvider<LocalStorageService, FinanceProvider>(
          create: (_) => FinanceProvider(),
          update: (_, storage, provider) => provider!..attachStorage(storage),
        ),
        ChangeNotifierProxyProvider2<
          LocalStorageService,
          FirestoreNoteService,
          NotesProvider
        >(
          create: (_) => NotesProvider(),
          update: (_, storage, cloud, provider) {
            return provider!
              ..attachStorage(storage)
              ..attachCloud(cloud);
          },
        ),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider2<
          AuthProvider,
          PaymentGatewayService,
          MarketplaceProvider
        >(
          create: (_) => MarketplaceProvider(),
          update: (_, auth, paymentGateway, provider) {
            return provider!
              ..setPostingPermission(isAdmin: auth.isAdmin)
              ..attachPaymentGateway(paymentGateway);
          },
        ),
        ChangeNotifierProxyProvider2<
          FirestoreChatService,
          AuthProvider,
          ChatProvider
        >(
          create: (_) => ChatProvider(),
          update: (_, chatService, auth, provider) {
            return provider!
              ..setCurrentUser(
                userId: auth.userId,
                displayName: auth.currentUser.displayName.isEmpty
                    ? 'Bạn'
                    : auth.currentUser.displayName,
                isAdmin: auth.isAdmin,
              )
              ..attachCloud(chatService);
          },
        ),
        ChangeNotifierProxyProvider2<
          LocalStorageService,
          CloudSyncService,
          SyncProvider
        >(
          create: (_) => SyncProvider(),
          update: (_, storage, cloudSync, provider) {
            return provider!
              ..attachStorage(storage)
              ..attachCloud(cloudSync);
          },
        ),
        ProxyProvider3<
          StudyProvider,
          FinanceProvider,
          NotesProvider,
          SmartSuggestionService
        >(
          update: (_, study, finance, notes, previous) {
            return SmartSuggestionService(
              studyProvider: study,
              financeProvider: finance,
              notesProvider: notes,
            );
          },
        ),
        ProxyProvider3<
          StudyProvider,
          FinanceProvider,
          LlmApiService,
          AIAssistantService
        >(
          update: (_, study, finance, llmApi, previous) {
            return AIAssistantService(
              studyProvider: study,
              financeProvider: finance,
              llmApiService: llmApi,
            );
          },
        ),
        ChangeNotifierProxyProvider4<
          StudyProvider,
          FinanceProvider,
          LocalStorageService,
          LocalReminderService,
          NotificationProvider
        >(
          create: (_) => NotificationProvider(),
          update: (_, study, finance, storage, reminder, provider) {
            return provider!
              ..attachStorage(storage)
              ..attachReminderService(reminder)
              ..bind(study, finance);
          },
        ),
        ChangeNotifierProxyProvider3<
          StudyProvider,
          FinanceProvider,
          NotesProvider,
          AppBootstrapProvider
        >(
          create: (_) => AppBootstrapProvider(),
          update: (_, study, finance, notes, provider) {
            return provider!..bind(study, finance, notes);
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'SmartLife App',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const _AuthGate(),
          );
        },
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, AppBootstrapProvider>(
      builder: (context, auth, bootstrap, _) {
        if (!auth.isAuthenticated) {
          return const LoginScreen();
        }

        if (!bootstrap.initialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return const HomeShell();
      },
    );
  }
}
