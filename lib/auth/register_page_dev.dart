//import 'dart:convert';

//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
//import 'package:shared_preferences/shared_preferences.dart';

import '../../services/auth_service.dart';
//import '../pages/dashboard_page.dart';

class DevRegisterPage extends StatefulWidget {
  const DevRegisterPage({super.key});

  @override
  State<DevRegisterPage> createState() => _DevRegisterPageState();
}

class _DevRegisterPageState extends State<DevRegisterPage> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  bool _validate() {
    final name = nameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text.trim();
    final conf = confirmCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || pass.isEmpty || conf.isEmpty) {
      _showMessage('Semua field wajib diisi');
      return false;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _showMessage('Format email tidak valid');
      return false;
    }

    if (pass.length < 6) {
      _showMessage('Password minimal 6 karakter');
      return false;
    }

    if (pass != conf) {
      _showMessage('Password dan konfirmasi tidak cocok');
      return false;
    }

    return true;
  }

  Future<void> _registerFirestore() async {
    if (!_validate()) return;

    setState(() => loading = true);

    try {
      final email = emailCtrl.text.trim();
      final pass = passCtrl.text.trim();
      final cred = await AuthService.registerAuth(email: email, password: pass);
      final user = cred.user;
      if (user == null) throw Exception('User null');
      try {
        // debug: print Firebase project id and user info to help diagnose
        try {
          // ignore: avoid_print
          print('Firebase project: ${Firebase.app().options.projectId}');
        } catch (e) {
          // ignore: avoid_print
          print('Could not read Firebase.app(): $e');
        }
        // ignore: avoid_print
        print('Sending verification to: ${user.email}');

        await user.sendEmailVerification();
        _showMessage('Email verifikasi dikirim — periksa inbox/spam.');
      } on FirebaseAuthException catch (e) {
        _showMessage('Gagal kirim verifikasi: ${e.message}');
        // ignore: avoid_print
        print('sendEmailVerification failed: ${e.code} ${e.message}');
      } catch (e) {
        _showMessage('Gagal kirim verifikasi: $e');
        // ignore: avoid_print
        print('sendEmailVerification unknown error: $e');
      }
      await AuthService.logout();
    } catch (e) {
      _showMessage('Gagal mendaftar: $e');
    } finally {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama'),
              ),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Konfirmasi Password',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: loading ? null : _registerFirestore,
                child:
                    loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Daftar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
