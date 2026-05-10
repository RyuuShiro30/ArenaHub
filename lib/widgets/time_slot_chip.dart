import 'package:flutter/material.dart';

enum SlotStatus { available, booked, extra }

class TimeSlotChip extends StatelessWidget {
  final String time;
  final SlotStatus status;

  const TimeSlotChip({
    super.key,
    required this.time,
    this.status = SlotStatus.available,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final Color textColor;

    switch (status) {
      case SlotStatus.booked:
        bg = const Color(0xFFFBE9E7);
        border = const Color(0xFFEF9A9A);
        textColor = const Color(0xFFC62828);
        break;
      case SlotStatus.extra:
        bg = const Color(0xFFF5F5F5);
        border = const Color(0xFFBDBDBD);
        textColor = const Color(0xFF757575);
        break;
      case SlotStatus.available:
      default:
        bg = const Color(0xFFE8F5E9);
        border = const Color(0xFF66BB6A);
        textColor = const Color(0xFF2E7D32);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == SlotStatus.booked) ...[
            Icon(Icons.lock_outline_rounded, size: 11, color: textColor),
            const SizedBox(width: 3),
          ],
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}