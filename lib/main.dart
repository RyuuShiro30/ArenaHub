import 'package:appbookinglapangan/core/constant/constant.dart';
import 'package:flutter/material.dart';
import 'package:appbookinglapangan/routes/app_routes.dart';
import 'package:google_fonts/google_fonts.dart'; // <--- Tambahkan import ini

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Menggunakan poppinsTextTheme agar merubah semua gaya teks di aplikasi
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true, // Opsional: Untuk tampilan yang lebih modern
      ),
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}