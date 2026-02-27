import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../shared/theme/shadcn_theme.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static final _tabs = [
    (icon: LucideIcons.home, label: 'Home', path: '/'),
    (icon: LucideIcons.bookOpen, label: 'Recipes', path: '/recipes'),
    (icon: LucideIcons.calendarDays, label: 'Meal Plan', path: '/meal-plan'),
    (icon: LucideIcons.package, label: 'Pantry', path: '/pantry'),
    (icon: LucideIcons.messageCircle, label: 'Chat', path: '/chat'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path) &&
          (_tabs[i].path == '/' ? location == '/' : true)) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.background,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.mutedForeground,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          elevation: 0,
          onTap: (i) => context.go(_tabs[i].path),
          items: _tabs.map((t) => BottomNavigationBarItem(
            icon: Icon(t.icon, size: 20),
            label: t.label,
          )).toList(),
        ),
      ),
    );
  }
}
