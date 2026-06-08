class Question {
  final String id; // Firebase ID'leri String olur
  final String text;
  final List<String> options;
  final String kategori;
  final String altKategori; // acemi, deneyimli, ortak
  final int sira; // Soruların sırası

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.kategori,
    required this.altKategori,
    required this.sira,
  });

  // Firebase'den gelen Map yapısını Question objesine çevirir
  factory Question.fromMap(String id, Map<String, dynamic> data) {
    // Hem 'secenekler' hem 'secenek' anahtarlarını kontrol ediyoruz
    var rawOptions = data['secenekler'] ?? data['secenek'] ?? [];

    return Question(
      id: id,
      text: data['soru_metni'] ?? 'Soru bulunamadı',
      options: List<String>.from(rawOptions),
      kategori: data['kategori'] ?? '',
      altKategori: data['alt_kategori'] ?? 'ortak',
      sira: int.tryParse(data['sira'].toString()) ?? 0,
    );
  }
}