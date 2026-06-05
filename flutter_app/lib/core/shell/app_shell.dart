import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _items = [
    (icon: Icons.dashboard_outlined,       label: 'الرئيسية',   path: '/dashboard'),
    (icon: Icons.people_outline,           label: 'العملاء',    path: '/leads'),
    (icon: Icons.local_shipping_outlined,  label: 'التوصيل',   path: '/delivery'),
    (icon: Icons.credit_card_outlined,     label: 'اشتراكات',  path: '/subscriptions'),
    (icon: Icons.settings_outlined,        label: 'الإعدادات', path: '/settings'),
  ];

  int _idx(BuildContext ctx) {
    final loc = GoRouterState.of(ctx).matchedLocation;
    for (var i = 0; i < _items.length; i++) {
      if (loc.startsWith(_items[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 800;
    if (wide) {
      return Scaffold(
        body: Row(children: [
          NavigationRail(
            extended: MediaQuery.sizeOf(context).width > 1200,
            destinations: _items.map((e) => NavigationRailDestination(
              icon: Icon(e.icon), label: Text(e.label))).toList(),
            selectedIndex: _idx(context),
            onDestinationSelected: (i) => context.go(_items[i].path),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ]),
      );
    }
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        destinations: _items.map((e) => NavigationDestination(
          icon: Icon(e.icon), label: e.label)).toList(),
        selectedIndex: _idx(context),
        onDestinationSelected: (i) => context.go(_items[i].path),
      ),
    );
  }
}
