import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../../keranjang/cart_manager.dart';
import '../../keranjang/keranjang.dart';

class PilihJadwalPage extends StatefulWidget {
  const PilihJadwalPage({
    super.key,
    required this.lapanganId,
    this.namaLapangan,
    this.jenisLapangan,
    this.jenisFloor,
    this.fotoUrl,
    this.pricePerHour,
  });

  final String lapanganId;
  final String? namaLapangan;
  final String? jenisLapangan;
  final String? jenisFloor;
  final String? fotoUrl;
  final int? pricePerHour;

  @override
  _PilihJadwalPageState createState() => _PilihJadwalPageState();
}

class _PilihJadwalPageState extends State<PilihJadwalPage>
    with SingleTickerProviderStateMixin {
  // ── Data lapangan ─────────────────────────────────────────────
  late String namaLapangan;
  late String jenisLapangan;
  late String jenisFloor;
  late String fotoUrl;
  late int pricePerHour;

  // ── Slot state ────────────────────────────────────────────────
  bool isLoadingSlot = false;
  late DateTime selectedDate;
  List<String> selectedTimes = [];
  List<String> bookedTimes   = [];

  /// Slot yang tersedia dari koleksi jadwal admin
  /// Setiap item: { 'id': docId, 'slot': '06.00 - 07.00', 'status': 'tersedia' }
  List<Map<String, dynamic>> jadwalDocs = [];

  /// Label slot yang ditampilkan di grid (diisi dari jadwalDocs)
  List<String> times = [];

  // ── Animasi FAB ───────────────────────────────────────────────
  late AnimationController _fabAnimController;
  late Animation<double> _fabScaleAnim;

  // ── Colors ────────────────────────────────────────────────────
  final Color primaryBlue  = const Color(0xFF0B4E89);
  final Color primaryGreen = const Color(0xFF1A8C6A);
  final Color fullGrey     = const Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();

    namaLapangan  = widget.namaLapangan  ?? '';
    jenisLapangan = widget.jenisLapangan ?? '';
    jenisFloor    = widget.jenisFloor    ?? '';
    fotoUrl       = widget.fotoUrl       ?? '';
    pricePerHour  = widget.pricePerHour  ?? 0;

    // Animasi bounce FAB
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fabScaleAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _fabAnimController,
      curve: Curves.easeInOut,
    ));

    tz_data.initializeTimeZones();
    selectedDate = _nowWib();

    if (namaLapangan.isEmpty) {
      _fetchLapangan();
    } else {
      _fetchJadwalDanBooking();
    }
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  // ── WIB helpers ───────────────────────────────────────────────
  DateTime _nowWib() {
    final wib    = tz.getLocation('Asia/Jakarta');
    final nowWib = tz.TZDateTime.now(wib);
    return DateTime(
      nowWib.year, nowWib.month, nowWib.day,
      nowWib.hour, nowWib.minute, nowWib.second,
    );
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
    final selected = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    if (selected.isBefore(today)) return true;
    if (selected.isAfter(today)) return false;

    final double currentHour = nowWib.hour + nowWib.minute / 60.0;
    return _slotEndHour(slot) <= currentHour;
  }

  bool _isSlotUnavailable(String slot) =>
      _isSlotPassed(slot) || bookedTimes.contains(slot);

  // ── Fetch lapangan ────────────────────────────────────────────
  Future<void> _fetchLapangan() async {
    setState(() => isLoadingSlot = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('lapangan')
          .doc(widget.lapanganId)
          .get();
      if (doc.exists) {
        final map = doc.data()!;
        setState(() {
          namaLapangan  = map['nama_lapangan']  ?? '';
          jenisLapangan = map['jenis_lapangan'] ?? '';
          jenisFloor    = map['jenis_floor']    ?? '';
          fotoUrl       = (map['foto'] as List?)?.first ?? '';
          pricePerHour  = map['harga'] ?? 0;
        });
      }
    } finally {
      if (mounted) setState(() => isLoadingSlot = false);
      _fetchJadwalDanBooking();
    }
  }

  // ── Konversi format waktu: "08:00" → "08.00" ─────────────────
  String _toSlotLabel(String waktuMulai, String waktuSelesai) {
    final mulai   = waktuMulai.replaceAll(':', '.');
    final selesai = waktuSelesai.replaceAll(':', '.');
    return '$mulai - $selesai';
  }

  // ── Fetch jadwal dari admin + booking existing ────────────────
  Future<void> _fetchJadwalDanBooking() async {
    if (!mounted) return;
    setState(() => isLoadingSlot = true);

    try {
      final startOfDay = DateTime(
          selectedDate.year, selectedDate.month, selectedDate.day, 0, 0, 0);
      final endOfDay = DateTime(
          selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

      // ① Ambil jadwal yang dibuat admin untuk lapangan & tanggal ini
      final jadwalSnap = await FirebaseFirestore.instance
          .collection('jadwal')
          .where('lapangan_id', isEqualTo: widget.lapanganId)
          .where('tanggal',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('tanggal',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      final List<Map<String, dynamic>> docs = [];
      final List<String> unavailableFromAdmin = [];

      for (final doc in jadwalSnap.docs) {
        final data    = doc.data();
        final mulai   = data['waktu_mulai']   ?? '';
        final selesai = data['waktu_selesai'] ?? '';
        final status  = data['status']        ?? 'tersedia';
        final label   = _toSlotLabel(mulai, selesai);

        docs.add({
          'id':     doc.id,
          'slot':   label,
          'status': status,
        });

        // Slot yang admin tandai tidak tersedia / sudah dipesan
        if (status == 'tidak_tersedia' || status == 'dipesan') {
          unavailableFromAdmin.add(label);
        }
      }

      // Urutkan berdasarkan jam mulai
      docs.sort((a, b) {
        final aH = int.tryParse((a['slot'] as String).split('.')[0]) ?? 0;
        final bH = int.tryParse((b['slot'] as String).split('.')[0]) ?? 0;
        return aH.compareTo(bH);
      });

      // ② Ambil slot yang sudah dibooking user lain
      final bookingSnap = await FirebaseFirestore.instance
          .collection('bookings')
          .where('lapangan_id', isEqualTo: widget.lapanganId)
          .where('tanggal', isEqualTo: dateStr)
          .where('status', whereIn: ['confirmed', 'pending'])
          .get();

      final bookedByUser = <String>{};
      for (final doc in bookingSnap.docs) {
        final slots =
            doc.data()['slots'] ?? doc.data()['selected_times'];
        if (slots is List) {
          bookedByUser.addAll(slots.map((e) => e.toString()));
        }
      }

      if (mounted) {
        setState(() {
          jadwalDocs = docs;
          times      = docs.map((d) => d['slot'] as String).toList();
          bookedTimes = {
            ...unavailableFromAdmin,
            ...bookedByUser,
          }.toList();
          // Hapus pilihan yang tiba-tiba jadi tidak tersedia
          selectedTimes.removeWhere((t) => _isSlotUnavailable(t));
          isLoadingSlot = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingSlot = false);
    }
  }

  List<DateTime> getFiveDays() {
    final today =
        DateTime(_nowWib().year, _nowWib().month, _nowWib().day);
    return List.generate(5, (i) => today.add(Duration(days: i)));
  }

  String formatCurrency(int amount) => NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
      .format(amount);

  // ── Toggle slot ───────────────────────────────────────────────
  void _toggleSlot(String time) {
    setState(() {
      if (selectedTimes.contains(time)) {
        selectedTimes.remove(time);
      } else {
        selectedTimes.add(time);
        _fabAnimController.forward(from: 0);
      }
    });
  }

  // ── Tambah ke keranjang → buka halaman keranjang ──────────────
  void _bukaKeranjang() {
    if (selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Pilih minimal 1 slot waktu terlebih dahulu'),
        backgroundColor: primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    // Tambah ke CartManager (merge otomatis jika lapangan+tanggal sama)
    CartManager.instance.tambah(KeranjangItem(
      lapanganId:    widget.lapanganId,
      namaLapangan:  namaLapangan,
      jenisLapangan: jenisLapangan,
      jenisFloor:    jenisFloor,
      fotoUrl:       fotoUrl,
      pricePerHour:  pricePerHour,
      selectedDate:  selectedDate,
      selectedTimes: List<String>.from(selectedTimes),
    ));

    // Reset pilihan lokal setelah masuk keranjang
    setState(() => selectedTimes = []);

    // Buka halaman keranjang
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const KeranjangPage()),
    );
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final int totalAmount = selectedTimes.length * pricePerHour;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: primaryBlue, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pilih Jadwal',
          style: TextStyle(
              color: primaryBlue,
              fontWeight: FontWeight.w700,
              fontSize: 18),
        ),
        actions: [
          ValueListenableBuilder<List<KeranjangItem>>(
            valueListenable: CartManager.instance.itemsNotifier,
            builder: (_, items, __) {
              final totalSlot = CartManager.instance.totalSlot;
              return GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const KeranjangPage())),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(Icons.shopping_cart_rounded,
                          color: primaryBlue, size: 26),
                      if (totalSlot > 0)
                        Positioned(
                          top: -4, right: -6,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle),
                            constraints: const BoxConstraints(
                                minWidth: 17, minHeight: 17),
                            child: Text('$totalSlot',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xffF5F6FA),

      // ── FAB Keranjang ──────────────────────────────────────────
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnim,
        child: FloatingActionButton(
          onPressed: _bukaKeranjang,
          backgroundColor: primaryBlue,
          elevation: 4,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.shopping_cart_rounded,
                  color: Colors.white, size: 26),
              if (selectedTimes.isNotEmpty)
                Positioned(
                  top: -6, right: -8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    constraints: const BoxConstraints(
                        minWidth: 18, minHeight: 18),
                    child: Text(
                      '${selectedTimes.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              children: [
                // ── Info lapangan ──────────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: fotoUrl.isNotEmpty
                            ? Image.network(fotoUrl,
                                width: 70, height: 70,
                                fit: BoxFit.cover,
                                cacheWidth: 140,
                                errorBuilder: (_, __, ___) =>
                                    _placeholderFoto())
                            : _placeholderFoto(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(namaLapangan,
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w800)),
                            Text('$jenisLapangan • $jenisFloor'),
                            const SizedBox(height: 4),
                            Text(
                              '${formatCurrency(pricePerHour)} /jam',
                              style: GoogleFonts.poppins(
                                  color: primaryBlue,
                                  fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Header bulan ───────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat("MMMM yyyy").format(selectedDate),
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800),
                    ),
                    IconButton(
                      icon: Icon(Icons.calendar_month,
                          color: primaryBlue),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(
                              _nowWib().year,
                              _nowWib().month,
                              _nowWib().day),
                          lastDate: DateTime(2026, 12),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                            selectedTimes.clear();
                            times = [];
                            jadwalDocs = [];
                          });
                          _fetchJadwalDanBooking();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── 5 hari horizontal ──────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: getFiveDays().map((date) {
                      final isSelected =
                          date.day   == selectedDate.day &&
                          date.month == selectedDate.month &&
                          date.year  == selectedDate.year;
                      return GestureDetector(
                        onTap: () {
                          if (!isSelected) {
                            setState(() {
                              selectedDate = date;
                              selectedTimes.clear();
                              times = [];
                              jadwalDocs = [];
                            });
                            _fetchJadwalDanBooking();
                          }
                        },
                        child: Container(
                          width: 60, height: 80,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected
                                  ? primaryBlue
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: Container(
                            margin: isSelected
                                ? const EdgeInsets.all(2.5)
                                : EdgeInsets.zero,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primaryBlue
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat("E").format(date),
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                Text(
                                  date.day.toString(),
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
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
                const SizedBox(height: 20),

                // ── Header slot ────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Slot Waktu Tersedia",
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w800,
                            fontSize: 14)),
                    if (isLoadingSlot)
                      SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: primaryBlue),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Empty state jika tidak ada jadwal ─────────
                if (!isLoadingSlot && times.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 36, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.event_busy_rounded,
                            size: 48,
                            color: Colors.grey.shade300),
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
                          'Admin belum menambahkan slot untuk tanggal ini',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ),

                // ── Grid slot ──────────────────────────────────
                if (times.isNotEmpty)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: times.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 102.34 / 46,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemBuilder: (context, index) {
                      final time       = times[index];
                      final isSelected = selectedTimes.contains(time);
                      final isFull     = _isSlotUnavailable(time);

                      return GestureDetector(
                        onTap: (isFull || isLoadingSlot)
                            ? null
                            : () => _toggleSlot(time),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isFull
                                  ? Colors.transparent
                                  : (isSelected
                                      ? primaryBlue
                                      : primaryGreen),
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
                              borderRadius: BorderRadius.circular(
                                  isSelected ? 14 : 16),
                            ),
                            child: Text(
                              time,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                decoration: isFull
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isFull
                                    ? Colors.grey.shade500
                                    : (isSelected
                                        ? Colors.white
                                        : primaryGreen),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                // ── Legend ─────────────────────────────────────
                if (times.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _legend(primaryGreen.withOpacity(0.2), "Tersedia"),
                      const SizedBox(width: 10),
                      _legend(primaryBlue, "Dipilih"),
                      const SizedBox(width: 10),
                      _legend(fullGrey, "Penuh"),
                    ],
                  ),
                ],

                // ── Info total (muncul jika ada slot dipilih) ──
                if (selectedTimes.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: primaryBlue.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Icon(Icons.shopping_cart_rounded,
                              color: primaryBlue, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '${selectedTimes.length} slot dipilih',
                            style: GoogleFonts.poppins(
                                color: primaryBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                          ),
                        ]),
                        Text(
                          formatCurrency(totalAmount),
                          style: GoogleFonts.poppins(
                              color: primaryBlue,
                              fontWeight: FontWeight.w800,
                              fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Tombol masuk keranjang
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _bukaKeranjang,
                      icon: const Icon(
                          Icons.shopping_cart_rounded, size: 18),
                      label: Text(
                        'Masukkan ke Keranjang',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholderFoto() => Container(
        width: 70, height: 70,
        decoration: BoxDecoration(
            color: const Color(0xFFE3EAF5),
            borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.sports_soccer_rounded,
            color: Color(0xFF1B4E82), size: 28),
      );

  Widget _legend(Color color, String text) => Row(
        children: [
          Container(
            width: 12, height: 12,
            decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 4),
          Text(text),
        ],
      );
}