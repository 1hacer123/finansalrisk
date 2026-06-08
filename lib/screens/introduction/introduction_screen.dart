import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../quiz/quiz_screen.dart';

// Not: _isBeginnerSelection değişkenini sınıfın dışında tutmaya devam edebilirsin
// ama bütünlük için bunu bir stateful widget'a çevirmek daha iyidir.
// Şimdilik tasarım odaklı gidiyoruz.

bool _isBeginnerSelection = true;

class IntroductionScreen extends StatelessWidget {
  const IntroductionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor'ı Container içindeki gradient ile ezeceğiz
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A), // Koyu Gece Mavisi
              Color(0xFF1E293B), // Derin Lacivert
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 40),

                // Özellik kartları
                _buildFeatureCard(
                  icon: Icons.bar_chart_rounded,
                  title: 'Risk Analizi',
                  subtitle: 'Kişiselleştirilmiş risk profili',
                ),
                _buildFeatureCard(
                  icon: Icons.track_changes_rounded,
                  title: 'Yatırım Önerileri',
                  subtitle: 'Risk seviyenize uygun stratejiler',
                ),
                _buildFeatureCard(
                  icon: Icons.memory_rounded,
                  title: 'Makine Öğrenmesi',
                  subtitle: 'Gelişmiş analiz algoritmaları',
                ),

                const Spacer(),

                _buildStartButton(context),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Parlayan Logo Efekti
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: kAccentColor.withOpacity(0.3),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 45,
            backgroundColor: kAccentColor,
            child: const Text(
                '₿',
                style: TextStyle(fontSize: 45, color: Colors.white, fontWeight: FontWeight.bold)
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'CryptoRisk',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Kripto para yatırımlarında risk algınızı keşfedin\nve bilinçli yatırım kararları alın',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E222D), // Soru kartlarıyla aynı renk
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)), // İnce şık çerçeve
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kAccentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: kAccentColor, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [kAccentColor, kAccentColor.withOpacity(0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: kAccentColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: () async{
          _showLoadingDialog(context);
          try {
            // 2. Firebase'den verileri çeken fonksiyonu burada tetikle
            // (FirebaseService içindeki veriyi önceden yükleme metodun varsa onu çağırıyoruz)
            // Eğer veriler zaten QuizScreen içinde çekiliyorsa, sadece küçük bir gecikme verip geçeceğiz.

            await Future.delayed(const Duration(milliseconds: 1500)); // En az 1.5 sn görünsün ki şık dursun

            if (context.mounted) {
              Navigator.pop(context); // Yükleniyor ekranını kapat
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizScreen(isBeginner: _isBeginnerSelection),
                ),
              );
            }
          } catch (e) {
            Navigator.pop(context); // Hata olursa kapat
            print("Veri çekme hatası: $e");
          }
        },
        child: const Text(
          'Teste Başla',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
void _showLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false, // Kullanıcı dışarı basarak kapatamaz
    builder: (BuildContext context) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: const Color(0xFF1E222D),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kAccentColor.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Kendi etrafında dönen Bitcoin logosu
              const SizedBox(
                height: 60,
                width: 60,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Risk Analizi Hazırlanıyor...",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration
                      .none, // Yazı altındaki sarı çizgiyi siler
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}