import 'package:flutter/material.dart';
import 'package:appbookinglapangan/features/auth/screens/splash_screen.dart';
import 'package:appbookinglapangan/features/home/screens/home_screen.dart';
import 'package:appbookinglapangan/features/auth/screens/login_screen.dart';
import 'package:appbookinglapangan/features/auth/screens/register_screen.dart';
import 'package:appbookinglapangan/features/booking/screens/pilih_jadwal.dart';
import 'package:appbookinglapangan/features/booking/screens/payment_screen.dart';
import 'package:appbookinglapangan/features/booking/screens/paymentSucces_screen.dart';
import 'package:appbookinglapangan/features/auth/screens/pencarian_lapangan_screen.dart';
import 'package:appbookinglapangan/features/booking/screens/field_detail.dart'; // ← tambah ini

class AppRoutes {
  static const String login = "/login";
  static const String splash = "/splash";
  static const String register = "/register";
  static const String home = "/home";
  static const String pilihJadwal = '/pilihJadwal';
  static const String payment = '/payment';
  static const String paymentSucces = '/paymentSucces';
  static const String cariLapangan = '/cariLapangan';
  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    home: (context) => const HomeScreen(),
    register: (context) => const RegisterScreen(),
    paymentSucces: (context) => const PaymentSuccessPage(),
    cariLapangan: (context) => const PencarianLapanganScreen(),
  };

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case pilihJadwal:
        final lapanganId = settings.arguments as String;

        return MaterialPageRoute(
          builder: (_) => PilihJadwalPage(
            lapanganId: lapanganId,
          ),
        );
      case payment: 
        final args = settings.arguments;

        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => PaymentScreen(
              totalHarga: args['totalHarga'] ?? 0,
              namaLapangan: args['namaLapangan'] ?? 'Lapangan',
              customerName: args['customerName'] ?? 'Guest',
              email: args['email'] ?? '',
              phone: args['phone'] ?? '',
              selectedDate: args['selectedDate'] ?? '',
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
