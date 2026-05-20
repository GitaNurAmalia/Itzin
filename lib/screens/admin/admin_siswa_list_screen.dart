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
  
  List<String> _tingkatList = ['Semua'];
  List<String> _jurusanList = ['Semua'];
  
  String _selectedTingkat = 'Semua';
  String _selectedJurusan = 'Semua';
  
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

          final uniqueTingkat = <String>{};
          final uniqueJurusan = <String>{};

          for (var siswa in _allSiswaList) {
            final kelasString = siswa['kelas']?.toString().trim().toUpperCase() ?? '';
            if (kelasString.isNotEmpty) {
              final parts = kelasString.split(RegExp(r'[\s\-]+'));
              if (parts.isNotEmpty && parts[0].isNotEmpty) {
                uniqueTingkat.add(parts[0]);
              }
              if (parts.length > 1 && parts[1].isNotEmpty) {
                uniqueJurusan.add(parts[1]);
              }
            }
          }

          final sortedTingkat = uniqueTingkat.toList()..sort();
          final sortedJurusan = uniqueJurusan.toList()..sort();

          _tingkatList = ['Semua', ...sortedTingkat];
          _jurusanList = ['Semua', ...sortedJurusan];

          if (!_tingkatList.contains(_selectedTingkat)) {
            _selectedTingkat = 'Semua';
          }
          if (!_jurusanList.contains(_selectedJurusan)) {
            _selectedJurusan = 'Semua';
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
    return _allSiswaList.where((siswa) {
      final kelasString = siswa['kelas']?.toString().trim().toUpperCase() ?? '';
      final parts = kelasString.split(RegExp(r'[\s\-]+'));
      
      final tingkat = parts.isNotEmpty ? parts[0] : '';
      final jurusan = parts.length > 1 ? parts[1] : '';

      final matchTingkat = _selectedTingkat == 'Semua' || tingkat == _selectedTingkat;
      final matchJurusan = _selectedJurusan == 'Semua' || jurusan == _selectedJurusan;

      return matchTingkat && matchJurusan;
    }).toList();
  }

  void _showEditDialog(Map<String, dynamic> siswa) {
    final nameController = TextEditingController(text: siswa['nama_lengkap']);
    final nisController = TextEditingController(text: siswa['nomor_induk']);
    final kelasController = TextEditingController(text: siswa['kelas']);
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit Data Siswa',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Nama Lengkap',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: nisController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Nomor Induk Siswa (NIS)',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: kelasController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Kelas (Contoh: X RPL 1)',
                            prefixIcon: Icon(Icons.class_outlined),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isSaving ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSaving ? null : () async {
                            if (!formKey.currentState!.validate()) return;
                            setDialogState(() => isSaving = true);
                            
                            try {
                              await _supabase.from('profiles').update({
                                'nama_lengkap': nameController.text.trim(),
                                'nomor_induk': nisController.text.trim(),
                                'kelas': kelasController.text.trim(),
                              }).eq('id', siswa['id']);
                              
                              if (mounted) {
                                Navigator.pop(context);
                                _fetchSiswa();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Data siswa berhasil diperbarui'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            } catch (e) {
                              setDialogState(() => isSaving = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Gagal menyimpan: $e'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Simpan'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFilterDialog() {
    String tempTingkat = _selectedTingkat;
    String tempJurusan = _selectedJurusan;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final tempFilteredCount = _allSiswaList.where((siswa) {
              final kelasString = siswa['kelas']?.toString().trim().toUpperCase() ?? '';
              final parts = kelasString.split(RegExp(r'[\s\-]+'));
              final tingkat = parts.isNotEmpty ? parts[0] : '';
              final jurusan = parts.length > 1 ? parts[1] : '';

              final matchTingkat = tempTingkat == 'Semua' || tingkat == tempTingkat;
              final matchJurusan = tempJurusan == 'Semua' || jurusan == tempJurusan;
              return matchTingkat && matchJurusan;
            }).length;

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded, size: 28),
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Text(
                          'Filter',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kelas / Tingkat',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _tingkatList.map((t) {
                              final isSelected = tempTingkat == t;
                              return GestureDetector(
                                onTap: () => setModalState(() => tempTingkat = t),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : Colors.transparent, // Warna orange sesuai referensi
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    t,
                                    style: TextStyle(
                                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Jurusan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _jurusanList.map((j) {
                              final isSelected = tempJurusan == j;
                              return GestureDetector(
                                onTap: () => setModalState(() => tempJurusan = j),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : Colors.transparent,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    j,
                                    style: TextStyle(
                                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Bottom Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempTingkat = 'Semua';
                              tempJurusan = 'Semua';
                            });
                          },
                          child: const Text(
                            'Clear',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedTingkat = tempTingkat;
                              _selectedJurusan = tempJurusan;
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size(200, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Lihat $tempFilteredCount hasil',
                            style: const TextStyle(
                              color: Colors.white, 
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _filteredSiswa;
    final isFiltered = _selectedTingkat != 'Semua' || _selectedJurusan != 'Semua';

    return Column(
      children: [
        // Header Count & Filter Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Menampilkan ${displayList.length} Siswa',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (isFiltered)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '$_selectedTingkat • $_selectedJurusan',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _showFilterDialog,
                icon: Icon(
                  Icons.filter_list_rounded, 
                  size: 20,
                  color: isFiltered ? AppColors.primary : AppColors.textSecondary,
                ),
                label: Text(
                  'Filter',
                  style: TextStyle(
                    color: isFiltered ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: isFiltered ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              IconButton(
                onPressed: _fetchSiswa,
                icon: const Icon(Icons.refresh_rounded, size: 22, color: AppColors.textSecondary),
                tooltip: 'Segarkan',
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: AppColors.divider),

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
                          Text(
                            isFiltered ? 'Tidak ada siswa yang sesuai filter' : 'Belum ada siswa',
                            style: const TextStyle(
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
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                                    onPressed: () => _showEditDialog(siswa),
                                    tooltip: 'Edit Data Siswa',
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

