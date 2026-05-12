import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/model/booking_model.dart';
import '../screens/payment_screen.dart';

/// Data tambahan dari form booking yang diteruskan ke halaman ini
class KonfirmasiData {
  final String lapanganId;
  final String namaLapangan;
  final String imagePath;
  final DateTime tanggal;
  final List<String> selectedTimes;
  final int hargaPerJam;
  final int biayaLayanan;
  final String namaPemesan;
  final String nomorTelepon;
  final String? catatan;
  final PromoData? promo;

  const KonfirmasiData({
    required this.lapanganId,
    required this.namaLapangan,
    required this.imagePath,
    required this.tanggal,
    required this.selectedTimes,
    required this.hargaPerJam,
    required this.biayaLayanan,
    required this.namaPemesan,
    required this.nomorTelepon,
    this.catatan,
    this.promo,
  });

  int get durasiJam => selectedTimes.length;

  String get tanggalDisplay {
    const bulan = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return '${tanggal.day} ${bulan[tanggal.month]} ${tanggal.year}';
  }

  String get waktuDisplay {
    if (selectedTimes.isEmpty) return '-';

    final jamMulai = selectedTimes.first.split(' - ').first;
    final jamSelesai = selectedTimes.last.split(' - ').last;

    return '$jamMulai s/d $jamSelesai ($durasiJam Jam)';
  }
}

class KonfirmasiBookingPage extends StatefulWidget {
  final KonfirmasiData data;

  const KonfirmasiBookingPage({super.key, required this.data});

  @override
  State<KonfirmasiBookingPage> createState() => _KonfirmasiBookingPageState();
}

class _KonfirmasiBookingPageState extends State<KonfirmasiBookingPage> {
  static const Color _primaryColor = Color(0xFF135B9D);
  static const Color _successColor = Color(0xFF4CAF50);
  static const Color _errorColor = Color(0xFFE53935);

  bool _setujuSyarat = false;

  // kalkulasi harga
  int get _hargaLapangan => widget.data.hargaPerJam * widget.data.durasiJam;
  int get _diskon => widget.data.promo?.diskon ?? 0;
  int get _total => _hargaLapangan + widget.data.biayaLayanan - _diskon;

  String _formatRupiah(int nominal) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'IDR ',
      decimalDigits: 0,
    ).format(nominal);
  }

  // pop up syarat dan ketentuan

  void _tampilkanSyarat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Syarat & Ketentuan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Divider(height: 24),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: const [
                    _SeksiSyarat(
                      judul: 'Syarat Pemesanan',
                      isi:
                          'Pengguna wajib memastikan data yang dimasukkan sudah benar sebelum melanjutkan ke pembayaran. Booking dianggap sah setelah pembayaran berhasil dikonfirmasi.',
                    ),
                    _SeksiSyarat(
                      judul: 'Keterlambatan',
                      isi:
                          'ArenaHub tidak bertanggung jawab atas keterlambatan pengguna. Waktu bermain tetap dihitung sesuai jadwal yang dipesan.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: const Text('Mengerti',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Form(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: _buildRingkasanBooking()),
            SliverToBoxAdapter(child: _buildRincianPembayaran()),
            SliverToBoxAdapter(child: _buildCheckboxSyarat()),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      bottomNavigationBar: _buildTombolLanjut(),
    );
  }

  // app bar

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: _primaryColor, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Konfirmasi Booking',
        style: TextStyle(
          color: _primaryColor,
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
      centerTitle: false,
    );
  }

  // ringkasan booking

  Widget _buildRingkasanBooking() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calendar_month_rounded,
                      color: _primaryColor, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Ringkasan Booking',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),

          // Foto lapangan
          ClipRRect(
            child: widget.data.imagePath.startsWith('http')
                ? Image.network(widget.data.imagePath,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _PlaceholderGambar())
                : Image.asset(widget.data.imagePath,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _PlaceholderGambar()),
          ),

          // Info lapangan
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.data.namaLapangan,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                const SizedBox(height: 14),

                // Grid info: tanggal & pemesan
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TANGGAL & WAKTU',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF888888),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3)),
                          const SizedBox(height: 4),
                          Text(widget.data.tanggalDisplay,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A2E))),
                          Text(widget.data.waktuDisplay,
                              style: const TextStyle(
                                  fontSize: 13, color: Color(0xFF666666))),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('PEMESAN',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF888888),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3)),
                          const SizedBox(height: 4),
                          Text(widget.data.namaPemesan,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A2E))),
                          Text(widget.data.nomorTelepon,
                              style: const TextStyle(
                                  fontSize: 13, color: Color(0xFF666666))),
                        ],
                      ),
                    ),
                  ],
                ),

                // Catatan (hanya tampil kalau ada isinya)
                if (widget.data.catatan != null &&
                    widget.data.catatan!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 12),
                  const Text('CATATAN',
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF888888),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3)),
                  const SizedBox(height: 4),
                  Text(
                    widget.data.catatan!,
                    style: const TextStyle(
                        fontSize: 13.5, color: Color(0xFF444444)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // rincian pembayaran

  Widget _buildRincianPembayaran() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: _primaryColor, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Rincian Pembayaran',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _BarisPricing(
                  label: 'Harga Lapangan (${widget.data.durasiJam} Jam)',
                  nilai: _formatRupiah(_hargaLapangan),
                ),
                const SizedBox(height: 8),
                _BarisPricing(
                  label: 'Biaya Layanan',
                  nilai: _formatRupiah(widget.data.biayaLayanan),
                ),
                if (_diskon > 0) ...[
                  const SizedBox(height: 8),
                  _BarisPricing(
                    label: 'Promo "${widget.data.promo!.kode}"',
                    nilai: '- ${_formatRupiah(_diskon)}',
                    warnaNilai: _successColor,
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: Color(0xFFDDDDDD)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Pembayaran',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    Text(
                      _formatRupiah(_total),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // checkbox syarat

  Widget _buildCheckboxSyarat() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(
            value: _setujuSyarat,
            onChanged: (v) => setState(() => _setujuSyarat = v ?? false),
            activeColor: _primaryColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _setujuSyarat = !_setujuSyarat),
              child: RichText(
                text: TextSpan(
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF444444)),
                  children: [
                    const TextSpan(text: 'Saya menyetujui '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: _tampilkanSyarat,
                        child: const Text(
                          'Syarat & Ketentuan',
                          style: TextStyle(
                            fontSize: 13,
                            color: _primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const TextSpan(text: ' yang berlaku di ArenaHub.'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // tombol lanjut

  Widget _buildTombolLanjut() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          // Tombol aktif hanya kalau checkbox dicentang
        onPressed: _setujuSyarat
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentScreen(
                      totalHarga: _total,
                      namaLapangan: widget.data.namaLapangan,
                      lapanganId: widget.data.lapanganId,
                      imagePath: widget.data.imagePath,
                      customerName: widget.data.namaPemesan,
                      email: FirebaseAuth.instance.currentUser?.email ?? '',
                      phone: widget.data.nomorTelepon,
                      selectedDate: widget.data.tanggal
                          .toIso8601String()
                          .split('T')
                          .first,
                      kodePromo: widget.data.promo?.kode,
                      durasiJam: widget.data.durasiJam,

                      // ===== TAMBAHAN BARU =====
                      jamMain: widget.data.selectedTimes.join(', '),
                      // =========================

                      subtotal: _hargaLapangan,
                      diskon: _diskon,
                    ),
                  ),
                );
              }
            : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFBBCCDD),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Lanjutkan ke Pembayaran',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// widget pembantu

class _BarisPricing extends StatelessWidget {
  final String label;
  final String nilai;
  final Color? warnaNilai;

  const _BarisPricing({
    required this.label,
    required this.nilai,
    this.warnaNilai,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF666666))),
        Text(
          nilai,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: warnaNilai ?? const Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }
}

class _PlaceholderGambar extends StatelessWidget {
  const _PlaceholderGambar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      color: const Color(0xFFE3EAF5),
      child: const Center(
        child: Icon(Icons.sports_soccer_rounded,
            size: 48, color: Color(0xFF1B4E82)),
      ),
    );
  }
}

class _SeksiSyarat extends StatelessWidget {
  final String judul;
  final String isi;

  const _SeksiSyarat({required this.judul, required this.isi});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(judul,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 4),
          Text(isi,
              style: const TextStyle(
                  fontSize: 13.5, color: Color(0xFF555555), height: 1.5)),
        ],
      ),
    );
  }
}