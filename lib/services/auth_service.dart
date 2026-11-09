import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  /// Return null jika sukses, atau pesan error.
  Future<String?> register({
    required String nama,
    required String nim,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      await _db.collection('users').doc(cred.user!.uid).set({
        'nama': nama.trim(),
        'nim': nim.trim(),
        'email': email.trim().toLowerCase(),
        'created_at': FieldValue.serverTimestamp(),
      });
      await _auth.signOut(); // kembali ke Login sesuai flowchart
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') return 'Email sudah terdaftar';
      if (e.code == 'weak-password') return 'Kata sandi terlalu lemah';
      return e.message ?? 'Pendaftaran gagal';
    } catch (e) {
      return 'Pendaftaran gagal: $e';
    }
  }

  /// Return true jika login berhasil.
  Future<bool> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      return true;
    } on FirebaseAuthException {
      return false;
    }
  }

  Future<UserModel?> getUserByUid(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(uid, doc.data()!);
  }

  Future<void> logout() => _auth.signOut();
}