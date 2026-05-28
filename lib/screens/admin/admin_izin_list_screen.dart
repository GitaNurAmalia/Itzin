import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:itzin/services/izin_service.dart';
import 'package:itzin/screens/izin_detail_screen.dart';
import 'package:itzin/core/theme.dart';

class AdminIzinListScreen extends StatefulWidget {
  const AdminIzinListScreen({super.key});

  @override
  State<AdminIzinListScreen> createState() => _AdminIzinListScreenState();
}

class _AdminIzinListScreenState extends State<AdminIzinListScreen> {
  late final IzinService _izinService;
  List<Map<String, dynamic>> _allData = [];
  bool _isLoading = true;
  String _filterStatus = 'menunggu'; // default filter
  String _namaGuruLogin = 'Admin/Guru'; // Default penampung nama guru yang login

  final List<_FilterOption> _filters = const [
    _FilterOption(value: 'semua', label: 'Semua'),
    _FilterOption(value: 'menunggu', label: 'Menunggu'),
    _FilterOption(value: 'diizinkan', label: 'Diizinkan'),
    _FilterOption(value: 'ditolak', label: 'Ditolak'),
  ];

  @override
  void initState() {
    super.initState();
    _izinService = IzinService(supabase: Supabase.instance.client);
    _initDataAndProfile();
  }

  // Menggabungkan inisialisasi agar berjalan berurutan dengan benar
  Future<void> _initDataAndProfile() async {
    await _getGuruProfileName();
    await _loadData();
  }

  // Fungsi untuk mengambil nama asli guru yang sedang login dari tabel profiles
  Future<void> _getGuruProfileName() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profileData = await Supabase.instance.client
            .from('profiles')
            .select('nama_lengkap')
            .eq('id', user.id)
            .maybeSingle();

        if (profileData != null && profileData['nama_lengkap'] != null) {
          if (mounted) {
            setState(() {
              _namaGuruLogin = profileData['nama_lengkap'];
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Gagal mengambil profil nama guru: $e');
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await _izinService.getAllIzin();
      if (mounted) {
        setState(() {
          _allData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error DB Supabase:\n$e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredData {
    if (_filterStatus == 'semua') return _allData;
    return _allData.where((item) => item['status'] == _filterStatus).toList();
  }

  Future<void> _showActionDialog(
      Map<String, dynamic> izin, String action) async {
    final catatanController = TextEditingController();
    final isApprove = action == 'diizinkan';
    final nama = izin['profiles']?['nama_lengkap'] ?? 'Siswa';
    final tanggal = izin['tanggal_izin'] != null
        ? DateFormat('EEE, d MMM yyyy', 'id_ID').format(DateTime.parse(izin['tanggal_izin']))
        : '';

    bool? confirm = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.dividerDark
                    : AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(
              isApprove
                  ? Icons.check_circle_outline_rounded
                  : Icons.cancel_outlined,
              size: 40,
              color: isApprove ? AppColors.success : AppColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              isApprove ? 'Izinkan Siswa?' : 'Tolak Izin?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$nama — $tanggal',
              style: TextStyle(
                fontSize: 13, 
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // INDIKATOR INFO OTOMATIS GURU
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.border_color_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Dikonfirmasi oleh: $_namaGuruLogin',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.primaryDark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: catatanController,
              maxLines: 3,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                labelText: 'Catatan (opsional)',
                hintText: isApprove
                    ? 'Misal: Silakan izin keluar'
                    : 'Alasan penolakan...',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isApprove ? AppColors.success : AppColors.error,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(isApprove ? 'Izinkan' : 'Tolak'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      await _processAction(
        izinId: izin['id'],
        status: action,
        catatan: catatanController.text,
      );
    }
    catatanController.dispose();
  }

  Future<void> _processAction({
    required int izinId,
    required String status,
    String? catatan,
  }) async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    final result = await _izinService.updateStatusIzin(
      izinId: izinId,
      status: status,
      catatan: catatan?.trim().isEmpty == true ? null : catatan,
      disetujuiOleh: currentUserId, 
    );

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'diizinkan'
                ? 'Izin berhasil disetujui'
                : 'Izin berhasil ditolak dan kuota di-refund',
          ),
          backgroundColor: status == 'diizinkan'
              ? AppColors.success
              : AppColors.error,
        ),
      );
      await _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal memproses izin'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredData;

    return Column(
      children: [
        // Filter chips 
        Container(
          width: double.infinity,
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((f) {
                final isSelected = _filterStatus == f.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f.label),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _filterStatus = f.value),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected 
                          ? Colors.white 
                          : (Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white70 
                              : Colors.black87),
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Divider(
          height: 1, 
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.dividerDark
              : AppColors.divider,
        ),

        // Count badge & Refresh Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Text(
                '${filtered.length} izin',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white70 
                      : Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.refresh_rounded,
                  size: 20, 
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white70 
                      : Colors.black54,
                ),
                onPressed: _loadData,
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) => InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            final needsRefresh = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => IzinDetailScreen(
                                  izin: filtered[i],
                                  isAdmin: true,
                                ),
                              ),
                            );
                            if (needsRefresh == true) _loadData();
                          },
                          child: _AdminIzinCard(
                            data: filtered[i],
                            onApprove: () =>
                                _showActionDialog(filtered[i], 'diizinkan'),
                            onReject: () =>
                                _showActionDialog(filtered[i], 'ditolak'),
                          ),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: AppColors.textMuted.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'Tidak ada izin',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white70 
                  : Colors.black54,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterOption {
  final String value;
  final String label;

  const _FilterOption({required this.value, required this.label});
}

class _AdminIzinCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _AdminIzinCard({
    required this.data,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? 'menunggu';
    final profiles = data['profiles'] as Map<String, dynamic>? ?? {};
    final namaLengkap = profiles['nama_lengkap'] ?? 'Siswa';
    final kelas = profiles['kelas'] ?? '-';
    final nomorInduk = profiles['nomor_induk'] ?? '';
    final alasan = data['alasan'] ?? '-';
    final tanggal = data['tanggal_izin'] != null
        ? DateFormat('EEE, d MMM yyyy', 'id_ID')
            .format(DateTime.parse(data['tanggal_izin']))
        : '-';
    final isMenunggu = status == 'menunggu';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? AppColors.dividerDark : AppColors.divider,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    namaLengkap.isNotEmpty ? namaLengkap[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        namaLengkap,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87, 
                        ),
                      ),
                      Text(
                        '$kelas${nomorInduk.isNotEmpty ? ' • $nomorInduk' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: status),
              ],
            ),
            const SizedBox(height: 12),
            Divider(
              height: 1, 
              color: isDark ? AppColors.dividerDark : AppColors.divider,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      alasan,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87, 
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              text: tanggal,
            ),
            const SizedBox(height: 12),
            if (data['jam_keluar'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _InfoRow(
                  icon: Icons.output_rounded,
                  text: 'Keluar: ${_fmt(data['jam_keluar'])}',
                ),
              ),
            if (data['jam_kembali'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _InfoRow(
                  icon: Icons.login_rounded,
                  text: 'Kembali: ${_fmt(data['jam_kembali'])}',
                ),
              ),
            
            if (!isMenunggu) ...[
              (() {
                final namaPemeriksa = data['pemeriksa']?['nama_lengkap'] ?? data['reviewed_by'];
                if (namaPemeriksa != null) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _InfoRow(
                      icon: Icons.assignment_turned_in_rounded,
                      text: status == 'diizinkan' 
                          ? 'Diizinkan oleh: $namaPemeriksa' 
                          : 'Ditolak oleh: $namaPemeriksa',
                    ),
                  );
                }
                return const SizedBox.shrink();
              })(),
            ],

            if (isMenunggu) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        minimumSize: const Size(0, 40),
                        padding: EdgeInsets.zero,
                      ),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Tolak'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onApprove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        minimumSize: const Size(0, 40),
                        padding: EdgeInsets.zero,
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Izinkan'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmt(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return timeStr;
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white70 : Colors.black54;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'diizinkan':
        bg = AppColors.statusDiizinkanBg;
        fg = AppColors.statusDiizinkanText;
        label = 'Diizinkan';
        break;
      case 'ditolak':
        bg = AppColors.statusDitolakBg;
        fg = AppColors.statusDitolakText;
        label = 'Ditolak';
        break;
      default:
        bg = AppColors.statusMenungguBg;
        fg = AppColors.statusMenungguText;
        label = 'Menunggu';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}