import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'barang_page.dart';
import 'masuk_page.dart';
import 'keluar_page.dart';
import 'pesanan_page.dart';
import 'laporan_page.dart';
import 'user_management_page.dart';
import '../auth/login_page.dart';
import '../utils/role_helper.dart';
import 'menu_kombinasi_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String? role;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRole();
    });
  }

  void _loadRole() {
    setState(() {
      role = AuthService.role ?? 'user';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (role == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard (${role!.toUpperCase()})"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginPage()),
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [
          _menu(context, "Stok Barang", BarangPage()),
          _menu(context, "Buat Menu Makanan", MenuKombinasiPage()),

          if (canAccess(role!, ['admin', 'staff']))
            _menu(context, "Masukan Barang", BarangMasukPage()),

          if (canAccess(role!, ['admin', 'staff', 'user']))
            _menu(context, "Keluarkan Barang", BarangKeluarPage()),

          if (canAccess(role!, ['admin', 'staff']))
            _menu(context, "Pesanan Barang", PesananPage()),

          if (canAccess(role!, ['admin', 'staff']))
            _menu(context, "Laporan", LaporanPage()),

          if (canAccess(role!, ['admin']))
            _menu(context, "Manajemen Pengguna", UserManagementPage()),
        ],
      ),
    );
  }

  Widget _menu(BuildContext context, String title, Widget page) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(title),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        },
      ),
    );
  }
}
