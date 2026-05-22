class HydrationLog {
  final int? id;
  final int userId;
  final int amount;
  final DateTime date;

  HydrationLog({
    this.id,
    required this.userId,
    required this.amount,
    required this.date,
  });

  factory HydrationLog.fromJson(Map<String, dynamic> json) {
    return HydrationLog(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      userId: json['user_id'] ?? 1,
      amount: json['amount'] ?? 0,
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }
}
