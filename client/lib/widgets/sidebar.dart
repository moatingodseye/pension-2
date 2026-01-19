import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';


class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final destinations = <NavigationRailDestination>[
      const NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Dashboard')),
      const NavigationRailDestination(icon: Icon(Icons.account_balance), label: Text('Accounts')),
      const NavigationRailDestination(icon: Icon(Icons.monetization_on), label: Text('Incomes')),
      const NavigationRailDestination(icon: Icon(Icons.money_off), label: Text('Outgoings')),
      const NavigationRailDestination(icon: Icon(Icons.compare_arrows), label: Text('Transfers')),
      const NavigationRailDestination(icon: Icon(Icons.bar_chart), label: Text('Sim')),
      // Admin button always visible
      NavigationRailDestination(
        icon: Icon(Icons.admin_panel_settings,
            color: auth.isAdmin ? null : Colors.grey),
        label: Text(
          'Admin',
          style: TextStyle(color: auth.isAdmin ? null : Colors.grey),
        ),
      ),
      // Logout
      const NavigationRailDestination(icon: Icon(Icons.logout), label: Text('Logout')),
    ];

    return NavigationRail(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            // Disable admin click for non-admin
            if (index == 6 && !auth.isAdmin) return;
            // Logout
            if (index == 7) {
              auth.logout();
              return;
            }
            onItemSelected(index);
          },
          labelType: NavigationRailLabelType.all,
          destinations: destinations,
    );
  }
}
