import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../models/server_node.dart';
import 'glass_card.dart';
import 'ping_badge.dart';

class NodeCard extends StatelessWidget {
  final ServerNode node;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onPing;
  final VoidCallback onDelete;

  const NodeCard({
    super.key,
    required this.node,
    required this.isSelected,
    required this.onSelect,
    required this.onPing,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 18,
      borderColor: isSelected
          ? (isDark ? AppColors.neonCyan : AppColors.lightPrimary)
          : null,
      onTap: onSelect,
      child: Row(
        children: [
          // Radio indicator
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? (isDark ? AppColors.neonCyan : AppColors.lightPrimary)
                    : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
                width: 2,
              ),
              color: isSelected
                  ? (isDark ? AppColors.neonCyan : AppColors.lightPrimary)
                  : Colors.transparent,
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    size: 14,
                    color: isDark ? Colors.black : Colors.white,
                  )
                : null,
          ),
          const SizedBox(width: 14),

          // Server Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Protocol Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getProtocolColor(node.protocol).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        node.protocol.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _getProtocolColor(node.protocol),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Name
                    Expanded(
                      child: Text(
                        node.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${node.address}:${node.port} • ${node.network.toUpperCase()}${node.security != 'none' ? ' • ${node.security.toUpperCase()}' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Ping Pill
          PingBadge(ping: node.ping),

          const SizedBox(width: 4),

          // Actions Popup
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              size: 20,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            color: isDark ? AppColors.darkSurface : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (action) {
              if (action == 'ping') {
                onPing();
              } else if (action == 'copy') {
                if (node.rawUri.isNotEmpty) {
                  Clipboard.setData(ClipboardData(text: node.rawUri));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Config URL copied to clipboard')),
                  );
                }
              } else if (action == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'ping',
                child: Row(
                  children: [
                    Icon(Icons.speed_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('Test Ping'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    Icon(Icons.copy_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('Copy Link'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.disconnectedRed),
                    SizedBox(width: 10),
                    Text('Delete', style: TextStyle(color: AppColors.disconnectedRed)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getProtocolColor(String protocol) {
    switch (protocol.toLowerCase()) {
      case 'vless':
        return AppColors.neonCyan;
      case 'vmess':
        return AppColors.cyberBlue;
      case 'trojan':
        return AppColors.electricViolet;
      case 'hysteria2':
      case 'hy2':
        return AppColors.neonPurple;
      case 'shadowsocks':
        return Colors.amber;
      case 'wireguard':
        return Colors.tealAccent;
      default:
        return Colors.blueGrey;
    }
  }
}
