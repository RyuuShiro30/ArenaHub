import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentSuccessPage extends StatefulWidget {
  const PaymentSuccessPage({super.key});

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  late Future<DocumentSnapshot> _bookingFuture;
  String orderId = '';
  String selectedJamMain = ''; // Variabel untuk menampung jam yang dipilih
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      // Mengambil argumen dalam bentuk Map agar bisa menampung orderId dan jamMain
      final dynamic args = ModalRoute.of(context)?.settings.arguments;
      
      if (args is Map<String, dynamic>) {
        orderId = args['orderId'] ?? '';
        selectedJamMain = args['jamMain'] ?? '';
      } else if (args is String) {
        orderId = args;
      }

      if (orderId.isNotEmpty) {
        _bookingFuture = _processPaymentAndFetchData(orderId, selectedJamMain);
      }
      _isInit = true;
    }
  }

  // Fungsi diperbarui untuk menerima jamMain, mengecek duplikasi, dan menyimpannya ke Firebase
  Future<DocumentSnapshot> _processPaymentAndFetchData(String id, String jamMainInput) async {
    final docRef = FirebaseFirestore.instance.collection('bookings').doc(id);
    
    final snapshot = await docRef.get();
    if (snapshot.exists) {
      final bookingData = snapshot.data() as Map<String, dynamic>;
      
      // Mencegah proses ulang jika status sudah final (sukses/gagal)
      String currentStatus = bookingData['status_pembayaran'] ?? '';
      if (currentStatus == 'pembayaran selesai' || currentStatus == 'gagal') {
        return snapshot;
      }

      String namaLapangan = bookingData['nama_lapangan'] ?? '';
      String tanggalMain = bookingData['tanggal_main'] ?? '';
      // Jika jamMainInput kosong, coba ambil dari data yang sudah ada (fallback)
      String jamMain = jamMainInput.isNotEmpty ? jamMainInput : (bookingData['jam_main'] ?? '');

      // LOGIKA CEK DUPLIKASI
      final duplicateQuery = await FirebaseFirestore.instance
          .collection('bookings')
          .where('nama_lapangan', isEqualTo: namaLapangan)
          .where('tanggal_main', isEqualTo: tanggalMain)
          .where('jam_main', isEqualTo: jamMain)
          .where('status_pembayaran', isEqualTo: 'pembayaran selesai')
          .get();

      // Mengecek apakah ada dokumen lain dengan jadwal sama yang sudah lunas
      bool isDuplicate = duplicateQuery.docs.any((doc) => doc.id != id);
      String newStatus = isDuplicate ? "gagal" : "pembayaran selesai";
      
      // Update Firebase: Menyertakan field jam_main dan status terbaru
      await docRef.update({
        'status_pembayaran': newStatus,
        'jam_main': jamMain, 
      });

      // Kembalikan data terbaru setelah update agar UI merefleksikan status yang benar
      return await docRef.get();
    }
    
    return snapshot;
  }

  @override
  Widget build(BuildContext context) {
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
      body: orderId.isEmpty
          ? _buildErrorState(context, "ID Pesanan tidak valid")
          : FutureBuilder<DocumentSnapshot>(
              future: _bookingFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return _buildErrorState(context, "Data pembayaran tidak ditemukan");
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;

                final String bookingId = data['order_id'] ?? orderId;
                final String namaLapangan = data['nama_lapangan'] ?? 'Lapangan';
                final int totalHarga = data['total_harga'] ?? 0;
                final String statusPembayaranDb = data['status_pembayaran'] ?? 'pending';
                final String jamMainDisplay = data['jam_main'] ?? '-';

                DateTime jadwalDate = DateTime.now();
                if (data['tanggal_booking'] != null) {
                  jadwalDate = (data['tanggal_booking'] as Timestamp).toDate();
                }

                String formattedDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(jadwalDate);

                return _buildSuccessUI(
                  context,
                  bookingId: bookingId,
                  namaLapangan: namaLapangan,
                  formattedDate: formattedDate,
                  jamMain: jamMainDisplay,
                  totalHarga: totalHarga,
                  statusPembayaran: statusPembayaranDb,
                );
              },
            ),
    );
  }

  Widget _buildSuccessUI(
    BuildContext context, {
    required String bookingId,
    required String namaLapangan,
    required String formattedDate,
    required String jamMain,
    required int totalHarga,
    required String statusPembayaran,
  }) {
    bool isSuccess = statusPembayaran == "pembayaran selesai";
    
    String labelStatusBadge = isSuccess ? "LUNAS" : "GAGAL";
    Color colorStatusText = isSuccess ? Colors.blue : Colors.red;
    Color colorStatusBg = isSuccess ? Colors.blue.shade50 : Colors.red.shade50;
    
    String headerTitle = isSuccess ? "Pembayaran Berhasil!" : "Pembayaran Gagal";
    String headerSubtitle = isSuccess 
        ? "Booking lapangan kamu sudah dikonfirmasi" 
        : "Maaf, pembayaran untuk booking ini gagal diproses karena jadwal sudah terisi";
    IconData headerIcon = isSuccess ? Icons.check_circle : Icons.cancel;
    Color headerIconColor = isSuccess ? const Color(0xFF2D958E) : Colors.red;
    Color headerBgColor = isSuccess ? const Color(0xFFF0F9F8) : Colors.red.shade50;

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: headerBgColor, // Background dinamis menyesuaikan status
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Column(
              children: [
                Icon(headerIcon, size: 80, color: headerIconColor),
                const SizedBox(height: 16),
                Text(
                  headerTitle,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Text(
                    headerSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
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
                              color: colorStatusBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              labelStatusBadge,
                              style: TextStyle(fontSize: 10, color: colorStatusText, fontWeight: FontWeight.bold),
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
                      _rowInfo("Jadwal", formattedDate, isMulti: true),
                      _rowInfo("Jam Main", jamMain), 
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
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
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

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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