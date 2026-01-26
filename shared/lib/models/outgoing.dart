import 'ageOrDate.dart';
import 'base.dart';

class Outgoing extends Base {
  final int fromId;
  final AgeOrDate startAt;
  final AgeOrDate? endAt;

  Outgoing({
    int? id,
    required name,
    required amount,
    double rate = 0.0,
    required this.fromId,
    required this.startAt,
    this.endAt,
  }) : super(id:id, name:name, amount:amount, rate:rate);

  Outgoing.fromBase(Base base, {required this.fromId, required this.startAt, this.endAt})
    : super(id:base.id, name:base.name, amount:base.amount, rate:base.rate);

  Outgoing.startAt(Outgoing from, {required this.startAt}) : fromId=from.fromId, endAt=from.endAt, 
    super(id:from.id, name:from.name, amount:from.amount, rate:from.rate);
    
  Outgoing.endAt(Outgoing from, {required this.endAt}) : fromId=from.fromId, startAt=from.startAt, 
    super(id:from.id, name:from.name, amount:from.amount, rate:from.rate);
    
  Outgoing copyWith({
    int? id,
    String? name,
    double? amount,
    double? rate,
    int? fromId,
    AgeOrDate? startAt,
    AgeOrDate? endAt,
  }) {
    return Outgoing(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      rate: rate ?? this.rate,
      fromId: fromId ?? this.fromId,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
    );
  }

  factory Outgoing.fromDb(Map<String, Object?> row) {
    final base = Base.fromDb(row);
    final json = base.toJson();

    row.forEach((columnName, value) {
      switch (columnName) {
        case 'fromid':
          json['fromId'] = value; // just a string at the point
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
    return Outgoing.fromJson(json);     
  }

  factory Outgoing.fromJson(Map<String, dynamic> json) {
    final base = Base.fromJson(json);
    return Outgoing.fromBase(base,
      fromId: json['fromId'] as int,
      startAt: AgeOrDate.fromJson(json['startAt'] as Map<String, dynamic>),
      endAt: json['endAt'] == null ? null : AgeOrDate.fromJson(json['endAt'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'fromId': fromId,
      'startAt': startAt.toJson(),
      'endAt': endAt?.toJson(),
    });
    return json;
  }
}
