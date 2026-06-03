import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_global.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/goals/presentation/goals_screen.dart';
import '../../features/goals/presentation/goal_detail_screen.dart';
import '../../features/tasks/presentation/tasks_screen.dart';
import '../../features/study_log/presentation/study_log_screen.dart';
import '../../features/study_log/presentation/note_edit_screen.dart';
import '../../features/review/presentation/review_screen.dart';
import '../../features/focus/presentation/focus_screen.dart';
import '../../features/stats/presentation/stats_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/auth/presentation/auth_guard.dart';
import '../../features/auth/data/auth_repository.dart';
import '../di/injection.dart';
import '../theme/app_theme.dart';

export '../auth/auth_global.dart' show rootNavigatorKey;

final GlobalKey<NavigatorState> _rootNavigatorKey = rootNavigatorKey;
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',
  redirect: (context, state) async {
    final isLoggedIn = await AuthGuard.isLoggedIn;
    final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';

    if (!isLoggedIn && !isAuthRoute) {
      return '/login';
    }
    if (isLoggedIn && isAuthRoute) {
      return '/dashboard';
    }
    return null;
  },
  routes: [
    // Auth routes
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),

    // Main app with bottom navigation
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/goals',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: GoalsScreen(),
          ),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) => GoalDetailScreen(
                goalId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/tasks',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: TasksScreen(),
          ),
        ),
        GoRoute(
          path: '/study-log',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: StudyLogScreen(),
          ),
          routes: [
            GoRoute(
              path: 'edit/:id',
              builder: (context, state) => NoteEditScreen(
                logId: state.pathParameters['id'],
              ),
            ),
            GoRoute(
              path: 'new',
              builder: (context, state) => const NoteEditScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/review',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ReviewScreen(),
          ),
        ),
        GoRoute(
          path: '/focus',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: FocusScreen(),
          ),
        ),
        GoRoute(
          path: '/stats',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: StatsScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
        ),
      ],
    ),
  ],
);

class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: Row(
        children: [
          // Custom Sidebar - matches prototype design
          Container(
            width: 210,
            color: AppTheme.surface,
            child: Column(
              children: [
                // Logo/Header
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primary, AppTheme.primaryLight],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            '学',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        '学流',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.text,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Navigation items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    children: [
                      _SidebarItem(
                        icon: Icons.dashboard_outlined,
                        activeIcon: Icons.dashboard,
                        label: '工作台',
                        isSelected: selectedIndex == 0,
                        onTap: () => context.go('/dashboard'),
                      ),
                      _SidebarItem(
                        icon: Icons.flag_outlined,
                        activeIcon: Icons.flag,
                        label: '学习目标',
                        isSelected: selectedIndex == 1,
                        onTap: () => context.go('/goals'),
                      ),
                      _SidebarItem(
                        icon: Icons.task_outlined,
                        activeIcon: Icons.task,
                        label: '任务清单',
                        isSelected: selectedIndex == 2,
                        onTap: () => context.go('/tasks'),
                      ),
                      _SidebarItem(
                        icon: Icons.note_alt_outlined,
                        activeIcon: Icons.note_alt,
                        label: '学习笔记',
                        isSelected: selectedIndex == 3,
                        onTap: () => context.go('/study-log'),
                      ),
                      _SidebarItem(
                        icon: Icons.refresh_outlined,
                        activeIcon: Icons.refresh,
                        label: '复习计划',
                        isSelected: selectedIndex == 4,
                        onTap: () => context.go('/review'),
                      ),
                      _SidebarItem(
                        icon: Icons.timer_outlined,
                        activeIcon: Icons.timer,
                        label: '专注模式',
                        isSelected: selectedIndex == 5,
                        onTap: () => context.go('/focus'),
                      ),
                      _SidebarItem(
                        icon: Icons.bar_chart_outlined,
                        activeIcon: Icons.bar_chart,
                        label: '数据统计',
                        isSelected: selectedIndex == 6,
                        onTap: () => context.go('/stats'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Footer - Settings + Logout
                Container(
                  color: AppTheme.surface2,
                  child: Column(
                    children: [
                      _SidebarItem(
                        icon: Icons.settings_outlined,
                        activeIcon: Icons.settings,
                        label: '设置',
                        isSelected: selectedIndex == 7,
                        onTap: () => context.go('/settings'),
                      ),
                      _SidebarItem(
                        icon: Icons.logout,
                        activeIcon: Icons.logout,
                        label: '退出登录',
                        isSelected: false,
                        onTap: () async {
                          final authRepo = getIt<AuthRepository>();
                          await authRepo.logout();
                          if (context.mounted) {
                            context.go('/login');
                          }
                        },
                        textColor: AppTheme.textMuted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main content
          Expanded(child: child),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/goals')) return 1;
    if (location.startsWith('/tasks')) return 2;
    if (location.startsWith('/study-log')) return 3;
    if (location.startsWith('/review')) return 4;
    if (location.startsWith('/focus')) return 5;
    if (location.startsWith('/stats')) return 6;
    if (location.startsWith('/settings')) return 7;
    return 0;
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? textColor;

  const _SidebarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppTheme.primary : (textColor ?? AppTheme.textSecondary);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: isSelected ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 18,
                  color: color,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}