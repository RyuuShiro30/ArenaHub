import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class KelolaBookingScreen extends StatefulWidget {
  const KelolaBookingScreen({super.key});
  @override
  State<KelolaBookingScreen> createState() => _KelolaBookingScreenState();
}

class _KelolaBookingScreenState extends State<KelolaBookingScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _searchCtrl = TextEditingController();
  String _search = '';

  static const Color _blue    = Color(0xFF2563EB);
  static const Color _blueBg  = Color(0xFFEFF6FF);
  static const Color _bg      = Color(0xFFF4F6F9);
  static const Color _white   = Color(0xFFFFFFFF);
  static const Color _text    = Color(0xFF1A2B3C);
  static const Color _muted   = Color(0xFF6B7280);
  static const Color _border  = Color(0xFFE5E7EB);
  static const Color _green   = Color(0xFF22C55E);
  static const Color _orange  = Color(0xFFF59E0B);
  static const Color _red     = Color(0xFFEF4444);

  // ── Helpers ──────────────────────────────────────────────────────────────
  TextStyle _t({double size = 14, FontWeight weight = FontWeight.normal,
      Color color = _text, double spacing = 0}) =>
      GoogleFonts.plusJakartaSans(
          fontSize: size, fontWeight: weight,
          color: color, letterSpacing: spacing);

  String _rp(dynamic v) {
    final d = double.tryParse(v?.toString() ?? '0') ?? 0;
    return 'Rp ${NumberFormat('#,###', 'id_ID').format(d.toInt())}';
  }

  /// Ambil waktu dari selected_times (List) → "08:00 – 10:00"
  String _jamRange(dynamic selectedTimes) {
    if (selectedTimes == null) return '-';
    List<String> times = [];
    if (selectedTimes is List) {
      times = selectedTimes.map((e) => e.toString()).toList()..sort();
    }
    if (times.isEmpty) return '-';
    return '${times.first} – ${times.last}';
  }

  String _tanggal(dynamic v) {
    if (v == null) return '-';
    // tanggal_main format: "2026-05-21"
    if (v is String && v.length >= 10) {
      try {
        final dt = DateTime.parse(v);
        return DateFormat('d MMMM yyyy', 'id_ID').format(dt);
      } catch (_) { return v; }
    }
    if (v is Timestamp) {
      return DateFormat('d MMMM yyyy', 'id_ID').format(v.toDate());
    }
    return v.toString();
  }

  String _initials(String name) {
    final p = name.trim().split(' ');
    return p.length >= 2
        ? '${p[0][0]}${p[1][0]}'.toUpperCase()
        : name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  // ── Status helpers ────────────────────────────────────────────────────────
  bool _isLunas(String s) {
    final v = s.toLowerCase().trim();
    return v == 'lunas' || v == 'paid' || v == 'selesai' ||
        v == 'pembayaran selesai' || v.contains('selesai');
  }

  bool _isPending(String s) {
    final v = s.toLowerCase().trim();
    return v == 'pending' || v == 'menunggu' || v.contains('pending');
  }

  bool _isBatal(String s) {
    final v = s.toLowerCase().trim();
    return v == 'batal' || v == 'cancelled' || v == 'gagal' ||
        v.contains('batal') || v.contains('cancel') || v.contains('gagal');
  }

  Color _statusColor(String? s) {
    if (s == null) return _muted;
    if (_isLunas(s)) return _green;
    if (_isPending(s)) return _orange;
    if (_isBatal(s)) return _red;
    return _muted;
  }

  String _statusLabel(String? s) {
    if (s == null) return '-';
    if (_isLunas(s)) return 'Lunas';
    if (_isPending(s)) return 'Menunggu';
    if (_isBatal(s)) return 'Dibatalkan';
    return s;
  }

  // ── Hitung stats dari semua booking ──────────────────────────────────────
  Map<String, dynamic> _calcStats(List<Map<String, dynamic>> all) {
    final now   = DateTime.now();
    final start = DateTime(now.year, now.month, 1);

    int total = all.length, pending = 0, batal = 0;
    double pendapatanHariIni = 0;
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';

    for (final b in all) {
      final s = (b['status_pembayaran'] ?? '').toString();
      if (_isPending(s)) pending++;
      if (_isBatal(s)) batal++;
      if (_isLunas(s) && b['tanggal_main']?.toString() == todayStr) {
        pendapatanHariIni += double.tryParse(b['total_harga']?.toString() ?? '0') ?? 0;
      }
    }

    return {
      'total'             : total,
      'pending'           : pending,
      'batal'             : batal,
      'pendapatanHariIni' : pendapatanHariIni,
    };
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('bookings')
            .orderBy('tanggal_booking', descending: true)
            .snapshots(),
        builder: (ctx, snap) {
          final allBookings = snap.hasData
              ? snap.data!.docs
                  .map((d) => {'id': d.id, ...d.data() as Map<String,dynamic>})
                  .toList()
              : <Map<String, dynamic>>[];

          // Filter by search
          final filtered = _search.isEmpty
              ? allBookings
              : allBookings.where((b) {
                  final name = (b['customer_name'] ?? '').toString().toLowerCase();
                  final lap  = (b['nama_lapangan'] ?? '').toString().toLowerCase();
                  final q    = _search.toLowerCase();
                  return name.contains(q) || lap.contains(q);
                }).toList();

          final stats = _calcStats(allBookings);

          return Column(children: [
            // ── Top Bar ──────────────────────────────────────────────────
            _buildTopBar(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──────────────────────────────────────────
                    Text('Kelola Booking',
                        style: _t(size: 22, weight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('Pantau dan kelola seluruh reservasi lapangan aktif di sistem ArenaHub.',
                        style: _t(size: 13, color: _muted)),
                    const SizedBox(height: 20),

                    // ── Stat Cards ───────────────────────────────────────
                    Row(children: [
                      _statCard(
                        icon: Icons.confirmation_number_outlined,
                        iconColor: _blue,
                        label: 'Total Booking',
                        value: stats['total'].toString(),
                        sub: '+12% dari bulan lalu',
                        subColor: _green,
                      ),
                      const SizedBox(width: 12),
                      _statCard(
                        icon: Icons.hourglass_empty_rounded,
                        iconColor: _orange,
                        label: 'Menunggu Verifikasi',
                        value: stats['pending'].toString(),
                        sub: stats['pending'] > 0
                            ? 'Butuh perhatian segera' : 'Semua clear',
                        subColor: stats['pending'] > 0 ? _orange : _green,
                      ),
                      const SizedBox(width: 12),
                      _statCard(
                        icon: Icons.payments_outlined,
                        iconColor: _green,
                        label: 'Pendapatan Hari Ini',
                        value: _rp(stats['pendapatanHariIni']),
                        sub: '85% target harian',
                        subColor: _green,
                      ),
                      const SizedBox(width: 12),
                      _statCard(
                        icon: Icons.cancel_outlined,
                        iconColor: _red,
                        label: 'Dibatalkan',
                        value: stats['batal'].toString(),
                        sub: '-2% dari rata-rata',
                        subColor: _red,
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // ── Tabel Booking ────────────────────────────────────
                    _buildTable(filtered, snap.connectionState),
                  ],
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }

  // ── Top Bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      height: 60,
      color: _white,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: _border))),
      child: Row(children: [
        // Search bar
        Container(
          width: 340,
          height: 38,
          decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border)),
          child: Row(children: [
            const SizedBox(width: 12),
            Icon(Icons.search_rounded, size: 18, color: _muted),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _search = v),
                style: _t(size: 13),
                decoration: InputDecoration(
                  hintText: 'Cari data booking...',
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
          ]),
        ),
        const Spacer(),
        // Settings icon placeholder
        Icon(Icons.settings_outlined, color: _muted, size: 22),
      ]),
    );
  }

  // ── Stat Card ─────────────────────────────────────────────────────────────
  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String sub,
    required Color subColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
          ]),
          const SizedBox(height: 14),
          Text(label,
              style: _t(size: 11, color: _muted, weight: FontWeight.w600,
                  spacing: 0.4)),
          const SizedBox(height: 6),
          Text(value,
              style: _t(size: 24, weight: FontWeight.w800),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(sub, style: _t(size: 12, color: subColor, weight: FontWeight.w500)),
        ]),
      ),
    );
  }

  // ── Tabel ─────────────────────────────────────────────────────────────────
  Widget _buildTable(List<Map<String, dynamic>> list, ConnectionState state) {
    return Container(
      decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border)),
      child: Column(children: [
        // Header tabel
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Daftar Transaksi Booking',
                  style: _t(size: 15, weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('Semua reservasi lapangan', style: _t(size: 12, color: _muted)),
            ]),
            const Spacer(),
            // Filter button
            _actionBtn(
              icon: Icons.filter_list_rounded,
              label: 'Filter',
              onTap: () {},
            ),
            const SizedBox(width: 8),
            // Ekspor button
            _actionBtn(
              icon: Icons.download_rounded,
              label: 'Ekspor PDF',
              onTap: () {},
              primary: false,
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Divider(color: _border, height: 1),

        // Loading
        if (state == ConnectionState.waiting)
          const Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(),
          )
        // Kosong
        else if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.all(40),
            child: Column(children: [
              Icon(Icons.inbox_outlined, size: 48, color: _muted),
              const SizedBox(height: 12),
              Text('Tidak ada data booking', style: _t(size: 14, color: _muted)),
            ]),
          )
        // Header kolom + rows
        else ...[
          _tableHeader(),
          ...list.map(_tableRow),
        ],

        // Pagination placeholder
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
              border: Border(top: BorderSide(color: _border))),
          child: Row(children: [
            Text('Menampilkan ${list.length} entri',
                style: _t(size: 12, color: _muted)),
            const Spacer(),
            _pageBtn('<', false),
            const SizedBox(width: 4),
            _pageBtn('1', true),
            const SizedBox(width: 4),
            _pageBtn('>',false),
          ]),
        ),
      ]),
    );
  }

  Widget _tableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(children: [
        _th('NAMA PENGGUNA', 3),
        _th('NAMA LAPANGAN', 2),
        _th('TANGGAL BOOKING', 2),
        _th('WAKTU BOOKING', 2),
        _th('TOTAL HARGA', 2),
        _th('STATUS', 2),
        _th('AKSI', 1),
      ]),
    );
  }

  Widget _th(String label, int flex) => Expanded(
    flex: flex,
    child: Text(label,
        style: _t(size: 11, weight: FontWeight.w700,
            color: _muted, spacing: 0.4)),
  );

  Widget _tableRow(Map<String, dynamic> b) {
    final name   = b['customer_name'] ?? '-';
    final lap    = b['nama_lapangan'] ?? '-';
    final tgl    = _tanggal(b['tanggal_main'] ?? b['tanggal_booking']);
    final jam    = _jamRange(b['selected_times']);
    final total  = _rp(b['total_harga']);
    final status = (b['status_pembayaran'] ?? '').toString();
    final sc     = _statusColor(status);

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(children: [
          // Nama pengguna
          Expanded(flex: 3, child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                  color: _blueBg, borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text(_initials(name),
                  style: _t(size: 12, weight: FontWeight.w700, color: _blue))),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(name, style: _t(size: 13, weight: FontWeight.w600),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              if ((b['phone'] ?? '').toString().isNotEmpty)
                Text(b['phone'].toString(),
                    style: _t(size: 11, color: _muted),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
          ])),

          // Lapangan
          Expanded(flex: 2, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: _blueBg, borderRadius: BorderRadius.circular(20)),
            child: Text(lap, style: _t(size: 12, color: _blue, weight: FontWeight.w500),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          )),

          // Tanggal
          Expanded(flex: 2, child: Text(tgl,
              style: _t(size: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),

          // Waktu
          Expanded(flex: 2, child: Text(jam,
              style: _t(size: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),

          // Total
          Expanded(flex: 2, child: Text(total,
              style: _t(size: 13, weight: FontWeight.w700),
              maxLines: 1, overflow: TextOverflow.ellipsis)),

          // Status badge
          Expanded(flex: 2, child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: sc.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6,
                    decoration: BoxDecoration(color: sc, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(_statusLabel(status),
                    style: _t(size: 11, weight: FontWeight.w700, color: sc),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
          )),

          // Aksi
          Expanded(flex: 1, child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _iconBtn(Icons.visibility_outlined, _muted,
                  () => _showDetail(b)),
              const SizedBox(width: 4),
              _iconBtn(Icons.edit_outlined, _blue,
                  () => _editStatus(b)),
              const SizedBox(width: 4),
              _iconBtn(Icons.delete_outline_rounded, _red,
                  () => _confirmDelete(b)),
            ],
          )),
        ]),
      ),
      Divider(color: _border, height: 1, indent: 24, endIndent: 24),
    ]);
  }

  // ── Action Buttons ────────────────────────────────────────────────────────
  Widget _actionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: primary ? _blue : _white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: primary ? _blue : _border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15,
              color: primary ? Colors.white : _text),
          const SizedBox(width: 6),
          Text(label, style: _t(size: 13, weight: FontWeight.w600,
              color: primary ? Colors.white : _text)),
        ]),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) =>
      IconButton(
        icon: Icon(icon, size: 18, color: color),
        onPressed: onTap,
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
        splashRadius: 18,
      );

  Widget _pageBtn(String label, bool active) => Container(
    width: 30, height: 30,
    decoration: BoxDecoration(
      color: active ? _blue : _white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: active ? _blue : _border),
    ),
    child: Center(
      child: Text(label, style: _t(size: 12, weight: FontWeight.w600,
          color: active ? Colors.white : _muted)),
    ),
  );

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Lihat detail booking
  void _showDetail(Map<String, dynamic> b) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(children: [
                Text('Detail Booking',
                    style: _t(size: 17, weight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ]),
              const SizedBox(height: 16),
              _detailRow('Nama Pelanggan', b['customer_name'] ?? '-'),
              _detailRow('Email', b['email'] ?? '-'),
              _detailRow('Telepon', b['phone'] ?? '-'),
              _detailRow('Lapangan', b['nama_lapangan'] ?? '-'),
              _detailRow('Tanggal Main', _tanggal(b['tanggal_main'])),
              _detailRow('Jam Main', b['jam_main']?.toString() ?? '-'),
              _detailRow('Waktu Booking', _jamRange(b['selected_times'])),
              _detailRow('Durasi', '${(b['selected_times'] is List ? (b['selected_times'] as List).length : 0)} jam'),
              const Divider(height: 24),
              _detailRow('Biaya Layanan',  _rp(b['biaya_layanan'])),
              _detailRow('Kode Promo', b['kode_promo']?.toString().isNotEmpty == true ? b['kode_promo'] : '-'),
              _detailRow('Diskon', _rp(b['diskon'] ?? 0)),
              _detailRow('Total Harga', _rp(b['total_harga']),
                  bold: true),
              _detailRow('Order ID', b['order_id']?.toString() ?? '-'),
              _detailRow('Status Pembayaran',
                  _statusLabel(b['status_pembayaran'])),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: Text('Tutup',
                      style: _t(size: 13, weight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool bold = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(flex: 2,
              child: Text(label,
                  style: _t(size: 13, color: _muted))),
          Expanded(flex: 3,
              child: Text(value,
                  style: _t(size: 13,
                      weight: bold ? FontWeight.w700 : FontWeight.w500))),
        ]),
      );

  /// Edit status pembayaran
  void _editStatus(Map<String, dynamic> b) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Ubah Status Booking',
              style: _t(size: 16, weight: FontWeight.w700)),
          const SizedBox(height: 20),
          _statusTile(b, 'lunas', Icons.check_circle_outline_rounded, _green),
          _statusTile(b, 'menunggu', Icons.hourglass_empty_rounded, _orange),
          _statusTile(b, 'batal', Icons.cancel_outlined, _red),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _statusTile(Map<String, dynamic> b, String status,
      IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(_statusLabel(status), style: _t(size: 14)),
      onTap: () async {
        Navigator.pop(context);
        await _firestore
            .collection('bookings')
            .doc(b['id'])
            .update({'status_pembayaran': status});
        // StreamBuilder otomatis refresh
      },
    );
  }

  /// Konfirmasi hapus
  void _confirmDelete(Map<String, dynamic> b) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Booking?',
            style: _t(size: 16, weight: FontWeight.w700)),
        content: Text(
            'Data booking ${b['customer_name'] ?? ''} akan dihapus permanen.',
            style: _t(size: 13, color: _muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: _t(size: 14, color: _muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('Hapus',
                style: _t(size: 14, weight: FontWeight.w600,
                    color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _firestore.collection('bookings').doc(b['id']).delete();
    }
  }
}