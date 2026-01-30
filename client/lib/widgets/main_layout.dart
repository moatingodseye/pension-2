import 'package:flutter/material.dart';

class MainLayout extends StatelessWidget {
  final Widget primarySidebar;
  final Widget secondarySidebar;
  final Widget body;

  const MainLayout({
    super.key,
    required this.primarySidebar,
    required this.secondarySidebar,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          primarySidebar,
          // Add a subtle border between sidebars
          VerticalDivider(width: 1, thickness: 1, color: Colors.grey.shade300),
          secondarySidebar,
          VerticalDivider(width: 1, thickness: 1, color: Colors.grey.shade300),
          Expanded(
            child: body,
          ),
        ],
      ),
    );
  }
}
