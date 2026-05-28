import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:itzin/services/izin_service.dart';
import 'package:itzin/core/theme.dart';

class IzinFormScreen extends StatefulWidget {
  const IzinFormScreen({super.key});

  @override
  State<IzinFormScreen> createState() => _IzinFormScreenState();
}

class _IzinFormScreenState extends State<IzinFormScreen> {
  late final IzinService _izinService;

  final _formKey = GlobalKey<FormState>();
  final _alasanController = TextEditingController();

  DateTime? _tanggalIzin;
  TimeOfDay? _jamKeluar;
  TimeOfDay? _jamKembali;
  bool _isLoading = false;
  bool _isLoadingKuota = true;
  int _sisaKuota = 7;

  @override
  void initState() {
    super.initState();
    _izinService = IzinService(supabase: Supabase.instance.client);
    _loadKuota();
  }

  @override
  void dispose() {
    _alasanController.dispose();
    super.dispose();
  }

  Future<void> _loadKuota() async {
    setState(() => _isLoadingKuota = true);
    final result = await _izinService.getKuotaBulanIni();
    if (mounted) {
      setState(() {
        _sisaKuota = result['sisa_kuota'] ?? 0;
        _isLoadingKuota = false;
      });
    }
  }

  Future<void> _pickTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalIzin ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      helpText: 'Pilih Tanggal Izin',
    );
    if (picked != null) setState(() => _tanggalIzin = picked);
  }

  Future<void> _pickJam({required bool isKeluar}) async {
    final initial = isKeluar
        ? (_jamKeluar ?? const TimeOfDay(hour: 8, minute: 0))
        : (_jamKembali ?? const TimeOfDay(hour: 14, minute: 0));

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: isKeluar ? 'Jam Keluar' : 'Jam Kembali',
    );
    if (picked != null) {
      setState(() {
        if (isKeluar) {
          _jamKeluar = picked;
        } else {
          _jamKembali = picked;
        }
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tanggalIzin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal izin wajib dipilih'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _izinService.buatIzin(
      alasan: _alasanController.text.trim(),
      tanggalIzin: _tanggalIzin!,
      jamKeluar: _jamKeluar,
      jamKembali: _jamKembali,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() => _isLoading = false);
      final sisaKuota = result['sisa_kuota'];
      _resetForm();
      _loadKuota();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sisaKuota != null
                ? 'Izin berhasil diajukan! Sisa kuota: $sisaKuota hari'
                : 'Izin berhasil diajukan!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal mengajukan izin'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _alasanController.clear();
    setState(() {
      _tanggalIzin = null;
      _jamKeluar = null;
      _jamKembali = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kuota card
          _KuotaCard(
            sisaKuota: _sisaKuota,
            isLoading: _isLoadingKuota,
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
                    Text(
                      'Formulir Pengajuan Izin',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Alasan
                    TextFormField(
                      controller: _alasanController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Alasan Izin',
                        hintText: 'Jelaskan alasan izin keluar...',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Alasan wajib diisi';
                        }
                        if (v.trim().length < 10) {
                          return 'Alasan terlalu singkat';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Tanggal Izin
                    _DatePickerField(
                      label: 'Tanggal Izin',
                      value: _tanggalIzin != null
                          ? DateFormat('EEEE, d MMMM yyyy', 'id_ID')
                              .format(_tanggalIzin!)
                          : null,
                      icon: Icons.calendar_today_outlined,
                      onTap: _pickTanggal,
                      isRequired: true,
                    ),
                    const SizedBox(height: 12),

                    // Jam Keluar
                    _DatePickerField(
                      label: 'Jam Keluar (Opsional)',
                      value: _jamKeluar?.format(context),
                      icon: Icons.access_time_outlined,
                      onTap: () => _pickJam(isKeluar: true),
                      onClear: _jamKeluar != null
                          ? () => setState(() => _jamKeluar = null)
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // Jam Kembali
                    _DatePickerField(
                      label: 'Jam Kembali (Opsional)',
                      value: _jamKembali?.format(context),
                      icon: Icons.access_time_filled_outlined,
                      onTap: () => _pickJam(isKeluar: false),
                      onClear: _jamKembali != null
                          ? () => setState(() => _jamKembali = null)
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // Submit
                    ElevatedButton(
                      onPressed: (_isLoading || _sisaKuota <= 0)
                          ? null
                          : _handleSubmit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              _sisaKuota <= 0 ? 'Kuota Habis' : 'Ajukan Izin',
                            ),
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

// Kuota Banner Widget
class _KuotaCard extends StatelessWidget {
  final int sisaKuota;
  final bool isLoading;

  const _KuotaCard({required this.sisaKuota, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final isLow = sisaKuota <= 2;
    final isZero = sisaKuota <= 0;

    final bgColor = isZero
        ? AppColors.statusDitolakBg
        : isLow
            ? AppColors.statusMenungguBg
            : AppColors.primaryLight;
    final iconColor = isZero
        ? AppColors.statusDitolak
        : isLow
            ? AppColors.statusMenunggu
            : AppColors.primary;
    final textColor = isZero
        ? AppColors.statusDitolakText
        : isLow
            ? AppColors.statusMenungguText
            : AppColors.primaryDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isZero ? Icons.block_rounded : Icons.badge_outlined,
              color: iconColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sisa Kuota Izin Bulan Ini',
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 2),
                if (isLoading)
                  const SizedBox(
                    height: 20,
                    width: 60,
                    child: LinearProgressIndicator(),
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$sisaKuota',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'hari tersisa',
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Date/Time picker field widget
class _DatePickerField extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final bool isRequired;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.onClear,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: value != null && onClear != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: onClear,
                )
              : const Icon(Icons.chevron_right_rounded),
        ),
        child: Text(
          value ?? (isRequired ? 'Pilih tanggal' : 'Tidak diisi'),
          style: TextStyle(
            fontSize: 14,
            color: value != null 
                ? Theme.of(context).textTheme.bodyLarge?.color 
                : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}