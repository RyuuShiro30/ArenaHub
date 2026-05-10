import 'package:flutter/material.dart';
import '../../../data/model/riwayat_booking_model.dart';
import '../widgets/riwayat_booking_card.dart';

// ── Dummy data (move to data layer when integrating with API) ─────────────────

final List<RiwayatBookingModel> _dummyRiwayat = [
  RiwayatBookingModel(
    bookingId: 'AH-9821',
    namaLapangan: 'Lapangan Futsal A',
    kategori: 'FUTSAL',
    tanggal: '24 Maret 2026',
    waktu: '19:00 - 20:00',
    totalPembayaran: 130000,
    status: BookingStatus.aktif,
    imagePath:
        'https://images.unsplash.com/photo-1577223625816-7546f13df25d?w=600',
    sisaWaktu: const Duration(hours: 2, minutes: 15, seconds: 0),
  ),
  RiwayatBookingModel(
    bookingId: 'AH-8712',
    namaLapangan: 'lapangan Basket A',
    kategori: 'BASKETBALL',
    tanggal: '15 Maret 2026',
    waktu: '16:00 - 18:00',
    totalPembayaran: 240000,
    status: BookingStatus.selesai,
    imagePath:
        'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=600',
  ),
  RiwayatBookingModel(
    bookingId: 'AH-7611',
    namaLapangan: 'Lapangan Bulutangkis A',
    kategori: 'BADMINTON',
    tanggal: '12 Maret 2026',
    waktu: '20:00 - 21:00',
    totalPembayaran: 80000,
    status: BookingStatus.dibatalkan,
    imagePath:
        'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=600',
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class RiwayatBookingScreen extends StatefulWidget {
  const RiwayatBookingScreen({super.key});

  @override
  State<RiwayatBookingScreen> createState() => _RiwayatBookingScreenState();
}

class _RiwayatBookingScreenState extends State<RiwayatBookingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = ['Semua', 'Aktif', 'Selesai', 'Dibatalkan'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Filter list by tab ────────────────────────────────────────

  List<RiwayatBookingModel> _filtered(int tabIndex) {
    switch (tabIndex) {
      case 1:
        return _dummyRiwayat
            .where((b) => b.status == BookingStatus.aktif)
            .toList();
      case 2:
        return _dummyRiwayat
            .where((b) => b.status == BookingStatus.selesai)
            .toList();
      case 3:
        return _dummyRiwayat
            .where((b) => b.status == BookingStatus.dibatalkan)
            .toList();
      default:
        return _dummyRiwayat;
    }
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(
                _tabs.length,
                (index) => _buildList(index),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E), size: 22),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: const Text(
        'Riwayat Booking',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A2E),
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: const Color(0xFFEEEEEE), height: 1),
      ),
    );
  }

  // ── Tab bar ───────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.center,
        labelColor: const Color(0xFF1565C0),
        unselectedLabelColor: const Color(0xFF9E9E9E),
        labelStyle: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(
            color: Color(0xFF1565C0),
            width: 2.5,
          ),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }

  // ── List ──────────────────────────────────────────────────────

  Widget _buildList(int tabIndex) {
    final list = _filtered(tabIndex);

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Belum ada riwayat booking',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final booking = list[index];
        return RiwayatBookingCard(
          booking: booking,
          onLihatDetail: () {
            // TODO: navigate to detail tiket
          },
          onBeriUlasan: () {
            // TODO: navigate to ulasan
          },
          onPesanLagi: () {
            // TODO: navigate to booking
          },
        );
      },
    );
  }
}
