import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:itzin/core/supabase_config.dart';
import 'package:itzin/core/theme.dart';
import 'package:itzin/screens/auth/splash_screen.dart';
import 'package:itzin/screens/auth/login_screen.dart';
import 'package:itzin/screens/siswa/siswa_home_screen.dart';
import 'package:itzin/screens/admin/admin_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // Initialize locale data untuk format tanggal bahasa Indonesia
  await initializeDateFormatting('id_ID', null);

  runApp(const IzinApp());
}

class IzinApp extends StatelessWidget {
  const IzinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'itzin — Aplikasi Izin Siswa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/siswa': (_) => const SiswaHomeScreen(),
        '/admin': (_) => const AdminHomeScreen(),
      },
    );
  }
}
