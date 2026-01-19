enum AccountType {
  pension(0, 'Pension'),
  savings(1, 'Savings'),
  current(2, 'Current'),
  isa(3, 'ISA'),
  other(4, 'Other');

  final int id;
  final String label;

  const AccountType(this.id, this.label);

  static AccountType fromId(int? id) {
    return AccountType.values.firstWhere(
      (e) => e.id == id,
      orElse: () => AccountType.pension,
    );
  }
}
