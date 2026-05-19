import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:itzin/services/auth_service.dart';
import 'package:itzin/screens/admin/admin_izin_list_screen.dart';
import 'package:itzin/screens/admin/admin_siswa_list_screen.dart';
import 'package:itzin/screens/admin/admin_tambah_siswa_screen.dart';
import 'package:itzin/screens/profile/profile_screen.dart';
import 'package:itzin/core/theme.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late final AuthService _authService;
  int _currentIndex = 0;
  Map<String, dynamic>? _profile;

  late final List<Widget> _screens = [
    const AdminIzinListScreen(),
    const AdminSiswaListScreen(),
    const AdminTambahSiswaScreen(),
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
        _screens[3] = ProfileScreen(profileData: _profile);
      });
    }
  }

  // _handleLogout dipindahkan ke ProfileScreen

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('itzin Admin'),
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
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'ADMIN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment_rounded),
              label: 'Daftar Izin',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_outlined),
              activeIcon: Icon(Icons.people_alt_rounded),
              label: 'Daftar Siswa',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_add_outlined),
              activeIcon: Icon(Icons.person_add_rounded),
              label: 'Tambah Siswa',
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
