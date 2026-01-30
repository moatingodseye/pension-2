class SimulationResult {
  final double sumPotMin;
  final double sumPotMax;
  final double incomeMin;
  final double incomeMax;
  final double xAxisMin;
  final double xAxisMax;
  
  final List<String> nameList;
  final List<double> sumList;
  final List<double> incomeList;
  final List<List<double>> accountMap;
  final List<double> monteMinList;
  final List<double> monteMaxList;
  final List<double> totalIncomeList; // New: Cash flow INTO Current Account
  final List<double> totalOutgoingList; // New: Cash flow OUT of Current Account
  final List<double> annualNetFlow; // New: Net flow INTO Pension Pot
  final List<List<double>>? montePath; // New field for full traces
  final List<double> ageList;

  SimulationResult({
    required this.sumPotMin,
    required this.sumPotMax,
    required this.incomeMin,
    required this.incomeMax,
    required this.xAxisMin,
    required this.xAxisMax,
    required this.nameList,
    required this.sumList,
    required this.incomeList,
    required this.accountMap,
    required this.monteMinList,
    required this.monteMaxList,
    this.montePath,
    required this.ageList,
    required this.totalIncomeList,
    required this.totalOutgoingList,
    required this.annualNetFlow,
  });

  factory SimulationResult.fromJson(Map<String, dynamic> json) {
    SimulationResult test = SimulationResult(
      sumPotMin: (json['sumPotMin'] as num).toDouble(),
      sumPotMax: (json['sumPotMax'] as num).toDouble(),
      incomeMin: (json['incomeMin'] as num).toDouble(),
      incomeMax: (json['incomeMax'] as num).toDouble(),
      xAxisMin: (json['xAxisMin'] as num).toDouble(),
      xAxisMax: (json['xAxisMax'] as num).toDouble(),
      nameList: (json['name'] as List).map((e) => (e as String)).toList(),
      sumList: (json['sum'] as List).map((e) => (e as num).toDouble()).toList(),
      incomeList: (json['income'] as List).map((e) => (e as num).toDouble()).toList(),
      accountMap: (json['account'] as List).map((e) => (e as List).map((v) => (v as num).toDouble()).toList()).toList(),
      monteMinList: (json['monteMin'] as List).map((e) => (e as num).toDouble()).toList(),
      monteMaxList: (json['monteMax'] as List).map((e) => (e as num).toDouble()).toList(),
      montePath: json['montePath'] != null 
          ? (json['montePath'] as List).map((e) => (e as List).map((v) => (v as num).toDouble()).toList()).toList()
          : null,
      ageList: (json['age'] as List).map((e) => (e as num).toDouble()).toList(),
      totalIncomeList: (json['totalIncome'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      totalOutgoingList: (json['totalOutgoing'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      annualNetFlow: (json['annualNetFlow'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
    );
    return test;
  }

  Map<String, dynamic> toJson() {
    return {
      'sumPotMin': sumPotMin,
      'sumPotMax': sumPotMax,
      'incomeMin': incomeMin,
      'incomeMax': incomeMax,
      'xAxisMin': xAxisMin,
      'xAxisMax': xAxisMax,
      'name': nameList,
      'sum': sumList,
      'income': incomeList,
      'account': accountMap,
      'monteMin': monteMinList,
      'monteMax': monteMaxList,
      if (montePath != null) 'montePath': montePath,
      'age': ageList,
      'totalIncome': totalIncomeList,
      'totalOutgoing': totalOutgoingList,
      'annualNetFlow': annualNetFlow,
    };
  }
}
