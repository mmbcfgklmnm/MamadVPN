import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/server_controller.dart';
import '../widgets/node_card.dart';
import 'add_server_dialog.dart';

class ServerListScreen extends StatelessWidget {
  const ServerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Servers & Nodes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            tooltip: 'Auto-select Fastest',
            onPressed: () {
              final controller = context.read<ServerController>();
              controller.selectFastest();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Selected node with lowest latency')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.speed_rounded),
            tooltip: 'Test All Pings',
            onPressed: () {
              context.read<ServerController>().pingAll();
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
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Config', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Consumer<ServerController>(
        builder: (context, controller, child) {
          final servers = controller.filteredServers;

          return Column(
            children: [
              // Batch Ping Progress Bar
              if (controller.isPinging)
                LinearProgressIndicator(
                  value: controller.pingProgress > 0 ? controller.pingProgress : null,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? AppColors.neonCyan : AppColors.lightPrimary,
                  ),
                ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      onChanged: controller.setSearchQuery,
                      decoration: InputDecoration(
                        hintText: 'Search servers by name or host...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        suffixIcon: controller.searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => controller.setSearchQuery(''),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Protocol Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildFilterChip(context, 'All', 'all', controller),
                          const SizedBox(width: 8),
                          _buildFilterChip(context, 'VLESS', 'vless', controller),
                          const SizedBox(width: 8),
                          _buildFilterChip(context, 'VMess', 'vmess', controller),
                          const SizedBox(width: 8),
                          _buildFilterChip(context, 'Trojan', 'trojan', controller),
                          const SizedBox(width: 8),
                          _buildFilterChip(context, 'Hysteria 2', 'hysteria2', controller),
                          const SizedBox(width: 8),
                          _buildFilterChip(context, 'Shadowsocks', 'shadowsocks', controller),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Server Count & Sorting Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${servers.length} node(s) available',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                    DropdownButton<ServerSortBy>(
                      value: controller.sortBy,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.sort_rounded, size: 18),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                      onChanged: (sort) {
                        if (sort != null) controller.setSortBy(sort);
                      },
                      items: const [
                        DropdownMenuItem(
                          value: ServerSortBy.ping,
                          child: Text('Lowest Latency'),
                        ),
                        DropdownMenuItem(
                          value: ServerSortBy.name,
                          child: Text('Name (A-Z)'),
                        ),
                        DropdownMenuItem(
                          value: ServerSortBy.protocol,
                          child: Text('Protocol'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Server List
              Expanded(
                child: servers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.dns_outlined,
                              size: 56,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No servers match your criteria',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tap the "+ Add Config" button to import nodes',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        physics: const BouncingScrollPhysics(),
                        itemCount: servers.length,
                        itemBuilder: (context, index) {
                          final node = servers[index];
                          final isSelected = controller.activeServer?.id == node.id;

                          return NodeCard(
                            node: node,
                            isSelected: isSelected,
                            onSelect: () => controller.selectServer(node),
                            onPing: () => controller.pingSingle(node),
                            onDelete: () => controller.removeServer(node.id),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    String protocolValue,
    ServerController controller,
  ) {
    final isSelected = controller.filterProtocol == protocolValue;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => controller.setFilterProtocol(protocolValue),
      selectedColor: isDark ? AppColors.neonCyan : AppColors.lightPrimary,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightSurface,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected
            ? (isDark ? Colors.black : Colors.white)
            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? Colors.transparent
              : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
        ),
      ),
    );
  }
}
