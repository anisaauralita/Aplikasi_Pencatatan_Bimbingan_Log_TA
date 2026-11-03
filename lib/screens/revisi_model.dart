/// Satu poin revisi dari dosen pembimbing.
class Revisi {
  final String poin; // contoh: 'Perbaiki sitasi sesuai format'
  final String bab; // contoh: 'Bab 2 - Tinjauan Pustaka'
  final bool selesai;
  final String? fotoPath; // lokasi foto bukti perbaikan (kalau ada)

  const Revisi({
    required this.poin,
    required this.bab,
    this.selesai = false,
    this.fotoPath,
  });

  /// 'Bab 2 - Tinjauan Pustaka' -> 'Bab 2'
  String get babPendek {
    final i = bab.indexOf(' - ');
    return i == -1 ? bab : bab.substring(0, i);
  }

  Revisi copyWith({bool? selesai, String? fotoPath}) => Revisi(
        poin: poin,
        bab: bab,
        selesai: selesai ?? this.selesai,
        fotoPath: fotoPath ?? this.fotoPath,
      );
}

/// Pilihan bab sementara. Nanti ambil dari daftar bab di database.
const opsiBabContoh = [
  'Bab 1 - Pendahuluan',
  'Bab 2 - Tinjauan Pustaka',
  'Bab 3 - Metodologi Penelitian',
  'Bab 4 - Hasil dan Pembahasan',
  'Bab 5 - Penutup',
];