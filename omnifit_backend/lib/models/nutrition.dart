class NutritionLog {
  final int? id;
  final int userId;
  final String mealName;
  final int calories;
  final int proteins;
  final int carbs;
  final int fats;
  final DateTime date;

  NutritionLog({
    this.id,
    required this.userId,
    required this.mealName,
    required this.calories,
    required this.proteins,
    required this.carbs,
    required this.fats,
    required this.date,
  });

  factory NutritionLog.fromJson(Map<String, dynamic> json) {
    return NutritionLog(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      userId: json['user_id'] ?? 1,
      mealName: json['meal_name'] ?? 'Meal',
      calories: json['calories'] ?? 0,
      proteins: json['proteins'] ?? 0,
      carbs: json['carbs'] ?? 0,
      fats: json['fats'] ?? 0,
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id?.toString(),
      'meal_name': mealName,
      'calories': calories,
      'proteins': proteins,
      'carbs': carbs,
      'fats': fats,
      'date': date.toIso8601String(),
    };
  }
}
