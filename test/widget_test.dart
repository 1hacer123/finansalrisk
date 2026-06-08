import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Projenizin doğru ismini ('finansal_yatirim') kullanarak main.dart dosyasını import edin.
import 'package:finansa_yatirim/main.dart';

void main() {
  testWidgets('Uygulama CryptoRiskApp olarak başlar ve Giriş Ekranını gösterir', (WidgetTester tester) async {
    // 1. Uygulamayı başlat ve ilk frame'i tetikle
    await tester.pumpWidget(const CryptoRiskApp()); // CryptoRiskApp sınıfını kullanıyoruz

    // 2. Uygulamanın başarıyla yüklendiğini kontrol et
    // IntroductionScreen'deki temel metinlerden biri olan 'CryptoRisk' başlığını arayalım.
    expect(find.text('CryptoRisk'), findsOneWidget, reason: 'Uygulama başarıyla başlamalı ve başlığı göstermeli.');

    // 3. 'Teste Başla' butonunun ekranda olduğunu kontrol et
    expect(find.text('Teste Başla'), findsOneWidget, reason: 'Giriş ekranında Teste Başla butonu bulunmalı.');

    // 4. Teste Başla butonuna dokunmayı simüle et
    await tester.tap(find.text('Teste Başla'));
    await tester.pumpAndSettle(); // Navigasyonun tamamlanmasını bekle

    // 5. Artık Anket Ekranında (QuizScreen) olduğumuzu kontrol et
    // Anket ekranındaki ilk mock soruyu arayalım
    expect(find.text('Finansal okuryazarlık seviyenizi nasıl değerlendirirsiniz?'), findsOneWidget, reason: 'Teste Başla butonuna basıldıktan sonra Anket Ekranına geçilmeli.');
  });
}