import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class FasilitasItem {
  final String nama;
  final IconData icon;

  const FasilitasItem({required this.nama, required this.icon});
}

class UlasanItem {
  final String namaPengguna;
  final String avatarPath; // bisa URL atau asset
  final int rating;
  final String komentar;
  final String waktu; // "2 hari yang lalu"

  const UlasanItem({
    required this.namaPengguna,
    required this.avatarPath,
    required this.rating,
    required this.komentar,
    required this.waktu,
  });
}

class DetailLapanganData {
  final String namaLapangan;
  final String jenisLapangan; // "FUTSAL"
  final String lokasi;
  final int hargaPerJam;
  final String deskripsi;
  final double ratingRata;
  final int jumlahUlasan;
  final List<String> fotoPaths; // list URL atau asset
  final List<FasilitasItem> fasilitas;
  final List<UlasanItem> ulasan;
  final String? googleMapsUrl;

  const DetailLapanganData({
    required this.namaLapangan,
    required this.jenisLapangan,
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
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class DetailLapanganPage extends StatefulWidget {
  final DetailLapanganData data;

  const DetailLapanganPage({super.key, required this.data});

  @override
  State<DetailLapanganPage> createState() => _DetailLapanganPageState();
}

class _DetailLapanganPageState extends State<DetailLapanganPage> {
  static const Color _primaryColor = Color(0xFF135B9D);
  static const Color _starColor = Color(0xFFFFC107);
  static const Color _successColor = Color(0xFF2ECC71);

  final PageController _pageController = PageController();
  int _currentPhoto = 0;

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

  // ─── Share bottom sheet ───────────────────────────────────────────────────

  void _tampilkanShare() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const Text(
              'Bagikan',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _ShareOption(
              icon: Icons.link_rounded,
              label: 'Bagikan Link Lapangan',
              deskripsi: 'Salin link untuk promosi',
              onTap: () {
                Navigator.pop(context);
                // TODO: implement share link
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link disalin!')),
                );
              },
            ),
            const SizedBox(height: 12),
            _ShareOption(
              icon: Icons.location_on_rounded,
              label: 'Bagikan Lokasi',
              deskripsi: 'Buka atau bagikan di Google Maps',
              onTap: () {
                Navigator.pop(context);
                // TODO: launch widget.data.googleMapsUrl
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Membuka Google Maps...')),
                );
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildGaleri(),
              SliverToBoxAdapter(child: _buildInfoUtama()),
              SliverToBoxAdapter(child: _buildFasilitas()),
              SliverToBoxAdapter(child: _buildDeskripsi()), 
              SliverToBoxAdapter(child: _buildUlasan()),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          // Floating app bar
          _buildFloatingAppBar(),
        ],
      ),
      bottomNavigationBar: _buildTombolLihatJadwal(),
    );
  }

  // ─── Floating App Bar ─────────────────────────────────────────────────────

  Widget _buildFloatingAppBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _FloatingButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).pop(),
            ),
            _FloatingButton(
              icon: Icons.share_rounded,
              onTap: _tampilkanShare,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Galeri Foto ──────────────────────────────────────────────────────────

  Widget _buildGaleri() {
    final photos = widget.data.fotoPaths;

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 280,
        child: Stack(
          children: [
            // Swipe gallery
            PageView.builder(
              controller: _pageController,
              itemCount: photos.isEmpty ? 1 : photos.length,
              onPageChanged: (i) => setState(() => _currentPhoto = i),
              itemBuilder: (_, i) {
                if (photos.isEmpty) return _PlaceholderGambar(height: 280);
                final path = photos[i];
                return path.startsWith('http')
                    ? Image.network(path,
                        height: 280,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _PlaceholderGambar(height: 280))
                    : Image.asset(path,
                        height: 280,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _PlaceholderGambar(height: 280));
              },
            ),
            // Gradient bawah
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
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
            // Indikator halaman
            if (photos.length > 1)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
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

  // ─── Info Utama ───────────────────────────────────────────────────────────

  Widget _buildInfoUtama() {
    final d = widget.data;

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
          // Badge jenis + rating
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  const Icon(Icons.star_rounded,
                      color: _starColor, size: 18),
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
          // Nama lapangan
          Text(
            d.namaLapangan,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 6),
          // Lokasi
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 16, color: Color(0xFF888888)),
              const SizedBox(width: 4),
              Text(
                d.lokasi,
                style: const TextStyle(
                    fontSize: 13.5, color: Color(0xFF666666)),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),
          // Harga
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

  // Deskripsi
  
  Widget _buildDeskripsi() {
    final deskripsi = widget.data.deskripsi;
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

  // ─── Fasilitas ────────────────────────────────────────────────────────────

  Widget _buildFasilitas() {
    final fasilitas = widget.data.fasilitas;
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
            children: fasilitas
                .map((f) => _KartuFasilitas(item: f))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ─── Ulasan ───────────────────────────────────────────────────────────────

  Widget _buildUlasan() {
    final ulasan = widget.data.ulasan;

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
                '${widget.data.ratingRata.toStringAsFixed(1)} / 5.0',
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
                  // TODO: navigasi ke halaman semua ulasan
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

  // ─── Tombol Lihat Jadwal ──────────────────────────────────────────────────

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
          onPressed: () {
            // TODO: navigasi ke halaman pilih jadwal (temanmu)
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

// ─── Widget Pembantu ─────────────────────────────────────────────────────────

class _FloatingButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _FloatingButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF135B9D), size: 18),
      ),
    );
  }
}

class _KartuFasilitas extends StatelessWidget {
  final FasilitasItem item;

  const _KartuFasilitas({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(item.icon, color: const Color(0xFF135B9D), size: 26),
          const SizedBox(height: 6),
          Text(
            item.nama,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF444444),
            ),
          ),
        ],
      ),
    );
  }
}

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
              // Avatar
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
                        ulasan.namaPengguna[0],
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
              // Bintang
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

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String deskripsi;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.deskripsi,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF135B9D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF135B9D), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  Text(deskripsi,
                      style: const TextStyle(
                          fontSize: 12.5, color: Color(0xFF888888))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFF888888), size: 20),
          ],
        ),
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

// ─── Cara memanggil halaman ini ───────────────────────────────────────────────
//
// Navigator.push(
//   context,
//   MaterialPageRoute(
//     builder: (_) => DetailLapanganPage(
//       data: DetailLapanganData(
//         namaLapangan: 'Lapangan Futsal - A',
//         jenisLapangan: 'FUTSAL',
//         lokasi: 'Malang, Jawa Timur',
//         hargaPerJam: 150000,
//         ratingRata: 4.8,
//         jumlahUlasan: 2,
//         fotoPaths: ['assets/images/futsal_a.jpg'],
//         fasilitas: [
//           FasilitasItem(nama: 'Parkir Luas', icon: Icons.local_parking_rounded),
//           FasilitasItem(nama: 'Kamar Mandi', icon: Icons.shower_rounded),
//           FasilitasItem(nama: 'Kantin', icon: Icons.restaurant_rounded),
//         ],
//         ulasan: [
//           UlasanItem(
//             namaPengguna: 'Andi Saputra',
//             avatarPath: '',
//             rating: 5,
//             komentar: 'Lapangannya sangat bersih dan terawat!',
//             waktu: '2 hari yang lalu',
//           ),
//         ],
//         googleMapsUrl: 'https://maps.google.com/?q=...',
//       ),
//     ),
//   ),
// );