import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../pages/dashboard_page.dart';

class TenantLoginPage extends StatefulWidget {
  const TenantLoginPage({super.key});

  @override
  State<TenantLoginPage> createState() => _TenantLoginPageState();
}

class _TenantLoginPageState extends State<TenantLoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final tenantCtrl = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    tenantCtrl.dispose();
    super.dispose();
  }

  void _show(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  bool _validate() {
    final e = emailCtrl.text.trim();
    final p = passCtrl.text.trim();
    final t = tenantCtrl.text.trim();
    if (e.isEmpty || p.length < 6 || t.isEmpty) {
      _show('Email, password (min 6) dan tenantId wajib');
      return false;
    }
    return true;
  }

  Future<void> _login() async {
    if (!_validate()) return;
    setState(() => loading = true);
    try {
      await AuthService.loginWithTenant(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
        tenantId: tenantCtrl.text.trim(),
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardPage()),
      );
    } catch (e) {
      _show('Gagal login: $e');
    } finally {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login Tenant')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: tenantCtrl,
              decoration: const InputDecoration(labelText: 'Tenant ID'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : _login,
                child:
                    loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Login'),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gunakan form ini jika Anda login sebagai member tenant (bukan owner/admin via dev login). Pastikan akun sudah dibuat oleh tenant owner (via admin flow).',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
