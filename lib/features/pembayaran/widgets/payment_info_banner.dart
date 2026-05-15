import 'package:flutter/material.dart';

class PaymentInfoBanner extends StatelessWidget {
  const PaymentInfoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBBDEFB)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded,
                size: 18, color: Color(0xFF1565C0)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'E-tiket telah dikirim ke email kamu.\nTunjukkan tiket ini saat tiba di lokasi.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF1565C0),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}