/// Satu catatan bimbingan.
class LogBimbingan {
  final DateTime tanggal;
  final String catatan;

  const LogBimbingan(this.tanggal, this.catatan);
}

const _hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
const _bulan = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

/// Contoh hasil: 'Kamis, 29 Okt 2026'
String formatTanggal(DateTime d) =>
    '${_hari[d.weekday - 1]}, ${d.day} ${_bulan[d.month - 1]} ${d.year}';