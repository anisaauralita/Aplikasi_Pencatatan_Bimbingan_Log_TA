import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'profil_ta_bab_screen.dart';
import 'log_bimbingan_screen.dart';
import 'daftar_revisi_screen.dart';

class MainShell extends StatefulWidget {
  /// Opsional. Kalau kosong, Beranda mengambil nama dari akun yang login.
  final String? nama;

  const MainShell({super.key, this.nama});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _primary = Color(0xFF4338CA);
  static const _pill = Color(0xFFE5E7FB);

  int _index = 0;

  static const _items = [
    (Icons.grid_view_rounded, 'Beranda'),
    (Icons.menu_book_outlined, 'Bab'),
    (Icons.edit_note, 'Bimbingan'),
    (Icons.assignment_outlined, 'Revisi'),
  ];

  Widget _page(int i) {
    switch (i) {
      case 0:
        return HomeScreen(
          key: UniqueKey(), // muat ulang tiap kembali ke Beranda
          onLihatStatusBab: () => setState(() => _index = 1),
        ); // muat ulang tiap kembali ke Beranda
      case 1:
        return const ProfilTaBabScreen();
      case 2:
        return const LogBimbinganScreen();
      default:
        return const DaftarRevisiScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _page(_index),
      bottomNavigationBar: Container(
        color: const Color(0xFFEEF0FB),
        child: SafeArea(
          top: false,
          // Di layar lebar, navigasi dibatasi 640 px dan dipusatkan
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: List.generate(_items.length, (i) {
                      final selected = i == _index;
                      final (icon, label) = _items[i];
                      return Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => setState(() => _index = i),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 52,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: selected ? _pill : Colors.transparent,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Icon(icon,
                                    size: 22,
                                    color: selected
                                        ? _primary
                                        : Colors.grey.shade500),
                              ),
                              const SizedBox(height: 3),
                              Text(label,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: selected
                                        ? _primary
                                        : Colors.grey.shade600,
                                  )),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}