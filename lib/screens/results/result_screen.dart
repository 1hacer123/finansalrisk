import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/risk_result.dart';
import '../../models/portfolio_advice.dart';
import '../../services/portfolio_service.dart';
import '../../core/constants.dart';
import '../main_wrapper.dart';

class ResultScreen extends StatefulWidget {
  final RiskResult profile;

  const ResultScreen({
    super.key,
    required this.profile,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final PortfolioService _portfolioService = PortfolioService();
  final TextEditingController _questionController = TextEditingController();

  PortfolioAdviceResponse? _advice;
  bool _isLoadingAdvice = true;
  String _adviceError = '';

  bool _isLoadingAiResponse = false;
  String _aiResponse = '';
  String _aiError = '';

  @override
  void initState() {
    super.initState();
    _fetchPortfolioAdvice();
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _fetchPortfolioAdvice() async {
    setState(() {
      _isLoadingAdvice = true;
      _adviceError = '';
    });
    try {
      final score = widget.profile.scorePercent / 100;
      final response = await _portfolioService.getPortfolioAdvice(
        riskScore: score,
        segment: widget.profile.segment,
        label: widget.profile.label,
        horizonYears: 5, // Varsayılan vade yılı
        goal: "dengeli büyüme", // Varsayılan yatırım hedefi
      );
      setState(() {
        _advice = response;
        _isLoadingAdvice = false;
      });
    } catch (e) {
      setState(() {
        _adviceError = e.toString().replaceFirst("Exception: ", "");
        _isLoadingAdvice = false;
      });
    }
  }

  Future<void> _askAssistant() async {
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
        riskLabel: widget.profile.label,
        segment: widget.profile.segment,
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isHighRisk = widget.profile.risk == 1 || widget.profile.label.toLowerCase().contains('yüksek');
    final Color riskColor = isHighRisk ? kChartRed : kChartGreen;
    final IconData riskIcon = isHighRisk ? Icons.warning_amber_rounded : Icons.shield_rounded;

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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => const MainWrapper()),
                          );
                        }
                      },
                    ),
                    const Text(
                      "ANALİZ SONUCU",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 24),

                // Main Circular Gauge
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: riskColor.withOpacity(0.1),
                    border: Border.all(color: riskColor.withOpacity(0.3), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: riskColor.withOpacity(0.15),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    riskIcon,
                    size: 64,
                    color: riskColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Risk Label
                Text(
                  widget.profile.label.toUpperCase(),
                  style: TextStyle(
                    color: riskColor,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isHighRisk ? "Yüksek Risk Toleransı" : "Düşük Risk Toleransı",
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),

                // Basic Results Info Card
                Card(
                  color: colorScheme.surfaceVariant.withOpacity(0.1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildInfoColumn("Risk Değeri", widget.profile.risk.toString(), colorScheme.primary),
                        Container(width: 1, height: 40, color: Colors.white10),
                        _buildInfoColumn("Segment", widget.profile.segment.toUpperCase(), Colors.amberAccent),
                        Container(width: 1, height: 40, color: Colors.white10),
                        _buildInfoColumn("Skor", "%${widget.profile.scorePercent.toStringAsFixed(1)}", riskColor),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Pasta Grafiği & Öneri Bölümü
                Card(
                  color: colorScheme.surfaceVariant.withOpacity(0.15),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: colorScheme.outline.withOpacity(0.15)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: _buildPortfolioSectionContent(),
                  ),
                ),
                const SizedBox(height: 24),

                // AI Asistan Kartı (Bottom Panel)
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
                const SizedBox(height: 32),

                // Return Home Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const MainWrapper()),
                        );
                      }
                    },
                    child: const Text(
                      "Ana Sayfaya Dön",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildPortfolioSectionContent() {
    if (_isLoadingAdvice) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.0),
          child: Column(
            children: [
              CircularProgressIndicator(color: kPrimaryColor),
              SizedBox(height: 16),
              Text(
                "Yapay Zeka Portföy Önerisi Üretiliyor...",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (_adviceError.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
              const SizedBox(height: 12),
              Text(
                "Hata: $_adviceError",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                icon: const Icon(Icons.refresh_rounded, color: kPrimaryColor),
                label: const Text("Tekrar Dene", style: TextStyle(color: kPrimaryColor)),
                onPressed: _fetchPortfolioAdvice,
              ),
            ],
          ),
        ),
      );
    }

    final allocations = _advice?.allocations ?? [];
    if (allocations.isEmpty) {
      return const Center(
        child: Text("Portföy tahsisi bulunamadı.", style: TextStyle(color: Colors.white70)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.pie_chart_outline_rounded, color: kPrimaryColor, size: 22),
            SizedBox(width: 8),
            Text(
              "Önerilen Varlık Dağılımı",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildPieChart(allocations),
        const SizedBox(height: 20),
        const Divider(color: Colors.white10),
        const SizedBox(height: 12),
        const Text(
          "Yapay Zeka Analiz Gerekçesi",
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _advice?.reasoning ?? '',
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildPieChart(List<AllocationItem> allocations) {
    final List<Color> colors = [
      Colors.tealAccent.shade400,
      Colors.amberAccent.shade400,
      Colors.blueAccent.shade400,
      Colors.redAccent.shade400,
      Colors.purpleAccent.shade400,
      Colors.orangeAccent.shade400,
    ];

    final sections = allocations.asMap().entries.map((entry) {
      final i = entry.key;
      final item = entry.value;
      final color = colors[i % colors.length];
      return PieChartSectionData(
        color: color,
        value: item.pct,
        title: '%${item.pct.toStringAsFixed(0)}',
        radius: 40,
        titleStyle:TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.black.withOpacity(0.8),
        ),
      );
    }).toList();

    return SizedBox(
      height: 140,
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 30,
                sections: sections,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: allocations.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  final color = colors[i % colors.length];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "${item.name} (%${item.pct.toStringAsFixed(0)})",
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
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