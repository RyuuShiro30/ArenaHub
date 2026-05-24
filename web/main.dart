import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:appbookinglapangan/firebase_options.dart';
import 'auth/login.dart';
import 'dashboard/dashboardAdmin.dart';
import 'profile/profileAdmin.dart';
import 'field/add_field.dart';
import 'field/kelola_lapangan.dart';
import 'booking/kelola_booking.dart';

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

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'),
        Locale('en', 'US'),
      ],

      theme: ThemeData(
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          Theme.of(context).textTheme,
        ),
        useMaterial3: true,
      ),

      home: const AdminDashboardScreen(),

      routes: {
        '/dashboard': (context) => const AdminDashboardScreen(),
        '/profile': (context) => const ProfileAdminScreen(),
        '/field': (context) => const KelolaLapanganScreen(),
        '/add_field': (context) => const AddFieldScreen(),
        '/booking': (context) => const KelolaBookingScreen(),
      },
    );
  }
}