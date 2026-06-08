import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/question_model.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Future<List<Question>> getAllQuestions() async {
    try {
      // Tüm dokümanları 'sira' alanına göre çekiyoruz
      QuerySnapshot snapshot = await _db.collection('sorular').orderBy('sira').get();
      return snapshot.docs.map((doc) => Question.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      print("Veri çekme hatası: $e");
      return [];
    }
  }
}