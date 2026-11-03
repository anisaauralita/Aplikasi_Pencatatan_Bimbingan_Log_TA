import 'package:flutter/material.dart';

class EditJudulTaScreen extends StatefulWidget {
  final String judul;
  final String dosen;

  const EditJudulTaScreen({
    super.key,
    required this.judul,
    required this.dosen,
  });

  @override
  State<EditJudulTaScreen> createState() => _EditJudulTaScreenState();
}

class _EditJudulTaScreenState extends State<EditJudulTaScreen> {
  static const _primary = Color(0xFF4338CA);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _judulC;
  late final TextEditingController _dosenC;

  @override
  void initState() {
    super.initState();
    _judulC = TextEditingController(text: widget.judul);
    _dosenC = TextEditingController(text: widget.dosen);
  }

  @override
  void dispose() {
    _judulC.dispose();
    _dosenC.dispose();
    super.dispose();
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'judul': _judulC.text.trim(),
      'dosen': _dosenC.text.trim(),
    });
    // TODO: simpan juga ke database lewat database_helper.dart
  }

  InputDecoration _dekor({String? hint, IconData? icon}) => InputDecoration(
        hintText: hint,
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
        title: const Text('Edit Judul TA',
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
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
                            _label('Judul Tugas Akhir'),
                            TextFormField(
                              controller: _judulC,
                              minLines: 3,
                              maxLines: 5,
                              decoration: _dekor(hint: 'Masukkan judul TA'),
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Judul tidak boleh kosong'
                                      : null,
                            ),
                            const SizedBox(height: 16),
                            _label('Dosen Pembimbing'),
                            TextFormField(
                              controller: _dosenC,
                              decoration: _dekor(
                                  hint: 'Nama dosen pembimbing',
                                  icon: Icons.person_outline),
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Dosen tidak boleh kosong'
                                      : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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
                    child: const Text('Simpan',
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