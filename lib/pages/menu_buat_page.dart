import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/tenant_helper.dart';
import '../models/menu_kombinasi.dart';

class BuatMenuWidget extends StatefulWidget {
  final MenuKombinasi? menu;

  const BuatMenuWidget({super.key, this.menu});

  @override
  State<BuatMenuWidget> createState() => _BuatMenuWidgetState();
}

class _BuatMenuWidgetState extends State<BuatMenuWidget> {
  late TextEditingController namaController;
  late TextEditingController deskripsiController;
  List<IngredientItem> selectedIngredients = [];
  Map<String, String> selectedKolom = {}; // kategoriId -> pilihanValue

  @override
  void initState() {
    super.initState();
    if (widget.menu != null) {
      namaController = TextEditingController(text: widget.menu!.nama);
      deskripsiController = TextEditingController(text: widget.menu!.deskripsi);
      selectedIngredients = List.from(widget.menu!.ingredients);
      selectedKolom = Map.from(widget.menu!.kolom);
    } else {
      namaController = TextEditingController();
      deskripsiController = TextEditingController();
    }
  }

  @override
  void dispose() {
    namaController.dispose();
    deskripsiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.menu != null ? "Edit Menu" : "Buat Menu Baru"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NAMA MENU
            TextField(
              controller: namaController,
              decoration: const InputDecoration(
                labelText: "Nama Menu",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // DESKRIPSI
            TextField(
              controller: deskripsiController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Deskripsi",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // KOLOM KATEGORI
            const Text(
              "Pilihan Kolom Kombinasi",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream:
                  TenantHelper.isReady
                      ? FirestoreService.getKategoriMenuKombinasi()
                      : null,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!TenantHelper.isReady) {
                  return const Center(child: Text('Menunggu sesi tenant...'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final kategoris =
                    snapshot.data!.docs
                        .map(
                          (doc) =>
                          // ignore: avoid_dynamic_calls
                          MenuKombinasi.fromMap(
                            doc.id,
                            doc.data() as Map<String, dynamic>,
                          ),
                        )
                        .toList();

                // The previous code used a KategoriMenuKombinasi model; keep this area simple
                if (kategoris.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Belum ada kategori. Buat kategori terlebih dahulu di tab 'Kelola Kategori'.",
                    ),
                  );
                }

                return Container();
              },
            ),

            const SizedBox(height: 16),

            // INGREDIENTS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Ingredients",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Tambah"),
                  onPressed: () {
                    _showPilihBarangDialog();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (selectedIngredients.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Belum ada ingredient. Klik tombol Tambah untuk menambahkan.",
                ),
              )
            else
              ...selectedIngredients.asMap().entries.map((entry) {
                final idx = entry.key;
                final ing = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(ing.namaBarang),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${ing.jumlah} ${ing.satuan}"),
                        if (ing.barangId.isEmpty) const SizedBox(height: 4),
                        if (ing.barangId.isEmpty)
                          Text(
                            "Manual — masuk pesanan otomatis",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.redAccent,
                            ),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          selectedIngredients.removeAt(idx);
                        });
                      },
                    ),
                    onTap: () {
                      _showEditIngredientDialog(idx, ing);
                    },
                  ),
                );
              }),

            const SizedBox(height: 24),

            // TOMBOL SIMPAN
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _simpanMenu,
                child: const Text("Simpan Menu"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPilihBarangDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Pilih Barang"),
            content: SizedBox(
              width: double.maxFinite,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirestoreService.getBarang(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final nama = doc['nama'];

                      return ListTile(
                        title: Text(nama),
                        onTap: () {
                          Navigator.pop(context);
                          _showInputJumlahIngredient(
                            doc.id,
                            nama,
                            doc['satuan'] ?? 'pcs',
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal"),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text("Tambah Manual"),
                onPressed: () {
                  Navigator.pop(context);
                  _showTambahManualDialog();
                },
              ),
            ],
          ),
    );
  }

  void _showInputJumlahIngredient(
    String barangId,
    String namaBarang,
    String satuan,
  ) {
    final jumlahController = TextEditingController(text: '1');
    String selectedSatuan = satuan;
    final List<String> daftarSatuan = [
      'pcs',
      'kg',
      'liter',
      'gram',
      'ml',
      'box',
      'bungkus',
      'potong',
      'mangkuk',
    ];

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setStateDialog) => AlertDialog(
                  title: const Text("Jumlah Ingredient"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Barang: $namaBarang"),
                      const SizedBox(height: 12),
                      TextField(
                        controller: jumlahController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Jumlah",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedSatuan,
                        decoration: const InputDecoration(
                          labelText: "Satuan",
                          border: OutlineInputBorder(),
                        ),
                        items:
                            daftarSatuan
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setStateDialog(() {
                            selectedSatuan = value!;
                          });
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Batal"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final jumlah = int.tryParse(jumlahController.text) ?? 1;
                        if (jumlah < 1) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Jumlah harus minimal 1"),
                            ),
                          );
                          return;
                        }

                        setState(() {
                          selectedIngredients.add(
                            IngredientItem(
                              barangId: barangId,
                              namaBarang: namaBarang,
                              jumlah: jumlah,
                              satuan: selectedSatuan,
                            ),
                          );
                        });

                        Navigator.pop(context);
                      },
                      child: const Text("Tambah"),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showTambahManualDialog() {
    final namaController = TextEditingController();
    final jumlahController = TextEditingController(text: '1');
    String selectedSatuan = 'pcs';
    final List<String> daftarSatuan = [
      'pcs',
      'kg',
      'liter',
      'gram',
      'ml',
      'box',
      'bungkus',
      'potong',
      'mangkuk',
    ];

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setStateDialog) => AlertDialog(
                  title: const Text("Tambah Bahan Manual"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: namaController,
                        decoration: const InputDecoration(
                          labelText: "Nama Bahan",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: jumlahController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Jumlah",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedSatuan,
                        decoration: const InputDecoration(
                          labelText: "Satuan",
                          border: OutlineInputBorder(),
                        ),
                        items:
                            daftarSatuan
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setStateDialog(() {
                            selectedSatuan = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Catatan: bahan manual akan otomatis masuk saat membuat pesanan.",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Batal"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final nama = namaController.text.trim();
                        final jumlah = int.tryParse(jumlahController.text) ?? 1;
                        if (nama.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Nama bahan tidak boleh kosong"),
                            ),
                          );
                          return;
                        }

                        if (jumlah < 1) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Jumlah harus minimal 1"),
                            ),
                          );
                          return;
                        }

                        setState(() {
                          selectedIngredients.add(
                            IngredientItem(
                              barangId: '', // empty id marks manual item
                              namaBarang: nama,
                              jumlah: jumlah,
                              satuan: selectedSatuan,
                            ),
                          );
                        });

                        Navigator.pop(context);
                      },
                      child: const Text("Tambah"),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showEditIngredientDialog(int index, IngredientItem ingredient) {
    final jumlahController = TextEditingController(
      text: ingredient.jumlah.toString(),
    );
    String selectedSatuan = ingredient.satuan;
    final List<String> daftarSatuan = [
      'pcs',
      'kg',
      'liter',
      'gram',
      'ml',
      'box',
      'bungkus',
      'potong',
      'mangkuk',
    ];

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setStateDialog) => AlertDialog(
                  title: const Text("Edit Ingredient"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Barang: ${ingredient.namaBarang}"),
                      const SizedBox(height: 12),
                      TextField(
                        controller: jumlahController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Jumlah",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedSatuan,
                        decoration: const InputDecoration(
                          labelText: "Satuan",
                          border: OutlineInputBorder(),
                        ),
                        items:
                            daftarSatuan
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setStateDialog(() {
                            selectedSatuan = value!;
                          });
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Batal"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final jumlah = int.tryParse(jumlahController.text) ?? 1;
                        if (jumlah < 1) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Jumlah harus minimal 1"),
                            ),
                          );
                          return;
                        }

                        setState(() {
                          selectedIngredients[index] = IngredientItem(
                            barangId: ingredient.barangId,
                            namaBarang: ingredient.namaBarang,
                            jumlah: jumlah,
                            satuan: selectedSatuan,
                          );
                        });

                        Navigator.pop(context);
                      },
                      child: const Text("Update"),
                    ),
                  ],
                ),
          ),
    );
  }

  void _simpanMenu() async {
    if (namaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nama menu tidak boleh kosong")),
      );
      return;
    }

    if (selectedIngredients.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Minimal ada 1 ingredient")));
      return;
    }

    try {
      final ingredientsMaps =
          selectedIngredients.map((ing) => ing.toMap()).toList();

      if (widget.menu != null) {
        await FirestoreService.updateMenuKombinasi(
          menuId: widget.menu!.id,
          nama: namaController.text.trim(),
          deskripsi: deskripsiController.text.trim(),
          ingredients: ingredientsMaps,
          kolom: selectedKolom,
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Menu berhasil diupdate")));
      } else {
        await FirestoreService.tambahMenuKombinasi(
          nama: namaController.text.trim(),
          deskripsi: deskripsiController.text.trim(),
          ingredients: ingredientsMaps,
          kolom: selectedKolom,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Menu berhasil ditambahkan")),
        );
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
}
