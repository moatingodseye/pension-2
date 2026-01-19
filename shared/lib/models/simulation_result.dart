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
    required this.ages,
  });

  factory SimulationResult.fromJson(Map<String, dynamic> json) {
    return SimulationResult(
      sumPotMin: (json['sumMin'] as num).toDouble(),
      sumPotMax: (json['sumMax'] as num).toDouble(),
      incomeMin: (json['incomeMin'] as num).toDouble(),
      incomeMax: (json['incomeMax'] as num).toDouble(),
      xAxisMin: (json['xAxisMin'] as num).toDouble(),
      xAxisMax: (json['xAxisMax'] as num).toDouble(),
      sum: List<double>.from(json['sum']),
      income: List<double>.from(json['income']),
      pots: (json['pots'] as List).map((e) => List<double>.from(e)).toList(),
      monteMin: List<double>.from(json['monte_min']),
      monteMax: List<double>.from(json['monte_max']),
      ages: List<double>.from(json['ages']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sumMin': sumPotMin,
      'sumMax': sumPotMax,
      'incomeMin': incomeMin,
      'incomeMax': incomeMax,
      'xAxisMin': xAxisMin,
      'xAxisMax': xAxisMax,
      'sum': sum,
      'income': income,
      'pots': pots,
      'monte_min': monteMin,
      'monte_max': monteMax,
      'ages': ages,
    };
  }
}
