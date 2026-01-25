import 'ageOrDate.dart';
import 'account_type.dart';
import 'base.dart';

class Account extends Base{
  final AccountType type;
  final AgeOrDate amountAt;

  Account({
    int? id,
    required String name,
    required double amount,
    required AccountType this.type,
    double rate = 0.0,
    required this.amountAt,
  }) : super(id:id, name:name, amount:amount, rate:rate);

  Account.fromBase(Base base, {required this.type, required AgeOrDate this.amountAt,
  }) : super(id:base.id, name:base.name, amount:base.amount, rate:base.rate);

  // Change Constructor - create a copy of the Account with a different amountAt
  Account.amountAt(Account from, {required this.amountAt})
      : type = from.type,
        super(id: from.id, name: from.name, amount: from.amount, rate: from.rate);

  Account copyWith({
    int? id,
    String? name,
    double? amount,
    AccountType? type,
    AgeOrDate? amountAt,
    double? rate
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      amountAt: amountAt ?? this.amountAt,
      rate: rate ?? this.rate,
    );
  }

  factory Account.fromDb(Map<String, Object?> row) {
    final base = Base.fromDb(row);

    final json = base.toJson();

    row.forEach((columnName, value) {
      switch (columnName) {
        case 'istype':
          json['isType'] = value; // just a string at the point or an int, don't really care
          break;
        case 'amountat':
          json['amountAt'] = AgeOrDate.fromString(value as String?).toJson(); // just a string from the db convert to AgeOrDate
          break;
        default:
          ; //json[columnName] = value; base deals with other columns
      }
    });

    // Single source of truth
    return Account.fromJson(json);
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    final base = Base.fromJson(json);
    return Account.fromBase(base,
      type: AccountType.fromId(json['isType'] as int?),
      amountAt: AgeOrDate.fromJson(json['amountAt'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'isType': type.id,
      'amountAt': amountAt.toJson(),
    });
    return json;
  }
}
