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
import 'status_bab_loader.dart';
// Halaman profil mahasiswa: dibuka dari ikon profil di header Beranda
import 'profil_mahasiswa_screen.dart';

// ---------- BARU: import untuk kartu-kartu tambahan di Beranda ----------
// Firestore: mengambil judul TA, dosen, log terakhir, dan revisi yang belum selesai
import 'package:cloud_firestore/cloud_firestore.dart';
// Helper pembaca Firestore (cache dulu) yang sudah dipakai halaman lain
import '../services/fs_helper.dart';
// Halaman detail revisi: dibuka saat revisi di kartu "Revisi Menunggu" diketuk
import 'detail_revisi_screen.dart';
// formatTanggal(): mengubah DateTime menjadi teks 'Kamis, 29 Okt 2026'
import 'log_model.dart';
// Model Revisi yang dipakai halaman detail revisi
import 'revisi_model.dart';

// ---------- BARU: model data kecil khusus kartu tambahan Beranda ----------

/// Satu revisi yang belum selesai, lengkap dengan id dokumen Firestore-nya
/// (id dibutuhkan untuk menyimpan perubahan dari halaman detail revisi)
class _RevisiMenunggu {
  final String id;
  final Revisi revisi;
  const _RevisiMenunggu(this.id, this.revisi);
}

/// Kumpulan data tambahan yang ditampilkan di Beranda selain statistik lama
class _DataTambahan {
  final String judul; // judul tugas akhir
  final String dosen; // nama dosen pembimbing
  final DateTime? tglLogTerakhir; // tanggal bimbingan terakhir (null = belum ada log)
  final String? catatanLogTerakhir; // catatan bimbingan terakhir
  final int totalMenunggu; // jumlah SEMUA revisi yang belum selesai
  final List<_RevisiMenunggu> menunggu; // maksimal 3 revisi belum selesai (terbaru)
  final Map<String, DateTime> tglLog; // id log -> tanggal (untuk info asal bimbingan)

  const _DataTambahan({
    required this.judul,
    required this.dosen,
    required this.tglLogTerakhir,
    required this.catatanLogTerakhir,
    required this.totalMenunggu,
    required this.menunggu,
    required this.tglLog,
  });
}

// Definisi HomeScreen sebagai StatefulWidget karena datanya dinamis (perlu dimuat dari service)
class HomeScreen extends StatefulWidget {
  /// Dipanggil saat teks "Lihat Status Bab" ditekan untuk berpindah ke tab Bab pada bottom navigation
  final VoidCallback? onLihatStatusBab;

  /// BARU: Dipanggil untuk berpindah ke tab lain lewat bottom navigation
  /// (0 = Beranda, 1 = Bab, 2 = Bimbingan, 3 = Revisi). Dipakai oleh tombol
  /// aksi cepat dan kartu-kartu baru di Beranda.
  final ValueChanged<int>? onPindahTab;

  // Konstruktor konstan HomeScreen
  const HomeScreen({super.key, this.onLihatStatusBab, this.onPindahTab});

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
  // BARU: Future untuk data kartu tambahan (judul TA, log terakhir, revisi menunggu)
  late Future<_DataTambahan> _futureTambahan;

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
    _futureTambahan = _muatTambahan(id); // BARU: ikut memuat data kartu tambahan
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
  // Buka halaman Status Bab langsung, lalu muat ulang Beranda saat kembali
  Future<void> _bukaStatusBab() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StatusBabLoader()),
    );
    if (!mounted) return;
    setState(_muat);
  }
  // Buka halaman Profil Mahasiswa
  void _bukaProfil() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfilMahasiswaScreen()),
    );
  }

  // Fungsi aksi tombol Ekspor PDF: Navigasi ke EksporPdfScreen
  void _eksporPdf() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EksporPdfScreen()),
    );
  }

  // ====================== BARU: PEMUATAN DATA KARTU TAMBAHAN ======================

  // Mengambil semua data tambahan Beranda dari Firestore.
  // Setiap bagian dibungkus try/catch sendiri, jadi kalau salah satu gagal
  // (misal tidak ada koneksi), Beranda tetap tampil dan kartu itu hanya kosong.
  Future<_DataTambahan> _muatTambahan(String uid) async {
    final base = FirebaseFirestore.instance.collection('users').doc(uid);

    // --- 1) Judul TA dan dosen dari dokumen profil user (cache dulu, lalu server) ---
    var judul = 'Belum diisi';
    var dosen = 'Belum diisi';
    try {
      DocumentSnapshot<Map<String, dynamic>>? doc;
      try {
        final c = await base.get(const GetOptions(source: Source.cache));
        if (c.exists) doc = c;
      } catch (_) {}
      doc ??= await base.get().timeout(const Duration(seconds: 6));
      final u = doc.data();
      judul = (u?['judul_ta'] ?? 'Belum diisi').toString();
      dosen = (u?['dosen'] ?? 'Belum diisi').toString();
    } catch (_) {}

    // --- 2) Log bimbingan: ambil yang terbaru + peta id -> tanggal ---
    final tglLog = <String, DateTime>{};
    DateTime? tglTerakhir;
    String? catatanTerakhir;
    try {
      final snap = await ambilCepat(
          base.collection('logs').orderBy('tanggal', descending: true));
      for (final d in snap.docs) {
        final t = d.data()['tanggal'];
        if (t is Timestamp) tglLog[d.id] = t.toDate();
      }
      if (snap.docs.isNotEmpty) {
        final x = snap.docs.first.data(); // urutan menurun, jadi dokumen pertama = terbaru
        final t = x['tanggal'];
        if (t is Timestamp) {
          tglTerakhir = t.toDate();
          catatanTerakhir = (x['catatan'] ?? '').toString();
        }
      }
    } catch (_) {}

    // --- 3) Revisi yang belum selesai (tampilkan 3 yang terbaru) ---
    final menunggu = <_RevisiMenunggu>[];
    var totalMenunggu = 0;
    try {
      final snap = await ambilCepat(base.collection('revisions'));
      final belum = snap.docs.where((d) => d.data()['is_done'] != true).toList();
      // Urutkan dari yang terbaru. created_at kosong = baru saja ditambahkan, dianggap paling baru
      final kini = DateTime.now().millisecondsSinceEpoch;
      belum.sort((a, b) {
        final ta = a.data()['created_at'];
        final tb = b.data()['created_at'];
        final ma = ta is Timestamp ? ta.millisecondsSinceEpoch : kini;
        final mb = tb is Timestamp ? tb.millisecondsSinceEpoch : kini;
        return mb.compareTo(ma);
      });
      totalMenunggu = belum.length;
      for (final d in belum.take(3)) {
        final x = d.data();
        final foto = x['foto_path'] as String?;
        final lid = x['log_id'] as String?;
        menunggu.add(_RevisiMenunggu(
          d.id,
          Revisi(
            poin: (x['poin'] ?? '').toString(),
            bab: (x['bab'] ?? '').toString(),
            selesai: false,
            fotoPath: (foto == null || foto.isEmpty) ? null : foto,
            logId: (lid == null || lid.isEmpty) ? null : lid,
          ),
        ));
      }
    } catch (_) {}

    return _DataTambahan(
      judul: judul,
      dosen: dosen,
      tglLogTerakhir: tglTerakhir,
      catatanLogTerakhir: catatanTerakhir,
      totalMenunggu: totalMenunggu,
      menunggu: menunggu,
      tglLog: tglLog,
    );
  }

  // BARU: pembungkus untuk menampilkan kartu tambahan setelah datanya siap.
  // Selama data belum ada (atau gagal dimuat) tidak menampilkan apa pun,
  // sehingga bagian Beranda yang lama tidak terganggu.
  Widget _denganTambahan(Widget Function(_DataTambahan d) bangun) {
    return FutureBuilder<_DataTambahan>(
      future: _futureTambahan,
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        return bangun(snap.data!);
      },
    );
  }

  // BARU: menjalankan penulisan Firestore tanpa menunggu server (tersimpan di HP dulu);
  // jika gagal, pesan error ditampilkan lewat SnackBar
  Future<void> _bg(Future<dynamic> f, String pesan) async {
    try {
      await f;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$pesan: $e')));
    }
  }

  // BARU: berpindah ke tab lain (jika callback disediakan oleh MainShell)
  void _pindahTab(int i) => widget.onPindahTab?.call(i);

  // BARU: teks selisih hari, misal 'Hari ini', 'Kemarin', '5 hari yang lalu'
  String _selisihHari(DateTime tgl) {
    final sekarang = DateTime.now();
    final a = DateTime(sekarang.year, sekarang.month, sekarang.day);
    final b = DateTime(tgl.year, tgl.month, tgl.day);
    final n = a.difference(b).inDays;
    if (n < 0) return 'Akan datang';
    if (n == 0) return 'Hari ini';
    if (n == 1) return 'Kemarin';
    if (n < 30) return '$n hari yang lalu';
    return '${n ~/ 30} bulan yang lalu';
  }

  // BARU: buka detail revisi dari kartu "Revisi Menunggu".
  // Perubahan (foto / status selesai) disimpan ke Firestore, lalu Beranda dimuat ulang
  // supaya angka statistik dan daftar menunggu ikut diperbarui.
  Future<void> _bukaRevisi(_RevisiMenunggu r, _DataTambahan d) async {
    final uid = context.read<AuthProvider>().currentUser!.id;
    final lid = r.revisi.logId;
    final tgl = lid == null ? null : d.tglLog[lid];
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailRevisiScreen(
          revisi: r.revisi,
          asalBimbingan: tgl == null ? null : formatTanggal(tgl),
          onChanged: (baru) {
            _bg(
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('revisions')
                  .doc(r.id)
                  .update({
                'is_done': baru.selesai,
                'foto_path': baru.fotoPath,
              }),
              'Gagal menyimpan perubahan',
            );
          },
        ),
      ),
    );
    if (!mounted) return;
    setState(_muat);
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: _bukaProfil,
                            icon: const Icon(Icons.account_circle_outlined,
                                color: Colors.white, size: 22),
                            tooltip: 'Profil',
                          ),
                          IconButton(
                            onPressed: _keluar,
                            icon: const Icon(Icons.logout,
                                color: Colors.white, size: 20),
                            tooltip: 'Keluar',
                          ),
                        ],
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

                  // BARU - Komponen 0: Kartu judul TA + dosen pembimbing
                  _denganTambahan((d) => Column(
                        children: [
                          _kartuProfilTa(d),
                          const SizedBox(height: 12),
                        ],
                      )),
                  
                  // Komponen 1: Kartu Progres Total
                  _kartuProgresTotal(s),
                  const SizedBox(height: 12),
                  
                  // Komponen 2: Kartu Statistik Ringkas (Bab, Revisi, Log)
                  _kartuStatistik(s),
                  const SizedBox(height: 12),

                  // BARU - Komponen 2b: Aksi cepat (jalan pintas ke Bimbingan, Revisi, Status Bab)
                  _aksiCepat(),
                  const SizedBox(height: 12),
                  
                  // Komponen 3: Kartu Grafik Batang Progres per Bab
                  _kartuGrafik(s),
                  const SizedBox(height: 14),

                  // BARU - Komponen 3b: Kartu bimbingan terakhir
                  _denganTambahan((d) => Column(
                        children: [
                          _kartuBimbinganTerakhir(d),
                          const SizedBox(height: 12),
                        ],
                      )),

                  // BARU - Komponen 3c: Kartu revisi yang masih menunggu
                  _denganTambahan((d) => Column(
                        children: [
                          _kartuRevisiMenunggu(s, d),
                          const SizedBox(height: 12),
                        ],
                      )),
                  
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

  // ====================== BARU: KARTU-KARTU TAMBAHAN ======================

  /// BARU - Kartu judul TA + dosen pembimbing.
  /// Diketuk -> pindah ke tab Bab (tempat judul dan dosen bisa diedit).
  Widget _kartuProfilTa(_DataTambahan d) {
    final kosong = d.judul == 'Belum diisi';
    return _kartuKlik(
      onTap: () => _pindahTab(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kotak ikon topi wisuda di kiri
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF0FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.school_outlined,
                    size: 20, color: _primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('JUDUL TUGAS AKHIR',
                        style: TextStyle(
                            color: _primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(
                      kosong ? 'Judul belum diisi' : d.judul,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                        color: kosong ? Colors.grey.shade500 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
            ],
          ),
          const Divider(height: 22),
          // Baris dosen pembimbing
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text('Dosen Pembimbing: ',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
              Expanded(
                child: Text(
                  d.dosen == 'Belum diisi' ? '-' : d.dosen,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          // Petunjuk singkat jika judul belum diisi
          if (kosong) ...[
            const SizedBox(height: 8),
            const Text('Ketuk kartu ini untuk mengisi judul dan dosen.',
                style: TextStyle(fontSize: 11, color: _primary)),
          ],
        ],
      ),
    );
  }

  /// BARU - Baris tiga tombol aksi cepat (jalan pintas)
  Widget _aksiCepat() {
    return Row(
      children: [
        _tombolAksi(Icons.edit_note, 'Catat\nBimbingan', () => _pindahTab(2)),
        const SizedBox(width: 10),
        _tombolAksi(Icons.assignment_outlined, 'Lihat\nRevisi', () => _pindahTab(3)),
        const SizedBox(width: 10),
        _tombolAksi(Icons.fact_check_outlined, 'Status\nBab', _bukaStatusBab),
      ],
    );
  }

  // BARU - Satu tombol aksi cepat: ikon dalam lingkaran + label dua baris
  Widget _tombolAksi(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: Container(
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
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                        color: Color(0xFFEEF0FF), shape: BoxShape.circle),
                    child: Icon(icon, size: 20, color: _primary),
                  ),
                  const SizedBox(height: 8),
                  Text(label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 11,
                          height: 1.25,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// BARU - Kartu bimbingan terakhir (tanggal, selisih hari, cuplikan catatan).
  /// Diketuk -> pindah ke tab Bimbingan.
  Widget _kartuBimbinganTerakhir(_DataTambahan d) {
    final tgl = d.tglLogTerakhir;
    return _kartuKlik(
      onTap: () => _pindahTab(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul kartu + tautan "Lihat semua"
          Row(
            children: [
              const Expanded(
                child: Text('Bimbingan Terakhir',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              ),
              const Text('Lihat semua >',
                  style: TextStyle(
                      fontSize: 11,
                      color: _primary,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          if (tgl == null)
            // Keadaan kosong: belum pernah mencatat bimbingan
            Row(
              children: [
                Icon(Icons.event_note_outlined,
                    size: 22, color: Colors.grey.shade400),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                      'Belum ada bimbingan. Catat bimbingan pertamamu di menu Bimbingan.',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                ),
              ],
            )
          else ...[
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: _primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(formatTanggal(tgl),
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w700)),
                ),
                // Chip selisih hari (misal "3 hari yang lalu")
                _chip(_selisihHari(tgl), const Color(0xFFEEF0FF), _primary),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              (d.catatanLogTerakhir ?? '').trim().isEmpty
                  ? '-'
                  : d.catatanLogTerakhir!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12.5, height: 1.4, color: Colors.grey.shade800),
            ),
          ],
        ],
      ),
    );
  }

  /// BARU - Kartu revisi yang masih menunggu (maksimal 3, yang terbaru).
  /// Setiap revisi bisa diketuk -> Detail Revisi.
  Widget _kartuRevisiMenunggu(DashboardStats s, _DataTambahan d) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul kartu + jumlah revisi menunggu
          Row(
            children: [
              const Expanded(
                child: Text('Revisi Menunggu',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              ),
              if (d.totalMenunggu > 0)
                _chip('${d.totalMenunggu} belum selesai',
                    const Color(0xFFFDECEC), const Color(0xFFE5484D)),
            ],
          ),
          const SizedBox(height: 10),
          if (d.menunggu.isEmpty)
            // Keadaan kosong: belum ada revisi sama sekali, atau semuanya sudah selesai
            Row(
              children: [
                Icon(
                  s.totalRevisi == 0
                      ? Icons.assignment_outlined
                      : Icons.check_circle,
                  size: 22,
                  color: s.totalRevisi == 0
                      ? Colors.grey.shade400
                      : const Color(0xFF10B981),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.totalRevisi == 0
                        ? 'Belum ada revisi. Tambahkan di menu Revisi.'
                        : 'Semua revisi sudah selesai. Mantap!',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ],
            )
          else
            ...d.menunggu.map((r) => _barisRevisi(r, d)),
          // Info jika masih ada revisi lain yang tidak ikut ditampilkan
          if (d.totalMenunggu > d.menunggu.length) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: () => _pindahTab(3),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                    '+ ${d.totalMenunggu - d.menunggu.length} revisi lainnya. Lihat semua >',
                    style: const TextStyle(
                        fontSize: 11,
                        color: _primary,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // BARU - Satu baris revisi menunggu: lingkaran kosong, poin revisi, chip bab, panah
  Widget _barisRevisi(_RevisiMenunggu r, _DataTambahan d) {
    return InkWell(
      onTap: () => _bukaRevisi(r, d),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Icon(Icons.radio_button_unchecked,
                size: 18, color: Colors.grey.shade400),
            const SizedBox(width: 10),
            Expanded(
              child: Text(r.revisi.poin,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            _chip(r.revisi.babPendek, const Color(0xFFEEF0FF), _primary),
            Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  // BARU - Chip kecil berwarna (dipakai untuk selisih hari, bab, jumlah revisi)
  Widget _chip(String teks, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(teks,
            style: TextStyle(
                fontSize: 10, color: fg, fontWeight: FontWeight.w600)),
      );

  // BARU - Kartu putih yang bisa diketuk (efek riak muncul di atas kartu)
  Widget _kartuKlik({required Widget child, required VoidCallback onTap}) =>
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      );

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
                onTap: _bukaStatusBab,
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