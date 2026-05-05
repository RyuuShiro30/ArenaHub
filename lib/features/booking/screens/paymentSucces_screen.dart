import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentSuccessPage extends StatelessWidget {
  const PaymentSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Menangkap Order ID (String) yang dikirim dari PaymentScreen
    final dynamic args = ModalRoute.of(context)?.settings.arguments;
    final String orderId = (args is String) ? args : '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF004080)),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        title: const Text(
          "Status Pembayaran",
          style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      // Mengambil data dari Firestore secara Real-time sebelum menampilkan UI
      body: orderId.isEmpty
          ? _buildErrorState(context, "ID Pesanan tidak valid")
          : FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('bookings').doc(orderId).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return _buildErrorState(context, "Data pembayaran tidak ditemukan");
                }

                // Ambil data dari dokumen Firestore
                final data = snapshot.data!.data() as Map<String, dynamic>;

                // Mapping data Firestore ke variabel UI
                final String bookingId = data['order_id'] ?? orderId;
                final String namaLapangan = data['nama_lapangan'] ?? 'Lapangan';
                final int totalHarga = data['total_harga'] ?? 0;
                
                // Handle Tanggal (Timestamp Firestore ke DateTime)
                DateTime jadwalDate = DateTime.now();
                if (data['tanggal_booking'] != null) {
                  jadwalDate = (data['tanggal_booking'] as Timestamp).toDate();
                }

                // Format Tanggal Indonesia
                String formattedDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(jadwalDate);

                // Kembalikan UI Utama jika data ditemukan
                return _buildSuccessUI(
                  context,
                  bookingId: bookingId,
                  namaLapangan: namaLapangan,
                  formattedDate: formattedDate,
                  totalHarga: totalHarga,
                );
              },
            ),
    );
  }

  // WIDGET: UI UTAMA SAAT DATA BERHASIL DIMUAT
  Widget _buildSuccessUI(
    BuildContext context, {
    required String bookingId,
    required String namaLapangan,
    required String formattedDate,
    required int totalHarga,
  }) {
    return SingleChildScrollView(
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
                const Text(
                  "Pembayaran Berhasil!",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                ),
                const Text(
                  "Booking lapangan kamu sudah dikonfirmasi",
                  style: TextStyle(color: Colors.grey),
                ),
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
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              "LUNAS",
                              style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                      Text(
                        bookingId,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Divider(height: 30),
                      _rowInfo("Nama Lapangan", namaLapangan),
                      _rowInfo("Jadwal", "$formattedDate", isMulti: true),
                      _rowInfo("Metode Pembayaran", "QRIS"),
                      const Divider(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total Pembayaran", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            "IDR ${NumberFormat('#,###', 'id_ID').format(totalHarga)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D47A1),
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    // Logika untuk melihat detail booking
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: const Text("Lihat Detail Booking", style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () {
                    // Fungsi ini akan menghapus semua halaman (Payment, Success, dll) 
                    // dan menjadikan '/dashboard' sebagai halaman utama.
                    Navigator.pushNamedAndRemoveUntil(
                      context, 
                      '/home', // <--- Ganti dengan nama route Dashboard/Beranda kamu
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: const BorderSide(color: Color(0xFF0D47A1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: const Text(
                    "Kembali ke Beranda", 
                    style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET: INFO BARIS
  Widget _rowInfo(String label, String value, {bool isMulti = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: isMulti ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET: TAMPILAN ERROR JIKA DATA TIDAK DITEMUKAN
  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Kembali"),
          ),
        ],
      ),
    );
  }
}