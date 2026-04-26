import 'package:flutter/material.dart';
// Gunakan package import agar konsisten dan tidak error saat pindah folder
import 'package:appbookinglapangan/features/auth/screens/splash_screen.dart';
import 'package:appbookinglapangan/features/home/screens/home_screen.dart';
import 'package:appbookinglapangan/features/auth/screens/login_screen.dart';
import 'package:appbookinglapangan/features/booking/screens/booking_screen.dart';
import 'package:appbookinglapangan/features/auth/screens/register_screen.dart';
import 'package:appbookinglapangan/features/auth/screens/pilih_jadwal.dart';
import 'package:appbookinglapangan/features/auth/screens/admin/kelola_lapangan.dart';
import 'package:appbookinglapangan/features/booking/screens/payment_screen.dart';

class AppRoutes {
  static const String login = "/login";
  static const String splash = "/splash";
  static const String register = "/register";
  static const String home = "/home";
  static const String booking = "/booking";
  static const String pilihJadwal = '/pilihJadwal';
  static const String kelolaLapangan = '/kelolaLapangan';
  static const String payment = '/payment';

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    login: (context) => LoginScreen(),
    home: (context) => const HomeScreen(),
    booking: (context) => const BookingScreen(),
    register: (context) => const RegisterScreen(),
    pilihJadwal: (context) => PilihJadwalPage(), 
    kelolaLapangan: (context) => const KelolaLapanganPage(),
  };
}