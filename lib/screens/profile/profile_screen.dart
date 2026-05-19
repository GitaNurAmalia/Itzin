import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:itzin/services/auth_service.dart';
import 'package:itzin/core/theme.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? profileData;

  const ProfileScreen({super.key, this.profileData});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AuthService _authService;
  User? _currentUser;
  Map<String, dynamic>? _liveProfile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(supabase: Supabase.instance.client);
    _currentUser = _authService.currentUser;
    _liveProfile = widget.profileData;

    if (_liveProfile == null) {
      _fetchMyProfile();
    }
  }

  Future<void> _fetchMyProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final data = await _authService.getProfile();
      if (mounted && data != null) {
        setState(() {
          _liveProfile = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error Load Profil:\n$e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _handleLogout() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Icon(Icons.logout_rounded,
                  size: 40, color: AppColors.error),
              const SizedBox(height: 12),
              const Text(
                'Keluar dari Akun?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Yakin ingin keluar dari aplikasi?',
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _authService.logout();
                        if (mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              '/login', (route) => false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Keluar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isAdmin = _authService.isAdmin;
    final name = _liveProfile?['nama_lengkap'] ?? 'Pengguna';
    final nis = _liveProfile?['nomor_induk'] ?? '-';
    final kelas = _liveProfile?['kelas'] ?? '-';
    final email = _currentUser?.email ?? '-';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color:
                  isAdmin ? AppColors.statusMenungguBg : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isAdmin ? 'Administrator' : 'Siswa',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    isAdmin ? AppColors.statusMenungguText : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Info Cards
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.divider),
            ),
            child: Column(
              children: [
                _buildInfoRow(Icons.person_outline, 'Nama Lengkap', name),
                const Divider(height: 1, color: AppColors.divider),
                _buildInfoRow(Icons.email_outlined, 'Email', email),
                if (!isAdmin) ...[
                  const Divider(height: 1, color: AppColors.divider),
                  _buildInfoRow(Icons.badge_outlined, 'Nomor Induk', nis),
                  const Divider(height: 1, color: AppColors.divider),
                  _buildInfoRow(Icons.class_outlined, 'Kelas', kelas),
                ],
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Logout Button
          OutlinedButton.icon(
            onPressed: _handleLogout,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Keluar dari Akun'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
