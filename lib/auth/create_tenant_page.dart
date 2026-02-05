import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../pages/dashboard_page.dart';

class CreateTenantPage extends StatefulWidget {
  const CreateTenantPage({super.key});

  @override
  State<CreateTenantPage> createState() => _CreateTenantPageState();
}

class _CreateTenantPageState extends State<CreateTenantPage> {
  final nameCtrl = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  void _show(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _create() async {
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return _show('Nama tenant harus diisi');

    setState(() => loading = true);
    try {
      final tenantId = await AuthService.createTenantForCurrentUser(
        tenantName: name,
      );
      _show('Tenant dibuat: $tenantId');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardPage()),
      );
    } catch (e) {
      _show('Gagal membuat tenant: $e');
    } finally {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Tenant')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Tenant'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loading ? null : _create,
              child:
                  loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Buat Tenant'),
            ),
          ],
        ),
      ),
    );
  }
}
