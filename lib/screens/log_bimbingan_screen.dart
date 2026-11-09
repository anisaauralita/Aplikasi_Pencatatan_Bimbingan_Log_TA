import 'package:flutter/material.dart';
import 'log_model.dart';
import 'tambah_log_screen.dart';

class LogBimbinganScreen extends StatefulWidget {
  const LogBimbinganScreen({super.key});

  @override
  State<LogBimbinganScreen> createState() => _LogBimbinganScreenState();
}

class _LogBimbinganScreenState extends State<LogBimbinganScreen> {
  static const _primary = Color(0xFF4338CA);

  // Data dummy dulu. Nanti ganti dengan data dari database_helper.dart
  final List<LogBimbingan> daftarLog = [
    LogBimbingan(DateTime(2026, 10, 29),
        'Perjelas metode analisis data dan tambahkan referensi jurnal terbaru pada Bab 3.'),
    LogBimbingan(DateTime(2026, 10, 15),
        'Perbaiki sitasi sesuai format dan rapikan kerangka berpikir pada Bab 2.'),
    LogBimbingan(DateTime(2026, 10, 8),
        'Revisi rumusan masalah dan tujuan penelitian pada Bab 1.'),
    LogBimbingan(DateTime(2026, 10, 1),
        'Diskusi judul dan ruang lingkup penelitian.'),
  ];

  void _urutkan() =>
      daftarLog.sort((a, b) => b.tanggal.compareTo(a.tanggal)); // terbaru di atas

  Future<void> _tambahLog() async {
    final hasil = await Navigator.push<LogBimbingan>(
      context,
      MaterialPageRoute(builder: (_) => const TambahLogScreen()),
    );
    if (hasil == null || !mounted) return;
    setState(() {
      daftarLog.add(hasil);
      _urutkan();
    });
    // TODO: simpan ke database
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
    setState(() {
      daftarLog[index] = hasil;
      _urutkan();
    });
    // TODO: update di database
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
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => daftarLog.removeAt(index));
              // TODO: hapus juga dari database
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            children: [
              const Text('Log Bimbingan',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (daftarLog.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(
                    child: Text('Belum ada log bimbingan.',
                        style: TextStyle(color: Colors.white70)),
                  ),
                ),
              ...List.generate(daftarLog.length, (i) => _kartuLog(i)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kartuLog(int i) {
    final log = daftarLog[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 15, color: _primary),
              const SizedBox(width: 8),
              Text(formatTanggal(log.tanggal),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          Text(log.catatan,
              style: TextStyle(
                  fontSize: 12.5, height: 1.4, color: Colors.grey.shade800)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _aksiKecil(Icons.edit_outlined, 'Edit', Colors.grey.shade700,
                  Colors.white, Colors.grey.shade300, () => _editLog(i)),
              const SizedBox(width: 8),
              _aksiKecil(Icons.delete_outline, 'Hapus', Colors.red,
                  const Color(0xFFFDECEC), const Color(0xFFF8C9C9),
                  () => _hapusLog(i)),
            ],
          ),
        ],
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