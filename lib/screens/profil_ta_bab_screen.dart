import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'edit_judul_ta_screen.dart';
import 'tambah_bab_screen.dart';
import 'bab_model.dart';
import 'status_bab_screen.dart';

class ProfilTaBabScreen extends StatefulWidget {
  const ProfilTaBabScreen({super.key});

  @override
  State<ProfilTaBabScreen> createState() => _ProfilTaBabScreenState();
}

class _ProfilTaBabScreenState extends State<ProfilTaBabScreen> {
  static const _primary = Color(0xFF4338CA);

  late final String _uid;
  DocumentReference<Map<String, dynamic>> get _base =>
      FirebaseFirestore.instance.collection('users').doc(_uid);

  String judul = 'Belum diisi';
  String dosen = 'Belum diisi';

  final List<Bab> daftarBab = [];
  List<String> _ids = []; // id dokumen Firestore, urutannya sama dengan daftarBab
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _uid = context.read<AuthProvider>().currentUser!.id;
    _muat();
  }

  // ---------- Helper nomor & nama bab ----------
  int _nomorBab(Bab b) {
    final m = RegExp(r'Bab\s*(\d+)').firstMatch(b.nama);
    return m == null ? 0 : int.parse(m.group(1)!);
  }

  String _namaTanpaNomor(Bab b) {
    final i = b.nama.indexOf(' - ');
    return i == -1 ? b.nama : b.nama.substring(i + 3);
  }

  // ---------- Firestore ----------
    Future<void> _muat() async {
    try {
      final hasilBaca = await Future.wait([
        _base.get(),
        _base.collection('chapters').get(),
        _base.collection('revisions').get(),
      ]);
      final userDoc = hasilBaca[0] as DocumentSnapshot<Map<String, dynamic>>;
      final chapters = hasilBaca[1] as QuerySnapshot<Map<String, dynamic>>;
      final revs = hasilBaca[2] as QuerySnapshot<Map<String, dynamic>>;


      final items = <(String, Bab)>[];
      for (final c in chapters.docs) {
        final d = c.data();
        final nomor = (d['nomor'] ?? '').toString();
        final namaBab = (d['judul'] ?? '').toString();
        final mine =
            revs.docs.where((r) => r.data()['chapter_id'] == c.id).toList();
        final done =
            mine.where((r) => r.data()['is_done'] == true).length;
        final isDone = d['is_done'] == true;
        final status = isDone ? 'Selesai' : (done > 0 ? 'Berjalan' : 'Belum');
        items.add((
          c.id,
          Bab('$nomor - $namaBab', status,
              revisiSelesai: done, revisiTotal: mine.length),
        ));
      }
      items.sort((a, b) => _nomorBab(a.$2).compareTo(_nomorBab(b.$2)));

      if (!mounted) return;
      final u = userDoc.data();
      setState(() {
        judul = (u?['judul_ta'] ?? 'Belum diisi').toString();
        dosen = (u?['dosen'] ?? 'Belum diisi').toString();
        _ids = items.map((e) => e.$1).toList();
        daftarBab
          ..clear()
          ..addAll(items.map((e) => e.$2));
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

  @override
  Widget build(BuildContext context) {
    return Container(
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Profil TA & Bab',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      Icon(Icons.more_vert, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Kartu profil TA
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('JUDUL TUGAS AKHIR',
                                style: TextStyle(
                                    color: _primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5)),
                            OutlinedButton.icon(
                              onPressed: _editProfil,
                              icon: const Icon(Icons.edit, size: 12),
                              label: const Text('Edit',
                                  style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _primary,
                                side: const BorderSide(color: _primary),
                                shape: const StadiumBorder(),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(judul,
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                height: 1.3)),
                        const Divider(height: 28),
                        const Text('DOSEN PEMBIMBING',
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        Text(dosen,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Daftar Bab + tombol
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Daftar Bab',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold)),
                      ),
                      _pillButton(Icons.checklist, 'Status Bab',
                          filled: false, onTap: _statusBab),
                      const SizedBox(width: 8),
                      _pillButton(Icons.add, 'Tambah Bab',
                          filled: true, onTap: _tambahBab),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                          child:
                              CircularProgressIndicator(color: Colors.white)),
                    )
                  else if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text('Gagal memuat data:\n$_error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white)),
                    )
                  else if (daftarBab.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('Belum ada bab. Tekan "Tambah Bab".',
                            style: TextStyle(color: Colors.white70)),
                      ),
                    )
                  else
                    ...List.generate(daftarBab.length, (i) {
                      final bab = daftarBab[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _card(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(bab.nama,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 8),
                                    _statusChip(bab.status),
                                  ],
                                ),
                              ),
                              _iconCircle(Icons.edit, _primary,
                                  const Color(0xFFEEF0FF), () => _editBab(i)),
                              const SizedBox(width: 8),
                              _iconCircle(
                                  Icons.delete_outline,
                                  Colors.red,
                                  const Color(0xFFFDECEC),
                                  () => _hapusBab(i)),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Widget bantu ----------
  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: child,
      );

  Widget _pillButton(IconData icon, String label,
      {required bool filled, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: filled ? Colors.white : Colors.white.withAlpha(40),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(120)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: filled ? _primary : Colors.white),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: filled ? _primary : Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color bg, fg;
    switch (status) {
      case 'Selesai':
        bg = const Color(0xFFE3F6EA);
        fg = const Color(0xFF1E9E55);
        break;
      case 'Berjalan':
        bg = const Color(0xFFFFF1D6);
        fg = const Color(0xFFE08A00);
        break;
      default:
        bg = const Color(0xFFEDEDED);
        fg = Colors.grey.shade600;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(status,
          style:
              TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _iconCircle(IconData icon, Color fg, Color bg, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: fg.withAlpha(80))),
        child: Icon(icon, size: 16, color: fg),
      ),
    );
  }

  void _pesan(String teks) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(teks)));
  }

  // ---------- Aksi ----------
  Future<void> _editProfil() async {
    final hasil = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => EditJudulTaScreen(judul: judul, dosen: dosen),
      ),
    );
    if (hasil == null || !mounted) return;
    try {
      await _base.set(
          {'judul_ta': hasil['judul'], 'dosen': hasil['dosen']},
          SetOptions(merge: true));
      setState(() {
        judul = hasil['judul']!;
        dosen = hasil['dosen']!;
      });
    } catch (e) {
      _pesan('Gagal menyimpan: $e');
    }
  }

  Future<void> _tambahBab() async {
    final hasil = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => TambahBabScreen(
          nomorTerpakai: daftarBab.map(_nomorBab).toList(),
        ),
      ),
    );
    if (hasil == null || !mounted) return;
    try {
      await _base.collection('chapters').add({
        'nomor': 'Bab ${hasil['nomor']}',
        'judul': hasil['nama'],
        'is_done': false,
        'created_at': FieldValue.serverTimestamp(),
      });
      await _muat();
    } catch (e) {
      _pesan('Gagal menambah bab: $e');
    }
  }

  Future<void> _editBab(int index) async {
    final lama = daftarBab[index];
    final hasil = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => TambahBabScreen(
          isEdit: true,
          nomorAwal: _nomorBab(lama),
          namaAwal: _namaTanpaNomor(lama),
          nomorTerpakai: daftarBab.map(_nomorBab).toList(),
        ),
      ),
    );
    if (hasil == null || !mounted) return;
    try {
      await _base.collection('chapters').doc(_ids[index]).update({
        'nomor': 'Bab ${hasil['nomor']}',
        'judul': hasil['nama'],
      });
      await _muat();
    } catch (e) {
      _pesan('Gagal mengubah bab: $e');
    }
  }

  // Buka layar Status Bab (progres revisi + toggle ACC)
  void _statusBab() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StatusBabScreen(
          daftarBab: List.of(daftarBab),
          onChanged: (baru) async {
            // Simpan hanya bab yang toggle ACC-nya berubah
            for (var i = 0; i < baru.length && i < _ids.length; i++) {
              if (baru[i].acc != daftarBab[i].acc) {
                try {
                  await _base
                      .collection('chapters')
                      .doc(_ids[i])
                      .update({'is_done': baru[i].acc});
                } catch (e) {
                  _pesan('Gagal menyimpan status: $e');
                }
              }
            }
            if (!mounted) return;
            setState(() {
              daftarBab
                ..clear()
                ..addAll(baru);
            });
          },
        ),
      ),
    );
  }

  void _hapusBab(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus bab?'),
        content: Text('${daftarBab[index].nama} akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _base
                    .collection('chapters')
                    .doc(_ids[index])
                    .delete();
                await _muat();
              } catch (e) {
                _pesan('Gagal menghapus: $e');
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}