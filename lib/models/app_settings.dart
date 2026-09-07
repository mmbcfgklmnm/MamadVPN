import 'package:flutter/material.dart';

enum RoutingMode {
  bypassLanAndIran, // Bypass LAN & IR domains/IPs
  global,           // Route everything through VPN
  direct,           // Only proxy blocked domains
}

enum CoreMode {
  tun,         // Virtual Network Adapter (L3 IP packet capture)
  systemProxy, // HTTP/SOCKS system proxy
}

class AppSettings {
  final ThemeMode themeMode;
  final String accentColor;
  final RoutingMode routingMode;
  final CoreMode coreMode;
  final String dnsServer;
  final bool autoConnect;
  final bool killSwitch;
  final bool enableIpv6;
  final int mtu;
  final int mixedPort;

  const AppSettings({
    this.themeMode = ThemeMode.dark,
    this.accentColor = 'cyan',
    this.routingMode = RoutingMode.bypassLanAndIran,
    this.coreMode = CoreMode.tun,
    this.dnsServer = '1.1.1.1',
    this.autoConnect = false,
    this.killSwitch = false,
    this.enableIpv6 = false,
    this.mtu = 1500,
    this.mixedPort = 20808,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? accentColor,
    RoutingMode? routingMode,
    CoreMode? coreMode,
    String? dnsServer,
    bool? autoConnect,
    bool? killSwitch,
    bool? enableIpv6,
    int? mtu,
    int? mixedPort,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      routingMode: routingMode ?? this.routingMode,
      coreMode: coreMode ?? this.coreMode,
      dnsServer: dnsServer ?? this.dnsServer,
      autoConnect: autoConnect ?? this.autoConnect,
      killSwitch: killSwitch ?? this.killSwitch,
      enableIpv6: enableIpv6 ?? this.enableIpv6,
      mtu: mtu ?? this.mtu,
      mixedPort: mixedPort ?? this.mixedPort,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.name,
      'accentColor': accentColor,
      'routingMode': routingMode.name,
      'coreMode': coreMode.name,
      'dnsServer': dnsServer,
      'autoConnect': autoConnect,
      'killSwitch': killSwitch,
      'enableIpv6': enableIpv6,
      'mtu': mtu,
      'mixedPort': mixedPort,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    ThemeMode theme = ThemeMode.dark;
    if (json['themeMode'] == 'light') theme = ThemeMode.light;
    if (json['themeMode'] == 'system') theme = ThemeMode.system;

    RoutingMode routing = RoutingMode.bypassLanAndIran;
    if (json['routingMode'] == 'global') routing = RoutingMode.global;
    if (json['routingMode'] == 'direct') routing = RoutingMode.direct;

    CoreMode core = CoreMode.tun;
    if (json['coreMode'] == 'systemProxy') core = CoreMode.systemProxy;

    return AppSettings(
      themeMode: theme,
      accentColor: json['accentColor'] ?? 'cyan',
      routingMode: routing,
      coreMode: core,
      dnsServer: json['dnsServer'] ?? '1.1.1.1',
      autoConnect: json['autoConnect'] ?? false,
      killSwitch: json['killSwitch'] ?? false,
      enableIpv6: json['enableIpv6'] ?? false,
      mtu: json['mtu'] ?? 1500,
      mixedPort: json['mixedPort'] ?? 20808,
    );
  }
}
