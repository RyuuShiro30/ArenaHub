import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../routes/app_routes.dart';
import '../../profile/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;

  // ── Firebase ──────────────────────────────────────────────────────────────────
  final _auth      = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String _fullName       = '';
  String _userEmail      = '';
  bool   _loadingUser    = true;
  bool   _loadingBooking = true;

  Map<String, dynamic>? _lastBooking;

  // ── Colors ───────────────────────────────────────────────────────────────────
  static const Color _primaryDark = Color(0xFF0D2D6B);
  static const Color _accent      = Color(0xFF2563EB);
  static const Color _bgColor     = Color(0xFFF4F6F9);
  static const Color _textDark    = Color(0xFF1A2B3C);

  // ── Sport Data (Cloudinary) ───────────────────────────────────────────────────
  final List<Map<String, dynamic>> _sportCategories = [
    {
      'name' : 'Futsal',
      'image': 'https://res.cloudinary.com/dewncgzjd/image/upload/v1778238273/photo-1575361204480-aadea25e6e68_xyp6yg.jpg',
      'color': const Color(0xFF0D2D6B),
    },
    {
      'name' : 'Basket',
      'image': 'https://res.cloudinary.com/dewncgzjd/image/upload/v1778238254/photo-1546519638-68e109498ffc_x5qddl.jpg',
      'color': const Color(0xFF8B3A0F),
    },
    {
      'name' : 'Bulutangkis',
      'image': 'https://res.cloudinary.com/dewncgzjd/image/upload/v1778238604/glen-carrie-imHF66HA3VY-unsplash_fyjbit.jpg',
      'color': const Color(0xFF1A3A6E),
    },
  ];

  final List<Map<String, dynamic>> _schedules = [
    {'time': '16:00', 'name': 'Lapangan Futsal A',      'status': 'Tersedia', 'price': 'Rp150.000'},
    {'time': '19:00', 'name': 'Lapangan Bulutangkis A', 'status': 'Tersedia', 'price': 'Rp65.000'},
    {'time': '20:00', 'name': 'Lapangan Basket A',      'status': 'Tersedia', 'price': 'Rp200.000'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchLastBooking();
    _loadSavedPhoto();
  }

  // ── Load foto profil tersimpan ────────────────────────────────────────────────
  Future<void> _loadSavedPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('profile_photo_path');
    if (savedPath != null && File(savedPath).existsSync() && mounted) {
      profilePhotoNotifier.value = savedPath;
    }
  }


  Future<void> _fetchUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _fullName    = doc.data()?['fullName'] ?? 'User';
          _userEmail   = doc.data()?['email']    ?? user.email ?? '';
          _loadingUser = false;
        });
        // Sync nama ke notifier
        profileNameNotifier.value = _fullName;
      }
    } catch (e) {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  Future<void> _fetchLastBooking() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final email   = userDoc.data()?['email'] ?? user.email ?? '';
      final query   = await _firestore
          .collection('bookings')
          .where('email', isEqualTo: email)
          .orderBy('tanggal_booking', descending: true)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty && mounted) {
        setState(() {
          _lastBooking    = query.docs.first.data();
          _loadingBooking = false;
        });
      } else {
        if (mounted) setState(() => _loadingBooking = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loadingBooking = false);
    }
  }

  // ── Buka Google Maps ──────────────────────────────────────────────────────────
Future<void> _openMaps() async {
  final Uri mapsUri = Uri.parse(
    'geo:0,0?q=Unggul+Sport+Center+Malang'
  );
  await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
}

  String _formatTanggal(dynamic tanggal) {
    try {
      if (tanggal is Timestamp) {
        final dt = tanggal.toDate();
        return DateFormat('EEEE, d MMM yyyy', 'id_ID').format(dt).toUpperCase();
      }
      return tanggal.toString();
    } catch (_) { return ''; }
  }

  String _formatHarga(dynamic harga) {
    try {
      final num = int.parse(harga.toString());
      return 'Rp${NumberFormat('#,###', 'id_ID').format(num)}';
    } catch (_) { return 'Rp$harga'; }
  }

  String _formatStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid': case 'selesai': case 'success': return 'SELESAI';
      case 'pending':   return 'PENDING';
      case 'cancelled': return 'DIBATALKAN';
      default: return (status ?? '').toUpperCase();
    }
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid': case 'selesai': case 'success': return _accent;
      case 'pending':   return Colors.orange;
      case 'cancelled': return Colors.red;
      default: return _accent;
    }
  }

  TextStyle _p({
    double size = 14,
    FontWeight weight = FontWeight.normal,
    Color color = _textDark,
    double spacing = 0,
    double height = 1.4,
  }) {
    return GoogleFonts.poppins(
      fontSize: size, fontWeight: weight,
      color: color, letterSpacing: spacing, height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: _bgColor,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: _buildHeader(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFeaturedCard(),
                    const SizedBox(height: 26),
                    _sectionTitle('Cabang Olahraga'),
                    const SizedBox(height: 14),
                    _buildSportGrid(),
                    const SizedBox(height: 26),
                    _sectionTitle('Jadwal Tersedia Hari Ini'),
                    const SizedBox(height: 14),
                    _buildScheduleList(),
                    const SizedBox(height: 26),
                    _sectionTitle('Booking Terakhirku'),
                    const SizedBox(height: 14),
                    _buildLastBooking(),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _loadingUser
                  ? Container(
                      width: 160, height: 22,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    )
                  : ValueListenableBuilder<String>(
                      valueListenable: profileNameNotifier,
                      builder: (context, notifierName, _) {
                        final displayName = notifierName.isNotEmpty
                            ? notifierName
                            : _fullName;
                        return Text(
                          'Halo, $displayName!',
                          style: _p(size: 22, weight: FontWeight.bold,
                              color: _primaryDark, height: 1.2),
                        );
                      },
                    ),
              const SizedBox(height: 3),
              Text('Siap berkeringat hari ini?',
                  style: _p(size: 13, color: Colors.grey.shade500)),
            ],
          ),
        ),
        ValueListenableBuilder<String?>(
          valueListenable: profilePhotoNotifier,
          builder: (context, fotoPath, _) {
            return Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: ClipOval(
                child: fotoPath != null
                    ? Image.file(File(fotoPath), fit: BoxFit.cover)
                    : Icon(Icons.person_rounded,
                        color: Colors.grey.shade400, size: 24),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Featured Card ─────────────────────────────────────────────────────────────
  Widget _buildFeaturedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D3D4A), Color(0xFF1A6B5A), Color(0xFF2A9B7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A6B5A).withOpacity(0.45),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Text('REKOMENDASI UTAMA',
                style: _p(size: 10, weight: FontWeight.w600, color: Colors.white, spacing: 0.8)),
          ),
          const SizedBox(height: 14),
          Text('Sport Center\nArenaHub',
              style: _p(size: 26, weight: FontWeight.bold, color: Colors.white, height: 1.2)),
          const SizedBox(height: 14),
          _cardInfo(Icons.location_on_outlined, 'Jl. Raya Karanglo No.84, Malang'),
          const SizedBox(height: 6),
          _cardInfo(Icons.access_time_outlined, '06.00 - 22.00'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.cariLapangan),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0D3D4A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('Pesan Sekarang',
                      style: _p(size: 14, weight: FontWeight.w600, color: const Color(0xFF0D3D4A))),
                ),
              ),
              const SizedBox(width: 10),
              // Tombol Maps
              GestureDetector(
                onTap: _openMaps,
                child: Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.near_me_rounded, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 15),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: _p(size: 12, color: Colors.white70),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: _p(size: 16, weight: FontWeight.bold, color: _textDark));
  }

  // ── Sport Grid ────────────────────────────────────────────────────────────────
  Widget _buildSportGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: _sportCategories.length,
      itemBuilder: (context, i) {
        final sport = _sportCategories[i];
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                sport['image'] as String,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: sport['color'] as Color),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, (sport['color'] as Color).withOpacity(0.88)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                bottom: 14, left: 14,
                child: Text(sport['name'] as String,
                    style: _p(size: 15, weight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Schedule List ─────────────────────────────────────────────────────────────
  Widget _buildScheduleList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('lapangan').limit(3).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('Tidak ada jadwal tersedia', style: _p(color: Colors.grey)));
        }

        final docs = snapshot.data!.docs;
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = data['nama_lapangan'] ?? 'Lapangan';
            final price = data['harga'] ?? 0;
            // Gunakan jam dummy untuk tampilan ringkasan
            const time = "08.00 - 09.00"; 

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(time,
                        style: _p(size: 13, weight: FontWeight.bold, color: _primaryDark)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: _p(size: 13, weight: FontWeight.w600, color: _textDark)),
                        const SizedBox(height: 2),
                        Text('Tersedia', style: _p(size: 11, color: Colors.green.shade600)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_formatHarga(price), style: _p(size: 13, weight: FontWeight.bold, color: _accent)),
                      const SizedBox(height: 2),
                      Text('/ jam', style: _p(size: 11, color: Colors.grey.shade400)),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ── Last Booking ──────────────────────────────────────────────────────────────
  Widget _buildLastBooking() {
    if (_loadingBooking) {
      return Container(
        height: 100,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_lastBooking == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Center(child: Text('Belum ada booking', style: _p(size: 13, color: Colors.grey.shade400))),
      );
    }

    final booking      = _lastBooking!;
    final namaLapangan = booking['nama_lapangan']     ?? '-';
    final tanggal      = booking['tanggal_booking'];
    final totalHarga   = booking['total_harga']       ?? 0;
    final status       = booking['status_pembayaran'] ?? '';
    final customerName = booking['customer_name']     ?? '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(_formatTanggal(tanggal),
                    style: _p(size: 11, weight: FontWeight.w500, color: Colors.grey.shade500, spacing: 0.4)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_formatStatus(status),
                    style: _p(size: 10, weight: FontWeight.bold, color: _statusColor(status), spacing: 0.4)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 3.5, height: 38,
                decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(namaLapangan,
                  style: _p(size: 15, weight: FontWeight.bold, color: _textDark))),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 5),
                  Text(customerName, style: _p(size: 12, color: Colors.grey.shade500)),
                ],
              ),
              Text(_formatHarga(totalHarga),
                  style: _p(size: 14, weight: FontWeight.bold, color: _textDark)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Bottom Nav ────────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_rounded,    'label': 'Beranda'},
      {'icon': Icons.search_rounded,  'label': 'Cari'},
      {'icon': Icons.history_rounded, 'label': 'Riwayat'},
      {'icon': Icons.person_rounded,  'label': 'Profil'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final isActive = _selectedNavIndex == i;
              return GestureDetector(
                onTap: () async {
                  if (i == _selectedNavIndex && i == 0) return;

                  setState(() => _selectedNavIndex = i);

                  if (i == 1) {
                    await Navigator.pushNamed(context, AppRoutes.cariLapangan);
                  } else if (i == 2) {
                    await Navigator.pushNamed(context, AppRoutes.riwayatBooking);
                  } else if (i == 3) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  }

                  if (mounted) {
                    setState(() => _selectedNavIndex = 0);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? _accent.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(items[i]['icon'] as IconData,
                          color: isActive ? _primaryDark : Colors.grey.shade400, size: 24),
                      const SizedBox(height: 4),
                      Text(items[i]['label'] as String,
                          style: _p(
                            size: 11,
                            weight: isActive ? FontWeight.w600 : FontWeight.normal,
                            color: isActive ? _primaryDark : Colors.grey.shade400,
                          )),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}