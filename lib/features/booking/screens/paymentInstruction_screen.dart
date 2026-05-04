import 'package:flutter/material.dart';

class PaymentInstructionScreen extends StatelessWidget {
  const PaymentInstructionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Warna background abu-abu terang
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF104A7F)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Instruksi Pembayaran',
          style: TextStyle(
            color: Color(0xFF104A7F),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.access_time, color: Colors.red, size: 16),
                  SizedBox(width: 4),
                  Text(
                    '29:59',
                    style: TextStyle(
                      color: Colors.red,
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
            _buildTotalPaymentCard(),
            const SizedBox(height: 20),
            _buildQRCard(),
            const SizedBox(height: 24),
            _buildInstructionSteps(),
            const SizedBox(height: 100), // Spasi ekstra untuk bottom button
          ],
        ),
      ),
      bottomSheet: _buildBottomButton(),
    );
  }

  Widget _buildTotalPaymentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF104A7F), // Biru gelap
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'TOTAL PEMBAYARAN',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Rp 150.000',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  'Berakhir dalam 14:59',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Ganti dengan logo aplikasi kamu (misal: ARENAHUB)
              Container(
                width: 40,
                height: 20,
                color: Colors.grey[800], 
                child: const Center(child: Text("LOGO", style: TextStyle(color: Colors.white, fontSize: 8))),
              ),
              const Text(
                'ARENAHUB ID: 882910',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Area Mockup HP & QR Code
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E), // Warna layar HP mockup
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!, width: 4),
            ),
            child: const Center(
              // Ganti dengan Asset Gambar QR Code yang sebenarnya
              child: Icon(Icons.qr_code_2, size: 120, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Pindai kode QR di atas menggunakan aplikasi\nmobile banking atau e-wallet pilihan Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionSteps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF104A7F)),
            SizedBox(width: 8),
            Text(
              'Langkah Pembayaran',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF104A7F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildStep(1, 'Buka aplikasi pembayaran pilihan Anda\n(Gopay, OVO, Dana, atau Mobile\nBanking).'),
        _buildStep(2, 'Pilih menu Scan / Bayar dan arahkan\nkamera ke kode QR di atas.', highlight: 'Scan / Bayar'),
        _buildStep(3, 'Masukkan jumlah pembayaran yang\nsesuai yaitu Rp 150.000.', highlight: 'Rp 150.000'),
        _buildStep(4, 'Selesaikan transaksi dan simpan bukti\npembayaran Anda.'),
      ],
    );
  }

  Widget _buildStep(int number, String text, {String? highlight}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFF98E2C6), // Hijau pastel
            child: Text(
              number.toString(),
              style: const TextStyle(
                color: Color(0xFF104A7F),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: highlight == null
                ? Text(
                    text,
                    style: const TextStyle(color: Colors.black87, height: 1.4),
                  )
                // Memisahkan teks biasa dan teks yang di-highlight (Bold/Biru)
                : _buildHighlightedText(text, highlight),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedText(String fullText, String highlight) {
    List<String> parts = fullText.split(highlight);
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black87, height: 1.4, fontSize: 14),
        children: [
          TextSpan(text: parts[0]),
          TextSpan(
            text: highlight,
            style: const TextStyle(
              color: Color(0xFF104A7F),
              fontWeight: FontWeight.bold,
            ),
          ),
          if (parts.length > 1) TextSpan(text: parts[1]),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          // Aksi ketika tombol diklik
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF104A7F),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Saya Sudah Bayar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}