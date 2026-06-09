import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/model/riwayat_booking_model.dart';
import '../widgets/riwayat_booking_card.dart';
import '../screens/detail_riwayat.dart';
import '../screens/review.dart';
import '../../booking/screens/cancel_refund_page.dart';
import '../../auth/screens/pencarian_lapangan_screen.dart'; // Import Halaman Pencarian Lapangan
import 'package:google_fonts/google_fonts.dart';

class RiwayatBookingScreen extends StatefulWidget {
  const RiwayatBookingScreen({super.key});

  @override
  State<RiwayatBookingScreen> createState() => _RiwayatBookingScreenState();
}

class _RiwayatBookingScreenState extends State<RiwayatBookingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _timer;

  final List<String> _tabs = ['Semua', 'Aktif', 'Selesai', 'Dibatalkan'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);

    // Refresh UI tiap 1 menit agar status aktif→selesai terupdate otomatis
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // ── Parse waktu selesai dari selected_times + tanggal_main ───
  DateTime? _parseWaktuSelesai(Map<String, dynamic> data) {
    try {
      final tanggalStr =
          (data['tanggal_main'] ?? data['tanggal'] ?? '').toString().trim();
      if (tanggalStr.isEmpty) return null;

      final tanggal = DateTime.tryParse(tanggalStr);
      if (tanggal == null) return null;

      final rawJam =
          (data['selected_times'] ?? data['jam_main'] ?? '').toString().trim();
      if (rawJam.isEmpty) return null;

      // Ambil slot terakhir — pisah berdasarkan ","
      final slots = rawJam.split(',');
      final lastSlot = slots.last.trim(); // e.g. "07.00 - 08.00"

      // Ambil bagian setelah " - "
      final parts = lastSlot.split(' - ');
      if (parts.length < 2) return null;

      final waktuSelesaiStr = parts.last.trim(); // "08.00" atau "08:00"

      // Normalize titik → titik dua
      final normalized = waktuSelesaiStr.replaceAll('.', ':');
      final jamMenit = normalized.split(':');
      if (jamMenit.length < 2) return null;

      final jam = int.tryParse(jamMenit[0]) ?? 0;
      final menit = int.tryParse(jamMenit[1]) ?? 0;

      return DateTime(tanggal.year, tanggal.month, tanggal.day, jam, menit);
    } catch (_) {
      return null;
    }
  }

  // ── Tentukan status berdasarkan waktu selesai ─────────────────
  BookingStatus _parseStatusWithTime(
      String? statusPembayaran, Map<String, dynamic> data) {
    final lower = (statusPembayaran ?? '').toLowerCase().trim();

    // Dibatalkan → langsung return
    if (lower == 'dibatalkan' ||
        lower == 'gagal' ||
        lower == 'canceled' ||
        lower == 'cancelled') {
      return BookingStatus.dibatalkan;
    }

    // Semua status lunas / aktif → cek waktu selesai
    final waktuSelesai = _parseWaktuSelesai(data);

    if (waktuSelesai != null) {
      if (DateTime.now().isAfter(waktuSelesai)) {
        return BookingStatus.selesai;
      }
      return BookingStatus.aktif;
    }

    // Fallback jika waktu tidak bisa di-parse
    if (lower == 'selesai' || lower == 'pembayaran selesai') {
      return BookingStatus.selesai;
    }
    return BookingStatus.aktif;
  }

  // ── Ambil URL gambar dengan fallback ─────────────────────────
  String _getImageUrl(Map<String, dynamic> data) {
    final imageUrl = data['image_url'];
    if (imageUrl is String && imageUrl.isNotEmpty) return imageUrl;

    final foto = data['foto'];
    if (foto is List && foto.isNotEmpty) {
      final first = foto.first;
      if (first is String && first.isNotEmpty) return first;
      if (first is Map) return first['url']?.toString() ?? '';
    }
    if (foto is String && foto.isNotEmpty) return foto;

    return '';
  }

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
              children:
                  List.generate(_tabs.length, (index) => _buildList(index)),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF0B4E89), size: 24),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text(
        'Riwayat Booking',
        style: GoogleFonts.poppins(
            color: const Color(0xFF0B4E89),
            fontWeight: FontWeight.w700,
            fontSize: 18),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.center,
        labelColor: const Color(0xFF1565C0),
        unselectedLabelColor: const Color(0xFF9E9E9E),
        labelStyle:
            const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: Color(0xFF1565C0), width: 2.5),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }

  Widget _buildList(int tabIndex) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('email', isEqualTo: currentUser?.email)
          .orderBy('tanggal_booking', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        // Filter out child bookings to only display the main (parent) transactions
        final parentDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['is_child'] != true;
        }).toList();

        // ── Map docs ke model ─────────────────────────────────
        List<({RiwayatBookingModel model, String docId, bool sudahReview})>
            mapped = parentDocs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;

          // Tanggal booking untuk display
          String formattedTanggal = '-';
          if (data['tanggal_main'] != null &&
              data['tanggal_main'].toString().isNotEmpty) {
            final dt = DateTime.tryParse(data['tanggal_main'].toString());
            if (dt != null) {
              formattedTanggal = DateFormat('d MMMM yyyy', 'id_ID').format(dt);
            } else {
              formattedTanggal = data['tanggal_main'].toString();
            }
          } else {
            DateTime tanggalBooking = DateTime.now();
            if (data['tanggal_booking'] != null) {
              tanggalBooking = (data['tanggal_booking'] as Timestamp).toDate();
            }
            formattedTanggal =
                DateFormat('d MMMM yyyy', 'id_ID').format(tanggalBooking);
          }

          // Status berbasis waktu
          final status = _parseStatusWithTime(data['status_pembayaran'], data);

          // Sudah review atau belum — baca field 'sudah_review' dari Firestore
          final sudahReview = data['sudah_review'] == true;

          // Gambar dengan fallback
          final imagePath = _getImageUrl(data);

          // Waktu tampil
          final waktuTampil =
              (data['selected_times'] ?? data['jam_main'] ?? '-').toString();

          return (
            model: RiwayatBookingModel(
              bookingId: data['order_id'] ?? '',
              namaLapangan: data['nama_lapangan'] ?? 'Lapangan',
              kategori: data['kategori'] ?? 'SPORT',
              tanggal: formattedTanggal,
              waktu: waktuTampil,
              totalPembayaran: (data['total_harga'] as num?)?.toInt() ?? 0,
              imagePath: imagePath,
              status: status,
            ),
            docId: doc.id,
            sudahReview: sudahReview,
          );
        }).toList();

        // ── Filter berdasarkan tab ────────────────────────────
        List<({RiwayatBookingModel model, String docId, bool sudahReview})>
            filtered;
        switch (tabIndex) {
          case 1: // Aktif
            filtered = mapped
                .where((e) => e.model.status == BookingStatus.aktif)
                .toList();
            break;
          case 2: // Selesai
            filtered = mapped
                .where((e) => e.model.status == BookingStatus.selesai)
                .toList();
            break;
          case 3: // Dibatalkan
            filtered = mapped
                .where((e) => e.model.status == BookingStatus.dibatalkan)
                .toList();
            break;
          default: // Semua
            filtered = mapped;
        }

        if (filtered.isEmpty) {
          return _buildEmptyState(_emptyMessage(tabIndex));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final item = filtered[index];
            final isSelesai = item.model.status == BookingStatus.selesai;

            return GestureDetector(
              onTap: () {
                // Navigasi ke Detail Booking jika card diklik
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailRiwayatPage(bookingId: item.docId),
                  ),
                );
              },
              child: RiwayatBookingCard(
                booking: item.model,
                sudahReview: item.sudahReview,
                // Pastikan teks tombol di dalam file riwayat_booking_card.dart diganti jadi "Reschedule"
                // Fungsi di bawah ini memanggil pop up reschedule
                onLihatDetail: () {
                  _showRescheduleInfoBottomSheet(context, item.model);
                },
                onCancel: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CancelRefundPage(bookingId: item.docId),
                    ),
                  );
                },
                onBeriUlasan: (isSelesai && !item.sudahReview)
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReviewPage(bookingId: item.docId),
                          ),
                        );
                      }
                    : null,
                onPesanLagi: () {
                  // Implementasi logika pesan lagi jika diperlukan
                },
              ),
            );
          },
        );
      },
    );
  }

  String _emptyMessage(int tabIndex) {
    switch (tabIndex) {
      case 1:
        return 'Tidak ada booking aktif';
      case 2:
        return 'Belum ada booking selesai';
      case 3:
        return 'Tidak ada booking dibatalkan';
      default:
        return 'Belum ada riwayat booking';
    }
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  // ── Bottom Sheet untuk menampilkan Syarat & Ketentuan Reschedule ────
  void _showRescheduleInfoBottomSheet(BuildContext context, RiwayatBookingModel model) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle garis di atas modal
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Reschedule Booking',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Detail Booking Card 
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'DETAIL BOOKING',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: model.imagePath.isNotEmpty && model.imagePath.startsWith('http')
                              ? Image.network(model.imagePath, width: 70, height: 70, fit: BoxFit.cover)
                              : Container(
                                  width: 70,
                                  height: 70,
                                  color: const Color(0xFFE3EAF5),
                                  child: const Icon(Icons.sports_soccer_rounded, color: Color(0xFF1B4E82)),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                model.namaLapangan,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1A2E)),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${model.tanggal}\n${model.waktu}',
                                style: const TextStyle(color: Color(0xFF666666), fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                NumberFormat.currency(locale: 'id_ID', symbol: 'IDR ', decimalDigits: 0)
                                    .format(model.totalPembayaran),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF135B9D),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F5FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Booking ID: ${model.bookingId}',
                        style: const TextStyle(
                          color: Color(0xFF135B9D),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Ketentuan Reschedule (Box Kuning)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9E6),
                  border: Border.all(color: const Color(0xFFFFD54F)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFFF57F17), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Ketentuan Reschedule',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF57F17)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildRuleText('Reschedule dapat dilakukan maksimal H-2 dari jadwal yang telah dipesan.'),
                    _buildRuleText('Tidak ada biaya tambahan untuk melakukan reschedule.'),
                    _buildRuleText('Silakan pilih jadwal dan lapangan baru pada halaman pencarian.'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tombol Aksi - Langsung Navigasi ke Pencarian Lapangan Screen
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Menutup bottom sheet

                      // Langsung navigasi ke layar pencarian lapangan
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PencarianLapanganScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF135B9D),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Pilih Lapangan Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRuleText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFF666666), fontSize: 16, height: 1.0)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFF666666), fontSize: 13.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}