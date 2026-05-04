import 'package:flutter/material.dart';
import 'package:appbookinglapangan/features/auth/screens/splash_screen.dart';
import 'package:appbookinglapangan/features/home/screens/home_screen.dart';
import 'package:appbookinglapangan/features/auth/screens/login_screen.dart';
import 'package:appbookinglapangan/features/booking/screens/booking_screen.dart';
import 'package:appbookinglapangan/features/auth/screens/register_screen.dart';
import 'package:appbookinglapangan/features/auth/screens/pilih_jadwal.dart';
import 'package:appbookinglapangan/features/booking/screens/payment_screen.dart';
import 'package:appbookinglapangan/features/booking/screens/paymentSucces_screen.dart';
import 'package:appbookinglapangan/features/booking/screens/paymentInstruction_screen.dart';
class AppRoutes {
  static const String login = "/login";
  static const String splash = "/splash";
  static const String register = "/register";
  static const String home = "/home";
  static const String booking = "/booking";
  static const String pilihJadwal = '/pilihJadwal';
  static const String payment = '/payment';
  static const String paymentSucces = '/paymentSucces';
  static const String paymentInstruction = '/paymentInstruction';

  // Rute standar tanpa parameter
  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    home: (context) => const HomeScreen(),
    booking: (context) => const BookingScreen(),
    register: (context) => const RegisterScreen(),
    pilihJadwal: (context) => const PilihJadwalPage(),
    paymentSucces: (context) => const PaymentSuccessPage(),
    paymentInstruction: (context) => const PaymentInstructionScreen(),
  };

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case payment:
        // Cek apakah arguments null atau bukan Map
        final args = settings.arguments;
        
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => PaymentScreen(
              totalHarga: args['totalHarga'] ?? 0,
              namaLapangan: args['namaLapangan'] ?? 'Lapangan',
              customerName: args['customerName'] ?? 'Guest',
              email: args['email'] ?? '',
              phone: args['phone'] ?? '',
            ),
          );
        }
        
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("Data pembayaran tidak ditemukan")),
          ),
        );

      default:
        return null;
    }
  }
}