import 'package:flutter_test/flutter_test.dart';
import 'package:bapjaram/features/intake/models/intake_model.dart';

void main() {
  group('IntakeDetail.fromJson', () {
    test('모든 필드 파싱', () {
      final json = {
        'menu_name': '밥',
        'eaten_ratio': 0.8,
        'calories': 300.0,
        'protein': 10.0,
        'carbs': 60.0,
        'fat': 5.0,
        'sodium': 200.0,
      };
      final d = IntakeDetail.fromJson(json);

      expect(d.menuName, '밥');
      expect(d.eatenRatio, 0.8);
      expect(d.calories, 300.0);
      expect(d.protein, 10.0);
      expect(d.carbs, 60.0);
      expect(d.fat, 5.0);
      expect(d.sodium, 200.0);
    });

    test('int 값도 double 로 변환', () {
      final json = {
        'menu_name': '국',
        'eaten_ratio': 1,
        'calories': 150,
        'protein': 5,
        'carbs': 20,
        'fat': 3,
        'sodium': 300,
      };
      final d = IntakeDetail.fromJson(json);
      expect(d.eatenRatio, 1.0);
      expect(d.calories, 150.0);
    });
  });

  group('MealIntake.fromJson', () {
    test('items 파싱', () {
      final json = {
        'meal_type': 'lunch',
        'items': [
          {'menu_name': '밥', 'eaten_ratio': 1.0, 'calories': 300.0, 'protein': 10.0, 'carbs': 60.0, 'fat': 5.0, 'sodium': 100.0},
          {'menu_name': '국', 'eaten_ratio': 0.5, 'calories': 50.0, 'protein': 2.0, 'carbs': 5.0, 'fat': 1.0, 'sodium': 200.0},
        ],
      };
      final mi = MealIntake.fromJson(json);

      expect(mi.mealType, 'lunch');
      expect(mi.items.length, 2);
      expect(mi.items[1].eatenRatio, 0.5);
    });

    test('items null 이면 빈 리스트', () {
      final json = {'meal_type': 'breakfast', 'items': null};
      final mi = MealIntake.fromJson(json);
      expect(mi.items, isEmpty);
    });
  });

  group('MealIntake.label', () {
    test('식사 타입 레이블', () {
      MealIntake make(String t) => MealIntake.fromJson({'meal_type': t, 'items': []});

      expect(make('breakfast').label, '조식');
      expect(make('lunch').label, '중식');
      expect(make('dinner').label, '석식');
      expect(make('other').label, '중식'); // 기본값
    });
  });

  group('DailyIntake.fromJson', () {
    test('합계 및 meals 파싱', () {
      final json = {
        'date': '2026-06-09',
        'total_calories': 1800.0,
        'total_protein': 80.0,
        'total_carbs': 220.0,
        'total_fat': 55.0,
        'total_sodium': 1500.0,
        'meals': [
          {
            'meal_type': 'lunch',
            'items': [
              {'menu_name': '밥', 'eaten_ratio': 1.0, 'calories': 300.0, 'protein': 10.0, 'carbs': 60.0, 'fat': 5.0, 'sodium': 100.0},
            ],
          },
        ],
      };
      final di = DailyIntake.fromJson(json);

      expect(di.date, '2026-06-09');
      expect(di.totalCalories, 1800.0);
      expect(di.totalProtein, 80.0);
      expect(di.totalCarbs, 220.0);
      expect(di.totalFat, 55.0);
      expect(di.totalSodium, 1500.0);
      expect(di.meals.length, 1);
      expect(di.meals[0].mealType, 'lunch');
    });

    test('meals null 이면 빈 리스트', () {
      final json = {
        'date': '2026-06-09',
        'total_calories': 0.0,
        'total_protein': 0.0,
        'total_carbs': 0.0,
        'total_fat': 0.0,
        'total_sodium': 0.0,
        'meals': null,
      };
      final di = DailyIntake.fromJson(json);
      expect(di.meals, isEmpty);
    });
  });
}
