import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';

class SettingsController extends ChangeNotifier {
  final StorageService _storageService;

  late AppSettings _settings;
  AppSettings get settings => _settings;

  SettingsController(this._storageService) {
    _settings = _storageService.loadSettings();
  }

  void updateSettings(AppSettings newSettings) {
    _settings = newSettings;
    _storageService.saveSettings(_settings);
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    updateSettings(_settings.copyWith(themeMode: mode));
  }

  void setAccentColor(String color) {
    updateSettings(_settings.copyWith(accentColor: color));
  }

  void setRoutingMode(RoutingMode mode) {
    updateSettings(_settings.copyWith(routingMode: mode));
  }

  void setCoreMode(CoreMode mode) {
    updateSettings(_settings.copyWith(coreMode: mode));
  }

  void setDnsServer(String dns) {
    updateSettings(_settings.copyWith(dnsServer: dns));
  }

  void toggleAutoConnect() {
    updateSettings(_settings.copyWith(autoConnect: !_settings.autoConnect));
  }

  void toggleKillSwitch() {
    updateSettings(_settings.copyWith(killSwitch: !_settings.killSwitch));
  }

  void toggleIpv6() {
    updateSettings(_settings.copyWith(enableIpv6: !_settings.enableIpv6));
  }

  void setMtu(int mtu) {
    updateSettings(_settings.copyWith(mtu: mtu));
  }
}
