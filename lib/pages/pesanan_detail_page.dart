import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../services/tenant_helper.dart';

class PesananDetailPage extends StatefulWidget {
  final String pesananId;
  final Map<String, dynamic> pesananData;

  const PesananDetailPage({
    super.key,
    required this.pesananId,
    required this.pesananData,
  });

  @override
  State<PesananDetailPage> createState() => _PesananDetailPageState();
}

class _PesananDetailPageState extends State<PesananDetailPage> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: TenantHelper.doc('pesanan', widget.pesananId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detail Pesanan')),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        final data =
            snapshot.hasData && snapshot.data!.data() != null
                ? snapshot.data!.data()!
                : widget.pesananData;

        final isTipeMenu = data['tipeOrder'] == 'MENU';

        return Scaffold(
          appBar: AppBar(
            title: Text(
              isTipeMenu
                  ? data['namaMenu'] ?? 'Detail Pesanan Menu'
                  : data['namaBarang'] ?? 'Detail Pesanan',
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== HEADER INFO =====
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Status: ${data['status'] ?? 'N/A'}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(data['status']),
                              ),
                            ),
                            if (isTipeMenu)
                              Chip(
                                label: const Text("Menu"),
                                backgroundColor: Colors.blue[100],
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Tanggal: ${_formatDate(data['tanggalPesanan'] ?? data['createdAt'])}",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        if (isTipeMenu) ...[
                          const SizedBox(height: 8),
                          Text(
                            "Jumlah Porsi: ${data['jumlahPorsi'] ?? 1}",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ===== INGREDIENTS / ITEMS =====
                Text(
                  isTipeMenu ? "Ingredients yang Dipesan:" : "Detail Barang:",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),

                if (isTipeMenu)
                  _buildMenuIngredients(data['ingredients'] ?? [])
                else
                  _buildSingleItem(data),

                const SizedBox(height: 24),

                if (isTipeMenu)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.sync),
                      label: const Text(
                        "Masukkan Ingredients ke Daftar Pesanan",
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                      onPressed: () async {
                        try {
                          await FirestoreService.syncMenuIngredientsToPesanan(
                            menuPesananId: widget.pesananId,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Ingredients berhasil ditambahkan ke daftar pesanan",
                              ),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text("Error: $e")));
                        }
                      },
                    ),
                  ),

                // ===== ACTION BUTTONS =====
                if (data['status'] == 'DIPESAN' || data['status'] == 'SEBAGIAN')
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text("Update Penerimaan"),
                          onPressed: () {
                            if (isTipeMenu) {
                              _showUpdateMenuPenerimaan(context, data);
                            } else {
                              _showUpdatePenerimaan(context, data);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.cancel),
                          label: const Text("Batalkan"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () {
                            _confirmBatal(context);
                          },
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuIngredients(List<dynamic> ingredients) {
    if (ingredients.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text("Tidak ada ingredients"),
      );
    }

    return Column(
      children:
          ingredients.asMap().entries.map((entry) {
            final ing = entry.value as Map<String, dynamic>;
            final isAlternate = entry.key % 2 == 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAlternate ? Colors.grey[50] : Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ing['namaBarang'] ?? 'N/A',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Dipesan: ${ing['jumlah'] ?? 0} ${ing['satuan'] ?? 'pcs'}",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        if (ing['jumlahDiterima'] != null &&
                            ing['jumlahDiterima'] > 0)
                          Text(
                            "Diterima: ${ing['jumlahDiterima']} ${ing['satuan'] ?? 'pcs'}",
                            style: TextStyle(
                              color: Colors.green[600],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Chip(
                        label: Text(ing['status'] ?? 'DIPESAN'),
                        backgroundColor: _getStatusColor(ing['status']),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildSingleItem(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['namaBarang'] ?? 'N/A',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Dipesan: ${data['jumlahPesan'] ?? 0} ${data['satuan'] ?? 'pcs'}",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    if (data['jumlahDiterima'] != null &&
                        data['jumlahDiterima'] > 0)
                      Text(
                        "Diterima: ${data['jumlahDiterima']} ${data['satuan'] ?? 'pcs'}",
                        style: TextStyle(
                          color: Colors.green[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (data['keterangan'] != null &&
              data['keterangan'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Keterangan:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  Text(
                    data['keterangan'],
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else {
      return 'N/A';
    }
    return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
  }

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'DIPESAN':
        return Colors.orange;
      case 'SEBAGIAN':
        return Colors.blue;
      case 'LENGKAP':
        return Colors.green;
      case 'BATAL':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showUpdatePenerimaan(BuildContext context, Map<String, dynamic> data) {
    final jumlahController = TextEditingController(
      text: (data['jumlahPesan'] ?? 0).toString(),
    );
    final keteranganController = TextEditingController(
      text: data['keterangan'] ?? '',
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Update Penerimaan"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Barang: ${data['namaBarang']}"),
                  const SizedBox(height: 12),
                  TextField(
                    controller: jumlahController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    enableInteractiveSelection: false,
                    decoration: const InputDecoration(
                      labelText: "Jumlah Diterima",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: keteranganController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Keterangan",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final diterima = int.tryParse(jumlahController.text) ?? 0;
                    await FirestoreService.terimaPesanan(
                      pesananId: widget.pesananId,
                      jumlahTerima: diterima,
                      keterangan: keteranganController.text,
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Penerimaan berhasil diupdate"),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Error: $e")));
                  }
                },
                child: const Text("Simpan"),
              ),
            ],
          ),
    );
  }

  void _showUpdateMenuPenerimaan(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final ingredients = (data['ingredients'] as List?) ?? [];

    if (ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada ingredients untuk diupdate")),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Update Penerimaan Menu"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Untuk setiap ingredient yang sudah diterima, masukkan jumlah penerimaan di pesanan BARANG terkait.",
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Ingredients yang perlu diupdate:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...ingredients.map((ing) {
                    final ingData = ing as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ingData['namaBarang'] ?? 'N/A',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "Pesan: ${ingData['jumlah']} ${ingData['satuan']}",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            if (ingData['jumlahDiterima'] != null &&
                                ingData['jumlahDiterima'] > 0)
                              Chip(
                                label: Text(
                                  "Terima: ${ingData['jumlahDiterima']}",
                                ),
                                backgroundColor: Colors.green[100],
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  void _confirmBatal(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Batalkan Pesanan?"),
            content: const Text("Pesanan ini akan dibatalkan"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Tidak"),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await FirestoreService.batalkanPesanan(
                      pesananId: widget.pesananId,
                    );
                    Navigator.pop(context);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Pesanan berhasil dibatalkan"),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Error: $e")));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Ya, Batalkan"),
              ),
            ],
          ),
    );
  }
}
