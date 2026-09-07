import 'dart:async';
import 'dart:convert';
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

  Process? _coreProcess;
  String _activeEngine = 'unknown';
  String get activeEngine => _activeEngine;

  /// Start VPN connection with the given node and app settings
  Future<bool> connect(ServerNode node, AppSettings settings) async {
    _state = VpnState.connecting;
    _errorMessage = null;

    try {
      if (Platform.isAndroid) {
        final configJson = ConfigParser.generateSingBoxConfig(node, settings);
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
        await _androidChannel.invokeMethod('stopVpn');
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
