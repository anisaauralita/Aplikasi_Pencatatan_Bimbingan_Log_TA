// =====================================================================
// FILE   : lib/screens/detail_revisi_screen.dart
// FUNGSI : Halaman DETAIL satu revisi. Dibuka saat kartu revisi di
//          halaman "Daftar Revisi" diketuk. Di sini mahasiswa bisa:
//            1. Melihat poin revisi (deskripsi) dari dosen
//            2. Melihat informasi lengkap: bab, asal bimbingan, status
//            3. Melihat FOTO BUKTI perbaikan (ketuk untuk memperbesar)
//            4. Tombol "Edit Revisi" (ubah poin, bab, dan foto bukti)
//               bila halaman pemanggil menyediakannya
//            5. Menandai revisi Selesai / Belum Selesai
//          Setiap perubahan dikirim ke halaman daftar lewat callback
//          onChanged, lalu halaman daftar yang menyimpannya ke Firestore.
// =====================================================================
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'revisi_model.dart';

class DetailRevisiScreen extends StatefulWidget {
  /// Data revisi yang sedang dilihat
  final Revisi revisi;

  /// Tanggal bimbingan asal revisi (teks siap tampil, null = tidak dari bimbingan)
  final String? asalBimbingan;

  /// BARU: alternatif asalBimbingan berupa fungsi, supaya ikut berubah setelah revisi diedit
  final String? Function(Revisi)? asalDari;

  /// BARU: dipanggil saat tombol "Edit Revisi" ditekan; mengembalikan revisi hasil edit
  /// (null = dibatalkan). Jika null, tombol Edit tidak ditampilkan.
  final Future<Revisi?> Function(Revisi)? onEdit;

  /// Dipanggil setiap kali revisi berubah (foto ditambah / status diganti)
  final void Function(Revisi) onChanged;

  const DetailRevisiScreen({
    super.key,
    required this.revisi,
    required this.onChanged,
    this.asalBimbingan,
    this.asalDari,
    this.onEdit,
  });

  @override
  State<DetailRevisiScreen> createState() => _DetailRevisiScreenState();
}

class _DetailRevisiScreenState extends State<DetailRevisiScreen> {
  static const _primary = Color(0xFF4338CA);

  late Revisi _revisi; // Salinan revisi yang bisa berubah di halaman ini

  @override
  void initState() {
    super.initState();
    _revisi = widget.revisi;
  }

  // Teks asal bimbingan (diambil dari fungsi asalDari jika ada)
  String? get _asal =>
      widget.asalDari != null ? widget.asalDari!(_revisi) : widget.asalBimbingan;

  // Buka form edit (poin, bab, foto), lalu perbarui tampilan dengan hasilnya
  Future<void> _edit() async {
    final baru = await widget.onEdit!(_revisi);
    if (baru == null || !mounted) return;
    setState(() => _revisi = baru);
  }

  // Ubah status Selesai <-> Belum. Syarat: harus ada foto bukti dulu
  void _toggleSelesai() {
    final akanSelesai = !_revisi.selesai;
    if (akanSelesai && _revisi.fotoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.onEdit != null
                ? 'Tambahkan foto bukti dulu lewat tombol Edit Revisi.'
                : 'Tambahkan foto bukti dulu: buka Daftar Revisi, lalu tekan Edit.')),
      );
      return;
    }
    setState(() => _revisi = _revisi.copyWith(selesai: akanSelesai));
    widget.onChanged(_revisi);
    if (akanSelesai) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revisi ditandai selesai.')),
      );
      Navigator.pop(context);
    }
  }

  // BARU: buka foto dalam layar penuh, bisa di-zoom dengan dua jari
  void _perbesarFoto() {
    final path = _revisi.fotoPath;
    if (path == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Foto Bukti Perbaikan',
                style: TextStyle(fontSize: 16)),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 5,
              child: _gambar(path, BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selesai = _revisi.selesai;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Detail Revisi',
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ---- Kartu 1: deskripsi (poin revisi) + status ----
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            child: Text('Deskripsi Revisi',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey)),
                          ),
                          _badge(selesai),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_revisi.poin,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              height: 1.4)),
                      const SizedBox(height: 10),
                      _chipBab(_revisi.babPendek),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ---- Kartu 2 (BARU): informasi lengkap revisi ----
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Informasi Revisi',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      _baris(Icons.menu_book_outlined, 'Bab terkait',
                          _revisi.bab),
                      _baris(
                          Icons.event_note_outlined,
                          'Asal bimbingan',
                          _asal ?? 'Tidak dari bimbingan tertentu'),
                      _baris(
                          selesai
                              ? Icons.check_circle_outline
                              : Icons.pending_outlined,
                          'Status',
                          selesai ? 'Selesai dikerjakan' : 'Belum selesai'),
                      _baris(
                          Icons.photo_camera_outlined,
                          'Bukti perbaikan',
                          _revisi.fotoPath == null
                              ? 'Belum ada foto'
                              : '1 foto terlampir'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ---- Kartu 3: foto bukti + tombol kamera/galeri ----
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Foto Bukti Perbaikan',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      _areaFoto(),
                      if (widget.onEdit != null) ...[
                        const SizedBox(height: 8),
                        Text('Untuk mengganti foto, gunakan tombol Edit Revisi.',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ---- Tombol Edit Revisi (hanya jika disediakan pemanggil) ----
                if (widget.onEdit != null) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _edit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit Revisi',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white.withAlpha(220),
                        foregroundColor: _primary,
                        side: const BorderSide(color: _primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // ---- Tombol tandai selesai / belum selesai ----
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: selesai
                      ? OutlinedButton.icon(
                          onPressed: _toggleSelesai,
                          icon: const Icon(Icons.undo, size: 18),
                          label: const Text('Tandai Belum Selesai'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white.withAlpha(220),
                            foregroundColor: _primary,
                            side: const BorderSide(color: _primary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: _toggleSelesai,
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Tandai Selesai',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                Text(
                  selesai
                      ? 'Revisi ini sudah selesai'
                      : 'Status revisi akan berubah menjadi Selesai',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Widget bantu ----------

  // BARU: satu baris informasi (ikon + label kecil + nilai)
  Widget _baris(IconData icon, String label, String nilai) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: _primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 10.5, color: Colors.grey.shade600)),
                  const SizedBox(height: 1),
                  Text(nilai,
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      );

  // BARU: menampilkan gambar. Web memakai network, Android memakai file
  Widget _gambar(String path, BoxFit fit) {
    final gagal = _placeholderFoto('Foto tidak dapat ditampilkan');
    if (kIsWeb) {
      return Image.network(path,
          fit: fit, errorBuilder: (_, __, ___) => gagal);
    }
    return Image.file(File(path),
        fit: fit, errorBuilder: (_, __, ___) => gagal);
  }

  // Kotak foto bukti; kalau ada foto, bisa diketuk untuk diperbesar
  Widget _areaFoto() {
    final path = _revisi.fotoPath;
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primary.withAlpha(90), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: path == null
          ? _placeholderFoto('Belum ada foto bukti')
          : InkWell(
              onTap: _perbesarFoto,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _gambar(path, BoxFit.cover),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.zoom_in, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Ketuk untuk memperbesar',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _placeholderFoto(String teks) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 36, color: Colors.grey.shade400),
          const SizedBox(height: 6),
          Text(teks,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      );

  Widget _badge(bool selesai) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: selesai ? const Color(0xFFE3F6EA) : const Color(0xFFFDECEC),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(selesai ? 'Selesai' : 'Belum',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selesai
                    ? const Color(0xFF1E9E55)
                    : const Color(0xFFE5484D))),
      );

  Widget _chipBab(String teks) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF0FF),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(teks,
            style: const TextStyle(
                fontSize: 10, color: _primary, fontWeight: FontWeight.w600)),
      );

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