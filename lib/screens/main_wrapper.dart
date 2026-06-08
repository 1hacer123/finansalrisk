import 'package:finansa_yatirim/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import '../../core/constants.dart'; // Renkler için
import 'discover/discover_screen.dart';
import 'introduction/introduction_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const IntroductionScreen(),
    const DiscoverScreen(),
    const ProfileScreen(), // Buradaki Text kısmını silip bunu yazdık
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Bu satır, sayfanın Navbar'ın arkasına kadar uzanmasını sağlar (Beyazlığı çözer)
      extendBody: true,
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        // Navbar'ın etrafına hafif bir gölge ve transparanlık ekliyoruz
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              const Color(0xFF0F172A).withOpacity(0.8), // Arka planla uyumlu koyu geçiş
            ],
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          // TASARIM AYARLARI
          backgroundColor: Colors.transparent, // Arka planı transparan yaptık
          elevation: 0,
          selectedItemColor: kPrimaryColor, // Senin neon rengin
          unselectedItemColor: Colors.white24,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Ana Sayfa'),
            BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: 'Keşfet'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}