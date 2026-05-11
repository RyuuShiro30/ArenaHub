import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Data yang dikirim ke halaman review
class ReviewData {
  final String bookingId;
  final String lapanganId;
  final String namaLapangan;
  final String imagePath;
  final int hargaPerJam;

  const ReviewData({
    required this.bookingId,
    required this.lapanganId,
    required this.namaLapangan,
    required this.imagePath,
    required this.hargaPerJam,
  });
}

class ReviewPage extends StatefulWidget {
  final ReviewData data;

  const ReviewPage({super.key, required this.data});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  static const Color _primaryColor = Color(0xFF135B9D);
  static const Color _starColor = Color(0xFFFFC107);
  static const Color _errorColor = Color(0xFFE53935);

  // Overall rating
  int _ratingOverall = 0;

  // Category ratings
  int _ratingKebersihan = 0;
  int _ratingFasilitas = 0;
  int _ratingPelayanan = 0;
  int _ratingKondisi = 0;

  final _komentarController = TextEditingController();
  bool _isLoading = false;
  bool _showErrorOverall = false;

  @override
  void dispose() {
    _komentarController.dispose();
    super.dispose();
  }

  // label rating overall

  String get _labelOverall {
    switch (_ratingOverall) {
      case 1:
        return 'Sangat Buruk';
      case 2:
        return 'Buruk';
      case 3:
        return 'Cukup';
      case 4:
        return 'Sangat Bagus';
      case 5:
        return 'Luar Biasa!';
      default:
        return 'Ketuk bintang untuk memberi nilai';
    }
  }

  Color get _warnaLabelOverall {
    if (_ratingOverall == 0) return const Color(0xFF888888);
    if (_ratingOverall <= 2) return _errorColor;
    if (_ratingOverall == 3) return const Color(0xFFFF9800);
    return _primaryColor;
  }

  // format rp

  String _formatRupiah(int nominal) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'IDR ',
      decimalDigits: 0,
    ).format(nominal);
  }

  // submit

  Future<void> _kirimUlasan() async {
    // Validasi rating overall wajib diisi
    if (_ratingOverall == 0) {
      setState(() => _showErrorOverall = true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }
      final firestore = FirebaseFirestore.instance;

      // 1. Simpan ulasan ke collection 'ulasan'
      await firestore.collection('ulasan').add({
        'booking_id': widget.data.bookingId,
        'lapangan_id': widget.data.lapanganId,
        'user_id': user.uid,
        'rating_overall': _ratingOverall,
        'rating_kebersihan': _ratingKebersihan,
        'rating_fasilitas': _ratingFasilitas,
        'rating_pelayanan': _ratingPelayanan,
        'rating_kondisi': _ratingKondisi,
        'komentar': _komentarController.text.trim(),
        'fullName': user.displayName ?? '',
        'created_at': FieldValue.serverTimestamp(),
      });
      // 2. Ambil semua ulasan lapangan ini untuk hitung ulang rating_rata
      final ulasanSnapshot = await firestore
          .collection('ulasan')
          .where('lapangan_id', isEqualTo: widget.data.lapanganId)
          .get();

      final semuaRating = ulasanSnapshot.docs
          .map((doc) => (doc.data()['rating_overall'] as num).toDouble())
          .toList();

      final ratingBaru = semuaRating.isEmpty
          ? 0.0
          : semuaRating.reduce((a, b) => a + b) / semuaRating.length;

      // 3. Update rating_rata dan jumlah_ulasan di collection 'lapangan'
      await firestore
          .collection('lapangan')
          .doc(widget.data.lapanganId)
          .update({
        'rating_rata': double.parse(ratingBaru.toStringAsFixed(1)),
        'jumlah_ulasan': semuaRating.length,
      });
      // 4. Update status booking jadi sudah direview
      await firestore
          .collection('bookings')
          .doc(widget.data.bookingId)
          .update({'sudah_review': true});

      setState(() => _isLoading = false);

      if (!mounted) return;
      _tampilkanSukses();
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim ulasan: $e')),
      );
    }
  }

  void _tampilkanSukses() {
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
              decoration: BoxDecoration(
                color: _starColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.star_rounded, color: _starColor, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ulasan Terkirim!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Terima kasih! Ulasanmu membantu pengguna lain memilih lapangan terbaik.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // tutup dialog
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/home', (route) => false);
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

  // build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildKartuLapangan()),
          SliverToBoxAdapter(child: _buildRatingOverall()),
          SliverToBoxAdapter(child: _buildRatingKategori()),
          SliverToBoxAdapter(child: _buildKomentar()),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: _buildTombolKirim(),
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
        'Beri Ulasan',
        style: TextStyle(
          color: _primaryColor,
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
      centerTitle: false,
      titleSpacing: 0,
    );
  }

  // kartu lapangan

  Widget _buildKartuLapangan() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(12),
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
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: widget.data.imagePath.startsWith('http')
                ? Image.network(
                    widget.data.imagePath,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderKecil(),
                  )
                : Image.asset(
                    widget.data.imagePath,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderKecil(),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ArenaHub Booking',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF888888),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.data.namaLapangan,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatRupiah(widget.data.hargaPerJam)}/jam',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderKecil() {
    return Container(
      width: 72,
      height: 72,
      color: const Color(0xFFE3EAF5),
      child: const Icon(Icons.sports_soccer_rounded,
          color: Color(0xFF1B4E82), size: 28),
    );
  }

  // rating overall

  Widget _buildRatingOverall() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(20),
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
        children: [
          const Text(
            'Bagaimana pengalamanmu?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final index = i + 1;
              return GestureDetector(
                onTap: () => setState(() {
                  _ratingOverall = index;
                  _showErrorOverall = false;
                }),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    index <= _ratingOverall
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: index <= _ratingOverall
                        ? _starColor
                        : const Color(0xFFDDDDDD),
                    size: 42,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            _labelOverall,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: _warnaLabelOverall,
            ),
          ),
          if (_showErrorOverall) ...[
            const SizedBox(height: 6),
            const Text(
              'Rating keseluruhan wajib diisi',
              style: TextStyle(fontSize: 12, color: _errorColor),
            ),
          ],
        ],
      ),
    );
  }

  // rating kategori

  Widget _buildRatingKategori() {
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
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              'NILAI ASPEK LAPANGAN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF888888),
                letterSpacing: 0.5,
              ),
            ),
          ),
          _BariKategori(
            label: 'Kebersihan',
            nilai: _ratingKebersihan,
            onChanged: (v) => setState(() => _ratingKebersihan = v),
          ),
          const _Divider(),
          _BariKategori(
            label: 'Fasilitas',
            nilai: _ratingFasilitas,
            onChanged: (v) => setState(() => _ratingFasilitas = v),
          ),
          const _Divider(),
          _BariKategori(
            label: 'Pelayanan',
            nilai: _ratingPelayanan,
            onChanged: (v) => setState(() => _ratingPelayanan = v),
          ),
          const _Divider(),
          _BariKategori(
            label: 'Kondisi Lapangan',
            nilai: _ratingKondisi,
            onChanged: (v) => setState(() => _ratingKondisi = v),
            isLast: true,
          ),
        ],
      ),
    );
  }

  // komentar

  Widget _buildKomentar() {
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
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              'TULISKAN KOMENTARMU',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF888888),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _komentarController,
              maxLines: 5,
              maxLength: 500,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Ceritakan pengalamanmu bermain di sini...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: _primaryColor, width: 1.5),
                ),
                counterStyle:
                    const TextStyle(fontSize: 11, color: Color(0xFF888888)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // tombol kirim

  Widget _buildTombolKirim() {
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
          onPressed: _isLoading ? null : _kirimUlasan,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFBBCCDD),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : const Text(
                  'Kirim Ulasan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );
  }
}

// widget pembantu

class _BariKategori extends StatelessWidget {
  final String label;
  final int nilai;
  final ValueChanged<int> onChanged;
  final bool isLast;

  static const Color _starColor = Color(0xFFFFC107);

  const _BariKategori({
    required this.label,
    required this.nilai,
    required this.onChanged,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, isLast ? 16 : 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A2E),
            ),
          ),
          Row(
            children: List.generate(5, (i) {
              final index = i + 1;
              return GestureDetector(
                onTap: () => onChanged(index),
                child: Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Icon(
                    index <= nilai
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color:
                        index <= nilai ? _starColor : const Color(0xFFDDDDDD),
                    size: 26,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: Color(0xFFF0F0F0)),
    );
  }
}
