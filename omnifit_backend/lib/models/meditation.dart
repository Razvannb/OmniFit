class MeditationLog {
  final int? id;
  final int userId;
  final int minutes;
  final DateTime date;

  MeditationLog({
    this.id,
    required this.userId,
    required this.minutes,
    required this.date,
  });

  factory MeditationLog.fromJson(Map<String, dynamic> json) {
    return MeditationLog(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      userId: json['user_id'] ?? 1,
      minutes: json['minutes'] ?? 0,
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minutes': minutes,
      'date': date.toIso8601String(),
    };
  }
}
