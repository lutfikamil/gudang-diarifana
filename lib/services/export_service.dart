import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:gudang_app/services/export_helper.dart' as export_helper;
import 'package:excel/excel.dart';

class ExportService {
  static final _db = FirebaseFirestore.instance;

  // ================= EXPORT STOK BARANG KE EXCEL =================
  static Future<void> exportStokBarangToExcel() async {
    final snapshot = await _db.collection('barang').get();

    // Buat Excel workbook
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];
    sheetObject.setColumnWidth(0, 25);
    sheetObject.setColumnWidth(1, 10);
    sheetObject.setColumnWidth(2, 12);
    sheetObject.setColumnWidth(3, 15);

    // Tambah header
    sheetObject
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .value = TextCellValue('Nama Barang');
    sheetObject
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0))
        .value = TextCellValue('Stok');
    sheetObject
        .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0))
        .value = TextCellValue('Satuan');
    sheetObject
        .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0))
        .value = TextCellValue('Kategori');

    // Tambah data
    int rowIndex = 1;
    for (var doc in snapshot.docs) {
      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(doc['nama'] ?? '-');
      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = IntCellValue(doc['stok'] ?? 0);
      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = TextCellValue(doc['satuan'] ?? '-');
      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = TextCellValue(doc['kategori'] ?? '-');
      rowIndex++;
    }

    // Save file
    _generateExcel(excel, "stok_barang.xlsx");
  }

  // ================= EXPORT STOK BARANG =================
  static Future<void> exportStokBarang() async {
    final snapshot = await _db.collection('barang').get();

    List<List<dynamic>> rows = [];
    rows.add(["Nama Barang", "Stok"]);

    for (var doc in snapshot.docs) {
      rows.add([doc['nama'], doc['stok']]);
    }

    _generateCSV(rows, "stok_barang.csv");
  }

  // ================= EXPORT BARANG MASUK =================
  static Future<void> exportBarangMasuk() async {
    final snapshot = await _db.collection('barang_masuk').get();

    List<List<dynamic>> rows = [];
    rows.add(["Nama Barang", "Jumlah", "Tanggal"]);

    for (var doc in snapshot.docs) {
      rows.add([
        doc['namaBarang'],
        doc['jumlah'],
        doc['tanggal'].toDate().toString(),
      ]);
    }

    _generateCSV(rows, "barang_masuk.csv");
  }

  // ================= EXPORT BARANG KELUAR =================
  static Future<void> exportBarangKeluar() async {
    final snapshot = await _db.collection('barang_keluar').get();

    List<List<dynamic>> rows = [];
    rows.add(["Nama Barang", "Jumlah", "Tanggal"]);

    for (var doc in snapshot.docs) {
      rows.add([
        doc['namaBarang'],
        doc['jumlah'],
        doc['tanggal'].toDate().toString(),
      ]);
    }

    _generateCSV(rows, "barang_keluar.csv");
  }

  // ================= GENERATE CSV =================
  static Future<void> _generateCSV(
    List<List<dynamic>> rows,
    String filename,
  ) async {
    String csvData = const ListToCsvConverter().convert(rows);

    if (kIsWeb) {
      final bytes = csvData.codeUnits;
      await export_helper.downloadBytes(bytes, filename);
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final file = File("${directory.path}/$filename");
      await file.writeAsString(csvData);
    }
  }

  // ================= GENERATE EXCEL =================
  static Future<void> _generateExcel(Excel excel, String filename) async {
    if (kIsWeb) {
      // Download di web
      final bytes = excel.encode()!;
      await export_helper.downloadBytes(bytes, filename);
    } else {
      // Save di mobile/desktop
      final directory = await getApplicationDocumentsDirectory();
      final file = File("${directory.path}/$filename");
      await file.writeAsBytes(excel.encode()!);
    }
  }
}
