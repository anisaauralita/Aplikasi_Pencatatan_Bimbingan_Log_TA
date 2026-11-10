import 'package:cloud_firestore/cloud_firestore.dart';

/// Baca cache HP dulu (instan). Kalau kosong, baru tanya server (maks 6 detik).
Future<QuerySnapshot<Map<String, dynamic>>> ambilCepat(
    Query<Map<String, dynamic>> q) async {
  try {
    final c = await q.get(const GetOptions(source: Source.cache));
    if (c.docs.isNotEmpty) return c;
  } catch (_) {}
  try {
    return await q.get().timeout(const Duration(seconds: 6));
  } catch (_) {
    return q.get(const GetOptions(source: Source.cache));
  }
}