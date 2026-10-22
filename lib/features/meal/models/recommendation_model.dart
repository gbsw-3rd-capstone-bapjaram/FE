class RecItem {
  final String menuName;
  final int calories;
  final double protein, carbs, fat, fiber, sodium;
  final String status;           // 'recommend' | 'moderate' | 'normal'
  final double recommendedRatio; // 0.0 ~ 1.0
  final String reason;

  const RecItem({
    required this.menuName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sodium,
    required this.status,
    required this.recommendedRatio,
    required this.reason,
  });

  factory RecItem.fromJson(Map<String, dynamic> j) => RecItem(
        menuName:        j['menu_name'],
        calories:        (j['calories'] as num).toInt(),
        protein:         (j['protein']  as num).toDouble(),
        carbs:           (j['carbs']    as num).toDouble(),
        fat:             (j['fat']      as num).toDouble(),
        fiber:           (j['fiber']    as num).toDouble(),
        sodium:          (j['sodium']   as num).toDouble(),
        status:          j['status']   ?? 'normal',
        recommendedRatio:(j['recommended_ratio'] as num).toDouble(),
        reason:          j['reason']   ?? '',
      );

  String get statusLabel => switch (status) {
        'recommend' => '추천',
        'moderate'  => '적당히',
        _           => '일반',
      };

  /// 리스트에 표시할 보조 텍스트
  String get nutrientHint {
    if (sodium >= 500) return '나트륨 주의';
    if (protein >= 15) return '단백질 ${protein.toStringAsFixed(0)}g';
    if (carbs >= 30)   return '탄수화물 ${carbs.toStringAsFixed(0)}g';
    return '';
  }
}
