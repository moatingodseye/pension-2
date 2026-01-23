import 'dart:convert';

class Base {
  final int? id;
  final String name;
  final double amount;
  final double rate;

  Base({
    this.id,
    required this.name,
    required this.amount,
    this.rate = 0.0,
  });

  Base copyWith({
    int? id,
    String? name,
    double? amount,
    double? rate
  }) {
    return Base(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      rate: rate ?? this.rate,
    );
  }

  factory Base.fromDb(Map<String, Object?> row) {
    final json = <String, dynamic>{};

    row.forEach((columnName, value) {
      switch (columnName) {
        case 'is_deleted':
          json['isDeleted'] = (value as int) == 1;
          break;

        case 'flags':
          json['flags'] = value as int? ?? 0;
          break;

        case 'inner':
          // Assume stored as JSON string
          json['inner'] =
              value == null ? null : jsonDecode(value as String);
          break;

        default:
          // Default: keep the same name for “nice” columns
          json[columnName] = value;
      }
    });

    // Single source of truth
    return Base.fromJson(json);
  }

  factory Base.fromJson(Map<String, dynamic> json) {
    return Base(
      id: json['id'] as int?,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
//      amountAt: json['amountAt'] == null ? null : AgeOrDate.fromJson(json['amountAt'] as Map<String, dynamic>),
      rate: ((json['rate'] ?? 0.0) as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'rate': rate,
    };
  }
}
