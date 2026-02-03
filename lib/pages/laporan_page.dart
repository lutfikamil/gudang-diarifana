import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/laporan_service.dart';
import '../utils/excel_export.dart';
import '../utils/pdf_export.dart';
import '../utils/date_range_helper.dart';

class LaporanPage extends StatefulWidget {
  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  final service = LaporanService();

  List<Map<String, dynamic>> laporan = [];
  bool loading = false;

  String mode = 'HARIAN'; // HARIAN | BULANAN | CUSTOM
  String tipe = 'GLOBAL'; // GLOBAL | MASUK | KELUAR

  DateTimeRange? customRange;
  DateTime selectedMonth = DateTime.now(); // ✅ FIX BULANAN

  final df = DateFormat('dd-MM-yyyy HH:mm');

  // ================= LOAD CORE =================
  Future<void> pilihBulan() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        selectedMonth = DateTime(picked.year, picked.month);
        mode = 'BULANAN';
      });
      loadBulanan();
    }
  }

  Future<void> loadLaporan({
    required Timestamp start,
    required Timestamp end,
  }) async {
    setState(() => loading = true);

    try {
      if (tipe == 'MASUK') {
        laporan = await service.getLaporanMasuk(start, end);
      } else if (tipe == 'KELUAR') {
        laporan = await service.getLaporanKeluar(start, end);
      } else {
        // GLOBAL: gabungkan masuk + keluar ke daftar kronologis
        final masuk = await service.getLaporanMasuk(start, end);
        final keluar = await service.getLaporanKeluar(start, end);

        final List<Map<String, dynamic>> combined = [];

        for (var m in masuk) {
          combined.add({
            'waktu': m['waktu'],
            'namaBarang': m['namaBarang'],
            'masuk': m['jumlah'] ?? 0,
            'keluar': 0,
            'satuan': m['satuan'],
            'user': m['user'],
            'tipe': m['tipe'],
          });
        }

        for (var k in keluar) {
          combined.add({
            'waktu': k['waktu'],
            'namaBarang': k['namaBarang'],
            'masuk': 0,
            'keluar': k['jumlah'] ?? 0,
            'satuan': k['satuan'],
            'user': k['user'],
            'tipe': k['tipe'],
          });
        }

        combined.sort(
          (a, b) => (a['waktu'] as DateTime).compareTo(b['waktu'] as DateTime),
        );
        laporan = combined;
      }
    } catch (e, st) {
      debugPrint('$e');
      debugPrint('$st');
    }

    setState(() => loading = false);
  }

  // ================= LOAD HARIAN =================
  void loadHarian() {
    final range = DateRangeHelper.harian(DateTime.now());
    loadLaporan(start: range['start']!, end: range['end']!);
  }

  // ================= LOAD BULANAN (REFAKTOR FINAL) =================
  void loadBulanan() {
    final range = DateRangeHelper.bulanan(selectedMonth);
    loadLaporan(start: range['start']!, end: range['end']!);
  }

  // ================= LOAD CUSTOM =================
  Future<void> loadCustom() async {
    if (customRange == null) return;

    final range = DateRangeHelper.customRange(
      customRange!.start,
      customRange!.end,
    );

    loadLaporan(start: range['start']!, end: range['end']!);
  }

  // ================= DATE PICKER =================
  Future<void> pilihTanggalCustom() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
    );

    if (range != null) {
      setState(() {
        customRange = range;
        mode = 'CUSTOM';
      });
      await loadCustom();
    }
  }

  // ================= EXPORT =================
  Future<void> exportKeExcel() async {
    if (laporan.isEmpty) return;
    await exportExcel(laporan);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Excel berhasil dibuat')));
  }

  Future<void> exportKePdf() async {
    if (laporan.isEmpty) return;
    await exportPdf(laporan);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('PDF berhasil dibuat')));
  }

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    loadHarian();
  }

  // ================= UI HELPERS =================
  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataCell(String text, {TextAlign textAlign = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
        textAlign: textAlign,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'excel') exportKeExcel();
              if (value == 'pdf') exportKePdf();
            },
            itemBuilder:
                (context) => const [
                  PopupMenuItem(value: 'excel', child: Text('Export Excel')),
                  PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
                ],
            enabled: laporan.isNotEmpty,
          ),

          if (mode == 'BULANAN')
            IconButton(
              icon: const Icon(Icons.calendar_month),
              tooltip: 'Pilih Bulan',
              onPressed: pilihBulan,
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'excel') exportKeExcel();
              if (value == 'pdf') exportKePdf();
            },
            itemBuilder:
                (context) => const [
                  PopupMenuItem(value: 'excel', child: Text('Export Excel')),
                  PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
                ],
            enabled: laporan.isNotEmpty,
          ),
        ],
      ),
      body: Column(
        children: [
          // ================= TIPE =================
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'GLOBAL',
                  label: Text('Global'),
                  icon: Icon(Icons.view_list),
                ),
                ButtonSegment(
                  value: 'MASUK',
                  label: Text('Masuk'),
                  icon: Icon(Icons.arrow_downward),
                ),
                ButtonSegment(
                  value: 'KELUAR',
                  label: Text('Keluar'),
                  icon: Icon(Icons.arrow_upward),
                ),
              ],
              selected: {tipe},
              onSelectionChanged: (v) {
                setState(() {
                  tipe = v.first;
                  mode = 'HARIAN';
                  customRange = null;
                });
                loadHarian();
              },
            ),
          ),

          // ================= FILTER =================
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Harian'),
                selected: mode == 'HARIAN',
                onSelected: (_) {
                  setState(() => mode = 'HARIAN');
                  loadHarian();
                },
              ),
              ChoiceChip(
                label: const Text('Bulanan'),
                selected: mode == 'BULANAN',
                onSelected: (_) {
                  setState(() => mode = 'BULANAN');
                  loadBulanan();
                },
              ),
              ChoiceChip(
                label: const Text('Custom'),
                selected: mode == 'CUSTOM',
                onSelected: (_) => pilihTanggalCustom(),
              ),
            ],
          ),
          if (mode == 'BULANAN')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                DateFormat('MMMM yyyy', 'id_ID').format(selectedMonth),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

          // ================= TABLE =================
          Expanded(
            child:
                loading
                    ? const Center(child: CircularProgressIndicator())
                    : laporan.isEmpty
                    ? const Center(child: Text('Tidak ada data'))
                    : SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child:
                          tipe == 'GLOBAL'
                              ? Table(
                                border: TableBorder.all(
                                  color: Colors.grey.shade300,
                                ),
                                columnWidths: const {
                                  0: FlexColumnWidth(2.5),
                                  1: FlexColumnWidth(3),
                                  2: FlexColumnWidth(1.2),
                                  3: FlexColumnWidth(1.2),
                                  4: FlexColumnWidth(1.2),
                                  5: FlexColumnWidth(1.5),
                                },
                                children: [
                                  TableRow(
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade700,
                                    ),
                                    children:
                                        [
                                          'Tanggal',
                                          'Nama Barang',
                                          'Masuk',
                                          'Keluar',
                                          'Satuan',
                                          'User',
                                        ].map(_buildHeaderCell).toList(),
                                  ),
                                  ...laporan.map((item) {
                                    return TableRow(
                                      children: [
                                        _buildDataCell(
                                          df.format(item['waktu']),
                                        ),
                                        _buildDataCell(item['namaBarang']),
                                        _buildDataCell(
                                          (item['masuk'] ?? 0).toString(),
                                          textAlign: TextAlign.center,
                                        ),
                                        _buildDataCell(
                                          (item['keluar'] ?? 0).toString(),
                                          textAlign: TextAlign.center,
                                        ),
                                        _buildDataCell(
                                          item['satuan'] ?? '-',
                                          textAlign: TextAlign.center,
                                        ),
                                        _buildDataCell(
                                          item['user'] ?? '-',
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    );
                                  }),
                                ],
                              )
                              : Table(
                                border: TableBorder.all(
                                  color: Colors.grey.shade300,
                                ),
                                columnWidths: const {
                                  0: FlexColumnWidth(2.5),
                                  1: FlexColumnWidth(3),
                                  2: FlexColumnWidth(1.5),
                                  3: FlexColumnWidth(1.5),
                                  4: FlexColumnWidth(1.5),
                                },
                                children: [
                                  TableRow(
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade700,
                                    ),
                                    children:
                                        [
                                          'Tanggal',
                                          'Nama Barang',
                                          'Jumlah',
                                          'Satuan',
                                          'User',
                                        ].map(_buildHeaderCell).toList(),
                                  ),
                                  ...laporan.map((item) {
                                    return TableRow(
                                      children: [
                                        _buildDataCell(
                                          df.format(item['waktu']),
                                        ),
                                        _buildDataCell(item['namaBarang']),
                                        _buildDataCell(
                                          item['jumlah'].toString(),
                                          textAlign: TextAlign.center,
                                        ),
                                        _buildDataCell(
                                          item['satuan'],
                                          textAlign: TextAlign.center,
                                        ),
                                        _buildDataCell(
                                          item['user'],
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                    ),
          ),
        ],
      ),
    );
  }
}
