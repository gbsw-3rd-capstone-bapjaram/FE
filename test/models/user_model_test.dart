import 'package:flutter_test/flutter_test.dart';
import 'package:bapjaram/features/auth/models/user_model.dart';

void main() {
  group('UserModel.fromJson', () {
    test('모든 필드 정상 파싱', () {
      final json = {
        'id': 1,
        'email': 'test@gbsw.hs.kr',
        'name': '홍길동',
        'height': 175.0,
        'weight': 70.0,
        'age': 17,
        'gender': 'male',
        'activity_level': 'medium',
        'goal': 'maintain',
        'daily_calories': 2500.0,
      };
      final user = UserModel.fromJson(json);

      expect(user.id, 1);
      expect(user.email, 'test@gbsw.hs.kr');
      expect(user.name, '홍길동');
      expect(user.height, 175.0);
      expect(user.weight, 70.0);
      expect(user.age, 17);
      expect(user.gender, 'male');
      expect(user.activityLevel, 'medium');
      expect(user.goal, 'maintain');
      expect(user.dailyCalories, 2500.0);
    });

    test('nullable 필드 null 허용', () {
      final json = {
        'id': 2,
        'email': 'a@b.com',
        'name': null,
        'height': null,
        'weight': null,
        'age': null,
        'gender': null,
        'activity_level': 'medium',
        'goal': 'diet',
        'daily_calories': null,
      };
      final user = UserModel.fromJson(json);

      expect(user.name, isNull);
      expect(user.height, isNull);
      expect(user.weight, isNull);
      expect(user.age, isNull);
      expect(user.gender, isNull);
      expect(user.dailyCalories, isNull);
    });

    test('activity_level, goal 누락 시 기본값', () {
      final json = {'id': 3, 'email': 'x@y.com'};
      final user = UserModel.fromJson(json);

      expect(user.activityLevel, 'medium');
      expect(user.goal, 'maintain');
    });

    test('숫자 타입 변환 (int → double)', () {
      final json = {
        'id': 4,
        'email': 'x@y.com',
        'height': 170,   // int
        'weight': 60,    // int
        'daily_calories': 2000,
        'activity_level': 'low',
        'goal': 'bulk',
      };
      final user = UserModel.fromJson(json);

      expect(user.height, 170.0);
      expect(user.weight, 60.0);
      expect(user.dailyCalories, 2000.0);
    });
  });

  group('UserModel 레이블', () {
    test('goalLabel', () {
      expect(UserModel.fromJson({'id': 1, 'email': 'a@b.com', 'goal': 'diet', 'activity_level': 'medium'}).goalLabel, '다이어트');
      expect(UserModel.fromJson({'id': 1, 'email': 'a@b.com', 'goal': 'bulk', 'activity_level': 'medium'}).goalLabel, '증량');
      expect(UserModel.fromJson({'id': 1, 'email': 'a@b.com', 'goal': 'maintain', 'activity_level': 'medium'}).goalLabel, '유지');
      expect(UserModel.fromJson({'id': 1, 'email': 'a@b.com', 'goal': 'other', 'activity_level': 'medium'}).goalLabel, '유지');
    });

    test('activityLabel', () {
      expect(UserModel.fromJson({'id': 1, 'email': 'a@b.com', 'goal': 'maintain', 'activity_level': 'low'}).activityLabel, '낮음');
      expect(UserModel.fromJson({'id': 1, 'email': 'a@b.com', 'goal': 'maintain', 'activity_level': 'high'}).activityLabel, '높음');
      expect(UserModel.fromJson({'id': 1, 'email': 'a@b.com', 'goal': 'maintain', 'activity_level': 'medium'}).activityLabel, '보통');
    });
  });
}
