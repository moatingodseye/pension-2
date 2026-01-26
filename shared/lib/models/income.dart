import 'ageOrDate.dart';
import 'base.dart';

class Income extends Base{
  final int intoId;
  final AgeOrDate startAt;
  final AgeOrDate? endAt;

  Income({
    int? id,
    required String name,
    required double amount,
    double rate = 0.0,
    required this.intoId,
    required this.startAt,
    this.endAt,
  }) : super(id:id, name:name, amount:amount, rate:rate);

  Income.fromBase(Base base, {required this.intoId, required this.startAt, this.endAt
  }) : super(id:base.id, name:base.name, amount:base.amount, rate:base.rate);

  Income.startAt(Income from, {required this.startAt})
      : intoId = from.intoId, endAt = from.endAt,
        super(id: from.id, name: from.name, amount: from.amount, rate: from.rate);

  Income.endAt(Income from, {required this.endAt})
      : intoId = from.intoId, startAt = from.startAt,
        super(id: from.id, name: from.name, amount: from.amount, rate: from.rate);


  Income copyWith({
    int? id,
    String? name,
    double? amount,
    double? rate,
    int? intoId,
    AgeOrDate? startAt,
    AgeOrDate? endAt,
  }) {
    return Income(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      intoId: intoId ?? this.intoId,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      rate: rate ?? this.rate,
    );
  }

  factory Income.fromDb(Map<String, Object?> row) {
    final base = Base.fromDb(row);
    final json = base.toJson();

    row.forEach((columnName, value) {
      switch (columnName) {
        case 'intoid':
          json['intoId'] = value; // just a string at the point
          break;
        case 'startat':
          json['startAt'] = AgeOrDate.fromString(value as String).toJson();
          break;
        case 'endat':
          json['endAt'] = value == null ? null : AgeOrDate.fromString(value as String).toJson();
          break;
        default:
          ; //json[columnName] = value; base deals with other columns
      }
    });

    // Single source of truth
    return Income.fromJson(json);    
  }

  factory Income.fromJson(Map<String, dynamic> json) {
    final base = Base.fromJson(json);
    Income temp = Income.fromBase(base,
      intoId: json['intoId'] as int,
      startAt: AgeOrDate.fromJson(json['startAt']),
      endAt: json['endAt'] == null ? null : AgeOrDate.fromJson(json['endAt']),
    );
    return temp;
  }

  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'intoId': intoId,
      'startAt': startAt.toJson(),
      'endAt': endAt?.toJson(),
    });
    return json;
  }
}
