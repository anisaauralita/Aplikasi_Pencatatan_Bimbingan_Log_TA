import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  static const _sessionKey = 'session_user_id';
  final _service = AuthService();

  UserModel? currentUser;
  bool isLoading = false;
  bool isInitialized = false;

  bool get isLoggedIn => currentUser != null;

  /// Dipanggil saat aplikasi mulai: pulihkan sesi bila ada.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_sessionKey);
    if (id != null) {
      currentUser = await _service.getUserById(id);
      if (currentUser == null) await prefs.remove(_sessionKey);
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

  /// Return true jika login berhasil.
  Future<bool> login(String email, String password) async {
    isLoading = true;
    notifyListeners();
    final user = await _service.login(email, password);
    if (user != null) {
      currentUser = user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_sessionKey, user.id!);
    }
    isLoading = false;
    notifyListeners();
    return user != null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    currentUser = null;
    notifyListeners();
  }
}