import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/vpn_controller.dart';
import '../../providers/server_controller.dart';
import '../../providers/settings_controller.dart';
import '../widgets/pulse_power_button.dart';
import '../widgets/speed_card.dart';
import '../widgets/glass_card.dart';
import '../widgets/ping_badge.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onNavigateToServers;

  const HomeScreen({
    super.key,
    required this.onNavigateToServers,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Consumer3<VpnController, ServerController, SettingsController>(
          builder: (context, vpnCtrl, serverCtrl, settingsCtrl, child) {
            final activeNode = serverCtrl.activeServer;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top Navigation / Brand Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.shield_rounded,
                              color: Colors.black,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MamadVPN',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              Text(
                                settingsCtrl.settings.coreMode.name == 'tun'
                                    ? 'TUN Virtual Adapter'
                                    : 'System Proxy Mode',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.neonCyan : AppColors.lightPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Theme Mode Quick Switcher
                      IconButton(
                        onPressed: () {
                          final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
                          settingsCtrl.setThemeMode(newMode);
                        },
                        icon: Icon(
                          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          color: isDark ? AppColors.neonCyan : AppColors.lightPrimary,
                        ),
                        tooltip: 'Toggle Theme',
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Center Glowing Pulse Power Button
                  PulsePowerButton(
                    state: vpnCtrl.state,
                    connectedDuration: vpnCtrl.trafficStats.connectedDuration,
                    onTap: () {
                      vpnCtrl.toggleConnection(
                        selectedNode: activeNode,
                        settings: settingsCtrl.settings,
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Active Server Selector Card
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    borderRadius: 20,
                    onTap: onNavigateToServers,
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: (isDark ? AppColors.neonCyan : AppColors.lightPrimary).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.public_rounded,
                            color: isDark ? AppColors.neonCyan : AppColors.lightPrimary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeNode?.name ?? 'No Server Selected',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                activeNode != null
                                    ? '${activeNode.protocol.toUpperCase()} • ${activeNode.address}'
                                    : 'Tap here to choose a server',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (activeNode != null) ...[
                          PingBadge(ping: activeNode.ping),
                          const SizedBox(width: 8),
                        ],
                        Icon(
                          Icons.chevron_right_rounded,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Real-time Bandwidth Cards (Download & Upload)
                  Row(
                    children: [
                      SpeedCard(
                        title: 'Download',
                        bytesPerSec: vpnCtrl.trafficStats.downloadSpeed,
                        totalBytes: vpnCtrl.trafficStats.sessionDownloaded,
                        icon: Icons.arrow_downward_rounded,
                        accentColor: AppColors.neonCyan,
                      ),
                      const SizedBox(width: 14),
                      SpeedCard(
                        title: 'Upload',
                        bytesPerSec: vpnCtrl.trafficStats.uploadSpeed,
                        totalBytes: vpnCtrl.trafficStats.sessionUploaded,
                        icon: Icons.arrow_upward_rounded,
                        accentColor: AppColors.neonPurple,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Routing Mode Indicator Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.alt_route_rounded,
                              size: 18,
                              color: isDark ? AppColors.neonCyan : AppColors.lightPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Routing Rule:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _getRoutingName(settingsCtrl.settings.routingMode),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _getRoutingName(dynamic mode) {
    final str = mode.toString();
    if (str.contains('bypassLanAndIran')) return 'Bypass LAN & IR';
    if (str.contains('global')) return 'Global Proxy';
    return 'Direct Local';
  }
}
