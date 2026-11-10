import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/fs_helper.dart';
import 'bab_model.dart';
import 'status_bab_screen.dart';

/// Memuat daftar bab dari Firestore lalu membuka StatusBabScreen.
/// Dipakai supaya Beranda bisa langsung membuka halaman Status Bab.
class StatusBabLoader extends StatefulWidget {
  const StatusBabLoader({super.key});

  @override
  State<StatusBabLoader> createState() => _StatusBabLoaderState();
}

class _StatusBabLoaderState extends State<StatusBabLoader> {
  late final String _uid;
  DocumentReference<Map<String, dynamic>> get _base =>
      FirebaseFirestore.instance.collection('users').doc(_uid);

  List<Bab> _daftar = [];
  List<String> _ids = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _uid = context.read<AuthProvider>().currentUser!.id;
    _muat();
  }

  int _nomor(Bab b) {
    final m = RegExp(r'Bab\s*(\d+)').firstMatch(b.nama);
    return m == null ? 0 : int.parse(m.group(1)!);
  }

  Future<void> _muat() async {
    try {
      final hasil = await Future.wait([
        ambilCepat(_base.collection('chapters')),
        ambilCepat(_base.collection('revisions')),
      ]);
      final chapters = hasil[0];
      final revs = hasil[1];

      final items = <(String, Bab)>[];
      for (final c in chapters.docs) {
        final d = c.data();
        final mine =
            revs.docs.where((r) => r.data()['chapter_id'] == c.id).toList();
        final done = mine.where((r) => r.data()['is_done'] == true).length;
        final isDone = d['is_done'] == true;
        final status = isDone ? 'Selesai' : (done > 0 ? 'Berjalan' : 'Belum');
        items.add((
          c.id,
          Bab('${d['nomor'] ?? ''} - ${d['judul'] ?? ''}', status,
              revisiSelesai: done, revisiTotal: mine.length),
        ));
      }
      items.sort((a, b) => _nomor(a.$2).compareTo(_nomor(b.$2)));

      if (!mounted) return;
      setState(() {
        _ids = items.map((e) => e.$1).toList();
        _daftar = items.map((e) => e.$2).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // Simpan hanya bab yang toggle ACC-nya berubah (tanpa menunggu server)
  void _simpan(List<Bab> baru) {
    for (var i = 0; i < baru.length && i < _ids.length; i++) {
      if (baru[i].acc != _daftar[i].acc) {
        _base
            .collection('chapters')
            .doc(_ids[i])
            .update({'is_done': baru[i].acc}).catchError((e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gagal menyimpan status: $e')));
          }
        });
      }
    }
    _daftar = List.of(baru);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _error != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF4338CA),
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text('Status Bab',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ),
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4338CA), Color(0xFF5B52E0), Color(0xFFB8B4F5)],
            ),
          ),
          child: Center(
            child: _error != null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Gagal memuat data:\n$_error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white)),
                  )
                : const CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }
    return StatusBabScreen(daftarBab: _daftar, onChanged: _simpan);
  }
}