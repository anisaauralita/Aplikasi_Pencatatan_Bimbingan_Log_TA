/// Model data untuk merepresentasikan satu poin revisi dari dosen pembimbing.
class Revisi {
  // Properti utama untuk menyimpan isi deskripsi poin revisi (misal: 'Perbaiki sitasi sesuai format APA')
  final String poin;

  // Properti untuk menyimpan bab terkait (misal: 'Bab 2 - Tinjauan Pustaka')
  final String bab;

  // Status penyelesaian revisi (true = selesai, false = belum selesai), nilai bawaan adalah false
  final bool selesai;

  // Path/lokasi file foto bukti perbaikan dari gallery/kamera (opsional, bisa null jika belum ada foto)
  final String? fotoPath;

  // Konstruktor konstan untuk inisialisasi objek Revisi
  const Revisi({
    required this.poin, // Parameter wajib diisi
    required this.bab, // Parameter wajib diisi
    this.selesai = false, // Parameter opsional dengan nilai default false
    this.fotoPath, // Parameter opsional (boleh null)
  });

  /// Getter untuk mengembalikan nama bab singkat tanpa deskripsi tambahan.
  /// Contoh: 'Bab 2 - Tinjauan Pustaka' akan dipotong menjadi 'Bab 2'.
  String get babPendek {
    final i = bab.indexOf(' - '); // Mencari posisi indeks tanda pemisah ' - '
    return i == -1 ? bab : bab.substring(0, i); // Jika ada ' - ', potong string dari indeks 0 hingga sebelum ' - '
  }

  /// Method copyWith digunakan untuk membuat salinan objek Revisi baru
  /// dengan beberapa properti yang diperbarui tanpa merubah properti lainnya.
  Revisi copyWith({
    String? poin, // Parameter opsional untuk memperbarui poin revisi
    String? bab, // Parameter opsional untuk memperbarui bab
    bool? selesai, // Parameter opsional untuk memperbarui status selesai
    String? fotoPath, // Parameter opsional untuk memperbarui foto bukti
  }) =>
      Revisi(
        // Jika parameter baru dikirim (tidak null), gunakan nilai baru. Jika null, gunakan nilai lama (this).
        poin: poin ?? this.poin,
        bab: bab ?? this.bab,
        selesai: selesai ?? this.selesai,
        fotoPath: fotoPath ?? this.fotoPath,
      );
}

/// Constant List pilihan bab sementara (dummy data) sebelum dihubungkan dengan database SQLite/Firestore.
const opsiBabContoh = [
  'Bab 1 - Pendahuluan',
  'Bab 2 - Tinjauan Pustaka',
  'Bab 3 - Metodologi Penelitian',
  'Bab 4 - Hasil dan Pembahasan',
  'Bab 5 - Penutup',
];