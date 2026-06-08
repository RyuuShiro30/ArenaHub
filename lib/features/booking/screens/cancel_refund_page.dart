import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CancelRefundPage extends StatefulWidget {
  final String bookingId;
  const CancelRefundPage({super.key, required this.bookingId});

  @override
  State<CancelRefundPage> createState() => _CancelRefundPageState();
}

class _CancelRefundPageState extends State<CancelRefundPage> {
  static const Color _primaryColor = Color(0xFF135B9D);
  static const Color _errorColor = Color(0xFFE53935);
  static const Color _warningColor = Color(0xFFFF9800);
  static const Color _bgColor = Color(0xFFF5F7FA);

  Map<String, dynamic>? _booking;
  bool _isLoading = true;
  bool _isSubmitting = false;

  String? _alasanPilihan;
  final _alasanLainController = TextEditingController();
  final _noRekeningController = TextEditingController();
  final _namaBankController = TextEditingController();
  final _namaRekeningController = TextEditingController();
  bool _setujuKetentuan = false;

  final List<String> _pilihanAlasan = [
    'Jadwal berubah / tidak bisa hadir',
    'Salah pilih jadwal / lapangan',
    'Ada keperluan mendadak',
    'Lapangan tidak sesuai ekspektasi',
    'Alasan lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _fetchBooking();
  }

  @override
  void dispose() {
    _alasanLainController.dispose();
    _noRekeningController.dispose();
    _namaBankController.dispose();
    _namaRekeningController.dispose();
    super.dispose();
  }

  Future<void> _fetchBooking() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        final lapanganId = data['lapangan_id'] ?? '';
        if (lapanganId.isNotEmpty) {
          final lapDoc = await FirebaseFirestore.instance
              .collection('lapangan')
              .doc(lapanganId)
              .get();
          if (lapDoc.exists) {
            final fotoList = lapDoc.data()?['foto'];
            data['foto'] = (fotoList is List && fotoList.isNotEmpty)
                ? fotoList[0].toString()
                : '';
          }
        }
        setState(() {
          _booking = data;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  String _formatRupiah(dynamic nominal) {
    final int amount =
        nominal is int ? nominal : int.tryParse(nominal.toString()) ?? 0;
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'IDR ', decimalDigits: 0)
        .format(amount);
  }

  String _formatTanggal(String? s) {
    if (s == null) return '-';
    final dt = DateTime.tryParse(s);
    if (dt == null) return s;
    return DateFormat('d MMMM yyyy', 'id_ID').format(dt);
  }

  bool get _formValid =>
      _alasanPilihan != null &&
      (_alasanPilihan != 'Alasan lainnya' ||
          _alasanLainController.text.trim().isNotEmpty) &&
      _noRekeningController.text.trim().isNotEmpty &&
      _namaBankController.text.trim().isNotEmpty &&
      _namaRekeningController.text.trim().isNotEmpty &&
      _setujuKetentuan;

  // ── Submit cancel + refund ────────────────────────────────────
  Future<void> _submit() async {
    if (!_formValid) {
      _snack('Lengkapi semua data terlebih dahulu', isError: true);
      return;
    }
    final confirm = await _showKonfirmasiDialog();
    if (confirm != true) return;

    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final alasan = _alasanPilihan == 'Alasan lainnya'
          ? _alasanLainController.text.trim()
          : _alasanPilihan!;

      final batch = FirebaseFirestore.instance.batch();

      // 1. Update status booking → dibatalkan
      final bookingRef = FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId);
      batch.update(bookingRef, {
        'status': 'dibatalkan',
        'status_pembayaran': 'dibatalkan',
        'dibatalkan': true,
        'dibatalkan_at': FieldValue.serverTimestamp(),
        'alasan_cancel': alasan,
      });

      // 2. Simpan permohonan refund
      final refundRef =
          FirebaseFirestore.instance.collection('refund_requests').doc();
      batch.set(refundRef, {
        'booking_id': widget.bookingId,
        'order_id': _booking?['order_id'] ?? '',
        'user_id': user?.uid ?? '',
        'user_email': user?.email ?? '',
        'nama_lapangan': _booking?['nama_lapangan'] ?? '',
        'tanggal_main': _booking?['tanggal_main'] ?? '',
        'total_harga': _booking?['total_harga'] ?? 0,
        'alasan_cancel': alasan,
        'no_rekening': _noRekeningController.text.trim(),
        'nama_bank': _namaBankController.text.trim(),
        'nama_rekening': _namaRekeningController.text.trim(),
        'status_refund': 'menunggu',
        'created_at': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // 3. Kembalikan slot jadwal → tersedia
      await _restoreSlotJadwal();

      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSuksesDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _snack('Gagal mengajukan pembatalan: $e', isError: true);
      }
    }
  }

  // ── Restore slot jadwal ke 'tersedia' ─────────────────────────
  Future<void> _restoreSlotJadwal() async {
    try {
      final lapanganId = (_booking?['lapangan_id'] ?? '').toString();
      final tanggalMainStr = (_booking?['tanggal_main'] ?? '').toString();
      final jamMain =
          (_booking?['jam_main'] ?? _booking?['selected_times'] ?? '')
              .toString();

      // Restore collection jadwal → status: 'tersedia'
      if (lapanganId.isNotEmpty &&
          tanggalMainStr.isNotEmpty &&
          jamMain.isNotEmpty) {
        await _restoreJadwalCollection(lapanganId, tanggalMainStr, jamMain);
      }

      // Handle child bookings jika ada (multi-lapangan)
      final childCount = (_booking?['child_count'] ?? 0) as int;
      if (childCount <= 0) return;

      final restoreBatch = FirebaseFirestore.instance.batch();
      for (int i = 0; i < childCount; i++) {
        final childRef = FirebaseFirestore.instance
            .collection('bookings')
            .doc('${widget.bookingId}_$i');
        restoreBatch.update(childRef, {
          'status': 'dibatalkan',
          'status_pembayaran': 'dibatalkan',
          'dibatalkan': true,
          'dibatalkan_at': FieldValue.serverTimestamp(),
        });
      }
      await restoreBatch.commit();
    } catch (e) {
      debugPrint('_restoreSlotJadwal error: $e');
    }
  }

  // ── Query jadwal collection dan set slot yang dibatalkan → 'tersedia' ──
  Future<void> _restoreJadwalCollection(
      String lapanganId, String tanggalMainStr, String jamMain) async {
    try {
      final tanggal = DateTime.tryParse(tanggalMainStr);
      if (tanggal == null) return;

      final startOfDay =
          DateTime(tanggal.year, tanggal.month, tanggal.day, 0, 0, 0);
      final endOfDay =
          DateTime(tanggal.year, tanggal.month, tanggal.day, 23, 59, 59);

      // Parse slots — pisah koma, normalize titik → titik dua
      final rawSlots = jamMain
          .split(',')
          .map((s) => s.trim().replaceAll('.', ':'))
          .where((s) => s.isNotEmpty)
          .toSet();

      if (rawSlots.isEmpty) return;

      // Query jadwal: lapangan_id + tanggal range
      final snap = await FirebaseFirestore.instance
          .collection('jadwal')
          .where('lapangan_id', isEqualTo: lapanganId)
          .where('tanggal',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('tanggal', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      if (snap.docs.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      int updateCount = 0;

      for (final doc in snap.docs) {
        final data = doc.data();
        final waktuOp = (data['waktu_operasional'] as String? ?? '')
            .trim()
            .replaceAll('.', ':');

        // Hanya restore slot yang statusnya 'dipesan' (jangan ubah 'tidak_tersedia')
        if (rawSlots.contains(waktuOp) && data['status'] == 'dipesan') {
          batch.update(doc.reference, {'status': 'tersedia'});
          updateCount++;
        }
      }

      if (updateCount > 0) await batch.commit();
    } catch (e) {
      debugPrint('_restoreJadwalCollection error: $e');
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? _errorColor : _primaryColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<bool?> _showKonfirmasiDialog() => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Icon(Icons.warning_amber_rounded,
                color: Color(0xFFFF9800), size: 24),
            SizedBox(width: 8),
            Text('Konfirmasi Pembatalan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          content: const Text(
            'Booking akan dibatalkan dan permohonan pengembalian dana akan dikirim ke admin untuk diproses.\n\nProses refund membutuhkan 3-7 hari kerja.',
            style: TextStyle(fontSize: 13.5, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Kembali',
                  style: TextStyle(color: Color(0xFF9E9E9E))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _errorColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Ya, Batalkan'),
            ),
          ],
        ),
      );

  void _showSuksesDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF2E7D32), size: 48),
            ),
            const SizedBox(height: 16),
            const Text('Pembatalan Berhasil!',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            const Text(
              'Permohonan pengembalian dana kamu sudah diterima dan akan diproses admin dalam 3-7 hari kerja.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Color(0xFF666666), height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/home', (r) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: const Text('Kembali ke Beranda',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          backgroundColor: _bgColor,
          body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: _bgColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildInfoBooking()),
          SliverToBoxAdapter(child: _buildKetentuanRefund()),
          SliverToBoxAdapter(child: _buildFormAlasan()),
          SliverToBoxAdapter(child: _buildFormRekening()),
          SliverToBoxAdapter(child: _buildCheckbox()),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: _buildTombolSubmit(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0.5,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: _primaryColor, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text('Batalkan Booking',
          style: TextStyle(
              color: _primaryColor, fontWeight: FontWeight.w700, fontSize: 18)),
    );
  }

  Widget _buildInfoBooking() {
    if (_booking == null) return const SizedBox.shrink();
    final foto = _booking!['foto'] ?? '';
    final nama = _booking!['nama_lapangan'] ?? '-';
    final tanggal = _formatTanggal(_booking!['tanggal_main']);
    final jam = (_booking!['selected_times'] ?? _booking!['jam_main'] ?? '-')
        .toString();
    final totalHarga = _booking!['total_harga'] ?? 0;
    final orderId = _booking!['order_id'] ?? '-';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('DETAIL BOOKING',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF888888),
                letterSpacing: 0.5)),
        const SizedBox(height: 12),
        Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: foto.isNotEmpty && foto.startsWith('http')
                ? Image.network(foto,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fotoPlaceholder())
                : _fotoPlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nama,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E))),
              const SizedBox(height: 4),
              Text(tanggal,
                  style: const TextStyle(
                      fontSize: 12.5, color: Color(0xFF666666))),
              Text(jam,
                  style: const TextStyle(
                      fontSize: 12.5, color: Color(0xFF666666))),
              const SizedBox(height: 6),
              Text(_formatRupiah(totalHarga),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _primaryColor)),
            ],
          )),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(8)),
          child: Text('Booking ID: $orderId',
              style: const TextStyle(
                  fontSize: 12,
                  color: _primaryColor,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _fotoPlaceholder() => Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
            color: const Color(0xFFE3EAF5),
            borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.sports_soccer_rounded,
            color: Color(0xFF1B4E82), size: 28),
      );

  Widget _buildKetentuanRefund() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCC02)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.info_outline_rounded, color: _warningColor, size: 18),
          SizedBox(width: 8),
          Text('Ketentuan Pengembalian Dana',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _warningColor)),
        ]),
        const SizedBox(height: 10),
        ...[
          '• Refund diproses dalam 3-7 hari kerja setelah disetujui admin.',
          '• Pembatalan H-1 atau kurang dari 24 jam dikenakan potongan 50%.',
          '• Pastikan data rekening yang kamu masukkan sudah benar.',
          '• Dana dikembalikan ke rekening bank yang kamu daftarkan.',
        ].map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(t,
                  style: const TextStyle(
                      fontSize: 12.5, color: Color(0xFF795548), height: 1.4)),
            )),
      ]),
    );
  }

  Widget _buildFormAlasan() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('ALASAN PEMBATALAN',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF888888),
                letterSpacing: 0.5)),
        const SizedBox(height: 12),
        ..._pilihanAlasan.map((alasan) {
          final isSelected = _alasanPilihan == alasan;
          return GestureDetector(
            onTap: () => setState(() => _alasanPilihan = alasan),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? _primaryColor.withOpacity(0.08)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isSelected ? _primaryColor : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1),
              ),
              child: Row(children: [
                Icon(
                    isSelected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: isSelected ? _primaryColor : const Color(0xFFBBBBBB),
                    size: 20),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(alasan,
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? _primaryColor
                                : const Color(0xFF444444)))),
              ]),
            ),
          );
        }),
        if (_alasanPilihan == 'Alasan lainnya') ...[
          const SizedBox(height: 4),
          TextField(
            controller: _alasanLainController,
            maxLines: 3,
            maxLength: 200,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Jelaskan alasanmu...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
              filled: true,
              fillColor: const Color(0xFFF5F7FA),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: _primaryColor, width: 1.5)),
              counterStyle:
                  const TextStyle(fontSize: 11, color: Color(0xFF888888)),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildFormRekening() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('DATA REKENING REFUND',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF888888),
                letterSpacing: 0.5)),
        const SizedBox(height: 14),
        _inputField(
            controller: _namaBankController,
            label: 'Nama Bank',
            hint: 'Contoh: BCA, Mandiri, BRI, BNI...',
            icon: Icons.account_balance_rounded),
        const SizedBox(height: 12),
        _inputField(
            controller: _noRekeningController,
            label: 'Nomor Rekening',
            hint: 'Masukkan nomor rekening',
            icon: Icons.credit_card_rounded,
            keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        _inputField(
            controller: _namaRekeningController,
            label: 'Nama Pemilik Rekening',
            hint: 'Sesuai nama di buku tabungan',
            icon: Icons.person_outline_rounded),
      ]),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF444444))),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
          prefixIcon: Icon(icon, size: 18, color: const Color(0xFF9E9E9E)),
          filled: true,
          fillColor: const Color(0xFFF5F7FA),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _primaryColor, width: 1.5)),
        ),
      ),
    ]);
  }

  Widget _buildCheckbox() {
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
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Checkbox(
          value: _setujuKetentuan,
          onChanged: (v) => setState(() => _setujuKetentuan = v ?? false),
          activeColor: _primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _setujuKetentuan = !_setujuKetentuan),
            child: const Text(
              'Saya memahami ketentuan pembatalan dan pengembalian dana yang berlaku.',
              style: TextStyle(fontSize: 13, color: Color(0xFF444444)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildTombolSubmit() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -4))
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: (_formValid && !_isSubmitting) ? _submit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _errorColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFCCCCCC),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : const Text('Ajukan Pembatalan & Refund',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
