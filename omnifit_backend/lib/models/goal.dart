class Goal {
  final int? id;
  final int userId;
  final String muscleGroup;
  final int targetSets;
  final int currentSets;

  Goal({
    this.id,
    required this.userId,
    required this.muscleGroup,
    required this.targetSets,
    this.currentSets = 0,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      userId: json['user_id'] ?? 1,
      muscleGroup: json['muscleGroup'] ?? '',
      targetSets: json['targetSets'] ?? 0,
      currentSets: json['currentSets'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id?.toString(),
      'muscleGroup': muscleGroup,
      'targetSets': targetSets,
      'currentSets': currentSets,
    };
  }
}
