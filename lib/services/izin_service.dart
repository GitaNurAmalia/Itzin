import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IzinService {
  final SupabaseClient supabase;

  IzinService({required this.supabase});

  // Buat izin baru via RPC (agar kuota otomatis terkurangi)
  Future<Map<String, dynamic>> buatIzin({
    required String alasan,
    required DateTime tanggalIzin,
    TimeOfDay? jamKeluar,
    TimeOfDay? jamKembali,
  }) async {
    try {
      final params = <String, dynamic>{
        'p_alasan': alasan,
        'p_tanggal_izin': DateFormat('yyyy-MM-dd').format(tanggalIzin),
      };

      if (jamKeluar != null) {
        params['p_jam_keluar'] =
            '${jamKeluar.hour.toString().padLeft(2, '0')}:${jamKeluar.minute.toString().padLeft(2, '0')}:00';
      }
      if (jamKembali != null) {
        params['p_jam_kembali'] =
            '${jamKembali.hour.toString().padLeft(2, '0')}:${jamKembali.minute.toString().padLeft(2, '0')}:00';
      }

      final response = await supabase.rpc('buat_izin', params: params);

      // response adalah JSON: { success: bool, izin_id?: int, sisa_kuota?: int, message?: string }
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return {'success': false, 'message': 'Respons tidak valid dari server'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal membuat izin: $e'};
    }
  }

  // Ambil daftar izin milik user yang sedang login
  Future<List<Map<String, dynamic>>> getIzinSaya() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return [];

      final response = await supabase
          .from('izin_siswa')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> izinList =
          List<Map<String, dynamic>>.from(response);

      // Fetch profile untuk user
      final prof = await supabase
          .from('profiles')
          .select('nama_lengkap, kelas, nomor_induk')
          .eq('id', user.id)
          .maybeSingle();

      if (prof != null) {
        for (var i = 0; i < izinList.length; i++) {
          izinList[i]['profiles'] = prof;
        }
      }

      return izinList;
    } catch (e) {
      return [];
    }
  }

  // Ambil kuota izin bulan ini
  Future<Map<String, dynamic>> getKuotaBulanIni() async {
    try {
      final now = DateTime.now();
      final user = supabase.auth.currentUser;
      if (user == null) return {'sisa_kuota': 0};

      final response = await supabase
          .from('kuota_izin')
          .select('sisa_kuota')
          .eq('user_id', user.id)
          .eq('bulan', now.month)
          .eq('tahun', now.year)
          .maybeSingle();

      if (response == null) {
        // Belum ada record = kuota masih penuh (default 7)
        return {'sisa_kuota': 7};
      }
      return {'sisa_kuota': response['sisa_kuota'] ?? 0};
    } catch (e) {
      return {'sisa_kuota': 0};
    }
  }

  // Admin: Ambil semua izin dari semua siswa
  Future<List<Map<String, dynamic>>> getAllIzin() async {
    try {
      final response = await supabase
          .from('izin_siswa')
          .select()
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> izinList =
          List<Map<String, dynamic>>.from(response);

      // Ambil profile secara manual satu per satu tanpa Relation Join
      // (Bypass error foreign key Supabase)
      for (var i = 0; i < izinList.length; i++) {
        final userId = izinList[i]['user_id'];
        if (userId != null) {
          final prof = await supabase
              .from('profiles')
              .select('nama_lengkap, kelas, nomor_induk')
              .eq('id', userId)
              .maybeSingle();
          if (prof != null) {
            izinList[i]['profiles'] = prof;
          }
        }
      }
      return izinList;
    } catch (e) {
      debugPrint("SUPABASE ERROR getAllIzin: $e");
      return [];
    }
  }

  // Admin: Update status izin via RPC (agar kuota ter-refund jika ditolak)
  Future<Map<String, dynamic>> updateStatusIzin({
    required int izinId,
    required String status,
    String? catatan,
  }) async {
    try {
      final params = <String, dynamic>{
        'p_izin_id': izinId,
        'p_status': status,
      };
      if (catatan != null && catatan.isNotEmpty) {
        params['p_catatan'] = catatan;
      }

      final response = await supabase.rpc('update_status_izin', params: params);

      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return {'success': false, 'message': 'Respons tidak valid dari server'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal update status: $e'};
    }
  }
}
