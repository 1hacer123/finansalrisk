import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';
import '../main_wrapper.dart';
import '../quiz/quiz_screen.dart';
import '../results/result_screen.dart';
import '../../models/risk_result.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isSignUpMode = false;
  bool _isLoading = false;
  String _selectedLevel = "Yeni";

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuthAction() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Lütfen tüm alanları doldurun.", Colors.redAccent);
      return;
    }

    if (_isSignUpMode && name.isEmpty) {
      _showSnackBar("Lütfen adınızı girin.", Colors.redAccent);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? result;
      if (_isSignUpMode) {
        result = await AuthService().signUp(
          email: email,
          password: password,
          fullName: name,
          experience: _selectedLevel,
        );
      } else {
        result = await AuthService().signIn(
          email: email,
          password: password,
        );
      }

      if (result == "success") {
        if (mounted) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            // Check if test results exist
            final doc = await FirebaseFirestore.instance
                .collection('risk_profiles')
                .doc(user.uid)
                .get();

            if (mounted) {
              if (doc.exists) {
                // User has already completed the test
                final riskProfile = RiskResult.fromJson(doc.data()!);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResultScreen(profile: riskProfile),
                  ),
                );
              } else {
                // User has not completed the test, go to MainWrapper
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MainWrapper()),
                );
              }
            }
          }
        }
      } else {
        _showSnackBar("Hata: $result", Colors.redAccent);
      }
    } catch (e) {
      _showSnackBar("Beklenmedik bir hata oluştu.", Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: bgColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
                    child: const CircleAvatar(
                      radius: 45,
                      backgroundColor: kAccentColor,
                      child: Text(
                        '₿',
                        style: TextStyle(fontSize: 45, color: Colors.white, fontWeight: FontWeight.bold),
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
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isSignUpMode ? "Hesap Oluştur ve Başla" : "Kripto Kimliğini Oluştur",
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 15),
                  ),
                  const SizedBox(height: 40),

                  // Name Field (Only in sign up)
                  if (_isSignUpMode) ...[
                    _buildTextField(
                      Icons.person,
                      "Ad Soyad",
                      controller: _nameController,
                    ),
                    const SizedBox(height: 16),
                  ],

                  _buildTextField(
                    Icons.email,
                    "E-posta Adresi",
                    controller: _emailController,
                    isEmail: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    Icons.lock,
                    "Şifre",
                    controller: _passwordController,
                    isPassword: true,
                  ),

                  // Experience selection (Only in sign up)
                  if (_isSignUpMode) ...[
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 16),
                    const Text("Yatırım Tecrübeniz?", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 12),
                    _buildExperienceChips(),
                  ],

                  const SizedBox(height: 32),

                  // ACTION BUTTON
                  _isLoading
                      ? const CircularProgressIndicator(color: kAccentColor)
                      : _buildActionButton(
                          _isSignUpMode ? "Kayıt İşlemini Tamamla" : "Giriş Yap",
                          true,
                          _handleAuthAction,
                        ),

                  const SizedBox(height: 16),

                  // Toggle mode button
                  TextButton(
                    onPressed: () => setState(() => _isSignUpMode = !_isSignUpMode),
                    child: Text(
                      _isSignUpMode ? "Zaten hesabım var, Giriş Yap" : "Hesabın yok mu? Hesap Oluştur",
                      style: const TextStyle(color: kAccentColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    IconData icon,
    String hint, {
    bool isPassword = false,
    bool isEmail = false,
    required TextEditingController controller,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E222D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: kAccentColor.withOpacity(0.7)),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(18),
        ),
      ),
    );
  }

  Widget _buildExperienceChips() {
    List<String> levels = ["Yeni", "Orta", "Uzman"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: levels.map((level) {
        bool isSelected = _selectedLevel == level;
        return ChoiceChip(
          label: Text(level),
          selected: isSelected,
          onSelected: (val) {
            setState(() => _selectedLevel = level);
          },
          backgroundColor: const Color(0xFF1E222D),
          selectedColor: kAccentColor,
          labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white),
        );
      }).toList(),
    );
  }

  Widget _buildActionButton(String text, bool isPrimary, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isPrimary ? kAccentColor : Colors.transparent,
          border: isPrimary ? null : Border.all(color: kAccentColor.withOpacity(0.5)),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
