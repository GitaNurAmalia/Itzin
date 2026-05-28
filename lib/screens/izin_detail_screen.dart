import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:itzin/services/izin_service.dart';
import 'package:itzin/services/auth_service.dart';
import 'package:itzin/core/theme.dart';

class IzinDetailScreen extends StatefulWidget {
  final Map<String, dynamic> izin;
  final bool isAdmin;

  const IzinDetailScreen({
    super.key,
    required this.izin,
    required this.isAdmin,
  });

  @override
  State<IzinDetailScreen> createState() => _IzinDetailScreenState();
}

class _IzinDetailScreenState extends State<IzinDetailScreen> {
  late final IzinService _izinService;
  late final AuthService _authService;
  late Map<String, dynamic> _izin;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _izinService = IzinService(supabase: Supabase.instance.client);
    _authService = AuthService(supabase: Supabase.instance.client);
    _izin = Map<String, dynamic>.from(widget.izin);
    _checkAndFetchProfile();
  }

  Future<void> _checkAndFetchProfile() async {
    final profiles = _izin['profiles'] as Map<String, dynamic>? ?? {};
    final namaLengkap = profiles['nama_lengkap'] ?? '-';

    // Jika tidak ada nama dan bukan admin, coba ambil dari auth service (profil user saat ini)
    if ((namaLengkap == '-' || namaLengkap.toString().isEmpty) &&
        !widget.isAdmin) {
      final profile = await _authService.getProfile();
      if (profile != null && mounted) {
        setState(() {
          _izin['profiles'] = {
            ...profiles,
            'nama_lengkap': profile['nama_lengkap'],
            'kelas': profile['kelas'],
            'nomor_induk': profile['nomor_induk'],
          };
        });
      }
    }
  }

  String _formatTanggal(String? raw) {
    if (raw == null) return '-';
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.parse(raw));
  }

  String _formatTime(String? raw) {
    if (raw == null) return '-';
    final parts = raw.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return raw;
  }

  String _formatDateTime(String? raw) {
    if (raw == null) return '-';
    return DateFormat('d MMM yyyy, HH:mm')
        .format(DateTime.parse(raw).toLocal());
  }

  Future<void> _showActionSheet(String action) async {
    final catatanController = TextEditingController();
    final isApprove = action == 'diizinkan';
    final nama = _izin['profiles']?['nama_lengkap'] ?? 'Siswa';

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
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 4),
            Text(
              nama,
              style:
                  const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: catatanController,
              maxLines: 3,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                labelText: 'Catatan (opsional)',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                hintText: isApprove
                    ? 'Misal: Silakan izin keluar'
                    : 'Alasan penolakan...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                          borderRadius: BorderRadius.circular(12)),
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
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(isApprove ? 'Izinkan' : 'Tolak'),
                    onPressed: () => Navigator.pop(ctx, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      setState(() => _isProcessing = true);
      
      // Mengambil ID Admin/Guru yang sedang aktif login
      final currentAdminId = Supabase.instance.client.auth.currentUser?.id;

      final result = await _izinService.updateStatusIzin(
        izinId: _izin['id'],
        status: action,
        catatan: catatanController.text,
        disetujuiOleh: currentAdminId, // <-- SEKARANG ID GURU SUDAH DIKIRIM KE RPC
      );
      
      catatanController.dispose();
      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (result['success'] == true) {
        setState(() {
          _izin['status'] = action;
          _izin['catatan_admin'] = catatanController.text;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(action == 'diizinkan'
                ? 'Izin berhasil disetujui'
                : 'Izin berhasil ditolak'),
            backgroundColor: action == 'diizinkan'
                ? AppColors.success
                : AppColors.statusDitolak,
          ),
        );
        if (mounted) Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal memproses izin'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } else {
      catatanController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _izin['status'] as String? ?? 'menunggu';
    final profiles = _izin['profiles'] as Map<String, dynamic>? ?? {};
    final namaLengkap = profiles['nama_lengkap'] ?? '-';
    final kelas = profiles['kelas'] ?? '-';
    final nomorInduk = profiles['nomor_induk'] ?? '';
    final alasan = _izin['alasan'] ?? '-';
    final catatan = _izin['catatan_admin'] ?? _izin['catatan'];
    final isMenunggu = status == 'menunggu';

    // Ekstraksi info nama guru pemeriksa dari IzinService
    final pemeriksa = _izin['pemeriksa'] as Map<String, dynamic>?;
    final namaGuru = pemeriksa != null ? pemeriksa['nama_lengkap'] : null;

    final textThemeColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Detail Izin'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status + student card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            namaLengkap.isNotEmpty && namaLengkap != '-'
                                ? namaLengkap[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                namaLengkap.isNotEmpty && namaLengkap != '-'
                                    ? namaLengkap
                                    : (widget.isAdmin ? 'Siswa' : 'Pengguna'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textThemeColor,
                                ),
                              ),
                              if (widget.isAdmin)
                                Text(
                                  '$kelas${nomorInduk.isNotEmpty ? ' • $nomorInduk' : ''}',
                                  style: const TextStyle(
                                      fontSize: 13, color: AppColors.textMuted),
                                ),
                            ],
                          ),
                        ),
                        _StatusChip(status: status),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Alasan
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle('Alasan Izin'),
                    const SizedBox(height: 10),
                    Text(
                      alasan,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textThemeColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Info Waktu
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle('Informasi Waktu'),
                    const SizedBox(height: 12),
                    _DetailRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Tanggal Izin',
                        value: _formatTanggal(_izin['tanggal_izin'])),
                    if (_izin['jam_keluar'] != null) ...[
                      const SizedBox(height: 10),
                      _DetailRow(
                          icon: Icons.output_rounded,
                          label: 'Jam Keluar',
                          value: _formatTime(_izin['jam_keluar'])),
                    ],
                    if (_izin['jam_kembali'] != null) ...[
                      const SizedBox(height: 10),
                      _DetailRow(
                          icon: Icons.login_rounded,
                          label: 'Jam Kembali',
                          value: _formatTime(_izin['jam_kembali'])),
                    ],
                    const SizedBox(height: 10),
                    _DetailRow(
                        icon: Icons.schedule_outlined,
                        label: 'Diajukan',
                        value: _formatDateTime(_izin['created_at'])),
                  ],
                ),
              ),
            ),

            // KARTU BARU: MENAMPILKAN NAMA GURU YANG MENGIZINKAN/MENOLAK
            if (!isMenunggu && namaGuru != null) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        status == 'diizinkan' 
                            ? Icons.assignment_ind_rounded 
                            : Icons.gpp_bad_rounded,
                        color: status == 'diizinkan' ? AppColors.success : AppColors.error,
                        size: 24,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status == 'diizinkan' ? 'Disetujui Oleh' : 'Ditolak Oleh',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              namaGuru,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: textThemeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Catatan admin (if rejected / approved with note)
            if (catatan != null && catatan.toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle('Catatan Admin'),
                      const SizedBox(height: 10),
                      Text(
                        catatan.toString(),
                        style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Admin action buttons
            if (widget.isAdmin && isMenunggu) ...[
              const SizedBox(height: 24),
              if (_isProcessing)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showActionSheet('ditolak'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Tolak Izin'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showActionSheet('diizinkan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: const Text('Izinkan'),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyLarge?.color)),
            ],
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
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style:
              TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w600)),
    );
  }
} 