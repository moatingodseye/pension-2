import 'account_type.dart';

class Account {
  final int? id;
  final String name;
  final double amount;
  final AccountType type;
  final DateTime amountAt;
  final double rate;
  final int? age;

  Account({
    this.id,
    required this.name,
    required this.amount,
    required this.type,
    required this.amountAt,
    this.rate = 0.0,
    this.age = 0,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as int?,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: AccountType.fromId(json['istype'] as int?),
      amountAt: DateTime.parse(json['amountat'] as String),
      rate: ((json['rate'] ?? 0.0) as num).toDouble(),
      age: json['age'] as int? ?? 0,
    );
  }

  Account copyWith({
    int? id,
    String? name,
    double? amount,
    AccountType? type,
    DateTime? amountAt,
    double? rate,
    int? age,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      amountAt: amountAt ?? this.amountAt,
      rate: rate ?? this.rate,
      age: age ?? this.age,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'istype': type.id,
      'amountat': amountAt.toIso8601String().split('T')[0],
      'rate': rate,
      'age': age,
    };
  }
}
