import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:universal_html/html.dart' as html;

Future<void> exportExcel(List<Map<String, dynamic>> data) async {
  try {
    final excel = Excel.createExcel();
    final sheet = excel['Laporan'];

    // Header
    sheet.appendRow([
      TextCellValue('Tanggal'),
      TextCellValue('Barang'),
      TextCellValue('Jumlah'),
      TextCellValue('Satuan'),
      TextCellValue('User'),
    ]);

    final df = DateFormat('dd-MM-yyyy HH:mm');

    // Data
    for (var item in data) {
      sheet.appendRow([
        TextCellValue(df.format(item['waktu'] as DateTime)),
        TextCellValue(item['namaBarang'] ?? '-'),
        IntCellValue(item['jumlah'] ?? 0),
        TextCellValue(item['satuan'] ?? '-'),
        TextCellValue(item['user'] ?? '-'),
      ]);
    }

    final fileName =
        'laporan_${DateFormat('ddMMyyyy_HHmmss').format(DateTime.now())}.xlsx';

    final bytes = excel.encode();

    if (bytes == null) {
      throw Exception('Gagal generate Excel');
    }

    // ================= WEB =================
    if (kIsWeb) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();

      html.Url.revokeObjectUrl(url);

      debugPrint('Excel downloaded (Web): $fileName');
      return;
    }

    // ================= MOBILE / DESKTOP =================
    final dir = await getApplicationDocumentsDirectory();

    final file = File('${dir.path}/$fileName');

    await file.writeAsBytes(bytes, flush: true);

    debugPrint('Excel saved: ${file.path}');
  } catch (e, st) {
    debugPrint('EXPORT EXCEL ERROR: $e');
    debugPrint('$st');
    rethrow;
  }
}
