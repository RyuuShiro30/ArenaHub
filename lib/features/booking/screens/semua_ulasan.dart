import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// model

class UlasanLengkap {
  final String namaPengguna;
  final String avatarPath;
  final double ratingOverall;
  final double ratingFasilitas;
  final double ratingKebersihan;
  final double ratingPelayanan;
  final double ratingKondisi;
  final String komentar;
  final DateTime createdAt;

  const UlasanLengkap({
    required this.namaPengguna,
    required this.avatarPath,
    required this.ratingOverall,
    required this.ratingFasilitas,
    required this.ratingKebersihan,
    required this.ratingPelayanan,
    required this.ratingKondisi,
    required this.komentar,
    required this.createdAt,
  });

  factory UlasanLengkap.fromMap(Map<String, dynamic> map) {
    DateTime parsed = DateTime.now();
    final ts = map['created_at'];
    if (ts is Timestamp) parsed = ts.toDate();

    return UlasanLengkap(
      namaPengguna: (map['fullName'] ?? '').toString().trim().isEmpty
          ? 'Pengguna'
          : map['fullName'].toString().trim(),
      avatarPath: map['avatar_path'] ?? '',
      ratingOverall: (map['rating_overall'] ?? 0).toDouble(),
      ratingFasilitas: (map['rating_fasilitas'] ?? 0).toDouble(),
      ratingKebersihan: (map['rating_kebersihan'] ?? 0).toDouble(),
      ratingPelayanan: (map['rating_pelayanan'] ?? 0).toDouble(),
      ratingKondisi: (map['rating_kondisi'] ?? 0).toDouble(),
      komentar: map['komentar'] ?? '',
      createdAt: parsed,
    );
  }

  String get waktuFormatted =>
      DateFormat('d MMM yyyy', 'id_ID').format(createdAt);
}

// page

class SemuaUlasanPage extends StatefulWidget {
  final String lapanganId;
  final String namaLapangan;

  const SemuaUlasanPage({
    super.key,
    required this.lapanganId,
    required this.namaLapangan,
  });

  @override
  State<SemuaUlasanPage> createState() => _SemuaUlasanPageState();
}

class _SemuaUlasanPageState extends State<SemuaUlasanPage> {
  static const Color _primary = Color(0xFF135B9D);
  static const Color _starColor = Color(0xFFFFC107);

  List<UlasanLengkap> _ulasan = [];
  bool _isLoading = true;
  String? _error;

  double _avgOverall = 0;
  double _avgFasilitas = 0;
  double _avgKebersihan = 0;
  double _avgPelayanan = 0;
  double _avgKondisi = 0;

  @override
  void initState() {
    super.initState();
    _fetchUlasan();
  }

  Future<void> _fetchUlasan() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('ulasan')
          .where('lapangan_id', isEqualTo: widget.lapanganId)
          .orderBy('created_at', descending: true)
          .get();

      final list =
          snap.docs.map((d) => UlasanLengkap.fromMap(d.data())).toList();

      if (list.isNotEmpty) {
        final n = list.length;
        _avgOverall =
            list.map((u) => u.ratingOverall).reduce((a, b) => a + b) / n;
        _avgFasilitas =
            list.map((u) => u.ratingFasilitas).reduce((a, b) => a + b) / n;
        _avgKebersihan =
            list.map((u) => u.ratingKebersihan).reduce((a, b) => a + b) / n;
        _avgPelayanan =
            list.map((u) => u.ratingPelayanan).reduce((a, b) => a + b) / n;
        _avgKondisi =
            list.map((u) => u.ratingKondisi).reduce((a, b) => a + b) / n;
      }

      setState(() {
        _ulasan = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat ulasan: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _primary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Ulasan ${widget.namaLapangan}',
          style: const TextStyle(
            color: _primary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() => _isLoading = true);
                _fetchUlasan();
              },
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildRatingSummary(),
        const SizedBox(height: 16),
        if (_ulasan.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'Belum ada ulasan untuk lapangan ini.',
                style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
              ),
            ),
          )
        else
          ..._ulasan.map((u) => _KartuUlasanLengkap(ulasan: u)),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
      ],
    );
  }

  Widget _buildRatingSummary() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _avgOverall.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                  height: 1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  '/ 5',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF888888),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.star_rounded, color: _starColor, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${_ulasan.length} rating • ${_ulasan.length} ulasan',
            style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 16),
          _buildKategoriBar('Fasilitas', _avgFasilitas),
          _buildKategoriBar('Kebersihan', _avgKebersihan),
          _buildKategoriBar('Pelayanan', _avgPelayanan),
          _buildKategoriBar('Kondisi Venue', _avgKondisi),
        ],
      ),
    );
  }

  Widget _buildKategoriBar(String label, double nilai) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF444444),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: nilai / 5.0,
                minHeight: 8,
                backgroundColor: const Color(0xFFE8EDF5),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF135B9D)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 34,
            child: Text(
              nilai.toStringAsFixed(2),
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// kartu ulasan individual

class _KartuUlasanLengkap extends StatelessWidget {
  final UlasanLengkap ulasan;

  const _KartuUlasanLengkap({required this.ulasan});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFDDE3EE),
                backgroundImage: ulasan.avatarPath.isNotEmpty
                    ? (ulasan.avatarPath.startsWith('http')
                        ? NetworkImage(ulasan.avatarPath)
                        : AssetImage(ulasan.avatarPath)) as ImageProvider
                    : null,
                child: ulasan.avatarPath.isEmpty
                    ? Text(
                        ulasan.namaPengguna[0].toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF135B9D),
                          fontSize: 15,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ulasan.namaPengguna,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    Text(
                      ulasan.waktuFormatted,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF888888)),
                    ),
                  ],
                ),
              ),
              // Badge rating
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFE082), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ulasan.ratingOverall.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFFFC107), size: 15),
                  ],
                ),
              ),
            ],
          ),
          if (ulasan.komentar.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              ulasan.komentar,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF444444),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}