import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mamadvpn/main.dart';
import 'package:mamadvpn/services/storage_service.dart';
import 'package:mamadvpn/providers/settings_controller.dart';
import 'package:mamadvpn/providers/server_controller.dart';
import 'package:mamadvpn/providers/subscription_controller.dart';
import 'package:mamadvpn/providers/vpn_controller.dart';

void main() {
  testWidgets('MamadVPN app loads and renders dashboard', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs);

    await tester.pumpWidget(
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

    // Verify MamadVPN dashboard title renders
    expect(find.text('MamadVPN'), findsOneWidget);
  });
}
