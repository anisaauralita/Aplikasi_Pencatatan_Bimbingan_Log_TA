import 'package:flutter/material.dart';
import 'revisi_model.dart';

/// Hasil (lewat Navigator.pop): Revisi
class TambahRevisiScreen extends StatefulWidget {
  final List<String> opsiBab;

  const TambahRevisiScreen({super.key, this.opsiBab = opsiBabContoh});

  @override
  State<TambahRevisiScreen> createState() => _TambahRevisiScreenState();
}

class _TambahRevisiScreenState extends State<TambahRevisiScreen> {
  static const _primary = Color(0xFF4338CA);

  final _formKey = GlobalKey<FormState>();
  final _poinC = TextEditingController();
  String? _bab;

  @override
  void initState() {
    super.initState();
    if (widget.opsiBab.isNotEmpty) _bab = widget.opsiBab.first;
  }

  @override
  void dispose() {
    _poinC.dispose();
    super.dispose();
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Revisi(poin: _poinC.text.trim(), bab: _bab!),
    );
    // TODO: simpan juga ke database lewat database_helper.dart
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12,
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
        title: const Text('Tambah Revisi',
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
                    child: const Text('Simpan Revisi',
                        style: TextStyle(fontWeight: FontWeight.w600)),
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