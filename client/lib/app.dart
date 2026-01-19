import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'home_container.dart';
import 'core/theme.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          title: 'Pension Web App',
          theme: appTheme,
          home: auth.loggedIn ? const HomeContainer() : const LoginScreen(),
        );
      },
    );
  }
}
