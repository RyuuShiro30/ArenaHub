import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:appbookinglapangan/firebase_options.dart';
import 'auth/login.dart';
import 'dashboard/dashboardAdmin.dart';
import 'profile/profileAdmin.dart';
import 'kelola_jadwal/kelolaJadwal.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeDateFormatting('id_ID', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Admin ArenaHub',

      theme: ThemeData(
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          Theme.of(context).textTheme,
        ),
        useMaterial3: true,
      ),

      // HALAMAN PERTAMA
      home: const AdminLoginPage(),

      // ROUTES
      routes: {
        '/dashboard': (context) => const AdminDashboardScreen(),
        '/profile': (context) => const ProfileAdminScreen(),
      },
    );
  }
}
