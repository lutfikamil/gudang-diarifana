import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/tenant_helper.dart';
import '../models/menu_kombinasi.dart';
import 'menu_buat_page.dart';

class MenuLihatPage extends StatefulWidget {
  const MenuLihatPage({super.key});

  @override
  State<MenuLihatPage> createState() => _MenuLihatPageState();
}

class _MenuLihatPageState extends State<MenuLihatPage> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: TenantHelper.isReady ? FirestoreService.getMenuKombinasi() : null,
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

        if (snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.restaurant_menu, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text("Belum ada menu kombinasi"),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final menu = MenuKombinasi.fromMap(
              doc.id,
              doc.data() as Map<String, dynamic>,
            );

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(
                  menu.nama,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(menu.deskripsi),
                    const SizedBox(height: 8),
                    Text(
                      "Ingredients: ${menu.ingredients.length}",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                trailing: PopupMenuButton(
                  itemBuilder:
                      (context) => [
                        PopupMenuItem(
                          child: const Text("Order"),
                          onTap: () {
                            _showOrderDialog(context, menu);
                          },
                        ),
                        PopupMenuItem(
                          child: const Text("Edit"),
                          onTap: () {
                            _showEditDialog(context, menu);
                          },
                        ),
                        PopupMenuItem(
                          child: const Text("Hapus"),
                          onTap: () {
                            _confirmDelete(context, menu.id);
                          },
                        ),
                      ],
                ),
                onTap: () {
                  _showDetailMenu(context, menu);
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showDetailMenu(BuildContext context, MenuKombinasi menu) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(menu.nama),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Deskripsi: ${menu.deskripsi}"),
                  const SizedBox(height: 12),
                  if (menu.kolom.isNotEmpty) ...[
                    const Text(
                      "Pilihan Kolom:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...menu.kolom.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text("${entry.key}: ${entry.value}"),
                      );
                    }).toList(),
                    const SizedBox(height: 12),
                  ],
                  const Text(
                    "Ingredients:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...menu.ingredients.map((ing) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(ing.namaBarang)),
                          Text(
                            "${ing.jumlah} ${ing.satuan}",
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Tutup"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showOrderDialog(context, menu);
                },
                child: const Text("Order"),
              ),
            ],
          ),
    );
  }

  void _showOrderDialog(BuildContext context, MenuKombinasi menu) {
    showDialog(
      context: context,
      builder: (context) => _OrderDialogWidget(menu: menu),
    );
  }

  void _showEditDialog(BuildContext context, MenuKombinasi menu) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BuatMenuWidget(menu: menu)),
    );
  }

  void _confirmDelete(BuildContext context, String menuId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Hapus Menu?"),
            content: const Text(
              "Menu kombinasi ini akan dihapus secara permanen",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await FirestoreService.hapusMenuKombinasi(menuId: menuId);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Menu berhasil dihapus")),
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

// ORDER DIALOG
class _OrderDialogWidget extends StatefulWidget {
  final MenuKombinasi menu;

  const _OrderDialogWidget({required this.menu});

  @override
  State<_OrderDialogWidget> createState() => _OrderDialogWidgetState();
}

class _OrderDialogWidgetState extends State<_OrderDialogWidget> {
  late TextEditingController jumlahController;
  int jumlahPorsi = 1;

  @override
  void initState() {
    super.initState();
    jumlahController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    jumlahController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Order: ${widget.menu.nama}"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Jumlah Porsi:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: jumlahController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              enableInteractiveSelection: false,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "1",
              ),
              onChanged: (value) {
                setState(() {
                  jumlahPorsi = int.tryParse(value) ?? 1;
                  if (jumlahPorsi < 1) jumlahPorsi = 1;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text(
              "Ingredients yang akan dipesan:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    widget.menu.ingredients.map((ing) {
                      final totalJumlah = ing.jumlah * jumlahPorsi;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ing.namaBarang,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    "Per porsi: ${ing.jumlah} ${ing.satuan}",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "$totalJumlah ${ing.satuan}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
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
            if (jumlahPorsi < 1) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Jumlah harus minimal 1")),
              );
              return;
            }

            try {
              await FirestoreService.buatPesananDariMenu(
                menuId: widget.menu.id,
                namaMenu: widget.menu.nama,
                ingredients:
                    widget.menu.ingredients.map((ing) => ing.toMap()).toList(),
                jumlahPorsi: jumlahPorsi,
              );

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Pesanan berhasil dibuat")),
              );
            } catch (e) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("Error: $e")));
            }
          },
          child: const Text("Order"),
        ),
      ],
    );
  }
}
