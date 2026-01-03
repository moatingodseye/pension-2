import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/sidebar.dart';
import 'providers/auth_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/pension_pots_screen.dart';
import 'screens/drawdowns_screen.dart';
import 'screens/state_pension_screen.dart';
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
      const PensionPotsScreen(),
      const DrawdownsScreen(),
      const StatePensionScreen(),
      const SimulationScreen(),
      const AdminScreen(), // index 5
      Container(),         // logout index 6
    ];
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final screens = getScreens();

    int safeIndex = selectedIndex;

    // Prevent non-admin from viewing admin screen
    if (!auth.isAdmin && selectedIndex == 5) safeIndex = 0;

    // Logout index triggers logout
    if (selectedIndex == 6) {
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
