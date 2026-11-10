// Import pustaka UI utama dari Flutter
import 'package:flutter/material.dart';
// Import model data Bab untuk membaca dan memperbarui status progres bab
import 'bab_model.dart';

// Definisi kelas StatusBabScreen sebagai StatefulWidget karena status ACC bab dan daftar data bersifat dinamis
class StatusBabScreen extends StatefulWidget {
  // Property menampung daftar bab yang dikirim dari layar sebelumnya
  final List<Bab> daftarBab;

  /// Callback function yang dipanggil setiap kali ada perubahan status ACC pada bab
  final void Function(List<Bab>) onChanged;

  // Konstruktor konstan dengan parameter wajib daftarBab dan onChanged
  const StatusBabScreen({
    super.key,
    required this.daftarBab,
    required this.onChanged,
  });

  // Membuat instance State untuk mengelola tampilan dan logika layar StatusBabScreen
  @override
  State<StatusBabScreen> createState() => _StatusBabScreenState();
}

// Kelas State utama yang mengelola daftar bab dan kalkulasi progres
class _StatusBabScreenState extends State<StatusBabScreen> {
  // Warna utama aplikasi (Indigo pekat)
  static const _primary = Color(0xFF4338CA);
  // Warna hijau untuk indikator bab yang sudah selesai 100% atau ACC
  static const _hijau = Color(0xFF10B981);

  // Variable lokal untuk menampung salinan daftar bab agar dapat diubah statusnya
  late List<Bab> _daftar;

  // Method lifecycle yang dipanggil saat widget pertama kali diinisialisasi
  @override
  void initState() {
    super.initState();
    // Duplikasi data daftarBab dari widget ke variabel lokal _daftar
    _daftar = List.of(widget.daftarBab);
  }

  // Fungsi untuk mengubah status ACC (toggle switch) pada bab ke-i
  void _toggleAcc(int i, bool nilai) {
    final b = _daftar[i];
    // Menentukan teks status baru: jika di-switch (nilai true) maka 'Selesai', jika false cek revisinya
    final statusBaru =
        nilai ? 'Selesai' : (b.revisiSelesai > 0 ? 'Berjalan' : 'Belum');
    // Memperbarui isi bab pada indeks i menggunakan method copyWith
    setState(() => _daftar[i] = b.copyWith(status: statusBaru));
    // Memanggil callback onChanged untuk memberitahu parent widget bahwa daftar bab telah berubah
    widget.onChanged(List.of(_daftar));
    // TODO: tempat menambahkan logika penyimpanan perubahan status ke database SQLite/Firestore
  }

  // Method build yang mengembalikan struktur hirarki UI layar
  @override
  Widget build(BuildContext context) {
    // Menghitung total jumlah bab
    final total = _daftar.length;
    // Menghitung jumlah bab yang sudah berstatus ACC / selesai
    final selesai = _daftar.where((b) => b.acc).length;
    // Menghitung persentase progres total (0.0 sampai 1.0)
    final progres = total == 0 ? 0.0 : selesai / total;
    // Mengubah nilai progres ke bentuk persentase bulat (0% - 100%)
    final persen = (progres * 100).round();

    return Scaffold(
      // AppBar bagian atas layar
      appBar: AppBar(
        backgroundColor: _primary, // Warna latar belakang AppBar
        foregroundColor: Colors.white, // Warna teks dan ikon di AppBar
        elevation: 0, // Tanpa bayangan di bawah AppBar
        title: const Text('Status Bab',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      // Body layar dengan dekorasi gradien warna
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4338CA), Color(0xFF5B52E0), Color(0xFFB8B4F5)],
          ),
        ),
        child: SafeArea(
          // ListView untuk menampilkan kartu statistik total dan daftar kartu per bab
          child: ListView(
            padding: const EdgeInsets.all(16), // Padding di sekeliling daftar 16px
            children: [
              // 1. Kartu Ringkasan Progres Total Tugas Akhir
              _kartuProgresTotal(persen, selesai, total, progres),
              const SizedBox(height: 12), // Jarak vertikal 12px
              // 2. Menampilkan daftar kartu bab secara dinamis sebanyak jumlah total bab
              ...List.generate(total, (i) => _kartuBab(i)),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Kartu Progres Total ----------
  /// Sub-widget untuk menampilkan ringkasan persentase total bab yang sudah di-ACC
  Widget _kartuProgresTotal(int persen, int selesai, int total, double progres) {
    return _card(
      child: Row(
        children: [
          // Indikator Lingkaran Progres (CircularProgressIndicator)
          SizedBox(
            width: 58,
            height: 58,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 58,
                  height: 58,
                  child: CircularProgressIndicator(
                    value: progres, // Nilai progres 0.0 - 1.0
                    strokeWidth: 6, // Ketebalan garis lingkaran
                    color: _primary, // Warna garis progres utama
                    backgroundColor: const Color(0xFFEEF0FF), // Warna latar belakang lingkaran
                  ),
                ),
                // Teks persentase angka di tengah lingkaran
                Text('$persen%',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(width: 14), // Jarak horizontal antar elemen
          // Rincian Teks Progres Total
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Progres Total TA',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800)),
                    ),
                    // Badge kecil "Dihitung otomatis"
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF0FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('Dihitung otomatis',
                          style: TextStyle(
                              fontSize: 9,
                              color: _primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 4), // Spasi vertikal kecil
                // Teks jumlah bab selesai
                Text('$selesai dari $total bab selesai',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                // Progress Bar Garis Lurus (LinearProgressIndicator)
                _bar(progres, _primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Kartu Per Bab ----------
  /// Sub-widget untuk membuat kartu status detail per bab
  Widget _kartuBab(int i) {
    final b = _daftar[i]; // Ambil data bab ke-i
    final p = b.progresRevisi; // Nilai progres revisi bab (0.0 - 1.0)
    final penuh = p >= 1.0; // Pengecekan apakah revisi bab sudah 100%
    final warnaBar = penuh ? _hijau : _primary; // Warna bar hijau jika 100%, indigo jika belum
    final warnaPersen = penuh
        ? _hijau
        : (p > 0 ? _primary : Colors.grey.shade500); // Warna teks persentase dinamis

    return Padding(
      padding: const EdgeInsets.only(bottom: 10), // Jarak antar kartu bab
      child: _card(
        child: Column(
          children: [
            // Baris atas: Judul Bab & Switch ACC
            Row(
              children: [
                // Nama bab
                Expanded(
                  child: Text(b.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 6),
                // Label Teks Selesai (ACC)
                Text('Selesai (ACC)',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                // Tombol Switch pengubah status ACC bab
                Transform.scale(
                  scale: 0.8, // Memperkecil skala ukuran switch agar tampak rapi
                  child: Switch(
                    value: b.acc, // Status tombol switch (aktif/tidak)
                    activeColor: Colors.white,
                    activeTrackColor: _primary,
                    onChanged: (v) => _toggleAcc(i, v), // Panggil fungsi toggleAcc saat diklik
                  ),
                ),
              ],
            ),
            // Progress Bar revisi per bab
            _bar(p, warnaBar),
            const SizedBox(height: 6),
            // Baris bawah: Rincian jumlah revisi selesai & Angka persentase
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${b.revisiSelesai} dari ${b.revisiTotal} revisi selesai',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                Text('${(p * 100).round()}%',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: warnaPersen)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Widget Bantu ----------
  /// Helper method untuk merender Progress Bar garis lurus berujung tumpul
  Widget _bar(double value, Color color) => ClipRRect(
        borderRadius: BorderRadius.circular(8), // Radius tumpul 8px
        child: LinearProgressIndicator(
          value: value, // Nilai progres (0.0 - 1.0)
          minHeight: 5, // Tinggi garis indikator 5px
          color: color, // Warna garis aktif
          backgroundColor: const Color(0xFFEEF0F5), // Warna latar garis
        ),
      );

  /// Helper method pembungkus kartu putih dengan rounded corner & bayangan
  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12), // Inner padding kartu
        decoration: BoxDecoration(
          color: Colors.white, // Background putih
          borderRadius: BorderRadius.circular(16), // Radius sudut 16px
          boxShadow: [
            // Efek bayangan halus kartu
            BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: child,
      );
}