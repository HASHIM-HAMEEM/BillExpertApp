import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/themes/app_theme.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  final List<({IconData icon, IconData selectedIcon, String label})> _navItems = [
    (icon: Icons.space_dashboard_outlined, selectedIcon: Icons.space_dashboard, label: 'Home'),
    (icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long, label: 'Invoices'),
    (icon: Icons.people_alt_outlined, selectedIcon: Icons.people_alt, label: 'Clients'),
    (icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Settings'),
  ];

  void _goBranch(int index, BuildContext context) {
    widget.shell.goBranch(index, initialLocation: index == widget.shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: widget.shell),
      bottomNavigationBar: Container(
        height: 80,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.getCardSurfaceColor(context),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: AppTheme.getBorderColor(context),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_navItems.length, (index) {
            final item = _navItems[index];
            final isSelected = index == widget.shell.currentIndex;

            return Expanded(
              child: GestureDetector(
                onTap: () => _goBranch(index, context),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSelected ? item.selectedIcon : item.icon,
                        color: isSelected
                            ? AppTheme.getTextPrimaryColor(context)
                            : AppTheme.getTextSecondaryColor(context),
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? AppTheme.getTextPrimaryColor(context)
                              : AppTheme.getTextSecondaryColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

