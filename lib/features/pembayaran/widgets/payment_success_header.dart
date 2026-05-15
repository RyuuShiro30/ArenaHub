import 'package:flutter/material.dart';

class PaymentSuccessHeader extends StatelessWidget {
  const PaymentSuccessHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE8F5F0),
            Colors.white,
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5F0),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF2E7D32).withOpacity(0.2),
                width: 6,
              ),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: Color(0xFF2E7D32),
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Pembayaran Berhasil!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Booking lapangan kamu sudah dikonfirmasi',
            style: TextStyle(
              fontSize: 13.5,
              color: Color(0xFF757575),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}