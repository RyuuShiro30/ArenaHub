import 'package:flutter/material.dart';
import '../../../data/model/lapangan_model.dart';
import '../widgets/lapangan_card.dart';
 
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
  ),
];
 
class PencarianLapanganScreen extends StatefulWidget {
  const PencarianLapanganScreen({super.key});
 
  @override
  State<PencarianLapanganScreen> createState() =>
      _PencarianLapanganScreenState();
}
 
class _PencarianLapanganScreenState extends State<PencarianLapanganScreen> {
  // ── State ────────────────────────────────────────────────────
  String _activeCategory = 'Semua';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
 
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
 
  // ── Filtered list (category + search) ────────────────────────
  List<LapanganModel> get _filteredList {
    return _dummyLapangan.where((l) {
      final matchCategory = _activeCategory == 'Semua' ||
          l.kategori.toLowerCase() == _activeCategory.toLowerCase();
 
      final matchSearch = _searchQuery.isEmpty ||
          l.nama.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          l.kategori.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          l.lokasi.toLowerCase().contains(_searchQuery.toLowerCase());
 
      return matchCategory && matchSearch;
    }).toList();
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(context),
            _buildSearchBar(),
            _buildCategoryChips(),
            Expanded(
              child: _filteredList.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: _filteredList.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 20),
                      itemBuilder: (context, index) =>
                          LapanganCard(lapangan: _filteredList[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
 
  // ── TOP BAR ───────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
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
 
  // ── SEARCH BAR ────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                  hintText: 'Cari jenis olahraga atau lapangan...',
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
    );
  }
 
  // ── CATEGORY CHIPS ────────────────────────────────────────────
  Widget _buildCategoryChips() {
    final categories = ['Semua', 'Futsal', 'Badminton', 'Basket'];
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 10, bottom: 2),
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
 
  // ── EMPTY STATE ───────────────────────────────────────────────
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
            'Coba kata kunci atau kategori lain',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}