import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:appbookinglapangan/features/booking/screens/pilih_jadwal.dart';
import 'package:url_launcher/url_launcher.dart';
import 'semua_ulasan.dart';

// --- Model ---

class FasilitasItem {
  final String nama;
  final String iconName;
  final String iconUrl;

  const FasilitasItem({
    required this.nama,
    required this.iconName,
    required this.iconUrl,
  });

  static String? _extractFromString(String data, String key) {
    try {
      final pattern = RegExp('$key:\\s*([^,}]+)');
      final match = pattern.firstMatch(data);
      if (match != null) {
        return match.group(1)?.trim();
      }
    } catch (_) {}
    return null;
  }

  factory FasilitasItem.fromMap(dynamic data) {
    if (data is String) {
      if (data.contains('{') && data.contains('}')) {
        String? namaExtracted = _extractFromString(data, 'nama');
        String? labelExtracted = _extractFromString(data, 'label');
        final namaFinal = (namaExtracted != null && namaExtracted.isNotEmpty)
            ? namaExtracted
            : (labelExtracted != null && labelExtracted.isNotEmpty)
                ? labelExtracted
                : 'Fasilitas';
        return FasilitasItem(nama: namaFinal, iconName: namaFinal, iconUrl: '');
      }
      final namaFinal = data.trim().isEmpty ? 'Fasilitas' : data.trim();
      return FasilitasItem(nama: namaFinal, iconName: namaFinal, iconUrl: '');
    }

    if (data is Map<String, dynamic>) {
      String namaRaw = (data['nama'] ?? data['label'] ?? '').toString();
      String labelRaw = (data['label'] ?? data['nama'] ?? '').toString();
      String namaFinal = namaRaw;
      if (namaRaw.contains('{') && namaRaw.contains('}')) {
        namaFinal = _extractFromString(namaRaw, 'nama') ??
            _extractFromString(namaRaw, 'label') ??
            'Fasilitas';
      } else if (namaRaw.isEmpty && labelRaw.isNotEmpty) {
        namaFinal = labelRaw;
      }
      return FasilitasItem(
        nama: namaFinal.isEmpty ? 'Fasilitas' : namaFinal,
        iconName: (data['icon_name'] ?? namaFinal).toString(),
        iconUrl: (data['icon_url'] ?? '').toString(),
      );
    }

    return const FasilitasItem(nama: 'Fasilitas', iconName: '', iconUrl: '');
  }
}

class UlasanItem {
  final String namaPengguna;
  final String avatarPath;
  final int rating;
  final String komentar;
  final String waktu;

  const UlasanItem({
    required this.namaPengguna,
    required this.avatarPath,
    required this.rating,
    required this.komentar,
    required this.waktu,
  });

  factory UlasanItem.fromMap(Map<String, dynamic> map) {
    return UlasanItem(
      namaPengguna: map['fullName'] ?? map['nama_pengguna'] ?? 'Pengguna',
      avatarPath: map['avatar_path'] ?? '',
      rating: map['rating_overall'] ?? 0,
      komentar: map['komentar'] ?? '',
      waktu: UlasanItem._hitungWaktu(map['created_at']),
    );
  }

  static String _hitungWaktu(dynamic timestamp) {
    if (timestamp == null) return '';
    final dt = (timestamp as Timestamp).toDate();
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays} hari yang lalu';
    if (diff.inHours > 0) return '${diff.inHours} jam yang lalu';
    return 'Baru saja';
  }
}

class DetailLapanganData {
  final String id;
  final String namaLapangan;
  final String jenisLapangan;
  final String jenisFloor;
  final String lokasi;
  final int hargaPerJam;
  final String deskripsi;
  final double ratingRata;
  final int jumlahUlasan;
  final List<String> fotoPaths;
  final List<FasilitasItem> fasilitas;
  final List<UlasanItem> ulasan;
  final String? googleMapsUrl;

  const DetailLapanganData({
    required this.id,
    required this.namaLapangan,
    required this.jenisLapangan,
    required this.jenisFloor,
    required this.lokasi,
    required this.hargaPerJam,
    required this.deskripsi,
    required this.ratingRata,
    required this.jumlahUlasan,
    required this.fotoPaths,
    required this.fasilitas,
    required this.ulasan,
    this.googleMapsUrl,
  });

  factory DetailLapanganData.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return DetailLapanganData(
      id: doc.id,
      namaLapangan: map['nama_lapangan'] ?? '',
      jenisLapangan: map['jenis_lapangan'] ?? '',
      jenisFloor: map['jenis_floor'] ?? '',
      lokasi: map['lokasi'] ?? '',
      hargaPerJam: map['harga'] ?? 0,
      deskripsi: map['deskripsi_lapangan'] ?? '',
      ratingRata: (map['rating_overall'] ?? 0).toDouble(),
      jumlahUlasan: map['jumlah_ulasan'] ?? 0,
      fotoPaths: map['foto'] != null ? List<String>.from(map['foto']) : [],
      fasilitas: (map['fasilitas'] as List? ?? [])
          .map((f) => FasilitasItem.fromMap(f))
          .toList(),
      ulasan: [],
      googleMapsUrl: map['maps_url'],
    );
  }
}

// --- Page ---

class DetailLapanganPage extends StatefulWidget {
  final String lapanganId;

  const DetailLapanganPage({super.key, required this.lapanganId});

  @override
  State<DetailLapanganPage> createState() => _DetailLapanganPageState();
}

class _DetailLapanganPageState extends State<DetailLapanganPage> {
  static const Color _primaryColor = Color(0xFF135B9D);
  static const Color _starColor = Color(0xFFFFC107);
  static const Color _successColor = Color(0xFF2ECC71);

  final PageController _pageController = PageController();
  int _currentPhoto = 0;

  DetailLapanganData? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final lapanganDoc = await FirebaseFirestore.instance
          .collection('lapangan')
          .doc(widget.lapanganId)
          .get();

      if (!lapanganDoc.exists) {
        setState(() {
          _error = 'Lapangan tidak ditemukan';
          _isLoading = false;
        });
        return;
      }

      final lapangan = DetailLapanganData.fromFirestore(lapanganDoc);

      final ulasanSnapshot = await FirebaseFirestore.instance
          .collection('ulasan')
          .where('lapangan_id', isEqualTo: widget.lapanganId)
          .orderBy('created_at', descending: true)
          .limit(3)
          .get();

      final ulasan = ulasanSnapshot.docs
          .map((doc) => UlasanItem.fromMap(doc.data()))
          .toList();

      final countSnapshot = await FirebaseFirestore.instance
          .collection('ulasan')
          .where('lapangan_id', isEqualTo: widget.lapanganId)
          .count()
          .get();

      final totalUlasan = countSnapshot.count ?? 0;

      setState(() {
        _data = DetailLapanganData(
          id: lapangan.id,
          namaLapangan: lapangan.namaLapangan,
          jenisLapangan: lapangan.jenisLapangan,
          jenisFloor: lapangan.jenisFloor,
          lokasi: lapangan.lokasi,
          hargaPerJam: lapangan.hargaPerJam,
          deskripsi: lapangan.deskripsi,
          ratingRata: lapangan.ratingRata,
          jumlahUlasan: totalUlasan,
          fotoPaths: lapangan.fotoPaths,
          fasilitas: lapangan.fasilitas,
          ulasan: ulasan,
          googleMapsUrl: lapangan.googleMapsUrl,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat data $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatRupiah(int nominal) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(nominal);
  }

  void _tampilkanShare() async {
    final mapsUrl = _data!.googleMapsUrl;
    if (mapsUrl == null || mapsUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi tidak tersedia')),
      );
      return;
    }
    final uri = Uri.parse(mapsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _fetchData();
                },
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          _buildGaleri(),
          SliverToBoxAdapter(child: _buildInfoUtama()),
          SliverToBoxAdapter(child: _buildFasilitas()),
          SliverToBoxAdapter(child: _buildDeskripsi()),
          SliverToBoxAdapter(child: _buildUlasan()),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: _buildTombolLihatJadwal(),
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
      title: const Text(
        'Detail Lapangan',
        style: TextStyle(
          color: _primaryColor,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildGaleri() {
    final photos = _data!.fotoPaths;

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 280,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: photos.isEmpty ? 1 : photos.length,
              onPageChanged: (i) => setState(() => _currentPhoto = i),
              itemBuilder: (_, i) {
                if (photos.isEmpty) return const _PlaceholderGambar(height: 280);
                final path = photos[i];
                return path.startsWith('http')
                    ? Image.network(path,
                        height: 280,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const _PlaceholderGambar(height: 280))
                    : Image.asset(path,
                        height: 280,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const _PlaceholderGambar(height: 280));
              },
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                height: 80,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xCC000000), Colors.transparent],
                  ),
                ),
              ),
            ),
            if (photos.length > 1)
              Positioned(
                bottom: 12, left: 0, right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(photos.length, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _currentPhoto ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _currentPhoto
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoUtama() {
    final d = _data!;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _successColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  d.jenisLapangan,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _successColor,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: _starColor, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${d.ratingRata.toStringAsFixed(1)} (${d.jumlahUlasan} ulasan)',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF444444),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            d.namaLapangan,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            d.jenisFloor,
            style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 16, color: Color(0xFF888888)),
              const SizedBox(width: 4),
              Text(
                d.lokasi,
                style: const TextStyle(fontSize: 13.5, color: Color(0xFF666666)),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),
          const Text(
            'HARGA LAPANGAN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF888888),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: _formatRupiah(d.hargaPerJam),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const TextSpan(
                  text: ' /jam',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF888888),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeskripsi() {
    final deskripsi = _data!.deskripsi;
    if (deskripsi.isEmpty) return const SizedBox.shrink();

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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Deskripsi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            deskripsi,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF555555),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFasilitas() {
    final fasilitas = _data!.fasilitas;
    if (fasilitas.isEmpty) return const SizedBox.shrink();

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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fasilitas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: fasilitas.map((f) => _KartuFasilitas(item: f)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUlasan() {
    final ulasan = _data!.ulasan;

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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ulasan Pengguna',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              Text(
                '${_data!.ratingRata.toStringAsFixed(1)} / 5.0',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (ulasan.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Belum ada ulasan',
                  style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
                ),
              ),
            )
          else
            ...ulasan.take(2).map((u) => _KartuUlasan(ulasan: u)),
          if (ulasan.length > 2) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SemuaUlasanPage(
                        lapanganId: _data!.id,
                        namaLapangan: _data!.namaLapangan,
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryColor,
                  side: const BorderSide(color: Color(0xFFDDE3EE)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: Text(
                  'Lihat Semua Ulasan (${ulasan.length})',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===== FIX: pass data lapangan langsung, tidak fetch ulang =====
  Widget _buildTombolLihatJadwal() {
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
          onPressed: _data == null
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PilihJadwalPage(
                        lapanganId: _data!.id,
                        // Data dikirim langsung — tidak perlu fetch ulang di PilihJadwalPage
                        namaLapangan: _data!.namaLapangan,
                        jenisLapangan: _data!.jenisLapangan,
                        jenisFloor: _data!.jenisFloor,
                        fotoUrl: _data!.fotoPaths.isNotEmpty
                            ? _data!.fotoPaths.first
                            : '',
                        pricePerHour: _data!.hargaPerJam,
                      ),
                    ),
                  );
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: const Text(
            'Lihat Jadwal',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

// --- Komponen Kartu Fasilitas ---

class _KartuFasilitas extends StatelessWidget {
  final FasilitasItem item;

  const _KartuFasilitas({required this.item});

  static IconData _getIconFromKeyword(String text) {
    String cleanText = text.trim().toLowerCase();
    if (cleanText.contains('wifi')) return Icons.wifi;
    if (cleanText.contains('air') || cleanText.contains('minum')) return Icons.water_drop_outlined;
    if (cleanText.contains('ganti') || cleanText.contains('baju')) return Icons.door_sliding_outlined;
    if (cleanText.contains('parkir')) return Icons.local_parking;
    if (cleanText.contains('kantin') || cleanText.contains('makan')) return Icons.restaurant;
    if (cleanText.contains('musholla') || cleanText.contains('sholat')) return Icons.mosque;
    if (cleanText.contains('toilet') || cleanText.contains('wc')) return Icons.wc;
    if (cleanText.contains('shower')) return Icons.shower;
    if (cleanText.contains('ac') || cleanText.contains('kipas')) return Icons.ac_unit;
    if (cleanText.contains('tribun')) return Icons.chair;
    return Icons.widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIconFromKeyword(item.nama),
            color: const Color(0xFF135B9D),
            size: 32,
          ),
          const SizedBox(height: 6),
          Text(
            item.nama,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF444444),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Komponen Kartu Ulasan ---

class _KartuUlasan extends StatelessWidget {
  final UlasanItem ulasan;

  const _KartuUlasan({required this.ulasan});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFDDE3EE),
                backgroundImage: ulasan.avatarPath.isNotEmpty
                    ? (ulasan.avatarPath.startsWith('http')
                        ? NetworkImage(ulasan.avatarPath)
                        : AssetImage(ulasan.avatarPath)) as ImageProvider
                    : null,
                child: ulasan.avatarPath.isEmpty
                    ? Text(
                        ulasan.namaPengguna.isNotEmpty
                            ? ulasan.namaPengguna[0]
                            : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF135B9D),
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
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    Text(
                      ulasan.waktu,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF888888)),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < ulasan.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: i < ulasan.rating
                        ? const Color(0xFFFFC107)
                        : const Color(0xFFDDDDDD),
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ulasan.komentar,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF444444),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderGambar extends StatelessWidget {
  final double height;

  const _PlaceholderGambar({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: const Color(0xFFE3EAF5),
      child: const Center(
        child: Icon(Icons.sports_soccer_rounded,
            size: 48, color: Color(0xFF1B4E82)),
      ),
    );
  }
}
