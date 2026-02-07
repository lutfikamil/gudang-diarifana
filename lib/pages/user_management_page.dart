import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../utils/password_helper.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  String selectedRole = 'user';
  bool loading = false;

  String get tenantId => AuthService.tenantId!;

  bool get isAdmin =>
      AuthService.role == 'admin' || AuthService.role == 'owner';

  @override
  void dispose() {
    emailCtrl.dispose();
    super.dispose();
  }

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  bool _validate() {
    final email = emailCtrl.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showMsg("Email tidak valid");
      return false;
    }

    return true;
  }

  // ================= TAMBAH USER INTERNAL =================
  Future<void> _tambahUser() async {
    if (!_validate()) return;

    setState(() => loading = true);

    try {
      final email = emailCtrl.text.trim().toLowerCase();

      final ref = FirebaseFirestore.instance
          .collection('tenants')
          .doc(tenantId)
          .collection('members')
          .doc(email);

      final snap = await ref.get();

      if (snap.exists) {
        throw Exception("User sudah ada di tenant");
      }

      await ref.set({
        'username': email,
        'password': PasswordHelper.hash(passCtrl.text),

        'role': selectedRole,
        'type': 'internal',
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showMsg("User internal berhasil ditambahkan");

      emailCtrl.clear();
      setState(() => selectedRole = 'user');
    } catch (e) {
      _showMsg(e.toString().replaceAll('Exception:', '').trim());
    }

    setState(() => loading = false);
  }

  // ================= HAPUS USER =================
  Future<void> _hapusUser(String memberId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Hapus User"),
            content: const Text("User akan dihapus dari tenant"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Hapus"),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance
        .collection('tenants')
        .doc(tenantId)
        .collection('members')
        .doc(memberId)
        .delete();

    _showMsg("User berhasil dihapus");
  }

  // ================= ITEM USER =================
  Widget _buildUserItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final email = data['email'] ?? '-';
    final role = data['role'] ?? '-';
    final type = data['type'] ?? 'auth';

    return Card(
      child: ListTile(
        leading: Icon(
          type == 'auth' ? Icons.verified_user : Icons.person_outline,
          color: type == 'auth' ? Colors.green : Colors.grey,
        ),
        title: Text(email),
        subtitle: Text("Role: $role • $type"),
        trailing:
            isAdmin && type == 'internal'
                ? IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _hapusUser(doc.id),
                )
                : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isAdmin) {
      return const Scaffold(
        body: Center(child: Text("Anda tidak punya akses")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Manajemen Pengguna")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            AuthService.role?.toUpperCase() ?? '',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          // ================= FORM =================
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Tambah User Internal",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: "Email / Username",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Password",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('User')),
                      DropdownMenuItem(
                        value: 'kordinator',
                        child: Text('Kordinator'),
                      ),
                      DropdownMenuItem(
                        value: 'customservices',
                        child: Text('Custom Services'),
                      ),
                      DropdownMenuItem(
                        value: 'suplayer',
                        child: Text('Supplier'),
                      ),
                      DropdownMenuItem(value: 'staff', child: Text('Staff')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (v) => setState(() => selectedRole = v!),
                    decoration: const InputDecoration(
                      labelText: "Role",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : _tambahUser,
                      child:
                          loading
                              ? const CircularProgressIndicator()
                              : const Text("Tambah User"),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ================= LIST =================
          Text(
            "Daftar Pengguna",
            style: Theme.of(context).textTheme.titleMedium,
          ),

          const SizedBox(height: 12),

          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('tenants')
                    .doc(tenantId)
                    .collection('members')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text("Belum ada user");
              }

              final members = snapshot.data!.docs;

              return Column(
                children: members.map((doc) => _buildUserItem(doc)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
