class AccountSnapshot {
  final int? id;
  final int accountId;
  final double value;
  final DateTime date;

  AccountSnapshot({
    this.id,
    required this.accountId,
    required this.value,
    required this.date,
  });

  factory AccountSnapshot.fromDb(Map<String, dynamic> row) {
    return AccountSnapshot(
      id: row['id'] as int?,
      accountId: row['accountId'] as int,
      value: (row['value'] as num).toDouble(),
      date: DateTime.parse(row['date'] as String),
    );
  }

  factory AccountSnapshot.fromJson(Map<String, dynamic> json) {
    return AccountSnapshot(
      id: json['id'] as int?,
      accountId: json['accountId'] as int,
      value: (json['value'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountId': accountId,
      'value': value,
      'date': date.toIso8601String(),
    };
  }
}
