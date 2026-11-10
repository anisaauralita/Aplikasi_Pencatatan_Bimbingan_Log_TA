// Import pustaka UI utama dari Flutter
import 'package:flutter/material.dart';
// Import package pihak ketiga untuk menangani papan/canvas tanda tangan digital
import 'package:signature/signature.dart';

// Definisi kelas EksporPdfScreen sebagai StatefulWidget karena halaman memiliki status interaktif (input & coretan)
class EksporPdfScreen extends StatefulWidget {
  // Konstruktor konstan dengan key opsional untuk identifikasi widget
  const EksporPdfScreen({super.key});

  // Membuat instance state untuk mengelola state halaman ini
  @override
  State<EksporPdfScreen> createState() => _EksporPdfScreenState();
}

// Kelas State utama yang mengelola logika dan tampilan layar ekspor PDF
class _EksporPdfScreenState extends State<EksporPdfScreen> {
  // Controller untuk membaca dan mengontrol isi teks inputan "Catatan Tambahan"
  final TextEditingController _catatanController = TextEditingController();

  // Controller untuk mengontrol aktivitas coretan canvas tanda tangan
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3, // Ketebalan garis pena saat menggoreskan tanda tangan
    penColor: Colors.black, // Warna tinta tanda tangan (hitam)
    exportBackgroundColor: Colors.transparent, // Warna latar transparan saat hasil tanda tangan diekspor
  );

  // Method lifecycle yang dipanggil ketika widget dihancurkan/ditutup untuk membebaskan memori
  @override
  void dispose() {
    _catatanController.dispose(); // Membersihkan memory controller catatan
    _signatureController.dispose(); // Membersihkan memory controller tanda tangan
    super.dispose(); // Memanggil dispose bawaan dari superclass State
  }

  // Method build yang mengembalikan struktur hirarki UI utama layar
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar: Bilah navigasi bagian atas layar
      appBar: AppBar(
        backgroundColor: const Color(0xFF4338CA), // Warna latar belakang AppBar (Indigo/Biru Tua)
        elevation: 0, // Menghilangkan bayangan di bawah AppBar agar rata dengan background
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // Tombol panah kembali berwarna putih
          onPressed: () => Navigator.pop(context), // Aksi untuk kembali ke layar sebelumnya
        ),
        title: const Text(
          'Ekspor PDF', // Judul halaman
          style: TextStyle(
            color: Colors.white, // Warna teks putih
            fontWeight: FontWeight.bold, // Teks dicetak tebal
            fontSize: 18, // Ukuran font 18px
          ),
        ),
      ),
      // Body: Area utama isi halaman
      body: Container(
        // Menambahkan dekorasi gradien warna pada background layar
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, // Gradien dimulai dari atas
            end: Alignment.bottomCenter, // Gradien berakhir di bawah
            colors: [
              Color(0xFF4338CA), // Warna atas: Indigo pekat
              Color(0xFF5B52E0), // Warna tengah: Ungu kebiruan
              Color(0xFFB8B4F5), // Warna bawah: Ungu muda/lembut
            ],
          ),
        ),
        // SafeArea memastikan konten tidak tertutup notch atau bar navigasi bawaan sistem HP
        child: SafeArea(
          // SingleChildScrollView agar seluruh konten di dalamnya bisa di-scroll jika layar kecil
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Padding luar 16px kiri-kanan & 8px atas-bawah
            child: Column(
              children: [
                // 1. Memanggil widget kartu ringkasan statistik (Log, Revisi, Foto Bukti)
                _buildStatistikCard(),
                const SizedBox(height: 14), // Jarak spasi vertikal 14px

                // 2. Memanggil widget kartu form input catatan dan canvas tanda tangan
                _buildCatatanDanTandaTanganCard(),
                const SizedBox(height: 14), // Jarak spasi vertikal 14px

                // 3. Memanggil widget kartu pratinjau dokumen PDF kartu bimbingan
                _buildPratinjauKartuCard(),
                const SizedBox(height: 16), // Jarak spasi vertikal 16px

                // 4. Tombol Utama: Ekspor ke PDF
                SizedBox(
                  width: double.infinity, // Lebar tombol memenuhi area yang tersedia
                  height: 48, // Tinggi tombol 48px
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Tempat menaruh logika proses ekspor file ke PDF
                    },
                    icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white), // Ikon dokumen PDF
                    label: const Text(
                      'Ekspor ke PDF', // Label teks tombol
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4338CA), // Warna background tombol (Indigo)
                      foregroundColor: Colors.white, // Warna splash/efek tombol saat ditekan
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // Sudut melengkung 12px
                      ),
                      elevation: 2, // Efek bayangan tipis 2px
                    ),
                  ),
                ),
                const SizedBox(height: 10), // Jarak spasi vertikal 10px

                // 5. Tombol Sekunder: Batal
                SizedBox(
                  width: double.infinity, // Lebar tombol memenuhi area
                  height: 48, // Tinggi tombol 48px
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context), // Kembali ke halaman sebelumnya saat ditekan
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withAlpha(200), // Background putih agak semi-transparan
                      foregroundColor: const Color(0xFF4338CA), // Warna teks tombol (Indigo)
                      elevation: 0, // Tanpa bayangan
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // Sudut melengkung 12px
                      ),
                    ),
                    child: const Text(
                      'Batal', // Teks label batal
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16), // Spasi penutup bagian bawah
              ],
            ),
          ),
        ),
      ),

      // Menampilkan Bottom Navigation Bar di bagian paling bawah halaman
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // --- SUB-WIDGET HELPER ---

  /// Function Pembantu Widget 1: Kartu Rincian Statistik (Log Bimbingan, Revisi, Foto Bukti)
  Widget _buildStatistikCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12), // Inner padding kartu
      decoration: BoxDecoration(
        color: Colors.white, // Warna latar belakang putih
        borderRadius: BorderRadius.circular(18), // Sudut membulat 18px
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround, // Menyebar 3 item secara merata
        children: [
          // Item statistik 1: Log Bimbingan
          _buildStatItem(Icons.reorder_rounded, '9', 'Log Bimbingan'),
          // Garis pembatas vertikal 1
          Container(height: 35, width: 1, color: Colors.grey.shade300),
          // Item statistik 2: Revisi
          _buildStatItem(Icons.assignment_outlined, '12', 'Revisi'),
          // Garis pembatas vertikal 2
          Container(height: 35, width: 1, color: Colors.grey.shade300),
          // Item statistik 3: Foto Bukti
          _buildStatItem(Icons.image_outlined, '7', 'Foto Bukti'),
        ],
      ),
    );
  }

  // Sub-item per kategori statistik (Icon, Angka, dan Label)
  Widget _buildStatItem(IconData icon, String count, String label) {
    return Column(
      children: [
        // Wadah lingkaran/kotak tempat ikon ditempatkan
        Container(
          padding: const EdgeInsets.all(8), // Inner padding ikon 8px
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF), // Latar ikon biru soft
            borderRadius: BorderRadius.circular(10), // Radius sudut 10px
          ),
          child: Icon(icon, color: const Color(0xFF4338CA), size: 20), // Ikon berwarna indigo
        ),
        const SizedBox(height: 6), // Jarak antara ikon dan angka
        Text(
          count, // Menampilkan angka total statistik
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        Text(
          label, // Menampilkan label deskripsi di bawah angka
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  /// Function Pembantu Widget 2: Form Catatan Tambahan & Canvas Tanda Tangan Digital
  Widget _buildCatatanDanTandaTanganCard() {
    return Container(
      padding: const EdgeInsets.all(16), // Padding dalam 16px
      decoration: BoxDecoration(
        color: Colors.white, // Latar belakang putih
        borderRadius: BorderRadius.circular(18), // Membulat 18px
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Rata kiri untuk teks judul section
        children: [
          const Text(
            'CATATAN & TANDA TANGAN', // Judul section
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.5, // Spasi antar huruf agak renggang
            ),
          ),
          const SizedBox(height: 12), // Spasi vertikal

          // Textfield tempat user mengetik catatan opsional
          TextField(
            controller: _catatanController, // Menghubungkan ke controller catatan
            decoration: InputDecoration(
              hintText: 'Catatan tambahan (opsional)', // Teks hint pembantu
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              filled: true,
              fillColor: const Color(0xFFF8FAFC), // Warna isi background input abu-abu sangat muda
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), // Inner padding teks
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200), // Border saat normal
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200), // Border saat aktif
              ),
            ),
          ),
          const SizedBox(height: 12), // Spasi vertikal

          // Wadah Kotak Canvas Tanda Tangan
          Container(
            height: 100, // Tinggi area tanda tangan 100px
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC), // Warna latar kotak
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300, // Border keliling abu-abu
                style: BorderStyle.solid,
              ),
            ),
            child: Stack(
              children: [
                // Lapisan 1: Widget Signature (Area coretan tanda tangan)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12), // Memotong garis keluar agar tidak melewati radius
                  child: Signature(
                    controller: _signatureController, // Menghubungkan ke controller signature
                    height: 100,
                    backgroundColor: Colors.transparent, // Background kanvas bening
                  ),
                ),
                // Lapisan 2: Teks placeholder petunjuk di tengah area kanvas
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit, size: 16, color: Colors.grey.shade400), // Ikon pensil
                      const SizedBox(width: 6),
                      Text(
                        'Tanda tangan di sini', // Teks petunjuk instruksi
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                // Lapisan 3: Tombol "Hapus" coretan tanda tangan di pojok kanan atas
                Positioned(
                  top: 6,
                  right: 6,
                  child: OutlinedButton(
                    onPressed: () => _signatureController.clear(), // Menghapus/reset coretan kanvas
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2), // Size kompak
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: BorderSide(color: Colors.grey.shade300), // Border tombol tipis
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text('Hapus', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Function Pembantu Widget 3: Card Pratinjau Lembar Dokumen Kartu Bimbingan PDF
  Widget _buildPratinjauKartuCard() {
    return Container(
      padding: const EdgeInsets.all(16), // Inner padding 16px
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PRATINJAU KARTU BIMBINGAN', // Judul section pratinjau
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          // Miniatur Kertas Dokumen Fisik
          Container(
            padding: const EdgeInsets.all(12), // Inner padding lembar kertas
            decoration: BoxDecoration(
              color: Colors.white, // Kertas berwarna putih
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300), // Garis pinggir kertas
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10), // Efek bayangan halus agar berkesan 3D seperti kertas
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Miniatur Kertas: Judul Dokumen
                const Center(
                  child: Text(
                    'KARTU BIMBINGAN TUGAS AKHIR',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 8),
                // Informasi Mahasiswa
                const Text('Nama: Siti', style: TextStyle(fontSize: 10, color: Colors.black87)),
                const SizedBox(height: 2),
                const Text(
                  'Judul: Aplikasi Absensi Pegawai Menggunakan Fitur Geofencing Berbasis Android',
                  style: TextStyle(fontSize: 9, color: Colors.black54),
                ),
                const SizedBox(height: 8),

                // Mini Baris Header Tabel Log Bimbingan
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF), // Background header tabel
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  child: const Row(
                    children: [
                      SizedBox(width: 70, child: Text('Tanggal', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
                      Expanded(child: Text('Catatan', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                // Baris-baris data pada tabel pratinjau
                _buildTableRow('01 Okt 2026', 'Diskusi judul & ruang lingkup penelitian.'),
                _buildTableRow('08 Okt 2026', 'Revisi rumusan masalah & Bab 1.'),
                _buildTableRow('15 Okt 2026', 'Perbaiki sitasi format APA & Bab 2.'),
                const SizedBox(height: 12),

                // Footer Miniatur Kertas Dokumen
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Halaman 1 dari 1', style: TextStyle(fontSize: 8, color: Colors.grey)),
                    Text('Format Resmi LogTA', style: TextStyle(fontSize: 8, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Function pembantu untuk merender setiap baris data tabel pratinjau dokumen
  Widget _buildTableRow(String tanggal, String catatan) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70, // Lebar kolom tanggal 70px
            child: Text(tanggal, style: const TextStyle(fontSize: 8.5, color: Colors.black87)),
          ),
          Expanded(
            child: Text(catatan, style: const TextStyle(fontSize: 8.5, color: Colors.black87)), // Kolom catatan fleksibel
          ),
        ],
      ),
    );
  }

  /// Function Pembantu Widget 4: Bottom Navigation Bar Aplikasi
  Widget _buildBottomNav() {
    return Container(
      height: 65, // Tinggi bar navigasi bawah 65px
      decoration: const BoxDecoration(
        color: Colors.white, // Background putih
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20), // Sudut kiri atas membulat 20px
          topRight: Radius.circular(20), // Sudut kanan atas membulat 20px
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround, // Menyebar menu navigasi merata
        children: [
          _buildNavItem(Icons.grid_view_rounded, 'Beranda', isSelected: true), // Menu aktif
          _buildNavItem(Icons.menu_book_outlined, 'Bab'),
          _buildNavItem(Icons.reorder_rounded, 'Bimbingan'),
          _buildNavItem(Icons.assignment_outlined, 'Revisi'),
        ],
      ),
    );
  }

  // Function pembantu untuk membuat ikon item navigasi di bar bawah
  Widget _buildNavItem(IconData icon, String label, {bool isSelected = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Wadah sorotan indikator menu jika statusnya sedang terpilih (isSelected = true)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEEF2FF) : Colors.transparent, // Highlight latar jika aktif
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isSelected ? const Color(0xFF4338CA) : Colors.grey, // Warna ikon indigo jika aktif, grey jika biasa
            size: 22,
          ),
        ),
        Text(
          label, // Teks nama menu navigasi
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF4338CA) : Colors.grey, // Warna teks indigo jika aktif
          ),
        ),
      ],
    );
  }
}