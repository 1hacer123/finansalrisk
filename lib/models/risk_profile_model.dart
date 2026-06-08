//Örnek riskprofili dataları

class RiskProfile {
  final String profileName;
  final double riskScore;
  final String investmentStyle;
  final String recommendedDistribution;
  final List<InvestmentRecommendation> recommendations;

  RiskProfile({
    required this.profileName,
    required this.riskScore,
    required this.investmentStyle,
    required this.recommendedDistribution,
    required this.recommendations,
  });
}

class InvestmentRecommendation {
  final String title;
  final String description;

  InvestmentRecommendation({
    required this.title,
    required this.description,
  });
}

// sonuç ekranı örnek veri
final mockResult = RiskProfile(
  profileName: 'Orta Risk Profili',
  riskScore: 6.2,
  investmentStyle: 'Dengeli',
  recommendedDistribution: '60% Güvenli, 40% Riskli',
  recommendations: [
    InvestmentRecommendation(
      title: 'Portföy Çeşitlendirme',
      description: "Bitcoin ve Ethereum gibi büyük coin'lerin yanında altcoin'lere de yer verin.",
    ),
    InvestmentRecommendation(
      title: 'Risk Yönetimi',
      description: "Toplam portföyünüzün %5-10'unu kripto paralarda tutun.",
    ),
    InvestmentRecommendation(
      title: 'Düzenli Takip',
      description: "Piyasa hareketlerini takip edin ancak panik satış yapmayın.",
    ),
  ],
);