import 'package:flutter/material.dart';
import 'log_model.dart';

/// Dipakai untuk Tambah Log dan Edit Log.
/// Hasil (lewat Navigator.pop): LogBimbingan
class TambahLogScreen extends StatefulWidget {
  final DateTime? tanggalAwal;
  final String? catatanAwal;
  final bool isEdit;

  const TambahLogScreen({
    super.key,
    this.tanggalAwal,
    this.catatanAwal,
    this.isEdit = false,
  });

  @override
  State<TambahLogScreen> createState() => _TambahLogScreenState();
}

class _TambahLogScreenState extends State<TambahLogScreen> {
  static const _primary = Color(0xFF4338CA);

  final _formKey = GlobalKey<FormState>();
  late DateTime _tanggal;
  late final TextEditingController _catatanC;

  @override
  void initState() {
    super.initState();
    _tanggal = widget.tanggalAwal ?? DateTime.now();
    _catatanC = TextEditingController(text: widget.catatanAwal ?? '');
  }

  @override
  void dispose() {
    _catatanC.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final hasil = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (hasil != null) setState(() => _tanggal = hasil);
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      LogBimbingan(
        DateTime(_tanggal.year, _tanggal.month, _tanggal.day),
        _catatanC.text.trim(),
      ),
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
        title: Text(widget.isEdit ? 'Edit Log Bimbingan' : 'Tambah Log Bimbingan',
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
                        _label('Tanggal Bimbingan'),
                        InkWell(
                          onTap: _pilihTanggal,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F6FA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined,
                                    size: 18, color: _primary),
                                const SizedBox(width: 10),
                                Text(formatTanggal(_tanggal),
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _label('Catatan Hasil Bimbingan'),
                        TextFormField(
                          controller: _catatanC,
                          minLines: 8,
                          maxLines: 12,
                          decoration: InputDecoration(
                            hintText:
                                'Tuliskan poin hasil diskusi dengan dosen pembimbing...',
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
                              ? 'Catatan tidak boleh kosong'
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
                    child: Text(
                        widget.isEdit ? 'Simpan Perubahan' : 'Simpan Log',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white.withAlpha(220),
                      foregroundColor: _primary,
                      side: const BorderSide(color: _primary, width: 1.5),
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