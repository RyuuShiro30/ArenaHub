import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class ReschedulePage extends StatefulWidget {
  final String bookingId;

  const ReschedulePage({super.key, required this.bookingId});

  @override
  State<ReschedulePage> createState() => _ReschedulePageState();
}

class _ReschedulePageState extends State<ReschedulePage> {
  // ── Colors ─────────────────────────────────────────────────────
  final Color primaryBlue  = const Color(0xFF0B4E89);
  final Color primaryGreen = const Color(0xFF1A8C6A);
  final Color fullGrey     = const Color(0xFFE2E8F0);

  static const Color _primaryColor = Color(0xFF135B9D);
  static const Color _errorColor   = Color(0xFFE53935);
  static const Color _successColor = Color(0xFF2ECC71);
  static const Color _warningColor = Color(0xFFFF9800);

  // ── State: booking lama ────────────────────────────────────────
  Map<String, dynamic>? _booking;
  bool _isLoadingBooking = true;

  // ── State: jadwal baru ─────────────────────────────────────────
  bool _isLoadingSlot = false;
  late DateTime _selectedDate;
  List<String> _selectedTimes = [];
  List<String> _bookedTimes   = [];
  List<Map<String, dynamic>> _jadwalDocs = [];
  List<String> _times = [];

  // ── State: submit ──────────────────────────────────────────────
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    tz_data.initializeTimeZones();
    _selectedDate = _nowWib();
    _fetchBooking();
  }

  // ────────────────────────────────────────────────────────────────
  // HELPERS
  // ────────────────────────────────────────────────────────────────

  DateTime _nowWib() {
    final wib    = tz.getLocation('Asia/Jakarta');
    final nowWib = tz.TZDateTime.now(wib);
    return DateTime(nowWib.year, nowWib.month, nowWib.day,
        nowWib.hour, nowWib.minute, nowWib.second);
  }

  double _slotEndHour(String slot) {
    final part     = slot.split(' - ').last.trim();
    final segments = part.split('.');
    final hour     = int.tryParse(segments[0]) ?? 0;
    final minute   =
        int.tryParse(segments.length > 1 ? segments[1] : '0') ?? 0;
    return hour + minute / 60.0;
  }

  bool _isSlotPassed(String slot) {
    final nowWib   = _nowWib();
    final today    = DateTime(nowWib.year, nowWib.month, nowWib.day);
    final selected = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day);

    if (selected.isBefore(today)) return true;
    if (selected.isAfter(today))  return false;

    final double currentHour = nowWib.hour + nowWib.minute / 60.0;
    return _slotEndHour(slot) <= currentHour;
  }

  bool _isSlotUnavailable(String slot) =>
      _isSlotPassed(slot) || _bookedTimes.contains(slot);

  String _toSlotLabel(String mulai, String selesai) {
    return '${mulai.replaceAll(':', '.')} - ${selesai.replaceAll(':', '.')}';
  }

  String _formatTanggal(DateTime dt) {
    const bulan = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${dt.day} ${bulan[dt.month]} ${dt.year}';
  }

  String _formatRupiah(dynamic nominal) {
    final int amount =
        nominal is int ? nominal : int.tryParse(nominal.toString()) ?? 0;
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(amount);
  }

  List<DateTime> _getFiveDays() {
    final today = DateTime(_nowWib().year, _nowWib().month, _nowWib().day);
    return List.generate(14, (i) => today.add(Duration(days: i)));
  }

  // ────────────────────────────────────────────────────────────────
  // FETCH
  // ────────────────────────────────────────────────────────────────

  Future<void> _fetchBooking() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;

        // Ambil foto lapangan
        final lapId = data['lapangan_id'] ?? '';
        if (lapId.isNotEmpty) {
          final lapDoc = await FirebaseFirestore.instance
              .collection('lapangan')
              .doc(lapId)
              .get();
          if (lapDoc.exists) {
            final fotoList = lapDoc.data()?['foto'];
            data['foto'] = (fotoList is List && fotoList.isNotEmpty)
                ? fotoList[0].toString()
                : '';
          }
        }

        // Set tanggal awal = tanggal booking lama (supaya user lihat
        // konteks, tapi tetap bisa ganti)
        final tanggalStr = data['tanggal_main'] as String?;
        if (tanggalStr != null) {
          final parsed = DateTime.tryParse(tanggalStr);
          if (parsed != null) {
            final nowWib = _nowWib();
            final today  = DateTime(nowWib.year, nowWib.month, nowWib.day);
            // Kalau tanggal lama sudah lewat, default ke hari ini
            _selectedDate = parsed.isBefore(today) ? today : parsed;
          }
        }

        setState(() {
          _booking         = data;
          _isLoadingBooking = false;
        });
        _fetchJadwalDanBooking();
      } else {
        setState(() => _isLoadingBooking = false);
      }
    } catch (_) {
      setState(() => _isLoadingBooking = false);
    }
  }

  Future<void> _fetchJadwalDanBooking() async {
    if (!mounted) return;
    setState(() => _isLoadingSlot = true);

    try {
      final lapId      = (_booking?['lapangan_id'] ?? '').toString();
      final startOfDay = DateTime(
          _selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0, 0);
      final endOfDay   = DateTime(
          _selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);
      final dateStr    = DateFormat('yyyy-MM-dd').format(_selectedDate);

      // ① Jadwal dari admin
      final jadwalSnap = await FirebaseFirestore.instance
          .collection('jadwal')
          .where('lapangan_id', isEqualTo: lapId)
          .where('tanggal',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('tanggal',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      final docs = <Map<String, dynamic>>[];
      final unavailableFromAdmin = <String>[];

      for (final doc in jadwalSnap.docs) {
        final d      = doc.data();
        final mulai   = d['waktu_mulai']   ?? '';
        final selesai = d['waktu_selesai'] ?? '';
        final status  = d['status']        ?? 'tersedia';
        final label   = _toSlotLabel(mulai, selesai);

        docs.add({'id': doc.id, 'slot': label, 'status': status});

        if (status == 'tidak_tersedia' || status == 'dipesan') {
          unavailableFromAdmin.add(label);
        }
      }

      docs.sort((a, b) {
        final aH = int.tryParse((a['slot'] as String).split('.')[0]) ?? 0;
        final bH = int.tryParse((b['slot'] as String).split('.')[0]) ?? 0;
        return aH.compareTo(bH);
      });

      // ② Slot yang sudah dibooking user lain
      final bookingSnap = await FirebaseFirestore.instance
          .collection('bookings')
          .where('lapangan_id', isEqualTo: lapId)
          .where('tanggal', isEqualTo: dateStr)
          .where('status', whereIn: ['confirmed', 'pending'])
          .get();

      final bookedByOthers = <String>{};
      for (final doc in bookingSnap.docs) {
        // Abaikan booking yang sedang di-reschedule (booking diri sendiri)
        if (doc.id == widget.bookingId) continue;
        final slots = doc.data()['slots'] ?? doc.data()['selected_times'];
        if (slots is List) {
          bookedByOthers.addAll(slots.map((e) => e.toString()));
        }
      }

      if (mounted) {
        setState(() {
          _jadwalDocs   = docs;
          _times        = docs.map((d) => d['slot'] as String).toList();
          _bookedTimes  = {...unavailableFromAdmin, ...bookedByOthers}.toList();
          _selectedTimes.removeWhere(_isSlotUnavailable);
          _isLoadingSlot = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingSlot = false);
    }
  }

  // ────────────────────────────────────────────────────────────────
  // TOGGLE SLOT
  // ────────────────────────────────────────────────────────────────

  void _toggleSlot(String time) {
    setState(() {
      if (_selectedTimes.contains(time)) {
        _selectedTimes.remove(time);
      } else {
        _selectedTimes.add(time);
      }
    });
  }

  // ────────────────────────────────────────────────────────────────
  // SUBMIT RESCHEDULE
  // ────────────────────────────────────────────────────────────────

  Future<void> _konfirmasiReschedule() async {
    if (_selectedTimes.isEmpty) return;

    final confirm = await _showKonfirmasiDialog();
    if (confirm != true || !mounted) return;

    setState(() => _isSubmitting = true);

    try {
      final oldLapId       = (_booking?['lapangan_id'] ?? '').toString();
      final oldTanggalStr  = (_booking?['tanggal_main'] ?? '').toString();
      final oldJamMain     =
          (_booking?['selected_times'] ?? _booking?['jam_main'] ?? '')
              .toString();

      final newTanggalStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      // Urutkan slot baru berdasarkan jam mulai
      final sortedNew = List<String>.from(_selectedTimes)
        ..sort((a, b) {
          final aH = int.tryParse(a.split('.')[0]) ?? 0;
          final bH = int.tryParse(b.split('.')[0]) ?? 0;
          return aH.compareTo(bH);
        });
      final newJamMain = sortedNew.join(', ');

      final hargaPerJam =
          (_booking?['harga_per_jam'] as num?)?.toInt() ??
          (_booking?['total_harga'] as num?)?.toInt() ?? 0;
      final biayaLayanan = (_booking?['biaya_layanan'] as num?)?.toInt() ?? 5000;
      final diskon       = (_booking?['diskon'] as num?)?.toInt() ?? 0;
      final newSubtotal  = hargaPerJam * sortedNew.length;
      final newTotal     = newSubtotal + biayaLayanan - diskon;

      final firestore = FirebaseFirestore.instance;

      // ① Restore slot LAMA → tersedia
      await _restoreOldSlots(
          lapId: oldLapId,
          tanggalStr: oldTanggalStr,
          jamMain: oldJamMain);

      // ② Tandai slot BARU → dipesan di koleksi jadwal
      await _markNewSlots(
          lapId: oldLapId,
          tanggalStr: newTanggalStr,
          selectedTimes: sortedNew);

      // ③ Update dokumen booking
      await firestore.collection('bookings').doc(widget.bookingId).update({
        'tanggal_main'  : newTanggalStr,
        'tanggal'       : newTanggalStr,
        'selected_times': newJamMain,
        'jam_main'      : newJamMain,
        'total_harga'   : newTotal,
        'subtotal'      : newSubtotal,
        'rescheduled_at': FieldValue.serverTimestamp(),
        'rescheduled_from_tanggal': oldTanggalStr,
        'rescheduled_from_jam'    : oldJamMain,
      });

      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSuksesDialog(newTanggalStr, newJamMain);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal melakukan reschedule: $e'),
          backgroundColor: _errorColor,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // ── Restore slot lama ─────────────────────────────────────────
  Future<void> _restoreOldSlots({
    required String lapId,
    required String tanggalStr,
    required String jamMain,
  }) async {
    try {
      if (lapId.isEmpty || tanggalStr.isEmpty || jamMain.isEmpty) return;

      final tanggal = DateTime.tryParse(tanggalStr);
      if (tanggal == null) return;

      final startOfDay =
          DateTime(tanggal.year, tanggal.month, tanggal.day, 0, 0, 0);
      final endOfDay =
          DateTime(tanggal.year, tanggal.month, tanggal.day, 23, 59, 59);

      // Parse slot lama — pisah koma, normalize titik → titik dua
      final rawSlots = jamMain
          .split(',')
          .map((s) => s.trim().replaceAll('.', ':'))
          .where((s) => s.isNotEmpty)
          .toSet();

      if (rawSlots.isEmpty) return;

      final snap = await FirebaseFirestore.instance
          .collection('jadwal')
          .where('lapangan_id', isEqualTo: lapId)
          .where('tanggal',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('tanggal',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      if (snap.docs.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      int count   = 0;
      for (final doc in snap.docs) {
        final waktu = (doc.data()['waktu_operasional'] as String? ?? '')
            .trim()
            .replaceAll('.', ':');
        if (rawSlots.contains(waktu) && doc.data()['status'] == 'dipesan') {
          batch.update(doc.reference, {'status': 'tersedia'});
          count++;
        }
      }
      if (count > 0) await batch.commit();
    } catch (e) {
      debugPrint('_restoreOldSlots error: $e');
    }
  }

  // ── Tandai slot baru → dipesan ────────────────────────────────
  Future<void> _markNewSlots({
    required String lapId,
    required String tanggalStr,
    required List<String> selectedTimes,
  }) async {
    try {
      if (lapId.isEmpty || tanggalStr.isEmpty || selectedTimes.isEmpty) return;

      final tanggal = DateTime.tryParse(tanggalStr);
      if (tanggal == null) return;

      final startOfDay =
          DateTime(tanggal.year, tanggal.month, tanggal.day, 0, 0, 0);
      final endOfDay =
          DateTime(tanggal.year, tanggal.month, tanggal.day, 23, 59, 59);

      // Konversi selectedTimes ke format titik dua untuk dibandingkan
      // dengan waktu_operasional di Firestore
      // Format slot di UI: "08.00 - 09.00", format di jadwal: "08:00 - 09:00"
      final normalizedNew = selectedTimes
          .map((s) => s.trim().replaceAll('.', ':'))
          .toSet();

      final snap = await FirebaseFirestore.instance
          .collection('jadwal')
          .where('lapangan_id', isEqualTo: lapId)
          .where('tanggal',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('tanggal',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      if (snap.docs.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      int count   = 0;
      for (final doc in snap.docs) {
        final waktu = (doc.data()['waktu_operasional'] as String? ?? '')
            .trim()
            .replaceAll('.', ':');
        if (normalizedNew.contains(waktu) &&
            doc.data()['status'] == 'tersedia') {
          batch.update(doc.reference, {'status': 'dipesan'});
          count++;
        }
      }
      if (count > 0) await batch.commit();
    } catch (e) {
      debugPrint('_markNewSlots error: $e');
    }
  }

  // ────────────────────────────────────────────────────────────────
  // DIALOGS
  // ────────────────────────────────────────────────────────────────

  Future<bool?> _showKonfirmasiDialog() {
    final sortedNew = List<String>.from(_selectedTimes)
      ..sort((a, b) {
        final aH = int.tryParse(a.split('.')[0]) ?? 0;
        final bH = int.tryParse(b.split('.')[0]) ?? 0;
        return aH.compareTo(bH);
      });

    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.swap_horiz_rounded,
                color: _warningColor, size: 22),
          ),
          const SizedBox(width: 10),
          const Text('Konfirmasi Reschedule',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Jadwal lama
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _errorColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _errorColor.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('JADWAL LAMA',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF888888),
                          letterSpacing: 0.4)),
                  const SizedBox(height: 6),
                  Text(
                    _formatTanggal(
                        DateTime.tryParse(
                                (_booking?['tanggal_main'] ?? '').toString()) ??
                            DateTime.now()),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                  Text(
                    (_booking?['selected_times'] ??
                            _booking?['jam_main'] ??
                            '-')
                        .toString(),
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Icon(Icons.arrow_downward_rounded,
                  color: _primaryColor, size: 20),
            ),
            const SizedBox(height: 8),
            // Jadwal baru
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _successColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _successColor.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('JADWAL BARU',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF888888),
                          letterSpacing: 0.4)),
                  const SizedBox(height: 6),
                  Text(
                    _formatTanggal(_selectedDate),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                  Text(
                    sortedNew.join(', '),
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFCC02)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: _warningColor, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Slot lama akan dikembalikan dan slot baru akan langsung dipesan.',
                      style:
                          TextStyle(fontSize: 12, color: Color(0xFF795548)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal',
                style: TextStyle(color: Color(0xFF9E9E9E))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Ya, Reschedule',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showSuksesDialog(String tanggalBaru, String jamBaru) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF2E7D32), size: 48),
            ),
            const SizedBox(height: 16),
            const Text('Reschedule Berhasil!',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            Text(
              'Jadwal booking telah diperbarui ke:\n'
              '${_formatTanggal(DateTime.tryParse(tanggalBaru) ?? _selectedDate)}\n'
              '$jamBaru',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF666666), height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Pop dialog + pop ReschedulePage,
                  // kembali ke DetailRiwayatPage dengan result true
                  // supaya DetailRiwayatPage bisa refresh
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: const Text('Kembali ke Detail Booking',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // BUILD
  // ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoadingBooking) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          surfaceTintColor: Colors.white,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: primaryBlue, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Reschedule Booking',
              style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 18)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: primaryBlue, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Reschedule Booking',
            style: TextStyle(
                color: primaryBlue,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
      ),
      bottomNavigationBar: _buildTombolKonfirmasi(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoLama(),
              const SizedBox(height: 20),
              _buildPilihTanggal(),
              const SizedBox(height: 20),
              _buildGridSlot(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Info booking lama ─────────────────────────────────────────
  Widget _buildInfoLama() {
    if (_booking == null) return const SizedBox.shrink();

    final foto     = (_booking!['foto'] ?? '').toString();
    final nama     = (_booking!['nama_lapangan'] ?? '-').toString();
    final tanggal  = _formatTanggal(
        DateTime.tryParse((_booking!['tanggal_main'] ?? '').toString()) ??
            DateTime.now());
    final jam      =
        (_booking!['selected_times'] ?? _booking!['jam_main'] ?? '-')
            .toString();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(Icons.swap_horiz_rounded, color: _warningColor, size: 18),
          ),
          const SizedBox(width: 8),
          const Text('Jadwal Saat Ini',
              style:
                  TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: foto.isNotEmpty && foto.startsWith('http')
                ? Image.network(foto,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder())
                : _placeholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nama,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E))),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 12, color: _primaryColor),
                const SizedBox(width: 4),
                Text(tanggal,
                    style: const TextStyle(
                        fontSize: 12.5, color: Color(0xFF666666))),
              ]),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.access_time_rounded,
                    size: 12, color: _primaryColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(jam,
                      style: const TextStyle(
                          fontSize: 12.5, color: Color(0xFF666666))),
                ),
              ]),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFFCC02)),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline_rounded, color: _warningColor, size: 15),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Pilih jadwal baru di bawah untuk mengganti jadwal ini.',
                style: TextStyle(fontSize: 12, color: Color(0xFF795548)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Pilih tanggal ─────────────────────────────────────────────
  Widget _buildPilihTanggal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('MMMM yyyy').format(_selectedDate),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
            ),
            IconButton(
              icon: Icon(Icons.calendar_month, color: primaryBlue),
              onPressed: () async {
                final nowWib = _nowWib();
                final today  = DateTime(nowWib.year, nowWib.month, nowWib.day);
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate.isBefore(today)
                      ? today
                      : _selectedDate,
                  firstDate: today,
                  lastDate: DateTime(2026, 12),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate  = picked;
                    _selectedTimes = [];
                    _times         = [];
                    _jadwalDocs    = [];
                  });
                  _fetchJadwalDanBooking();
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Strip 14 hari
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _getFiveDays().map((date) {
              final isSelected = date.day   == _selectedDate.day &&
                  date.month == _selectedDate.month &&
                  date.year  == _selectedDate.year;
              return GestureDetector(
                onTap: () {
                  if (!isSelected) {
                    setState(() {
                      _selectedDate  = date;
                      _selectedTimes = [];
                      _times         = [];
                      _jadwalDocs    = [];
                    });
                    _fetchJadwalDanBooking();
                  }
                },
                child: Container(
                  width: 60,
                  height: 80,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected ? primaryBlue : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Container(
                    margin: isSelected
                        ? const EdgeInsets.all(2.5)
                        : EdgeInsets.zero,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryBlue : Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E').format(date),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color:
                                isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          date.day.toString(),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color:
                                isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Grid slot ─────────────────────────────────────────────────
  Widget _buildGridSlot() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Pilih Slot Baru',
                style:
                    GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 14)),
            if (_isLoadingSlot)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: primaryBlue),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // Empty state
        if (!_isLoadingSlot && _times.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.event_busy_rounded,
                    size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  'Belum ada jadwal tersedia',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.grey.shade500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Coba pilih tanggal lain',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),

        // Grid
        if (_times.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _times.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 102.34 / 46,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final time       = _times[index];
              final isSelected = _selectedTimes.contains(time);
              final isFull     = _isSlotUnavailable(time);

              return GestureDetector(
                onTap: (isFull || _isLoadingSlot)
                    ? null
                    : () => _toggleSlot(time),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isFull
                          ? Colors.transparent
                          : (isSelected ? primaryBlue : primaryGreen),
                      width: 1,
                    ),
                  ),
                  child: Container(
                    margin: isSelected
                        ? const EdgeInsets.all(2)
                        : EdgeInsets.zero,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 13, vertical: 12),
                    decoration: BoxDecoration(
                      color: isFull
                          ? fullGrey
                          : (isSelected
                              ? primaryBlue
                              : primaryGreen.withOpacity(0.1)),
                      borderRadius:
                          BorderRadius.circular(isSelected ? 14 : 16),
                    ),
                    child: Text(
                      time,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        decoration:
                            isFull ? TextDecoration.lineThrough : null,
                        color: isFull
                            ? Colors.grey.shade500
                            : (isSelected ? Colors.white : primaryGreen),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

        // Legend
        if (_times.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legend(primaryGreen.withOpacity(0.2), 'Tersedia'),
              const SizedBox(width: 10),
              _legend(primaryBlue, 'Dipilih'),
              const SizedBox(width: 10),
              _legend(fullGrey, 'Penuh'),
            ],
          ),
        ],
      ],
    );
  }

  // ── Tombol konfirmasi ─────────────────────────────────────────
  Widget _buildTombolKonfirmasi() {
    final bool canConfirm = _selectedTimes.isNotEmpty && !_isSubmitting;

    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -4))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedTimes.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: primaryBlue.withOpacity(0.15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(Icons.access_time_rounded,
                        color: primaryBlue, size: 16),
                    const SizedBox(width: 6),
                    Text('${_selectedTimes.length} slot dipilih',
                        style: GoogleFonts.poppins(
                            color: primaryBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ]),
                  Text(
                    _formatTanggal(_selectedDate),
                    style: GoogleFonts.poppins(
                        color: primaryBlue,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: canConfirm ? _konfirmasiReschedule : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFBBCCDD),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : const Text('Konfirmasi Reschedule',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers widget ────────────────────────────────────────────
  Widget _placeholder() => Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
            color: const Color(0xFFE3EAF5),
            borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.sports_soccer_rounded,
            color: Color(0xFF1B4E82), size: 28),
      );

  Widget _legend(Color color, String text) => Row(children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(text,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
      ]);
}