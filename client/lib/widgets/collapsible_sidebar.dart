import 'package:flutter/material.dart';

class SidebarItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  SidebarItem({required this.icon, required this.label, this.onTap, this.enabled = true});
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
                
                // If item has a specific onTap (like Logout), use that.
                // If onTap is null in a SidebarItem, it means it is disabled.
                // If onTap is NOT set in SidebarItem, it defaults to onItemSelected(index) for navigation items.
                // Wait, if I set onTap: null in SidebarItem (in home_container), it means I passed null explicitly.
                // But the constructor field is `final VoidCallback? onTap;`.
                
                // Logic in home_container was: 
                // SidebarItem(..., onTap: auth.isAdmin ? null : () { snackbar... }) <-- This effectively enables it but shows snackbar.
                // The user said "used to be greyed out". 
                // If I want it greyed out, I should probably pass a flag or handle logic here.
                // In my previous step I did: onTap: auth.isAdmin ? null : () { ... }
                // This means if isAdmin is true, onTap is null. 
                // If isAdmin is false, onTap is the snackbar closure.
                
                // standard items (like Dashboard) have onTap: null (in definition) so they default to onItemSelected.
                // So "null" onTap in SidebarItem definition usually implies "use default matching behavior".
                
                // I need to change home_container logic OR change sidebar logic.
                // Let's change home_container to be:
                // onTap: auth.isAdmin ? null : () {}, // If I want it disabled, I might need a specific way to say "disabled".
                // Or I can check if selectedIndex is achievable.
                
                // Actually, looking at the code: 
                // final VoidCallback onTap = item.onTap ?? () => onItemSelected(index);
                
                // If I want to disable it, I should probably add a `enabled` flag to SidebarItem? 
                // Or I can interpret "onTap is a dummy function" as disabled? No.
                
                // Let's adding `enabled` property to SidebarItem seems cleanest but requires changing SidebarItem definition.
                // Let's check SidebarItem definition at top of file.
                
                // Code view shows:
                // class SidebarItem { final IconData icon; final String label; final VoidCallback? onTap; ... }
                
                // I will add `bool enabled` to SidebarItem.
                
                return InkWell(
                  onTap: item.enabled ? onTap : null,
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
                            color: !item.enabled 
                                ? theme.disabledColor 
                                : isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (!isCollapsed)
                          Expanded(
                            child: Text(
                              item.label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: !item.enabled
                                    ? theme.disabledColor
                                    : isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
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
