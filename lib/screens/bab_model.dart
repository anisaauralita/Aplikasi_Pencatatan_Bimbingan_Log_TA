/// Data satu bab TA.
/// status: 'Selesai' | 'Berjalan' | 'Belum'
/// revisiSelesai / revisiTotal diambil dari data Revisi (tab Revisi).
class Bab {
  final String nama; // contoh: 'Bab 1 - Pendahuluan'
  final String status;
  final int revisiSelesai;
  final int revisiTotal;

  const Bab(
    this.nama,
    this.status, {
    this.revisiSelesai = 0,
    this.revisiTotal = 0,
  });

  bool get acc => status == 'Selesai';

  /// Menghitung progres revisi (0.0 - 1.0)
  /// - Jika status ACC ('Selesai'), otomatis 1.0 (100%).
  /// - Jika belum ada revisi sama sekali (revisiTotal == 0), bernilai 0.0 (0%).
  /// - Jika ada revisi, dihitung dari revisiSelesai / revisiTotal.
  double get progresRevisi {
    if (acc) return 1.0;
    if (revisiTotal == 0) return 0.0;
    return (revisiSelesai / revisiTotal).clamp(0.0, 1.0);
  }

  Bab copyWith({
    String? nama,
    String? status,
    int? revisiSelesai,
    int? revisiTotal,
  }) =>
      Bab(
        nama ?? this.nama,
        status ?? this.status,
        revisiSelesai: revisiSelesai ?? this.revisiSelesai,
        revisiTotal: revisiTotal ?? this.revisiTotal,
      );
}