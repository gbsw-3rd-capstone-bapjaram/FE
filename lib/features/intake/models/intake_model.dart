class IntakeDetail {
  final String menuName;
  final double eatenRatio;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double sodium;

  const IntakeDetail({
    required this.menuName,
    required this.eatenRatio,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.sodium,
  });

  factory IntakeDetail.fromJson(Map<String, dynamic> j) => IntakeDetail(
        menuName: j['menu_name'],
        eatenRatio: (j['eaten_ratio'] as num).toDouble(),
        calories: (j['calories'] as num).toDouble(),
        protein: (j['protein'] as num).toDouble(),
        carbs: (j['carbs'] as num).toDouble(),
        fat: (j['fat'] as num).toDouble(),
        sodium: (j['sodium'] as num).toDouble(),
      );
}

class MealIntake {
  final String mealType;
  final List<IntakeDetail> items;
  const MealIntake({required this.mealType, required this.items});

  factory MealIntake.fromJson(Map<String, dynamic> j) => MealIntake(
        mealType: j['meal_type'],
        items: (j['items'] as List? ?? []).map((e) => IntakeDetail.fromJson(e)).toList(),
      );

  String get label => switch (mealType) {
        'breakfast' => '조식',
        'dinner' => '석식',
        _ => '중식',
      };
}

class DailyIntake {
  final String date;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double totalSodium;
  final List<MealIntake> meals;

  const DailyIntake({
    required this.date,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.totalSodium,
    required this.meals,
  });

  factory DailyIntake.fromJson(Map<String, dynamic> j) => DailyIntake(
        date: j['date'],
        totalCalories: (j['total_calories'] as num).toDouble(),
        totalProtein: (j['total_protein'] as num).toDouble(),
        totalCarbs: (j['total_carbs'] as num).toDouble(),
        totalFat: (j['total_fat'] as num).toDouble(),
        totalSodium: (j['total_sodium'] as num).toDouble(),
        meals: (j['meals'] as List? ?? []).map((e) => MealIntake.fromJson(e)).toList(),
      );
}
