import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/form_booking.dart';

class PilihJadwalPage extends StatefulWidget {
  const PilihJadwalPage({
    super.key,
    required this.lapanganId,
    // Data lapangan dikirim langsung dari DetailLapanganPage
    // agar tidak perlu fetch ulang
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

class _PilihJadwalPageState extends State<PilihJadwalPage> {
  // Data lapangan — langsung dari widget jika tersedia
  late String namaLapangan;
  late String jenisLapangan;
  late String jenisFloor;
  late String fotoUrl;
  late int pricePerHour;

  // Loading hanya untuk fetch booking (slot penuh), bukan data lapangan
  bool isLoadingSlot = false;
  DateTime selectedDate = DateTime.now();
  List<String> selectedTimes = [];
  List<String> fullTimes = [];

  final Color primaryBlue = const Color(0xFF0B4E89);
  final Color primaryGreen = const Color(0xFF1A8C6A);
  final Color fullGrey = const Color(0xFFE2E8F0);

  final List<String> times = [
    "06.00 - 07.00", "07.00 - 08.00", "08.00 - 09.00",
    "09.00 - 10.00", "10.00 - 11.00", "11.00 - 12.00",
    "12.00 - 13.00", "13.00 - 14.00", "14.00 - 15.00",
    "15.00 - 16.00", "16.00 - 17.00", "17.00 - 18.00",
    "18.00 - 19.00", "19.00 - 20.00", "20.00 - 21.00",
  ];

  @override
  void initState() {
    super.initState();

    // Pakai data dari parameter jika ada, fallback ke string kosong
    namaLapangan  = widget.namaLapangan  ?? '';
    jenisLapangan = widget.jenisLapangan ?? '';
    jenisFloor    = widget.jenisFloor    ?? '';
    fotoUrl       = widget.fotoUrl       ?? '';
    pricePerHour  = widget.pricePerHour  ?? 0;

    // Jika data lapangan belum tersedia (dipanggil tanpa parameter),
    // baru fetch dari Firestore
    final needsFetch = namaLapangan.isEmpty;
    if (needsFetch) {
      _fetchLapangan();
    } else {
      // Langsung fetch slot yang sudah terisi untuk tanggal hari ini
      _fetchFullSlots();
    }
  }

  // Hanya dipanggil jika data tidak dikirim lewat constructor
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
      setState(() => isLoadingSlot = false);
      _fetchFullSlots();
    }
  }

  // Fetch slot yang sudah dibooking untuk tanggal yang dipilih
  Future<void> _fetchFullSlots() async {
    if (!mounted) return;
    setState(() => isLoadingSlot = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

      // Query pakai 'tanggal_main' (field utama sejak payment baru)
      final snap1 = await FirebaseFirestore.instance
          .collection('bookings')
          .where('lapangan_id', isEqualTo: widget.lapanganId)
          .where('tanggal_main', isEqualTo: dateStr)
          .get();

      // Query pakai 'tanggal' (field lama / kompatibilitas)
      final snap2 = await FirebaseFirestore.instance
          .collection('bookings')
          .where('lapangan_id', isEqualTo: widget.lapanganId)
          .where('tanggal', isEqualTo: dateStr)
          .get();

      // Gabung dan deduplikasi berdasarkan ID dokumen
      final seenIds = <String>{};
      final allDocs = <QueryDocumentSnapshot>[];
      for (final doc in [...snap1.docs, ...snap2.docs]) {
        if (seenIds.add(doc.id)) allDocs.add(doc);
      }

      // Status yang dianggap "sudah dipesan"
      const validStatuses = {
        'sudah dibayar',
        'pembayaran selesai',
        'confirmed',
        'pending',
      };

      final booked = <String>{};
      for (final doc in allDocs) {
        final data = doc.data() as Map<String, dynamic>;

        // Cek status: dukung 'status_pembayaran' maupun 'status'
        final statusPembayaran =
            data['status_pembayaran']?.toString() ?? '';
        final statusAlt = data['status']?.toString() ?? '';
        if (!validStatuses.contains(statusPembayaran) &&
            !validStatuses.contains(statusAlt)) {
          continue; // Lewati booking yang gagal / tidak valid
        }

        // Baca slot: dukung List (field 'slots') maupun String (field 'selected_times'/'jam_main')
        final slotField = data['slots'] ?? data['selected_times'] ?? data['jam_main'];
        if (slotField is List) {
          booked.addAll(slotField.map((e) => e.toString()));
        } else if (slotField is String && slotField.isNotEmpty) {
          booked.addAll(
            slotField.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
          );
        }
      }

      if (mounted) {
        setState(() {
          fullTimes = booked.toList();
          // Hapus dari pilihan jika slot yang dipilih ternyata sudah penuh
          selectedTimes.removeWhere((t) => fullTimes.contains(t));
          isLoadingSlot = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingSlot = false);
    }
  }


  List<DateTime> getFiveDays() {
    return List.generate(5, (i) => selectedDate.add(Duration(days: i - 2)));
  }

  String formatCurrency(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final int totalAmount = selectedTimes.length * pricePerHour;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryBlue, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pilih Jadwal',
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      backgroundColor: const Color(0xffF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // KARTU INFO LAPANGAN
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
                                  ? Image.network(
                                      fotoUrl,
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      // Tampil langsung dari cache jika sudah pernah load
                                      cacheWidth: 140,
                                      errorBuilder: (_, __, ___) =>
                                          _placeholderFoto(),
                                    )
                                  : _placeholderFoto(),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    namaLapangan,
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w800),
                                  ),
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

                      // HEADER BULAN
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat("MMMM yyyy").format(selectedDate),
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w800),
                          ),
                          IconButton(
                            icon: Icon(Icons.calendar_month, color: primaryBlue),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2026, 1),
                                lastDate: DateTime(2026, 12),
                              );
                              if (picked != null) {
                                setState(() {
                                  selectedDate = picked;
                                  selectedTimes.clear();
                                });
                                _fetchFullSlots();
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // PILIHAN HARI
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: getFiveDays().map((date) {
                            final isSelected =
                                date.day == selectedDate.day &&
                                date.month == selectedDate.month &&
                                date.year == selectedDate.year;
                            return GestureDetector(
                              onTap: () {
                                if (!isSelected) {
                                  setState(() {
                                    selectedDate = date;
                                    selectedTimes.clear();
                                  });
                                  _fetchFullSlots();
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

                      // HEADER SLOT
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Slot Waktu Tersedia",
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                          // Indikator loading kecil saat fetch slot
                          if (isLoadingSlot)
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: primaryBlue,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // GRID SLOT WAKTU
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
                          final time = times[index];
                          final isSelected = selectedTimes.contains(time);
                          final isFull = fullTimes.contains(time);

                          return GestureDetector(
                            onTap: (isFull || isLoadingSlot)
                                ? null
                                : () {
                                    setState(() {
                                      if (isSelected) {
                                        selectedTimes.remove(time);
                                      } else {
                                        selectedTimes.add(time);
                                      }
                                    });
                                  },
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
                      const SizedBox(height: 20),

                      // LEGENDA
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
                  ),
                ),
              ),
            ),

            // BOTTOM BAR
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Harga (${selectedTimes.length} Jam)",
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        formatCurrency(totalAmount),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800,
                          color: primaryBlue,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                    ),
                    onPressed: selectedTimes.isEmpty
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FormBookingPage(
                                  lapanganId: widget.lapanganId,
                                  selectedDate: selectedDate,
                                  selectedTimes: selectedTimes,
                                  serviceFee: 5000,
                                ),
                              ),
                            );
                          },
                    child: const Text(
                      "Lanjut ke Booking",
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: Colors.white),
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

  Widget _placeholderFoto() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFFE3EAF5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.sports_soccer_rounded,
          color: Color(0xFF1B4E82), size: 28),
    );
  }

  Widget _legend(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 4),
        Text(text),
      ],
    );
  }
}