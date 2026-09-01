import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config/app_settings.dart';
import '../core/network/api_client.dart';
import '../core/theme/app_theme.dart';
import '../features/ads/data/ad_repository.dart';
import '../features/ads/presentation/ad_state.dart';
import '../features/pools/data/pool_repository.dart';
import '../features/pools/presentation/pool_state.dart';
import '../features/messages/data/chat_repository.dart';
import '../features/messages/presentation/chat_state.dart';
import '../features/location/data/location_repository.dart';
import '../features/location/presentation/location_state.dart';
import '../features/shell/presentation/super_app_shell.dart';
import '../features/tasks/data/task_repository.dart';
import '../features/tasks/presentation/task_state.dart';
import '../features/user/data/user_repository.dart';
import '../features/user/presentation/auth_page.dart';
import '../features/user/presentation/user_state.dart';

class MicroLogisticsApp extends StatelessWidget {
  const MicroLogisticsApp({super.key, required this.appSettings});

  final AppSettings appSettings;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppSettings>.value(value: appSettings),
        Provider<ApiClient>(create: (_) => ApiClient(appSettings)),
        Provider<UserRepository>(
          create: (context) => UserRepository(context.read<ApiClient>()),
        ),
        Provider<TaskRepository>(
          create: (context) => TaskRepository(context.read<ApiClient>()),
        ),
        Provider<AdRepository>(
          create: (context) => AdRepository(context.read<ApiClient>()),
        ),
        Provider<PoolRepository>(
          create: (context) => PoolRepository(context.read<ApiClient>()),
        ),
        Provider<ChatRepository>(
          create: (context) => ChatRepository(context.read<ApiClient>()),
        ),
        Provider<LocationRepository>(
          create: (context) => LocationRepository(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider<UserState>(
          create: (context) => UserState(
            settings: appSettings,
            repository: context.read<UserRepository>(),
          )..initialize(),
        ),
        ChangeNotifierProvider<TaskState>(
          create: (context) =>
              TaskState(
                  settings: appSettings,
                  repository: context.read<TaskRepository>(),
                )
                ..refreshNearby()
                ..refreshMyTasks(),
        ),
        ChangeNotifierProvider<AdState>(
          create: (context) => AdState(repository: context.read<AdRepository>())
            ..load('HOME_TOP')
            ..load('MARKETPLACE_TOP'),
        ),
        ChangeNotifierProvider<PoolState>(
          create: (context) =>
              PoolState(repository: context.read<PoolRepository>())
                ..initialize(),
        ),
        ChangeNotifierProvider<ChatState>(
          create: (context) => ChatState(
            repository: context.read<ChatRepository>(),
            settings: appSettings,
          ),
        ),
        ChangeNotifierProvider<LocationState>(
          create: (context) => LocationState(
            settings: appSettings,
            repository: context.read<LocationRepository>(),
          ),
        ),
      ],
      child: Consumer<UserState>(
        builder: (context, userState, _) {
          final mode = userState.currentMode;
          final settings = context.watch<AppSettings>();
          return MaterialApp(
            title: '打个酱油',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(mode),
            darkTheme: AppTheme.dark(mode),
            themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: userState.isLoggedIn
                ? const SuperAppShell()
                : const AuthPage(),
          );
        },
      ),
    );
  }
}
