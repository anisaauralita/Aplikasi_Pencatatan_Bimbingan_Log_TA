import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/stats_service.dart';
import '../widgets/auth_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<DashboardStats> _future;

  @override
  void initState() {
    super.initState();
    final id = context.read<AuthProvider>().currentUser!.id;
    _future = StatsService().load(id);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final nama = auth.currentUser?.nama.split(' ').first ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFEEF0FB),
      body: FutureBuilder<DashboardStats>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final s = snap.data!;
          final persen = (s.progresTotal * 100).round();

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              // Header
              Container(
                padding: EdgeInsets.fromLTRB(
                    20, MediaQuery.of(context).padding.top + 12, 20, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Halo, $nama',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          const Text('Semangat mengerjakan tugas akhirmu',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.white70)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: () => auth.logout(),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Progres total
                    _card(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('STATUS PROGRES',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: kPrimary)),
                                const SizedBox(height: 4),
                                const Text('Progres Total Tugas Akhir',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(
                                    '${s.babSelesai} dari ${s.totalBab} bab selesai',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: CircularProgressIndicator(
                                    value: s.progresTotal,
                                    strokeWidth: 9,
                                    backgroundColor: const Color(0xFFE5E7F8),
                                    color: kPrimary,
                                  ),
                                ),
                                Text('$persen%',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Ringkasan
                    _card(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _stat(Icons.menu_book_outlined,
                              '${s.babSelesai}/${s.totalBab}', 'Bab'),
                          _stat(Icons.assignment_outlined,
                              '${s.revisiSelesai}/${s.totalRevisi}', 'Revisi'),
                          _stat(Icons.edit_note, '${s.totalLog}', 'Log'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Grafik per bab
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Progres per Bab',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          if (s.perBab.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text('Belum ada bab. Tambahkan di menu Bab.',
                                    style: TextStyle(color: Colors.black45)),
                              ),
                            )
                          else
                            SizedBox(
                              height: 150,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children:
                                    s.perBab.map((c) => _bar(c)).toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tombol ekspor (diisi Firda nanti)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: kPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Ekspor Kartu Bimbingan ke PDF'),
                        onPressed: () => ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                                content: Text('Fitur ekspor PDF segera hadir'))),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
                color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4))
          ],
        ),
        child: child,
      );

  Widget _stat(IconData icon, String value, String label) => Column(
        children: [
          Icon(icon, color: kPrimary),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ],
      );

  Widget _bar(ChapterProgress c) {
    final pct = (c.persen * 100).round();
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('$pct%',
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600, color: kPrimary)),
          const SizedBox(height: 4),
          Container(
            width: 26,
            height: 100 * c.persen + 3,
            decoration: BoxDecoration(
              color: c.persen == 0 ? const Color(0xFFE5E7F8) : kPrimary,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 6),
          Text(c.nomor,
              style: const TextStyle(fontSize: 10, color: Colors.black54)),
        ],
      ),
    );
  }
}