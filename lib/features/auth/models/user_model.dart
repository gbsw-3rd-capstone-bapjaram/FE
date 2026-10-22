class UserModel {
  final int id;
  final String email;
  final String? name;
  final double? height;
  final double? weight;
  final int? age;
  final String? gender;
  final String activityLevel;
  final String goal;
  final double? dailyCalories;

  const UserModel({
    required this.id,
    required this.email,
    this.name,
    this.height,
    this.weight,
    this.age,
    this.gender,
    required this.activityLevel,
    required this.goal,
    this.dailyCalories,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'],
        email: j['email'],
        name: j['name'],
        height: (j['height'] as num?)?.toDouble(),
        weight: (j['weight'] as num?)?.toDouble(),
        age: j['age'],
        gender: j['gender'],
        activityLevel: j['activity_level'] ?? 'medium',
        goal: j['goal'] ?? 'maintain',
        dailyCalories: (j['daily_calories'] as num?)?.toDouble(),
      );

  String get goalLabel => switch (goal) {
        'diet' => '다이어트',
        'bulk' => '증량',
        _ => '유지',
      };

  String get activityLabel => switch (activityLevel) {
        'low' => '낮음',
        'high' => '높음',
        _ => '보통',
      };
}
