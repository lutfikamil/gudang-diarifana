import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

Future<void> exportPdf(List<Map<String, dynamic>> data) async {
  // Initialize locale data untuk 'id_ID'
  await initializeDateFormatting('id_ID', null);

  final pdf = pw.Document();
  final df = DateFormat('dd-MM-yyyy HH:mm');
  final dateNow = DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now());

  // Header table
  final headers = ['Tanggal', 'Barang', 'Jumlah', 'Satuan', 'User'];

  // Data rows
  final rows = <List<dynamic>>[];
  for (var item in data) {
    rows.add([
      df.format(item['waktu']),
      item['namaBarang'],
      item['jumlah'].toString(),
      item['satuan'],
      item['user'],
    ]);
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(20),
      build:
          (context) => [
            // Title
            pw.Header(
              level: 0,
              child: pw.Center(
                child: pw.Text(
                  'LAPORAN BARANG',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ),
            pw.SizedBox(height: 10),

            // Date info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Tanggal: $dateNow'),
                pw.Text('Total Item: ${data.length}'),
              ],
            ),
            pw.SizedBox(height: 20),

            // Table
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1.5),
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey300),
                  children:
                      headers
                          .map(
                            (header) => pw.Padding(
                              padding: pw.EdgeInsets.all(8),
                              child: pw.Text(
                                header,
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
                // Data rows
                ...rows
                    .map(
                      (row) => pw.TableRow(
                        children:
                            row
                                .map(
                                  (cell) => pw.Padding(
                                    padding: pw.EdgeInsets.all(8),
                                    child: pw.Text(cell.toString()),
                                  ),
                                )
                                .toList(),
                      ),
                    )
                    .toList(),
              ],
            ),
            pw.SizedBox(height: 20),

            // Footer
            pw.Center(
              child: pw.Text(
                'Laporan ini dicetak otomatis dari Sistem Gudang',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ),
          ],
    ),
  );

  // Save file
  final fileName =
      'laporan_mbg_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

  try {
    if (kIsWeb) {
      // Web: Download file
      final bytes = await pdf.save();
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
      print('File PDF berhasil diunduh: $fileName');
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

      final pdfBytes = await pdf.save();
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);
      print('File PDF berhasil disimpan di: $filePath');
    }
  } catch (e) {
    print('Error menyimpan PDF: $e');
    rethrow;
  }
}
