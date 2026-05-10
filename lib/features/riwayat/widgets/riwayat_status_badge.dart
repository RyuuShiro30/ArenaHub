import 'package:flutter/material.dart';
import '../../../data/model/riwayat_booking_model.dart';

class RiwayatStatusBadge extends StatelessWidget {
  final BookingStatus status;

  const RiwayatStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color textColor;
    final String label;

    switch (status) {
      case BookingStatus.aktif:
        bg = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1565C0);
        label = 'AKTIF';
        break;
      case BookingStatus.selesai:
        bg = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        label = 'SELESAI';
        break;
      case BookingStatus.dibatalkan:
        bg = const Color(0xFFFBE9E7);
        textColor = const Color(0xFFC62828);
        label = 'DIBATALKAN';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}