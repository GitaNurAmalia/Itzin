import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:itzin/core/theme.dart';
import 'package:itzin/core/supabase_config.dart';

enum UserType { siswa, guru }

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
  
  UserType _selectedUserType = UserType.siswa; 
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _currentAdminEmail = '';

  @override
  void initState() {
    super.initState();
    // Mengambil email admin yang sedang login saat ini
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && user.email != null) {
      _currentAdminEmail = user.email!;
    }
  }

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
      final nomorInduk = _nomorIndukController.text.trim();
      final kelas = _kelasController.text.trim();

      if (supabaseServiceRoleKey.isEmpty) {
        throw 'Kunci Rahasia Service Role belum diisi di supabase_config.dart!';
      }

      final supabaseAdmin = SupabaseClient(supabaseUrl, supabaseServiceRoleKey);

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
        final isSiswa = _selectedUserType == UserType.siswa;
        
        final Map<String, dynamic> profileData = {
          'id': newUserId,
          'nama_lengkap': nama,
          'nomor_induk': nomorInduk, 
          'role': isSiswa ? 'siswa' : 'admin', 
          'kelas': isSiswa ? kelas : null, 
        };

        await supabaseAdmin.from('profiles').upsert(profileData);

        _resetForm();
        if (!mounted) return;
        
        final labelSukses = isSiswa ? 'Siswa' : 'Guru (Admin)';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Akun $labelSukses $nama Berhasil Dibuat!'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dynamicTextColor = isDark ? Colors.white : Colors.black87;
    final dynamicSubtitleColor = isDark ? Colors.white70 : Colors.black54;
    final dynamicHintColor = isDark ? Colors.white38 : Colors.black38;
    final dynamicBorderColor = isDark ? Colors.white30 : Colors.black12;
    final dynamicFocusedBorderColor = isDark ? Colors.white : AppColors.primary;

    final isSiswa = _selectedUserType == UserType.siswa;

    // TENTUKAN EMAIL SUPER ADMIN UTAMA KAMU DI SINI
    // Silakan ganti 'admin@itzin.com' dengan email asli akun admin utama kamu
    final bool isSuperAdmin = _currentAdminEmail == 'admin@itzin.com';

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
                Expanded(
                  child: Text(
                    isSiswa 
                        ? 'Akun akan dibuat via Edge Function. Siswa dapat langsung login dengan email & password yang diisi.'
                        : 'Guru yang didaftarkan akan otomatis memiliki hak akses penuh sebagai Admin Piket.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // TOGGLE PILIHAN: Hanya muncul jika akun yang login adalah Super Admin
          if (isSuperAdmin) ...[
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<UserType>(
                segments: const <ButtonSegment<UserType>>[
                  ButtonSegment<UserType>(
                    value: UserType.siswa,
                    label: Text('Tambah Siswa'),
                    icon: Icon(Icons.school_outlined),
                  ),
                  ButtonSegment<UserType>(
                    value: UserType.guru,
                    label: Text('Tambah Guru'),
                    icon: Icon(Icons.supervisor_account_outlined),
                  ),
                ],
                selected: <UserType>{_selectedUserType},
                onSelectionChanged: (Set<UserType> newSelection) {
                  setState(() {
                    _selectedUserType = newSelection.first;
                  });
                },
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.primary,
                  selectedForegroundColor: Colors.white,
                  foregroundColor: dynamicTextColor,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Form card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Theme(
                data: Theme.of(context).copyWith(
                  primaryColor: dynamicFocusedBorderColor,
                  textTheme: Theme.of(context).textTheme.apply(
                    bodyColor: dynamicTextColor,
                    displayColor: dynamicTextColor,
                  ),
                  inputDecorationTheme: InputDecorationTheme(
                    labelStyle: TextStyle(color: dynamicSubtitleColor),
                    hintStyle: TextStyle(color: dynamicHintColor),
                    floatingLabelStyle: TextStyle(color: dynamicFocusedBorderColor),
                    suffixIconColor: dynamicSubtitleColor,
                    prefixIconColor: dynamicSubtitleColor,
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: dynamicBorderColor),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: dynamicFocusedBorderColor),
                    ),
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSiswa ? 'Data Akun Siswa' : 'Data Akun Guru / Admin',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: dynamicTextColor,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: TextStyle(color: dynamicTextColor),
                        decoration: InputDecoration(
                          labelText: isSiswa ? 'Email Siswa' : 'Email Guru',
                          prefixIcon: const Icon(Icons.email_outlined),
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
                        style: TextStyle(color: dynamicTextColor),
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

                      Text(
                        isSiswa ? 'Data Profil Siswa' : 'Data Profil Guru',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: dynamicTextColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Nama Lengkap
                      TextFormField(
                        controller: _namaController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        style: TextStyle(color: dynamicTextColor),
                        decoration: InputDecoration(
                          labelText: 'Nama Lengkap',
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Nama lengkap wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Nomor Induk (NIS / NIP)
                      TextFormField(
                        controller: _nomorIndukController,
                        keyboardType: TextInputType.number,
                        textInputAction: isSiswa ? TextInputAction.next : TextInputAction.done,
                        style: TextStyle(color: dynamicTextColor),
                        decoration: InputDecoration(
                          labelText: isSiswa ? 'Nomor Induk Siswa (NIS)' : 'Nomor Induk Pegawai (NIP)',
                          prefixIcon: const Icon(Icons.badge_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return isSiswa ? 'NIS wajib diisi' : 'NIP wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Kelas (Hanya untuk Siswa)
                      if (isSiswa) ...[
                        TextFormField(
                          controller: _kelasController,
                          textInputAction: TextInputAction.done,
                          textCapitalization: TextCapitalization.characters,
                          style: TextStyle(color: dynamicTextColor),
                          decoration: const InputDecoration(
                            labelText: 'Kelas',
                            prefixIcon: Icon(Icons.class_outlined),
                            hintText: 'Contoh: X RPL 1',
                          ),
                          validator: (v) {
                            if (isSiswa && (v == null || v.trim().isEmpty)) {
                              return 'Kelas wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),
                      ] else ...[
                        const SizedBox(height: 14),
                      ],

                      // Tombol Submit
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Icon(isSiswa ? Icons.person_add_rounded : Icons.admin_panel_settings_rounded),
                        label: Text(
                          _isLoading 
                              ? 'Membuat akun...' 
                              : (isSiswa ? 'Buat Akun Siswa' : 'Buat Akun Guru (Admin)'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}