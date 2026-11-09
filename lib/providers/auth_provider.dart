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
}