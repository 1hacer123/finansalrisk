import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/risk_profile_model.dart';

class ResultScreen extends StatelessWidget {
  final RiskProfile profile;

  const ResultScreen({
    super.key,
    required this.profile
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text(
          "Sonuçlar",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 30),

            _buildScoreCard(),
            const SizedBox(height: 30),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Önerilerimiz',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 15),

            ...profile.recommendations.map((rec) => _buildRecommendationCard(rec)).toList(),
            const SizedBox(height: 30),

            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: kAccentColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.assessment, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 16),
        Text(
          profile.profileName,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        const Text(
          'Dengeli bir yatırım yaklaşımınız var',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildScoreCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildScoreRow('Risk Skoru', '${profile.riskScore} / 10'),
          Divider(height: 30, color: Colors.grey.shade800),
          _buildScoreRow('Yatırım Tarzı', profile.investmentStyle),
          Divider(height: 30, color: Colors.grey.shade800),
          _buildScoreRow('Önerilen Dağılım', profile.recommendedDistribution),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.white70)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
  Widget _buildRecommendationCard(InvestmentRecommendation rec) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF26262A), // Daha açık koyu gri – okunabilirlik arttı
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: kPrimaryColor.withOpacity(0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // BAŞLIK
            Text(
              rec.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,   // ARTIK GÖRÜLÜYOR
              ),
            ),

            const SizedBox(height: 8),

            // AÇIKLAMA
            Text(
              rec.description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [kPrimaryColor, kSecondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: MaterialButton(
            padding: const EdgeInsets.symmetric(vertical: 18),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rapor indirme fonksiyonu yakında.')),
              );
            },
            child: const Text(
              'Detaylı Raporu İndir',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        const SizedBox(height: 15),

        OutlinedButton(
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: BorderSide(color: Colors.white24, width: 1),
          ),
          child: const Text(
            'Yeni Test',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),

        const SizedBox(height: 15),

        OutlinedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Paylaşım fonksiyonu yakında...')),
            );
          },
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: BorderSide(color: Colors.white24, width: 1),
          ),
          child: const Text(
            'Sonuçları Paylaş',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      ],
    );
  }
}
