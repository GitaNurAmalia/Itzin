import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:itzin/services/izin_service.dart';
import 'package:itzin/screens/izin_detail_screen.dart';
import 'package:itzin/core/theme.dart';

class RiwayatIzinScreen extends StatefulWidget {
  const RiwayatIzinScreen({super.key});

  @override
  State<RiwayatIzinScreen> createState() => _RiwayatIzinScreenState();
}

class _RiwayatIzinScreenState extends State<RiwayatIzinScreen> {
  late final IzinService _izinService;
  List<Map<String, dynamic>> _dataIzin = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _izinService = IzinService(supabase: Supabase.instance.client);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await _izinService.getIzinSaya();
    if (mounted) {
      setState(() {
        _dataIzin = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dataIzin.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _dataIzin.length,
                  itemBuilder: (ctx, i) => InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => IzinDetailScreen(
                          izin: _dataIzin[i],
                          isAdmin: false,
                        ),
                      ),
                    ),
                    child: _IzinItem(data: _dataIzin[i]),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 72,
              color: isDark ? Colors.white30 : AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada riwayat izin',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ajukan izin dari tab "Buat Izin"',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _IzinItem extends StatelessWidget {
  final Map<String, dynamic> data;

  const _IzinItem({required this.data});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? 'menunggu';
    final tanggal = data['tanggal_izin'] != null
        ? DateFormat('EEE, d MMM yyyy', 'id_ID')
            .format(DateTime.parse(data['tanggal_izin']))
        : '-';
    final alasan = data['alasan'] ?? '-';
    final catatan = data['catatan_admin'];
    final createdAt = data['created_at'] != null
        ? DateFormat('d MMM yyyy HH:mm')
            .format(DateTime.parse(data['created_at']).toLocal())
        : '';

    // Deteksi Mode Gelap
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
            // Row Tanggal + Status Badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    tanggal,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isDark ? Colors.white : AppColors.textPrimary, // Perbaikan warna tanggal
                    ),
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 10),
            Divider(
              height: 1, 
              color: isDark ? AppColors.dividerDark : AppColors.divider, // Perbaikan warna divider
            ),
            const SizedBox(height: 10),
            
            // Row Alasan / Keterangan Dispen
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.notes_rounded,
                  size: 16,
                  color: isDark ? Colors.white60 : AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    alasan,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : AppColors.textSecondary, // Perbaikan warna text alasan
                    ),
                  ),
                ),
              ],
            ),

            // Jam keluar / kembali
            if (data['jam_keluar'] != null || data['jam_kembali'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time_outlined,
                    size: 16,
                    color: isDark ? Colors.white60 : AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    [
                      if (data['jam_keluar'] != null)
                        'Keluar: ${_formatTime(data['jam_keluar'])}',
                      if (data['jam_kembali'] != null)
                        'Kembali: ${_formatTime(data['jam_kembali'])}',
                    ].join('  •  '),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : AppColors.textMuted, // Perbaikan warna teks jam
                    ),
                  ),
                ],
              ),
            ],

            // Catatan admin
            if (catatan != null && catatan.toString().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.statusMenungguBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.admin_panel_settings_outlined,
                      size: 14,
                      color: AppColors.statusMenungguText,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Catatan Admin: $catatan',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.statusMenungguText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),
            // Teks Diajukan di bagian bawah
            Text(
              'Diajukan: $createdAt',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : AppColors.textMuted, // Perbaikan warna teks diajukan
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return timeStr;
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case 'diizinkan':
        bg = AppColors.statusDiizinkanBg;
        textColor = AppColors.statusDiizinkanText;
        label = 'Diizinkan';
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'ditolak':
        bg = AppColors.statusDitolakBg;
        textColor = AppColors.statusDitolakText;
        label = 'Ditolak';
        icon = Icons.cancel_outlined;
        break;
      default:
        bg = AppColors.statusMenungguBg;
        textColor = AppColors.statusMenungguText;
        label = 'Menunggu';
        icon = Icons.hourglass_top_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}