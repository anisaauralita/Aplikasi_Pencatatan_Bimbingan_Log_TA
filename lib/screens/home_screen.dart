// Import pustaka UI Flutter dasar
import 'package:flutter/material.dart';
// Import package Provider untuk state management aplikasi
import 'package:provider/provider.dart';
// Import AuthProvider untuk mengambil data akun pengguna yang sedang login
import '../providers/auth_provider.dart';
// Import Services untuk memuat statistik dashboard bimbingan
import '../services/stats_service.dart';
// Import layar Ekspor PDF agar tombol ekspor dapat berpindah ke halaman ekspor
import 'ekspor_pdf_screen.dart';

// Definisi HomeScreen sebagai StatefulWidget karena datanya dinamis (perlu dimuat dari service)
class HomeScreen extends StatefulWidget {
  /// Dipanggil saat teks "Lihat Status Bab" ditekan untuk berpindah ke tab Bab pada bottom navigation
  final VoidCallback? onLihatStatusBab;

  // Konstruktor konstan HomeScreen
  const HomeScreen({super.key, this.onLihatStatusBab});

  // Membuat state internal untuk HomeScreen
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// State class HomeScreen
class _HomeScreenState extends State<HomeScreen> {
  // Warna utama tema aplikasi (Indigo)
  static const _primary = Color(0xFF4338CA);
  // Variable Future untuk menampung proses loading statistik dashboard
  late Future<DashboardStats> _future;

  // Lifecycle initState: dipanggil pertama kali saat halaman dibuat
  @override
  void initState() {
    super.initState();
    _muat(); // Memuat data statistik pertama kali
  }

  // Fungsi internal untuk memuat statistik berdasarkan id akun user yang sedang aktif
  void _muat() {
    final id = context.read<AuthProvider>().currentUser!.id; // Mengambil ID pengguna
    _future = StatsService().load(id); // Memanggil layanan statistik
  }

  // Fungsi refresh saat layar ditarik ke bawah (Pull to Refresh)
  Future<void> _refresh() async {
    setState(_muat); // Memperbarui state Future
    await _future; // Menunggu pemuatan data selesai
  }

  // Dialog konfirmasi saat pengguna menekan tombol keluar (logout)
  void _keluar() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar?'), // Judul dialog konfirmasi
        content: const Text('Kamu akan keluar dari akun ini.'), // Pesan deskripsi
        actions: [
          // Tombol Batal dialog
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          // Tombol Keluar dialog
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Tutup dialog
              context.read<AuthProvider>().logout(); // Proses logout akun
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Fungsi aksi tombol Ekspor PDF: Navigasi ke EksporPdfScreen
  void _eksporPdf() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EksporPdfScreen()),
    );
  }

  // ====================== BUILD METHOD ======================
  @override
  Widget build(BuildContext context) {
    // Mengambil nama depan pengguna dari AuthProvider secara reaktif
    final nama =
        context.watch<AuthProvider>().currentUser?.nama.split(' ').first ?? '';

    return Container(
      // Dekorasi gradien warna latar belakang aplikasi
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4338CA), Color(0xFF5B52E0), Color(0xFFB8B4F5)],
        ),
      ),
      child: SafeArea(
        bottom: false, // Menjaga kontenn tetap berada di area aman layar
        child: RefreshIndicator(
          onRefresh: _refresh, // Mengaktifkan fitur tarik untuk memperbarui
          child: FutureBuilder<DashboardStats>(
            future: _future,
            builder: (context, snap) {
              // Tampilan loading saat data sedang dimuat
              if (snap.connectionState != ConnectionState.done) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.white));
              }
              // Tampilan jika terjadi eror saat memuat data
              if (snap.hasError) {
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 80),
                    Text('Gagal memuat data:\n${snap.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white)),
                  ],
                );
              }
              
              // Data statistik berhasil dimuat
              final s = snap.data!;
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(), // Scrollable meskipun data sedikit
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  // Header paling atas (Teks "Beranda" & Tombol Logout)
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
                        icon: const Icon(Icons.logout,
                            color: Colors.white, size: 20),
                        tooltip: 'Keluar',
                      ),
                    ],
                  ),
                  const SizedBox(height: 6), // Spasi vertikal
                  // Teks Sapaan Pengguna
                  Text('Halo, $nama',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  const Text('Semangat mengerjakan tugas akhirmu',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 16),
                  
                  // Komponen 1: Kartu Progres Total
                  _kartuProgresTotal(s),
                  const SizedBox(height: 12),
                  
                  // Komponen 2: Kartu Statistik Ringkas (Bab, Revisi, Log)
                  _kartuStatistik(s),
                  const SizedBox(height: 12),
                  
                  // Komponen 3: Kartu Grafik Batang Progres per Bab
                  _kartuGrafik(s),
                  const SizedBox(height: 14),
                  
                  // Komponen 4: Tombol Ekspor PDF
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _eksporPdf, // Memanggil fungsi navigasi ke EksporPdfScreen
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
              );
            },
          ),
        ),
      ),
    );
  }

  // ====================== SUB-WIDGET CARD BUILDERS ======================

  /// Widget Kartu 1: Menampilkan Progres Total (Donut Progress Indicator)
  Widget _kartuProgresTotal(DashboardStats s) {
    final persen = (s.progresTotal * 100).round();
    return _card(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Ukuran indikator donat beradaptasi dinamis dengan lebar kartu
          final ukuran =
              (constraints.maxWidth * 0.30).clamp(72.0, 120.0).toDouble();
          return Row(
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
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            height: 1.25)),
                    const SizedBox(height: 6),
                    Text('${s.babSelesai} dari ${s.totalBab} bab selesai',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: ukuran,
                height: ukuran,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Lingkaran Progres
                    SizedBox(
                      width: ukuran,
                      height: ukuran,
                      child: CircularProgressIndicator(
                        value: s.progresTotal,
                        strokeWidth: ukuran * 0.12,
                        color: _primary,
                        backgroundColor: const Color(0xFFEEF0FF),
                      ),
                    ),
                    // Persentase Teks di tengah lingkaran
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$persen%',
                            style: TextStyle(
                                fontSize: ukuran * 0.22,
                                fontWeight: FontWeight.w800)),
                        Text('Selesai',
                            style: TextStyle(
                                fontSize: 9, color: Colors.grey.shade600)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Widget Kartu 2: Menampilkan statistik jumlah Bab, Revisi, dan Log
  Widget _kartuStatistik(DashboardStats s) {
    return _card(
      child: IntrinsicHeight(
        child: Row(
          children: [
            _statItem(Icons.menu_book_outlined,
                '${s.babSelesai}/${s.totalBab}', 'Bab'),
            _garis(), // Pembatas vertikal
            _statItem(Icons.assignment_outlined,
                '${s.revisiSelesai}/${s.totalRevisi}', 'Revisi'),
            _garis(), // Pembatas vertikal
            _statItem(Icons.edit_note, '${s.totalLog}', 'Log'),
          ],
        ),
      ),
    );
  }

  // Render per item statistik
  Widget _statItem(IconData icon, String nilai, String label) => Expanded(
        child: Column(
          children: [
            Icon(icon, size: 20, color: _primary),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(nilai,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      );

  // Garis vertikal tipis
  Widget _garis() => Container(width: 1, color: const Color(0xFFE8EAF2));

  /// Widget Kartu 3: Menampilkan Grafik Batang Progres tiap Bab
  Widget _kartuGrafik(DashboardStats s) {
    const tinggiChart = 150.0;
    const labelY = ['100%', '75%', '50%', '25%', '0%'];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text('Progres per Bab',
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              ),
              InkWell(
                onTap: widget.onLihatStatusBab,
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
          if (s.perBab.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('Belum ada bab. Tambahkan di menu Bab.',
                    style: TextStyle(color: Colors.black45)),
              ),
            )
          else
            SizedBox(
              height: tinggiChart + 40,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sumbu Y (Teks Persentase)
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
                  // Area Batang Grafik
                  Expanded(
                    child: Row(
                      children: List.generate(
                          s.perBab.length, (i) => _batang(i, s.perBab[i])),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Render individu tiap batang pada grafik
  Widget _batang(int i, ChapterProgress c) {
    final p = c.persen.clamp(0.0, 1.0);
    final persen = (p * 100).round();
    final label = c.nomor.isEmpty ? 'Bab ${i + 1}' : c.nomor;
    return Expanded(
      child: Column(
        children: [
          // Teks angka persentase di atas batang
          SizedBox(
            height: 16,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('$persen%',
                  style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: persen == 0 ? Colors.grey.shade500 : _primary)),
            ),
          ),
          const SizedBox(height: 4),
          // Batang Grafik Berwarna
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final lebarBatang =
                    (c.maxWidth * 0.6).clamp(18.0, 44.0).toDouble();
                return Center(
                  child: SizedBox(
                    width: lebarBatang,
                    child: Stack(
                      children: [
                        // Background Batang Abu-abu
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F2F8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        // Isi Batang Berwarna Indigo Sesuai Progres
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
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          // Label Nama Bab di bawah batang
          SizedBox(
            height: 14,
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600)),
          ),
        ],
      ),
    );
  }

  // Pembungkus dasar kartu putih bertema membulat dengan bayangan
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