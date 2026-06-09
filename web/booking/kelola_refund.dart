import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;

class KelolaRefundScreen extends StatefulWidget {
  const KelolaRefundScreen({super.key});

  @override
  State<KelolaRefundScreen> createState() => _KelolaRefundScreenState();
}

class _KelolaRefundScreenState extends State<KelolaRefundScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _searchCtrl = TextEditingController();
  String _search = '';

  // Tab filter: 'menunggu' (Pending), 'disetujui' (Approved), 'ditolak' (Rejected)
  String _currentTab = 'menunggu';

  static const Color _blue = Color(0xFF2563EB);
  static const Color _blueBg = Color(0xFFEFF6FF);
  static const Color _bg = Color(0xFFF4F6F9);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _text = Color(0xFF1A2B3C);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _green = Color(0xFF22C55E);
  static const Color _orange = Color(0xFFF59E0B);
  static const Color _red = Color(0xFFEF4444);

  TextStyle _t({
    double size = 14,
    FontWeight weight = FontWeight.normal,
    Color color = _text,
    double spacing = 0,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: spacing,
    );
  }

  String _rp(dynamic v) {
    final d = double.tryParse(v?.toString() ?? '0') ?? 0;
    return 'Rp ${NumberFormat('#,###', 'id_ID').format(d.toInt())}';
  }

  String _dateTime(dynamic v) {
    if (v == null) return '-';
    if (v is Timestamp) {
      return DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(v.toDate());
    }
    if (v is String && v.length >= 10) {
      try {
        final dt = DateTime.parse(v);
        return DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(dt);
      } catch (_) {
        return v;
      }
    }
    return v.toString();
  }

  String _initials(String name) {
    final p = name.trim().split(' ');
    return p.length >= 2
        ? '${p[0][0]}${p[1][0]}'.toUpperCase()
        : name.isNotEmpty
            ? name[0].toUpperCase()
            : '?';
  }

  // Calculate refund policy recommendation (50% or 100%)
  // Returns Map with 'percent', 'amount', 'message', and 'isPenalty'
  Map<String, dynamic> _calculateRefundRecommendation({
    required dynamic tanggalMainRaw,
    required dynamic selectedTimesRaw,
    required Timestamp? createdAt,
    required double totalHarga,
  }) {
    if (createdAt == null) {
      return {
        'percent': 100,
        'amount': totalHarga,
        'message': 'Data pengajuan tidak lengkap. Direkomendasikan refund penuh.',
        'isPenalty': false,
      };
    }

    try {
      // Parse tanggal main
      String dateStr = tanggalMainRaw?.toString() ?? '';
      if (dateStr.isEmpty) {
        return {
          'percent': 100,
          'amount': totalHarga,
          'message': 'Tanggal main tidak ditemukan. Direkomendasikan refund penuh.',
          'isPenalty': false,
        };
      }

      DateTime playDate = DateTime.parse(dateStr);

      // Extract earliest hour from times
      int startHour = 8; // Default
      int startMinute = 0;
      String timesStr = selectedTimesRaw?.toString() ?? '';
      if (timesStr.isNotEmpty) {
        // e.g. "08.00 - 09.00" or List of times
        final match = RegExp(r'(\d{2})[:\.](\d{2})').firstMatch(timesStr);
        if (match != null) {
          startHour = int.tryParse(match.group(1) ?? '8') ?? 8;
          startMinute = int.tryParse(match.group(2) ?? '0') ?? 0;
        }
      }

      final playDateTime = DateTime(
        playDate.year,
        playDate.month,
        playDate.day,
        startHour,
        startMinute,
      );
      final cancelTime = createdAt.toDate();

      final difference = playDateTime.difference(cancelTime);
      final hoursDifference = difference.inHours;

      if (hoursDifference < 24) {
        final recommendedAmount = totalHarga * 0.5;
        return {
          'percent': 50,
          'amount': recommendedAmount,
          'message':
              'Pembatalan dilakukan kurang dari 24 jam sebelum jadwal main ($hoursDifference jam sebelumnya). Sesuai ketentuan, dikenakan potongan 50%.',
          'isPenalty': true,
        };
      } else {
        return {
          'percent': 100,
          'amount': totalHarga,
          'message':
              'Pembatalan dilakukan ${difference.inDays} hari sebelum jadwal main ($hoursDifference jam sebelumnya). Direkomendasikan refund penuh 100%.',
          'isPenalty': false,
        };
      }
    } catch (e) {
      return {
        'percent': 100,
        'amount': totalHarga,
        'message': 'Gagal menghitung kebijakan otomatis secara akurat. Direkomendasikan refund penuh.',
        'isPenalty': false,
      };
    }
  }

  // Calculate overview statistics
  Map<String, dynamic> _calcStats(List<Map<String, dynamic>> all) {
    int pending = 0;
    int approved = 0;
    int rejected = 0;
    double totalRefunded = 0;

    for (final r in all) {
      final status = (r['status_refund'] ?? 'menunggu').toString().toLowerCase();
      if (status == 'menunggu') {
        pending++;
      } else if (status == 'disetujui' || status == 'selesai') {
        approved++;
        totalRefunded += double.tryParse(r['refund_amount']?.toString() ?? '0') ?? 0;
      } else if (status == 'ditolak') {
        rejected++;
      }
    }

    return {
      'total': all.length,
      'pending': pending,
      'approved': approved,
      'rejected': rejected,
      'totalRefunded': totalRefunded,
    };
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label berhasil disalin ke clipboard'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('refund_requests')
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (ctx, snap) {
        final allRequests = snap.hasData
            ? snap.data!.docs
                .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
                .toList()
            : <Map<String, dynamic>>[];

        // Filter by current tab
        final tabFiltered = allRequests.where((r) {
          final s = (r['status_refund'] ?? 'menunggu').toString().toLowerCase();
          if (_currentTab == 'menunggu') return s == 'menunggu';
          if (_currentTab == 'disetujui') return s == 'disetujui' || s == 'selesai';
          if (_currentTab == 'ditolak') return s == 'ditolak';
          return true;
        }).toList();

        // Search filter
        final filtered = _search.isEmpty
            ? tabFiltered
            : tabFiltered.where((r) {
                final email = (r['user_email'] ?? '').toString().toLowerCase();
                final name = (r['nama_rekening'] ?? '').toString().toLowerCase();
                final lap = (r['nama_lapangan'] ?? '').toString().toLowerCase();
                final orderId = (r['order_id'] ?? '').toString().toLowerCase();
                final q = _search.toLowerCase();
                return email.contains(q) ||
                    name.contains(q) ||
                    lap.contains(q) ||
                    orderId.contains(q);
              }).toList();

        final stats = _calcStats(allRequests);

        return Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kelola Refund & Pembatalan',
                        style: _t(size: 22, weight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      'Tinjau permohonan refund dari pengguna dan catat bukti penyelesaian transaksi pembatalan.',
                      style: _t(size: 13, color: _muted),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _statCard(
                          icon: Icons.assignment_return_outlined,
                          iconColor: _blue,
                          label: 'Total Permohonan',
                          value: stats['total'].toString(),
                        ),
                        const SizedBox(width: 12),
                        _statCard(
                          icon: Icons.hourglass_empty_rounded,
                          iconColor: _orange,
                          label: 'Menunggu Verifikasi',
                          value: stats['pending'].toString(),
                        ),
                        const SizedBox(width: 12),
                        _statCard(
                          icon: Icons.check_circle_outline_rounded,
                          iconColor: _green,
                          label: 'Total Dana Direfund',
                          value: _rp(stats['totalRefunded']),
                        ),
                        const SizedBox(width: 12),
                        _statCard(
                          icon: Icons.cancel_outlined,
                          iconColor: _red,
                          label: 'Permohonan Ditolak',
                          value: stats['rejected'].toString(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildTable(filtered, snap.connectionState),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Top bar
  Widget _buildTopBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: _white,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Text('Kelola Refund', style: _t(size: 17, weight: FontWeight.w700)),
          const Spacer(),
        ],
      ),
    );
  }

  // Stat card
  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: _t(
                size: 11,
                color: _muted,
                weight: FontWeight.w600,
                spacing: 0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: _t(size: 22, weight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Main list & table area
  Widget _buildTable(List<Map<String, dynamic>> list, ConnectionState state) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          // Filter Tabs (Menunggu, Disetujui, Ditolak)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _border)),
            ),
            child: Row(
              children: [
                _tabButton('menunggu', 'Menunggu Verifikasi'),
                const SizedBox(width: 8),
                _tabButton('disetujui', 'Disetujui'),
                const SizedBox(width: 8),
                _tabButton('ditolak', 'Ditolak'),
                const Spacer(),
                // Search box
                Container(
                  width: 260,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(Icons.search_rounded, size: 18, color: _muted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (v) => setState(() => _search = v),
                          style: _t(size: 13),
                          decoration: InputDecoration(
                            hintText: 'Cari email / norek / lapangan...',
                            hintStyle: _t(size: 13, color: _muted),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      if (_search.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            setState(() => _search = '');
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Icon(Icons.close_rounded, size: 16, color: _muted),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (state == ConnectionState.waiting)
            const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            )
          else if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: _muted),
                  const SizedBox(height: 12),
                  Text('Tidak ada data permohonan refund', style: _t(size: 14, color: _muted)),
                ],
              ),
            )
          else ...[
            _tableHeader(),
            const Divider(color: _border, height: 1),
            ...list.map(_tableRow),
          ],

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: _border)),
            ),
            child: Row(
              children: [
                Text('Menampilkan ${list.length} entri', style: _t(size: 12, color: _muted)),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String tab, String label) {
    final active = _currentTab == tab;
    Color activeColor = _blue;
    Color activeBgColor = _blueBg;
    if (tab == 'menunggu') {
      activeColor = _orange;
      activeBgColor = _orange.withOpacity(0.1);
    } else if (tab == 'ditolak') {
      activeColor = _red;
      activeBgColor = _red.withOpacity(0.1);
    } else if (tab == 'disetujui') {
      activeColor = _green;
      activeBgColor = _green.withOpacity(0.1);
    }

    return GestureDetector(
      onTap: () => setState(() => _currentTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? activeBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? activeColor.withOpacity(0.3) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: _t(
            size: 13,
            weight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? activeColor : _muted,
          ),
        ),
      ),
    );
  }

  Widget _tableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          _th('PELANGGAN / REKENING', 3),
          _th('LAPANGAN & ORDER ID', 3),
          _th('TANGGAL PENGAJUAN', 2),
          _th('TOTAL HARGA', 2),
          _th('STATUS REFUND', 2),
          _th('AKSI', 2),
        ],
      ),
    );
  }

  Widget _th(String label, int flex) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: _t(size: 11, weight: FontWeight.w700, color: _muted, spacing: 0.4),
      ),
    );
  }

  Widget _tableRow(Map<String, dynamic> r) {
    final email = r['user_email'] ?? '-';
    final user = r['nama_rekening'] ?? '-';
    final bank = r['nama_bank'] ?? '-';
    final norek = r['no_rekening'] ?? '-';
    final lap = r['nama_lapangan'] ?? '-';
    final orderId = r['order_id'] ?? '-';
    final tglRequest = _dateTime(r['created_at']);
    final total = _rp(r['total_harga']);
    final status = (r['status_refund'] ?? 'menunggu').toString().toLowerCase();

    Color sc = _orange;
    String statusLabel = 'Menunggu';
    if (status == 'disetujui' || status == 'selesai') {
      sc = _green;
      statusLabel = 'Disetujui';
    } else if (status == 'ditolak') {
      sc = _red;
      statusLabel = 'Ditolak';
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              // User & Rekening Info
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: sc.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          _initials(user),
                          style: _t(size: 12, weight: FontWeight.w700, color: sc),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user, style: _t(size: 13, weight: FontWeight.w600)),
                          Text(email, style: _t(size: 11, color: _muted)),
                          if ((r['user_phone'] ?? '').toString().isNotEmpty)
                            Text(r['user_phone'].toString(), style: _t(size: 11, color: _muted)),
                          Text('$bank • $norek', style: _t(size: 11, color: _blue)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Field & Order ID Info
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lap, style: _t(size: 13, weight: FontWeight.w500)),
                    Text(
                      'ID: #${orderId.substring(0, orderId.length > 8 ? 8 : orderId.length).toUpperCase()}',
                      style: _t(size: 11, color: _muted),
                    ),
                  ],
                ),
              ),
              // Time
              Expanded(
                flex: 2,
                child: Text(
                  tglRequest,
                  style: _t(size: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Total
              Expanded(
                flex: 2,
                child: Text(
                  total,
                  style: _t(size: 13, weight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Status Badge
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: sc.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(color: sc, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          statusLabel,
                          style: _t(size: 11, weight: FontWeight.w700, color: sc),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Actions
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showDetail(r),
                      icon: const Icon(Icons.visibility_outlined, size: 14),
                      label: Text('Detail', style: _t(size: 12, weight: FontWeight.w600, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _blue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(color: _border, height: 1, indent: 24, endIndent: 24),
      ],
    );
  }

  // Action: Show Detail Dialog
  void _showDetail(Map<String, dynamic> r) {
    final bookingId = r['booking_id'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550, maxHeight: 680),
            child: FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('bookings').doc(bookingId).get(),
              builder: (ctx, bookingSnap) {
                final Map<String, dynamic> bData = bookingSnap.hasData && bookingSnap.data!.exists
                    ? bookingSnap.data!.data() as Map<String, dynamic>
                    : {};

                final double totalHarga = double.tryParse(r['total_harga']?.toString() ?? '0') ?? 0;
                final Timestamp? createdAt = r['created_at'] as Timestamp?;
                final tanggalMain = bData['tanggal_main'] ?? r['tanggal_main'] ?? '';
                final selectedTimes = bData['selected_times'] ?? bData['jam_main'] ?? '';
                final String userPhone = r['user_phone'] ?? bData['phone'] ?? '';

                // Calculate recommendation
                final rec = _calculateRefundRecommendation(
                  tanggalMainRaw: tanggalMain,
                  selectedTimesRaw: selectedTimes,
                  createdAt: createdAt,
                  totalHarga: totalHarga,
                );

                final status = (r['status_refund'] ?? 'menunggu').toString().toLowerCase();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Detail Pengajuan Refund', style: _t(size: 18, weight: FontWeight.w700)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // User section
                      _buildDialogSectionHeader('Informasi Pelanggan'),
                      _detailRow('Nama Pemohon', r['nama_rekening'] ?? '-'),
                      _detailRow('Email Akun', r['user_email'] ?? '-'),
                      if (userPhone.isNotEmpty)
                        _phoneRow('No. Telepon', userPhone),
                      _detailRow('ID Booking', r['order_id'] ?? '-'),

                      const Divider(height: 20),

                      // Booking Details
                      _buildDialogSectionHeader('Detail Lapangan & Jadwal'),
                      _detailRow('Nama Lapangan', r['nama_lapangan'] ?? '-'),
                      _detailRow('Tanggal Main', _dateTime(tanggalMain).split(',').first),
                      _detailRow('Slot Jam Main', selectedTimes.isNotEmpty ? selectedTimes.toString() : '-'),
                      _detailRow('Waktu Pengajuan', _dateTime(createdAt)),

                      const Divider(height: 20),

                      // Bank Account Details
                      _buildDialogSectionHeader('Rekening Pengembalian Dana'),
                      _rekeningRow('Bank Tujuan', r['nama_bank'] ?? '-'),
                      _rekeningRow('Nomor Rekening', r['no_rekening'] ?? '-'),
                      _rekeningRow('Atas Nama (Rek)', r['nama_rekening'] ?? '-'),
                      _detailRow('Alasan Pembatalan', r['alasan_cancel'] ?? '-', isItalic: true),

                      const Divider(height: 20),

                      // Policy recommendation (Only show if pending)
                      if (status == 'menunggu') ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: rec['isPenalty'] ? _orange.withOpacity(0.1) : _green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: rec['isPenalty']
                                  ? _orange.withOpacity(0.3)
                                  : _green.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    rec['isPenalty']
                                        ? Icons.warning_amber_rounded
                                        : Icons.check_circle_outline_rounded,
                                    color: rec['isPenalty'] ? _orange : _green,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    rec['isPenalty'] ? 'Kebijakan: Potongan 50%' : 'Kebijakan: Refund Penuh 100%',
                                    style: _t(
                                      size: 13,
                                      weight: FontWeight.w700,
                                      color: rec['isPenalty'] ? _orange : _green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                rec['message'],
                                style: _t(
                                  size: 12,
                                  color: rec['isPenalty']
                                      ? const Color(0xFF8B5A00)
                                      : const Color(0xFF1E5E3A),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total Pembayaran Asli:', style: _t(size: 12, color: _muted)),
                                  Text(_rp(totalHarga), style: _t(size: 12, weight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Rekomendasi Nominal Refund:',
                                    style: _t(size: 13, weight: FontWeight.w700, color: _text),
                                  ),
                                  Text(
                                    _rp(rec['amount']),
                                    style: _t(
                                      size: 14,
                                      weight: FontWeight.w800,
                                      color: rec['isPenalty'] ? _orange : _green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ] else ...[
                        _buildDialogSectionHeader('Status Penyelesaian'),
                        if (status == 'disetujui' || status == 'selesai') ...[
                          _detailRow('Status Selesai', 'Disetujui & Uang Dikembalikan', color: _green, isBold: true),
                          _detailRow('Jumlah yang Direfund', _rp(r['refund_amount']), color: _green, isBold: true),
                          _detailRow('Diproses Pada', _dateTime(r['processed_at'])),
                        ] else if (status == 'ditolak') ...[
                          _detailRow('Status Selesai', 'Pengajuan Ditolak', color: _red, isBold: true),
                          _detailRow('Alasan Penolakan', r['alasan_tolak'] ?? '-', color: _red),
                          _detailRow('Diproses Pada', _dateTime(r['processed_at'])),
                        ],
                        const SizedBox(height: 20),
                      ],

                      // Actions buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              side: const BorderSide(color: _border),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            child: Text('Tutup', style: _t(size: 13, weight: FontWeight.w600, color: _muted)),
                          ),
                          if (status == 'menunggu') ...[
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _rejectRefundDialog(r);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _red.withOpacity(0.1),
                                foregroundColor: _red,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              child: Text('Tolak Refund', style: _t(size: 13, weight: FontWeight.w600, color: _red)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _approveRefundDialog(r, rec['amount']);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _green,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              ),
                              child: Text(
                                'Setujui & Transfer',
                                style: _t(size: 13, weight: FontWeight.w600, color: Colors.white),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        title.toUpperCase(),
        style: _t(size: 11, weight: FontWeight.w700, color: _muted, spacing: 0.5),
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
    bool isItalic = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: _t(size: 13, color: _muted)),
          ),
          Expanded(
            child: Text(
              value,
              style: _t(
                size: 13,
                weight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: color ?? _text,
              ).copyWith(fontStyle: isItalic ? FontStyle.italic : FontStyle.normal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rekeningRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: _t(size: 13, color: _muted)),
          ),
          Expanded(
            child: Row(
              children: [
                Text(
                  value,
                  style: _t(size: 13, weight: FontWeight.w600, color: _blue),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 14, color: _blue),
                  onPressed: () => _copyToClipboard(value, label),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 16,
                  tooltip: 'Salin data',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _phoneRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: _t(size: 13, color: _muted)),
          ),
          Expanded(
            child: Row(
              children: [
                Text(
                  value,
                  style: _t(size: 13, weight: FontWeight.w600, color: _blue),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 14, color: _blue),
                  onPressed: () => _copyToClipboard(value, label),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 16,
                  tooltip: 'Salin nomor',
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: _green),
                  onPressed: () => _openWhatsApp(value),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 16,
                  tooltip: 'Hubungi via WhatsApp',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatWhatsAppNumber(String phone) {
    String digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) {
      digits = '62' + digits.substring(1);
    } else if (digits.startsWith('8')) {
      digits = '62' + digits;
    }
    return digits;
  }

  void _openWhatsApp(String phone) {
    final formatted = _formatWhatsAppNumber(phone);
    final url = 'https://wa.me/$formatted';
    html.window.open(url, '_blank');
  }

  // Action: Reject Refund Dialog
  void _rejectRefundDialog(Map<String, dynamic> r) {
    final TextEditingController alasanCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Tolak Permohonan Refund', style: _t(size: 16, weight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Harap masukkan alasan penolakan secara jelas. Alasan ini akan dapat dilihat oleh pelanggan.',
                style: _t(size: 13, color: _muted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: alasanCtrl,
                maxLines: 3,
                style: _t(size: 13),
                decoration: InputDecoration(
                  hintText: 'Contoh: Nomor rekening tidak valid, mohon ajukan kembali...',
                  hintStyle: _t(size: 13, color: _muted),
                  filled: true,
                  fillColor: _bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: _t(size: 14, color: _muted)),
            ),
            ElevatedButton(
              onPressed: () async {
                final alasan = alasanCtrl.text.trim();
                if (alasan.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Alasan penolakan tidak boleh kosong'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                navigator.pop();
                try {
                  await _firestore.collection('refund_requests').doc(r['id']).update({
                    'status_refund': 'ditolak',
                    'alasan_tolak': alasan,
                    'processed_at': FieldValue.serverTimestamp(),
                  });
                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text('Permohonan refund berhasil ditolak'),
                      backgroundColor: _red,
                    ),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Gagal menolak refund: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text(
                'Tolak Sekarang',
                style: _t(size: 14, weight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // Action: Approve Refund Dialog
  void _approveRefundDialog(Map<String, dynamic> r, double suggestedAmount) {
    final TextEditingController nominalCtrl =
        TextEditingController(text: suggestedAmount.toInt().toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Setujui & Selesaikan Refund', style: _t(size: 16, weight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pastikan Anda telah mentransfer uang pengembalian ke rekening bank pelanggan secara manual.',
                style: _t(size: 13, color: _muted),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: _blueBg, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  children: [
                    _rekeningRow('Bank Tujuan', r['nama_bank'] ?? '-'),
                    _rekeningRow('No. Rekening', r['no_rekening'] ?? '-'),
                    _detailRow('Nama Pemilik', r['nama_rekening'] ?? '-'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Jumlah Nominal Transfer (Rp)', style: _t(size: 13, weight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: nominalCtrl,
                keyboardType: TextInputType.number,
                style: _t(size: 14, weight: FontWeight.w700),
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  prefixStyle: _t(size: 14, weight: FontWeight.w700, color: _blue),
                  filled: true,
                  fillColor: _bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: _t(size: 14, color: _muted)),
            ),
            ElevatedButton(
              onPressed: () async {
                final nominalText = nominalCtrl.text.trim();
                final double finalAmount = double.tryParse(nominalText) ?? 0;

                if (finalAmount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nominal transfer harus lebih besar dari 0'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                navigator.pop();
                try {
                  final batch = _firestore.batch();

                  // 1. Update status refund ke disetujui
                  final refundRef = _firestore.collection('refund_requests').doc(r['id']);
                  batch.update(refundRef, {
                    'status_refund': 'disetujui',
                    'refund_amount': finalAmount,
                    'processed_at': FieldValue.serverTimestamp(),
                  });

                  // 2. Update status pembayaran di bookings terkait
                  final bookingId = r['booking_id'] ?? '';
                  if (bookingId.isNotEmpty) {
                    final bookingRef = _firestore.collection('bookings').doc(bookingId);
                    batch.update(bookingRef, {
                      'status_pembayaran': 'refunded',
                    });
                  }

                  await batch.commit();

                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text('Refund disetujui dan status berhasil diperbarui'),
                      backgroundColor: _green,
                    ),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Gagal memproses refund: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text(
                'Setujui & Selesai',
                style: _t(size: 14, weight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
