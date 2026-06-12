import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants.dart';
import '../../models/risk_result.dart';
import '../results/result_screen.dart';

class PastAnalysesScreen extends StatefulWidget {
  const PastAnalysesScreen({super.key});

  @override
  State<PastAnalysesScreen> createState() => _PastAnalysesScreenState();
}

class _PastAnalysesScreenState extends State<PastAnalysesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _analyses = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadAnalyses();
  }

  Future<void> _loadAnalyses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = "Lütfen önce giriş yapın.";
          _isLoading = false;
        });
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('risk_profiles')
          .doc(user.uid)
          .collection('history')
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> list = [];
      for (var doc in snapshot.docs) {
        var data = doc.data();
        data['id'] = doc.id;
        list.add(data);
      }

      // Fallback Migration: Geçmiş boşsa ama aktif profil varsa geçmişe kopyala
      if (list.isEmpty) {
        final mainDoc = await FirebaseFirestore.instance
            .collection('risk_profiles')
            .doc(user.uid)
            .get();

        if (mainDoc.exists) {
          final mainData = mainDoc.data();
          if (mainData != null) {
            // Eğer createdAt alanı yoksa şimdiki zamanı ata
            if (!mainData.containsKey('createdAt')) {
              mainData['createdAt'] = Timestamp.now();
            }

            // Alt koleksiyona kaydet
            await FirebaseFirestore.instance
                .collection('risk_profiles')
                .doc(user.uid)
                .collection('history')
                .add(mainData);

            mainData['id'] = 'migrated_main';
            list.add(mainData);
          }
        }
      }

      setState(() {
        _analyses = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Veriler yüklenirken bir hata oluştu: $e";
        _isLoading = false;
      });
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "-";
    final date = timestamp.toDate();
    final months = [
      "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
      "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"
    ];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return "$day $month $year, $hour:$minute";
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "GEÇMİŞ ANALİZLERİM",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
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
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: colorScheme.primary,
                ),
              )
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _loadAnalyses,
                            child: const Text("Tekrar Dene"),
                          )
                        ],
                      ),
                    ),
                  )
                : _analyses.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.analytics_outlined, color: colorScheme.primary.withOpacity(0.5), size: 80),
                              const SizedBox(height: 20),
                              const Text(
                                "Henüz Analiz Bulunmuyor",
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Yatırım risk analizinizi yapmak için ana sayfadan teste başlayabilirsiniz.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: colorScheme.primary,
                        backgroundColor: const Color(0xFF1E222D),
                        onRefresh: _loadAnalyses,
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          itemCount: _analyses.length,
                          itemBuilder: (context, index) {
                            final analysis = _analyses[index];
                            final result = RiskResult.fromJson(analysis);
                            final timestamp = analysis['createdAt'] as Timestamp?;
                            
                            final bool isHighRisk = result.risk == 1 || result.label.toLowerCase().contains('yüksek');
                            final Color riskColor = isHighRisk ? kChartRed : kChartGreen;
                            final IconData riskIcon = isHighRisk ? Icons.warning_amber_rounded : Icons.shield_rounded;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E222D),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.04),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ResultScreen(profile: result),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        children: [
                                          // Sol Kısım: İkon
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: riskColor.withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(riskIcon, color: riskColor, size: 24),
                                          ),
                                          const SizedBox(width: 16),
                                          // Orta Kısım: Detaylar
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  result.label.toUpperCase(),
                                                  style: TextStyle(
                                                    color: riskColor,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _formatDate(timestamp),
                                                  style: const TextStyle(
                                                    color: Colors.white38,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Sağ Kısım: Segment & Skor
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.amberAccent.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  result.segment.toUpperCase(),
                                                  style: const TextStyle(
                                                    color: Colors.amberAccent,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                "%${result.scorePercent.toStringAsFixed(1)}",
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            color: Colors.white24,
                                            size: 14,
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}
