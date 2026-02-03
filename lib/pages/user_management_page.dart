import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class UserManagementPage extends StatefulWidget {
  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  String selectedRole = 'user';
  bool loading = false;

  String get tenantId => AuthService.tenantId!;

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  bool _validate() {
    if (emailCtrl.text.isEmpty || passCtrl.text.length < 6) {
      _showMsg("Email & password wajib (min 6 karakter)");
      return false;
    }
    return true;
  }

  // ================= TAMBAH USER KE TENANT =================
  Future<void> _tambahUser() async {
    if (!_validate()) return;

    setState(() => loading = true);

    try {
      await FirebaseFirestore.instance
          .collection('tenants')
          .doc(AuthService.tenantId)
          .collection('members')
          .add({
            'email': emailCtrl.text.trim(),
            'role': selectedRole,
            'status': 'invited',
            'createdAt': FieldValue.serverTimestamp(),
          });

      _showMsg("Undangan user berhasil dibuat");
      emailCtrl.clear();
      selectedRole = 'user';
    } catch (e) {
      _showMsg(e.toString());
    }

    setState(() => loading = false);
  }

  // ================= HAPUS USER DARI TENANT =================
  Future<void> _hapusUser(String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Hapus User"),
            content: const Text("User akan dikeluarkan dari tenant ini"),
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
        .doc(uid)
        .delete();

    _showMsg("User berhasil dihapus dari tenant");
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = AuthService.role == 'admin';

    return Scaffold(
      appBar: AppBar(title: const Text("Manajemen Pengguna")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ================= FORM TAMBAH =================
          if (isAdmin)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tambah Pengguna Tenant",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
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
                          child: Text('CustomServices'),
                        ),
                        DropdownMenuItem(
                          value: 'suplayer',
                          child: Text('Suplayer'),
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

          // ================= LIST USER TENANT =================
          Text(
            "Pengguna Tenant",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('tenants')
                    .doc(tenantId)
                    .collection('members')
                    .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final members = snapshot.data!.docs;

              if (members.isEmpty) {
                return const Text("Belum ada pengguna");
              }

              return Column(
                children:
                    members.map((doc) {
                      final uid = doc['email'];
                      final role = doc['role'];

                      return Card(
                        child: ListTile(
                          title: Text(uid),
                          subtitle: Text("Role: $role"),
                          trailing:
                              isAdmin
                                  ? IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _hapusUser(uid),
                                  )
                                  : null,
                        ),
                      );
                    }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
