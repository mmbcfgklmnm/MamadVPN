import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/server_controller.dart';
import '../../providers/subscription_controller.dart';
import '../../services/config_parser.dart';

class AddServerDialog extends StatefulWidget {
  const AddServerDialog({super.key});

  @override
  State<AddServerDialog> createState() => _AddServerDialogState();
}

class _AddServerDialogState extends State<AddServerDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _importTextController = TextEditingController();
  final TextEditingController _subNameController = TextEditingController();
  final TextEditingController _subUrlController = TextEditingController();

  // Manual Form
  String _selectedProtocol = 'vless';
  final TextEditingController _manualNameController = TextEditingController();
  final TextEditingController _manualHostController = TextEditingController();
  final TextEditingController _manualPortController = TextEditingController(text: '443');
  final TextEditingController _manualUuidController = TextEditingController();
  final TextEditingController _manualSniController = TextEditingController();
  String _manualSecurity = 'tls';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _importTextController.dispose();
    _subNameController.dispose();
    _subUrlController.dispose();
    _manualNameController.dispose();
    _manualHostController.dispose();
    _manualPortController.dispose();
    _manualUuidController.dispose();
    _manualSniController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      setState(() {
        _importTextController.text = data!.text!;
      });
    }
  }

  void _handleImportConfigs() {
    final content = _importTextController.text.trim();
    if (content.isEmpty) return;

    final nodes = ConfigParser.parseMultiple(content);
    if (nodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid VPN configs found in text')),
      );
      return;
    }

    final serverController = context.read<ServerController>();
    serverController.addMultiple(nodes);

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Successfully imported ${nodes.length} server(s)')),
    );
  }

  Future<void> _handleAddSubscription() async {
    final name = _subNameController.text.trim();
    final url = _subUrlController.text.trim();

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid subscription URL')),
      );
      return;
    }

    final subController = context.read<SubscriptionController>();
    final serverController = context.read<ServerController>();

    final success = await subController.addSubscription(
      name: name.isEmpty ? 'Subscription' : name,
      url: url,
      serverController: serverController,
    );

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription imported successfully')),
        );
      } else {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                SizedBox(width: 8),
                Text('Import Failed'),
              ],
            ),
            content: Text(
              subController.errorMessage ?? 'Could not retrieve subscription nodes. Check your internet connection or URL.',
              style: const TextStyle(fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _handleManualAdd() {
    final host = _manualHostController.text.trim();
    final port = int.tryParse(_manualPortController.text.trim()) ?? 443;
    final uuid = _manualUuidController.text.trim();
    final name = _manualNameController.text.trim();

    if (host.isEmpty || uuid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill host and UUID/password')),
      );
      return;
    }

    final serverController = context.read<ServerController>();
    final node = ConfigParser.parseSingle(
      '$_selectedProtocol://$uuid@$host:$port?security=$_manualSecurity&sni=${_manualSniController.text.trim()}#${name.isNotEmpty ? Uri.encodeComponent(name) : host}',
    );

    if (node != null) {
      serverController.addServer(node);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server added successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 520,
        height: 520,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add VPN Configuration',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TabBar(
              controller: _tabController,
              labelColor: isDark ? AppColors.neonCyan : AppColors.lightPrimary,
              unselectedLabelColor: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              indicatorColor: isDark ? AppColors.neonCyan : AppColors.lightPrimary,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: 'Import Link'),
                Tab(text: 'Subscription'),
                Tab(text: 'Manual'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Import Link / Clipboard
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Paste links (VLESS, VMess, Trojan, etc.)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          TextButton.icon(
                            onPressed: _pasteFromClipboard,
                            icon: const Icon(Icons.paste_rounded, size: 16),
                            label: const Text('Paste Clipboard', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: TextField(
                          controller: _importTextController,
                          maxLines: null,
                          expands: true,
                          style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                          decoration: const InputDecoration(
                            hintText: 'vless://...\nvmess://...\ntrojan://...\nss://...',
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleImportConfigs,
                          child: const Text('Import Configs'),
                        ),
                      ),
                    ],
                  ),

                  // Tab 2: Subscription URL
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _subNameController,
                          decoration: const InputDecoration(
                            labelText: 'Subscription Name',
                            hintText: 'e.g. Premium VIP Nodes',
                            prefixIcon: Icon(Icons.bookmark_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _subUrlController,
                          decoration: InputDecoration(
                            labelText: 'Subscription URL',
                            hintText: 'https://...',
                            prefixIcon: const Icon(Icons.link_rounded),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.paste_rounded, size: 18),
                              tooltip: 'Paste URL',
                              onPressed: () async {
                                final data = await Clipboard.getData(Clipboard.kTextPlain);
                                if (data?.text != null) {
                                  _subUrlController.text = data!.text!.trim();
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceLight.withOpacity(0.5) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 18, color: isDark ? AppColors.neonCyan : AppColors.lightPrimary),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Supports Base64, Clash YAML, and Sing-Box JSON subscriptions. Handles custom ports (e.g. 2096) and SSL bypass.',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Consumer<SubscriptionController>(
                          builder: (context, controller, child) {
                            return SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: controller.isLoading ? null : _handleAddSubscription,
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: controller.isLoading
                                    ? Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: isDark ? Colors.black : Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          const Text(
                                            'Fetching Subscription...',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                        ],
                                      )
                                    : const Text(
                                        'Fetch & Save Subscription',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Tab 3: Manual Entry
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: _selectedProtocol,
                          decoration: const InputDecoration(labelText: 'Protocol'),
                          items: const [
                            DropdownMenuItem(value: 'vless', child: Text('VLESS')),
                            DropdownMenuItem(value: 'vmess', child: Text('VMess')),
                            DropdownMenuItem(value: 'trojan', child: Text('Trojan')),
                            DropdownMenuItem(value: 'shadowsocks', child: Text('Shadowsocks')),
                            DropdownMenuItem(value: 'hysteria2', child: Text('Hysteria 2')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedProtocol = val);
                          },
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _manualNameController,
                          decoration: const InputDecoration(labelText: 'Remark / Name'),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _manualHostController,
                                decoration: const InputDecoration(labelText: 'Server Address'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: TextField(
                                controller: _manualPortController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Port'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _manualUuidController,
                          decoration: const InputDecoration(labelText: 'UUID / Password'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _manualSniController,
                          decoration: const InputDecoration(labelText: 'SNI / Server Name'),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _handleManualAdd,
                            child: const Text('Add Node'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
