import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/model/lapangan_model.dart';
import '../widgets/lapangan_card.dart';
import '../../lapangan/widgets/lapangan_filter_sheet.dart';
import 'package:appbookinglapangan/features/booking/screens/field_detail.dart';

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

  // ── Stream Firestore ──────────────────────────────────────────

  Stream<List<LapanganModel>> get _lapanganStream =>
      FirebaseFirestore.instance.collection('lapangan').snapshots().map(
            (snap) => snap.docs
                .map((doc) =>
                    LapanganModel.fromFirestore(doc.data(), doc.id))
                .toList(),
          );

  // ── Filter ────────────────────────────────────────────────────

  bool get _hasActiveFilter =>
      _activeFilter != null && _activeFilter!.hasActiveFilter;

  int get _activeFilterCount {
    if (_activeFilter == null) return 0;
    int n = 0;
    if (_activeFilter!.selectedDate != null) n++;
    if (_activeFilter!.selectedTimeRange != null) n++;
    return n;
  }

  List<LapanganModel> _filterList(List<LapanganModel> list) {
    return list.where((l) {
      // Category
      final matchCategory = _activeCategory == 'Semua' ||
          l.jenisLapangan.toLowerCase() ==
              _activeCategory.toLowerCase();

      // Search text
      final q = _searchQuery.toLowerCase();
      final matchSearch = q.isEmpty ||
          l.namaLapangan.toLowerCase().contains(q) ||
          l.jenisLapangan.toLowerCase().contains(q) ||
          l.lokasi.toLowerCase().contains(q);

      return matchCategory && matchSearch;
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
            Expanded(
              child: StreamBuilder<List<LapanganModel>>(
                stream: _lapanganStream,
                builder: (context, snapshot) {
                  // Loading
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1565C0),
                      ),
                    );
                  }

                  // Error
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off_rounded,
                              size: 48,
                              color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'Gagal memuat data',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final filtered =
                      _filterList(snapshot.data ?? []);

                  if (filtered.isEmpty) return _buildEmptyState();

                  return ListView.separated(
                    padding:
                        const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 20),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return LapanganCard(
                        lapangan: item,
                        selectedDate: _activeFilter?.selectedDate,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => 
                                DetailLapanganPage(lapanganId: item.id),
                          ),
                        ),
                      );
                    },
                  );
                },
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
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 20),
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
                  const Icon(Icons.search,
                      color: Color(0xFF9E9E9E), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) =>
                          setState(() => _searchQuery = v),
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
                        padding:
                            EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(Icons.close,
                            size: 18, color: Color(0xFF9E9E9E)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
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
    final categories = [
      'Semua',
      'Futsal',
      'Badminton',
      'Basket',
      'Tennis',
    ];
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
                onTap: () =>
                    setState(() => _activeCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF1565C0)
                        : Colors.white,
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
                      color: isActive
                          ? Colors.white
                          : const Color(0xFF424242),
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
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  Icon(Icons.close_rounded,
                      size: 14, color: Color(0xFF757575)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 56, color: Colors.grey.shade300),
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
            style: TextStyle(
                fontSize: 13, color: Colors.grey.shade400),
          ),
          if (_hasActiveFilter) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _clearFilter,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3F3),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: const Color(0xFFFFCDD2)),
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