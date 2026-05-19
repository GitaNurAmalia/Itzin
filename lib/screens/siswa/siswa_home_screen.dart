import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:itzin/services/auth_service.dart';
import 'package:itzin/screens/siswa/izin_form_screen.dart';
import 'package:itzin/screens/siswa/riwayat_izin_screen.dart';
import 'package:itzin/screens/profile/profile_screen.dart';
import 'package:itzin/core/theme.dart';

class SiswaHomeScreen extends StatefulWidget {
  const SiswaHomeScreen({super.key});

  @override
  State<SiswaHomeScreen> createState() => _SiswaHomeScreenState();
}

class _SiswaHomeScreenState extends State<SiswaHomeScreen> {
  late final AuthService _authService;
  int _currentIndex = 0;
  Map<String, dynamic>? _profile;

  late final List<Widget> _screens = [
    const IzinFormScreen(),
    const RiwayatIzinScreen(),
    ProfileScreen(profileData: _profile),
  ];

  @override
  void initState() {
    super.initState();
    _authService = AuthService(supabase: Supabase.instance.client);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _authService.getProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _screens[2] = ProfileScreen(profileData: _profile);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('itzin', style: TextStyle(color: Colors.white)),
            if (_profile != null)
              Text(
                _profile!['nama_lengkap'] ?? '',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline_rounded),
              activeIcon: Icon(Icons.add_circle_rounded),
              label: 'Buat Izin',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_outlined),
              activeIcon: Icon(Icons.list_alt_rounded),
              label: 'Riwayat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
