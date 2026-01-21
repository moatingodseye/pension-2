import 'package:flutter/material.dart';

class ScreenLayout extends StatelessWidget {
  final Widget body;
  final Widget? sidebar;
  final double sidebarWidth;

  const ScreenLayout({
    super.key,
    required this.body,
    this.sidebar,
    this.sidebarWidth = 300,
  });

  @override
  Widget build(BuildContext context) {
    if (sidebar == null) {
      return body;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main Content
        Expanded(
          child: body,
        ),
        
        // Divider
        VerticalDivider(width: 1, thickness: 1, color: Colors.grey[300]),
        
        // Right Sidebar
        SizedBox(
          width: sidebarWidth,
          child: Material(
            color: Colors.grey[50],
            child: sidebar!,
          ),
        ),
      ],
    );
  }
}
