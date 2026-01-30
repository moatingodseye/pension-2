import 'package:flutter/material.dart';

class SidebarItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  SidebarItem({required this.icon, required this.label, this.onTap});
}

class CollapsibleSidebar extends StatelessWidget {
  final List<SidebarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final bool isCollapsed;
  final VoidCallback onToggle;
  final Widget? header;
  final Color? backgroundColor;

  const CollapsibleSidebar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.isCollapsed,
    required this.onToggle,
    this.header,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = isCollapsed ? 70.0 : 250.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      color: backgroundColor ?? theme.colorScheme.surface,
      child: Column(
        children: [
          // Header / Toggle
          SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                if (!isCollapsed && header != null) ...[
                  const SizedBox(width: 16),
                  Expanded(child: header!),
                ],
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: onToggle,
                  tooltip: isCollapsed ? 'Expand' : 'Collapse',
                ),
                if (!isCollapsed) const SizedBox(width: 8),
              ],
            ),
          ),
          const Divider(height: 1),
          // Items
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = selectedIndex == index;
                
                // If item has a specific onTap (like Logout), use that, otherwise use onItemSelected
                final VoidCallback onTap = item.onTap ?? () => onItemSelected(index);

                return InkWell(
                  onTap: onTap,
                  child: Container(
                    height: 50,
                    color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : null,
                    child: Row(
                      mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 70,
                          child: Icon(
                            item.icon,
                            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (!isCollapsed)
                          Expanded(
                            child: Text(
                              item.label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
