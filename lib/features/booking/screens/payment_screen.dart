import 'dart:async';
import 'package:flutter/material.dart';
import 'package:appbookinglapangan/data/service/midtrans_service.dart';
import 'package:appbookinglapangan/routes/app_routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentScreen extends StatefulWidget {
  final int totalHarga;
  final String namaLapangan;
  final String customerName;
  final String email;
  final String phone;

  const PaymentScreen({
    super.key,
    required this.totalHarga,
    required this.namaLapangan,
    required this.customerName,
    required this.email,
    required this.phone,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final MidtransService midtransService = MidtransService();
  
  bool isLoading = true;
  String? qrUrl;
  String? currentOrderId;

  Timer? _timer;
  int _remainingSeconds = 15 * 60;
  String _bookingCode = '';

  final Color primaryDarkBlue = const Color(0xFF0F4C81);
  final Color backgroundColor = const Color(0xFFF4F6F9);

  @override
  void initState() {
    super.initState();
    _startTimer();
    _initializeBookingAndPayment();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Integrasi: Menggabungkan inisialisasi ID dan pemanggilan Midtrans
  Future<void> _initializeBookingAndPayment() async {
    await _generateSequentialBookingCode();
    await payNow();
  }

 Future<void> _generateSequentialBookingCode() async {
  try {
    // 1. Ambil tanggal hari ini (Format: YYYYMMDD)
    final now = DateTime.now();
    final dateTag = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";

    // 2. Cari transaksi terakhir KHUSUS hari ini
    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('order_id', isGreaterThanOrEqualTo: 'INV-$dateTag-')
        .where('order_id', isLessThanOrEqualTo: 'INV-$dateTag-\uf8ff')
        .orderBy('order_id', descending: true)
        .limit(1)
    .get();

    if (snapshot.docs.isEmpty) {
      // Jika booking pertama hari ini
      _bookingCode = 'INV-$dateTag-001';
    } else {
      String lastId = snapshot.docs.first.data()['order_id'] ?? '';
      
      // Ambil 3 angka terakhir (setelah strip kedua)
      List<String> parts = lastId.split('-');
      int nextNumber = 1;
      
      if (parts.length >= 3) {
        nextNumber = (int.tryParse(parts[2]) ?? 0) + 1;
      }
      
      _bookingCode = 'INV-$dateTag-${nextNumber.toString().padLeft(3, '0')}';
    }
  } catch (e) {
    // Fallback: Gunakan millisecond agar Midtrans tidak menolak karena ID Duplikat
    _bookingCode = 'INV-${DateTime.now().millisecondsSinceEpoch}';
    print("Error ID: $e");
  }

  if (mounted) setState(() {});
}

// Ini fungsi bantuan untuk simulasi (nanti hubungkan ke backend/provider kamu)
Future<String> _fetchLastOrderId() async {
  // Contoh: jika Rani sudah pernah buat INV-00001, 
  // maka fungsi ini harusnya mengembalikan 'INV-00001'
  return 'INV-00001'; 
}

  Future<String> _fetchLastBookingIdFromDatabase() async {
    // Placeholder untuk integrasi database di masa depan
    return ''; 
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
          });
        }
      } else {
        _timer?.cancel();
      }
    });
  }

  String _getFormattedTimer() {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatRupiah(int amount) {
    String amountStr = amount.toString();
    String result = '';
    int count = 0;
    for (int i = amountStr.length - 1; i >= 0; i--) {
      result = amountStr[i] + result;
      count++;
      if (count % 3 == 0 && i != 0) {
        result = '.$result';
      }
    }
    return 'Rp $result';
  }

  Future<void> payNow() async {
    if (_bookingCode.isEmpty) return;
    
    setState(() => isLoading = true);

    currentOrderId = _bookingCode;

    final qr = await midtransService.createTransaction(
      orderId: currentOrderId!,
      grossAmount: widget.totalHarga,
      customerName: widget.customerName,
      email: widget.email,
      phone: widget.phone,
    );

    if (mounted) {
      setState(() {
        qrUrl = qr;
        isLoading = false;
      });

      if (qr == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal membuat QR. Cek koneksi atau Server Key Midtrans kamu.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> handleConfirmPayment() async {
    if (currentOrderId == null) return;

    setState(() {
      isLoading = true;
    });

    final status = await midtransService.checkStatus(currentOrderId!);

    if (mounted) {
      setState(() {
        isLoading = false;
      });

      if (status == 'settlement' || status == 'pending') { 
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.paymentSucces,
          (route) => false,
          arguments: currentOrderId,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == null
                  ? "Gagal cek status pembayaran"
                  : "Status pembayaran: $status",
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int serviceFee = 5000;
    final int basePrice = widget.totalHarga - serviceFee;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pembayaran',
          style: TextStyle(
            color: primaryDarkBlue,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 12, bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: Colors.red.shade700, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _getFormattedTimer(),
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 140,
                    width: double.infinity,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image, size: 50, color: Colors.grey),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ARENAHUB BOOKING',
                              style: TextStyle(
                                color: primaryDarkBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _bookingCode.isEmpty ? '#...' : '#$_bookingCode',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.namaLapangan,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        const Text(
                          'Total yang harus dibayar',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatRupiah(widget.totalHarga),
                          style: TextStyle(
                            color: primaryDarkBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    color: primaryDarkBlue),
                const SizedBox(width: 8),
                const Text(
                  'Metode Pembayaran',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryDarkBlue, width: 1.5),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.qr_code_scanner,
                              color: primaryDarkBlue),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'QRIS',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Bayar via GoPay, OVO, DANA, dll.',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.check_circle, color: primaryDarkBlue),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Container(
                          height: 220,
                          width: 220,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: isLoading
                                ? Center(
                                    child: CircularProgressIndicator(
                                      color: primaryDarkBlue,
                                    ),
                                  )
                                : qrUrl != null
                                    ? Image.network(
                                        qrUrl!,
                                        fit: BoxFit.contain,
                                        loadingBuilder: (context, child, progress) {
                                          if (progress == null) return child;
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        },
                                        errorBuilder: (context, error, stack) {
                                          return const Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.broken_image, color: Colors.grey),
                                                SizedBox(height: 8),
                                                Text(
                                                  'Gagal memuat QR',
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      )
                                    : Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.error_outline,
                                              size: 60,
                                              color: Colors.red.shade300,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'QR gagal dimuat.\nCek koneksi kamu.',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Scan kode QR di atas menggunakan aplikasi m-banking\natau e-wallet pilihan Anda untuk melakukan pembayaran\ninstan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Ringkasan Pesanan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Harga Lapangan (1 Jam)',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      Text(
                        _formatRupiah(basePrice),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Biaya Layanan',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      Text(
                        _formatRupiah(serviceFee),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Pembayaran',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        _formatRupiah(widget.totalHarga),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: primaryDarkBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              offset: const Offset(0, -2),
              blurRadius: 6,
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, size: 16, color: primaryDarkBlue),
                    const SizedBox(width: 8),
                    Text(
                      'Pembayaran aman & terenkripsi',
                      style: TextStyle(
                        fontSize: 12,
                        color: primaryDarkBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : handleConfirmPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryDarkBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Konfirmasi Pembayaran',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}