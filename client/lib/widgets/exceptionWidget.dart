import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';

final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

class ErrorListener extends StatelessWidget {
  final Widget child;

  const ErrorListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, provider, _) {
        // Show SnackBar if there's an error
        if (provider.error != null) {
          // Schedule SnackBar after build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            messengerKey.currentState?.showSnackBar(
              SnackBar(
                content: Text(provider.error!),
                duration: const Duration(seconds: 3),
              ),
            );
            provider.clean(); // reset error so it doesn't repeat
          });
        }
        return child;
      },
    );
  }
}
