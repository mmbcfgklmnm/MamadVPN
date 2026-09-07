class AppConstants {
  static const String appName = 'MamadVPN';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  static const String githubRepo = 'https://github.com/mamadvpn/mamadvpn';

  // Storage Keys
  static const String keyServers = 'mamad_vpn_servers';
  static const String keyActiveServerId = 'mamad_vpn_active_server_id';
  static const String keySubscriptions = 'mamad_vpn_subscriptions';
  static const String keySettings = 'mamad_vpn_settings';

  // Default Protocols Supported
  static const List<String> supportedProtocols = [
    'vless',
    'vmess',
    'trojan',
    'shadowsocks',
    'hysteria2',
    'wireguard',
  ];

  // Default DNS Providers
  static const Map<String, String> defaultDnsServers = {
    'Cloudflare Secure (1.1.1.1)': '1.1.1.1',
    'Google Public DNS (8.8.8.8)': '8.8.8.8',
    'AdGuard Ad-Blocking (94.140.14.14)': '94.140.14.14',
    'Quad9 Privacy (9.9.9.9)': '9.9.9.9',
    'Cloudflare DoH': 'https://cloudflare-dns.com/dns-query',
  };

  // Connectivity test URLs
  static const String defaultPingUrl = 'http://cp.cloudflare.com/generate_204';
  static const String alternativePingUrl = 'https://www.google.com/generate_204';
}
