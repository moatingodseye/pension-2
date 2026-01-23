import 'ageOrDate.dart';
import 'base.dart';

class Transfer extends Base{
  final int fromId; 
  final int intoId; 
  final AgeOrDate startAt;
  final AgeOrDate? endAt;

  Transfer({
    int? id,
    required name,
    required amount,
    double rate = 0.0,
    required this.fromId,
    required this.intoId,
    required this.startAt,
    this.endAt,
  }) : super(id:id, name:name, amount:amount, rate:rate);

  Transfer.fromBase(Base base, {required this.fromId, required this.intoId, required this.startAt,
    this.endAt}) : super(id:base.id, name:base.name, amount:base.amount, rate:base.rate);

  Transfer copyWith({
    int? id,
    String? name,
    double? amount,
    double? rate,
    int? fromId,
    int? intoId,
    AgeOrDate? startAt,
    AgeOrDate? endAt,
  }) {
    return Transfer(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      rate: rate ?? this.rate,
      fromId: fromId ?? this.fromId,
      intoId: intoId ?? this.intoId,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
    );
  }

  factory Transfer.fromDb(Map<String, Object?> row) {
    final base = Base.fromDb(row);
    final json = base.toJson();

    row.forEach((columnName, value) {
      switch (columnName) {
        case 'intoid':
          json['intoId'] = value; // just a int at the point
          break;
        case 'fromid':
          json['fromId'] = value; // just a int at the point
          break;
        case 'startat':
          json['startAt'] = AgeOrDate.fromString(value as String).toJson();
          break;
        case 'endat':
          json['endAt'] == null ? null : AgeOrDate.fromString(value as String).toJson();
          break;
        default:
          ; //json[columnName] = value; base deals with other columns
      }
    });

    // Single source of truth
    return Transfer.fromJson(json);    
  }

  factory Transfer.fromJson(Map<String, dynamic> json) {
    final base = Base.fromJson(json);
    return Transfer.fromBase(base,
      fromId: json['fromId'] as int,
      intoId: json['intoId'] as int,
      startAt: AgeOrDate.fromJson(json['startAt'] as Map<String,dynamic>),
      endAt: json['endAt'] == null ? null : AgeOrDate.fromJson(json['endAt'] as Map<String,dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'fromId': fromId,
      'intoId': intoId,
      'startAt': startAt.toJson(),
      'endAt': endAt?.toJson(),
    });
    return json;
  }
}
