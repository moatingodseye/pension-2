class Transfer {
  final int? id;
  final String name;
  final double amount;
  final int fromAccount; // fromid
  final int intoAccount; // intoid
  final String startAt;
  final String? endAt;
  final double rate;

  Transfer({
    this.id,
    required this.name,
    required this.amount,
    required this.fromAccount,
    required this.intoAccount,
    required this.startAt,
    this.endAt,
    this.rate = 0.0,
  });

  factory Transfer.fromJson(Map<String, dynamic> json) {
    return Transfer(
      id: json['id'] as int?,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      fromAccount: json['fromid'] as int,
      intoAccount: json['intoid'] as int,
      startAt: json['startat'] as String,
      endAt: json['endat'] as String?,
      rate: ((json['rate'] ?? 0.0) as num).toDouble(),
    );
  }

  Transfer copyWith({
    int? id,
    String? name,
    double? amount,
    int? fromAccount,
    int? intoAccount,
    String? startAt,
    String? endAt,
    double? rate,
  }) {
    return Transfer(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      fromAccount: fromAccount ?? this.fromAccount,
      intoAccount: intoAccount ?? this.intoAccount,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      rate: rate ?? this.rate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'fromid': fromAccount,
      'intoid': intoAccount,
      'startat': startAt,
      'endat': endAt,
      'rate': rate,
    };
  }
}
