class SimulationResult {
  final double sumPotMin;
  final double sumPotMax;
  final double incomeMin;
  final double incomeMax;
  final double xAxisMin;
  final double xAxisMax;
  
  final List<double> sum;
  final List<double> income;
  final List<List<double>> pots;
  final List<double> monteMin;
  final List<double> monteMax;
  final List<List<double>>? montePaths; // New field for full traces
  final List<double> ages;

  SimulationResult({
    required this.sumPotMin,
    required this.sumPotMax,
    required this.incomeMin,
    required this.incomeMax,
    required this.xAxisMin,
    required this.xAxisMax,
    required this.sum,
    required this.income,
    required this.pots,
    required this.monteMin,
    required this.monteMax,
    this.montePaths, // Optional
    required this.ages,
  });

  factory SimulationResult.fromJson(Map<String, dynamic> json) {
    return SimulationResult(
      sumPotMin: (json['sumPotMin'] as num).toDouble(),
      sumPotMax: (json['sumPotMax'] as num).toDouble(),
      incomeMin: (json['incomeMin'] as num).toDouble(),
      incomeMax: (json['incomeMax'] as num).toDouble(),
      xAxisMin: (json['xAxisMin'] as num).toDouble(),
      xAxisMax: (json['xAxisMax'] as num).toDouble(),
      sum: (json['sum'] as List).map((e) => (e as num).toDouble()).toList(),
      income: (json['income'] as List).map((e) => (e as num).toDouble()).toList(),
      pots: (json['pots'] as List).map((e) => (e as List).map((v) => (v as num).toDouble()).toList()).toList(),
      monteMin: (json['monteMin'] as List).map((e) => (e as num).toDouble()).toList(),
      monteMax: (json['monteMax'] as List).map((e) => (e as num).toDouble()).toList(),
      montePaths: json['montePaths'] != null 
          ? (json['montePaths'] as List).map((e) => (e as List).map((v) => (v as num).toDouble()).toList()).toList()
          : null,
      ages: (json['ages'] as List).map((e) => (e as num).toDouble()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sumPotMin': sumPotMin,
      'sumPotMax': sumPotMax,
      'incomeMin': incomeMin,
      'incomeMax': incomeMax,
      'xAxisMin': xAxisMin,
      'xAxisMax': xAxisMax,
      'sum': sum,
      'income': income,
      'pots': pots,
      'monteMin': monteMin,
      'monteMax': monteMax,
      if (montePaths != null) 'montePaths': montePaths,
      'ages': ages,
    };
  }
}
