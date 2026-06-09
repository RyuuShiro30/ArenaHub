import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CourtReviewState {
  final String bookingId;
  final String lapanganId;
  final String namaLapangan;
  final String fotoUrl;
  final int hargaPerJam;

  int ratingOverall = 0;
  int ratingKebersihan = 0;
  int ratingFasilitas = 0;
  int ratingPelayanan = 0;
  int ratingKondisi = 0;
  final komentarController = TextEditingController();
  bool showErrorOverall = false;

  CourtReviewState({
    required this.bookingId,
    required this.lapanganId,
    required this.namaLapangan,
    required this.fotoUrl,
    required this.hargaPerJam,
  });

  void dispose() {
    komentarController.dispose();
  }
}

class ReviewPage extends StatefulWidget {
  final String bookingId;

  const ReviewPage({
    super.key,
    required this.bookingId,
  });

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  static const Color _primaryColor = Color(0xFF135B9D);
  static const Color _starColor = Color(0xFFFFC107);
  static const Color _errorColor = Color(0xFFE53935);

  Map<String, dynamic>? _booking;
  List<CourtReviewState> _courtReviews = [];

  bool _isPageLoading = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchBooking();
  }

  @override
  void dispose() {
    for (var review in _courtReviews) {
      review.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchBooking() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .get();
      if (doc.exists) {
        final bookingData = doc.data()!;
        final int childCount = bookingData['child_count'] ?? 0;

        List<CourtReviewState> tempReviews = [];

        if (childCount > 0) {
          for (int i = 0; i < childCount; i++) {
            final childDocId = '${widget.bookingId}_$i';
            final childDoc = await FirebaseFirestore.instance
                .collection('bookings')
                .doc(childDocId)
                .get();
            if (childDoc.exists) {
              final childData = childDoc.data()!;
              final cLapanganId = childData['lapangan_id'] ?? '';
              String cFoto = childData['image_url'] ?? '';
              int cHarga = 0;

              if (cLapanganId.isNotEmpty) {
                final lapDoc = await FirebaseFirestore.instance
                    .collection('lapangan')
                    .doc(cLapanganId)
                    .get();
                if (lapDoc.exists) {
                  final fotoList = lapDoc.data()?['foto'];
                  cFoto = (fotoList is List && fotoList.isNotEmpty)
                      ? fotoList[0].toString()
                      : cFoto;
                  cHarga = (lapDoc.data()?['harga'] as num?)?.toInt() ?? 0;
                }
              }

              tempReviews.add(CourtReviewState(
                bookingId: childDocId,
                lapanganId: cLapanganId,
                namaLapangan: childData['nama_lapangan'] ?? 'Lapangan',
                fotoUrl: cFoto,
                hargaPerJam: cHarga,
              ));
            }
          }
        } else {
          final lapanganId = bookingData['lapangan_id'] ?? '';
          String foto = bookingData['image_url'] ?? '';
          int harga = 0;

          if (lapanganId.isNotEmpty) {
            final lapanganDoc = await FirebaseFirestore.instance
                .collection('lapangan')
                .doc(lapanganId)
                .get();
            if (lapanganDoc.exists) {
              final fotoList = lapanganDoc.data()?['foto'];
              foto = (fotoList is List && fotoList.isNotEmpty)
                  ? fotoList[0].toString()
                  : foto;
              harga = (lapanganDoc.data()?['harga'] as num?)?.toInt() ?? 0;
            }
          }

          tempReviews.add(CourtReviewState(
            bookingId: widget.bookingId,
            lapanganId: lapanganId,
            namaLapangan: bookingData['nama_lapangan'] ?? 'Lapangan',
            fotoUrl: foto,
            hargaPerJam: harga,
          ));
        }

        setState(() {
          _booking = bookingData;
          _courtReviews = tempReviews;
          _isPageLoading = false;
        });
      } else {
        setState(() => _isPageLoading = false);
      }
    } catch (e) {
      setState(() => _isPageLoading = false);
    }
  }

  String _formatRupiah(int nominal) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'IDR ',
      decimalDigits: 0,
    ).format(nominal);
  }

  Future<void> _kirimUlasan() async {
    // Validasi rating overall wajib diisi untuk semua lapangan
    bool hasError = false;
    for (var review in _courtReviews) {
      if (review.ratingOverall == 0) {
        setState(() => review.showErrorOverall = true);
        hasError = true;
      }
    }
    if (hasError) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }
      final firestore = FirebaseFirestore.instance;

      for (var review in _courtReviews) {
        final lapanganId = review.lapanganId;

        // 1. Simpan ulasan ke collection 'ulasan'
        await firestore.collection('ulasan').add({
          'booking_id': review.bookingId,
          'parent_booking_id': widget.bookingId,
          'lapangan_id': lapanganId,
          'user_id': user.uid,
          'rating_overall': review.ratingOverall,
          'rating_kebersihan': review.ratingKebersihan,
          'rating_fasilitas': review.ratingFasilitas,
          'rating_pelayanan': review.ratingPelayanan,
          'rating_kondisi': review.ratingKondisi,
          'komentar': review.komentarController.text.trim(),
          'fullName': user.displayName ?? '',
          'created_at': FieldValue.serverTimestamp(),
        });

        // 2. Ambil semua ulasan lapangan ini untuk hitung ulang rating_rata
        final ulasanSnapshot = await firestore
            .collection('ulasan')
            .where('lapangan_id', isEqualTo: lapanganId)
            .get();

        final docs = ulasanSnapshot.docs;

        double rata(String field) {
          final list = docs
              .map((d) => (d.data()[field] as num?)?.toDouble() ?? 0)
              .where((v) => v > 0)
              .toList();
          return list.isEmpty ? 0.0 : list.reduce((a, b) => a + b) / list.length;
        }

        final ratingBaru = rata('rating_overall');
        final ratingKebersihan = rata('rating_kebersihan');
        final ratingFasilitas = rata('rating_fasilitas');
        final ratingPelayanan = rata('rating_pelayanan');
        final ratingKondisi = rata('rating_kondisi');

        // 3. Update rating_rata dan jumlah_ulasan di collection 'lapangan'
        await firestore
            .collection('lapangan')
            .doc(lapanganId)
            .update({
          'rating_overall': double.parse(ratingBaru.toStringAsFixed(1)),
          'jumlah_ulasan': docs.length,
          'rating_kebersihan': double.parse(ratingKebersihan.toStringAsFixed(1)),
          'rating_fasilitas': double.parse(ratingFasilitas.toStringAsFixed(1)),
          'rating_pelayanan': double.parse(ratingPelayanan.toStringAsFixed(1)),
          'rating_kondisi': double.parse(ratingKondisi.toStringAsFixed(1)),
        });

        // 4. Update status child booking jadi sudah direview jika ada
        if (review.bookingId != widget.bookingId) {
          await firestore
              .collection('bookings')
              .doc(review.bookingId)
              .update({'sudah_review': true});
        }
      }

      // 5. Update status parent booking jadi sudah direview
      await firestore
          .collection('bookings')
          .doc(widget.bookingId)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _isPageLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final reviewState = _courtReviews[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_courtReviews.length > 1)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                              child: Text(
                                'LAPANGAN #${index + 1}: ${reviewState.namaLapangan.toUpperCase()}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: _primaryColor,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          _buildKartuLapangan(reviewState),
                          _buildRatingOverall(reviewState),
                          _buildRatingKategori(reviewState),
                          _buildKomentar(reviewState),
                          const SizedBox(height: 16),
                          if (index < _courtReviews.length - 1)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Divider(thickness: 2, color: Color(0xFFE0E0E0)),
                            ),
                        ],
                      );
                    },
                    childCount: _courtReviews.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
      bottomNavigationBar: _isPageLoading ? null : _buildTombolKirim(),
    );
  }

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

  Widget _buildKartuLapangan(CourtReviewState state) {
    final imagePath = state.fotoUrl;
    final namaLapangan = state.namaLapangan;
    final hargaPerJam = state.hargaPerJam;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
            child: imagePath.isNotEmpty && imagePath.startsWith('http')
                ? Image.network(
                    imagePath,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderKecil(),
                  )
                  : _placeholderKecil(),
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
                  namaLapangan,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatRupiah(hargaPerJam)}/jam',
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

  Widget _buildRatingOverall(CourtReviewState state) {
    String labelOverall(int rating) {
      switch (rating) {
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

    Color warnaLabelOverall(int rating) {
      if (rating == 0) return const Color(0xFF888888);
      if (rating <= 2) return _errorColor;
      if (rating == 3) return const Color(0xFFFF9800);
      return _primaryColor;
    }

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
                  state.ratingOverall = index;
                  state.showErrorOverall = false;
                }),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    index <= state.ratingOverall
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: index <= state.ratingOverall
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
            labelOverall(state.ratingOverall),
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: warnaLabelOverall(state.ratingOverall),
            ),
          ),
          if (state.showErrorOverall) ...[
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

  Widget _buildRatingKategori(CourtReviewState state) {
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
            nilai: state.ratingKebersihan,
            onChanged: (v) => setState(() => state.ratingKebersihan = v),
          ),
          const _Divider(),
          _BariKategori(
            label: 'Fasilitas',
            nilai: state.ratingFasilitas,
            onChanged: (v) => setState(() => state.ratingFasilitas = v),
          ),
          const _Divider(),
          _BariKategori(
            label: 'Pelayanan',
            nilai: state.ratingPelayanan,
            onChanged: (v) => setState(() => state.ratingPelayanan = v),
          ),
          const _Divider(),
          _BariKategori(
            label: 'Kondisi Lapangan',
            nilai: state.ratingKondisi,
            onChanged: (v) => setState(() => state.ratingKondisi = v),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildKomentar(CourtReviewState state) {
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
              controller: state.komentarController,
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
