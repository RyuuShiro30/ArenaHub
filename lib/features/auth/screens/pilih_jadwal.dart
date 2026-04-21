import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PilihJadwalPage extends StatefulWidget {
  @override
  _PilihJadwalPageState createState() => _PilihJadwalPageState();
}

class _PilihJadwalPageState extends State<PilihJadwalPage> {
  DateTime selectedDate = DateTime(2026, 3, 24);
  String? selectedTime;

  final Color primaryBlue = Color(0xFF0B4E89);
  final Color primaryGreen = Color(0xFF1A8C6A);
  final Color fullGrey = Color(0xFFE2E8F0); // Kode Figma E2E8F0

  List<String> times = [
    "06.00 - 07.00", "07.00 - 08.00", "08.00 - 09.00",
    "09.00 - 10.00", "10.00 - 11.00", "11.00 - 12.00",
    "12.00 - 13.00", "13.00 - 14.00", "14.00 - 15.00",
    "15.00 - 16.00", "16.00 - 17.00", "17.00 - 18.00",
    "18.00 - 19.00", "19.00 - 20.00", "20.00 - 21.00",
  ];

  // Contoh data jam yang sudah penuh
  List<String> fullTimes = ["07.00 - 08.00", "09.00 - 10.00", "15.00 - 16.00"];

  List<DateTime> getFiveDays() {
    return List.generate(5, (index) {
      return selectedDate.add(Duration(days: index - 2));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF5F6FA),
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
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Pilih Jadwal",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: primaryBlue)),
                      Text("ArenaHub • Lapangan A",
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
                        padding: EdgeInsets.all(12),
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
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Lapangan Futsal A",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text("Futsal • Vinyl Floor"),
                                SizedBox(height: 4),
                                Text("IDR 150.000 /jam",
                                    style: TextStyle(
                                        color: primaryBlue,
                                        fontWeight: FontWeight.bold)),
                              ],
                            )
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat("MMMM yyyy").format(selectedDate),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: Icon(Icons.calendar_month),
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
                      SizedBox(height: 10),
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
                                margin: EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: isSelected ? primaryBlue : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: Container(
                                  margin: isSelected ? EdgeInsets.all(2.5) : EdgeInsets.zero,
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
                      SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Slot Waktu Tersedia",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: times.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 102.34 / 46,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemBuilder: (context, index) {
                          String time = times[index];
                          bool isSelected = selectedTime == time;
                          bool isFull = fullTimes.contains(time);

                          return GestureDetector(
                            onTap: isFull 
                                ? null // Tidak bisa diklik jika penuh
                                : () {
                                    setState(() {
                                      selectedTime = time;
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
                                margin: isSelected ? EdgeInsets.all(2) : EdgeInsets.zero,
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
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          legend(primaryGreen.withOpacity(0.2), "Tersedia"),
                          SizedBox(width: 10),
                          legend(primaryBlue, "Dipilih"),
                          SizedBox(width: 10),
                          legend(fullGrey, "Penuh"),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
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
                      Text("Total Harga (1 Jam)",
                          style: TextStyle(fontSize: 12)),
                      Text("IDR 150.000",
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
                      padding: EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                    ),
                    onPressed: () {},
                    child: Text("Lanjut ke Booking",
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
        SizedBox(width: 4),
        Text(text)
      ],
    );
  }
}