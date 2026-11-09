import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'revisi_model.dart';

class DetailRevisiScreen extends StatefulWidget {
  final Revisi revisi;

  /// Dipanggil setiap kali revisi berubah (foto ditambah / status diganti)
  final void Function(Revisi) onChanged;

  const DetailRevisiScreen({
    super.key,
    required this.revisi,
    required this.onChanged,
  });

  @override
  State<DetailRevisiScreen> createState() => _DetailRevisiScreenState();
}

class _DetailRevisiScreenState extends State<DetailRevisiScreen> {
  static const _primary = Color(0xFF4338CA);

  final _picker = ImagePicker();
  late Revisi _revisi;

  @override
  void initState() {
    super.initState();
    _revisi = widget.revisi;
  }

  Future<void> _ambilFoto(ImageSource sumber) async {
    try {
      final hasil = await _picker.pickImage(source: sumber, imageQuality: 80);
      if (hasil == null || !mounted) return;
      setState(() => _revisi = _revisi.copyWith(fotoPath: hasil.path));
      widget.onChanged(_revisi);
      // TODO: simpan path foto ke database
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengambil foto. Cek izin kamera.')),
      );
    }
  }

  void _toggleSelesai() {
    final akanSelesai = !_revisi.selesai;
    if (akanSelesai && _revisi.fotoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tambahkan foto bukti perbaikan dulu.')),
      );
      return;
    }
    setState(() => _revisi = _revisi.copyWith(selesai: akanSelesai));
    widget.onChanged(_revisi);
    // TODO: simpan status ke database
    if (akanSelesai) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revisi ditandai selesai.')),
      );
      Navigator.pop(context);
    }
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
                // Kartu info revisi
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(_revisi.poin,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    height: 1.3)),
                          ),
                          const SizedBox(width: 8),
                          _badge(selesai),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _chipBab(_revisi.babPendek),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Kartu foto bukti
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Foto Bukti Perbaikan',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      _areaFoto(),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _tombolFoto(Icons.photo_camera_outlined,
                                'Kamera', () => _ambilFoto(ImageSource.camera)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _tombolFoto(Icons.photo_outlined, 'Galeri',
                                () => _ambilFoto(ImageSource.gallery)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Tombol tandai selesai
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
  Widget _areaFoto() {
    final path = _revisi.fotoPath;
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primary.withAlpha(90), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: path == null
          ? _placeholderFoto('Belum ada foto bukti')
          : Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _placeholderFoto('Foto tidak dapat ditampilkan'),
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

  Widget _tombolFoto(IconData icon, String label, VoidCallback onTap) =>
      OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          foregroundColor: _primary,
          side: const BorderSide(color: _primary),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
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