import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _nim = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _hide = true;

  @override
  void dispose() {
    _nama.dispose();
    _nim.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final error = await auth.register(
        _nama.text, _nim.text, _email.text, _pass.text);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pendaftaran berhasil')));
      Navigator.pop(context); // kembali ke Login
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().isLoading;
    return AuthBackground(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.school, size: 32, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Text('Buat Akun Baru',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 4),
          const Text('Daftar untuk mulai mencatat bimbingan tugas akhirmu',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 24),
          AuthCard(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  AuthField(
                    label: 'Nama Lengkap',
                    hint: 'Masukkan nama lengkap',
                    icon: Icons.person_outline,
                    controller: _nama,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nama wajib diisi'
                        : null,
                  ),
                  AuthField(
                    label: 'NIM',
                    hint: 'Nomor Induk Mahasiswa',
                    icon: Icons.badge_outlined,
                    controller: _nim,
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'NIM wajib diisi'
                        : null,
                  ),
                  AuthField(
                    label: 'Email',
                    hint: 'nama@mahasiswa.ac.id',
                    icon: Icons.mail_outline,
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Email wajib diisi';
                      }
                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                          .hasMatch(v.trim())) {
                        return 'Format email tidak valid';
                      }
                      return null;
                    },
                  ),
                  AuthField(
                    label: 'Kata Sandi',
                    hint: 'Buat kata sandi minimal 8 karakter',
                    icon: Icons.lock_outline,
                    controller: _pass,
                    obscure: _hide,
                    suffix: IconButton(
                      icon: Icon(
                          _hide ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 20),
                      onPressed: () => setState(() => _hide = !_hide),
                    ),
                    validator: (v) => (v == null || v.length < 8)
                        ? 'Kata sandi minimal 8 karakter'
                        : null,
                  ),
                  AuthButton(text: 'Daftar', loading: loading, onPressed: _submit),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Sudah punya akun? ',
                  style: TextStyle(fontSize: 13, color: Color(0xFF312E81))),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text('Masuk',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: kPrimary)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}