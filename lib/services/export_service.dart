import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class ExportService {
  // EXPORT TO EXCEL
  static Future<String> exportIzinToExcel(
      List<Map<String, dynamic>> data) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Daftar Izin'];
    excel.setDefaultSheet('Daftar Izin');

    // Header array
    List<String> headers = [
      'Nama Siswa',
      'Kelas',
      'Nomor Induk',
      'Tanggal Izin',
      'Jam Keluar',
      'Jam Kembali',
      'Total Jam',
      'Alasan',
      'Status',
      'Catatan',
      'Dibuat Pada'
    ];

    sheetObject.appendRow(headers.map((e) => TextCellValue(e)).toList());

    for (var d in data) {
      final profiles = d['profiles'] as Map<String, dynamic>? ?? {};
      final namaLengkap = profiles['nama_lengkap'] ?? '';
      final kelas = profiles['kelas'] ?? '';
      final nomorInduk = profiles['nomor_induk'] ?? '';
      final alasan = d['alasan'] ?? '';
      final status = d['status'] ?? '';
      final catatan = d['catatan'] ?? '';
      final tanggalIzin = d['tanggal_izin'] != null
          ? DateFormat('yyyy-MM-dd').format(DateTime.parse(d['tanggal_izin']))
          : '';
      final jamKeluar = d['jam_keluar'] ?? '';
      final jamKembali = d['jam_kembali'] ?? '';
      final totalJam = d['jam_keluar_berapa_lama']?.toString() ?? '';
      final createdAt = d['created_at'] != null
          ? DateFormat('yyyy-MM-dd HH:mm')
              .format(DateTime.parse(d['created_at']))
          : '';

      sheetObject.appendRow([
        TextCellValue(namaLengkap),
        TextCellValue(kelas),
        TextCellValue(nomorInduk),
        TextCellValue(tanggalIzin),
        TextCellValue(jamKeluar),
        TextCellValue(jamKembali),
        TextCellValue(totalJam),
        TextCellValue(alasan),
        TextCellValue(status),
        TextCellValue(catatan),
        TextCellValue(createdAt),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Gagal encode file excel');
    }

    final dir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/Daftar_Izin_$timestamp.xlsx');

    await file.writeAsBytes(bytes);
    return file.path;
  }

  // EXPORT TO CSV
  static Future<String> exportIzinToCsv(List<Map<String, dynamic>> data) async {
    List<List<dynamic>> rows = [];
    rows.add([
      'Nama Siswa',
      'Kelas',
      'Nomor Induk',
      'Tanggal Izin',
      'Jam Keluar',
      'Jam Kembali',
      'Total Jam',
      'Alasan',
      'Status',
      'Catatan',
      'Dibuat Pada'
    ]);

    for (var d in data) {
      final profiles = d['profiles'] as Map<String, dynamic>? ?? {};
      final namaLengkap = profiles['nama_lengkap'] ?? '';
      final kelas = profiles['kelas'] ?? '';
      final nomorInduk = profiles['nomor_induk'] ?? '';
      final alasan = d['alasan'] ?? '';
      final status = d['status'] ?? '';
      final catatan = d['catatan'] ?? '';
      final tanggalIzin = d['tanggal_izin'] != null
          ? DateFormat('yyyy-MM-dd').format(DateTime.parse(d['tanggal_izin']))
          : '';
      final jamKeluar = d['jam_keluar'] ?? '';
      final jamKembali = d['jam_kembali'] ?? '';
      final totalJam = d['jam_keluar_berapa_lama']?.toString() ?? '';
      final createdAt = d['created_at'] != null
          ? DateFormat('yyyy-MM-dd HH:mm')
              .format(DateTime.parse(d['created_at']))
          : '';

      rows.add([
        namaLengkap,
        kelas,
        nomorInduk,
        tanggalIzin,
        jamKeluar,
        jamKembali,
        totalJam,
        alasan,
        status,
        catatan,
        createdAt
      ]);
    }

    String csv = rows
        .map((row) => row.map((cell) {
              final str = cell.toString().replaceAll('"', '""');
              return '"$str"';
            }).join(','))
        .join('\n');

    final dir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/Daftar_Izin_$timestamp.csv');

    await file.writeAsString(csv);
    return file.path;
  }
}
