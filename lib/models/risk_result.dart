//risk_resul.dart
class RiskResult {
  final int risk;
  final String label;
  final String segment;
  final Map<String, double> probabilities;

  RiskResult({
    required this.risk,
    required this.label,
    required this.segment,
    required this.probabilities,
  });

  factory RiskResult.fromJson(Map<String, dynamic> json) {
    return RiskResult(
      risk: json['risk'] ?? 0,
      label: json['label'] ?? '',
      segment: json['segment'] ?? '',
      probabilities: Map<String, double>.from(
        (json['probabilities'] ?? {}).map(
              (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
        ),
      ),
    );
  }

  double get probability0Percent => (probabilities['0'] ?? 0.0) * 100;
  double get probability1Percent => (probabilities['1'] ?? 0.0) * 100;
  double get scorePercent => (probabilities['1'] ?? 0.0) * 100;
}