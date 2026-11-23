// =====================================================================
// FILE   : lib/screens/detail_log_screen.dart   (FILE BARU)
// FUNGSI : Halaman DETAIL satu log bimbingan. Dibuka saat kartu log di
//          halaman "Log Bimbingan" diketuk. Isinya:
//            1. Tanggal bimbingan + catatan hasil diskusi (teks LENGKAP)
//            2. Ringkasan progres revisi dari bimbingan ini (bar + angka)
//            3. DAFTAR REVISI yang lahir dari bimbingan ini, lengkap
//               dengan bab, status, dan penanda foto bukti. Tiap revisi
//               bisa diketuk untuk membuka Detail Revisi.
//            4. Tombol "Tambah Revisi dari Bimbingan Ini"
//          Halaman ini TIDAK menyimpan ke Firestore sendiri. Semua
//          pemuatan dan penyimpanan data dilakukan lewat fungsi
//          (callback) yang diberikan halaman Log Bimbingan.
// =====================================================================
import 'package:flutter/material.dart';
import 'detail_revisi_screen.dart';
import 'log_model.dart';
import 'revisi_model.dart';

/// Pembungkus satu revisi + id dokumennya di Firestore
/// (id dibutuhkan supaya perubahan bisa disimpan ke dokumen yang benar).
class RevisiItem {
  final String id;
  final Revisi revisi;
  const RevisiItem(this.id, this.revisi);
}

class DetailLogScreen extends StatefulWidget {
  /// Tanggal bimbingan
  final DateTime tanggal;

  /// Catatan hasil bimbingan (teks lengkap)
  final String catatan;

  /// Fungsi untuk memuat daftar revisi milik log ini (disediakan halaman Log Bimbingan)
  final Future<List<RevisiItem>> Function() muatRevisi;

  /// Fungsi untuk menambah revisi dari log ini (membuka form Tambah Revisi)
  final Future<void> Function() onTambahRevisi;

  /// Fungsi untuk menyimpan perubahan revisi (status / foto) ke Firestore
  final void Function(String id, Revisi baru) onUbahRevisi;

  const DetailLogScreen({
    super.key,
    required this.tanggal,
    required this.catatan,
    required this.muatRevisi,
    required this.onTambahRevisi,
    required this.onUbahRevisi,
  });

  @override
  State<DetailLogScreen> createState() => _DetailLogScreenState();
}

class _DetailLogScreenState extends State<DetailLogScreen> {
  static const _primary = Color(0xFF4338CA);

  List<RevisiItem> _items = []; // revisi milik log ini
  bool _memuat = true; // true selama revisi masih dimuat

  @override
  void initState() {
    super.initState();
    _muat();
  }

  // Muat (ulang) daftar revisi milik log ini
  Future<void> _muat() async {
    try {
      final hasil = await widget.muatRevisi();
      if (!mounted) return;
      setState(() {
        _items = hasil;
        _memuat = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _memuat = false);
    }
  }

  // Tambah revisi dari log ini, lalu muat ulang daftarnya
  Future<void> _tambahRevisi() async {
    await widget.onTambahRevisi();
    if (!mounted) return;
    await _muat();
  }

  // Buka Detail Revisi untuk revisi ke-i
  void _bukaRevisi(int i) {
    final item = _items[i];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailRevisiScreen(
          revisi: item.revisi,
          asalBimbingan: formatTanggal(widget.tanggal),
          onChanged: (baru) {
            widget.onUbahRevisi(item.id, baru); // simpan ke Firestore
            if (!mounted) return;
            setState(() => _items[i] = RevisiItem(item.id, baru));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _items.length;
    final selesai = _items.where((e) => e.revisi.selesai).length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Detail Bimbingan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4338CA), Color(0xFF5B52E0), Color(0xFFB8B4F5)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ---- Kartu 1: tanggal + catatan lengkap ----
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined,
                                  size: 16, color: _primary),
                              const SizedBox(width: 8),
                              Text(formatTanggal(widget.tanggal),
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text('Catatan Hasil Bimbingan',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade600)),
                          const SizedBox(height: 6),
                          SelectableText(widget.catatan,
                              style: const TextStyle(
                                  fontSize: 13.5, height: 1.5)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ---- Kartu 2: revisi dari bimbingan ini ----
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text('Revisi dari Bimbingan Ini',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800)),
                              ),
                              if (!_memuat && total > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF0FF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text('$selesai/$total selesai',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: _primary)),
                                ),
                            ],
                          ),
                          if (!_memuat && total > 0) ...[
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: selesai / total,
                                minHeight: 6,
                                backgroundColor: const Color(0xFFE5E7F5),
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          if (_memuat)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)),
                            )
                          else if (total == 0)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                  'Belum ada revisi dari bimbingan ini.',
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.grey.shade600)),
                            )
                          else
                            ...List.generate(total, (i) => _barisRevisi(i)),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: _tambahRevisi,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Tambah Revisi dari Bimbingan Ini',
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _primary,
                                side: const BorderSide(color: _primary),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Widget bantu ----------

  // Satu baris revisi: ikon status, poin, chip bab, penanda foto, badge status
  Widget _barisRevisi(int i) {
    final r = _items[i].revisi;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7F5)),
      ),
      child: InkWell(
        onTap: () => _bukaRevisi(i),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                r.selesai ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 20,
                color: r.selesai
                    ? const Color(0xFF10B981)
                    : Colors.grey.shade400,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.poin,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            height: 1.35)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF0FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(r.babPendek,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: _primary,
                                  fontWeight: FontWeight.w600)),
                        ),
                        if (r.fotoPath != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.photo_camera_outlined,
                              size: 13, color: Colors.grey.shade600),
                          const SizedBox(width: 3),
                          Text('1 foto',
                              style: TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.grey.shade600)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: r.selesai
                      ? const Color(0xFFE3F6EA)
                      : const Color(0xFFFDECEC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(r.selesai ? 'Selesai' : 'Belum',
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: r.selesai
                            ? const Color(0xFF1E9E55)
                            : const Color(0xFFE5484D))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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