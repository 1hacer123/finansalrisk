import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- GİRİŞ YAPMA FONKSİYONU ---
  Future<String?> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return "success";
    } on FirebaseAuthException catch (e) {
      return e.message; // Hata mesajını döner (şifre yanlış vb.)
    } catch (e) {
      return e.toString();
    }
  }
  // --- ÇIKIŞ YAPMA FONKSİYONU ---
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print("Kullanıcı güvenli bir şekilde çıkış yaptı.");
    } catch (e) {
      print("Çıkış yapılırken hata oluştu: $e");
    }
  }
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        return doc.data() as Map<String, dynamic>?;
      }
    } catch (e) {
      print("Veri çekme hatası: $e");
    }
    return null;
  }
  // KAYIT OL VE VERİTABANINA YAZ
  Future<String?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String experience,
  }) async {
    try {
      // 1. Firebase Auth ile hesabı oluştur
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Kullanıcı ID'sini al ve Firestore'da "users" koleksiyonu oluştur
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'fullName': fullName,
        'email': email,
        'experience': experience,
        'riskScore': 0, // Henüz test çözmediği için 0
        'createdAt': DateTime.now(),
      });

      return "success";
    } catch (e) {
      return e.toString();
    }
  }
}