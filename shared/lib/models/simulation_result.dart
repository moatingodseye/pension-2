class SimulationResult {
  final double ageMin; // age min/max x-axis
  final double ageMax;
  final double pensionMin; // the pension pots min/max - left y-axis, will be the sum line values
  final double pensionMax;
  final double accountMin; // account min max (excluding pension) - right y-axis
  final double accountMax;
  
  final List<double> ageList; // x-axis, ages
  final List<String> nameList; // names of the accounts for labelling
  final List<double> sumList;
  final List<double> incomeList; // into and out of current
  final List<double> outgoingList; 
  final List<List<double>> accountMap;
  final List<double> monteMinList;
  final List<double> monteMaxList;
  final List<double> intoPensionList; // New: Net flow INTO Pension Pot
  final List<List<double>>? montePath; // New field for full traces

  SimulationResult({
    required this.ageMin,
    required this.ageMax,
    required this.pensionMin,
    required this.pensionMax,
    required this.accountMin,
    required this.accountMax,
    required this.nameList,
    required this.sumList,
    required this.incomeList,
    required this.accountMap,
    required this.monteMinList,
    required this.monteMaxList,
    required this.ageList,
    required this.outgoingList,
    required this.intoPensionList,
    this.montePath,
  });

  factory SimulationResult.fromJson(Map<String, dynamic> json) {
    SimulationResult test = SimulationResult(
      ageList: (json['age'] as List).map((e) => (e as num).toDouble()).toList(),
      ageMin: (json['ageMin'] as num).toDouble(),
      ageMax: (json['ageMax'] as num).toDouble(),
      pensionMin: (json['pensionMin'] as num).toDouble(),
      pensionMax: (json['pensionMax'] as num).toDouble(),
      accountMin: (json['accountMin'] as num).toDouble(),
      accountMax: (json['accountMax'] as num).toDouble(),
      nameList: (json['name'] as List).map((e) => (e as String)).toList(),
      sumList: (json['sum'] as List).map((e) => (e as num).toDouble()).toList(),
      incomeList: (json['income'] as List).map((e) => (e as num).toDouble()).toList(),
      outgoingList: (json['outgoing'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      accountMap: (json['account'] as List).map((e) => (e as List).map((v) => (v as num).toDouble()).toList()).toList(),
      monteMinList: (json['monteMin'] as List).map((e) => (e as num).toDouble()).toList(),
      monteMaxList: (json['monteMax'] as List).map((e) => (e as num).toDouble()).toList(),
      intoPensionList: (json['intoPension'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      montePath: json['montePath'] != null 
          ? (json['montePath'] as List).map((e) => (e as List).map((v) => (v as num).toDouble()).toList()).toList()
          : null,
    );
    return test;
  }

  Map<String, dynamic> toJson() {
    return {
      'age': ageList,
      'ageMin': ageMin,
      'ageMax': ageMax,
      'pensionMin': pensionMin,
      'pensionMax': pensionMax,
      'accountMin': accountMin,
      'accountMax': accountMax,
      'name': nameList,
      'sum': sumList,
      'income': incomeList,
      'outgoing': outgoingList,
      'account': accountMap,
      'monteMin': monteMinList,
      'monteMax': monteMaxList,
      if (montePath != null) 'montePath': montePath,
      'intoPension': intoPensionList,
    };
  }
}
