import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _service = AuthService();

  UserModel? currentUser;
  bool isLoading = false;
  bool isInitialized = false;

  bool get isLoggedIn => currentUser != null;

  /// Dipanggil saat aplikasi mulai: pulihkan sesi bila ada.
  Future<void> init() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUser = await _service.getUserByUid(user.uid);
    }
    isInitialized = true;
    notifyListeners();
  }

  Future<String?> register(
      String nama, String nim, String email, String password) async {
    isLoading = true;
    notifyListeners();
    final error = await _service.register(
        nama: nama, nim: nim, email: email, password: password);
    isLoading = false;
    notifyListeners();
    return error;
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    notifyListeners();
    final ok = await _service.login(email, password);
    if (ok) {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      currentUser = await _service.getUserByUid(uid);
    }
    isLoading = false;
    notifyListeners();
    return ok && currentUser != null;
  }

  Future<void> logout() async {
    await _service.logout();
    currentUser = null;
    notifyListeners();
  }

  /// Menyimpan profil mahasiswa. Data di aplikasi langsung diperbarui, lalu
  /// ditulis ke dokumen users/{uid} di Firestore (field baru: prodi, angkatan,
  /// no_hp, foto_profil_path). Mengembalikan null jika berhasil, atau pesan error.
  /// [fotoPath] null berarti foto dihapus.
  Future<String?> updateProfil({
    required String nama,
    required String prodi,
    required String angkatan,
    required String noHp,
    required String? fotoPath,
  }) async {
    final u = currentUser;
    if (u == null) return 'Kamu belum login';

    // Perbarui data di aplikasi dulu supaya Beranda ikut berubah
    currentUser = UserModel(
      id: u.id,
      nama: nama,
      nim: u.nim,
      email: u.email,
      prodi: prodi,
      angkatan: angkatan,
      noHp: noHp,
      fotoPath: fotoPath,
    );
    notifyListeners();

    try {
      await FirebaseFirestore.instance.collection('users').doc(u.id).set({
        'nama': nama,
        'prodi': prodi,
        'angkatan': angkatan,
        'no_hp': noHp,
        'foto_profil_path':
            fotoPath == null ? FieldValue.delete() : fotoPath,
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 6));
    } on TimeoutException {
      // Tidak ada koneksi: Firestore menyimpan di antrean HP dan mengirimnya nanti
    } catch (e) {
      return 'Gagal menyimpan profil: $e';
    }
    return null;
  }
}