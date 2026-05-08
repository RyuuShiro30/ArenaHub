import 'package:flutter/material.dart';

class PaymentActionButtons extends StatelessWidget {
  final VoidCallback? onLihatDetail;
  final VoidCallback? onKembaliBerada;

  const PaymentActionButtons({
    super.key,
    this.onLihatDetail,
    this.onKembaliBerada,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onLihatDetail,
              icon: const Icon(Icons.confirmation_number_outlined,
                  size: 20, color: Colors.white),
              label: const Text(
                'Lihat Detail Booking',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: onKembaliBerada ??
                  () => Navigator.of(context)
                      .popUntil((route) => route.isFirst),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1565C0),
                side: const BorderSide(
                    color: Color(0xFF1565C0), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Kembali ke Beranda',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1565C0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}