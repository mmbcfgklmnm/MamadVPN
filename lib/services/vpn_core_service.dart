import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_v2ray_client/flutter_v2ray.dart';
import '../models/server_node.dart';
import '../models/app_settings.dart';
import 'config_parser.dart';
import 'traffic_service.dart';

enum VpnState {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

class VpnCoreService {
  final TrafficService? _trafficService;

  VpnState _state = VpnState.disconnected;
  VpnState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Process? _coreProcess;
  String _activeEngine = 'unknown';
  String get activeEngine => _activeEngine;

  void Function(VpnState state)? onStateChanged;

  // Android native Xray-core client instance (lazily initialized on Android)
  V2ray? _v2rayInstance;
  bool _isV2rayInitialized = false;

  VpnCoreService({TrafficService? trafficService}) : _trafficService = trafficService;

  V2ray get _androidV2ray {
    return _v2rayInstance ??= V2ray(
      onStatusChanged: (status) {
        _handleAndroidV2RayStatus(status);
      },
    );
  }

  void _handleAndroidV2RayStatus(V2RayStatus status) {
    final s = status.state.toLowerCase();
    if (s.contains('connected')) {
      _state = VpnState.connected;
    } else if (s.contains('connecting')) {
      _state = VpnState.connecting;
    } else if (s.contains('disconnect')) {
      _state = VpnState.disconnected;
    }
    onStateChanged?.call(_state);

    final traffic = _trafficService;
    if (traffic != null) {
      Duration duration = Duration.zero;
      try {
        final parts = status.duration.split(':');
        if (parts.length == 3) {
          final h = int.tryParse(parts[0]) ?? 0;
          final m = int.tryParse(parts[1]) ?? 0;
          final sec = int.tryParse(parts[2]) ?? 0;
          duration = Duration(hours: h, minutes: m, seconds: sec);
        }
      } catch (_) {}

      traffic.updateAndroidMetrics(
        downloadSpeed: status.downloadSpeed.toDouble(),
        uploadSpeed: status.uploadSpeed.toDouble(),
        sessionDownloaded: status.download,
        sessionUploaded: status.upload,
        connectedDuration: duration,
      );
    }
  }

  /// Start VPN connection with the given node and app settings
  Future<bool> connect(ServerNode node, AppSettings settings) async {
    _state = VpnState.connecting;
    _errorMessage = null;

    try {
      if (Platform.isAndroid) {
        return await _connectAndroid(node, settings);
      } else if (Platform.isWindows) {
        return await _connectWindows(node, settings);
      } else {
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

  /// Real Android VPN Execution using official Xray-core (libv2ray) with native TUN
  Future<bool> _connectAndroid(ServerNode node, AppSettings settings) async {
    try {
      if (!_isV2rayInitialized) {
        await _androidV2ray.initialize(
          notificationIconResourceType: "mipmap",
          notificationIconResourceName: "ic_launcher",
        );
        _isV2rayInitialized = true;
      }

      final bool hasPermission = await _androidV2ray.requestPermission();
      if (!hasPermission) {
        _state = VpnState.error;
        _errorMessage = 'VPN permission was rejected by user';
        return false;
      }

      String remark = node.name.isNotEmpty ? node.name : 'MamadVPN';
      Map<String, dynamic>? customOutbound;

      if (node.rawUri.isNotEmpty && (node.rawUri.startsWith('vless://') || node.rawUri.startsWith('vmess://') || node.rawUri.startsWith('trojan://') || node.rawUri.startsWith('ss://'))) {
        try {
          final parser = V2ray.parseFromURL(node.rawUri);
          if (parser.remark.isNotEmpty) {
            remark = parser.remark;
          }
          final rawOutbound = parser.removeNulls(parser.outbound1);
          if (rawOutbound is Map) {
            customOutbound = Map<String, dynamic>.from(rawOutbound);
          }
        } catch (_) {}
      }

      final configJson = ConfigParser.generateAndroidXrayConfig(
        node,
        settings,
        customOutbound: customOutbound,
      );

      _activeEngine = 'Xray-core (Android)';
      _state = VpnState.connecting;

      await _androidV2ray.startV2Ray(
        remark: remark,
        config: configJson,
        bypassSubnets: null, // Full default route (0.0.0.0/0) cleanly captured by TUN
        proxyOnly: false,
        notificationDisconnectButtonName: "DISCONNECT",
      );

      _state = VpnState.connected;
      return true;
    } catch (e) {
      _state = VpnState.error;
      _errorMessage = 'Android Connection Error: $e';
      return false;
    }
  }

  /// Real Windows VPN Core Execution (Xray-core / Sing-Box) & System Proxy Setup
  Future<bool> _connectWindows(ServerNode node, AppSettings settings) async {
    try {
      final appDir = await _getAppDirectory();

      // 1. Locate available proxy core engine
      final xrayExe = await _resolveExecutable('xray.exe', appDir);
      final singBoxExe = await _resolveExecutable('sing-box.exe', appDir);

      if (xrayExe == null && singBoxExe == null) {
        _state = VpnState.error;
        _errorMessage = 'VPN Core not found (neither xray.exe nor sing-box.exe located in application folder).';
        return false;
      }

      // 2. Determine preferred engine
      final isXhttp = node.network.toLowerCase() == 'xhttp' || node.network.toLowerCase() == 'splithttp';
      final useXray = (xrayExe != null) && (isXhttp || singBoxExe == null);

      final exeToRun = useXray ? xrayExe! : singBoxExe!;
      _activeEngine = useXray ? 'Xray-core' : 'Sing-Box';

      // 3. Generate engine-specific configuration
      final configJson = useXray
          ? ConfigParser.generateXrayConfig(node, settings)
          : ConfigParser.generateSingBoxConfig(node, settings);

      final configFile = File('${appDir.path}\\config.json');
      await configFile.writeAsString(configJson);

      // 4. Terminate any previous core instances
      await _killCoreProcesses();

      // 5. Launch proxy core process
      _coreProcess = await Process.start(
        exeToRun.path,
        ['run', '-c', configFile.path],
        workingDirectory: exeToRun.parent.path,
        mode: ProcessStartMode.normal,
      );

      String processError = '';
      _coreProcess!.stderr.transform(utf8.decoder).listen((data) {
        processError += data;
      });
      _coreProcess!.stdout.transform(utf8.decoder).listen((data) {
        if (data.contains('FATAL') || data.contains('Failed to start')) {
          processError += data;
        }
      });

      // Wait a moment to verify process does not exit immediately on startup
      await Future.delayed(const Duration(milliseconds: 1200));
      if (await _isProcessDead(_coreProcess)) {
        _state = VpnState.error;
        _errorMessage = '$_activeEngine exited unexpectedly: ${processError.isNotEmpty ? processError.trim() : "Invalid configuration or port occupied"}';
        await disconnect();
        return false;
      }

      // 6. Apply Windows System Proxy (SOCKS5/HTTP mixed on 127.0.0.1:port)
      if (settings.coreMode == CoreMode.systemProxy || useXray) {
        await _setWindowsSystemProxy(enabled: true, port: settings.mixedPort);
      }

      _state = VpnState.connected;
      return true;
    } catch (e) {
      _state = VpnState.error;
      _errorMessage = 'Windows Connection Error: $e';
      await disconnect();
      return false;
    }
  }

  /// Disconnect the active VPN session
  Future<bool> disconnect() async {
    _state = VpnState.disconnecting;

    try {
      if (Platform.isAndroid) {
        await _androidV2ray.stopV2Ray();
      } else if (Platform.isWindows) {
        // Kill core process
        if (_coreProcess != null) {
          _coreProcess!.kill();
          _coreProcess = null;
        }
        await _killCoreProcesses();

        // Reset Windows system proxy
        await _setWindowsSystemProxy(enabled: false);
      }

      _state = VpnState.disconnected;
      return true;
    } catch (e) {
      _state = VpnState.disconnected;
      return false;
    }
  }

  // -------------------------------------------------------------
  // Windows System Proxy & Process Helpers
  // -------------------------------------------------------------
  Future<void> _setWindowsSystemProxy({required bool enabled, int port = 20808}) async {
    try {
      if (enabled) {
        await Process.run('reg', [
          'add',
          r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
          '/v',
          'ProxyEnable',
          '/t',
          'REG_DWORD',
          '/d',
          '1',
          '/f',
        ]);
        await Process.run('reg', [
          'add',
          r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
          '/v',
          'ProxyServer',
          '/t',
          'REG_SZ',
          '/d',
          '127.0.0.1:$port',
          '/f',
        ]);
      } else {
        await Process.run('reg', [
          'add',
          r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
          '/v',
          'ProxyEnable',
          '/t',
          'REG_DWORD',
          '/d',
          '0',
          '/f',
        ]);
      }

      // Refresh system internet settings
      await Process.run('rundll32.exe', ['inetcpl.cpl,ClearMyTracksByProcess', '8']);
    } catch (_) {}
  }

  Future<void> _killCoreProcesses() async {
    try {
      await Process.run('taskkill', ['/F', '/IM', 'xray.exe', '/T']);
      await Process.run('taskkill', ['/F', '/IM', 'sing-box.exe', '/T']);
    } catch (_) {}
  }

  Future<bool> _isProcessDead(Process? process) async {
    if (process == null) return true;
    try {
      bool exited = false;
      process.exitCode.then((_) => exited = true);
      await Future.delayed(const Duration(milliseconds: 100));
      return exited;
    } catch (_) {
      return true;
    }
  }

  Future<Directory> _getAppDirectory() async {
    final appData = Platform.environment['APPDATA'] ?? Directory.current.path;
    final dir = Directory('$appData\\MamadVPN');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File?> _resolveExecutable(String exeName, Directory appDir) async {
    // 1. Check in same folder as MamadVPN executable
    final exeDir = File(Platform.resolvedExecutable).parent;
    final localExe = File('${exeDir.path}\\$exeName');
    if (await localExe.exists()) return localExe;

    // 2. Check in MamadVPN AppData folder
    final appDataExe = File('${appDir.path}\\$exeName');
    if (await appDataExe.exists()) return appDataExe;

    // 3. Check current working directory
    final currentDirExe = File('${Directory.current.path}\\$exeName');
    if (await currentDirExe.exists()) return currentDirExe;

    // 4. Check system PATH
    try {
      final res = await Process.run('where', [exeName]);
      if (res.exitCode == 0 && res.stdout.toString().trim().isNotEmpty) {
        final path = res.stdout.toString().split(RegExp(r'[\r\n]+')).first.trim();
        return File(path);
      }
    } catch (_) {}

    return null;
  }
}
