import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../meal/models/meal_model.dart';
import '../../meal/models/recommendation_model.dart';
import '../../meal/providers/meal_provider.dart';
import '../../../core/theme.dart';
import '../../../core/meal_cache_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  double _progress = 0;
  String _statusText = '초기화 중...';
  bool _started = false;

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // 진척도 부드럽게 업데이트
  void _setProgress(double value, String text) {
    if (!mounted) return;
    setState(() {
      _progress = value.clamp(0.0, 1.0);
      _statusText = text;
    });
  }

  Future<void> _loadAll() async {
    // 인메모리 캐시 초기화 (재진입 시 stale 데이터 방지)
    ref.read(recCacheProvider.notifier).state = {};
    ref.read(intakeCacheProvider.notifier).state = {};

    final dio = ref.read(dioProvider);
    final now = DateTime.now();
    final today = _fmt(now);
    final monthStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    // ── STEP 1: 이번달 급식 (0 → 50%) ──────────────────────
    _setProgress(0.02, '급식 데이터 확인 중...');

    final cached =
        await MealCacheService.loadMonth(now.year, now.month);

    Map<String, List<MealModel>> mealCache;

    if (cached != null && cached.isNotEmpty) {
      _setProgress(0.1, '저장된 급식 데이터 불러오는 중...');
      mealCache = cached;
      _setProgress(0.45, '급식 데이터 준비 완료');
    } else {
      _setProgress(0.05, '${now.month}월 급식 데이터 로드 중...');
      try {
        final res = await dio.get(
          '/meals/month',
          queryParameters: {'month': monthStr},
          onReceiveProgress: (received, total) {
            if (total > 0) {
              final p = 0.05 + 0.38 * (received / total);
              _setProgress(p, '${now.month}월 급식 데이터 로드 중...');
            }
          },
        );
        _setProgress(0.43, '데이터 정리 중...');

        final mealList = res.data['data']['meals'] as List? ?? [];
        mealCache = {};
        for (final item in mealList) {
          final date = item['date'] as String;
          final mealJson = item['meal'] as Map<String, dynamic>?;
          if (mealJson == null) continue;
          mealCache.putIfAbsent(date, () => [])
              .add(MealModel.fromJson(mealJson));
        }
        await MealCacheService.saveMonth(now.year, now.month, mealCache);
      } catch (_) {
        mealCache = {};
      }
      _setProgress(0.48, '급식 데이터 준비 완료');
    }

    ref.read(mealCacheProvider.notifier).state = mealCache;
    _setProgress(0.50, '추천 데이터 준비 중...');

    // ── STEP 2: 오늘 추천 3식 병렬 로드 (50 → 85%) ─────────
    final todayMeals = mealCache[today] ?? [];
    final mealTypes = todayMeals.map((m) => m.mealType).toSet().toList();

    if (mealTypes.isEmpty) {
      // 오늘 급식 없으면 기본 타입 시도
      mealTypes.addAll(['breakfast', 'lunch', 'dinner']);
    }

    double recBase = 0.50;
    final recStep = 0.35 / mealTypes.length;

    await Future.wait(mealTypes.map((type) async {
      try {
        final res = await dio.get('/recommendation',
            queryParameters: {'date': today, 'type': type});
        final items = (res.data['data']['items'] as List)
            .map((e) => RecItem.fromJson(e))
            .toList();
        final key = '${today}_$type';
        ref.read(recCacheProvider.notifier)
            .update((s) => {...s, key: items});
      } catch (_) {}
      recBase += recStep;
      _setProgress(recBase, '$type 추천 완료');
    }));

    _setProgress(0.86, '섭취 기록 불러오는 중...');

    // ── STEP 3: 오늘 섭취 기록 (85 → 95%) ──────────────────
    try {
      final res =
          await dio.get('/intake', queryParameters: {'date': today});
      ref.read(intakeCacheProvider.notifier).state = {
        today: res.data['data'],
      };
    } catch (_) {}

    _setProgress(1.0, '완료!');
    await Future.delayed(const Duration(milliseconds: 350));
    _navigate();
  }

  void _navigate() {
    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (auth.isLoggedIn) {
      final user = auth.user!;
      if (user.height == null || user.weight == null) {
        context.go('/onboarding');
      } else {
        context.go('/home');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    // 인증 복원 완료 → 사전로딩 시작 (1회)
    if (!auth.isRestoring && !_started) {
      _started = true;
      Future.microtask(() {
        if (auth.isLoggedIn) {
          _loadAll();
        } else {
          _navigate();
        }
      });
    }

    return Scaffold(
      backgroundColor: kPrimary,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),

            // 로고
            Image.asset('assets/images/logo.png', width: 120, height: 120),
            const SizedBox(height: 20),
            const Text(
              'BAP JARAM',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '밥자람',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '경북소프트웨어마이스터고\n급식 맞춤 식단 가이드',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 13, height: 1.6),
            ),

            const Spacer(flex: 3),

            // ── 진척도 영역 ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      _statusText,
                      key: ValueKey(_statusText),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: _progress),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      builder: (ctx, value, child) => LinearProgressIndicator(
                        value: value,
                        minHeight: 4,
                        backgroundColor: Colors.white24,
                        valueColor:
                            const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Text('v1.0.0',
                style: TextStyle(color: Colors.white60, fontSize: 12)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
