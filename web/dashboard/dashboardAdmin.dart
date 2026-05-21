import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth      = FirebaseAuth.instance;

  static const Color _blue   = Color(0xFF2563EB);
  static const Color _blueBg = Color(0xFFEFF6FF);
  static const Color _bg     = Color(0xFFF4F6F9);
  static const Color _white  = Color(0xFFFFFFFF);
  static const Color _text   = Color(0xFF1A2B3C);
  static const Color _muted  = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _green  = Color(0xFF22C55E);
  static const Color _orange = Color(0xFFF59E0B);

  bool _expanded    = true;
  int  _selectedNav = 0;

  static const double _collapsedW = 56;
  static const double _expandedW  = 220;

  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.dashboard_rounded,           'label': 'Dashboard'},
    {'icon': Icons.confirmation_number_outlined, 'label': 'Kelola Booking'},
    {'icon': Icons.sports_soccer_rounded,       'label': 'Kelola Lapangan'},
    {'icon': Icons.event_note_outlined,         'label': 'Kelola Jadwal'},
    {'icon': Icons.person_outline_rounded,      'label': 'Profil'},
  ];

  String _adminName  = 'Admin';
  String _adminEmail = '';
  String _adminRole  = 'Administrator';

  @override
  void initState() {
    super.initState();
    _fetchAdminSession();
  }

  Future<void> _fetchAdminSession() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _adminName  = data['fullName'] ?? user.displayName ?? 'Admin';
          _adminEmail = data['email']    ?? user.email ?? '';
          _adminRole  = data['role']     ?? 'Administrator';
        });
      }
    } catch (_) {}
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Keluar dari Akun?',
            style: _t(size: 16, weight: FontWeight.w700)),
        content: Text('Kamu akan keluar dari panel admin.',
            style: _t(size: 13, color: _muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: _t(size: 14, color: _muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('Keluar',
                style: _t(size: 14, weight: FontWeight.w600,
                    color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, '/login', (route) => false);
      }
    }
  }

  bool _isSuccess(String s) {
    final v = s.toLowerCase().trim();
    return v == 'pembayaran selesai' || v == 'selesai' ||
        v == 'paid' || v.contains('selesai');
  }

  bool _isPending(String s) {
    final v = s.toLowerCase().trim();
    return v == 'pending' || v == 'menunggu' || v.contains('pending');
  }

  bool _isGagal(String s) {
    final v = s.toLowerCase().trim();
    return v == 'gagal' || v == 'cancelled' || v == 'batal' ||
        v.contains('gagal') || v.contains('cancel') || v.contains('batal');
  }

  String _bulanIni() {
    const bulan = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final now = DateTime.now();
    return '${bulan[now.month]} ${now.year}';
  }

  String _rp(double v) =>
      'Rp ${NumberFormat('#,###', 'id_ID').format(v.toInt())}';

  String _waktu(dynamic ts) {
    if (ts == null) return '-';
    try {
      final dt  = (ts as Timestamp).toDate();
      final now = DateTime.now();
      if (dt.day == now.day && dt.month == now.month && dt.year == now.year)
        return 'Hari Ini, ${DateFormat('HH:mm').format(dt)}';
      final tmr = now.add(const Duration(days: 1));
      if (dt.day == tmr.day && dt.month == tmr.month)
        return 'Esok, ${DateFormat('HH:mm').format(dt)}';
      return DateFormat('d MMM, HH:mm', 'id_ID').format(dt);
    } catch (_) { return '-'; }
  }

  String _initials(String name) {
    final p = name.trim().split(' ');
    return p.length >= 2
        ? '${p[0][0]}${p[1][0]}'.toUpperCase()
        : name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color _sc(String? s) {
    if (s == null) return _muted;
    if (_isSuccess(s)) return _blue;
    if (_isPending(s)) return _orange;
    if (_isGagal(s)) return const Color(0xFFEF4444);
    return _muted;
  }

  String _sl(String? s) {
    if (s == null) return '-';
    if (_isSuccess(s)) return 'SELESAI';
    if (_isPending(s)) return 'PENDING';
    if (_isGagal(s)) return 'GAGAL';
    return s.toUpperCase();
  }

  TextStyle _t({double size = 14, FontWeight weight = FontWeight.normal,
      Color color = _text, double spacing = 0}) =>
      GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: weight,
          color: color, letterSpacing: spacing);

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('bookings').snapshots(),
        builder: (context, bookingSnap) {
          return StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('lapangan').snapshots(),
            builder: (context, lapanganSnap) {
              return StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('users').snapshots(),
                builder: (context, userSnap) {

                  // ── Hitung stats real-time ────────────────────────────
                  final now        = DateTime.now();
                  final start      = DateTime(now.year, now.month, 1);
                  final startLast  = DateTime(now.year, now.month - 1, 1);
                  final endLast    = DateTime(now.year, now.month, 1);
                  final end        = DateTime(now.year, now.month + 1, 1);
                  final todayStart = DateTime(now.year, now.month, now.day);
                  final todayEnd   = todayStart.add(const Duration(days: 1));

                  final allBookings = bookingSnap.hasData
                      ? bookingSnap.data!.docs
                          .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
                          .toList()
                      : <Map<String, dynamic>>[];

                  // Booking hari ini - pakai tanggal_main (format "2026-05-21")
                  final todayStr = '${DateTime.now().year}-'
                      '${DateTime.now().month.toString().padLeft(2, '0')}-'
                      '${DateTime.now().day.toString().padLeft(2, '0')}';
                  final bookingHariIni = allBookings.where((b) {
                    final tanggalMain = b['tanggal_main']?.toString() ?? '';
                    if (tanggalMain.isNotEmpty) return tanggalMain == todayStr;
                    // fallback ke tanggal_booking jika tanggal_main kosong
                    final ts = b['tanggal_booking'];
                    if (ts == null) return false;
                    final dt = (ts as Timestamp).toDate();
                    return dt.isAfter(todayStart) && dt.isBefore(todayEnd);
                  }).length;

                  // Pendapatan bulan ini & bulan lalu
                  double pendapatanIni = 0, pendapatanLalu = 0;

                  for (final b in allBookings) {
                    final ts = b['tanggal_booking'];
                    if (ts == null) continue;
                    final dt     = (ts as Timestamp).toDate();
                    final harga  = double.tryParse(b['total_harga']?.toString() ?? '0') ?? 0;
                    final status = (b['status_pembayaran'] ?? '').toString();

                    if (_isSuccess(status) && dt.isAfter(start) && dt.isBefore(end)) {
                      pendapatanIni += harga;
                    }
                    if (_isSuccess(status) &&
                        dt.isAfter(startLast) && dt.isBefore(endLast)) {
                      pendapatanLalu += harga;
                    }
                  }

                  // Booking terbaru (sorted, limit 10)
                  final sorted = List<Map<String, dynamic>>.from(allBookings)
                    ..sort((a, b) {
                      final ta = a['tanggal_booking'];
                      final tb = b['tanggal_booking'];
                      if (ta == null || tb == null) return 0;
                      return (tb as Timestamp).compareTo(ta as Timestamp);
                    });
                  final bookingList = sorted.take(10).toList();

                  // Lapangan — sort createdAt desc, 3 terbaru tampil di dashboard
                  final lapanganList = lapanganSnap.hasData
                      ? (lapanganSnap.data!.docs
                          .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
                          .toList()
                        ..sort((a, b) {
                          final ta = a['createdAt'];
                          final tb = b['createdAt'];
                          if (ta == null && tb == null) return 0;
                          if (ta == null) return 1;
                          if (tb == null) return -1;
                          return (tb as Timestamp).compareTo(ta as Timestamp);
                        }))
                      : <Map<String, dynamic>>[];
                  final totalLapangan = lapanganList.length;
                  final lapanganAktif = lapanganList
                      .where((l) => l['status'] == 'aktif' || l['status'] == null)
                      .length;

                  // Pelanggan baru bulan ini
                  final pelangganBaru = userSnap.hasData
                      ? userSnap.data!.docs.where((d) {
                          final data = d.data() as Map<String, dynamic>;
                          final ts   = data['createdAt'];
                          if (ts == null) return false;
                          return (ts as Timestamp).toDate().isAfter(start);
                        }).length
                      : 0;

                  final growth = pendapatanLalu == 0
                      ? 0.0
                      : ((pendapatanIni - pendapatanLalu) / pendapatanLalu) * 100;
                  final kapPct = totalLapangan == 0
                      ? 0.0
                      : (lapanganAktif / totalLapangan) * 100;
                  final isLoading = !bookingSnap.hasData ||
                      !lapanganSnap.hasData ||
                      !userSnap.hasData;

                  return Row(children: [
                    ClipRect(child: _buildSidebar()),
                    Expanded(
                      child: Column(children: [
                        _buildTopBar(),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                  Expanded(flex: 3, child: _buildPerformaCard(
                                    pendapatanIni:  pendapatanIni,
                                    pendapatanLalu: pendapatanLalu,
                                    growth:         growth,
                                    isLoading:      isLoading,
                                    bookingTerbaru: bookingList,
                                    allBookings:    allBookings,
                                  )),
                                  const SizedBox(width: 16),
                                  Expanded(flex: 2, child: _buildBookingAktifCard(
                                    total:     bookingHariIni,
                                    isLoading: isLoading,
                                  )),
                                ]),
                                const SizedBox(height: 16),
                                Row(crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                  Expanded(child: _buildKapasitasCard(pct: kapPct)),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildPelangganCard(total: pelangganBaru)),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildStatusCard(lapanganList: lapanganList)),
                                ]),
                                const SizedBox(height: 24),
                                _buildTableBooking(
                                  bookingList: bookingList,
                                  isLoading:   isLoading,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ]);
                },
              );
            },
          );
        },
      ),
    );
  }

  // ── SIDEBAR ───────────────────────────────────────────────────────────────
  Widget _buildSidebar() {
    return ClipRect(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        width: _expanded ? _expandedW : _collapsedW,
        color: _white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Logo ──────────────────────────────────────────────────
            Container(
                height: 64,
                padding: EdgeInsets.symmetric(horizontal: _expanded ? 14 : 10),
                decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: _border))),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                        color: _blue,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.sports_soccer_rounded,
                        color: Colors.white, size: 20),
                  ),
                  AnimatedOpacity(
                    opacity: _expanded ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: SizedBox(
                      width: _expandedW - 36 - 14 - 14,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ArenaHub',
                                style: _t(size: 14, weight: FontWeight.w800,
                                    color: _blue),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text('PANEL ADMINISTRASI',
                                style: _t(size: 8, weight: FontWeight.w600,
                                    color: _muted, spacing: 0.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ),
                  ),
                ]),
              ),

            const SizedBox(height: 12),

            // ── Nav items ────────────────────────────────────────────────
            ...List.generate(_navItems.length, (i) {
              final active = _selectedNav == i;
              final item   = _navItems[i];
              return GestureDetector(
                onTap: () => setState(() => _selectedNav = i),
                child: Container(
                  margin: EdgeInsets.symmetric(
                      horizontal: _expanded ? 8 : 4, vertical: 2),
                  padding: EdgeInsets.symmetric(
                      horizontal: _expanded ? 10 : 4, vertical: 10),
                  decoration: BoxDecoration(
                    color: active ? _blueBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 3, height: 20,
                        margin: EdgeInsets.only(right: _expanded ? 7 : 2),
                        decoration: BoxDecoration(
                          color: active ? _blue : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Icon(item['icon'] as IconData,
                          color: active ? _blue : _muted, size: 20),
                      AnimatedOpacity(
                        opacity: _expanded ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 150),
                        child: SizedBox(
                          width: _expanded ? _expandedW - 80 : 0,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Text(item['label'] as String,
                                style: _t(size: 13,
                                    weight: active
                                        ? FontWeight.w700 : FontWeight.w500,
                                    color: active ? _blue : _muted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const Spacer(),

            // ── Logout button ─────────────────────────────────────────
            GestureDetector(
              onTap: _logout,
              child: Container(
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 3, height: 20),
                    const SizedBox(width: 6),
                    const Icon(Icons.logout_rounded,
                        color: Color(0xFFEF4444), size: 20),
                    AnimatedOpacity(
                      opacity: _expanded ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 150),
                      child: SizedBox(
                        width: _expanded ? _expandedW - 80 : 0,
                        child: const Padding(
                          padding: EdgeInsets.only(left: 10),
                          child: Text('Keluar',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFEF4444),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Admin info ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: _border))),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: _blue),
                    child: Center(
                      child: Text(_initials(_adminName),
                          style: _t(size: 13, weight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: _expanded ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: SizedBox(
                      width: _expanded
                          ? _expandedW - 36 - 12 - 12 - 10
                          : 0,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_adminName,
                                style: _t(size: 12, weight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text(_adminRole,
                                style: _t(size: 10, color: _muted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

  // ── TOP BAR ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    final titles = ['Dashboard', 'Kelola Booking',
        'Kelola Lapangan', 'Kelola Jadwal', 'Profil'];
    return Container(
      height: 60, color: _white,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(children: [
        Text(titles[_selectedNav],
            style: _t(size: 17, weight: FontWeight.w700)),
        const Spacer(),
      ]),
    );
  }

  // ── PERFORMA CARD ─────────────────────────────────────────────────────────
  Widget _buildPerformaCard({
    required double pendapatanIni,
    required double pendapatanLalu,
    required double growth,
    required bool isLoading,
    required List<Map<String, dynamic>> bookingTerbaru,
    required List<Map<String, dynamic>> allBookings,
  }) {
    final isUp = growth >= 0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: _white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Text('PERFORMA BULAN INI',
            style: _t(size: 11, weight: FontWeight.w700,
                color: _blue, spacing: 0.6)),
        const SizedBox(height: 10),
        isLoading
            ? _shimmer(w: 160, h: 28)
            : Text(_rp(pendapatanIni),
                style: _t(size: 26, weight: FontWeight.w800)),
        const SizedBox(height: 8),
        if (!isLoading)
          Row(children: [
            Icon(isUp
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
                color: isUp ? _green : const Color(0xFFEF4444),
                size: 16),
            const SizedBox(width: 4),
            Text('${isUp ? '+' : ''}${growth.toStringAsFixed(1)}% ',
                style: _t(size: 13, weight: FontWeight.w600,
                    color: isUp ? _green : const Color(0xFFEF4444))),
            Text('dibanding bulan lalu',
                style: _t(size: 13, color: _muted)),
          ]),
        const SizedBox(height: 20),
        Wrap(spacing: 12, runSpacing: 10, children: [
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download_rounded,
                size: 16, color: Colors.white),
            label: Text('Unduh Laporan',
                style: _t(size: 13, weight: FontWeight.w600,
                    color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _blue,
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
          OutlinedButton(
            onPressed: () => _showDetailTransaksi(
              allBookings:    allBookings,
              bookingTerbaru: bookingTerbaru,
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _blue.withOpacity(0.4)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Detail Transaksi',
                style: _t(size: 13, weight: FontWeight.w600,
                    color: _blue)),
          ),
        ]),
      ]),
    );
  }

  // ── BOOKING AKTIF ─────────────────────────────────────────────────────────
  Widget _buildBookingAktifCard({
    required int total,
    required bool isLoading,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.calendar_today_rounded,
              color: Colors.white, size: 22),
        ),
        const SizedBox(height: 16),
        Text('BOOKING AKTIF HARI INI',
            style: _t(size: 11, weight: FontWeight.w700,
                color: Colors.white70, spacing: 0.5)),
        const SizedBox(height: 8),
        isLoading
            ? _shimmer(w: 60, h: 36, dark: true)
            : Text(total.toString(),
                style: _t(size: 40, weight: FontWeight.w800,
                    color: Colors.white)),
        const SizedBox(height: 6),
        Text('Data diperbarui secara real-time',
            style: _t(size: 12, color: Colors.white70)),
      ]),
    );
  }

  // ── KAPASITAS ─────────────────────────────────────────────────────────────
  Widget _buildKapasitasCard({required double pct}) {
    final lbl = pct >= 80 ? 'OPTIMAL' : pct >= 50 ? 'NORMAL' : 'RENDAH';
    final lc  = pct >= 80 ? _green
        : pct >= 50 ? _orange : const Color(0xFFEF4444);
    return Container(
      height: 130,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Text('KAPASITAS LAPANGAN',
            style: _t(size: 10, weight: FontWeight.w700,
                color: _muted, spacing: 0.5)),
        const SizedBox(height: 14),
        Row(children: [
          Text('${pct.toStringAsFixed(0)}%',
              style: _t(size: 24, weight: FontWeight.w800)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: lc.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Text(lbl,
                style: _t(size: 11, weight: FontWeight.w700,
                    color: lc)),
          ),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct / 100,
            backgroundColor: _border,
            valueColor: AlwaysStoppedAnimation<Color>(_blue),
            minHeight: 6,
          ),
        ),
      ]),
    );
  }

  // ── PELANGGAN BARU ────────────────────────────────────────────────────────
  Widget _buildPelangganCard({required int total}) {
    return Container(
      height: 130,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Text('PELANGGAN BARU',
            style: _t(size: 10, weight: FontWeight.w700,
                color: _muted, spacing: 0.5)),
        const SizedBox(height: 14),
        Row(children: [
          Text('+$total',
              style: _t(size: 24, weight: FontWeight.w800)),
          const SizedBox(width: 12),
          SizedBox(
            height: 30, width: 70,
            child: Stack(children: [
              _av('BP', 0), _av('SM', 22), _av('AK', 44),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        Text('Bulan ini', style: _t(size: 11, color: _muted)),
      ]),
    );
  }

  Widget _av(String init, double left) {
    final colors = [_blue, const Color(0xFF7C3AED), const Color(0xFF059669)];
    final idx    = init.hashCode.abs() % colors.length;
    return Positioned(
      left: left,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(color: colors[idx],
            shape: BoxShape.circle,
            border: Border.all(color: _white, width: 2)),
        child: Center(child: Text(init,
            style: _t(size: 9, weight: FontWeight.w700,
                color: Colors.white))),
      ),
    );
  }

  // ── STATUS OPERASIONAL ────────────────────────────────────────────────────
  Widget _buildStatusCard({required List<Map<String, dynamic>> lapanganList}) {
    return Container(
      height: 130,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Text('STATUS OPERASIONAL',
            style: _t(size: 10, weight: FontWeight.w700,
                color: _muted, spacing: 0.5)),
        const SizedBox(height: 14),
        if (lapanganList.isEmpty)
          Text('Tidak ada lapangan', style: _t(size: 12, color: _muted))
        else
          ...lapanganList.take(3).map((l) {
            final s = l['status']?.toString().toLowerCase();
            return _sRow(l['nama_lapangan'] ?? 'Lapangan',
                s == 'aktif' || s == null ? _green : _orange);
          }),
      ]),
    );
  }

  Widget _sRow(String name, Color dot) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Expanded(child: Text(name, style: _t(size: 13),
          maxLines: 1, overflow: TextOverflow.ellipsis)),
      Container(width: 10, height: 10,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
    ]),
  );

  // ── TABLE BOOKING ─────────────────────────────────────────────────────────
  Widget _buildTableBooking({
    required List<Map<String, dynamic>> bookingList,
    required bool isLoading,
  }) {
    return Container(
      decoration: BoxDecoration(color: _white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border)),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('Booking Terbaru',
                  style: _t(size: 15, weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('Daftar transaksi 24 jam terakhir',
                  style: _t(size: 12, color: _muted)),
            ]),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() => _selectedNav = 1),
              child: Text('Lihat Semua',
                  style: _t(size: 13, weight: FontWeight.w600,
                      color: _blue)),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(children: [
            _th('PELANGGAN', 3), _th('LAYANAN', 2),
            _th('WAKTU', 2),     _th('TOTAL', 2),
            _th('STATUS', 2),    _th('AKSI', 1),
          ]),
        ),
        const SizedBox(height: 8),
        Divider(color: _border, height: 1),
        if (isLoading)
          const Padding(padding: EdgeInsets.all(32),
              child: CircularProgressIndicator())
        else if (bookingList.isEmpty)
          Padding(padding: const EdgeInsets.all(32),
              child: Text('Tidak ada data booking',
                  style: _t(size: 13, color: _muted)))
        else
          ...bookingList.map(_buildRow),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _th(String label, int flex) => Expanded(
    flex: flex,
    child: Text(label, style: _t(size: 11, weight: FontWeight.w700,
        color: _muted, spacing: 0.4)),
  );

  Widget _buildRow(Map<String, dynamic> b) {
    final name    = b['customer_name']     ?? '-';
    final lap     = b['nama_lapangan']     ?? '-';
    final dur     = b['durasi']            ?? '';
    final waktu   = _waktu(b['tanggal_booking']);
    final total   = double.tryParse(b['total_harga'].toString()) ?? 0;
    final status  = b['status_pembayaran'] ?? b['status'] ?? '';
    final dc      = _sc(status);
    final docId   = b['id'].toString();
    final shortId = docId.length >= 4
        ? docId.substring(0, 4).toUpperCase() : docId;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(children: [
          Expanded(flex: 3, child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(color: _blueBg,
                  borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text(_initials(name),
                  style: _t(size: 12, weight: FontWeight.w700,
                      color: _blue))),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(name,
                  style: _t(size: 13, weight: FontWeight.w600),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('ID: #$shortId',
                  style: _t(size: 11, color: _muted),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
          ])),
          Expanded(flex: 2,
              child: Text(
                dur.toString().isNotEmpty ? '$lap ($dur Jam)' : lap,
                style: _t(size: 13),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              )),
          Expanded(flex: 2,
              child: Text(waktu, style: _t(size: 13),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2,
              child: Text(_rp(total),
                  style: _t(size: 13, weight: FontWeight.w700),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: dc.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(_sl(status),
                    style: _t(size: 11, weight: FontWeight.w700,
                        color: dc),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
          ),
          Expanded(flex: 1,
            child: IconButton(
              icon: Icon(Icons.more_vert_rounded, size: 18, color: _muted),
              onPressed: () => _showActions(b),
            ),
          ),
        ]),
      ),
      Divider(color: _border, height: 1, indent: 24, endIndent: 24),
    ]);
  }

  void _showActions(Map<String, dynamic> b) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Aksi Booking',
              style: _t(size: 15, weight: FontWeight.w700)),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.check_circle_outline_rounded,
                color: Colors.green),
            title: Text('Konfirmasi Selesai', style: _t(size: 14)),
            onTap: () async {
              Navigator.pop(context);
              await _firestore.collection('bookings').doc(b['id'])
                  .update({'status_pembayaran': 'selesai'});
              // Stream otomatis update, tidak perlu fetch manual
            },
          ),
          ListTile(
            leading: const Icon(Icons.cancel_outlined,
                color: Color(0xFFEF4444)),
            title: Text('Batalkan Booking',
                style: _t(size: 14, color: const Color(0xFFEF4444))),
            onTap: () async {
              Navigator.pop(context);
              await _firestore.collection('bookings').doc(b['id'])
                  .update({'status_pembayaran': 'cancelled'});
              // Stream otomatis update, tidak perlu fetch manual
            },
          ),
        ]),
      ),
    );
  }

  void _showDetailTransaksi({
    required List<Map<String, dynamic>> allBookings,
    required List<Map<String, dynamic>> bookingTerbaru,
  }) {
    // Rekap bulan ini (dinamis, real-time)
    final now   = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end   = DateTime(now.year, now.month + 1, 1);

    double totalPendapatan = 0;
    int selesai = 0, pending = 0, batal = 0;

    for (final b in allBookings) {
      final ts = b['tanggal_booking'];
      if (ts != null) {
        final dt = (ts as Timestamp).toDate();
        if (dt.isBefore(start) || !dt.isBefore(end)) continue;
      }

      final s     = (b['status_pembayaran'] ?? '').toString();
      final harga = double.tryParse(b['total_harga']?.toString() ?? '0') ?? 0;

      if (_isSuccess(s)) {
        selesai++;
        totalPendapatan += harga;
      } else if (_isPending(s)) {
        pending++;
      } else if (_isGagal(s)) {
        batal++;
      }
    }

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 680,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            Row(children: [
              Text('Detail Transaksi',
                  style: _t(size: 18, weight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
            Text('Rekap transaksi ${_bulanIni()}',
                style: _t(size: 13, color: _muted)),
            const SizedBox(height: 20),
            Row(children: [
              _dCard('Total Pendapatan', _rp(totalPendapatan),
                  _blue, Icons.payments_outlined),
              const SizedBox(width: 10),
              _dCard('Selesai', '$selesai booking',
                  _green, Icons.check_circle_outline_rounded),
              const SizedBox(width: 10),
              _dCard('Pending', '$pending booking',
                  _orange, Icons.pending_outlined),
              const SizedBox(width: 10),
              _dCard('Dibatalkan', '$batal booking',
                  const Color(0xFFEF4444), Icons.cancel_outlined),
            ]),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: _bg,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12))),
                  child: Row(children: [
                    _th2('Pelanggan', 3), _th2('Lapangan', 2),
                    _th2('Total', 2),     _th2('Status', 2),
                  ]),
                ),
                Divider(color: _border, height: 1),
                ...bookingTerbaru.take(5).map((b) {
                  final total =
                      double.tryParse(b['total_harga'].toString()) ?? 0;
                  // Baca semua kemungkinan field status
                  final rawStatus = (b['status_pembayaran'] ?? b['status'] ?? '').toString();
                  final dc = _sc(rawStatus);
                  final label = _sl(rawStatus);
                  return Column(children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(children: [
                        Expanded(flex: 3,
                            child: Text(b['customer_name'] ?? '-',
                                style: _t(size: 13,
                                    weight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)),
                        Expanded(flex: 2,
                            child: Text(b['nama_lapangan'] ?? '-',
                                style: _t(size: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)),
                        Expanded(flex: 2,
                            child: Text(_rp(total),
                                style: _t(size: 13,
                                    weight: FontWeight.w700))),
                        Expanded(flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: dc.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(label,
                                style: _t(size: 11,
                                    weight: FontWeight.w700,
                                    color: dc),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ]),
                    ),
                    if (b != bookingTerbaru.take(5).last)
                      Divider(color: _border, height: 1,
                          indent: 16, endIndent: 16),
                  ]);
                }),
              ]),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _border),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Tutup',
                    style: _t(size: 13, weight: FontWeight.w600,
                        color: _muted)),
              ),
            ),
          ]),
        ),
      ),
        ),
      ),
    );
  }

  Widget _dCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value,
              style: _t(size: 15, weight: FontWeight.w800, color: color),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label, style: _t(size: 10, color: _muted),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  Widget _th2(String label, int flex) => Expanded(
    flex: flex,
    child: Text(label, style: _t(size: 11, weight: FontWeight.w700,
        color: _muted, spacing: 0.4)),
  );

  Widget _shimmer({required double w, required double h, bool dark = false}) =>
      Container(
        width: w, height: h,
        decoration: BoxDecoration(
          color: dark
              ? Colors.white.withOpacity(0.2)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
      );
}