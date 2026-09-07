import 'dart:async';
import 'package:flutter/material.dart';
import '../models/server_node.dart';
import '../models/traffic_stats.dart';
import '../models/app_settings.dart';
import '../services/vpn_core_service.dart';
import '../services/traffic_service.dart';

class VpnController extends ChangeNotifier {
  final VpnCoreService _vpnService;
  final TrafficService _trafficService;

  StreamSubscription<TrafficStats>? _trafficSub;
  TrafficStats _trafficStats = const TrafficStats();
  TrafficStats get trafficStats => _trafficStats;

  VpnState get state => _vpnService.state;
  bool get isConnected => _vpnService.state == VpnState.connected;
  bool get isConnecting => _vpnService.state == VpnState.connecting;
  bool get isDisconnected => _vpnService.state == VpnState.disconnected;
  String? get errorMessage => _vpnService.errorMessage;

  VpnController({
    VpnCoreService? vpnService,
    TrafficService? trafficService,
  })  : _vpnService = vpnService ?? VpnCoreService(),
        _trafficService = trafficService ?? TrafficService() {
    _trafficSub = _trafficService.statsStream.listen((stats) {
      _trafficStats = stats;
      notifyListeners();
    });
  }

  Future<void> toggleConnection({
    required ServerNode? selectedNode,
    required AppSettings settings,
  }) async {
    if (isConnected || isConnecting) {
      await disconnect();
    } else {
      if (selectedNode == null) {
        return;
      }
      await connect(selectedNode, settings);
    }
  }

  Future<bool> connect(ServerNode node, AppSettings settings) async {
    notifyListeners();
    final success = await _vpnService.connect(node, settings);
    if (success) {
      _trafficService.startMonitoring();
    } else {
      _trafficService.stopMonitoring();
    }
    notifyListeners();
    return success;
  }

  Future<void> disconnect() async {
    notifyListeners();
    await _vpnService.disconnect();
    _trafficService.stopMonitoring();
    _trafficStats = const TrafficStats();
    notifyListeners();
  }

  @override
  void dispose() {
    _trafficSub?.cancel();
    _trafficService.dispose();
    super.dispose();
  }
}
