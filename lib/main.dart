import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/vpn_controller.dart';
import 'providers/server_controller.dart';
import 'providers/subscription_controller.dart';
import 'providers/settings_controller.dart';
import 'services/storage_service.dart';
import 'views/main_navigation_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge system overlays
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final storageService = await StorageService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsController(storageService)),
        ChangeNotifierProvider(create: (_) => ServerController(storageService)),
        ChangeNotifierProvider(create: (_) => SubscriptionController(storageService)),
        ChangeNotifierProvider(create: (_) => VpnController()),
      ],
      child: const MamadVpnApp(),
    ),
  );
}

class MamadVpnApp extends StatelessWidget {
  const MamadVpnApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = context.watch<SettingsController>();

    return MaterialApp(
      title: 'MamadVPN',
      debugShowCheckedModeBanner: false,
      themeMode: settingsController.settings.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const MainNavigationShell(),
    );
  }
}
