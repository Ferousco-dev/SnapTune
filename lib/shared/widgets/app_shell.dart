import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _tabs = [
    _NavTab(label: 'Gallery',   icon: Icons.photo_library_outlined,    activeIcon: Icons.photo_library_rounded,    path: Routes.gallery),
    _NavTab(label: 'Albums',    icon: Icons.folder_outlined,            activeIcon: Icons.folder_rounded,           path: Routes.albums),
    _NavTab(label: 'Optimize',  icon: Icons.auto_fix_high_outlined,     activeIcon: Icons.auto_fix_high_rounded,    path: Routes.optimize),
    _NavTab(label: 'Favorites', icon: Icons.favorite_outline_rounded,   activeIcon: Icons.favorite_rounded,         path: Routes.favorites),
    _NavTab(label: 'Settings',  icon: Icons.settings_outlined,          activeIcon: Icons.settings_rounded,         path: Routes.settings),
  ];

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slideAnim;
  bool _navVisible = true;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 0, // 0 = visible
    );
    _slideAnim = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 1),
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  void _onScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      if (delta > 4 && _navVisible) {
        // Scrolling down — hide
        _navVisible = false;
        _slideCtrl.forward();
      } else if (delta < -4 && !_navVisible) {
        // Scrolling up — show
        _navVisible = true;
        _slideCtrl.reverse();
      }
    } else if (notification is ScrollEndNotification) {
      if (!_navVisible) {
        _navVisible = true;
        _slideCtrl.reverse();
      }
    }
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final idx = AppShell._tabs.indexWhere((t) => location.startsWith(t.path));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final current = _currentIndex(context);
    final navHeight = 60 + MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          _onScroll(n);
          return false;
        },
        child: widget.child,
      ),
      bottomNavigationBar: SlideTransition(
        position: _slideAnim,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.darkOutline : AppColors.outline,
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: navHeight - MediaQuery.of(context).padding.bottom,
              child: Row(
                children: List.generate(AppShell._tabs.length, (i) {
                  final tab = AppShell._tabs[i];
                  final isActive = i == current;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // Tapping the nav always shows it
                        if (!_navVisible) {
                          _navVisible = true;
                          _slideCtrl.reverse();
                        }
                        context.go(tab.path);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              isActive ? tab.activeIcon : tab.icon,
                              key: ValueKey(isActive),
                              size: 22,
                              color: isActive
                                  ? AppColors.primary
                                  : (isDark ? AppColors.darkMuted : AppColors.muted),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            tab.label,
                            style: AppTypography.dmSans(
                              fontSize: 10,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                              color: isActive
                                  ? AppColors.primary
                                  : (isDark ? AppColors.darkMuted : AppColors.muted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String path;
  const _NavTab({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.path,
  });
}
