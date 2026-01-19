class Income {
  final int? id;
  final String name;
  final double amount;
  final int? intoAccount; // intoid
  final String startAt;
  final String? endAt;
  final double rate;

  Income({
    this.id,
    required this.name,
    required this.amount,
    this.intoAccount,
    required this.startAt,
    this.endAt,
    this.rate = 0.0,
  });

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id'] as int?,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      intoAccount: json['intoid'] as int?,
      startAt: json['startat'] as String,
      endAt: json['endat'] as String?,
      rate: ((json['rate'] ?? 0.0) as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'intoid': intoAccount,
      'startat': startAt,
      'endat': endAt,
      'rate': rate,
    };
  }
}
