import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import '../../services/auth_service.dart';
import '../pages/dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController(
    /*text: "admin@gudang.com"*/
  ); // DEBUG
  final passCtrl = TextEditingController(/*text: "123456"*/); // DEBUG
  bool loading = false;

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  bool _validate() {
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      _showError("Email dan password wajib diisi");
      return false;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _showError("Format email tidak valid");
      return false;
    }

    if (pass.length < 6) {
      _showError("Password minimal 6 karakter");
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              "Login",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "GUDANG DIARIFANA",
              style: TextStyle(
                fontSize: 20,
                color: Color.fromARGB(255, 52, 116, 255),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 20),

            // LOGIN
            ElevatedButton(
              onPressed:
                  loading
                      ? null
                      : () async {
                        if (!_validate()) return;

                        setState(() => loading = true);

                        try {
                          await AuthService.login(
                            email: emailCtrl.text.trim(),
                            password: passCtrl.text.trim(),
                          );

                          if (!mounted) return;

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => DashboardPage()),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          _showError(e.toString());
                        }

                        if (!mounted) return;
                        setState(() => loading = false);
                      },
              child:
                  loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Login"),
            ),
            const SizedBox(height: 12),
            const Text(
              "Informasi: untuk test Email: admin@gudang.com \n Password: 123456",
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                children: [
                  const TextSpan(text: 'Created by '),
                  TextSpan(
                    text: 'lm-Digital',
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer:
                        TapGestureRecognizer()
                          ..onTap = () async {
                            final url = Uri.parse('https://lm-digital.com');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
