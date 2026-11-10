import 'package:cloud_firestore/cloud_firestore.dart';
import 'fs_helper.dart';

class ChapterProgress {
  final String nomor;
  final double persen; // 0.0 - 1.0
  ChapterProgress(this.nomor, this.persen);
}

class DashboardStats {
  final int totalBab;
  final int babSelesai;
  final int totalRevisi;
  final int revisiSelesai;
  final int totalLog;
  final List<ChapterProgress> perBab;

  DashboardStats({
    required this.totalBab,
    required this.babSelesai,
    required this.totalRevisi,
    required this.revisiSelesai,
    required this.totalLog,
    required this.perBab,
  });

  /// Rumus proposal: bab selesai / total bab x 100
  double get progresTotal => totalBab == 0 ? 0 : babSelesai / totalBab;
}

class StatsService {
  final _db = FirebaseFirestore.instance;

  Future<DashboardStats> load(String uid) async {
    final base = _db.collection('users').doc(uid);

    // Tiga bacaan jalan bersamaan, cache HP dulu baru server
    final hasil = await Future.wait([
      ambilCepat(base.collection('chapters')),
      ambilCepat(base.collection('revisions')),
      ambilCepat(base.collection('logs')),
    ]);
    final chapters = hasil[0];
    final revs = hasil[1];
    final logs = hasil[2];

    int babSelesai = 0;
    final perBab = <ChapterProgress>[];

    for (final c in chapters.docs) {
      final data = c.data();
      final isDone = data['is_done'] == true;
      if (isDone) babSelesai++;

      final mine =
          revs.docs.where((r) => r.data()['chapter_id'] == c.id).toList();
      final done = mine.where((r) => r.data()['is_done'] == true).length;
      final persen = isDone ? 1.0 : (mine.isEmpty ? 0.0 : done / mine.length);

      perBab.add(ChapterProgress((data['nomor'] ?? '').toString(), persen));
    }

    return DashboardStats(
      totalBab: chapters.docs.length,
      babSelesai: babSelesai,
      totalRevisi: revs.docs.length,
      revisiSelesai:
          revs.docs.where((r) => r.data()['is_done'] == true).length,
      totalLog: logs.docs.length,
      perBab: perBab,
    );
  }
}