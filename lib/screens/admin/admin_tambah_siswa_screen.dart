import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:itzin/core/theme.dart';
import 'package:itzin/core/supabase_config.dart';

class AdminTambahSiswaScreen extends StatefulWidget {
  const AdminTambahSiswaScreen({super.key});

  @override
  State<AdminTambahSiswaScreen> createState() => _AdminTambahSiswaScreenState();
}

class _AdminTambahSiswaScreenState extends State<AdminTambahSiswaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _namaController = TextEditingController();
  final _nomorIndukController = TextEditingController();
  final _kelasController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _namaController.dispose();
    _nomorIndukController.dispose();
    _kelasController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final nama = _namaController.text.trim();
      final nis = _nomorIndukController.text.trim();
      final kelas = _kelasController.text.trim();

      // BACKDOOR: Kita buat Supabase khusus Admin API yang pake kunci Service Role
      if (supabaseServiceRoleKey.isEmpty) {
        throw 'Kunci Rahasia Service Role belum diisi di supabase_config.dart!';
      }

      final supabaseAdmin = SupabaseClient(supabaseUrl, supabaseServiceRoleKey);

      // 1. Buat User baru (bypass RLS dan tidak mengeluarkan sesi admin)
      final userRes = await supabaseAdmin.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          emailConfirm: true,
          userMetadata: {'nama_lengkap': nama},
        ),
      );

      final newUserId = userRes.user?.id;
      if (newUserId != null) {
        // 2. Isi data pendaftaran lainnya langsung via UPSERT untuk menghindari Crash Trigger Database
        await supabaseAdmin.from('profiles').upsert({
          'id': newUserId,
          'nama_lengkap': nama,
          'nomor_induk': nis,
          'kelas': kelas,
          'role': 'siswa'
        });

        _resetForm();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Akun $nama Berhasil Dibuat (Jalur Backdoor)'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mendaftar: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _emailController.clear();
    _passwordController.clear();
    _namaController.clear();
    _nomorIndukController.clear();
    _kelasController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Akun akan dibuat via Edge Function. Siswa dapat langsung login dengan email & password yang diisi.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Form card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Data Akun Siswa',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email Siswa',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email wajib diisi';
                        }
                        if (!v.contains('@')) return 'Format email tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Password wajib diisi';
                        }
                        if (v.length < 6) {
                          return 'Password minimal 6 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Data Profil Siswa',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nama Lengkap
                    TextFormField(
                      controller: _namaController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Nama lengkap wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Nomor Induk
                    TextFormField(
                      controller: _nomorIndukController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nomor Induk Siswa (NIS)',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Nomor induk wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Kelas
                    TextFormField(
                      controller: _kelasController,
                      textInputAction: TextInputAction.done,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Kelas',
                        prefixIcon: Icon(Icons.class_outlined),
                        hintText: 'Contoh: X RPL 1',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Kelas wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // Submit
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleSubmit,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.person_add_rounded),
                      label: Text(
                          _isLoading ? 'Membuat akun...' : 'Buat Akun Siswa'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
