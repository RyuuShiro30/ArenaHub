// lib/features/booking/screens/detail_riwayat_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/review.dart';

class DetailRiwayatPage extends StatefulWidget {
  final String bookingId;

  const DetailRiwayatPage({super.key, required this.bookingId});

  @override
  State<DetailRiwayatPage> createState() => _DetailRiwayatPageState();
}

class _DetailRiwayatPageState extends State<DetailRiwayatPage> {
  static const Color _primaryColor = Color(0xFF135B9D);
  static const Color _successColor = Color(0xFF2ECC71);
  static const Color _errorColor = Color(0xFFE53935);
  static const Color _warningColor = Color(0xFFFF9800);

  Map<String, dynamic>? _booking;
  Map<String, dynamic>? _lapangan;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBooking();
  }

  Future<void> _fetchLapangan(String lapanganId) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('lapangan')
        .doc(lapanganId)
        .get();

    if (doc.exists) {
      setState(() {
        _lapangan = doc.data();
      });
    }
  } catch (e) {
    debugPrint('Gagal fetch lapangan: $e');
  }
}

  Future<void> _fetchBooking() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .get();
      if (doc.exists) {
        final bookingData = doc.data()!;
        
        // Fetch lapangan untuk ambil foto
        final lapanganId = bookingData['lapangan_id'] ?? '';
        if (lapanganId.isNotEmpty) {
          final lapanganDoc = await FirebaseFirestore.instance
              .collection('lapangan')
              .doc(lapanganId)
              .get();
          if (lapanganDoc.exists) {
            final fotoList = lapanganDoc.data()?['foto'];
            bookingData['foto'] = (fotoList is List && fotoList.isNotEmpty)
                ? fotoList[0].toString()
                : '';
          }
        }

        setState(() {
          _booking = bookingData;
          _isPageLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isPageLoading = false);
    }
  }

  // ─── Hitung status ────────────────────────────────────────────────────────

  String _hitungStatus() {
    if (_booking == null) return 'aktif';

    // Kalau admin batalkan
    if (_booking!['status_pembayaran'] == 'canceled' ||
        _booking!['dibatalkan'] == true) {
      return 'dibatalkan';
    }

    // Cek tanggal main
    final tanggalMainStr = _booking!['tanggal_main'] as String?;
    if (tanggalMainStr == null) return 'aktif';

    final tanggalMain = DateTime.tryParse(tanggalMainStr);
    if (tanggalMain == null) return 'aktif';

    final sekarang = DateTime.now();
    final hariIni = DateTime(sekarang.year, sekarang.month, sekarang.day);
    final hariMain =
        DateTime(tanggalMain.year, tanggalMain.month, tanggalMain.day);

    if (hariIni.isAfter(hariMain)) return 'selesai';
    return 'aktif';
  }

  // ─── Warna & label status ─────────────────────────────────────────────────

  Color _warnaStatus(String status) {
    switch (status) {
      case 'aktif':
        return _primaryColor;
      case 'selesai':
        return _successColor;
      case 'dibatalkan':
        return _errorColor;
      default:
        return _primaryColor;
    }
  }

  String _labelStatus(String status) {
    switch (status) {
      case 'aktif':
        return 'AKTIF';
      case 'selesai':
        return 'SELESAI';
      case 'dibatalkan':
        return 'DIBATALKAN';
      default:
        return 'AKTIF';
    }
  }

  // ─── Format ───────────────────────────────────────────────────────────────

  String _formatRupiah(dynamic nominal) {
    final int amount = nominal is int
        ? nominal
        : int.tryParse(nominal.toString()) ?? 0;
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'IDR ',
      decimalDigits: 0,
    ).format(amount);
  }

  String _formatTanggal(String? tanggalStr) {
    if (tanggalStr == null) return '-';
    final dt = DateTime.tryParse(tanggalStr);
    if (dt == null) return tanggalStr;
    const bulan = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${dt.day} ${bulan[dt.month]} ${dt.year}';
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _fetchBooking();
                },
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final status = _hitungStatus();
    final b = _booking!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(status),
          SliverToBoxAdapter(child: _buildKartuLapangan(b)),
          SliverToBoxAdapter(child: _buildDetailJadwal(b)),
          SliverToBoxAdapter(child: _buildRincianPembayaran(b)),
          if (status == 'selesai' && b['sudah_review'] != true)
            SliverToBoxAdapter(child: _buildTombolReview(b)),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  // ─── App Bar ──────────────────────────────────────────────────────────────

  Widget _buildAppBar(String status) {
    final warna = _warnaStatus(status);
    final label = _labelStatus(status);

    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0.5,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: _primaryColor, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Detail Booking',
        style: TextStyle(
          color: _primaryColor,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: warna.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: warna.withOpacity(0.3)),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: warna,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Kartu Lapangan ───────────────────────────────────────────────────────

  Widget _buildKartuLapangan(Map<String, dynamic> b) {
    final fotoField = _booking?['foto'];
    final imagePath = (fotoField is List && fotoField.isNotEmpty) ? fotoField.first.toString() : (fotoField is String ? fotoField : '');
    final namaLapangan = b['nama_lapangan'] ?? '-';
    final lokasi = b['lokasi'] ?? 'Arena Hub';
    final mapsUrl = b['maps_url'] as String?;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Foto
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: imagePath.isNotEmpty && imagePath.startsWith('http')
                ? Image.network(
                    imagePath,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _PlaceholderGambar(height: 180),
                  )
                : _PlaceholderGambar(height: 180),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  namaLapangan,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lokasi,
                  style: const TextStyle(
                      fontSize: 13.5, color: Color(0xFF888888)),
                ),
                if (mapsUrl != null && mapsUrl.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse(mapsUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.map_outlined,
                            color: _primaryColor, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Lihat di Peta',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: _primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Detail Jadwal ────────────────────────────────────────────────────────

  Widget _buildDetailJadwal(Map<String, dynamic> b) {
    final tanggal = _formatTanggal(b['tanggal_main'] as String?);
    final selectedTimes = List<String>.from(b['selected_times'] ?? []);
    final jamMulai = selectedTimes.isNotEmpty
        ? selectedTimes.first.split(' - ').first
        : '-';
    final jamSelesai = selectedTimes.isNotEmpty
        ? selectedTimes.last.split(' - ').last
        : '-';
    final durasi = selectedTimes.length;
    final penyewa = b['customer_name'] ?? '-';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Text(
            'DETAIL JADWAL',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF888888),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ItemJadwal(
                  icon: Icons.calendar_today_rounded,
                  label: 'Tanggal',
                  nilai: tanggal,
                ),
              ),
              Expanded(
                child: _ItemJadwal(
                  icon: Icons.access_time_rounded,
                  label: 'Jam',
                  nilai: '$jamMulai - $jamSelesai',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ItemJadwal(
                  icon: Icons.timer_outlined,
                  label: 'Durasi',
                  nilai: '$durasi Jam',
                ),
              ),
              Expanded(
                child: _ItemJadwal(
                  icon: Icons.person_outline_rounded,
                  label: 'Penyewa',
                  nilai: penyewa,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Rincian Pembayaran ───────────────────────────────────────────────────

  Widget _buildRincianPembayaran(Map<String, dynamic> b) {
    final orderId = b['order_id'] ?? '-';
    final totalHarga = b['total_harga'] ?? 0;
    final hargaPerJam = b['harga_per_jam'] ?? 0;
    final durasi = (b['selected_times'] as List?)?.length ?? 1;
    final biayaLayanan = b['biaya_layanan'] ?? 5000;
    final kodePromo = b['kode_promo'] as String?;
    final diskon = b['diskon'] ?? 0;
    final sewaLapangan = hargaPerJam * durasi;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Text(
            'RINCIAN PEMBAYARAN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF888888),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          _BarisPembayaran(
            label: 'Nomor Booking',
            nilai: orderId,
            nilaiTebal: true,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),
          _BarisPembayaran(
            label: 'Sewa Lapangan ($durasi Jam)',
            nilai: _formatRupiah(sewaLapangan),
          ),
          const SizedBox(height: 8),
          _BarisPembayaran(
            label: 'Biaya Layanan',
            nilai: _formatRupiah(biayaLayanan),
          ),
          if (kodePromo != null && kodePromo.isNotEmpty && diskon > 0) ...[
            const SizedBox(height: 8),
            _BarisPembayaran(
              label: 'Promo "$kodePromo"',
              nilai: '- ${_formatRupiah(diskon)}',
              warnaLabel: const Color(0xFF2ECC71),
              warnaNilai: const Color(0xFF2ECC71),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Pembayaran',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              Text(
                _formatRupiah(totalHarga),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Tombol Beri Ulasan ───────────────────────────────────────────────────

  Widget _buildTombolReview(Map<String, dynamic> b) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReviewPage(bookingId: widget.bookingId),
              ),
            );
          },
          icon: const Icon(Icons.star_outline_rounded, color: _primaryColor),
          label: const Text(
            'Beri Ulasan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _primaryColor,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: _primaryColor),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }
}

// ─── Widget Pembantu ─────────────────────────────────────────────────────────

class _ItemJadwal extends StatelessWidget {
  final IconData icon;
  final String label;
  final String nilai;

  const _ItemJadwal({
    required this.icon,
    required this.label,
    required this.nilai,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF3FA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF135B9D), size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF888888),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                nilai,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BarisPembayaran extends StatelessWidget {
  final String label;
  final String nilai;
  final bool nilaiTebal;
  final Color? warnaLabel;
  final Color? warnaNilai;

  const _BarisPembayaran({
    required this.label,
    required this.nilai,
    this.nilaiTebal = false,
    this.warnaLabel,
    this.warnaNilai,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: warnaLabel ?? const Color(0xFF666666),
          ),
        ),
        Text(
          nilai,
          style: TextStyle(
            fontSize: 14,
            fontWeight:
                nilaiTebal ? FontWeight.w700 : FontWeight.w500,
            color: warnaNilai ?? const Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }
}

class _PlaceholderGambar extends StatelessWidget {
  final double height;

  const _PlaceholderGambar({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      color: const Color(0xFFE3EAF5),
      child: const Center(
        child: Icon(Icons.sports_soccer_rounded,
            size: 48, color: Color(0xFF1B4E82)),
      ),
    );
  }
}