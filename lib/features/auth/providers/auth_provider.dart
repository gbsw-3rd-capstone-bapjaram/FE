import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api_client.dart';
import '../../../core/constants.dart';
import '../models/user_model.dart';
import '../../meal/providers/meal_provider.dart';

// ── Dio 싱글턴 ────────────────────────────────────────────
final dioProvider = Provider((ref) => buildDio());

// ── 인증 상태 ─────────────────────────────────────────────
class AuthState {
  final UserModel? user;
  final String? token;
  final bool loading;
  final bool isRestoring; // 앱 시작 시 토큰 복원 중 여부
  final String? error;

  const AuthState({
    this.user,
    this.token,
    this.loading = false,
    this.isRestoring = true, // 초기값 true → 복원 완료 전까지 대기
    this.error,
  });

  bool get isLoggedIn => token != null;

  AuthState copyWith({UserModel? user, String? token, bool? loading, bool? isRestoring, String? error}) =>
      AuthState(
        user:         user         ?? this.user,
        token:        token        ?? this.token,
        loading:      loading      ?? this.loading,
        isRestoring:  isRestoring  ?? this.isRestoring,
        error:        error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState()) {
    _restore();
  }

  final Ref _ref;

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(kTokenKey);
      if (token == null) {
        state = state.copyWith(isRestoring: false);
        return;
      }
      final dio = _ref.read(dioProvider);
      final res = await dio.get('/user/me');
      final user = UserModel.fromJson(res.data['data']);
      state = AuthState(user: user, token: token, isRestoring: false);
    } catch (_) {
      // 토큰 만료 or 서버 오류 → 로그아웃 처리
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(kTokenKey);
      state = const AuthState(isRestoring: false);
    }
  }

  // ── 이메일 인증 코드 발송 ───────────────────────────────
  Future<bool> sendVerification(String email) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final dio = _ref.read(dioProvider);
      await dio.post('/auth/send-verification', data: {'email': email});
      state = state.copyWith(loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: _msg(e));
      return false;
    }
  }

  // ── 이메일 인증 코드 확인 ───────────────────────────────
  Future<bool> verifyEmail(String email, String code) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final dio = _ref.read(dioProvider);
      await dio.post('/auth/verify-email', data: {'email': email, 'code': code});
      state = state.copyWith(loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: _msg(e));
      return false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final dio = _ref.read(dioProvider);
      final res = await dio.post('/auth/signup', data: {'email': email, 'password': password});
      final token = res.data['data']['token'] as String;
      final user = UserModel.fromJson(res.data['data']['user']);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kTokenKey, token);
      state = AuthState(user: user, token: token);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: _msg(e));
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final dio = _ref.read(dioProvider);
      final res = await dio.post('/auth/login', data: {'email': email, 'password': password});
      final token = res.data['data']['token'] as String;
      final user = UserModel.fromJson(res.data['data']['user']);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kTokenKey, token);
      state = AuthState(user: user, token: token);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: _msg(e));
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final dio = _ref.read(dioProvider);
      final res = await dio.put('/user/me', data: data);
      final user = UserModel.fromJson(res.data['data']);
      state = state.copyWith(user: user, loading: false);

      // 프로필 변경 → 추천 캐시 무효화 → meal_screen 자동 리로드
      _ref.invalidate(recommendationProvider);

      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: _msg(e));
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kTokenKey);
    state = const AuthState();
  }

  String _msg(dynamic e) {
    try {
      return (e as dynamic).response?.data['message'] ?? e.toString();
    } catch (_) {
      return e.toString();
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref),
);
