import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/fs_helper.dart';
import 'detail_log_screen.dart';
import 'log_model.dart';
import 'revisi_model.dart';
import 'tambah_log_screen.dart';
import 'tambah_revisi_screen.dart';

class LogBimbinganScreen extends StatefulWidget {
  const LogBimbinganScreen({super.key});

  @override
  State<LogBimbinganScreen> createState() => _LogBimbinganScreenState();
}

class _LogBimbinganScreenState extends State<LogBimbinganScreen> {
  static const _primary = Color(0xFF4338CA);

  late final String _uid;
  CollectionReference<Map<String, dynamic>> get _logs => FirebaseFirestore
      .instance
      .collection('users')
      .doc(_uid)
      .collection('logs');

  // BARU: dokumen induk user (untuk akses chapters dan revisions)
  DocumentReference<Map<String, dynamic>> get _base =>
      FirebaseFirestore.instance.collection('users').doc(_uid);

  final List<LogBimbingan> daftarLog = [];
  List<String> _ids = []; // id dokumen Firestore, urutan sama dengan daftarLog
  bool _loading = true;
  String? _error;

  // BARU: jumlah revisi per log (kunci = id dokumen log)
  final Map<String, int> _totalRevisi = {};
  final Map<String, int> _revisiSelesai = {};
  // BARU: daftar revisi lengkap per log (untuk halaman detail log)
  final Map<String, List<RevisiItem>> _revisiPerLog = {};

  @override
  void initState() {
    super.initState();
    _uid = context.read<AuthProvider>().currentUser!.id;
    _muat();
  }

  // ---------- Firestore ----------
  // BARU: hitung revisi yang tertaut ke tiap log (kalau gagal, ringkasan saja yang kosong)
  Future<void> _muatRingkasanRevisi() async {
    try {
      final snap = await ambilCepat(_base.collection('revisions'));
      final total = <String, int>{};
      final selesai = <String, int>{};
      final perLog = <String, List<RevisiItem>>{};
      for (final d in snap.docs) {
        final x = d.data();
        final lid = x['log_id'];
        if (lid is! String || lid.isEmpty) continue;
        total[lid] = (total[lid] ?? 0) + 1;
        if (x['is_done'] == true) selesai[lid] = (selesai[lid] ?? 0) + 1;
        // BARU: simpan data revisi lengkap untuk halaman detail log
        final foto = x['foto_path'] as String?;
        perLog.putIfAbsent(lid, () => []).add(RevisiItem(
              d.id,
              Revisi(
                poin: (x['poin'] ?? '').toString(),
                bab: (x['bab'] ?? '').toString(),
                selesai: x['is_done'] == true,
                fotoPath: (foto == null || foto.isEmpty) ? null : foto,
                logId: lid,
              ),
            ));
      }
      _totalRevisi
        ..clear()
        ..addAll(total);
      _revisiSelesai
        ..clear()
        ..addAll(selesai);
      _revisiPerLog
        ..clear()
        ..addAll(perLog);
    } catch (_) {}
  }

  Future<void> _muat() async {
    try {
      final snap =
          await ambilCepat(_logs.orderBy('tanggal', descending: true));
      await _muatRingkasanRevisi();
      if (!mounted) return;
      setState(() {
        _ids = snap.docs.map((d) => d.id).toList();
        daftarLog
          ..clear()
          ..addAll(snap.docs.map((d) {
            final x = d.data();
            final t = x['tanggal'];
            final tanggal = t is Timestamp ? t.toDate() : DateTime.now();
            return LogBimbingan(tanggal, (x['catatan'] ?? '').toString());
          }));
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _pesan(String teks) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  // Jalankan penulisan tanpa menunggu server (tersimpan di HP dulu)
  Future<void> _bg(Future<dynamic> f, String pesan) async {
    try {
      await f;
    } catch (e) {
      _pesan('$pesan: $e');
    }
  }

  Future<void> _tambahLog() async {
    final hasil = await Navigator.push<LogBimbingan>(
      context,
      MaterialPageRoute(builder: (_) => const TambahLogScreen()),
    );
    if (hasil == null || !mounted) return;
    _bg(
      _logs.add({
        'tanggal': Timestamp.fromDate(hasil.tanggal),
        'catatan': hasil.catatan,
        'created_at': FieldValue.serverTimestamp(),
      }),
      'Gagal menyimpan log',
    );
    await _muat();
  }

  Future<void> _editLog(int index) async {
    final lama = daftarLog[index];
    final hasil = await Navigator.push<LogBimbingan>(
      context,
      MaterialPageRoute(
        builder: (_) => TambahLogScreen(
          isEdit: true,
          tanggalAwal: lama.tanggal,
          catatanAwal: lama.catatan,
        ),
      ),
    );
    if (hasil == null || !mounted) return;
    _bg(
      _logs.doc(_ids[index]).update({
        'tanggal': Timestamp.fromDate(hasil.tanggal),
        'catatan': hasil.catatan,
      }),
      'Gagal mengubah log',
    );
    await _muat();
  }

  // BARU: tambah revisi langsung dari kartu log (log ini otomatis terpilih)
  Future<void> _tambahRevisiDariLog(int index) async {
    final chapters = await ambilCepat(_base.collection('chapters'));
    if (!mounted) return;

    // Daftar nama bab, format "Bab 1 - Pendahuluan", diurutkan menurut nomor
    final namaBab = chapters.docs.map((c) {
      final d = c.data();
      return '${d['nomor']} - ${d['judul']}';
    }).toList();
    int nomor(String s) {
      final m = RegExp(r'Bab\s*(\d+)').firstMatch(s);
      return m == null ? 0 : int.parse(m.group(1)!);
    }

    namaBab.sort((a, b) => nomor(a).compareTo(nomor(b)));

    if (namaBab.isEmpty) {
      _pesan('Tambahkan bab dulu di tab Bab, baru bisa menambah revisi.');
      return;
    }

    final logId = _ids[index];
    final hasil = await Navigator.push<Revisi>(
      context,
      MaterialPageRoute(
        builder: (_) => TambahRevisiScreen(
          opsiBab: namaBab,
          opsiLog: [
            OpsiLog(id: logId, label: formatTanggal(daftarLog[index].tanggal)),
          ],
          logIdAwal: logId,
        ),
      ),
    );
    if (hasil == null || !mounted) return;

    // Cari id bab yang cocok dengan nama bab terpilih
    String? chapterId;
    for (final c in chapters.docs) {
      final d = c.data();
      if ('${d['nomor']} - ${d['judul']}' == hasil.bab) {
        chapterId = c.id;
        break;
      }
    }

    _bg(
      _base.collection('revisions').add({
        'poin': hasil.poin,
        'bab': hasil.bab,
        'chapter_id': chapterId,
        'log_id': hasil.logId,
        'is_done': hasil.selesai,
        'foto_path': hasil.fotoPath,
        'created_at': FieldValue.serverTimestamp(),
      }),
      'Gagal menyimpan revisi',
    );
    await _muat();
  }

  // BARU: buka halaman detail log (catatan lengkap + daftar revisinya)
  void _bukaDetailLog(int index) {
    final id = _ids[index];
    final log = daftarLog[index];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailLogScreen(
          tanggal: log.tanggal,
          catatan: log.catatan,
          // Memuat ulang revisi milik log ini setiap dibutuhkan
          muatRevisi: () async {
            await _muatRingkasanRevisi();
            return List<RevisiItem>.of(_revisiPerLog[id] ?? const []);
          },
          // Tambah revisi dari log ini (memakai form yang sama dengan tombol + Revisi)
          onTambahRevisi: () => _tambahRevisiDariLog(index),
          // Simpan perubahan status / foto revisi ke Firestore
          onUbahRevisi: (revId, baru) {
            _bg(
              _base.collection('revisions').doc(revId).update({
                'is_done': baru.selesai,
                'foto_path': baru.fotoPath,
              }),
              'Gagal menyimpan perubahan',
            );
          },
        ),
      ),
    ).then((_) {
      // Setelah kembali dari halaman detail, segarkan ringkasan di kartu
      if (mounted) _muat();
    });
  }

  void _hapusLog(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus log?'),
        content: Text(
            'Log bimbingan ${formatTanggal(daftarLog[index].tanggal)} akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              _bg(_logs.doc(_ids[index]).delete(), 'Gagal menghapus');
              await _muat();
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tambahLog,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Log',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4338CA), Color(0xFF5B52E0), Color(0xFFB8B4F5)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          // Di layar lebar, konten dibatasi 640 px dan dipusatkan
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: RefreshIndicator(
                onRefresh: _muat,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                  children: [
                    const Text('Log Bimbingan',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: Colors.white)),
                      )
                    else if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Text('Gagal memuat data:\n$_error',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white)),
                      )
                    else if (daftarLog.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Center(
                          child: Text('Belum ada log bimbingan.',
                              style: TextStyle(color: Colors.white70)),
                        ),
                      )
                    else
                      ...List.generate(daftarLog.length, (i) => _kartuLog(i)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _kartuLog(int i) {
    final log = daftarLog[i];
    // Ringkasan revisi yang tertaut ke log ini
    final total = _totalRevisi[_ids[i]] ?? 0;
    final selesai = _revisiSelesai[_ids[i]] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      // BARU: kartu bisa diketuk -> membuka halaman detail log
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _bukaDetailLog(i),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 15, color: _primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(formatTanggal(log.tanggal),
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800)),
                    ),
                    Text('Lihat detail',
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600)),
                    Icon(Icons.chevron_right,
                        size: 18, color: Colors.grey.shade600),
                  ],
                ),
                const SizedBox(height: 8),
                // Di daftar hanya cuplikan 3 baris; teks lengkap ada di halaman detail
                Text(log.catatan,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: Colors.grey.shade800)),
                const SizedBox(height: 10),
                // Ringkasan revisi dari bimbingan ini
                Row(
                  children: [
                    Icon(Icons.assignment_outlined,
                        size: 14,
                        color: total > 0 ? _primary : Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Text(
                      total == 0
                          ? 'Belum ada revisi dari bimbingan ini'
                          : '$total revisi, $selesai selesai',
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color:
                              total > 0 ? _primary : Colors.grey.shade500),
                    ),
                  ],
                ),
                // BARU: bar progres revisi (hanya jika ada revisi)
                if (total > 0) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: selesai / total,
                      minHeight: 5,
                      backgroundColor: const Color(0xFFE5E7F5),
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Tombol tambah revisi dari bimbingan ini
                    _aksiKecil(Icons.add, 'Revisi', _primary,
                        const Color(0xFFEEF0FF), const Color(0xFFD5D8FA),
                        () => _tambahRevisiDariLog(i)),
                    const SizedBox(width: 8),
                    _aksiKecil(Icons.edit_outlined, 'Edit',
                        Colors.grey.shade700, Colors.white,
                        Colors.grey.shade300, () => _editLog(i)),
                    const SizedBox(width: 8),
                    _aksiKecil(Icons.delete_outline, 'Hapus', Colors.red,
                        const Color(0xFFFDECEC), const Color(0xFFF8C9C9),
                        () => _hapusLog(i)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _aksiKecil(IconData icon, String label, Color fg, Color bg,
      Color border, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
          ],
        ),
      ),
    );
  }
}