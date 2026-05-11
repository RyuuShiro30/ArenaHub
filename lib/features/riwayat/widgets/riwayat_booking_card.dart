import 'package:flutter/material.dart';
import '../../../data/model/riwayat_booking_model.dart';
import 'riwayat_status_badge.dart';
import 'countdown_timer_widget.dart';

class RiwayatBookingCard extends StatelessWidget {
  final RiwayatBookingModel booking;
  final VoidCallback? onLihatDetail;
  final VoidCallback? onBeriUlasan;
  final VoidCallback? onPesanLagi;

  const RiwayatBookingCard({
    super.key,
    required this.booking,
    this.onLihatDetail,
    this.onBeriUlasan,
    this.onPesanLagi,
  });

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

  Color get _kategoriBadgeColor {
    switch (booking.kategori.toUpperCase()) {
      case 'FUTSAL':
        return const Color(0xFF2E7D32);
      case 'BASKETBALL':
        return const Color(0xFFE65100);
      case 'BADMINTON':
        return const Color(0xFF00695C);
      default:
        return const Color(0xFF1565C0);
    }
  }

  IconData get _kategoriIcon {
    switch (booking.kategori.toUpperCase()) {
      case 'FUTSAL':
        return Icons.sports_soccer_rounded;
      case 'BASKETBALL':
        return Icons.sports_basketball_rounded;
      case 'BADMINTON':
        return Icons.sports_tennis_rounded;
      default:
        return Icons.sports_rounded;
    }
  }

  bool get _isAktif => booking.status == BookingStatus.aktif;
  bool get _isSelesai => booking.status == BookingStatus.selesai;
  bool get _isDibatalkan => booking.status == BookingStatus.dibatalkan;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: _isAktif
            ? Border.all(color: const Color(0xFF1565C0), width: 1.5)
            : Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildContent(),
          if (_isAktif && booking.sisaWaktu != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: CountdownTimerWidget(
                  initialDuration: booking.sisaWaktu!),
            ),
            const SizedBox(height: 12),
          ],
          if (_isAktif || _isSelesai || _isDibatalkan)
            _buildActions(context),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RiwayatStatusBadge(status: booking.status),
          Text(
            'Booking ID: ${booking.bookingId}',
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF9E9E9E),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Content ───────────────────────────────────────────────────

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              booking.imagePath,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 80,
                height: 80,
                color: const Color(0xFFB0BEC5),
                child: const Icon(Icons.sports, color: Colors.white54),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kategori chip
                Row(
                  children: [
                    Icon(_kategoriIcon,
                        size: 13, color: _kategoriBadgeColor),
                    const SizedBox(width: 4),
                    Text(
                      booking.kategori,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _kategoriBadgeColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Nama lapangan
                Text(
                  booking.namaLapangan,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                // Tanggal & waktu
                Text(
                  '${booking.tanggal} • ${booking.waktu}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 8),
                // Total
                Text(
                  _formatRupiah(booking.totalPembayaran),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _isAktif
                        ? const Color(0xFF1565C0)
                        : _isDibatalkan
                            ? const Color(0xFF9E9E9E)
                            : const Color(0xFF1A1A2E),
                    decoration: _isDibatalkan
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────

  Widget _buildActions(BuildContext context) {
    if (_isAktif) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: onLihatDetail,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Lihat Detail Tiket',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    if (_isSelesai) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: onBeriUlasan,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1565C0),
                    side: const BorderSide(
                        color: Color(0xFF1565C0), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Beri Ulasan',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: onPesanLagi,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Pesan Lagi',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Dibatalkan — no action buttons
    return const SizedBox(height: 4);
  }
}