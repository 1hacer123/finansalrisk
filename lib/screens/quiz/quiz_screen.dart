import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/question_model.dart';
import '../../services/firebase_service.dart';
import 'question_widget.dart';
import '../../widgets/navigation_button.dart';
import '../results/result_screen.dart';
import '../../models/risk_profile_model.dart';

class QuizScreen extends StatefulWidget {
  final bool isBeginner;
  const QuizScreen({super.key, required this.isBeginner});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  // DEĞİŞİKLİKLER BURADA BAŞLIYOR
  List<Question> _allQuestionsFromDb = []; // Firebase'den gelen ham liste
  List<Question> _visibleQuestions = [];   // Filtrelenmiş, ekranda görünen liste
  bool _isLoading = true;
  int _currentQuestionIndex = 0;
  final Map<String, int> _userAnswers = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // Verileri ilk kez çekme
  Future<void> _loadInitialData() async {
    try {
      // FirebaseService içinde getAllQuestions metodu olduğunu varsayıyoruz
      final results = await _firebaseService.getAllQuestions();
      setState(() {
        _allQuestionsFromDb = results;
        // İlk etapta sadece Kişisel (sira <= 11) soruları gösteriyoruz
        _visibleQuestions = _allQuestionsFromDb.where((q) => q.sira <= 11).toList();
        _visibleQuestions.sort((a, b) => a.sira.compareTo(b.sira));
        _isLoading = false;
      });
    } catch (e) {
      print("Yükleme hatası: $e");
    }
  }

  void _answerQuestion(String questionId, int selectedOptionIndex) {
    setState(() {
      _userAnswers[questionId] = selectedOptionIndex;

      final currentQuestion = _visibleQuestions[_currentQuestionIndex];

      // KRİTİK NOKTA: 11. soru cevaplandığında yolu ayır
      if (currentQuestion.sira == 11) {
        // Senin mantığın: 0-2 yıl seçeneği (index 0 ve 1) ACEMİ, 3+ yıl (index 2) DENEYİMLİ
        bool userIsAcemi = (selectedOptionIndex == 0 || selectedOptionIndex == 1);
        _updateQuestionFlow(userIsAcemi);
      }
    });
  }

  void _updateQuestionFlow(bool isAcemi) {
    // 1. Önce ilk 11 soruyu tut
    List<Question> newFlow = _allQuestionsFromDb.where((q) => q.sira <= 11).toList();

    // 2. Risk kategorisindeki uygun soruları ekle (Acemi/Deneyimli + Ortak)
    var riskQuestions = _allQuestionsFromDb.where((q) => q.kategori == "Risk").where((q) {
      if (isAcemi) {
        return q.altKategori == "acemi" || q.altKategori == "ortak";
      } else {
        return q.altKategori == "deneyimli" || q.altKategori == "ortak";
      }
    }).toList();
    newFlow.addAll(riskQuestions);

    // 3. En son Keşfet kategorisini ekle
    var kesfetQuestions = _allQuestionsFromDb.where((q) => q.kategori == "Keşfet").toList();
    newFlow.addAll(kesfetQuestions);

    // Sıralamayı garantiye al
    newFlow.sort((a, b) => a.sira.compareTo(b.sira));

    setState(() {
      _visibleQuestions = newFlow;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. YÜKLENME EKRANI (Boş görünmemesi için gradyanı buraya da ekliyoruz)
    if (_isLoading) {
      return Scaffold(
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
          child: Stack( // Stack kullanarak iç içe havalı bir görüntü yapıyoruz
            children: [
              // Arka planda çok hafif, belli belirsiz parlayan bir logo
              Center(
                child: Opacity(
                  opacity: 0.05,
                  child: Icon(Icons.currency_bitcoin, size: 300, color: kPrimaryColor),
                ),
              ),
              // Tam ortada sadece şık bir animasyon
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Standart çark yerine daha modern bir halka
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, // İnce çizgi daha asil durur
                        valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor.withOpacity(0.5)),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Yazıyı tamamen sildik veya çok daha "cool" bir hale getirdik
                    Text(
                      "RISK PROFILE ANALYSIS",
                      style: TextStyle(
                        color: Colors.white, // Tam beyaz yaparak netliği artırdık
                        fontSize: 14, // Biraz büyüttük
                        letterSpacing: 1.5, // Aralığı çok açmadık, daha derli toplu durur
                        fontWeight: FontWeight.w800, // Yazıyı iyice kalınlaştırdık (Extra Bold)
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: kPrimaryColor.withOpacity(0.5), // Yazının altına hafif bir neon parlama
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: 120,
                      child: LinearProgressIndicator(
                        minHeight: 1, // Çok ince, iplik gibi
                        backgroundColor: Colors.white.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    // 2. SORU BULUNAMADI DURUMU
    if (_visibleQuestions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Text(
            "Şu an soru bulunamadı, lütfen internetinizi kontrol edin.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
        ),
      );
    }

    // 3. ASIL TEST EKRANI (Buradan sonrası senin mevcut kodun)
    final currentQuestion = _visibleQuestions[_currentQuestionIndex];
    final totalQuestions = _visibleQuestions.length;
    final bool isAnswered = _userAnswers.containsKey(currentQuestion.id);

    return Scaffold(
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
          child: Column(
            children: [
              _buildTopProgress(_currentQuestionIndex, totalQuestions),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  child: QuestionWidget(
                    question: currentQuestion,
                    selectedOptionIndex: _userAnswers[currentQuestion.id],
                    onOptionSelected: (index) => _answerQuestion(currentQuestion.id, index),
                  ),
                ),
              ),
              _buildNavigationButtons(isAnswered, totalQuestions, _visibleQuestions),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildTopProgress(int index, int total) {
    //ilerleme oranı
    double progress=(index+1)/total;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20,vertical:15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight:8,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Soru ${index+1}/ $total',
            style: const TextStyle(
              color:Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14
            )
          ),

         ],
      ),
    );
  }

  Widget _buildNavigationButtons(bool isAnswered, int total, List<Question> questions) {
    final bool isLast = _currentQuestionIndex == total - 1;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          if (_currentQuestionIndex > 0)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: NavigationButton(
                  text: "Önceki",
                  type: ButtonType.Secondary,
                  onPressed: () => setState(() => _currentQuestionIndex--),
                ),
              ),
            ),
          Expanded(
            child: NavigationButton(
              text: isLast ? "Sonuçları Gör" : "Sonraki",
              onPressed: isAnswered
                  ? () {
                if (isLast) {
                  // Sonuç ekranına git (Risk puanı hesaplamasını sonra ekleyeceğiz)
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ResultScreen(profile: mockResult)));
                } else {
                  setState(() => _currentQuestionIndex++);
                }
              }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}