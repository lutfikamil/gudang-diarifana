import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';

class PesananSelesaiPage extends StatefulWidget {
  @override
  State<PesananSelesaiPage> createState() => _PesananSelesaiPageState();
}

class _PesananSelesaiPageState extends State<PesananSelesaiPage> {
  final df = DateFormat('dd-MM-yyyy');
  DateTimeRange? filterRange;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pesanan Selesai"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Filter Tanggal',
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2022),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (range != null) {
                setState(() => filterRange = range);
              }
            },
          ),
          if (filterRange != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Hapus Filter',
              onPressed: () => setState(() => filterRange = null),
            ),
        ],
      ),
      body: Column(
        children: [
          // ========== FILTER INFO ==========
          if (filterRange != null)
            Container(
              color: Colors.green.shade50,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filter: ${df.format(filterRange!.start)} - ${df.format(filterRange!.end)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ========== DAFTAR PESANAN SELESAI ==========
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirestoreService.getPesanan(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Filter hanya status LENGKAP dan BATAL
                var pesananSelesai =
                    snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      final status = data['status'];
                      final tipeOrder = data['tipeOrder']; // bisa null

                      return (status == 'LENGKAP' || status == 'BATAL') &&
                          tipeOrder !=
                              'MENU'; // kalau null ≠ MENU → tetap lolos
                    }).toList();

                // ========== FILTER TANGGAL ==========
                if (filterRange != null) {
                  pesananSelesai =
                      pesananSelesai.where((doc) {
                        final tanggalPesan =
                            (doc['tanggalPesanan'] as Timestamp?)?.toDate() ??
                            (doc['createdAt'] as Timestamp).toDate();

                        final isAfterStart =
                            tanggalPesan.isAfter(
                              DateTime(
                                filterRange!.start.year,
                                filterRange!.start.month,
                                filterRange!.start.day,
                              ),
                            ) ||
                            (tanggalPesan.year == filterRange!.start.year &&
                                tanggalPesan.month ==
                                    filterRange!.start.month &&
                                tanggalPesan.day == filterRange!.start.day);

                        final isBeforeEnd =
                            tanggalPesan.isBefore(
                              DateTime(
                                filterRange!.end.year,
                                filterRange!.end.month,
                                filterRange!.end.day,
                                23,
                                59,
                                59,
                              ),
                            ) ||
                            (tanggalPesan.year == filterRange!.end.year &&
                                tanggalPesan.month == filterRange!.end.month &&
                                tanggalPesan.day == filterRange!.end.day);

                        return isAfterStart && isBeforeEnd;
                      }).toList();
                }

                if (pesananSelesai.isEmpty) {
                  return const Center(child: Text("Tidak ada pesanan selesai"));
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Table(
                      border: TableBorder.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      columnWidths: {
                        0: FlexColumnWidth(2.5),
                        1: FlexColumnWidth(1.5),
                        2: FlexColumnWidth(1),
                        3: FlexColumnWidth(1.5),
                        4: FlexColumnWidth(1),
                        5: FlexColumnWidth(1),
                      },
                      children: [
                        // HEADER
                        TableRow(
                          decoration: BoxDecoration(
                            color: Colors.blue.shade700,
                          ),
                          children: [
                            _buildHeaderCell('Nama Barang'),
                            _buildHeaderCell('Dipesan'),
                            _buildHeaderCell('Satuan'),
                            _buildHeaderCell('Diterima'),
                            _buildHeaderCell('Status'),
                            _buildHeaderCell('Aksi'),
                          ],
                        ),
                        // DATA ROWS
                        ...pesananSelesai.asMap().entries.map((entry) {
                          final index = entry.key;
                          final doc = entry.value;
                          final satuan = doc['satuan'] ?? 'pcs';
                          final namaBarang = doc['namaBarang'] ?? '-';
                          final statusColor =
                              doc['status'] == 'LENGKAP'
                                  ? Colors.green
                                  : Colors.orange;
                          final isAlternate = index % 2 == 0;

                          return TableRow(
                            decoration: BoxDecoration(
                              color:
                                  isAlternate
                                      ? Colors.grey.shade50
                                      : Colors.white,
                            ),
                            children: [
                              _buildDataCell(namaBarang),
                              _buildDataCell(
                                doc['jumlahPesan']?.toString() ?? '0',
                                textAlign: TextAlign.center,
                              ),
                              _buildDataCell(
                                satuan,
                                textAlign: TextAlign.center,
                              ),
                              _buildDataCell(
                                doc['jumlahDiterima']?.toString() ?? '0',
                                textAlign: TextAlign.center,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 8,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Center(
                                    child: Text(
                                      doc['status'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 8,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 16,
                                  ),
                                  onPressed: () {
                                    _confirmDelete(context, doc);
                                  },
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================= HELPER WIDGETS =================

  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataCell(String text, {TextAlign textAlign = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11),
        textAlign: textAlign,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _confirmDelete(BuildContext context, DocumentSnapshot doc) {
    final namaBarang = doc['namaBarang'] ?? 'pesanan';
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Hapus Pesanan?"),
            content: Text(
              "Apakah Anda yakin ingin menghapus pesanan $namaBarang?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () async {
                  await FirestoreService.hapusPesanan(pesananId: doc.id);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Pesanan berhasil dihapus")),
                  );
                },
                child: const Text("Hapus"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
    );
  }
}
