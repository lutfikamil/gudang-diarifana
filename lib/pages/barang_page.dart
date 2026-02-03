import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/export_service.dart';
import '../auth/login_page.dart';

class BarangPage extends StatefulWidget {
  const BarangPage({super.key});
  @override
  State<BarangPage> createState() => _BarangPageState();
}

class _BarangPageState extends State<BarangPage> {
  final TextEditingController namaController = TextEditingController();
  final TextEditingController stokController = TextEditingController();

  String satuan = 'pcs';
  String? selectedKategori;
  final List<String> daftarSatuan = ['pcs', 'kg', 'liter', 'gram'];
  final List<String> daftarKategori = [
    'Pokok',
    'Sayur & Buah',
    'Bumbu',
    'Lainnya',
  ];

  void showTambahBarangDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Tambah Barang"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // NAMA BARANG
              TextField(
                controller: namaController,
                decoration: const InputDecoration(labelText: "Nama Barang"),
              ),
              const SizedBox(height: 8),

              // JUMLAH (ANGKA SAJA)
              TextField(
                controller: stokController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                enableInteractiveSelection: false,
                decoration: const InputDecoration(labelText: "Jumlah"),
              ),
              const SizedBox(height: 8),

              // SATUAN
              DropdownButtonFormField<String>(
                value: satuan,
                items:
                    daftarSatuan
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    satuan = value!;
                  });
                },
                decoration: const InputDecoration(labelText: "Satuan"),
              ),
              const SizedBox(height: 8),

              // KATEGORI
              DropdownButtonFormField<String>(
                value: selectedKategori,
                items:
                    daftarKategori
                        .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedKategori = value!;
                  });
                },
                decoration: const InputDecoration(labelText: "Kategori"),
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
                if (namaController.text.trim().isEmpty ||
                    stokController.text.trim().isEmpty) {
                  return;
                }

                if (selectedKategori == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pilih kategori terlebih dahulu'),
                    ),
                  );
                  return;
                }

                await FirestoreService.tambahBarang(
                  nama: namaController.text.trim(),
                  stok: int.parse(stokController.text),
                  satuan: satuan,
                  kategori: selectedKategori!,
                );

                namaController.clear();
                stokController.clear();
                satuan = 'pcs';
                selectedKategori = null;
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  void showEditKategoriDialog(
    BuildContext context,
    String docId,
    String kategoriSaat,
  ) {
    // Validasi kategori, jika tidak ada di list gunakan default pertama
    String tempKategori =
        daftarKategori.contains(kategoriSaat)
            ? kategoriSaat
            : daftarKategori.first;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Edit Kategori"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: tempKategori,
                items:
                    daftarKategori
                        .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                        .toList(),
                onChanged: (value) {
                  tempKategori = value!;
                },
                decoration: const InputDecoration(labelText: "Kategori"),
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
                await FirestoreService.updateBarangKategori(
                  docId,
                  tempKategori,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stok Barang"),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: "Download Excel",
            onPressed: () => _downloadExcel(context),
          ),
          IconButton(
            icon: const Icon(Icons.upload),
            tooltip: "Upload Excel",
            onPressed: () => _uploadExcel(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => LoginPage()),
                  (_) => false,
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService.getBarang(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Belum ada barang"));
          }

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Table(
                border: TableBorder.all(color: Colors.grey.shade300, width: 1),
                columnWidths: {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(1.5),
                  3: FlexColumnWidth(1.5),
                },
                children: [
                  // HEADER
                  TableRow(
                    decoration: BoxDecoration(color: Colors.blue.shade700),
                    children: [
                      _buildHeaderCell('Nama Barang'),
                      _buildHeaderCell('Kategori'),
                      _buildHeaderCell('Stok'),
                      _buildHeaderCell('Satuan'),
                    ],
                  ),
                  // DATA ROWS
                  ...snapshot.data!.docs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final doc = entry.value;
                    final data = doc.data() as Map<String, dynamic>;
                    final stok = data['stok'] ?? 0;
                    final satuan = data['satuan'] ?? 'pcs';
                    final kategori = data['kategori'] ?? '-';
                    final isAlternate = index % 2 == 0;

                    return TableRow(
                      decoration: BoxDecoration(
                        color: isAlternate ? Colors.grey.shade50 : Colors.white,
                      ),
                      children: [
                        _buildDataCell(doc['nama']),
                        GestureDetector(
                          onTap:
                              () => showEditKategoriDialog(
                                context,
                                doc.id,
                                kategori,
                              ),
                          child: _buildDataCell(
                            kategori,
                            textAlign: TextAlign.center,
                            isClickable: true,
                          ),
                        ),
                        _buildDataCell(
                          stok.toString(),
                          textAlign: TextAlign.center,
                        ),
                        _buildDataCell(satuan, textAlign: TextAlign.center),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => showTambahBarangDialog(context),
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

  Widget _buildDataCell(
    String text, {
    TextAlign textAlign = TextAlign.left,
    bool isClickable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: isClickable ? Colors.blue : Colors.black,
          decoration:
              isClickable ? TextDecoration.underline : TextDecoration.none,
        ),
        textAlign: textAlign,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ================= DOWNLOAD EXCEL =================
  Future<void> _downloadExcel(BuildContext context) async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Mengunduh file Excel...')));
      await ExportService.exportStokBarangToExcel();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File Excel berhasil diunduh')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // ================= UPLOAD EXCEL =================
  Future<void> _uploadExcel(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null) return;

      final bytes = result.files.first.bytes;
      if (bytes == null) throw Exception('Gagal membaca file');

      // Tampilkan dialog konfirmasi
      if (!mounted) return;
      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Konfirmasi Import'),
              content: const Text(
                'File Excel akan diproses. Barang yang ada akan diupdate, barang baru akan ditambahkan.\n\n'
                'Format Excel: Nama Barang | Stok | Satuan | Kategori',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    if (!mounted) return;
                    await _processExcelImport(context, bytes);
                  },
                  child: const Text('Lanjutkan'),
                ),
              ],
            ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // ================= PROCESS EXCEL IMPORT =================
  Future<void> _processExcelImport(
    BuildContext context,
    Uint8List bytes,
  ) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Memproses file Excel...'),
          duration: Duration(minutes: 1),
        ),
      );

      final result = await FirestoreService.importStokDariExcel(bytes);

      if (!mounted) return;

      final berhasil = result['berhasil'] as int;
      final gagal = result['gagal'] as int;
      final errors = result['errors'] as List<String>;

      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Hasil Import'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Berhasil: $berhasil',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gagal: $gagal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: gagal > 0 ? Colors.red : Colors.grey,
                      ),
                    ),
                    if (errors.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Error Details:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:
                              errors.take(5).map((error) {
                                return Text(
                                  '• $error',
                                  style: const TextStyle(fontSize: 12),
                                );
                              }).toList(),
                        ),
                      ),
                      if (errors.length > 5)
                        Text(
                          '... dan ${errors.length - 5} error lainnya',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import selesai: $berhasil berhasil, $gagal gagal'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
