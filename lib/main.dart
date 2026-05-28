import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:itzin/core/supabase_config.dart';
import 'package:itzin/core/theme.dart';
import 'package:itzin/screens/auth/splash_screen.dart';
import 'package:itzin/screens/auth/login_screen.dart';
import 'package:itzin/screens/siswa/siswa_home_screen.dart';
import 'package:itzin/screens/admin/admin_home_screen.dart';

// 1. Buat global notifier untuk mendeteksi perubahan tema aplikasi
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

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
    // 2. Bungkus dengan ValueListenableBuilder agar aplikasi merender ulang saat tema berubah
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'itzin — Aplikasi Izin Siswa',
          debugShowCheckedModeBanner: false,
          
          // 3. Daftarkan konfigurasi tema dari theme.dart kamu
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode, // Ini yang mengontrol mode aktif saat ini
          
          initialRoute: '/',
          routes: {
            '/': (_) => const SplashScreen(),
            '/login': (_) => const LoginScreen(),
            '/siswa': (_) => const SiswaHomeScreen(),
            '/admin': (_) => const AdminHomeScreen(),
          },
        );
      },
    );
  }
}