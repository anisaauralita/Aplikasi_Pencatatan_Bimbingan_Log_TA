/// Data satu bab TA.
/// status: 'Selesai' | 'Berjalan' | 'Belum'
/// revisiSelesai / revisiTotal nanti diambil dari data Revisi (tab Revisi).
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

  /// 0.0 - 1.0
double get progresRevisi => acc
    ? 1.0
    : (revisiTotal == 0 ? 0 : (revisiSelesai / revisiTotal).clamp(0.0, 1.0));
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