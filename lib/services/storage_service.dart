import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/server_node.dart';
import '../models/subscription.dart';
import '../models/app_settings.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // Servers
  Future<void> saveServers(List<ServerNode> servers) async {
    final list = servers.map((s) => s.toJson()).toList();
    await _prefs.setString(AppConstants.keyServers, jsonEncode(list));
  }

  List<ServerNode> loadServers() {
    final raw = _prefs.getString(AppConstants.keyServers);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((item) => ServerNode.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  // Active Server ID
  Future<void> saveActiveServerId(String? id) async {
    if (id == null) {
      await _prefs.remove(AppConstants.keyActiveServerId);
    } else {
      await _prefs.setString(AppConstants.keyActiveServerId, id);
    }
  }

  String? loadActiveServerId() {
    return _prefs.getString(AppConstants.keyActiveServerId);
  }

  // Subscriptions
  Future<void> saveSubscriptions(List<Subscription> subscriptions) async {
    final list = subscriptions.map((s) => s.toJson()).toList();
    await _prefs.setString(AppConstants.keySubscriptions, jsonEncode(list));
  }

  List<Subscription> loadSubscriptions() {
    final raw = _prefs.getString(AppConstants.keySubscriptions);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((item) => Subscription.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  // Settings
  Future<void> saveSettings(AppSettings settings) async {
    await _prefs.setString(AppConstants.keySettings, jsonEncode(settings.toJson()));
  }

  AppSettings loadSettings() {
    final raw = _prefs.getString(AppConstants.keySettings);
    if (raw == null || raw.isEmpty) return const AppSettings();
    try {
      final decoded = jsonDecode(raw);
      return AppSettings.fromJson(decoded);
    } catch (e) {
      return const AppSettings();
    }
  }
}
