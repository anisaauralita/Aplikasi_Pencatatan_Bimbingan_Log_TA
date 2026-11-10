// Import pustaka utama dari Flutter untuk komponen UI bertema Material Design
import 'package:flutter/material.dart';

// Import 4 halaman utama yang akan ditampilkan di dalam shell/navigasi bawah
import 'home_screen.dart';
import 'profil_ta_bab_screen.dart';
import 'log_bimbingan_screen.dart';
import 'daftar_revisi_screen.dart';

// Definisi kelas MainShell sebagai StatefulWidget karena status tab aktif dan versi UI selalu berubah saat digunakan
class MainShell extends StatefulWidget {
  /// Opsional. Kalau kosong, Beranda mengambil nama dari akun yang sedang login.
  final String? nama;

  // Konstruktor MainShell dengan opsional super key dan parameter nama
  const MainShell({super.key, this.nama});

  // Membuat instance State untuk mengelola tampilan dan logika navigasi MainShell
  @override
  State<MainShell> createState() => _MainShellState();
}

// Kelas State utama yang menyimpan indeks tab aktif dan mengontrol perpindahan halaman
class _MainShellState extends State<MainShell> {
  // Konstanta warna utama (Indigo pekat) untuk ikon/teks yang terpilih
  static const _primary = Color(0xFF4338CA);

  // Konstanta warna pill/kapsul soft untuk efek latar belakang ikon tab terpilih
  static const _pill = Color(0xFFE5E7FB);

  // Menandai indeks tab yang sedang aktif (0: Beranda, 1: Bab, 2: Bimbingan, 3: Revisi)
  int _index = 0;

  // List hitungan versi untuk tiap tab. Nilainya naik setiap tab ditekan agar widget memuat ulang data terbaru
  final List<int> _versi = [0, 0, 0, 0];

  // Daftar data konstan berisi pasangan (Icon, Label Teks) untuk masing-masing item Bottom Navigation
  static const _items = [
    (Icons.grid_view_rounded, 'Beranda'),
    (Icons.menu_book_outlined, 'Bab'),
    (Icons.edit_note, 'Bimbingan'),
    (Icons.assignment_outlined, 'Revisi'),
  ];

  // Fungsi untuk menangani perpindahan tab saat pengguna menekan tombol menu navigasi
  void _pindah(int i) {
    setState(() {
      // Jika menekan tab yang berbeda, tambah angka versi tab tersebut untuk memicu reload widget secara optimal
      if (i != _index) _versi[i]++;
      // Mengubah indeks tab aktif ke indeks tab yang baru dipilih
      _index = i;
    });
  }

  // Method build untuk menyusun tata letak utama layar
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body menggunakan IndexedStack agar keempat halaman tetap berada di memori tanpa mereset ulang status dari awal
      body: IndexedStack(
        index: _index, // Menentukan halaman mana yang sedang aktif ditampilkan
        children: [
          // Halaman 1: Beranda (HomeScreen) dengan Key dinamis berdasarkan versi reload
          HomeScreen(
            key: ValueKey('home-${_versi[0]}'),
            onLihatStatusBab: () => _pindah(1), // Callback jika tombol "Lihat Status Bab" di beranda ditekan
          ),
          // Halaman 2: Status Bab (ProfilTaBabScreen)
          ProfilTaBabScreen(key: ValueKey('bab-${_versi[1]}')),
          // Halaman 3: Log Bimbingan (LogBimbinganScreen)
          LogBimbinganScreen(key: ValueKey('log-${_versi[2]}')),
          // Halaman 4: Daftar Revisi (DaftarRevisiScreen)
          DaftarRevisiScreen(key: ValueKey('rev-${_versi[3]}')),
        ],
      ),

      // Bilah Navigasi Bawah (Bottom Navigation Bar)
      bottomNavigationBar: Container(
        color: const Color(0xFFEEF0FB), // Warna latar belakang di luar kapsul navigasi
        child: SafeArea(
          top: false, // Menghindari bagian atas, hanya mengamankan area bawah dari gesture bar HP
          // Mengamankan tampilan di layar lebar (Tablet/Desktop) agar navigasi dipusatkan dan tidak melar berlebihan
          child: Center(
            heightFactor: 1, // Mengikuti tinggi alami dari anak widget
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640), // Batas lebar maksimal bilah navigasi 640px
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10), // Padding luar kapsul navigasi
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // Padding dalam kapsul
                  decoration: BoxDecoration(
                    color: Colors.white, // Warna dasar kapsul navigasi (putih)
                    borderRadius: BorderRadius.circular(20), // Sudut kapsul membulat halus 20px
                    boxShadow: [
                      // Efek bayangan halus di bawah kapsul navigasi
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    // Menggenerasi 4 item tombol navigasi sesuai isi dari variabel _items
                    children: List.generate(_items.length, (i) {
                      // Mengecek apakah indeks iterasi saat ini sama dengan indeks tab yang sedang aktif
                      final selected = i == _index;
                      // Destructuring tuple untuk mengambil IconData dan String label
                      final (icon, label) = _items[i];
                      
                      return Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14), // Efek riak gelombang (ripple) membulat
                          onTap: () => _pindah(i), // Panggil fungsi pindah tab saat item diklik
                          child: Column(
                            mainAxisSize: MainAxisSize.min, // Ukuran kolom mengikuti tinggi kontennya
                            children: [
                              // Wadah ikon bertransisi halus (AnimatedContainer)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200), // Durasi animasi perpindahan 200ms
                                width: 52, // Lebar kapsul sorotan ikon
                                height: 30, // Tinggi kapsul sorotan ikon
                                decoration: BoxDecoration(
                                  // Memberi warna latar soft indigo jika terpilih, transparan jika tidak
                                  color: selected ? _pill : Colors.transparent,
                                  borderRadius: BorderRadius.circular(15), // Radius kapsul ikon 15px
                                ),
                                child: Icon(
                                  icon,
                                  size: 22,
                                  // Warna ikon menjadi indigo pekat jika dipilih, abu-abu jika tidak
                                  color: selected
                                      ? _primary
                                      : Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 3), // Spasi vertikal kecil antara ikon dan teks
                              // Label Teks Menu Navigasi
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  // Ketebalan font lebih tegas jika menu terpilih
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  // Warna teks menyesuaikan status terpilih
                                  color: selected
                                      ? _primary
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}