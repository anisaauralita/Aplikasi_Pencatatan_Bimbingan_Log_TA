import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/fs_helper.dart';
import 'detail_revisi_screen.dart';
import 'revisi_model.dart';
import 'tambah_revisi_screen.dart';

class DaftarRevisiScreen extends StatefulWidget {
  const DaftarRevisiScreen({super.key});

  @override
  State<DaftarRevisiScreen> createState() => _DaftarRevisiScreenState();
}

class _DaftarRevisiScreenState extends State<DaftarRevisiScreen> {
  static const _primary = Color(0xFF4338CA);

  late final String _uid;
  DocumentReference<Map<String, dynamic>> get _base =>
      FirebaseFirestore.instance.collection('users').doc(_uid);

  String _filter = 'Semua'; // 'Semua' | 'Belum' | 'Selesai'

  final List<Revisi> daftarRevisi = [];
  List<String> _ids = []; // id dokumen Firestore, urutan sama dengan daftarRevisi
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _uid = context.read<AuthProvider>().currentUser!.id;
    _muat();
  }

  // ---------- Firestore ----------
  Future<void> _muat() async {
    try {
      final snap = await ambilCepat(
          _base.collection('revisions').orderBy('created_at', descending: true));
      if (!mounted) return;
      setState(() {
        _ids = snap.docs.map((d) => d.id).toList();
        daftarRevisi
          ..clear()
          ..addAll(snap.docs.map((d) {
            final x = d.data();
            final foto = x['foto_path'] as String?;
            return Revisi(
              poin: (x['poin'] ?? '').toString(),
              bab: (x['bab'] ?? '').toString(),
              selesai: x['is_done'] == true,
              fotoPath: (foto == null || foto.isEmpty) ? null : foto,
            );
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

  // Penulisan tanpa menunggu server (tersimpan di HP dulu).
  // Kalau gagal, errornya tetap ditampilkan.
  Future<void> _bg(Future<dynamic> f, String pesan) async {
    try {
      await f;
    } catch (e) {
      _pesan('$pesan: $e');
    }
  }

  // Daftar nama bab dari Firestore, format "Bab 1 - Pendahuluan"
  Future<List<String>> _daftarNamaBab() async {
    final chapters = await ambilCepat(_base.collection('chapters'));
    final list = chapters.docs.map((c) {
      final d = c.data();
      return '${d['nomor']} - ${d['judul']}';
    }).toList();
    int nomor(String s) {
      final m = RegExp(r'Bab\s*(\d+)').firstMatch(s);
      return m == null ? 0 : int.parse(m.group(1)!);
    }

    list.sort((a, b) => nomor(a).compareTo(nomor(b)));
    return list;
  }

  // Cari id bab yang cocok dengan nama bab pada revisi
  Future<String?> _idBab(String namaBab) async {
    final chapters = await ambilCepat(_base.collection('chapters'));
    final m = RegExp(r'Bab\s*(\d+)').firstMatch(namaBab);
    final nomor = m == null ? null : 'Bab ${m.group(1)}';
    for (final c in chapters.docs) {
      final d = c.data();
      if ('${d['nomor']} - ${d['judul']}' == namaBab) return c.id;
    }
    if (nomor != null) {
      for (final c in chapters.docs) {
        if (c.data()['nomor'] == nomor) return c.id;
      }
    }
    return null;
  }

  void _pesan(String teks) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  List<Revisi> get _tampil {
    if (_filter == 'Belum') {
      return daftarRevisi.where((r) => !r.selesai).toList();
    }
    if (_filter == 'Selesai') {
      return daftarRevisi.where((r) => r.selesai).toList();
    }
    return daftarRevisi;
  }

  // ---------- Aksi ----------
  Future<void> _tambahRevisi() async {
    final namaBab = await _daftarNamaBab();
    if (!mounted) return;
    if (namaBab.isEmpty) {
      _pesan('Tambahkan bab dulu di tab Bab, baru bisa menambah revisi.');
      return;
    }
    final hasil = await Navigator.push<Revisi>(
      context,
      MaterialPageRoute(builder: (_) => TambahRevisiScreen(opsiBab: namaBab)),
    );
    if (hasil == null || !mounted) return;
    final chapterId = await _idBab(hasil.bab);
    _bg(
      _base.collection('revisions').add({
        'poin': hasil.poin,
        'bab': hasil.bab,
        'chapter_id': chapterId,
        'is_done': hasil.selesai,
        'foto_path': hasil.fotoPath,
        'created_at': FieldValue.serverTimestamp(),
      }),
      'Gagal menyimpan revisi',
    );
    await _muat();
  }

  Future<void> _editRevisi(Revisi r) async {
    final index = daftarRevisi.indexOf(r);
    if (index == -1) return;

    final namaBab = await _daftarNamaBab();
    if (!mounted) return;

    final hasil = await Navigator.push<Revisi>(
      context,
      MaterialPageRoute(
        builder: (_) => TambahRevisiScreen(
          isEdit: true,
          opsiBab: namaBab,
          poinAwal: r.poin,
          babAwal: r.bab,
        ),
      ),
    );
    if (hasil == null || !mounted) return;

    final chapterId = await _idBab(hasil.bab);
    _bg(
      _base.collection('revisions').doc(_ids[index]).update({
        'poin': hasil.poin,
        'bab': hasil.bab,
        'chapter_id': chapterId,
      }),
      'Gagal mengubah revisi',
    );
    if (!mounted) return;
    setState(() {
      daftarRevisi[index] = r.copyWith(poin: hasil.poin, bab: hasil.bab);
    });
  }

  void _hapusRevisi(Revisi r) {
    final index = daftarRevisi.indexOf(r);
    if (index == -1) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus revisi?'),
        content: Text('"${r.poin}" akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _bg(
                _base.collection('revisions').doc(_ids[index]).delete(),
                'Gagal menghapus',
              );
              setState(() {
                daftarRevisi.removeAt(index);
                _ids.removeAt(index);
              });
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _bukaDetail(Revisi r) {
    final index = daftarRevisi.indexOf(r);
    if (index == -1) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailRevisiScreen(
          revisi: r,
          onChanged: (baru) {
            setState(() => daftarRevisi[index] = baru);
            _bg(
              _base.collection('revisions').doc(_ids[index]).update({
                'is_done': baru.selesai,
                'foto_path': baru.fotoPath,
              }),
              'Gagal menyimpan perubahan',
            );
          },
        ),
      ),
    );
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    final tampil = _tampil;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tambahRevisi,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Revisi',
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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: RefreshIndicator(
                onRefresh: _muat,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                  children: [
                    const Text('Daftar Revisi',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),
                    Row(
                      children: ['Semua', 'Belum', 'Selesai']
                          .map((f) => Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                      right: f == 'Selesai' ? 0 : 8),
                                  child: _filterChip(f),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 14),
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
                    else if (tampil.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Center(
                          child: Text('Tidak ada revisi.',
                              style: TextStyle(color: Colors.white70)),
                        ),
                      )
                    else
                      ...tampil.map(_kartuRevisi),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label) {
    final aktif = _filter == label;
    return InkWell(
      onTap: () => setState(() => _filter = label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: aktif ? const Color(0xFF3730A3) : Colors.white.withAlpha(200),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: aktif ? Colors.white : _primary)),
      ),
    );
  }

  Widget _kartuRevisi(Revisi r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _bukaDetail(r),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      r.selesai
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 20,
                      color: r.selesai
                          ? const Color(0xFF10B981)
                          : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(r.poin,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    _badge(r.selesai),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: 30),
                    _chipBab(r.babPendek),
                    const Spacer(),
                    if (r.fotoPath != null) ...[
                      Icon(Icons.photo_camera_outlined,
                          size: 13, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text('1 foto',
                          style: TextStyle(
                              fontSize: 10.5, color: Colors.grey.shade600)),
                      const SizedBox(width: 8),
                    ],
                    _aksiKecil(Icons.edit_outlined, 'Edit',
                        Colors.grey.shade700, Colors.white,
                        Colors.grey.shade300, () => _editRevisi(r)),
                    const SizedBox(width: 6),
                    _aksiKecil(Icons.delete_outline, 'Hapus', Colors.red,
                        const Color(0xFFFDECEC), const Color(0xFFF8C9C9),
                        () => _hapusRevisi(r)),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 10.5, fontWeight: FontWeight.w600, color: fg)),
          ],
        ),
      ),
    );
  }

  Widget _badge(bool selesai) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: selesai ? const Color(0xFFE3F6EA) : const Color(0xFFFDECEC),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(selesai ? 'Selesai' : 'Belum',
            style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: selesai
                    ? const Color(0xFF1E9E55)
                    : const Color(0xFFE5484D))),
      );

  Widget _chipBab(String teks) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF0FF),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(teks,
            style: const TextStyle(
                fontSize: 10, color: _primary, fontWeight: FontWeight.w600)),
      );
}