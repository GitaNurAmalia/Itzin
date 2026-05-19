import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';

import 'package:itzin/services/izin_service.dart';
import 'package:itzin/services/export_service.dart';
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
    _loadData();
  }

  Future<void> _loadData() async {
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
    final tanggal = izin['tanggal_izin'] ?? '';

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
                color: AppColors.divider,
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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$nama — $tanggal',
              style:
                  const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: catatanController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Catatan (opsional)',
                hintText: isApprove
                    ? 'Misal: Silakan izin keluar'
                    : 'Alasan penolakan...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
    final result = await _izinService.updateStatusIzin(
      izinId: izinId,
      status: status,
      catatan: catatan,
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
              : AppColors.statusDitolak,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal memproses izin'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showExportOptions() {
    if (_filteredData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada data untuk diekspor'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Export Data',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.table_view_rounded,
                      color: AppColors.primary),
                  title: const Text('Export ke Excel (.xlsx)'),
                  onTap: () {
                    Navigator.pop(context);
                    _processExport('excel');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.description_rounded,
                      color: AppColors.primary),
                  title: const Text('Export ke CSV (.csv)'),
                  onTap: () {
                    Navigator.pop(context);
                    _processExport('csv');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _processExport(String format) async {
    try {
      final path = format == 'excel'
          ? await ExportService.exportIzinToExcel(_filteredData)
          : await ExportService.exportIzinToCsv(_filteredData);

      final xFile = XFile(path,
          mimeType: format == 'excel'
              ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
              : 'text/csv');

      // ignore: deprecated_member_use
      await Share.shareXFiles([xFile], subject: 'Export Daftar Izin ($format)');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengekspor data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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
          color: Colors.white,
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
        const Divider(height: 1, color: AppColors.divider),

        // Count badge
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Text(
                '${filtered.length} izin',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Export Data'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 32),
                ),
                onPressed: _showExportOptions,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh_rounded,
                    size: 20, color: AppColors.textSecondary),
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
          const Text(
            'Tidak ada izin',
            style: TextStyle(
              color: AppColors.textSecondary,
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: nama + status
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '$kelas${nomorInduk.isNotEmpty ? ' • $nomorInduk' : ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: status),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 12),

            // Alasan
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      alasan,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tanggal
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              text: tanggal,
            ),
            const SizedBox(height: 12),

            // Jam Keluar
            if (data['jam_keluar'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _InfoRow(
                  icon: Icons.output_rounded,
                  text: 'Keluar: ${_fmt(data['jam_keluar'])}',
                ),
              ),

            // Jam Kembali
            if (data['jam_kembali'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _InfoRow(
                  icon: Icons.login_rounded,
                  text: 'Kembali: ${_fmt(data['jam_kembali'])}',
                ),
              ),

            // Action buttons (only for menunggu)
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
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
