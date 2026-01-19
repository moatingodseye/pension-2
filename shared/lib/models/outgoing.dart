class Outgoing {
  final int? id;
  final String name;
  final double amount;
  final int? fromAccount; // fromid
  final String startAt;
  final String? endAt;
  final double rate;

  Outgoing({
    this.id,
    required this.name,
    required this.amount,
    this.fromAccount,
    required this.startAt,
    this.endAt,
    this.rate = 0.0,
  });

  factory Outgoing.fromJson(Map<String, dynamic> json) {
    return Outgoing(
      id: json['id'] as int?,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      fromAccount: json['fromid'] as int?,
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
      'fromid': fromAccount,
      'startat': startAt,
      'endat': endAt,
      'rate': rate,
    };
  }
}
