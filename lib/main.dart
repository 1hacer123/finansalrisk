import 'package:finansa_yatirim/screens/introduction/splash_screen.dart';
import 'package:finansa_yatirim/screens/main_wrapper.dart';
import 'package:flutter/material.dart';
import 'core/constants.dart';
import 'package:firebase_core/firebase_core.dart';
// Yeni oluşturulan IntroductionScreen'i import ediyoruz
import 'screens/introduction/introduction_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i bu şekilde başlatmak daha garantidir
  await Firebase.initializeApp();

  runApp(const CryptoRiskApp());
}

class CryptoRiskApp extends StatelessWidget {
  const CryptoRiskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CryptoRisk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: kPrimaryColor,
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: kBackgroundColor,
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      // splash screenı ayarladık!
      home: const SplashScreen(),
    );
  }
}