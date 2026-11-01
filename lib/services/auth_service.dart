import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';

class AuthService {
  final _dbHelper = DatabaseHelper.instance;

  String _generateSalt() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _hash(String password, String salt) {
    return sha256.convert(utf8.encode(salt + password)).toString();
  }

  /// Return null jika sukses, atau pesan error jika gagal.
  Future<String?> register({
    required String nama,
    required String nim,
    required String email,
    required String password,
  }) async {
    final db = await _dbHelper.database;
    final emailNorm = email.trim().toLowerCase();

    final existing = await db.query('users',
        where: 'email = ?', whereArgs: [emailNorm], limit: 1);
    if (existing.isNotEmpty) return 'Email sudah terdaftar';

    final salt = _generateSalt();
    final user = UserModel(
      nama: nama.trim(),
      nim: nim.trim(),
      email: emailNorm,
      passwordHash: _hash(password, salt),
      salt: salt,
      createdAt: DateTime.now().toIso8601String(),
    );
    await db.insert('users', user.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.abort);
    return null;
  }

  /// Return UserModel jika berhasil, null jika email/password salah.
  Future<UserModel?> login(String email, String password) async {
    final db = await _dbHelper.database;
    final rows = await db.query('users',
        where: 'email = ?',
        whereArgs: [email.trim().toLowerCase()],
        limit: 1);
    if (rows.isEmpty) return null;

    final user = UserModel.fromMap(rows.first);
    return _hash(password, user.salt) == user.passwordHash ? user : null;
  }

  Future<UserModel?> getUserById(int id) async {
    final db = await _dbHelper.database;
    final rows =
        await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : UserModel.fromMap(rows.first);
  }
}