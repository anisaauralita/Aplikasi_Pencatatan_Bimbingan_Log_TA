import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dipakai untuk Tambah Bab dan Edit Bab.
/// Hasil (lewat Navigator.pop): {'nomor': int, 'nama': String}
class TambahBabScreen extends StatefulWidget {
  /// Nomor bab yang sudah ada (untuk cek duplikat & teks petunjuk)
  final List<int> nomorTerpakai;
  final int? nomorAwal;
  final String? namaAwal;
  final bool isEdit;

  const TambahBabScreen({
    super.key,
    required this.nomorTerpakai,
    this.nomorAwal,
    this.namaAwal,
    this.isEdit = false,
  });

  @override
  State<TambahBabScreen> createState() => _TambahBabScreenState();
}

class _TambahBabScreenState extends State<TambahBabScreen> {
  static const _primary = Color(0xFF4338CA);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomorC;
  late final TextEditingController _namaC;

  @override
  void initState() {
    super.initState();
    final terpakai = widget.nomorTerpakai;
    final berikutnya = terpakai.isEmpty
        ? 1
        : terpakai.reduce((a, b) => a > b ? a : b) + 1;
    _nomorC = TextEditingController(
        text: (widget.nomorAwal ?? berikutnya).toString());
    _namaC = TextEditingController(text: widget.namaAwal ?? '');
  }

  @override
  void dispose() {
    _nomorC.dispose();
    _namaC.dispose();
    super.dispose();
  }

  String get _petunjuk {
    final t = widget.nomorTerpakai;
    if (t.isEmpty) return 'Belum ada bab.';
    final min = t.reduce((a, b) => a < b ? a : b);
    final max = t.reduce((a, b) => a > b ? a : b);
    return min == max
        ? 'Bab yang sudah ada: Bab $min.'
        : 'Bab yang sudah ada: Bab $min sampai Bab $max.';
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'nomor': int.parse(_nomorC.text.trim()),
      'nama': _namaC.text.trim(),
    });
    // TODO: simpan juga ke database lewat database_helper.dart
  }

  InputDecoration _dekor({String? hint, IconData? icon, String? prefix}) =>
      InputDecoration(
        hintText: hint,
        prefixText: prefix,
        prefixIcon: icon == null ? null : Icon(icon, size: 18),
        filled: true,
        fillColor: const Color(0xFFF4F6FA),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.black87)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.isEdit ? 'Edit Bab' : 'Tambah Bab',
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
                        _label('Nomor Bab'),
                        TextFormField(
                          controller: _nomorC,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: _dekor(
                              prefix: 'Bab ',
                              icon: Icons.format_list_numbered),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Nomor bab wajib diisi';
                            }
                            final n = int.parse(v.trim());
                            if (n < 1) return 'Nomor minimal 1';
                            final bentrok = widget.nomorTerpakai.contains(n) &&
                                n != widget.nomorAwal;
                            if (bentrok) return 'Bab $n sudah ada';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _label('Nama Bab'),
                        TextFormField(
                          controller: _namaC,
                          textCapitalization: TextCapitalization.words,
                          decoration: _dekor(
                              hint: 'Contoh: Lampiran',
                              icon: Icons.menu_book_outlined),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Nama bab wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 10),
                        Text(_petunjuk,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade600)),
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
                    child: Text(widget.isEdit ? 'Simpan Perubahan' : 'Simpan Bab',
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