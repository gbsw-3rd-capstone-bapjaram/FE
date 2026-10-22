import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../meal/providers/meal_provider.dart';
import '../../../core/theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('프로필'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => _showEditSheet(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 프로필 카드
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kPrimary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name ?? user.email.split('@').first,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      const Text('경북소프트웨어마이스터고', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${user.goalLabel} 목표',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 신체 정보
          Row(children: [
            _StatCard(label: 'cm / 키',   value: user.height?.toStringAsFixed(0) ?? '-'),
            const SizedBox(width: 12),
            _StatCard(label: 'kg / 몸무게', value: user.weight?.toStringAsFixed(0) ?? '-'),
            const SizedBox(width: 12),
            _StatCard(label: '세 / 나이',  value: user.age?.toString() ?? '-'),
          ]),
          const SizedBox(height: 28),
          const Text('설정', style: TextStyle(fontSize: 13, color: kTextGray, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          _SettingGroup(items: [
            _SettingItem(label: '신체 정보 수정',   onTap: () => _showEditSheet(context, ref)),
            _SettingItem(label: '목표 변경',        onTap: () => _showGoalSheet(context, ref)),
            _SettingItem(label: '알림 설정',        onTap: () {}),
          ]),
          const SizedBox(height: 16),
          _SettingGroup(items: [
            _SettingItem(label: '앱 정보', trailing: 'v1.0.0', onTap: null),
            _SettingItem(
              label: '로그아웃',
              labelColor: kTextRed,
              onTap: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ]),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).user!;
    final heightCtrl = TextEditingController(text: user.height?.toStringAsFixed(0) ?? '');
    final weightCtrl = TextEditingController(text: user.weight?.toStringAsFixed(0) ?? '');
    final ageCtrl    = TextEditingController(text: user.age?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('신체 정보 수정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _sheetField(heightCtrl, '키 (cm)')),
              const SizedBox(width: 12),
              Expanded(child: _sheetField(weightCtrl, '몸무게 (kg)')),
            ]),
            const SizedBox(height: 12),
            _sheetField(ageCtrl, '나이'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final ok = await ref.read(authProvider.notifier).updateProfile({
                  'height': double.tryParse(heightCtrl.text),
                  'weight': double.tryParse(weightCtrl.text),
                  'age': int.tryParse(ageCtrl.text),
                });
                if (!context.mounted) return;
                if (ok) {
                  // 추천 캐시 초기화 후 스플래시에서 재로딩
                  ref.read(recCacheProvider.notifier).state = {};
                  ref.read(intakeCacheProvider.notifier).state = {};
                  Navigator.pop(context);
                  context.go('/');
                }
              },
              child: const Text('저장'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showGoalSheet(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).user!;
    String selected = user.goal;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('목표 변경', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              Row(children: [
                for (final e in [('diet', '다이어트'), ('maintain', '유지'), ('bulk', '증량')]) ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selected = e.$1),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: selected == e.$1 ? kPrimary : const Color(0xFFF2F2F2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(e.$2, style: TextStyle(
                          color: selected == e.$1 ? Colors.white : kTextGray,
                          fontWeight: FontWeight.w700,
                        )),
                      ),
                    ),
                  ),
                  if (e.$1 != 'bulk') const SizedBox(width: 8),
                ],
              ]),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final ok = await ref.read(authProvider.notifier).updateProfile({'goal': selected});
                  if (!context.mounted) return;
                  if (ok) {
                    // 추천 캐시 초기화 후 스플래시에서 재로딩
                    ref.read(recCacheProvider.notifier).state = {};
                    ref.read(intakeCacheProvider.notifier).state = {};
                    Navigator.pop(context);
                    context.go('/');
                  }
                },
                child: const Text('저장'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetField(TextEditingController ctrl, String label) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '---')),
        ],
      );
}

class _StatCard extends StatelessWidget {
  final String label, value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFEEEEEE)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: [
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: kTextGray)),
          ]),
        ),
      );
}

class _SettingGroup extends StatelessWidget {
  final List<_SettingItem> items;
  const _SettingGroup({required this.items});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFEEEEEE)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: items.map((item) {
            final idx = items.indexOf(item);
            return Column(
              children: [
                if (idx > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                _SettingTile(item: item),
              ],
            );
          }).toList(),
        ),
      );
}

class _SettingItem {
  final String label;
  final String? trailing;
  final Color? labelColor;
  final VoidCallback? onTap;
  const _SettingItem({required this.label, this.trailing, this.labelColor, required this.onTap});
}

class _SettingTile extends StatelessWidget {
  final _SettingItem item;
  const _SettingTile({required this.item});

  @override
  Widget build(BuildContext context) => ListTile(
        title: Text(item.label, style: TextStyle(fontSize: 15, color: item.labelColor ?? kTextDark)),
        trailing: item.onTap != null
            ? (item.trailing != null ? Text(item.trailing!, style: const TextStyle(color: kTextGray)) : const Icon(Icons.chevron_right, color: kTextGray))
            : (item.trailing != null ? Text(item.trailing!, style: const TextStyle(color: kTextGray)) : null),
        onTap: item.onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      );
}
