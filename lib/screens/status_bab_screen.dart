import 'package:flutter/material.dart';
import 'bab_model.dart';

class StatusBabScreen extends StatefulWidget {
  final List<Bab> daftarBab;

  /// Dipanggil setiap kali ada perubahan (toggle ACC)
  final void Function(List<Bab>) onChanged;

  const StatusBabScreen({
    super.key,
    required this.daftarBab,
    required this.onChanged,
  });

  @override
  State<StatusBabScreen> createState() => _StatusBabScreenState();
}

class _StatusBabScreenState extends State<StatusBabScreen> {
  static const _primary = Color(0xFF4338CA);
  static const _hijau = Color(0xFF10B981);

  late List<Bab> _daftar;

  @override
  void initState() {
    super.initState();
    _daftar = List.of(widget.daftarBab);
  }

  void _toggleAcc(int i, bool nilai) {
    final b = _daftar[i];
    final statusBaru =
        nilai ? 'Selesai' : (b.revisiSelesai > 0 ? 'Berjalan' : 'Belum');
    setState(() => _daftar[i] = b.copyWith(status: statusBaru));
    widget.onChanged(List.of(_daftar));
    // TODO: simpan status ke database
  }

  @override
  Widget build(BuildContext context) {
    final total = _daftar.length;
    final selesai = _daftar.where((b) => b.acc).length;
    final progres = total == 0 ? 0.0 : selesai / total;
    final persen = (progres * 100).round();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Status Bab',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
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
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _kartuProgresTotal(persen, selesai, total, progres),
              const SizedBox(height: 12),
              ...List.generate(total, (i) => _kartuBab(i)),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Kartu progres total ----------
  Widget _kartuProgresTotal(int persen, int selesai, int total, double progres) {
    return _card(
      child: Row(
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 58,
                  height: 58,
                  child: CircularProgressIndicator(
                    value: progres,
                    strokeWidth: 6,
                    color: _primary,
                    backgroundColor: const Color(0xFFEEF0FF),
                  ),
                ),
                Text('$persen%',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Progres Total TA',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF0FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('Dihitung otomatis',
                          style: TextStyle(
                              fontSize: 9,
                              color: _primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('$selesai dari $total bab selesai',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                _bar(progres, _primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Kartu per bab ----------
  Widget _kartuBab(int i) {
    final b = _daftar[i];
    final p = b.progresRevisi;
    final penuh = p >= 1.0;
    final warnaBar = penuh ? _hijau : _primary;
    final warnaPersen = penuh
        ? _hijau
        : (p > 0 ? _primary : Colors.grey.shade500);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _card(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(b.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 6),
                Text('Selesai (ACC)',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: b.acc,
                    activeColor: Colors.white,
                    activeTrackColor: _primary,
                    onChanged: (v) => _toggleAcc(i, v),
                  ),
                ),
              ],
            ),
            _bar(p, warnaBar),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${b.revisiSelesai} dari ${b.revisiTotal} revisi selesai',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                Text('${(p * 100).round()}%',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: warnaPersen)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Widget bantu ----------
  Widget _bar(double value, Color color) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: value,
          minHeight: 5,
          color: color,
          backgroundColor: const Color(0xFFEEF0F5),
        ),
      );

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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