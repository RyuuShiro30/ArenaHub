import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/form_booking.dart';

class PilihJadwalPage extends StatefulWidget {
  const PilihJadwalPage({super.key, required this.lapanganId});
  final String lapanganId;

  @override
  _PilihJadwalPageState createState() => _PilihJadwalPageState();
}

class _PilihJadwalPageState extends State<PilihJadwalPage> {
  // ── Data lapangan ─────────────────────────────────────────────
  String namaLapangan = '';
  String jenisLapangan = '';
  String jenisFloor = '';
  String fotoUrl = '';
  int pricePerHour = 0;
  bool isLoadingLapangan = true;

  // ── Date & slot state ─────────────────────────────────────────
  DateTime selectedDate = DateTime.now();
  List<String> selectedTimes = [];
  List<String> times = [];       // slot dari Firestore
  List<String> fullTimes = [];   // slot tidak tersedia / dipesan
  bool isLoadingSlot = false;

  // ── Colors ────────────────────────────────────────────────────
  final Color primaryBlue = const Color(0xFF0B4E89);
  final Color primaryGreen = const Color(0xFF1A8C6A);
  final Color fullGrey = const Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _fetchLapangan();
    _fetchSlot();
  }

  // ── Fetch lapangan detail ─────────────────────────────────────
  Future<void> _fetchLapangan() async {
    final doc = await FirebaseFirestore.instance
        .collection('lapangan')
        .doc(widget.lapanganId)
        .get();

    if (doc.exists) {
      final map = doc.data()!;
      setState(() {
        namaLapangan  = map['nama_lapangan'] ?? '';
        jenisLapangan = map['jenis_lapangan'] ?? '';
        jenisFloor    = map['jenis_floor'] ?? '';
        fotoUrl       = (map['foto'] as List?)?.first ?? '';
        pricePerHour  = map['harga'] ?? 0;
        isLoadingLapangan = false;
      });
    } else {
      setState(() => isLoadingLapangan = false);
    }
  }

  // ── Fetch slot dari Firestore berdasarkan lapangan + tanggal ──
  Future<void> _fetchSlot() async {
    setState(() {
      isLoadingSlot = true;
      times         = [];
      fullTimes     = [];
      selectedTimes = []; // reset pilihan saat ganti tanggal
    });

    final startOfDay = DateTime(
      selectedDate.year, selectedDate.month, selectedDate.day,
      0, 0, 0,
    );
    final endOfDay = DateTime(
      selectedDate.year, selectedDate.month, selectedDate.day,
      23, 59, 59,
    );

    try {
      final snap = await FirebaseFirestore.instance
          .collection('jadwal')
          .where('lapangan_id', isEqualTo: widget.lapanganId)
          .where('tanggal',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('tanggal',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('tanggal')
          .get();

      final List<String> allTimes    = [];
      final List<String> bookedTimes = [];

      for (final doc in snap.docs) {
        final data   = doc.data();
        final waktu  = data['waktu_operasional'] as String? ?? '';
        final status = data['status'] as String? ?? 'tersedia';

        if (waktu.isEmpty) continue;

        allTimes.add(waktu);
        if (status == 'dipesan' || status == 'tidak_tersedia') {
          bookedTimes.add(waktu);
        }
      }

      setState(() {
        times         = allTimes;
        fullTimes     = bookedTimes;
        isLoadingSlot = false;
      });
    } catch (e) {
      setState(() => isLoadingSlot = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────
  List<DateTime> getFiveDays() {
    return List.generate(5, (index) {
      return selectedDate.add(Duration(days: index - 2));
    });
  }

  String formatCurrency(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (isLoadingLapangan) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final int totalAmount = selectedTimes.length * pricePerHour;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: primaryBlue,
            size: 20,
          ),
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
                      // ── Info lapangan ───────────────────────────
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
                                    )
                                  : Container(
                                      width: 70,
                                      height: 70,
                                      color: const Color(0xFFE3EAF5),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Column(
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
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Header bulan + icon kalender ────────────
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
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2026, 1),
                                lastDate: DateTime(2026, 12),
                              );
                              if (picked != null) {
                                setState(() => selectedDate = picked);
                                _fetchSlot(); // ← refresh slot
                              }
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // ── 5 hari horizontal ───────────────────────
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: getFiveDays().map((date) {
                            final bool isSelected =
                                date.day == selectedDate.day &&
                                date.month == selectedDate.month &&
                                date.year == selectedDate.year;

                            return GestureDetector(
                              onTap: () {
                                setState(() => selectedDate = date);
                                _fetchSlot(); // ← refresh slot
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
                                  padding: const EdgeInsets.only(
                                      left: 9.18, right: 9.19),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? primaryBlue
                                        : Colors.transparent,
                                    borderRadius:
                                        BorderRadius.circular(22),
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

                      // ── Label slot ──────────────────────────────
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Slot Waktu Tersedia",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ── Grid slot ───────────────────────────────
                      isLoadingSlot
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                  child: CircularProgressIndicator()),
                            )
                          : times.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 32),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.calendar_today_outlined,
                                          size: 40,
                                          color: Colors.grey.shade300,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Tidak ada slot tersedia\nuntuk tanggal ini',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey.shade400,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : GridView.builder(
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  itemCount: times.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    childAspectRatio: 102.34 / 46,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                                  itemBuilder: (context, index) {
                                    final String time = times[index];
                                    final bool isSelected =
                                        selectedTimes.contains(time);
                                    final bool isFull =
                                        fullTimes.contains(time);

                                    return GestureDetector(
                                      onTap: isFull
                                          ? null
                                          : () {
                                              setState(() {
                                                if (isSelected) {
                                                  selectedTimes
                                                      .remove(time);
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
                                          borderRadius:
                                              BorderRadius.circular(16),
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
                                          padding: const EdgeInsets.only(
                                            left: 13.91,
                                            right: 13.9,
                                            top: 12,
                                            bottom: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isFull
                                                ? fullGrey
                                                : (isSelected
                                                    ? primaryBlue
                                                    : primaryGreen
                                                        .withOpacity(0.1)),
                                            borderRadius:
                                                BorderRadius.circular(
                                                    isSelected ? 14 : 16),
                                          ),
                                          child: Text(
                                            time,
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                              decoration: isFull
                                                  ? TextDecoration
                                                      .lineThrough
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

                      // ── Legend ──────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          legend(primaryGreen.withOpacity(0.2), "Tersedia"),
                          const SizedBox(width: 10),
                          legend(primaryBlue, "Dipilih"),
                          const SizedBox(width: 10),
                          legend(fullGrey, "Penuh"),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Bottom bar ──────────────────────────────────────
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
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                    ),
                    onPressed: selectedTimes.isEmpty
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FormBookingPage(
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
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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

  // ── Legend widget ─────────────────────────────────────────────
  Widget legend(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(text),
      ],
    );
  }
}