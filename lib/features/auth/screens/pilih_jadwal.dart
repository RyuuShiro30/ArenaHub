import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PilihJadwalPage extends StatefulWidget {
  const PilihJadwalPage({super.key});

  @override
  _PilihJadwalPageState createState() => _PilihJadwalPageState();
}

class _PilihJadwalPageState extends State<PilihJadwalPage> {
  DateTime selectedDate = DateTime.now();
  
  // Perubahan 1: Gunakan List untuk menampung banyak pilihan
  List<String> selectedTimes = [];

  final Color primaryBlue = Color(0xFF0B4E89);
  final Color primaryGreen = Color(0xFF1A8C6A);
  final Color fullGrey = Color(0xFFE2E8F0);
  final int pricePerHour = 150000;

  List<String> times = [
    "06.00 - 07.00", "07.00 - 08.00", "08.00 - 09.00",
    "09.00 - 10.00", "10.00 - 11.00", "11.00 - 12.00",
    "12.00 - 13.00", "13.00 - 14.00", "14.00 - 15.00",
    "15.00 - 16.00", "16.00 - 17.00", "17.00 - 18.00",
    "18.00 - 19.00", "19.00 - 20.00", "20.00 - 21.00",
  ];

  List<String> fullTimes = [];

  List<DateTime> getFiveDays() {
    return List.generate(5, (index) {
      return selectedDate.add(Duration(days: index - 2));
    });
  }

  // Perubahan 2: Fungsi formatter untuk harga Rupiah
  String formatCurrency(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    // Perubahan 3: Hitung total harga berdasarkan jumlah pilihan
    int totalAmount = selectedTimes.length * pricePerHour;

    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.arrow_back, color: primaryBlue),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Pilih Jadwal",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: primaryBlue)),
                      const Text("ArenaHub • Lapangan A",
                          style: TextStyle(fontSize: 12)),
                    ],
                  )
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
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
                              child: Image.network(
                                "https://via.placeholder.com/80",
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Lapangan Futsal A",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),
                                const Text("Futsal • Vinyl Floor"),
                                const SizedBox(height: 4),
                                Text("${formatCurrency(pricePerHour)} /jam",
                                    style: TextStyle(
                                        color: primaryBlue,
                                        fontWeight: FontWeight.bold)),
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat("MMMM yyyy").format(selectedDate),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_month),
                            onPressed: () async {
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2026, 1),
                                lastDate: DateTime(2026, 12),
                              );
                              if (picked != null) {
                                setState(() {
                                  selectedDate = picked;
                                });
                              }
                            },
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: getFiveDays().map((date) {
                            bool isSelected = date.day == selectedDate.day;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedDate = date;
                                });
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
                                  margin: isSelected ? const EdgeInsets.all(2.5) : EdgeInsets.zero,
                                  padding: const EdgeInsets.only(left: 9.18, right: 9.19),
                                  decoration: BoxDecoration(
                                    color: isSelected ? primaryBlue : Colors.transparent,
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        DateFormat("E").format(date),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: isSelected ? Colors.white : Colors.black,
                                        ),
                                      ),
                                      Text(
                                        date.day.toString(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: isSelected ? Colors.white : Colors.black,
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
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Slot Waktu Tersedia",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: times.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 102.34 / 46,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemBuilder: (context, index) {
                          String time = times[index];
                          
                          // Perubahan 4: Cek apakah jam ini ada di dalam list pilihan
                          bool isSelected = selectedTimes.contains(time);
                          bool isFull = fullTimes.contains(time);

                          return GestureDetector(
                            onTap: isFull 
                                ? null 
                                : () {
                                    setState(() {
                                      // Perubahan 5: Toggle pilihan (tambah jika belum ada, hapus jika sudah ada)
                                      if (isSelected) {
                                        selectedTimes.remove(time);
                                      } else {
                                        selectedTimes.add(time);
                                      }
                                    });
                                  },
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
                                margin: isSelected ? const EdgeInsets.all(2) : EdgeInsets.zero,
                                alignment: Alignment.center,
                                padding: const EdgeInsets.only(
                                    left: 13.91, right: 13.9, top: 12, bottom: 12),
                                decoration: BoxDecoration(
                                  color: isFull
                                      ? fullGrey
                                      : (isSelected
                                          ? primaryBlue
                                          : primaryGreen.withOpacity(0.1)),
                                  borderRadius: BorderRadius.circular(isSelected ? 14 : 16),
                                ),
                                child: Text(
                                  time,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    decoration: isFull ? TextDecoration.lineThrough : null,
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
                      const SizedBox(height: 20),
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
            
            // BOTTOM BAR DENGAN KALKULASI DINAMIS
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Perubahan 6: Tampilkan jumlah jam yang dipilih
                      Text("Total Harga (${selectedTimes.length} Jam)",
                          style: const TextStyle(fontSize: 12)),
                      Text(formatCurrency(totalAmount),
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: primaryBlue,
                              fontSize: 18)),
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
                    onPressed: selectedTimes.isEmpty ? null : () {
                      Navigator.pushNamed(
                      context,
                      '/payment',
                      arguments: {
                        'totalHarga': totalAmount + 5000, // +5000 biaya layanan
                        'namaLapangan': 'Lapangan Futsal A',
                        'customerName': 'Nama Customer', // ganti dengan data user asli
                        'email': 'email@example.com',    // ganti dengan data user asli
                        'phone': '08123456789',          // ganti dengan data user asli
                      },
                    );
                    },
                    child: const Text("Lanjut ke Booking",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget legend(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 4),
        Text(text)
      ],
    );
  }
}