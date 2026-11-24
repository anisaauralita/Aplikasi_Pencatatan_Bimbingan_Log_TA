// =====================================================================
// FILE   : lib/screens/profil_mahasiswa_screen.dart
// FUNGSI : Halaman PROFIL MAHASISWA.
//          - Menampilkan foto, nama, NIM, email, judul TA, dan dosen.
//          - Mahasiswa dapat mengubah: foto, nama, program studi,
//            angkatan, dan nomor HP.
//          - NIM dan email hanya ditampilkan (tidak bisa diubah).
//          - Judul TA dan dosen diubah lewat menu Bab (halaman Edit Judul TA).
//          - Foto profil disimpan LOKAL di HP (folder dokumen aplikasi),
//            bukan di Firebase Storage. Data teks disimpan di dokumen
//            users/{uid} pada Firestore.
//          Paket yang dipakai: image_picker, path_provider, cloud_firestore, provider.
// =====================================================================
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class ProfilMahasiswaScreen extends StatefulWidget {
  const ProfilMahasiswaScreen({super.key});

  @override
  State<ProfilMahasiswaScreen> createState() => _ProfilMahasiswaScreenState();
}

class _ProfilMahasiswaScreenState extends State<ProfilMahasiswaScreen> {
  static const _primary = Color(0xFF4338CA);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaC;
  late final TextEditingController _prodiC;
  late final TextEditingController _angkatanC;
  late final TextEditingController _hpC;

  late final String _uid;
  late final String _nim;
  late final String _email;

  String? _foto; // path foto yang sedang dipilih
  String? _fotoAwal; // path foto yang tersimpan sebelum halaman dibuka
  String _judul = '-';
  String _dosen = '-';
  bool _menyimpan = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().currentUser!;
    _uid = u.id;
    _nim = u.nim;
    _email = u.email;
    _namaC = TextEditingController(text: u.nama);
    _prodiC = TextEditingController(text: u.prodi);
    _angkatanC = TextEditingController(text: u.angkatan);
    _hpC = TextEditingController(text: u.noHp);
    _foto = u.fotoPath;
    _fotoAwal = u.fotoPath;
    _muatTa();
  }

  @override
  void dispose() {
    _namaC.dispose();
    _prodiC.dispose();
    _angkatanC.dispose();
    _hpC.dispose();
    super.dispose();
  }

  // Ambil judul TA dan dosen dari profil (cache dulu, lalu server maksimal 6 detik)
  Future<void> _muatTa() async {
    final ref = FirebaseFirestore.instance.collection('users').doc(_uid);
    try {
      DocumentSnapshot<Map<String, dynamic>>? doc;
      try {
        final c = await ref.get(const GetOptions(source: Source.cache));
        if (c.exists) doc = c;
      } catch (_) {}
      doc ??= await ref.get().timeout(const Duration(seconds: 6));
      final x = doc.data();
      if (!mounted) return;
      setState(() {
        _judul = (x?['judul_ta'] ?? '').toString().trim();
        _dosen = (x?['dosen'] ?? '').toString().trim();
      });
    } catch (_) {
      // gagal memuat: biarkan tampil '-'
    }
  }

  void _pesan(String teks) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  // True jika file foto ada dan bisa ditampilkan
  bool _fotoAda(String? path) {
    if (kIsWeb || path == null || path.isEmpty) return false;
    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }

  // Menu pilihan sumber foto
  void _menuFoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Ambil foto'),
              onTap: () {
                Navigator.pop(ctx);
                _pilihFoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari galeri'),
              onTap: () {
                Navigator.pop(ctx);
                _pilihFoto(ImageSource.gallery);
              },
            ),
            if (_foto != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Hapus foto',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _foto = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  // Ambil foto, lalu salin ke folder dokumen aplikasi agar tidak hilang
  Future<void> _pilihFoto(ImageSource sumber) async {
    try {
      final x = await ImagePicker()
          .pickImage(source: sumber, maxWidth: 800, imageQuality: 85);
      if (x == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final tujuan =
          '${dir.path}/foto_profil_${_uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(x.path).copy(tujuan);
      if (!mounted) return;
      setState(() => _foto = tujuan);
    } catch (e) {
      _pesan('Gagal memilih foto: $e');
    }
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    setState(() => _menyimpan = true);
    final error = await auth.updateProfil(
      nama: _namaC.text.trim(),
      prodi: _prodiC.text.trim(),
      angkatan: _angkatanC.text.trim(),
      noHp: _hpC.text.trim(),
      fotoPath: _foto,
    );
    if (!mounted) return;
    setState(() => _menyimpan = false);
    if (error != null) {
      _pesan(error);
      return;
    }
    // Hapus file foto lama yang sudah tidak dipakai
    final lama = _fotoAwal;
    if (lama != null && lama != _foto && lama.contains('foto_profil_')) {
      try {
        File(lama).deleteSync();
      } catch (_) {}
    }
    _pesan('Profil berhasil disimpan');
    Navigator.pop(context);
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

  Widget _judulKartu(String teks) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(teks,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.5)),
      );

  // Foto bulat dengan tombol kamera kecil di pojok
  Widget _avatar() {
    final nama = _namaC.text.trim();
    final inisial = nama.isEmpty ? '?' : nama[0].toUpperCase();
    return GestureDetector(
      onTap: _menuFoto,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 52,
              backgroundColor: const Color(0xFFEEF0FF),
              backgroundImage:
                  _fotoAda(_foto) ? FileImage(File(_foto!)) : null,
              child: _fotoAda(_foto)
                  ? null
                  : Text(inisial,
                      style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: _primary)),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                  color: _primary, shape: BoxShape.circle),
              child: const Icon(Icons.photo_camera,
                  size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Satu baris info yang tidak bisa diubah
  Widget _info(IconData icon, String label, String nilai) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: _primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 10.5, color: Colors.grey.shade600)),
                  const SizedBox(height: 2),
                  Text(nilai.isEmpty ? '-' : nilai,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Profil Mahasiswa',
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
                    child: Column(
                      children: [
                        _avatar(),
                        const SizedBox(height: 6),
                        const Text('Ketuk foto untuk mengubah',
                            style:
                                TextStyle(fontSize: 11, color: Colors.white70)),
                        const SizedBox(height: 16),

                        // ===== Kartu data diri (bisa diubah) =====
                        Container(
                          width: double.infinity,
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
                                _judulKartu('DATA DIRI'),
                                _label('Nama Lengkap'),
                                TextFormField(
                                  controller: _namaC,
                                  textCapitalization: TextCapitalization.words,
                                  onChanged: (_) => setState(() {}),
                                  decoration: _dekor(
                                      hint: 'Nama lengkap',
                                      icon: Icons.person_outline),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Nama tidak boleh kosong'
                                          : null,
                                ),
                                const SizedBox(height: 14),
                                _label('Program Studi'),
                                TextFormField(
                                  controller: _prodiC,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: _dekor(
                                      hint: 'Contoh: Teknik Informatika',
                                      icon: Icons.school_outlined),
                                ),
                                const SizedBox(height: 14),
                                _label('Angkatan'),
                                TextFormField(
                                  controller: _angkatanC,
                                  keyboardType: TextInputType.number,
                                  maxLength: 4,
                                  decoration: _dekor(
                                          hint: 'Contoh: 2023',
                                          icon: Icons.calendar_today_outlined)
                                      .copyWith(counterText: ''),
                                  validator: (v) {
                                    final t = (v ?? '').trim();
                                    if (t.isEmpty) return null;
                                    return RegExp(r'^\d{4}$').hasMatch(t)
                                        ? null
                                        : 'Isi 4 digit tahun, misal 2023';
                                  },
                                ),
                                const SizedBox(height: 14),
                                _label('Nomor HP'),
                                TextFormField(
                                  controller: _hpC,
                                  keyboardType: TextInputType.phone,
                                  decoration: _dekor(
                                      hint: 'Contoh: 081234567890',
                                      icon: Icons.phone_outlined),
                                  validator: (v) {
                                    final t = (v ?? '')
                                        .replaceAll(RegExp(r'[\s-]'), '');
                                    if (t.isEmpty) return null;
                                    return RegExp(r'^\+?\d{8,15}$').hasMatch(t)
                                        ? null
                                        : 'Nomor HP tidak valid';
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ===== Kartu akun & tugas akhir (hanya tampil) =====
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _judulKartu('AKUN & TUGAS AKHIR'),
                              _info(Icons.badge_outlined, 'NIM', _nim),
                              const Divider(height: 8),
                              _info(Icons.mail_outline, 'Email', _email),
                              const Divider(height: 8),
                              _info(Icons.menu_book_outlined,
                                  'Judul Tugas Akhir', _judul),
                              const Divider(height: 8),
                              _info(Icons.person_pin_outlined,
                                  'Dosen Pembimbing', _dosen),
                              const SizedBox(height: 6),
                              Text(
                                  'Judul TA dan dosen diubah lewat kartu judul di Beranda.',
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _menyimpan ? null : _simpan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _primary.withAlpha(150),
                      disabledForegroundColor: Colors.white70,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _menyimpan
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Simpan',
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