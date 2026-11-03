import 'package:flutter/material.dart';
import 'bab_model.dart';
import 'status_bab_screen.dart';

class DashboardScreen extends StatefulWidget {
  /// Nama pengguna yang ditampilkan di sapaan. Nanti ambil dari data login.
  final String nama;

  const DashboardScreen({super.key, this.nama = 'Siti'});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _primary = Color(0xFF4338CA);

  // Data dummy dulu (sama dengan layar Bab & Revisi).
  // Nanti ganti dengan data dari database_helper.dart
  final List<Bab> daftarBab = const [
    Bab('Bab 1 - Pendahuluan', 'Selesai', revisiSelesai: 3, revisiTotal: 3),
    Bab('Bab 2 - Tinjauan Pustaka', 'Selesai', revisiSelesai: 3, revisiTotal: 3),
    Bab('Bab 3 - Metodologi Penelitian', 'Berjalan',
        revisiSelesai: 1, revisiTotal: 4),
    Bab('Bab 4 - Hasil dan Pembahasan', 'Belum',
        revisiSelesai: 0, revisiTotal: 1),
    Bab('Bab 5 - Penutup', 'Belum', revisiSelesai: 0, revisiTotal: 1),
  ];
  final int jumlahLog = 9;

  // ---------- Perhitungan ringkasan ----------
  int get _babSelesai => daftarBab.where((b) => b.acc).length;
  int get _revisiSelesai =>
      daftarBab.fold(0, (jumlah, b) => jumlah + b.revisiSelesai);
  int get _revisiTotal =>
      daftarBab.fold(0, (jumlah, b) => jumlah + b.revisiTotal);
  double get _progresTotal =>
      daftarBab.isEmpty ? 0 : _babSelesai / daftarBab.length;

  void _lihatStatusBab() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StatusBabScreen(
          daftarBab: List.of(daftarBab),
          onChanged: (_) {}, // TODO: simpan perubahan ke database
        ),
      ),
    );
  }

  void _keluar() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar?'),
        content: const Text('Kamu akan keluar dari akun ini.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: hapus sesi login lalu pindah ke LoginScreen
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _eksporPdf() {
    // TODO: buat file PDF kartu bimbingan
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur ekspor PDF belum tersedia.')),
    );
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Beranda',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                IconButton(
                  onPressed: _keluar,
                  icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                  tooltip: 'Keluar',
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Halo, ${widget.nama}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            const Text('Semangat mengerjakan tugas akhirmu',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 16),

            _kartuProgresTotal(),
            const SizedBox(height: 12),
            _kartuStatistik(),
            const SizedBox(height: 12),
            _kartuGrafik(),
            const SizedBox(height: 14),

            // Tombol ekspor
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _eksporPdf,
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text('Ekspor Kartu Bimbingan ke PDF',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Kartu progres total (donut) ----------
  Widget _kartuProgresTotal() {
    final persen = (_progresTotal * 100).round();
    return _card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('STATUS PROGRES',
                    style: TextStyle(
                        color: _primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5)),
                const SizedBox(height: 6),
                const Text('Progres Total Tugas Akhir',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800, height: 1.25)),
                const SizedBox(height: 6),
                Text('$_babSelesai dari ${daftarBab.length} bab selesai',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 82,
            height: 82,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 82,
                  height: 82,
                  child: CircularProgressIndicator(
                    value: _progresTotal,
                    strokeWidth: 10,
                    color: _primary,
                    backgroundColor: const Color(0xFFEEF0FF),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$persen%',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    Text('Selesai',
                        style: TextStyle(
                            fontSize: 9, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Kartu statistik (Bab / Revisi / Log) ----------
  Widget _kartuStatistik() {
    return _card(
      child: IntrinsicHeight(
        child: Row(
          children: [
            _statItem(Icons.menu_book_outlined,
                '$_babSelesai/${daftarBab.length}', 'Bab'),
            _garis(),
            _statItem(Icons.assignment_outlined,
                '$_revisiSelesai/$_revisiTotal', 'Revisi'),
            _garis(),
            _statItem(Icons.edit_note, '$jumlahLog', 'Log'),
          ],
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String nilai, String label) => Expanded(
        child: Column(
          children: [
            Icon(icon, size: 20, color: _primary),
            const SizedBox(height: 6),
            Text(nilai,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      );

  Widget _garis() => Container(width: 1, color: const Color(0xFFE8EAF2));

  // ---------- Kartu grafik progres per bab ----------
  Widget _kartuGrafik() {
    const tinggiChart = 150.0;
    const labelY = ['100%', '75%', '50%', '25%', '0%'];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Progres per Bab',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              InkWell(
                onTap: _lihatStatusBab,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text('Lihat Status Bab >',
                      style: TextStyle(
                          fontSize: 11,
                          color: _primary,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: tinggiChart + 40,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sumbu Y
                SizedBox(
                  width: 34,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: labelY
                              .map((t) => Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(t,
                                        style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.grey.shade500)),
                                  ))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                // Batang per bab
                Expanded(
                  child: Row(
                    children: List.generate(
                        daftarBab.length, (i) => _batang(i, daftarBab[i])),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _batang(int i, Bab b) {
    final p = b.progresRevisi.clamp(0.0, 1.0);
    final persen = (p * 100).round();
    return Expanded(
      child: Column(
        children: [
          SizedBox(
            height: 16,
            child: Text('$persen%',
                style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: persen == 0 ? Colors.grey.shade500 : _primary)),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: SizedBox(
              width: 26,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F2F8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: p,
                      widthFactor: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 14,
            child: Text('Bab ${i + 1}',
                style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600)),
          ),
        ],
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
}