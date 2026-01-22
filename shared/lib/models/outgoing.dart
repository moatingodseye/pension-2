class Outgoing {
  final int? id;
  final String name;
  final double amount;
  final int fromId;
  final DateTime startAt;
  final DateTime? endAt;
  final double rate;

  Outgoing({
    this.id,
    required this.name,
    required this.amount,
    required this.fromId,
    required this.startAt,
    this.endAt,
    this.rate = 0.0,
  });

  factory Outgoing.fromJson(Map<String, dynamic> json) {
    return Outgoing(
      id: json['id'] as int?,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      fromId: json['fromid'] as int?,
      startAt: json['startat'] as String,
      endAt: json['endat'] as String?,
      rate: ((json['rate'] ?? 0.0) as num).toDouble(),
    );
  }

  Outgoing copyWith({
    int? id,
    String? name,
    double? amount,
    int? fromAccount,
    String? startAt,
    String? endAt,
    double? rate,
  }) {
    return Outgoing(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      fromAccount: fromAccount ?? this.fromAccount,
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
      'startat': startAt,
      'endat': endAt,
      'rate': rate,
    };
  }
}
