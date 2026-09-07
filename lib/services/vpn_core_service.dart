import 'dart:io';
import 'package:flutter/services.dart';
import '../models/server_node.dart';
import '../models/app_settings.dart';
import 'config_parser.dart';

enum VpnState {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

class VpnCoreService {
  static const MethodChannel _androidChannel = MethodChannel('com.mamad.vpn/engine');

  VpnState _state = VpnState.disconnected;
  VpnState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Start VPN connection with the given node and app settings
  Future<bool> connect(ServerNode node, AppSettings settings) async {
    _state = VpnState.connecting;
    _errorMessage = null;

    try {
      final configJson = ConfigParser.generateSingBoxConfig(node, settings);

      if (Platform.isAndroid) {
        // Request VPN permission if required
        final bool prepared = await _androidChannel.invokeMethod('prepareVpn') ?? false;
        if (!prepared) {
          _state = VpnState.error;
          _errorMessage = 'VPN permission was rejected by user';
          return false;
        }

        final bool success = await _androidChannel.invokeMethod('startVpn', {
          'config': configJson,
        }) ?? false;

        if (success) {
          _state = VpnState.connected;
          return true;
        } else {
          _state = VpnState.error;
          _errorMessage = 'Failed to start Android VPN service';
          return false;
        }
      } else if (Platform.isWindows) {
        // Windows Desktop connection:
        // In full deployment, this launches the bundled sing-box/wintun executable
        // or configures the Windows internet system proxy settings.
        await Future.delayed(const Duration(milliseconds: 1200)); // Simulating core startup
        _state = VpnState.connected;
        return true;
      } else {
        // Fallback / Other platforms
        await Future.delayed(const Duration(milliseconds: 1000));
        _state = VpnState.connected;
        return true;
      }
    } catch (e) {
      _state = VpnState.error;
      _errorMessage = e.toString();
      return false;
    }
  }

  /// Disconnect the active VPN session
  Future<bool> disconnect() async {
    _state = VpnState.disconnecting;

    try {
      if (Platform.isAndroid) {
        await _androidChannel.invokeMethod('stopVpn');
      } else if (Platform.isWindows) {
        await Future.delayed(const Duration(milliseconds: 400));
      }

      _state = VpnState.disconnected;
      return true;
    } catch (e) {
      _state = VpnState.disconnected;
      return false;
    }
  }
}
