import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/sidebar.dart';
import 'providers/auth_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/account_screen.dart';
import 'screens/transfer_screen.dart';
import 'screens/income_screen.dart';
import 'screens/outgoing_screen.dart';
import 'screens/simulation_screen.dart';
import 'screens/admin_screen.dart';

class HomeContainer extends StatefulWidget {
  const HomeContainer({super.key});

  @override
  State<HomeContainer> createState() => _HomeContainerState();
}

class _HomeContainerState extends State<HomeContainer> {
  int selectedIndex = 0;

  List<Widget> getScreens() {
    return [
      const DashboardScreen(),
      const AccountScreen(),
      const IncomeScreen(),
      const OutgoingScreen(),
      const TransferScreen(),
      const SimulationScreen(),
      const AdminScreen(), // index 6
      Container(),         // logout index 7
    ];
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final screens = getScreens();

    int safeIndex = selectedIndex;

    // Prevent non-admin from viewing admin screen
    if (!auth.isAdmin && selectedIndex == 6) safeIndex = 0;

    // Logout index triggers logout
    if (selectedIndex == 7) {
      WidgetsBinding.instance.addPostFrameCallback((_) => auth.logout());
      safeIndex = 0;
    }

    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            selectedIndex: selectedIndex,
            onItemSelected: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
          ),
          Expanded(child: screens[safeIndex]),
        ],
      ),
    );
  }
}
