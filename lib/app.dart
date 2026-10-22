import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/meal/screens/meal_screen.dart';
import 'features/intake/screens/intake_screen.dart';
import 'features/profile/screens/profile_screen.dart';

// ── 라우터 ────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/',           builder: (ctx, st) => const SplashScreen()),
      GoRoute(path: '/login',      builder: (ctx, st) => const LoginScreen()),
      GoRoute(path: '/onboarding', builder: (ctx, st) => const OnboardingScreen()),
      GoRoute(path: '/home',       builder: (ctx, st) => const HomeShell()),
    ],
  );
});

// ── 루트 앱 ───────────────────────────────────────────────
class BapjaramApp extends ConsumerWidget {
  const BapjaramApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: '밥자람',
      theme: appTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

// ── IndexedStack 기반 홈 Shell ────────────────────────────
// 3개 탭 화면을 동시에 트리에 유지 → 탭 전환 시 리빌드 없음
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _idx = 0;

  static const _tabs = [
    (icon: Icons.bar_chart_outlined,     activeIcon: Icons.bar_chart_rounded,     label: '급식'),
    (icon: Icons.access_time_outlined,   activeIcon: Icons.access_time_filled,    label: '기록'),
    (icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded,        label: '프로필'),
  ];

  // 화면 인스턴스를 상수로 유지 → IndexedStack이 dispose하지 않음
  static const _screens = [
    MealScreen(),
    IntakeScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _idx,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: BottomNavigationBar(
          currentIndex: _idx,
          onTap: (i) => setState(() => _idx = i),
          selectedItemColor: kPrimary,
          unselectedItemColor: const Color(0xFFBDBDBD),
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
              fontFamily: 'Paperlogy', fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              const TextStyle(fontFamily: 'Paperlogy', fontSize: 11),
          items: _tabs
              .map((t) => BottomNavigationBarItem(
                    icon: Icon(t.icon),
                    activeIcon: Icon(t.activeIcon),
                    label: t.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}
