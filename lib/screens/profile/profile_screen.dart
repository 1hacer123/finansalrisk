import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart'; // AuthService'i import etmeyi unutma!
import 'package:firebase_auth/firebase_auth.dart';

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

  bool _isLoggedIn = false;
  bool _isSignUpMode = false;
  String _selectedLevel = "Yeni";
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
    }
  }
  @override
  void dispose() {
    // Hafıza sızıntısını önlemek için kontrolleri kapatıyoruz
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
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
            // Analizler sayfasına yönlendirme buraya gelecek
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

  // (Diğer yardımcı widgetlar - _buildAuthIcon, _buildRiskSummaryCard, _buildMenuTile aynen kalabilir)
  Widget _buildAuthIcon() => const Icon(Icons.security, size: 60, color: kAccentColor);
  Widget _buildRiskSummaryCard() => Container(child: const Text("Risk Özeti", style: TextStyle(color: Colors.white)));
  Widget _buildMenuTile(IconData icon, String title, {Color color = Colors.white, VoidCallback? onTap}) {
    return ListTile(leading: Icon(icon, color: color), title: Text(title, style: TextStyle(color: color)), onTap: onTap);
  }
}