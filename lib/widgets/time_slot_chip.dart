import 'package:flutter/material.dart';
 
class TimeSlotChip extends StatelessWidget {
  final String time;
  final bool isExtra;
 
  const TimeSlotChip({
    super.key,
    required this.time,
    this.isExtra = false,
  });
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isExtra ? const Color(0xFFF5F5F5) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isExtra ? const Color(0xFFBDBDBD) : const Color(0xFF66BB6A),
        ),
      ),
      child: Text(
        time,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isExtra ? const Color(0xFF757575) : const Color(0xFF2E7D32),
        ),
      ),
    );
  }
}
 