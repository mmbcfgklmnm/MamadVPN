import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'home/home_screen.dart';
import 'servers/server_list_screen.dart';
import 'subscriptions/subscription_screen.dart';
import 'settings/settings_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    final pages = [
      HomeScreen(
        onNavigateToServers: () {
          setState(() => _currentIndex = 1);
        },
      ),
      const ServerListScreen(),
      const SubscriptionScreen(),
      const SettingsScreen(),
    ];

    if (isDesktop) {
      // Windows Desktop Layout: Sleek Side Navigation Rail
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() => _currentIndex = index);
              },
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              indicatorColor: (isDark ? AppColors.neonCyan : AppColors.lightPrimary).withOpacity(0.18),
              selectedIconTheme: IconThemeData(
                color: isDark ? AppColors.neonCyan : AppColors.lightPrimary,
              ),
              unselectedIconTheme: IconThemeData(
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
              selectedLabelTextStyle: TextStyle(
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.neonCyan : AppColors.lightPrimary,
              ),
              unselectedLabelTextStyle: TextStyle(
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    color: Colors.black,
                    size: 26,
                  ),
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.speed_rounded),
                  selectedIcon: Icon(Icons.speed_rounded),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.dns_rounded),
                  selectedIcon: Icon(Icons.dns_rounded),
                  label: Text('Servers'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.rss_feed_rounded),
                  selectedIcon: Icon(Icons.rss_feed_rounded),
                  label: Text('Subs'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.tune_rounded),
                  selectedIcon: Icon(Icons.tune_rounded),
                  label: Text('Settings'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: pages[_currentIndex]),
          ],
        ),
      );
    }

    // Android Mobile Layout: Modern Elevated Bottom Navigation Bar
    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          backgroundColor: Colors.transparent,
          indicatorColor: (isDark ? AppColors.neonCyan : AppColors.lightPrimary).withOpacity(0.18),
          destinations: [
            NavigationDestination(
              icon: Icon(
                Icons.speed_rounded,
                color: _currentIndex == 0
                    ? (isDark ? AppColors.neonCyan : AppColors.lightPrimary)
                    : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              ),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.dns_rounded,
                color: _currentIndex == 1
                    ? (isDark ? AppColors.neonCyan : AppColors.lightPrimary)
                    : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              ),
              label: 'Servers',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.rss_feed_rounded,
                color: _currentIndex == 2
                    ? (isDark ? AppColors.neonCyan : AppColors.lightPrimary)
                    : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              ),
              label: 'Subs',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.tune_rounded,
                color: _currentIndex == 3
                    ? (isDark ? AppColors.neonCyan : AppColors.lightPrimary)
                    : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              ),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
