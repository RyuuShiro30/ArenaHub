import 'package:flutter/material.dart';
import '../../../data/model/lapangan_model.dart';
import '../widgets/lapangan_card.dart';
import '../../lapangan/widgets/lapangan_filter_sheet.dart';

// ── Dummy data ────────────────────────────────────────────────────────────────

final List<LapanganModel> _dummyLapangan = [
  LapanganModel(
    kategori: 'FUTSAL',
    nama: 'Lapangan Futsal – A',
    lokasi: 'Kota Malang',
    jarak: 1.2,
    hargaPerJam: 150000,
    minOrang: 10,
    maxOrang: 12,
    adaKamarMandi: true,
    adaParkir: true,
    slotTersedia: ['16:00', '17:00', '20:00'],
    slotTambahan: 2,
    imagePath:
        'https://images.unsplash.com/photo-1577223625816-7546f13df25d?w=600',
    bookedSlots: {
      '2025-07-15': ['16:00', '17:00'],
      '2025-07-16': ['16:00', '17:00', '20:00'], // penuh
      '2025-07-20': ['20:00'],
    },
  ),
  LapanganModel(
    kategori: 'BADMINTON',
    nama: 'Gedung Olahraga Smash',
    lokasi: 'Kota Malang',
    jarak: 1.2,
    hargaPerJam: 65000,
    minOrang: 2,
    maxOrang: 4,
    adaKamarMandi: false,
    adaParkir: false,
    slotTersedia: ['19:00', '21:00'],
    slotTambahan: 0,
    imagePath:
        'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=600',
    bookedSlots: {
      '2025-07-15': ['19:00'],
      '2025-07-18': ['19:00', '21:00'], // penuh
    },
  ),
  LapanganModel(
    kategori: 'BASKET',
    nama: 'Lapangan Basket GOR',
    lokasi: 'Kota Malang',
    jarak: 2.0,
    hargaPerJam: 100000,
    minOrang: 8,
    maxOrang: 10,
    adaKamarMandi: true,
    adaParkir: true,
    slotTersedia: ['07:00', '09:00', '15:00'],
    slotTambahan: 1,
    imagePath:
        'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=600',
    bookedSlots: {
      '2025-07-15': ['07:00'],
      '2025-07-17': ['07:00', '09:00', '15:00'], // penuh
    },
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class PencarianLapanganScreen extends StatefulWidget {
  const PencarianLapanganScreen({super.key});

  @override
  State<PencarianLapanganScreen> createState() =>
      _PencarianLapanganScreenState();
}

class _PencarianLapanganScreenState extends State<PencarianLapanganScreen> {
  // ── State ─────────────────────────────────────────────────────
  String _activeCategory = 'Semua';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  LapanganFilterResult? _activeFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Computed ──────────────────────────────────────────────────

  bool get _hasActiveFilter =>
      _activeFilter != null && _activeFilter!.hasActiveFilter;

  int get _activeFilterCount {
    if (_activeFilter == null) return 0;
    int n = 0;
    if (_activeFilter!.selectedDate != null) n++;
    if (_activeFilter!.selectedTimeRange != null) n++;
    return n;
  }

  List<LapanganModel> get _filteredList {
    return _dummyLapangan.where((l) {
      // Category
      final matchCategory = _activeCategory == 'Semua' ||
          l.kategori.toLowerCase() == _activeCategory.toLowerCase();

      // Search text
      final q = _searchQuery.toLowerCase();
      final matchSearch = q.isEmpty ||
          l.nama.toLowerCase().contains(q) ||
          l.kategori.toLowerCase().contains(q) ||
          l.lokasi.toLowerCase().contains(q);

      // Time range
      bool matchTime = true;
      final range = _activeFilter?.selectedTimeRange;
      if (range != null) {
        final parts = range.split('-');
        if (parts.length == 2) {
          final startH = int.tryParse(parts[0]) ?? 0;
          final endH = int.tryParse(parts[1]) ?? 23;
          matchTime = l.slotTersedia.any((slot) {
            final hour = int.tryParse(slot.split(':')[0]) ?? -1;
            return hour >= startH && hour <= endH;
          });
        }
      }

      return matchCategory && matchSearch && matchTime;
    }).toList();
  }

  // ── Helpers ───────────────────────────────────────────────────

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
    return '${date.day} ${months[date.month]}';
  }

  Future<void> _openFilterSheet() async {
    final result = await LapanganFilterSheet.show(
      context,
      initialFilter: _activeFilter,
    );
    if (result != null) setState(() => _activeFilter = result);
  }

  void _clearFilter() => setState(() => _activeFilter = null);

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(),
            _buildSearchAndFilterRow(),
            _buildCategoryChips(),
            if (_hasActiveFilter) _buildActiveFilterBanner(),
            if (_hasActiveFilter && _activeFilter!.selectedDate != null)
              _buildAvailabilityLegend(),
            Expanded(
              child: _filteredList.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: _filteredList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 20),
                      itemBuilder: (context, index) => LapanganCard(
                        lapangan: _filteredList[index],
                        selectedDate: _activeFilter?.selectedDate,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: const Color(0xFF1565C0),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Text(
            'Cari Lapangan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search bar + filter icon ──────────────────────────────────

  Widget _buildSearchAndFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // Search bar
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const Icon(Icons.search, color: Color(0xFF9E9E9E), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF1A1A2E),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Cari lapangan...',
                        hintStyle: TextStyle(
                          color: Color(0xFF9E9E9E),
                          fontSize: 13.5,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(Icons.close,
                            size: 18, color: Color(0xFF9E9E9E)),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Filter icon button
          GestureDetector(
            onTap: _openFilterSheet,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _hasActiveFilter
                        ? const Color(0xFFC62828)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _hasActiveFilter
                          ? const Color(0xFFC62828)
                          : const Color(0xFFE0E0E0),
                    ),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    size: 22,
                    color: _hasActiveFilter
                        ? Colors.white
                        : const Color(0xFF616161),
                  ),
                ),
                // Active filter count badge
                if (_activeFilterCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1565C0),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$_activeFilterCount',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Category chips ────────────────────────────────────────────

  Widget _buildCategoryChips() {
    final categories = ['Semua', 'Futsal', 'Badminton', 'Basket'];
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 10, bottom: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((cat) {
            final isActive = _activeCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _activeCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF1565C0) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF1565C0)
                          : const Color(0xFFBDBDBD),
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : const Color(0xFF424242),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Active filter banner ──────────────────────────────────────

  Widget _buildActiveFilterBanner() {
    final parts = <String>[];
    if (_activeFilter?.selectedDate != null) {
      parts.add('📅 ${_formatDate(_activeFilter!.selectedDate!)}');
    }
    if (_activeFilter?.selectedTimeRange != null) {
      parts.add('🕐 ${_activeFilter!.selectedTimeRange}');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3F3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFFCDD2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.filter_list_rounded,
                size: 15, color: Color(0xFFC62828)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Filter aktif: ${parts.join('  •  ')}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFC62828),
                ),
              ),
            ),
            GestureDetector(
              onTap: _clearFilter,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Hapus',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF757575),
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.close_rounded, size: 14, color: Color(0xFF757575)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Availability legend ───────────────────────────────────────

  Widget _buildAvailabilityLegend() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Row(
        children: [
          _legendDot(const Color(0xFF4CAF50), 'Tersedia'),
          const SizedBox(width: 14),
          _legendDot(const Color(0xFFC62828), 'Dipesan'),
          const SizedBox(width: 14),
          _legendDot(const Color(0xFF9E9E9E), 'Penuh'),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF757575))),
      ],
    );
  }

  // ── Empty state ───────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Lapangan tidak ditemukan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Coba ubah filter atau kata kunci',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
          if (_hasActiveFilter) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _clearFilter,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3F3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFCDD2)),
                ),
                child: const Text(
                  'Hapus Filter',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFC62828),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
