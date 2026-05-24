import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/form_booking.dart';

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
  State<PilihJadwalPage> createState() => _PilihJadwalPageState();
}

class _PilihJadwalPageState extends State<PilihJadwalPage> {
  // ───────────────── DATA LAPANGAN ─────────────────
  late String namaLapangan;
  late String jenisLapangan;
  late String jenisFloor;
  late String fotoUrl;
  late int pricePerHour;

  // ───────────────── SLOT STATE ─────────────────
  bool isLoadingSlot = false;

  DateTime selectedDate = DateTime.now();

  List<String> selectedTimes = [];

  // Slot dari admin
  List<String> times = [];

  // Slot penuh dari bookings
  List<String> fullTimes = [];

  final Color primaryBlue = const Color(0xFF0B4E89);
  final Color primaryGreen = const Color(0xFF1A8C6A);
  final Color fullGrey = const Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();

    namaLapangan = widget.namaLapangan ?? '';
    jenisLapangan = widget.jenisLapangan ?? '';
    jenisFloor = widget.jenisFloor ?? '';
    fotoUrl = widget.fotoUrl ?? '';
    pricePerHour = widget.pricePerHour ?? 0;

    final needsFetch = namaLapangan.isEmpty;

    if (needsFetch) {
      _fetchLapangan();
    } else {
      _loadData();
    }
  }

  // ───────────────── LOAD DATA ─────────────────
  Future<void> _loadData() async {
    await _fetchJadwalAdmin();
    await _fetchFullSlots();
  }

  // ───────────────── FETCH LAPANGAN ─────────────────
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
          namaLapangan = map['nama_lapangan'] ?? '';
          jenisLapangan = map['jenis_lapangan'] ?? '';
          jenisFloor = map['jenis_floor'] ?? '';
          fotoUrl = (map['foto'] as List?)?.first ?? '';
          pricePerHour = map['harga'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error fetch lapangan: $e');
    } finally {
      if (mounted) {
        setState(() => isLoadingSlot = false);
      }

      _loadData();
    }
  }

  // ───────────────── FETCH JADWAL ADMIN ─────────────────
Future<void> _fetchJadwalAdmin() async {
  try {
    final startOfDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      0,
      0,
      0,
    );

    final endOfDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      23,
      59,
      59,
    );

    final snap = await FirebaseFirestore.instance
        .collection('jadwal')
        .where('lapangan_id', isEqualTo: widget.lapanganId)
        .where(
          'tanggal',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where(
          'tanggal',
          isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
        )
        .get();

    final List<String> jadwalAdmin = [];

    for (final doc in snap.docs) {
      final data = doc.data();

      final waktu =
          data['waktu_operasional']?.toString() ?? '';

      final status =
          data['status']?.toString().toLowerCase() ?? '';

      // HANYA tampilkan slot tersedia
      if (waktu.isNotEmpty && status == 'tersedia') {
        jadwalAdmin.add(waktu);
      }
    }

    // ───────────────── SORT JAM AGAR BERURUTAN ─────────────────
    jadwalAdmin.sort((a, b) {
      try {
        // Ambil jam awal
        final aStart =
            a.split('-').first.trim().replaceAll('.', ':');

        final bStart =
            b.split('-').first.trim().replaceAll('.', ':');

        final aParts = aStart.split(':');
        final bParts = bStart.split(':');

        final aHour = int.parse(aParts[0]);
        final aMinute = int.parse(aParts[1]);

        final bHour = int.parse(bParts[0]);
        final bMinute = int.parse(bParts[1]);

        final aTotal = (aHour * 60) + aMinute;
        final bTotal = (bHour * 60) + bMinute;

        return aTotal.compareTo(bTotal);
      } catch (e) {
        return 0;
      }
    });

    if (mounted) {
      setState(() {
        // Hilangkan duplikat tapi tetap urut
        times = jadwalAdmin.toSet().toList()
          ..sort((a, b) {
            try {
              final aStart =
                  a.split('-').first.trim().replaceAll('.', ':');

              final bStart =
                  b.split('-').first.trim().replaceAll('.', ':');

              final aParts = aStart.split(':');
              final bParts = bStart.split(':');

              final aHour = int.parse(aParts[0]);
              final aMinute = int.parse(aParts[1]);

              final bHour = int.parse(bParts[0]);
              final bMinute = int.parse(bParts[1]);

              final aTotal = (aHour * 60) + aMinute;
              final bTotal = (bHour * 60) + bMinute;

              return aTotal.compareTo(bTotal);
            } catch (e) {
              return 0;
            }
          });
      });
    }
  } catch (e) {
    debugPrint('Error fetch jadwal admin: $e');
  }
}

  // ───────────────── FETCH BOOKING FULL SLOT ─────────────────
  Future<void> _fetchFullSlots() async {
    if (!mounted) return;

    setState(() => isLoadingSlot = true);

    try {
      final dateStr =
          DateFormat('yyyy-MM-dd').format(selectedDate);

      // tanggal_main
      final snap1 = await FirebaseFirestore.instance
          .collection('bookings')
          .where(
            'lapangan_id',
            isEqualTo: widget.lapanganId,
          )
          .where(
            'tanggal_main',
            isEqualTo: dateStr,
          )
          .get();

      // tanggal lama
      final snap2 = await FirebaseFirestore.instance
          .collection('bookings')
          .where(
            'lapangan_id',
            isEqualTo: widget.lapanganId,
          )
          .where(
            'tanggal',
            isEqualTo: dateStr,
          )
          .get();

      final seenIds = <String>{};
      final allDocs = <QueryDocumentSnapshot>[];

      for (final doc in [...snap1.docs, ...snap2.docs]) {
        if (seenIds.add(doc.id)) {
          allDocs.add(doc);
        }
      }

      const validStatuses = {
        'sudah dibayar',
        'pembayaran selesai',
        'confirmed',
        'pending',
      };

      final booked = <String>{};

      for (final doc in allDocs) {
        final data =
            doc.data() as Map<String, dynamic>;

        final statusPembayaran =
            data['status_pembayaran']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final statusAlt =
            data['status']
                    ?.toString()
                    .toLowerCase() ??
                '';

        if (!validStatuses.contains(
              statusPembayaran,
            ) &&
            !validStatuses.contains(statusAlt)) {
          continue;
        }

        final slotField =
            data['slots'] ??
                data['selected_times'] ??
                data['jam_main'];

        if (slotField is List) {
          booked.addAll(
            slotField.map((e) => e.toString()),
          );
        } else if (slotField is String &&
            slotField.isNotEmpty) {
          booked.addAll(
            slotField
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty),
          );
        }
      }

      if (mounted) {
        setState(() {
          fullTimes = booked.toList();

          selectedTimes.removeWhere(
            (t) => fullTimes.contains(t),
          );

          isLoadingSlot = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetch full slots: $e');

      if (mounted) {
        setState(() => isLoadingSlot = false);
      }
    }
  }

  // ───────────────── FORMAT HARGA ─────────────────
  String formatCurrency(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  // ───────────────── 5 HARI ─────────────────
  List<DateTime> getFiveDays() {
    return List.generate(
      5,
      (i) => selectedDate.add(Duration(days: i - 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalAmount =
        selectedTimes.length * pricePerHour;

    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),

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

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding:
                      const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // ───────────────── INFO LAPANGAN ─────────────────
                      Container(
                        padding:
                            const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(
                                  16),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(
                                      12),
                              child: fotoUrl
                                      .isNotEmpty
                                  ? Image.network(
                                      fotoUrl,
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      cacheWidth: 140,
                                      errorBuilder:
                                          (_, __,
                                                  ___) =>
                                              _placeholderFoto(),
                                    )
                                  : _placeholderFoto(),
                            ),

                            const SizedBox(
                                width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    namaLapangan,
                                    style:
                                        GoogleFonts
                                            .poppins(
                                      fontWeight:
                                          FontWeight
                                              .w800,
                                    ),
                                  ),

                                  Text(
                                    '$jenisLapangan • $jenisFloor',
                                  ),

                                  const SizedBox(
                                      height: 4),

                                  Text(
                                    '${formatCurrency(pricePerHour)} /jam',
                                    style:
                                        GoogleFonts
                                            .poppins(
                                      color:
                                          primaryBlue,
                                      fontWeight:
                                          FontWeight
                                              .w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ───────────────── HEADER BULAN ─────────────────
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,
                        children: [
                          Text(
                            DateFormat(
                              "MMMM yyyy",
                            ).format(
                              selectedDate,
                            ),
                            style:
                                GoogleFonts.poppins(
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),

                          IconButton(
                            icon: Icon(
                              Icons.calendar_month,
                              color: primaryBlue,
                            ),
                            onPressed:
                                () async {
                              final picked =
                                  await showDatePicker(
                                context:
                                    context,
                                initialDate:
                                    selectedDate,
                                firstDate:
                                    DateTime(
                                        2026,
                                        1),
                                lastDate:
                                    DateTime(
                                        2026,
                                        12),
                              );

                              if (picked !=
                                  null) {
                                setState(() {
                                  selectedDate =
                                      picked;

                                  selectedTimes
                                      .clear();
                                });

                                _loadData();
                              }
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // ───────────────── PILIH HARI ─────────────────
                      SingleChildScrollView(
                        scrollDirection:
                            Axis.horizontal,
                        child: Row(
                          children:
                              getFiveDays()
                                  .map((date) {
                            final isSelected =
                                date.day ==
                                        selectedDate
                                            .day &&
                                    date.month ==
                                        selectedDate
                                            .month &&
                                    date.year ==
                                        selectedDate
                                            .year;

                            return GestureDetector(
                              onTap: () {
                                if (!isSelected) {
                                  setState(() {
                                    selectedDate =
                                        date;

                                    selectedTimes
                                        .clear();
                                  });

                                  _loadData();
                                }
                              },
                              child: Container(
                                width: 60,
                                height: 80,
                                margin:
                                    const EdgeInsets.only(
                                  right: 10,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color:
                                      Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(
                                          24),
                                  border:
                                      Border.all(
                                    color:
                                        isSelected
                                            ? primaryBlue
                                            : Colors
                                                .grey
                                                .shade300,
                                    width: 2,
                                  ),
                                ),
                                child:
                                    Container(
                                  margin:
                                      isSelected
                                          ? const EdgeInsets.all(
                                              2.5)
                                          : EdgeInsets
                                              .zero,
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        isSelected
                                            ? primaryBlue
                                            : Colors.transparent,
                                    borderRadius:
                                        BorderRadius.circular(
                                            22),
                                  ),
                                  child:
                                      Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        DateFormat(
                                          "E",
                                        ).format(
                                          date,
                                        ),
                                        style:
                                            GoogleFonts.poppins(
                                          fontWeight:
                                              FontWeight.w800,
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : Colors.black,
                                        ),
                                      ),
                                      Text(
                                        date.day
                                            .toString(),
                                        style:
                                            GoogleFonts.poppins(
                                          fontWeight:
                                              FontWeight.w800,
                                          fontSize:
                                              16,
                                          color:
                                              isSelected
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

                      // ───────────────── HEADER SLOT ─────────────────
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,
                        children: [
                          Text(
                            "Slot Waktu Tersedia",
                            style:
                                GoogleFonts.poppins(
                              fontWeight:
                                  FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),

                          if (isLoadingSlot)
                            SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    primaryBlue,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // ───────────────── GRID SLOT ─────────────────
                      times.isEmpty &&
                              !isLoadingSlot
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(
                                vertical: 40,
                              ),
                              child: Text(
                                'Tidak ada jadwal tersedia',
                                style:
                                    GoogleFonts.poppins(
                                  color: Colors
                                      .grey,
                                ),
                              ),
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              itemCount:
                                  times.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:
                                    3,
                                childAspectRatio:
                                    102.34 /
                                        46,
                                crossAxisSpacing:
                                    8,
                                mainAxisSpacing:
                                    8,
                              ),
                              itemBuilder:
                                  (context,
                                      index) {
                                final time =
                                    times[index];

                                final isSelected =
                                    selectedTimes
                                        .contains(
                                            time);

                                final isFull =
                                    fullTimes
                                        .contains(
                                            time);

                                return GestureDetector(
                                  onTap: (isFull ||
                                          isLoadingSlot)
                                      ? null
                                      : () {
                                          setState(
                                              () {
                                            if (isSelected) {
                                              selectedTimes.remove(
                                                  time);
                                            } else {
                                              selectedTimes.add(
                                                  time);
                                            }
                                          });
                                        },
                                  child:
                                      Container(
                                    decoration:
                                        BoxDecoration(
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : Colors.transparent,
                                      borderRadius:
                                          BorderRadius.circular(
                                              16),
                                      border:
                                          Border.all(
                                        color:
                                            isFull
                                                ? Colors.transparent
                                                : (isSelected
                                                    ? primaryBlue
                                                    : primaryGreen),
                                      ),
                                    ),
                                    child:
                                        Container(
                                      margin:
                                          isSelected
                                              ? const EdgeInsets.all(
                                                  2)
                                              : EdgeInsets.zero,
                                      alignment:
                                          Alignment.center,
                                      decoration:
                                          BoxDecoration(
                                        color:
                                            isFull
                                                ? fullGrey
                                                : (isSelected
                                                    ? primaryBlue
                                                    : primaryGreen.withOpacity(
                                                        0.1)),
                                        borderRadius:
                                            BorderRadius.circular(
                                                isSelected
                                                    ? 14
                                                    : 16),
                                      ),
                                      child:
                                          Text(
                                        time,
                                        style:
                                            GoogleFonts.poppins(
                                          fontWeight:
                                              FontWeight.w800,
                                          fontSize:
                                              12,
                                          decoration:
                                              isFull
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                          color:
                                              isFull
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

                      // ───────────────── LEGENDA ─────────────────
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                        children: [
                          _legend(
                            primaryGreen
                                .withOpacity(
                                    0.2),
                            "Tersedia",
                          ),

                          const SizedBox(
                              width: 10),

                          _legend(
                            primaryBlue,
                            "Dipilih",
                          ),

                          const SizedBox(
                              width: 10),

                          _legend(
                            fullGrey,
                            "Penuh",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ───────────────── BOTTOM BAR ─────────────────
            Container(
              padding:
                  const EdgeInsets.all(16),
              decoration:
                  const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        "Total Harga (${selectedTimes.length} Jam)",
                        style:
                            const TextStyle(
                          fontSize: 12,
                        ),
                      ),

                      Text(
                        formatCurrency(
                            totalAmount),
                        style:
                            GoogleFonts.poppins(
                          fontWeight:
                              FontWeight.w800,
                          color:
                              primaryBlue,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),

                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          primaryBlue,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                                30),
                      ),
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                    onPressed:
                        selectedTimes
                                .isEmpty
                            ? null
                            : () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) =>
                                            FormBookingPage(
                                      lapanganId:
                                          widget.lapanganId,
                                      selectedDate:
                                          selectedDate,
                                      selectedTimes:
                                          selectedTimes,
                                      serviceFee:
                                          5000,
                                    ),
                                  ),
                                );

                                _loadData();
                              },
                    child:
                        const Text(
                      "Lanjut ke Booking",
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w600,
                        color:
                            Colors.white,
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

  // ───────────────── PLACEHOLDER FOTO ─────────────────
  Widget _placeholderFoto() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFFE3EAF5),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.sports_soccer_rounded,
        color: Color(0xFF1B4E82),
        size: 28,
      ),
    );
  }

  // ───────────────── LEGENDA ─────────────────
  Widget _legend(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius:
                BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(text),
      ],
    );
  }
}
