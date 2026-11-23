import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'revisi_model.dart';

const List<String> opsiBabContoh = ['Bab 1', 'Bab 2', 'Bab 3', 'Bab 4', 'Bab 5'];

/// Hasil (lewat Navigator.pop): Revisi
class TambahRevisiScreen extends StatefulWidget {
  final bool isEdit;
  final List<String> opsiBab;
  final String? poinAwal;
  final String? babAwal;

  // Daftar log bimbingan untuk dropdown "Dari Bimbingan" (kosong = dropdown disembunyikan)
  final List<OpsiLog> opsiLog;
  // Id log yang terpilih di awal (dari tombol "+ Revisi" di kartu log, atau saat edit)
  final String? logIdAwal;

  // BARU: path foto bukti yang sudah ada (saat edit)
  final String? fotoAwal;

  const TambahRevisiScreen({
    super.key,
    this.isEdit = false,
    this.opsiBab = opsiBabContoh,
    this.poinAwal,
    this.babAwal,
    this.opsiLog = const [],
    this.logIdAwal,
    this.fotoAwal,
  });

  @override
  State<TambahRevisiScreen> createState() => _TambahRevisiScreenState();
}

class _TambahRevisiScreenState extends State<TambahRevisiScreen> {
  static const _primary = Color(0xFF4338CA);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _poinC;
  String? _bab;
  String? _logId; // log bimbingan asal (opsional)

  // BARU: foto bukti perbaikan (opsional)
  final ImagePicker _picker = ImagePicker();
  String? _foto;

  @override
  void initState() {
    super.initState();
    // Isi otomatis teks jika dalam mode edit
    _poinC = TextEditingController(text: widget.poinAwal ?? '');

    // Atur bab terpilih (prioritas: babAwal -> opsi pertama -> null)
    if (widget.babAwal != null && widget.opsiBab.contains(widget.babAwal)) {
      _bab = widget.babAwal;
    } else if (widget.opsiBab.isNotEmpty) {
      _bab = widget.opsiBab.first;
    }

    // Pilih log awal hanya jika id-nya memang ada di daftar pilihan
    if (widget.logIdAwal != null &&
        widget.opsiLog.any((o) => o.id == widget.logIdAwal)) {
      _logId = widget.logIdAwal;
    }

    // BARU: foto awal (mode edit)
    _foto = widget.fotoAwal;
  }

  @override
  void dispose() {
    _poinC.dispose();
    super.dispose();
  }

  // BARU: ambil foto dari kamera / galeri
  Future<void> _ambilFoto(ImageSource sumber) async {
    try {
      final x = await _picker.pickImage(
        source: sumber,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (x == null || !mounted) return;
      setState(() => _foto = x.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil foto: $e')),
      );
    }
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Revisi(
        poin: _poinC.text.trim(),
        bab: _bab!,
        logId: _logId,
        fotoPath: _foto, // BARU
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black87)),
      );

  // BARU: tampilan gambar (web memakai network, Android memakai file)
  Widget _gambar(String path) {
    final err = Center(
      child: Text('Foto tidak bisa ditampilkan',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
    );
    if (kIsWeb) {
      return Image.network(path,
          fit: BoxFit.cover, errorBuilder: (_, __, ___) => err);
    }
    return Image.file(File(path),
        fit: BoxFit.cover, errorBuilder: (_, __, ___) => err);
  }

  // BARU: kotak pratinjau foto bukti
  Widget _areaFoto() => Container(
        height: 180,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFC7CAF5)),
        ),
        child: _foto == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined,
                      size: 36, color: Colors.grey.shade400),
                  const SizedBox(height: 6),
                  Text('Belum ada foto bukti',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                ],
              )
            : _gambar(_foto!),
      );

  // BARU: tombol Kamera / Galeri
  Widget _tombolFoto(IconData icon, String label, ImageSource sumber) =>
      OutlinedButton.icon(
        onPressed: () => _ambilFoto(sumber),
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: _primary,
          side: const BorderSide(color: _primary),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.isEdit ? 'Edit Revisi' : 'Tambah Revisi',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Bab Terkait'),
                        DropdownButtonFormField<String>(
                          value: _bab,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.menu_book_outlined,
                                size: 18),
                            filled: true,
                            fillColor: const Color(0xFFF4F6FA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: widget.opsiBab
                              .map((b) => DropdownMenuItem(
                                    value: b,
                                    child: Text(b,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 14)),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _bab = v),
                          validator: (v) =>
                              v == null ? 'Pilih bab terkait' : null,
                        ),
                        // Dropdown opsional "Dari Bimbingan"
                        if (widget.opsiLog.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _label('Dari Bimbingan (opsional)'),
                          DropdownButtonFormField<String?>(
                            value: _logId,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.event_note_outlined,
                                  size: 18),
                              filled: true,
                              fillColor: const Color(0xFFF4F6FA),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Tidak dari bimbingan',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 14)),
                              ),
                              ...widget.opsiLog.map((o) =>
                                  DropdownMenuItem<String?>(
                                    value: o.id,
                                    child: Text('Bimbingan ${o.label}',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 14)),
                                  )),
                            ],
                            onChanged: (v) => setState(() => _logId = v),
                          ),
                        ],
                        const SizedBox(height: 16),
                        _label('Poin Revisi'),
                        TextFormField(
                          controller: _poinC,
                          minLines: 6,
                          maxLines: 10,
                          decoration: InputDecoration(
                            hintText: 'Tuliskan poin revisi dari dosen...',
                            hintStyle: TextStyle(
                                fontSize: 13, color: Colors.grey.shade500),
                            filled: true,
                            fillColor: const Color(0xFFF4F6FA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Poin revisi tidak boleh kosong'
                              : null,
                        ),
                        // BARU: upload foto bukti perbaikan (opsional)
                        const SizedBox(height: 16),
                        _label('Foto Bukti Perbaikan (opsional)'),
                        _areaFoto(),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                                child: _tombolFoto(Icons.photo_camera_outlined,
                                    'Kamera', ImageSource.camera)),
                            const SizedBox(width: 10),
                            Expanded(
                                child: _tombolFoto(Icons.photo_library_outlined,
                                    'Galeri', ImageSource.gallery)),
                          ],
                        ),
                        if (_foto != null)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => setState(() => _foto = null),
                              icon: const Icon(Icons.delete_outline,
                                  size: 16, color: Colors.red),
                              label: const Text('Hapus foto',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.red)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _simpan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(widget.isEdit ? 'Simpan Perubahan' : 'Simpan Revisi',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withAlpha(190),
                      foregroundColor: _primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Batal',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}