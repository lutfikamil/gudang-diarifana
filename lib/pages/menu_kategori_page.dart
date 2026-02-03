import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/tenant_helper.dart';
import '../models/kategori_menu_kombinasi.dart';

class MenuKategoriPage extends StatefulWidget {
  const MenuKategoriPage({super.key});

  @override
  State<MenuKategoriPage> createState() => _MenuKategoriPageState();
}

class _MenuKategoriPageState extends State<MenuKategoriPage> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          TenantHelper.isReady
              ? FirestoreService.getKategoriMenuKombinasi()
              : null,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (!TenantHelper.isReady) {
          return const Scaffold(
            body: Center(child: Text('Menunggu sesi tenant...')),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final kategoris =
            snapshot.data!.docs
                .map(
                  (doc) => KategoriMenuKombinasi.fromMap(
                    doc.id,
                    doc.data() as Map<String, dynamic>,
                  ),
                )
                .toList();

        return Scaffold(
          body:
              kategoris.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.list, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text("Belum ada kategori"),
                      ],
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: kategoris.length,
                    itemBuilder: (context, index) {
                      final kategori = kategoris[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(
                            kategori.nama,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text("Urutan: ${kategori.urutan}"),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 4,
                                children:
                                    kategori.pilihan
                                        .map(
                                          (pilihan) => Chip(
                                            label: Text(pilihan),
                                            onDeleted: () {
                                              _removeOption(kategori, pilihan);
                                            },
                                          ),
                                        )
                                        .toList(),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder:
                                (context) => [
                                  PopupMenuItem(
                                    child: const Text("Edit"),
                                    onTap: () {
                                      _showEditKategoriDialog(
                                        context,
                                        kategori,
                                      );
                                    },
                                  ),
                                  PopupMenuItem(
                                    child: const Text("Hapus"),
                                    onTap: () {
                                      _confirmDeleteKategori(
                                        context,
                                        kategori.id,
                                      );
                                    },
                                  ),
                                ],
                          ),
                        ),
                      );
                    },
                  ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showTambahKategoriDialog(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _showTambahKategoriDialog(BuildContext context) {
    final namaController = TextEditingController();
    final pilihanController = TextEditingController();
    final urutanController = TextEditingController(text: '1');
    List<String> pilihan = [];

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setStateDialog) => AlertDialog(
                  title: const Text("Tambah Kategori"),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: namaController,
                          decoration: const InputDecoration(
                            labelText: "Nama Kategori (Nasi, Lauk, dll)",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: urutanController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Urutan (1-5)",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: pilihanController,
                          decoration: const InputDecoration(
                            labelText: "Pilihan (ketik & tekan Add)",
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.add),
                          ),
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty) {
                              setStateDialog(() {
                                pilihan.add(value.trim());
                                pilihanController.clear();
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (pilihanController.text.trim().isNotEmpty) {
                              setStateDialog(() {
                                pilihan.add(pilihanController.text.trim());
                                pilihanController.clear();
                              });
                            }
                          },
                          child: const Text("Add Pilihan"),
                        ),
                        const SizedBox(height: 12),
                        if (pilihan.isNotEmpty)
                          Wrap(
                            spacing: 4,
                            children:
                                pilihan
                                    .asMap()
                                    .entries
                                    .map(
                                      (entry) => Chip(
                                        label: Text(entry.value),
                                        onDeleted: () {
                                          setStateDialog(() {
                                            pilihan.removeAt(entry.key);
                                          });
                                        },
                                      ),
                                    )
                                    .toList(),
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
                        if (namaController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Nama kategori tidak boleh kosong"),
                            ),
                          );
                          return;
                        }

                        if (pilihan.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Minimal ada 1 pilihan"),
                            ),
                          );
                          return;
                        }

                        try {
                          final urutan =
                              int.tryParse(urutanController.text) ?? 1;
                          await FirestoreService.tambahKategoriMenuKombinasi(
                            nama: namaController.text.trim(),
                            pilihan: pilihan,
                            urutan: urutan.clamp(1, 5),
                          );

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Kategori berhasil ditambahkan"),
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
          ),
    );
  }

  void _showEditKategoriDialog(
    BuildContext context,
    KategoriMenuKombinasi kategori,
  ) {
    final namaController = TextEditingController(text: kategori.nama);
    final pilihanController = TextEditingController();
    final urutanController = TextEditingController(
      text: kategori.urutan.toString(),
    );
    List<String> pilihan = List.from(kategori.pilihan);

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setStateDialog) => AlertDialog(
                  title: const Text("Edit Kategori"),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: namaController,
                          decoration: const InputDecoration(
                            labelText: "Nama Kategori",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: urutanController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Urutan (1-5)",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: pilihanController,
                          decoration: const InputDecoration(
                            labelText: "Tambah Pilihan Baru",
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty) {
                              setStateDialog(() {
                                pilihan.add(value.trim());
                                pilihanController.clear();
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (pilihanController.text.trim().isNotEmpty) {
                              setStateDialog(() {
                                pilihan.add(pilihanController.text.trim());
                                pilihanController.clear();
                              });
                            }
                          },
                          child: const Text("Add Pilihan"),
                        ),
                        const SizedBox(height: 12),
                        if (pilihan.isNotEmpty)
                          Wrap(
                            spacing: 4,
                            children:
                                pilihan
                                    .asMap()
                                    .entries
                                    .map(
                                      (entry) => Chip(
                                        label: Text(entry.value),
                                        onDeleted: () {
                                          setStateDialog(() {
                                            pilihan.removeAt(entry.key);
                                          });
                                        },
                                      ),
                                    )
                                    .toList(),
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
                        if (namaController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Nama kategori tidak boleh kosong"),
                            ),
                          );
                          return;
                        }

                        if (pilihan.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Minimal ada 1 pilihan"),
                            ),
                          );
                          return;
                        }

                        try {
                          final urutan =
                              int.tryParse(urutanController.text) ?? 1;
                          await FirestoreService.updateKategoriMenuKombinasi(
                            kategoriId: kategori.id,
                            nama: namaController.text.trim(),
                            pilihan: pilihan,
                            urutan: urutan.clamp(1, 5),
                          );

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Kategori berhasil diupdate"),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text("Error: $e")));
                        }
                      },
                      child: const Text("Update"),
                    ),
                  ],
                ),
          ),
    );
  }

  void _removeOption(KategoriMenuKombinasi kategori, String pilihan) async {
    try {
      final updatedPilihan = List<String>.from(kategori.pilihan)
        ..remove(pilihan);

      if (updatedPilihan.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Minimal ada 1 pilihan")));
        return;
      }

      await FirestoreService.updateKategoriMenuKombinasi(
        kategoriId: kategori.id,
        nama: kategori.nama,
        pilihan: updatedPilihan,
        urutan: kategori.urutan,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Pilihan berhasil dihapus")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _confirmDeleteKategori(BuildContext context, String kategoriId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Hapus Kategori?"),
            content: const Text("Kategori ini akan dihapus secara permanen"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await FirestoreService.hapusKategoriMenuKombinasi(
                      kategoriId: kategoriId,
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Kategori berhasil dihapus"),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Error: $e")));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  "Hapus",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }
}
