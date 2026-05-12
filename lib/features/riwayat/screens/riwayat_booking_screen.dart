import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../../data/model/riwayat_booking_model.dart';
import '../widgets/riwayat_booking_card.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RiwayatBookingScreen extends StatefulWidget {
  const RiwayatBookingScreen({super.key});

  @override
  State<RiwayatBookingScreen> createState() =>
      _RiwayatBookingScreenState();
}

class _RiwayatBookingScreenState
    extends State<RiwayatBookingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = [
    'Semua',
    'Aktif',
    'Selesai',
    'Dibatalkan',
  ];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // STATUS PARSER
  // ─────────────────────────────────────────────────────────────

  BookingStatus _parseStatus(String? status) {
    switch (status) {
      case 'sudah dibayar': // Sesuai label dari PaymentScreen
        return BookingStatus.aktif; 
      case 'pending':
        return BookingStatus.aktif;
      case 'selesai':
        return BookingStatus.selesai;
      case 'gagal':
      case 'dibatalkan':
        return BookingStatus.dibatalkan;
      default:
        return BookingStatus.aktif;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

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

  // ─────────────────────────────────────────────────────────────
  // APP BAR
  // ─────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,

      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back,
          color: Color(0xFF1A1A2E),
          size: 22,
        ),
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
        child: Container(
          color: const Color(0xFFEEEEEE),
          height: 1,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TAB BAR
  // ─────────────────────────────────────────────────────────────

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

  // ─────────────────────────────────────────────────────────────
  // LIST BOOKING
  // ─────────────────────────────────────────────────────────────

  Widget _buildList(int tabIndex) {
    // 1. Ambil user yang sedang login
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      // 2. Tambahkan filter .where berdasarkan email user yang login
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('email', isEqualTo: currentUser?.email) // Filter user
          .orderBy('tanggal_booking', descending: true)
          .snapshots(),

      builder: (context, snapshot) {
        // 1. CEK ERROR (Sangat Penting!)
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }
          // 2. LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

        final docs = snapshot.data!.docs;

        List<RiwayatBookingModel> list = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;

          DateTime tanggalBooking = DateTime.now();
          if (data['tanggal_booking'] != null) {
            tanggalBooking = (data['tanggal_booking'] as Timestamp).toDate();
          }

          String formattedTanggal = DateFormat('d MMMM yyyy', 'id_ID').format(tanggalBooking);

          return RiwayatBookingModel(
            bookingId: data['order_id'] ?? '',
            namaLapangan: data['nama_lapangan'] ?? 'Lapangan',
            kategori: data['kategori'] ?? 'SPORT',
            tanggal: formattedTanggal,
            // 1. Ubah 'jam_booking' menjadi 'jam_main'
            waktu: data['jam_main'] ?? '-', 
            totalPembayaran: data['total_harga'] ?? 0,
            imagePath: data['image_url'] ?? 'https://images.unsplash.com/photo-1577223625816-7546f13df25d?w=600',
            // 2. Ubah 'status' menjadi 'status_pembayaran'
            status: _parseStatus(data['status_pembayaran']), 
          );
        }).toList();

        // FILTER BERDASARKAN TAB (Logika filter tetap sama)
        if (tabIndex == 1) {
          list = list.where((e) => e.status == BookingStatus.aktif).toList();
        } else if (tabIndex == 2) {
          list = list.where((e) => e.status == BookingStatus.selesai).toList();
        } else if (tabIndex == 3) {
          list = list.where((e) => e.status == BookingStatus.dibatalkan).toList();
        }

        if (list.isEmpty) {
          return _buildEmptyState('Tidak ada data');
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) => RiwayatBookingCard(
            booking: list[index],
            onLihatDetail: () {},
            onBeriUlasan: () {},
            onPesanLagi: () {},
          ),
        );
      },
    );
  }

  // Helper untuk menampilkan state kosong agar kode lebih bersih
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
