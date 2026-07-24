import 'package:cardx/features/cards/views/collection_screen.dart';
import 'package:cardx/features/dashboard/views/dashboard_screen.dart';
import 'package:cardx/features/admin/views/admin_dashboard_screen.dart';
import 'package:cardx/features/profile/views/profile_screen.dart';
import 'package:cardx/features/shop/views/shop_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/admin_provider.dart';
import '../../../core/theme/app_theme.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>()!;
    final hasAdminAccess = ref.watch(hasAdminAccessProvider);

    final screens = <Widget>[
      const DashboardScreen(),
      const CollectionScreen(),
      const ShopScreen(),
      if (hasAdminAccess) const AdminDashboardScreen(),
      const ProfileScreen(),
    ];

    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Home',
      ),
      const NavigationDestination(
        icon: Icon(Icons.style_outlined),
        selectedIcon: Icon(Icons.style),
        label: 'Sammlung',
      ),
      const NavigationDestination(
        icon: Icon(Icons.store_outlined),
        selectedIcon: Icon(Icons.store),
        label: 'Shop',
      ),
      if (hasAdminAccess)
        const NavigationDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Profil',
      ),
    ];

    final selectedIndex = _currentIndex >= screens.length
        ? screens.length - 1
        : _currentIndex;

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: brand.surfaceBackground,
        indicatorColor: theme.colorScheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: destinations,
      ),
    );
  }
}
