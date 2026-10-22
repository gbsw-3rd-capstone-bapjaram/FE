import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/intake_model.dart';

final intakeDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final dailyIntakeProvider = FutureProvider.autoDispose.family<DailyIntake, String>((ref, date) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/intake', queryParameters: {'date': date});
  return DailyIntake.fromJson(res.data['data']);
});
