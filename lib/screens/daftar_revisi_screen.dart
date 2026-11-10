import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
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
      final snap = await _base
          .collection('revisions')
          .orderBy('created_at', descending: true)
          .get();
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

  // Cari id bab yang cocok dengan nama bab pada revisi
  Future<String?> _idBab(String namaBab) async {
    final chapters = await _base.collection('chapters').get();
    final m = RegExp(r'Bab\s*(\d+)').firstMatch(namaBab);
    final nomor = m == null ? null : 'Bab ${m.group(1)}';
    for (final c in chapters.docs) {
      final d = c.data();
      final nama = '${d['nomor']} - ${d['judul']}';
      if (nama == namaBab) return c.id;
    }
    // cadangan: cocokkan lewat nomor bab saja
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

  Future<void> _tambahRevisi() async {
    final hasil = await Navigator.push<Revisi>(
      context,
      MaterialPageRoute(builder: (_) => const TambahRevisiScreen()),
    );
    if (hasil == null || !mounted) return;
    try {
      final chapterId = await _idBab(hasil.bab);
      await _base.collection('revisions').add({
        'poin': hasil.poin,
        'bab': hasil.bab,
        'chapter_id': chapterId,
        'is_done': hasil.selesai,
        'foto_path': hasil.fotoPath,
        'created_at': FieldValue.serverTimestamp(),
      });
      if (chapterId == null) {
        _pesan('Revisi tersimpan, tapi bab "${hasil.bab}" tidak ditemukan '
            'di daftar bab, jadi belum terhitung di progres bab.');
      }
      await _muat();
    } catch (e) {
      _pesan('Gagal menyimpan revisi: $e');
    }
  }

  void _bukaDetail(Revisi r) {
    final index = daftarRevisi.indexOf(r);
    if (index == -1) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailRevisiScreen(
          revisi: r,
          onChanged: (baru) async {
            setState(() => daftarRevisi[index] = baru);
            try {
              await _base.collection('revisions').doc(_ids[index]).update({
                'is_done': baru.selesai,
                'foto_path': baru.fotoPath,
              });
            } catch (e) {
              _pesan('Gagal menyimpan perubahan: $e');
            }
          },
        ),
      ),
    );
  }

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
                      Text('1 foto bukti',
                          style: TextStyle(
                              fontSize: 10.5, color: Colors.grey.shade600)),
                    ],
                  ],
                ),
              ],
            ),
          ),
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