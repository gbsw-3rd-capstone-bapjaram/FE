class MealMenu {
  final int id;
  final String menuName;
  const MealMenu({required this.id, required this.menuName});
  factory MealMenu.fromJson(Map<String, dynamic> j) =>
      MealMenu(id: j['id'], menuName: j['menu_name']);
  Map<String, dynamic> toJson() => {'id': id, 'menu_name': menuName};
}

class MealModel {
  final int id;
  final String mealDate;
  final String mealType;
  final List<MealMenu> menus;
  final String? calInfo;

  const MealModel({
    required this.id,
    required this.mealDate,
    required this.mealType,
    required this.menus,
    this.calInfo,
  });

  factory MealModel.fromJson(Map<String, dynamic> j) => MealModel(
        id: j['id'],
        mealDate: j['meal_date'] ?? '',
        mealType: j['meal_type'],
        menus: (j['menus'] as List? ?? []).map((e) => MealMenu.fromJson(e)).toList(),
        calInfo: j['cal_info'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'meal_date': mealDate,
        'meal_type': mealType,
        'menus': menus.map((m) => m.toJson()).toList(),
        'cal_info': calInfo,
      };

  String get mealTypeLabel => switch (mealType) {
        'breakfast' => '조식',
        'dinner' => '석식',
        _ => '중식',
      };
}
