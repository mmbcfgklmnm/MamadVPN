import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/subscription.dart';
import '../../providers/subscription_controller.dart';
import '../../providers/server_controller.dart';
import '../widgets/glass_card.dart';
import '../servers/add_server_dialog.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
        actions: [
          Consumer2<SubscriptionController, ServerController>(
            builder: (context, subCtrl, serverCtrl, child) {
              return IconButton(
                icon: subCtrl.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync_rounded),
                tooltip: 'Update All Subscriptions',
                onPressed: subCtrl.isLoading
                    ? null
                    : () => subCtrl.updateAll(serverController: serverCtrl),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddServerDialog(),
          );
        },
        backgroundColor: isDark ? AppColors.neonCyan : AppColors.lightPrimary,
        foregroundColor: isDark ? Colors.black : Colors.white,
        icon: const Icon(Icons.add_link_rounded),
        label: const Text('Add Subscription', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Consumer2<SubscriptionController, ServerController>(
        builder: (context, subCtrl, serverCtrl, child) {
          final subs = subCtrl.subscriptions;

          if (subs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.rss_feed_rounded,
                    size: 60,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No subscriptions added yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Subscribe to your provider to keep server nodes automatically updated with the latest addresses and encryption keys.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            itemCount: subs.length,
            itemBuilder: (context, index) {
              final sub = subs[index];
              return _buildSubscriptionCard(context, sub, subCtrl, serverCtrl, isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildSubscriptionCard(
    BuildContext context,
    Subscription sub,
    SubscriptionController subCtrl,
    ServerController serverCtrl,
    bool isDark,
  ) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final hasQuota = sub.totalBytes > 0;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.neonCyan : AppColors.lightPrimary).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.cloud_sync_rounded,
                        color: isDark ? AppColors.neonCyan : AppColors.lightPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sub.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Updated: ${dateFormat.format(sub.updatedAt)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Actions (Refresh & Delete)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    tooltip: 'Update',
                    onPressed: () => subCtrl.updateSubscription(sub, serverController: serverCtrl),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.disconnectedRed),
                    tooltip: 'Delete',
                    onPressed: () => subCtrl.deleteSubscription(sub.id, serverController: serverCtrl),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Sub Details / URL
          Text(
            sub.url,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),

          const SizedBox(height: 12),

          // Quota Bar (if provided by provider)
          if (hasQuota) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: sub.usagePercent,
                minHeight: 6,
                backgroundColor: isDark ? AppColors.darkSurface : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  sub.usagePercent > 0.85 ? AppColors.disconnectedRed : AppColors.neonCyan,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Used: ${Formatters.formatBytes(sub.usedBytes)} / ${Formatters.formatBytes(sub.totalBytes)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                Text(
                  '${(sub.usagePercent * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.neonCyan : AppColors.lightPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // Footer Tags (Node count, Expiry)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${sub.nodeCount} nodes',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              if (sub.expireDate != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Expires: ${DateFormat('yyyy/MM/dd').format(sub.expireDate!)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neonPurple,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
