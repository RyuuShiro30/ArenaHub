import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentSuccessPage extends StatelessWidget {
  const PaymentSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mengambil arguments sebagai Map
    final dynamic rawArgs = ModalRoute.of(context)?.settings.arguments;
    
    // Jika arguments null atau bukan Map, beri data default agar tidak error saat testing
    final Map<String, dynamic> args = (rawArgs is Map<String, dynamic>) ? rawArgs : {
      'bookingId': '9281',
      'namaLapangan': 'Futsal Lapangan A',
      'jadwalDate': DateTime(2026, 3, 24),
      'jamMulai': '19:00',
      'jamSelesai': '20:00',
      'totalHarga': 130000,
      'durasi': 1,
    };

    final String bookingId = args['bookingId'].toString();
    final String namaLapangan = args['namaLapangan'];
    final DateTime jadwalDate = args['jadwalDate'];
    final String jamMulai = args['jamMulai'];
    final String jamSelesai = args['jamSelesai'];
    final int totalHarga = args['totalHarga'];
    final int durasi = args['durasi'];

    String formattedDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(jadwalDate);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF004080)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text("Status Pembayaran", style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Berhasil
            Container(
              width: double.infinity,
              color: const Color(0xFFF0F9F8),
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, size: 80, color: Color(0xFF2D958E)),
                  const SizedBox(height: 16),
                  const Text("Pembayaran Berhasil!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                  const Text("Booking lapangan kamu sudah dikonfirmasi", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Card Detail
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("NOMOR BOOKING", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                              child: const Text("LUNAS", style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                        Text("AH-$bookingId", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Divider(height: 30),
                        _rowInfo("Nama Lapangan", namaLapangan),
                        _rowInfo("Jadwal", "$formattedDate\n$jamMulai - $jamSelesai ($durasi Jam)", isMulti: true),
                        _rowInfo("Metode Pembayaran", "QRIS"),
                        const Divider(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total Pembayaran", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text("IDR ${NumberFormat('#,###', 'id_ID').format(totalHarga)}", 
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1), fontSize: 18)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    child: const Text("Lihat Detail Booking", style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: const BorderSide(color: Color(0xFF0D47A1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    child: const Text("Kembali ke Beranda", style: TextStyle(color: Color(0xFF0D47A1))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowInfo(String label, String value, {bool isMulti = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: isMulti ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}