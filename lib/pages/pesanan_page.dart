import 'package:flutter/material.dart';
import 'pesanan_barang_page.dart';
import 'pesanan_daftar_page.dart';
import 'pesanan_selesai_page.dart';
import 'menu_kombinasi_page.dart';

class PesananPage extends StatelessWidget {
  const PesananPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pesanan")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.restaurant_menu),
              label: const Text("Menu Makanan"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MenuKombinasiPage()),
                );
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text("Pesan Barang"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PesananBarangPage()),
                );
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.list),
              label: const Text("Daftar Pesanan (Berlangsung)"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DaftarPesananPage()),
                );
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.done_all),
              label: const Text("Pesanan Selesai"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PesananSelesaiPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
