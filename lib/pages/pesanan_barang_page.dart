import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../services/firestore_service.dart';
import 'barang_page.dart';

class PesananBarangPage extends StatefulWidget {
  const PesananBarangPage({super.key});
  @override
  State<PesananBarangPage> createState() => _PesananBarangPageState();
}

class _PesananBarangPageState extends State<PesananBarangPage> {
  final Map<String, TextEditingController> jumlahCtrl = {};

  @override
  void dispose() {
    for (var c in jumlahCtrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pesan Barang")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService.getBarang(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Belum ada barang"),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("Tambah Barang"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => BarangPage()),
                      );
                    },
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Tambah Barang Baru"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => BarangPage()),
                    );
                  },
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
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
                        2: FlexColumnWidth(1.5),
                        3: FlexColumnWidth(1),
                      },
                      children: [
                        // HEADER
                        TableRow(
                          decoration: BoxDecoration(
                            color: Colors.blue.shade700,
                          ),
                          children: [
                            _buildHeaderCell('Nama Barang'),
                            _buildHeaderCell('Satuan'),
                            _buildHeaderCell('Input'),
                            _buildHeaderCell('Aksi'),
                          ],
                        ),
                        // DATA ROWS
                        ...snapshot.data!.docs.asMap().entries.map((entry) {
                          final index = entry.key;
                          final doc = entry.value;
                          final satuan = doc['satuan'] ?? 'pcs';
                          final isAlternate = index % 2 == 0;

                          jumlahCtrl.putIfAbsent(
                            doc.id,
                            () => TextEditingController(),
                          );

                          return TableRow(
                            decoration: BoxDecoration(
                              color:
                                  isAlternate
                                      ? Colors.grey.shade50
                                      : Colors.white,
                            ),
                            children: [
                              _buildDataCell(doc['nama']),
                              _buildDataCell(
                                satuan,
                                textAlign: TextAlign.center,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 8,
                                ),
                                child: TextField(
                                  controller: jumlahCtrl[doc.id],
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  textInputAction: TextInputAction.done,
                                  enableInteractiveSelection: false,
                                  decoration: const InputDecoration(
                                    hintText: "0",
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.all(8),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 8,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.send, size: 18),
                                  onPressed: () {
                                    _showPesanDialog(
                                      context,
                                      doc.id,
                                      doc['nama'],
                                      satuan,
                                    );
                                  },
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
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

  void _showPesanDialog(
    BuildContext context,
    String barangId,
    String namaBarang,
    String satuan,
  ) {
    DateTime? tanggalPilih = DateTime.now();
    final jumlah = int.tryParse(jumlahCtrl[barangId]!.text);

    if (jumlah == null || jumlah <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Masukkan jumlah yang valid")),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text("Pesan $namaBarang"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Jumlah: $jumlah $satuan"),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final tgl = await showDatePicker(
                      context: context,
                      initialDate: tanggalPilih ?? DateTime.now(),
                      firstDate: DateTime(2022),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (tgl != null) {
                      tanggalPilih = tgl;
                      (context as Element).markNeedsBuild();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 8),
                        Text(
                          "Tanggal: ${DateFormat('dd-MM-yyyy').format(tanggalPilih ?? DateTime.now())}",
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () async {
                  await FirestoreService.buatPesanan(
                    barangId: barangId,
                    namaBarang: namaBarang,
                    jumlahPesanan: jumlah,
                    satuan: satuan,
                    tanggalPesanan: tanggalPilih,
                  );

                  jumlahCtrl[barangId]!.clear();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Pesanan berhasil dibuat untuk tanggal ${DateFormat('dd-MM-yyyy').format(tanggalPilih ?? DateTime.now())}",
                      ),
                    ),
                  );
                },
                child: const Text("Pesan"),
              ),
            ],
          ),
    );
  }
}
