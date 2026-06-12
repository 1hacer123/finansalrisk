import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main_wrapper.dart';
import '../auth/login_screen.dart';
import '../results/result_screen.dart';
import '../../models/risk_result.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();

    // 3 saniye sonra navigasyon başlasın
    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Oturum açılmamışsa -> LoginScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        try {
          // Test sonucu var mı kontrol et
          final doc = await FirebaseFirestore.instance
              .collection('risk_profiles')
              .doc(user.uid)
              .get();

          if (!mounted) return;

          if (doc.exists) {
            // Test çözülmüş -> Doğrudan ResultScreen
            final riskProfile = RiskResult.fromJson(doc.data()!);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ResultScreen(profile: riskProfile)),
            );
          } else {
            // Test çözülmemiş -> MainWrapper (Anket girişi)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainWrapper()),
            );
          }
        } catch (e) {
          // Hata durumunda varsayılan olarak MainWrapper'a git
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainWrapper()),
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A), // Senin koyu temanla uyumlu
              Color(0xFF1E293B),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Büyüyen parlayan logo animasyonu
            ScaleTransition(
              scale: _animation,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.4),
                      blurRadius: 50,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const CircleAvatar(
                  radius: 60,
                  backgroundColor: Color(0xFF2563EB),
                  child: Text(
                    '₿',
                    style: TextStyle(
                        fontSize: 60,
                        color: Colors.white,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Yavaşça beliren uygulama ismi
            FadeTransition(
              opacity: _animation,
              child: const Text(
                "CryptoRisk",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}