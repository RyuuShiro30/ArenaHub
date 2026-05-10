import 'package:flutter/material.dart';
import '../../../data/model/lapangan_model.dart';
import '../../../widgets/time_slot_chip.dart';

class LapanganCard extends StatelessWidget {
  final LapanganModel lapangan;

  /// When non-null, slot availability is shown based on this specific date.
  final DateTime? selectedDate;

  const LapanganCard({
    super.key,
    required this.lapangan,
    this.selectedDate,
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

  String _formatDate(DateTime date) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  Color get _kategoriBadgeColor {
    switch (lapangan.kategori.toUpperCase()) {
      case 'FUTSAL':
        return const Color(0xFF2E7D32);
      case 'BADMINTON':
        return const Color(0xFF00695C);
      case 'BASKET':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFF1565C0);
    }
  }

  bool get _isFull =>
      selectedDate != null && lapangan.isFullOnDate(selectedDate!);

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _isFull ? 0.55 : 1.0,
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
                  _buildFacilitiesRow(),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 10),
                  _buildSlotHeader(),
                  const SizedBox(height: 8),
                  _buildTimeSlots(),
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
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          child: Image.network(
            lapangan.imagePath,
            height: 170,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 170,
              color: const Color(0xFFB0BEC5),
              child: const Icon(Icons.sports_soccer,
                  size: 48, color: Colors.white54),
            ),
          ),
        ),
        // Kategori badge
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
              lapangan.kategori,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        // Penuh overlay
        if (_isFull)
          Positioned.fill(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: Container(
                color: Colors.black.withOpacity(0.38),
                child: const Center(
                  child: Text(
                    'PENUH',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 5,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Name & Price ──────────────────────────────────────────────

  Widget _buildNamePriceRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            lapangan.nama,
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
              _formatRupiah(lapangan.hargaPerJam),
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
        Text(
          '${lapangan.lokasi} • ${lapangan.jarak} km',
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF9E9E9E)),
        ),
      ],
    );
  }

  // ── Facilities ────────────────────────────────────────────────

  Widget _buildFacilitiesRow() {
    final List<Widget> items = [];

    if (lapangan.minOrang != null && lapangan.maxOrang != null) {
      items.add(_facilityItem(
        Icons.group_outlined,
        '${lapangan.minOrang}-${lapangan.maxOrang} Orang',
      ));
    } else if (lapangan.minOrang != null) {
      items.add(
          _facilityItem(Icons.group_outlined, '${lapangan.minOrang} Orang'));
    }

    if (lapangan.adaKamarMandi) {
      items.add(_facilityItem(Icons.shower_outlined, 'Kamar Mandi'));
    }

    if (lapangan.adaParkir) {
      items.add(_facilityItem(Icons.local_parking_outlined, 'Parkir Luas'));
    }

    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 14, runSpacing: 4, children: items);
  }

  Widget _facilityItem(IconData icon, String label) {
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

  // ── Slot Header ───────────────────────────────────────────────

  Widget _buildSlotHeader() {
    if (_isFull) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFC62828),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block_rounded, size: 12, color: Colors.white),
            SizedBox(width: 4),
            Text(
              'PENUH – TIDAK ADA SLOT TERSEDIA',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        const Text(
          'SLOT TERSEDIA',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF757575),
            letterSpacing: 0.4,
          ),
        ),
        if (selectedDate != null) ...[
          const SizedBox(width: 6),
          Text(
            '– ${_formatDate(selectedDate!)}',
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1565C0),
            ),
          ),
        ] else ...[
          const Text(
            ' HARI INI:',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF757575),
              letterSpacing: 0.4,
            ),
          ),
        ],
      ],
    );
  }

  // ── Time Slots ────────────────────────────────────────────────

  Widget _buildTimeSlots() {
    if (_isFull) return const SizedBox.shrink();

    final bookedOnDate =
        selectedDate != null ? lapangan.bookedSlotsForDate(selectedDate!) : <String>[];

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        ...lapangan.slotTersedia.map((slot) {
          final isBooked = bookedOnDate.contains(slot);
          return TimeSlotChip(
            time: slot,
            status: isBooked ? SlotStatus.booked : SlotStatus.available,
          );
        }),
        if (lapangan.slotTambahan > 0)
          TimeSlotChip(
            time: '+${lapangan.slotTambahan} lagi',
            status: SlotStatus.extra,
          ),
      ],
    );
  }
}