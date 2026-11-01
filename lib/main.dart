import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/main_shell.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..init(),
      child: const LogTAApp(),
    ),
  );
}

class LogTAApp extends StatelessWidget {
  const LogTAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LogTA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF4338CA),
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          if (!auth.isInitialized) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          return auth.isLoggedIn ? const MainShell() : const LoginScreen();
        },
      ),
    );
  }
}