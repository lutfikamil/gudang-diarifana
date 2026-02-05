import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class BarangKeluarPage extends StatefulWidget {
  const BarangKeluarPage({super.key});
  @override
  State<BarangKeluarPage> createState() => _BarangKeluarPageState();
}

class _BarangKeluarPageState extends State<BarangKeluarPage> {
  final TextEditingController jumlahCtrl = TextEditingController();
  String satuan = 'pcs';
  final List<String> daftarSatuan = ['pcs', 'kg', 'liter', 'gram'];
  @override
  void dispose() {
    jumlahCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Barang Keluar")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService.getBarang(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Table(
                border: TableBorder.all(color: Colors.grey.shade300, width: 1),
                columnWidths: {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(1.5),
                  2: FlexColumnWidth(1.5),
                  3: FlexColumnWidth(1.5),
                },
                children: [
                  // HEADER
                  TableRow(
                    decoration: BoxDecoration(color: Colors.blue.shade700),
                    children: [
                      _buildHeaderCell('Nama Barang'),
                      _buildHeaderCell('Stok'),
                      _buildHeaderCell('Satuan'),
                      _buildHeaderCell('Aksi'),
                    ],
                  ),
                  // DATA ROWS
                  ...snapshot.data!.docs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final doc = entry.value;
                    final stok = doc['stok'].toString();
                    final satuan = doc['satuan'] ?? 'pcs';
                    final isAlternate = index % 2 == 0;

                    return TableRow(
                      decoration: BoxDecoration(
                        color: isAlternate ? Colors.grey.shade50 : Colors.white,
                      ),
                      children: [
                        _buildDataCell(doc['nama']),
                        _buildDataCell(stok, textAlign: TextAlign.center),
                        _buildDataCell(satuan, textAlign: TextAlign.center),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          child: Center(
                            child: IconButton(
                              icon: const Icon(Icons.remove, size: 20),
                              onPressed: () {
                                _dialogKeluar(
                                  context,
                                  doc.id,
                                  doc['nama'],
                                  doc['satuan'] ?? 'pcs',
                                );
                              },
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              iconSize: 20,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ================= HELPER WIDGETS =================

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

  void _dialogKeluar(
    BuildContext context,
    String barangId,
    String namaBarang,
    String satuanBarang,
  ) {
    satuan = satuanBarang; // set satuan dari barang
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text("Barang Keluar - $namaBarang"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: jumlahCtrl,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  enableInteractiveSelection: false,
                  decoration: const InputDecoration(labelText: "Jumlah"),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: satuan,
                  items:
                      daftarSatuan
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => satuan = v!),
                  decoration: const InputDecoration(labelText: "Satuan"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                child: const Text("Simpan"),
                onPressed: () async {
                  final jumlah = int.tryParse(jumlahCtrl.text);
                  if (jumlah == null || jumlah <= 0) return;

                  try {
                    await FirestoreService.barangKeluar(
                      barangId: barangId,
                      namaBarang: namaBarang,
                      jumlah: jumlah,
                      satuan: satuan,
                      keterangan: 'sesuai kebutuhan',
                      waktu: Timestamp.now(),
                    );

                    jumlahCtrl.clear();
                    satuan = 'pcs';
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Stok tidak cukup")),
                    );
                  }
                },
              ),
            ],
          ),
    );
  }
}
