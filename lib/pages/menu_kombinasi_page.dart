import 'package:flutter/material.dart';

import 'menu_lihat_page.dart';
import 'menu_buat_page.dart';
import 'menu_kategori_page.dart';

class MenuKombinasiPage extends StatelessWidget {
  const MenuKombinasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Menu Kombinasi'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Lihat Menu'),
              Tab(text: 'Buat Menu'),
              Tab(text: 'Kelola Kategori'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [MenuLihatPage(), BuatMenuWidget(), MenuKategoriPage()],
        ),
      ),
    );
  }
}
