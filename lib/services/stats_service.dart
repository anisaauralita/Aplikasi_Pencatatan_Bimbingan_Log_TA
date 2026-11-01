import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

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
  Future<DashboardStats> load(int userId) async {
    final db = await DatabaseHelper.instance.database;

    final chapters = await db.query('chapters',
        where: 'user_id = ?', whereArgs: [userId], orderBy: 'id');

    final revs = await db.rawQuery('''
      SELECT r.chapter_id AS cid, r.is_done AS done
      FROM revisions r JOIN chapters c ON c.id = r.chapter_id
      WHERE c.user_id = ?''', [userId]);

    final totalLog = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM guidance_logs WHERE user_id = ?',
            [userId])) ??
        0;

    int babSelesai = 0;
    final perBab = <ChapterProgress>[];
    for (final c in chapters) {
      final isDone = (c['is_done'] as int) == 1;
      if (isDone) babSelesai++;
      final mine = revs.where((r) => r['cid'] == c['id']).toList();
      final done = mine.where((r) => (r['done'] as int) == 1).length;
      final persen = isDone ? 1.0 : (mine.isEmpty ? 0.0 : done / mine.length);
      perBab.add(ChapterProgress(c['nomor'] as String, persen));
    }

    return DashboardStats(
      totalBab: chapters.length,
      babSelesai: babSelesai,
      totalRevisi: revs.length,
      revisiSelesai: revs.where((r) => (r['done'] as int) == 1).length,
      totalLog: totalLog,
      perBab: perBab,
    );
  }
}