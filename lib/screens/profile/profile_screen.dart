import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart'; // AuthService'i import etmeyi unutma!
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/risk_result.dart';
import '../quiz/quiz_screen.dart';
import 'past_analyses_screen.dart';
import '../../services/portfolio_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // 1. KONTROLLER: Ekranda yazılanları okumak için
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();

  final PortfolioService _portfolioService = PortfolioService();

  bool _isLoggedIn = false;
  bool _isSignUpMode = false;
  String _selectedLevel = "Yeni";
  
  RiskResult? _userRiskProfile;
  bool _isLoadingRiskProfile = true;

  bool _isLoadingAiResponse = false;
  String _aiResponse = '';
  String _aiError = '';

  @override
  void initState() {
    super.initState();
    _checkUserStatus(); // Sayfa açılır açılmaz kullanıcıyı kontrol et
  }


  void _checkUserStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var userData = await AuthService().getUserData();
      if (userData != null) {
        setState(() {
          _isLoggedIn = true;
          _nameController.text = userData['fullName'] ?? "";
          // İŞTE BURASI: Firestore'dan gelen 'Orta' bilgisini değişkene atıyoruz
          _selectedLevel = userData['experience'] ?? "Yeni";
        });
      }
      
      try {
        final riskDoc = await FirebaseFirestore.instance
            .collection('risk_profiles')
            .doc(user.uid)
            .get();
        if (riskDoc.exists && mounted) {
          setState(() {
            _userRiskProfile = RiskResult.fromJson(riskDoc.data()!);
          });
        }
      } catch (e) {
        print("Profil risk verisi çekilemedi: $e");
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingRiskProfile = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoadingRiskProfile = false;
        });
      }
    }
  }
  
  Future<void> _askAssistant() async {
    final profile = _userRiskProfile;
    if (profile == null) return;
    
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _isLoadingAiResponse = true;
      _aiResponse = '';
      _aiError = '';
    });

    FocusScope.of(context).unfocus();

    try {
      final response = await _portfolioService.askAi(
        question: question,
        riskLabel: profile.label,
        segment: profile.segment,
      );
      setState(() {
        _aiResponse = response;
        _isLoadingAiResponse = false;
        _questionController.clear();
      });
    } catch (e) {
      setState(() {
        _aiError = e.toString().replaceFirst("Exception: ", "");
        _isLoadingAiResponse = false;
      });
    }
  }

  @override
  void dispose() {
    // Hafıza sızıntısını önlemek için kontrolleri kapatıyoruz
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _questionController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
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
          child: _isLoggedIn
              ? _buildProfileDashboard()
              : (_isSignUpMode ? _buildSignUpView() : _buildAuthView()),
        ),
      ),
    );
  }

  // --- 1. KAYIT OLMA EKRANI ---
  Widget _buildSignUpView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Text(
            "Yeni Hesap Oluştur",
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          // Kontrolleri buradaki textfieldlara bağlıyoruz
          _buildTextField(Icons.person, "Ad Soyad", controller: _nameController),
          const SizedBox(height: 16),
          _buildTextField(Icons.email, "E-posta Adresi", controller: _emailController, isEmail: true),
          const SizedBox(height: 16),
          _buildTextField(Icons.lock, "Şifre", controller: _passwordController, isPassword: true),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),
          const Text("Yatırım Tecrübeniz?", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          _buildExperienceChips(),
          const SizedBox(height: 40),

          // KAYIT BUTONU
          _buildActionButton("Kayıt İşlemini Tamamla", true, () async {
            print("BUTONA BASILDI!");
            try {
              String? result = await AuthService().signUp(
                email: _emailController.text.trim(),
                password: _passwordController.text.trim(),
                fullName: _nameController.text.trim(),
                experience: _selectedLevel,
              );

              print("Firebase Sonucu: $result");

              if (result == "success") {
                var userData = await AuthService().getUserData();
                if (userData != null) {
                  setState(() {
                    _isLoggedIn = true;
                    _nameController.text = userData['fullName'] ?? "";
                    // BURAYI DA UNUTMA:
                    _selectedLevel = userData['experience'] ?? "Yeni";
                  });
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Hata: $result"), backgroundColor: Colors.red),
                );
              }
            } catch (e) {
              print("Hata: $e");
            }
          }),

          TextButton(
            onPressed: () => setState(() => _isSignUpMode = false),
            child: const Text("Zaten hesabım var, Giriş Yap", style: TextStyle(color: kAccentColor)),
          ),
        ],
      ),
    );
  }

  // --- 2. GİRİŞ YAPMA EKRANI ---
  Widget _buildAuthView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildAuthIcon(),
          const SizedBox(height: 32),
          const Text(
            "Kripto Kimliğini Oluştur",
            style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 50),
          _buildTextField(Icons.email, "E-posta Adresi", controller: _emailController, isEmail: true),
          const SizedBox(height: 16),
          _buildTextField(Icons.lock, "Şifre", controller: _passwordController, isPassword: true),
          const SizedBox(height: 32),
          _buildActionButton("Giriş Yap", true, () async {
            // 1. Kullanıcıdan bilgileri alıyoruz
            String email = _emailController.text.trim();
            String password = _passwordController.text.trim();

            if (email.isEmpty || password.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Lütfen e-posta ve şifre girin!")),
              );
              return;
            }

            // 2. AuthService üzerinden Firebase'e soruyoruz
            String? result = await AuthService().signIn(
              email: email,
              password: password,
            );

            if (result == "success") {
              // 1. Giriş başarılı olunca kullanıcı verilerini çek
              var userData = await AuthService().getUserData();

              setState(() {
                _isLoggedIn = true;
                if (userData != null) {
                  _nameController.text = userData['fullName'] ?? "İsimsiz Kullanıcı";
                }
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Giriş Başarılı!"), backgroundColor: Colors.green),
              );
            } else {
              // Hatalıysa (şifre yanlış vb.) uyarı ver
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Hata: $result"), backgroundColor: Colors.red),
              );
            }
          }),
          const SizedBox(height: 16),
          _buildActionButton("Hesap Oluştur", false, () {
            setState(() => _isSignUpMode = true);
          }),
        ],
      ),
    );
  }
// --- 3. PROFİL DASHBOARD ---
  Widget _buildProfileDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: kAccentColor,
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 20),

          // İSİM: const kaldırıldı, veriye bağlandı
          Text(
            _nameController.text.isEmpty ? "Yükleniyor..." : _nameController.text,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold
            ),
          ),

          // İsim satırının hemen altındaki o sabit satırı şununla değiştir:
          Text(
              _selectedLevel.isEmpty ? "Öğrenci" : "Yatırım Seviyesi: $_selectedLevel",
              style: const TextStyle(color: Colors.white54)
          ),

          const SizedBox(height: 30),

          // RİSK KARTI: Zaten dinamik bir widget
          _buildRiskSummaryCard(),

          const SizedBox(height: 30),

          // MENÜ ÖGELERİ
          _buildMenuTile(Icons.history, "Geçmiş Analizlerim", onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PastAnalysesScreen()),
            );
          }),

          _buildMenuTile(Icons.logout, "Çıkış Yap", color: Colors.redAccent, onTap: () async {
            // Firebase'den gerçekten çıkış yapıyoruz
            await AuthService().signOut();
            //Uygulama arayüzünü temizleyip giriş ekranadön
            setState(() {
              _isLoggedIn = false;
              _isSignUpMode = false;
              _nameController.clear();
              _emailController.clear();
              _passwordController.clear();
            });
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Oturum Kapatıldı. ")),
            );
          }),
        ],
      ),
    );
  }
  // --- YARDIMCI WIDGETLAR ---
  Widget _buildTextField(IconData icon, String hint, {bool isPassword = false, bool isEmail = false, TextEditingController? controller}) {
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
          child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildAuthIcon() => const Icon(Icons.security, size: 60, color: kAccentColor);
  
  Widget _buildRiskSummaryCard() {
    if (_isLoadingRiskProfile) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(color: kAccentColor),
        ),
      );
    }

    final profile = _userRiskProfile;
    if (profile == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E222D),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            const Icon(Icons.analytics_outlined, color: kAccentColor, size: 48),
            const SizedBox(height: 16),
            const Text(
              "Henüz Risk Testi Çözülmedi",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Yatırım risk profilinizi belirlemek ve kişiselleştirilmiş portföy önerileri almak için hemen testi çözün.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const QuizScreen(isBeginner: true)),
                  );
                },
                child: const Text("Risk Testine Başla", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }

    // If profile is available, show the details and investment suggestions
    final bool isHighRisk = profile.risk == 1 || profile.label.toLowerCase().contains('yüksek');
    final Color riskColor = isHighRisk ? kChartRed : kChartGreen;

    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E222D),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Mevcut Risk Profiliniz",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: riskColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: riskColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      profile.label.toUpperCase(),
                      style: TextStyle(color: riskColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildProfileStat("Segment", profile.segment.toUpperCase(), Colors.amberAccent),
                  const SizedBox(width: 12),
                  _buildProfileStat("Risk Değeri", profile.risk.toString(), kAccentColor),
                  const SizedBox(width: 12),
                  _buildProfileStat("Skor", "%${profile.scorePercent.toStringAsFixed(1)}", riskColor),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildPortfolioSuggestion(isHighRisk),
        const SizedBox(height: 24),
        Card(
          color: colorScheme.surfaceVariant.withOpacity(0.15),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: colorScheme.primary.withOpacity(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: _buildAiAssistantContent(colorScheme),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioSuggestion(bool isHighRisk) {
    final List<Map<String, dynamic>> items = isHighRisk
        ? [
            {"asset": "Kripto (BTC, ETH)", "percent": 50, "color": kPrimaryColor, "icon": Icons.currency_bitcoin_rounded},
            {"asset": "Hisse Senetleri", "percent": 30, "color": Colors.purpleAccent, "icon": Icons.show_chart_rounded},
            {"asset": "Altcoinler", "percent": 20, "color": Colors.orangeAccent, "icon": Icons.token_rounded},
          ]
        : [
            {"asset": "Tahvil & Bono", "percent": 60, "color": Colors.teal, "icon": Icons.account_balance_rounded},
            {"asset": "Altın (Emtia)", "percent": 30, "color": Colors.amber, "icon": Icons.star_rounded},
            {"asset": "Kripto (BTC)", "percent": 10, "color": kPrimaryColor, "icon": Icons.currency_bitcoin_rounded},
          ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E222D),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_outline_rounded, color: isHighRisk ? kChartRed : kChartGreen, size: 22),
              const SizedBox(width: 8),
              const Text(
                "Önerilen Varlık Dağılımı",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...items.map((item) {
            final double percent = (item['percent'] as int).toDouble();
            final Color color = item['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(item['icon'] as IconData, color: color, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            item['asset'] as String,
                            style: TextStyle(color:
                            Colors.white.withOpacity(0.8),
                                fontSize: 13),
                          ),
                        ],
                      ),
                      Text(
                        "%${item['percent']}",
                        style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Stack(
                    children: [
                      Container(
                        height: 5,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Container(
                            height: 5,
                            width: constraints.maxWidth * (percent / 100),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2.5),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, {Color color = Colors.white, VoidCallback? onTap}) {
    return ListTile(leading: Icon(icon, color: color), title: Text(title, style: TextStyle(color: color)), onTap: onTap);
  }

  Widget _buildAiAssistantContent(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.smart_toy_rounded, color: colorScheme.primary, size: 24),
            const SizedBox(width: 8),
            const Text(
              "Yatırım Asistanına Sor",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          "Oluşturulan risk profiliniz ve yatırımlar hakkında aklınıza takılanları AI asistanımıza sorun.",
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),

        // AI Response Panel
        if (_isLoadingAiResponse || _aiResponse.isNotEmpty || _aiError.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.primary.withOpacity(0.15)),
            ),
            child: _isLoadingAiResponse
                ? const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: kPrimaryColor),
                      ),
                      SizedBox(width: 12),
                      Text("Asistan yanıt hazırlıyor...", style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  )
                : _aiError.isNotEmpty
                    ? Text("Hata: $_aiError", style: TextStyle(color: colorScheme.error, fontSize: 13))
                    : Text(_aiResponse, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, height: 1.4)),
          ),
        ],

        const SizedBox(height: 16),

        // Input Area
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E222D),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: TextField(
            controller: _questionController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: "Sorunuzu yazın (örn: Kripto yatırımı uygun mu?)",
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: _isLoadingAiResponse
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: kPrimaryColor),
                      ),
                    )
                  : IconButton(
                      icon: Icon(Icons.send_rounded, color: colorScheme.primary, size: 18),
                      onPressed: _askAssistant,
                    ),
            ),
            onSubmitted: (_) => _askAssistant(),
          ),
        ),
      ],
    );
  }
}