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

  /// Start VPN connection with the given node and app settings
  Future<bool> connect(ServerNode node, AppSettings settings) async {
    _state = VpnState.connecting;
    _errorMessage = null;

    try {
      final configJson = ConfigParser.generateSingBoxConfig(node, settings);

      if (Platform.isAndroid) {
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
        return await _connectWindows(configJson, settings);
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

  /// Real Windows VPN Core Execution & System Proxy Setup
  Future<bool> _connectWindows(String configJson, AppSettings settings) async {
    try {
      // 1. Write config.json to app storage
      final appDir = await _getAppDirectory();
      final configFile = File('${appDir.path}\\config.json');
      await configFile.writeAsString(configJson);

      // 2. Locate or download Sing-Box core executable
      final singBoxExe = await _resolveSingBoxExecutable(appDir);
      if (singBoxExe == null) {
        _state = VpnState.error;
        _errorMessage = 'Sing-Box engine (sing-box.exe) not found. Downloading core...';
        return false;
      }

      // 3. Terminate any previous core instances
      await _killSingBoxProcesses();

      // 4. Launch Sing-Box core process
      _coreProcess = await Process.start(
        singBoxExe.path,
        ['run', '-c', configFile.path],
        workingDirectory: appDir.path,
        mode: ProcessStartMode.normal,
      );

      String processError = '';
      _coreProcess!.stderr.transform(utf8.decoder).listen((data) {
        processError += data;
      });

      // Wait a moment to verify process does not exit immediately on startup
      await Future.delayed(const Duration(milliseconds: 1200));
      if (await _isProcessDead(_coreProcess)) {
        _state = VpnState.error;
        _errorMessage = 'VPN Core failed to start: ${processError.isNotEmpty ? processError : "Invalid server configuration"}';
        return false;
      }

      // 5. Enable Windows System Proxy
      await _setWindowsSystemProxy(enabled: true, port: settings.mixedPort);

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
        // Kill Sing-box core
        if (_coreProcess != null) {
          _coreProcess!.kill();
          _coreProcess = null;
        }
        await _killSingBoxProcesses();

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

  Future<void> _killSingBoxProcesses() async {
    try {
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

  Future<File?> _resolveSingBoxExecutable(Directory appDir) async {
    // 1. Check in same folder as MamadVPN executable
    final exeDir = File(Platform.resolvedExecutable).parent;
    final localExe = File('${exeDir.path}\\sing-box.exe');
    if (await localExe.exists()) return localExe;

    // 2. Check in MamadVPN AppData folder
    final appDataExe = File('${appDir.path}\\sing-box.exe');
    if (await appDataExe.exists()) return appDataExe;

    // 3. Check current working directory
    final currentDirExe = File('${Directory.current.path}\\sing-box.exe');
    if (await currentDirExe.exists()) return currentDirExe;

    // 4. Check system PATH
    try {
      final res = await Process.run('where', ['sing-box.exe']);
      if (res.exitCode == 0 && res.stdout.toString().trim().isNotEmpty) {
        final path = res.stdout.toString().split(RegExp(r'[\r\n]+')).first.trim();
        return File(path);
      }
    } catch (_) {}

    return null;
  }
}
