import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'home_container.dart';
import 'core/theme.dart';
import 'widgets/exceptionWidget.dart';

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            scaffoldMessengerKey: messengerKey,
            title: 'Pension Web App',
            theme: appTheme,
            home: auth.loggedIn ? const HomeContainer() : const LoginScreen(),
          );
        },
      ),
    );
  }
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorListener(
      child: ErrorApp(),
    );
  }
}