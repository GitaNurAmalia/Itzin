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

      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return {'success': false, 'message': 'Respons tidak valid dari server'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal membuat izin: $e'};
    }
  }

  // Ambil daftar izin milik user yang sedang login (Siswa)
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

      // 1. Ambil profile untuk siswa itu sendiri
      final profSiswa = await supabase
          .from('profiles')
          .select('nama_lengkap, kelas, nomor_induk')
          .eq('id', user.id)
          .maybeSingle();

      // Looping untuk menyisipkan data profil siswa DAN profil guru pemeriksa
      for (var i = 0; i < izinList.length; i++) {
        if (profSiswa != null) {
          izinList[i]['profiles'] = profSiswa;
        }

        // 2. AMBIL PROFIL GURU PEMERIKSA (reviewed_by) JIKA ADA
        final reviewedBy = izinList[i]['reviewed_by'];
        if (reviewedBy != null) {
          final profGuru = await supabase
              .from('profiles')
              .select('nama_lengkap')
              .eq('id', reviewedBy)
              .maybeSingle();
          
          if (profGuru != null) {
            // Dibungkus ke dalam map 'pemeriksa' agar strukturnya sama dengan UI Admin
            izinList[i]['pemeriksa'] = profGuru;
          }
        }
      }

      return izinList;
    } catch (e) {
      debugPrint("ERROR getIzinSaya: $e");
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
      for (var i = 0; i < izinList.length; i++) {
        // 1. Ambil Profil Siswa (user_id)
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

        // 2. AMBIL PROFIL GURU PEMERIKSA (reviewed_by) SECARA OTOMATIS
        final reviewedBy = izinList[i]['reviewed_by'];
        if (reviewedBy != null) {
          final profGuru = await supabase
              .from('profiles')
              .select('nama_lengkap')
              .eq('id', reviewedBy)
              .maybeSingle();
          if (profGuru != null) {
            izinList[i]['pemeriksa'] = profGuru;
          }
        }
      }
      return izinList;
    } catch (e) {
      debugPrint("SUPABASE ERROR getAllIzin: $e");
      return [];
    }
  }

  // Admin: Update status izin via RPC
  Future<Map<String, dynamic>> updateStatusIzin({
    required int izinId,
    required String status,
    String? catatan,
    String? disetujuiOleh, 
  }) async {
    try {
      final params = <String, dynamic>{
        'p_izin_id': izinId,
        'p_status': status,
      };
      
      if (catatan != null && catatan.isNotEmpty) {
        params['p_catatan'] = catatan;
      }
      
      if (disetujuiOleh != null && disetujuiOleh.isNotEmpty) {
        params['p_disetujui_oleh'] = disetujuiOleh;
      }

      final response = await supabase.rpc('update_status_izin', params: params);

      if (response is Map) {
        final resultMap = Map<String, dynamic>.from(response);
        
        // Jembatan sinkronisasi data ke UI: jika SQL mengembalikan status == 'success',
        // kita set key 'success' menjadi true agar UI tidak salah membaca respons.
        if (resultMap['status'] == 'success' || resultMap['success'] == true) {
          resultMap['success'] = true;
        } else {
          resultMap['success'] = false;
        }
        
        return resultMap;
      }
      return {'success': false, 'message': 'Respons tidak valid dari server'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal update status: $e'};
    }
  }
}