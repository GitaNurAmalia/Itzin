import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:itzin/core/theme.dart';

class AdminSiswaListScreen extends StatefulWidget {
  const AdminSiswaListScreen({super.key});

  @override
  State<AdminSiswaListScreen> createState() => _AdminSiswaListScreenState();
}

class _AdminSiswaListScreenState extends State<AdminSiswaListScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _allSiswaList = [];
  List<String> _kelasList = ['Semua'];
  String _selectedKelas = 'Semua';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSiswa();
  }

  Future<void> _fetchSiswa() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'siswa')
          .order('kelas', ascending: true)
          .order('nama_lengkap', ascending: true);

      if (mounted) {
        setState(() {
          _allSiswaList = List<Map<String, dynamic>>.from(response);

          // Deteksi semua kelas secara otomatis
          final uniqueKelas = <String>{};
          for (var siswa in _allSiswaList) {
            final kelas = siswa['kelas'];
            if (kelas != null && kelas.toString().trim().isNotEmpty) {
              uniqueKelas.add(kelas.toString().trim());
            }
          }
          final sortedKelas = uniqueKelas.toList()..sort();
          _kelasList = ['Semua', ...sortedKelas];

          // Pastikan selected filter masih valid
          if (!_kelasList.contains(_selectedKelas)) {
            _selectedKelas = 'Semua';
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil daftar siswa: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredSiswa {
    if (_selectedKelas == 'Semua') return _allSiswaList;
    return _allSiswaList
        .where((siswa) => siswa['kelas']?.toString().trim() == _selectedKelas)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _filteredSiswa;

    return Column(
      children: [
        // Filter Chips Bar
        if (_kelasList.length > 1)
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _kelasList.map((k) {
                  final isSelected = _selectedKelas == k;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(k),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedKelas = k),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color:
                            isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

        if (_kelasList.length > 1)
          const Divider(height: 1, color: AppColors.divider),

        // Header Count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Text(
                'Menampilkan ${displayList.length} Siswa',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _fetchSiswa,
                icon: const Icon(Icons.refresh_rounded,
                    size: 20, color: AppColors.textSecondary),
                tooltip: 'Segarkan',
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : displayList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_alt_outlined,
                            size: 64,
                            color: AppColors.textMuted.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Belum ada siswa di kelas ini',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchSiswa,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: displayList.length,
                        itemBuilder: (ctx, i) {
                          final siswa = displayList[i];
                          final id =
                              siswa['id']?.toString().substring(0, 8) ?? '???';
                          final nama = siswa['nama_lengkap'] ?? 'Tanpa Nama';
                          final kelas = siswa['kelas'] ?? 'Kelas -';
                          final nis = siswa['nomor_induk'] ?? 'NIS: -';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.primaryLight,
                                    radius: 24,
                                    child: Text(
                                      nama.isNotEmpty
                                          ? nama[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          nama,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$kelas • $nis',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'ID: $id...',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
