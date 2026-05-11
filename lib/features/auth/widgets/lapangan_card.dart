// lib/screens/lapangan/widgets/lapangan_card.dart

import 'package:flutter/material.dart';
import '../../../data/model/lapangan_model.dart';

class LapanganCard extends StatelessWidget {
  final LapanganModel lapangan;
  final DateTime? selectedDate;
  final VoidCallback? onTap; // ← BARU: navigasi ke detail

  const LapanganCard({
    super.key,
    required this.lapangan,
    this.selectedDate,
    this.onTap,
  });

  // ── Helpers ───────────────────────────────────────────────────

  String _formatRupiah(int amount) {
    if (amount >= 1000000) {
      return 'Rp${(amount / 1000000).toStringAsFixed(amount % 1000000 == 0 ? 0 : 1)}jt';
    } else if (amount >= 1000) {
      return 'Rp${(amount / 1000).round()}rb';
    }
    return 'Rp$amount';
  }

  Color get _kategoriBadgeColor {
    switch (lapangan.jenisLapangan.toUpperCase()) {
      case 'FUTSAL':
        return const Color(0xFF2E7D32);
      case 'BADMINTON':
        return const Color(0xFF00695C);
      case 'BASKET':
      case 'BASKETBALL':
        return const Color(0xFFE65100);
      case 'TENNIS':
        return const Color(0xFF6A1B9A);
      default:
        return const Color(0xFF1565C0);
    }
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNamePriceRow(),
                  const SizedBox(height: 6),
                  _buildLocationRow(),
                  const SizedBox(height: 8),
                  _buildInfoRow(),
                  const SizedBox(height: 10),
                  _buildRatingFloorRow(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Image Section ─────────────────────────────────────────────

  Widget _buildImageSection() {
    final imageUrl = lapangan.foto.isNotEmpty ? lapangan.foto[0] : '';
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  height: 170,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imagePlaceholder(),
                )
              : _imagePlaceholder(),
        ),
        // Jenis lapangan badge
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kategoriBadgeColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              lapangan.jenisLapangan.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        // Rating badge kanan atas
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded,
                    size: 13, color: Color(0xFFFFD700)),
                const SizedBox(width: 3),
                Text(
                  lapangan.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Foto count badge bawah kanan
        if (lapangan.foto.length > 1)
          Positioned(
            bottom: 10,
            right: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.photo_library_outlined,
                      size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    '${lapangan.foto.length} foto',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 170,
      width: double.infinity,
      color: const Color(0xFFB0BEC5),
      child: const Icon(Icons.sports_soccer, size: 48, color: Colors.white54),
    );
  }

  // ── Name & Price ──────────────────────────────────────────────

  Widget _buildNamePriceRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            lapangan.namaLapangan,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatRupiah(lapangan.harga),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1565C0),
              ),
            ),
            const Text(
              'per jam',
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF9E9E9E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Location ──────────────────────────────────────────────────

  Widget _buildLocationRow() {
    return Row(
      children: [
        const Icon(Icons.location_on_outlined,
            size: 14, color: Color(0xFF9E9E9E)),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            lapangan.lokasi,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF9E9E9E)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── Info Row (kapasitas + fasilitas) ──────────────────────────

  Widget _buildInfoRow() {
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: [
        _infoChip(Icons.group_outlined, 'Maks ${lapangan.kapasitas} orang'),
        if (lapangan.nama.isNotEmpty)
          _infoChip(Icons.info_outline_rounded, lapangan.nama),
      ],
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF616161)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF616161),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Rating + Floor Row ────────────────────────────────────────

  Widget _buildRatingFloorRow() {
    return Row(
      children: [
        // Jenis lantai
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Text(
            lapangan.jenisFloor,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF424242),
            ),
          ),
        ),
        const Spacer(),
        // Tap hint
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Lihat detail',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1565C0),
              ),
            ),
            SizedBox(width: 2),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 11, color: Color(0xFF1565C0)),
          ],
        ),
      ],
    );
  }
}