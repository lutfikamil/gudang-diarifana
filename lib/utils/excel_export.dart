import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:permission_handler/permission_handler.dart';

Future<void> exportExcel(List<Map<String, dynamic>> data) async {
  final excel = Excel.createExcel();
  final sheet = excel['Laporan'];

  sheet.appendRow([
    TextCellValue('Tanggal'),
    TextCellValue('Barang'),
    TextCellValue('Jumlah'),
    TextCellValue('Satuan'),
    TextCellValue('User'),
  ]);

  final df = DateFormat('dd-MM-yyyy HH:mm');

  for (var item in data) {
    sheet.appendRow([
      TextCellValue(df.format(item['waktu'])),
      TextCellValue(item['namaBarang']),
      IntCellValue(item['jumlah']),
      TextCellValue(item['satuan']),
      TextCellValue(item['user']),
    ]);
  }

  final fileName =
      'laporan_mbg_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

  try {
    if (kIsWeb) {
      // Web: Download file
      final bytes = excel.encode()!;
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
      print('File Excel berhasil diunduh: $fileName');
    } else {
      // Request permission
      final status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        throw Exception('Permission MANAGE_EXTERNAL_STORAGE ditolak');
      }

      String filePath;
      if (Platform.isAndroid) {
        // Android: Save ke Downloads folder
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
        filePath = '${downloadDir.path}/$fileName';
      } else if (Platform.isIOS) {
        // iOS: Gunakan Documents directory
        final dir = await getApplicationDocumentsDirectory();
        filePath = '${dir.path}/$fileName';
      } else {
        // Platform lain
        final dir = await getApplicationDocumentsDirectory();
        filePath = '${dir.path}/$fileName';
      }

      final bytes = excel.encode()!;
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      print('File Excel berhasil disimpan di: $filePath');
    }
  } catch (e) {
    print('Error menyimpan Excel: $e');
    rethrow;
  }
}
