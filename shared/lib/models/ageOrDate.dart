
class AgeOrDate {
  final DateTime? date;
  final int? age;

  AgeOrDate({this.date, this.age});

  // Factory constructor to create an instance from a date string or age string
  factory AgeOrDate.fromString(String? value) {
    if (value==null) return AgeOrDate(date:null,age:null);
    if (_isDate(value)) {
      final date = DateTime.tryParse(value);
      return AgeOrDate(date: date, age: null);
    } else if (_isAge(value)) {
      final age = int.tryParse(value);
      return AgeOrDate(date: null, age: age);
    }
    return AgeOrDate(date: null, age: null);
  }

  @override
  String toString() {
    if (date != null) {
      return "${date!.year.toString().padLeft(4, '0')}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}";
    }
    if (age != null) {
      return '$age';
    }
    return 'null';
  }

  // FROM json
  factory AgeOrDate.fromJson(Map<String, dynamic> json) {
    return AgeOrDate(
      date: json['date']==null ? null : DateTime.parse(json['date'] as String),
      age: json['age'] as int?,
    );
  }

  // TO json
  Map<String, dynamic> toJson() {
    return {
      'date': date?.toIso8601String(),
      'age': age,
    };
  }


  // Helper methods for checking date and age patterns
  static bool _isDate(String value) {
    final dateFormat = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    return dateFormat.hasMatch(value);
  }

  static bool _isAge(String value) {
    final ageFormat = RegExp(r'^\d{1,3}$');
    return ageFormat.hasMatch(value);
  }
}
