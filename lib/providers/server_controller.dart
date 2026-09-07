import 'package:flutter/material.dart';
import '../models/server_node.dart';
import '../services/storage_service.dart';
import '../services/ping_service.dart';

enum ServerSortBy { ping, name, protocol }

class ServerController extends ChangeNotifier {
  final StorageService _storageService;

  List<ServerNode> _servers = [];
  List<ServerNode> get servers => _servers;

  ServerNode? _activeServer;
  ServerNode? get activeServer => _activeServer;

  bool _isPinging = false;
  bool get isPinging => _isPinging;

  double _pingProgress = 0.0;
  double get pingProgress => _pingProgress;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _filterProtocol = 'all';
  String get filterProtocol => _filterProtocol;

  ServerSortBy _sortBy = ServerSortBy.ping;
  ServerSortBy get sortBy => _sortBy;

  ServerController(this._storageService) {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    _servers = _storageService.loadServers();
    final activeId = _storageService.loadActiveServerId();
    if (activeId != null && _servers.isNotEmpty) {
      _activeServer = _servers.firstWhere(
        (s) => s.id == activeId,
        orElse: () => _servers.first,
      );
    } else if (_servers.isNotEmpty) {
      _activeServer = _servers.first;
    }

    // If initial servers are empty, populate standard default demo servers so user has something out-of-the-box
    if (_servers.isEmpty) {
      _populateDefaultNodes();
    }
    notifyListeners();
  }

  void _populateDefaultNodes() {
    _servers = [
      ServerNode(
        id: 'mamad_fast_de',
        name: '🇩🇪 Germany - Frankfurt Superfast',
        protocol: 'vless',
        address: 'fra.mamadvpn.org',
        port: 443,
        uuid: 'd3b07384-d113-4a1a-a532-6a7e0e7a683a',
        network: 'tcp',
        security: 'reality',
        sni: 'speedtest.net',
        flow: 'xtls-rprx-vision',
        publicKey: '6S8m2z2-LqX7fUj_48b8g5V7k9l0m1n2o3p4q5r6s7t',
        shortId: '8a',
        fingerprint: 'chrome',
        ping: 42,
      ),
      ServerNode(
        id: 'mamad_speed_nl',
        name: '🇳🇱 Netherlands - Amsterdam Ultra',
        protocol: 'vmess',
        address: 'ams.mamadvpn.org',
        port: 443,
        uuid: 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d',
        network: 'ws',
        security: 'tls',
        sni: 'cloud.cloudflare.com',
        path: '/mamad-ws',
        ping: 58,
      ),
      ServerNode(
        id: 'mamad_us_east',
        name: '🇺🇸 US East - New York Fiber',
        protocol: 'hysteria2',
        address: 'nyc.mamadvpn.org',
        port: 8443,
        uuid: 'mamadSecretPass2026',
        security: 'tls',
        sni: 'apple.com',
        ping: 118,
      ),
      ServerNode(
        id: 'mamad_tr_turkey',
        name: '🇹🇷 Turkey - Istanbul Low Latency',
        protocol: 'trojan',
        address: 'ist.mamadvpn.org',
        port: 443,
        uuid: 'trPassMamadVPN',
        security: 'tls',
        sni: 'microsoft.com',
        ping: 35,
      ),
    ];
    _activeServer = _servers.first;
    _storageService.saveServers(_servers);
    _storageService.saveActiveServerId(_activeServer?.id);
  }

  List<ServerNode> get filteredServers {
    var result = List<ServerNode>.from(_servers);

    // Filter by protocol
    if (_filterProtocol != 'all') {
      result = result.where((s) => s.protocol.toLowerCase() == _filterProtocol.toLowerCase()).toList();
    }

    // Filter by search query
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      result = result.where((s) =>
          s.name.toLowerCase().contains(query) ||
          s.address.toLowerCase().contains(query) ||
          s.protocol.toLowerCase().contains(query)
      ).toList();
    }

    // Sort
    switch (_sortBy) {
      case ServerSortBy.ping:
        result.sort((a, b) {
          final pingA = (a.ping == null || a.ping! <= 0) ? 999999 : a.ping!;
          final pingB = (b.ping == null || b.ping! <= 0) ? 999999 : b.ping!;
          return pingA.compareTo(pingB);
        });
        break;
      case ServerSortBy.name:
        result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case ServerSortBy.protocol:
        result.sort((a, b) => a.protocol.compareTo(b.protocol));
        break;
    }

    return result;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterProtocol(String protocol) {
    _filterProtocol = protocol;
    notifyListeners();
  }

  void setSortBy(ServerSortBy sort) {
    _sortBy = sort;
    notifyListeners();
  }

  void selectServer(ServerNode node) {
    _activeServer = node;
    _storageService.saveActiveServerId(node.id);
    notifyListeners();
  }

  void addServer(ServerNode node) {
    _servers.add(node);
    if (_activeServer == null) {
      _activeServer = node;
      _storageService.saveActiveServerId(node.id);
    }
    _storageService.saveServers(_servers);
    notifyListeners();
  }

  void addMultiple(List<ServerNode> newNodes) {
    _servers.addAll(newNodes);
    if (_activeServer == null && _servers.isNotEmpty) {
      _activeServer = _servers.first;
      _storageService.saveActiveServerId(_activeServer?.id);
    }
    _storageService.saveServers(_servers);
    notifyListeners();
  }

  void removeServer(String id) {
    _servers.removeWhere((s) => s.id == id);
    if (_activeServer?.id == id) {
      _activeServer = _servers.isNotEmpty ? _servers.first : null;
      _storageService.saveActiveServerId(_activeServer?.id);
    }
    _storageService.saveServers(_servers);
    notifyListeners();
  }

  void removeSubscriptionNodes(String subscriptionId) {
    _servers.removeWhere((s) => s.subscriptionId == subscriptionId);
    if (_activeServer?.subscriptionId == subscriptionId) {
      _activeServer = _servers.isNotEmpty ? _servers.first : null;
      _storageService.saveActiveServerId(_activeServer?.id);
    }
    _storageService.saveServers(_servers);
    notifyListeners();
  }

  Future<void> pingSingle(ServerNode node) async {
    await PingService.pingNode(node);
    _storageService.saveServers(_servers);
    notifyListeners();
  }

  Future<void> pingAll() async {
    if (_isPinging || _servers.isEmpty) return;

    _isPinging = true;
    _pingProgress = 0.0;
    notifyListeners();

    int completed = 0;
    final total = _servers.length;

    await PingService.batchPing(
      _servers,
      concurrency: 8,
      onProgress: (node, ping) {
        completed++;
        _pingProgress = completed / total;
        notifyListeners();
      },
    );

    _isPinging = false;
    _pingProgress = 1.0;
    _storageService.saveServers(_servers);
    notifyListeners();
  }

  void selectFastest() {
    final best = PingService.findBestNode(_servers);
    if (best != null) {
      selectServer(best);
    }
  }
}
