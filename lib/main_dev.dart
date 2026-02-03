import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options_dev.dart';
import 'auth/login_page.dart';
import 'pages/dashboard_page.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DevFirebaseOptions.currentPlatform);

  await initializeDateFormatting('id_ID', null);

  runApp(const MyAppDev());
}

class MyAppDev extends StatelessWidget {
  const MyAppDev({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // 🔥 PENANDA JELAS INI DEV
      title: 'Gudang App (DEV)',

      home: Stack(
        children: [
          AuthService.currentUser == null ? LoginPage() : DashboardPage(),

          // 🔴 Banner DEV
          Positioned(
            top: 0,
            right: 0,
            child: Banner(
              message: 'DEV',
              location: BannerLocation.topEnd,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
