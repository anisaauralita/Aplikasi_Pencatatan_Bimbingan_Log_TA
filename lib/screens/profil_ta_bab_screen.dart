import 'package:flutter/material.dart';
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

  String judul =
      'Aplikasi Presensi Pegawai Menggunakan Fitur Geofencing Berbasis Android';
  String dosen = 'Dr. Ir. Hendra Wijaya, M.T.';

  // Data dummy dulu. Nanti ganti dengan data dari database_helper.dart
  final List<Bab> daftarBab = [
    const Bab('Bab 1 - Pendahuluan', 'Selesai', revisiSelesai: 3, revisiTotal: 3),
    const Bab('Bab 2 - Tinjauan Pustaka', 'Selesai', revisiSelesai: 3, revisiTotal: 3),
    const Bab('Bab 3 - Metodologi Penelitian', 'Berjalan', revisiSelesai: 1, revisiTotal: 4),
    const Bab('Bab 4 - Hasil dan Pembahasan', 'Belum', revisiSelesai: 0, revisiTotal: 1),
    const Bab('Bab 5 - Penutup', 'Belum', revisiSelesai: 0, revisiTotal: 1),
  ];

  // ---------- Helper nomor & nama bab ----------
  int _nomorBab(Bab b) {
    final m = RegExp(r'Bab\s*(\d+)').firstMatch(b.nama);
    return m == null ? 0 : int.parse(m.group(1)!);
  }

  String _namaTanpaNomor(Bab b) {
    final i = b.nama.indexOf(' - ');
    return i == -1 ? b.nama : b.nama.substring(i + 3);
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
        child: ListView(
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
                        label:
                            const Text('Edit', style: TextStyle(fontSize: 12)),
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

            // List bab
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
                      _iconCircle(Icons.delete_outline, Colors.red,
                          const Color(0xFFFDECEC), () => _hapusBab(i)),
                    ],
                  ),
                ),
              );
            }),
          ],
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

  // ---------- Aksi ----------
  Future<void> _editProfil() async {
    final hasil = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => EditJudulTaScreen(judul: judul, dosen: dosen),
      ),
    );
    if (hasil == null || !mounted) return;
    setState(() {
      judul = hasil['judul']!;
      dosen = hasil['dosen']!;
    });
    // TODO: simpan ke database
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
    setState(() {
      daftarBab.add(Bab('Bab ${hasil['nomor']} - ${hasil['nama']}', 'Belum'));
      daftarBab.sort((a, b) => _nomorBab(a).compareTo(_nomorBab(b)));
    });
    // TODO: simpan ke database
  }

  Future<void> _editBab(int index) async {
    final lama = daftarBab[index];
    final nomorLama = _nomorBab(lama);
    final hasil = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => TambahBabScreen(
          isEdit: true,
          nomorAwal: nomorLama,
          namaAwal: _namaTanpaNomor(lama),
          nomorTerpakai: daftarBab.map(_nomorBab).toList(),
        ),
      ),
    );
    if (hasil == null || !mounted) return;
    setState(() {
      daftarBab[index] = lama.copyWith(
          nama: 'Bab ${hasil['nomor']} - ${hasil['nama']}');
      daftarBab.sort((a, b) => _nomorBab(a).compareTo(_nomorBab(b)));
    });
    // TODO: update di database
  }

  // Buka layar Status Bab (progres revisi + toggle ACC)
  void _statusBab() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StatusBabScreen(
          daftarBab: List.of(daftarBab),
          onChanged: (baru) => setState(() {
            daftarBab
              ..clear()
              ..addAll(baru);
          }),
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
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => daftarBab.removeAt(index));
              // TODO: hapus juga dari database
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}