import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../services/firestore_service.dart';
import 'pesanan_selesai_page.dart';
import 'pesanan_detail_page.dart';
import '../services/tenant_helper.dart';

class DaftarPesananPage extends StatefulWidget {
  const DaftarPesananPage({super.key});
  @override
  State<DaftarPesananPage> createState() => _DaftarPesananPageState();
}

class _DaftarPesananPageState extends State<DaftarPesananPage>
    with TickerProviderStateMixin {
  final df = DateFormat('dd-MM-yyyy');
  DateTimeRange? filterRange;
  late TabController _tabController;
  DateTime? tanggalSpesifik;
  Future<void> _terimaBarang(DocumentSnapshot doc, int jumlahTerima) async {
    final data = doc.data() as Map<String, dynamic>;

    final int pesanan = data['jumlahPesan'] ?? 0;
    final int diterimaLama = data['jumlahDiterima'] ?? 0;

    final int diterimaBaru = diterimaLama + jumlahTerima;

    String statusBaru = 'DIPESAN';
    if (diterimaBaru > 0 && diterimaBaru < pesanan) {
      statusBaru = 'SEBAGIAN';
    } else if (diterimaBaru >= pesanan) {
      statusBaru = 'LENGKAP';
    }

    await TenantHelper.doc('pesanan', doc.id).update({
      'jumlahDiterima': diterimaBaru,
      'status': statusBaru,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  void initState() {
    super.initState();
    //    WidgetsBinding.instance.addPostFrameCallback((_) {
    _tabController = TabController(length: 3, vsync: this);
    //    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pesanan Berlangsung"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.today), text: "Hari Ini"),
            Tab(icon: Icon(Icons.calendar_month), text: "Akan Datang"),
            Tab(icon: Icon(Icons.date_range), text: "Tanggal"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2022),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (range != null) setState(() => filterRange = range);
            },
          ),
          if (filterRange != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() => filterRange = null),
            ),
          IconButton(
            icon: const Icon(Icons.check_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PesananSelesaiPage()),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPesananHariIni(),
          _buildPesananAkanDatang(),
          _buildPesananTanggalSpesifik(),
        ],
      ),
    );
  }

  // ================= PESANAN HARI INI =================
  Widget _buildPesananHariIni() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.getPesanan(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        print('Pesanan docs: ${snapshot.data?.docs.length}');

        // Filter: status != HAPUS dan tanggal pesanan = hari ini
        final today = DateTime.now();
        final pesananHariIni =
            snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final status = (data['status'] ?? '').toString();
              if (status == 'HAPUS' || status == 'BATAL') return false;

              final tgl =
                  (data['tanggalPesanan'] as Timestamp?)?.toDate() ??
                  (data['createdAt'] as Timestamp).toDate();

              return tgl.year == today.year &&
                  tgl.month == today.month &&
                  tgl.day == today.day;
            }).toList();

        if (pesananHariIni.isEmpty) {
          return const Center(child: Text("Tidak ada pesanan untuk hari ini"));
        }

        return _buildPesananContent(pesananHariIni);
      },
    );
  }

  // ================= PESANAN AKAN DATANG =================
  Widget _buildPesananAkanDatang() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.getPesanan(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final today = DateTime.now();
        final endToday = DateTime(
          today.year,
          today.month,
          today.day,
          23,
          59,
          59,
        );

        final pesananAkanDatang =
            snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final status = (data['status'] ?? '').toString();
              if (status == 'HAPUS' || status == 'BATAL') return false;

              final tgl =
                  (data['tanggalPesanan'] as Timestamp?)?.toDate() ??
                  (data['createdAt'] as Timestamp).toDate();

              // ✅ FIX UTAMA DI SINI
              return tgl.isAfter(endToday);
            }).toList();

        if (pesananAkanDatang.isEmpty) {
          return const Center(
            child: Text("Tidak ada pesanan yang akan datang"),
          );
        }

        return _buildPesananContent(pesananAkanDatang);
      },
    );
  }

  // ================= PESANAN TANGGAL SPESIFIK =================
  Widget _buildPesananTanggalSpesifik() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    tanggalSpesifik == null
                        ? 'Pilih Tanggal'
                        : DateFormat(
                          'dd MMM yyyy',
                          'id_ID',
                        ).format(tanggalSpesifik!),
                  ),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: tanggalSpesifik ?? DateTime.now(),
                      firstDate: DateTime(2022),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => tanggalSpesifik = date);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              if (tanggalSpesifik != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => tanggalSpesifik = null),
                ),
            ],
          ),
        ),
        if (tanggalSpesifik == null)
          const Expanded(
            child: Center(child: Text("Pilih tanggal untuk melihat pesanan")),
          )
        else
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirestoreService.getPesanan(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                // Filter: status != HAPUS dan tanggal pesanan = tanggalSpesifik
                final pesananTanggalSpesifik =
                    snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final status = (data['status'] ?? '').toString();
                      if (status == 'HAPUS' || status == 'BATAL') return false;

                      final tgl =
                          (data['tanggalPesanan'] as Timestamp?)?.toDate() ??
                          (data['createdAt'] as Timestamp).toDate();

                      return tgl.year == tanggalSpesifik!.year &&
                          tgl.month == tanggalSpesifik!.month &&
                          tgl.day == tanggalSpesifik!.day;
                    }).toList();

                if (pesananTanggalSpesifik.isEmpty) {
                  return Center(
                    child: Text(
                      "Tidak ada pesanan untuk ${DateFormat('dd MMM yyyy', 'id_ID').format(tanggalSpesifik!)}",
                    ),
                  );
                }

                return _buildPesananContent(pesananTanggalSpesifik);
              },
            ),
          ),
      ],
    );
  }

  // ================= BUILD PESANAN CONTENT =================
  Widget _buildPesananContent(List<DocumentSnapshot> allDocs) {
    // Pisahkan MENU dan BARANG
    final menuOrders =
        allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['tipeOrder'] == 'MENU';
        }).toList();

    final barangOrders =
        allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['tipeOrder'] != 'MENU';
        }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ================= MENU =================
          ...menuOrders.map((doc) => _menuCard(context, doc)),

          /// ================= BARANG =================
          if (barangOrders.isNotEmpty) _barangTable(barangOrders),
        ],
      ),
    );
  }

  // ================= MENU CARD =================

  Widget _menuCard(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'] ?? 'DIPESAN';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// CHIP MENU
            const Chip(
              label: Text('MENU'),
              backgroundColor: Colors.blue,
              labelStyle: TextStyle(color: Colors.white),
              visualDensity: VisualDensity.compact,
            ),

            const SizedBox(width: 8),

            /// NAMA MENU (fleksibel)
            Expanded(
              flex: 3,
              child: Text(
                data['namaMenu'] ?? '-',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            /// PORSI
            Expanded(
              flex: 1,
              child: Text(
                "Porsi: ${data['jumlahPorsi'] ?? 1}",
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),

            /// STATUS
            Expanded(flex: 1, child: _statusBadge(status)),

            /// AKSI
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, size: 20),
                  tooltip: 'Detail',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => PesananDetailPage(
                              pesananId: doc.id,
                              pesananData: data,
                            ),
                      ),
                    );
                  },
                ),

                if (status != 'HAPUS' && status != 'BATAL') ...[
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    tooltip: 'Ubah Status',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Ubah Status Pesanan'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // SEBAGIAN - hanya tampil jika status DIPESAN atau SEBAGIAN
                                if (status == 'DIPESAN' || status == 'SEBAGIAN')
                                  ListTile(
                                    leading: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                    title: const Text('SEBAGIAN'),
                                    subtitle: const Text(
                                      'Sudah diterima sebagian',
                                    ),
                                    onTap: () async {
                                      await TenantHelper.doc(
                                        'pesanan',
                                        doc.id,
                                      ).update({
                                        'status': 'SEBAGIAN',
                                        'updatedAt':
                                            FieldValue.serverTimestamp(),
                                      });
                                      Navigator.pop(context);
                                    },
                                  ),

                                // LENGKAP - tampil jika status DIPESAN, SEBAGIAN, atau sudah LENGKAP
                                if (status == 'DIPESAN' ||
                                    status == 'SEBAGIAN' ||
                                    status == 'LENGKAP')
                                  ListTile(
                                    leading: const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    ),
                                    title: const Text('LENGKAP'),
                                    subtitle: const Text(
                                      'Sudah diterima semua',
                                    ),
                                    onTap: () async {
                                      await TenantHelper.doc(
                                        'pesanan',
                                        doc.id,
                                      ).update({
                                        'status': 'LENGKAP',
                                        'updatedAt':
                                            FieldValue.serverTimestamp(),
                                      });
                                      Navigator.pop(context);
                                    },
                                  ),

                                // BATAL - tampil untuk semua status
                                ListTile(
                                  leading: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  title: const Text('BATAL'),
                                  subtitle: Text(
                                    status == 'LENGKAP'
                                        ? 'Selesaikan pesanan'
                                        : 'Batalkan pesanan',
                                  ),
                                  onTap: () async {
                                    // Konfirmasi sebelum batal
                                    showDialog(
                                      context: context,
                                      builder:
                                          (ctx) => AlertDialog(
                                            title: const Text(
                                              'Konfirmasi Batal',
                                            ),
                                            content: Text(
                                              'Yakin ingin ${status == 'LENGKAP' ? 'menyelesaikan' : 'membatalkan'} pesanan ini?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(ctx),
                                                child: const Text('Tidak'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  await TenantHelper.doc(
                                                    'pesanan',
                                                    doc.id,
                                                  ).update({
                                                    'status': 'BATAL',
                                                    'updatedAt':
                                                        FieldValue.serverTimestamp(),
                                                  });
                                                  Navigator.pop(ctx);
                                                  Navigator.pop(context);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                ),
                                                child: const Text('Batal'),
                                              ),
                                            ],
                                          ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= BARANG TABLE =================

  Widget _barangTable(List<DocumentSnapshot> docs) {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {
        0: FlexColumnWidth(2.5),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1),
        5: FlexColumnWidth(1.2),
      },
      children: [
        _tableHeader(),
        ...docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final pesan = data['jumlahPesanan'] ?? 0;
          final terima = data['jumlahDiterima'] ?? 0;
          final sisa = pesan - terima;

          return TableRow(
            children: [
              _cell(data['namaBarang']),
              _cell(pesan.toString()),
              _cell(terima.toString()),
              _cell(sisa.toString()),
              _cell(data['satuan']),

              // ===== AKSI =====
              Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed:
                          sisa <= 0
                              ? null
                              : () {
                                _showTerimaDialog(doc, sisa);
                              },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.green,
                      ),
                      child: const Text(
                        "Terima",
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 6),
                    TextButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder:
                              (ctx) => AlertDialog(
                                title: const Text('Konfirmasi Batalkan'),
                                content: const Text(
                                  'Batalkan pesanan barang ini?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Tidak'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Ya'),
                                  ),
                                ],
                              ),
                        );
                        if (confirm == true) {
                          await TenantHelper.doc('pesanan', doc.id).update({
                            'status': 'BATAL',
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Pesanan barang dibatalkan'),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Batal',
                        style: TextStyle(color: Colors.red, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  // ================= HELPER =================

  TableRow _tableHeader() {
    return TableRow(
      decoration: BoxDecoration(color: Colors.blue.shade700),
      children: const [
        _Header("Barang"),
        _Header("Pesan"),
        _Header("Terima"),
        _Header("Sisa"),
        _Header("Satuan"),
        _Header("Aksi"),
      ],
    );
  }

  void _showTerimaDialog(DocumentSnapshot doc, int maxSisa) {
    final controller = TextEditingController(text: "1");

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Terima Barang"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Jumlah diterima",
              helperText: "Maksimal: $maxSisa",
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Batal"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Simpan"),
              onPressed: () async {
                final jumlah = int.tryParse(controller.text) ?? 0;

                if (jumlah <= 0 || jumlah > maxSisa) return;

                await _terimaBarang(doc, jumlah);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _cell(String? text) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Text(text ?? '-', textAlign: TextAlign.center),
    );
  }

  Widget _statusBadge(String? status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: _statusColor(status),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status ?? '-',
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'DIPESAN':
        return Colors.blue;
      case 'SEBAGIAN':
        return Colors.orange;
      case 'LENGKAP':
        return Colors.green;
      case 'BATAL':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('Tenant ID: ${TenantHelper.tenantId}');
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
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
}
