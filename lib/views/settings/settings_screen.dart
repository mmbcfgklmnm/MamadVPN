import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/app_settings.dart';
import '../../providers/settings_controller.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Configuration'),
      ),
      body: Consumer<SettingsController>(
        builder: (context, controller, child) {
          final settings = controller.settings;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            physics: const BouncingScrollPhysics(),
            children: [
              // -----------------------------------------------------------
              // Appearance & Theme
              // -----------------------------------------------------------
              _buildSectionTitle('APPEARANCE', isDark),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                        SegmentedButton<ThemeMode>(
                          segments: const [
                            ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded)),
                            ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded)),
                            ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.auto_mode_rounded)),
                          ],
                          selected: {settings.themeMode},
                          onSelectionChanged: (set) => controller.setThemeMode(set.first),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // -----------------------------------------------------------
              // Routing Rules
              // -----------------------------------------------------------
              _buildSectionTitle('ROUTING & BYPASS', isDark),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildRadioTile<RoutingMode>(
                      title: 'Bypass LAN & Iran (Domestic)',
                      subtitle: 'Directly routes local Iranian IPs and sites; tunnels international traffic',
                      value: RoutingMode.bypassLanAndIran,
                      groupValue: settings.routingMode,
                      onChanged: (val) {
                        if (val != null) controller.setRoutingMode(val);
                      },
                    ),
                    const Divider(height: 16),
                    _buildRadioTile<RoutingMode>(
                      title: 'Global Proxy',
                      subtitle: 'Routes all device internet traffic through the encrypted VPN proxy',
                      value: RoutingMode.global,
                      groupValue: settings.routingMode,
                      onChanged: (val) {
                        if (val != null) controller.setRoutingMode(val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // -----------------------------------------------------------
              // Core Mode
              // -----------------------------------------------------------
              _buildSectionTitle('VPN ENGINE & TUNNEL', isDark),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildRadioTile<CoreMode>(
                      title: 'TUN Mode (Virtual Network Adapter)',
                      subtitle: 'Intercepts all apps, games, and system traffic at L3 IP level',
                      value: CoreMode.tun,
                      groupValue: settings.coreMode,
                      onChanged: (val) {
                        if (val != null) controller.setCoreMode(val);
                      },
                    ),
                    const Divider(height: 16),
                    _buildRadioTile<CoreMode>(
                      title: 'System Proxy Mode',
                      subtitle: 'Configures HTTP/SOCKS5 system proxy for browser & compatible apps',
                      value: CoreMode.systemProxy,
                      groupValue: settings.coreMode,
                      onChanged: (val) {
                        if (val != null) controller.setCoreMode(val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // -----------------------------------------------------------
              // DNS Configuration
              // -----------------------------------------------------------
              _buildSectionTitle('DNS SERVERS', isDark),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Remote DNS Provider',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'DNS is encrypted inside the VPN tunnel to prevent DNS poisoning and leaks',
                      style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: AppConstants.defaultDnsServers.values.contains(settings.dnsServer)
                          ? settings.dnsServer
                          : AppConstants.defaultDnsServers.values.first,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      items: AppConstants.defaultDnsServers.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.value,
                          child: Text(entry.key, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) controller.setDnsServer(val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // -----------------------------------------------------------
              // Security & Automation
              // -----------------------------------------------------------
              _buildSectionTitle('SECURITY & BEHAVIOR', isDark),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      title: const Text('Auto-Connect', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Automatically connect on app launch', style: TextStyle(fontSize: 12)),
                      value: settings.autoConnect,
                      activeColor: isDark ? AppColors.neonCyan : AppColors.lightPrimary,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (_) => controller.toggleAutoConnect(),
                    ),
                    const Divider(height: 12),
                    SwitchListTile.adaptive(
                      title: const Text('Kill Switch', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Block network if VPN disconnects unexpectedly', style: TextStyle(fontSize: 12)),
                      value: settings.killSwitch,
                      activeColor: isDark ? AppColors.neonCyan : AppColors.lightPrimary,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (_) => controller.toggleKillSwitch(),
                    ),
                    const Divider(height: 12),
                    SwitchListTile.adaptive(
                      title: const Text('Enable IPv6', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Allow IPv6 routing inside tunnel', style: TextStyle(fontSize: 12)),
                      value: settings.enableIpv6,
                      activeColor: isDark ? AppColors.neonCyan : AppColors.lightPrimary,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (_) => controller.toggleIpv6(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // -----------------------------------------------------------
              // About MamadVPN
              // -----------------------------------------------------------
              _buildSectionTitle('ABOUT', isDark),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.shield_rounded, color: Colors.black, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              AppConstants.appName,
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            Text(
                              'Version ${AppConstants.appVersion} (Build ${AppConstants.appBuildNumber})',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Cross-platform multi-protocol censorship circumvention client supporting VLESS, VMess, Trojan, Hysteria 2, Shadowsocks, and WireGuard for Windows and Android.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        ),
      ),
    );
  }

  Widget _buildRadioTile<T>({
    required String title,
    required String subtitle,
    required T value,
    required T groupValue,
    required ValueChanged<T?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<T>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
