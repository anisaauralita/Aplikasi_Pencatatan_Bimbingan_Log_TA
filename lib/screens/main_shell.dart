import 'package:flutter/material.dart';
import 'home_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  // Ganti _Placeholder dengan layar asli:
  // Bab -> Danis, Bimbingan & Revisi -> Hany
  Widget _page(int i) {
    switch (i) {
      case 0:
        return HomeScreen(key: UniqueKey()); // muat ulang tiap kembali ke Beranda
      case 1:
        return const _Placeholder('Profil TA & Bab');
      case 2:
        return const _Placeholder('Log Bimbingan');
      default:
        return const _Placeholder('Daftar Revisi');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _page(_index),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_view), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Bab'),
          NavigationDestination(icon: Icon(Icons.edit_note), label: 'Bimbingan'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), label: 'Revisi'),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String title;
  const _Placeholder(this.title);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Layar "$title" dikerjakan anggota lain')),
    );
  }
}