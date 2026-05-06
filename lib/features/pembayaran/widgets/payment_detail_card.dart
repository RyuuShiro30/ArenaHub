import 'package:flutter/material.dart';
import '../../../data/model/status_pembayaran_model.dart';

class PaymentDetailCard extends StatelessWidget {
  final StatusPembayaranModel data;

  const PaymentDetailCard({super.key, required this.data});

  String _formatRupiah(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
      count++;
    }
    return 'IDR ${buffer.toString().split('').reversed.join()}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Text(
                'Detail Transaksi',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            _buildBookingNumberRow(),
            const Divider(height: 1, color: Color(0xFFF5F5F5)),
            _buildDetailRows(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingNumberRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'NOMOR BOOKING',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9E9E9E),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.nomorBooking,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: data.isPaid
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFFF9C4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: data.isPaid
                    ? const Color(0xFF66BB6A)
                    : const Color(0xFFF9A825),
              ),
            ),
            child: Text(
              data.isPaid ? 'LUNAS' : 'PENDING',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: data.isPaid
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFF57F17),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRows() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _detailRow(
            label: 'Nama Lapangan',
            value: data.namaLapangan,
            valueBold: true,
          ),
          const SizedBox(height: 14),
          _detailRow(
            label: 'Jadwal',
            valueWidget: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${data.jadwalHari}, ${data.jadwalTanggal}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  '${data.jadwalWaktu} (${data.durasiJam})',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF757575),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _detailRow(
            label: 'Metode Pembayaran',
            value: data.metodePembayaran,
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Pembayaran',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              Text(
                _formatRupiah(data.totalPembayaran),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1565C0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow({
    required String label,
    String? value,
    bool valueBold = false,
    Widget? valueWidget,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF9E9E9E),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: valueWidget ??
              Text(
                value ?? '',
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight:
                      valueBold ? FontWeight.w700 : FontWeight.w500,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
        ),
      ],
    );
  }
}