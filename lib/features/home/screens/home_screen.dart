import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../routes/app_routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;

  // ── Colors ───────────────────────────────────────────────────────────────────
  static const Color _primaryDark  = Color(0xFF1A5C48);
  static const Color _primaryMid   = Color(0xFF27876A);
  static const Color _primaryLight = Color(0xFF3AAD87);
  static const Color _bgColor      = Color(0xFFF4F6F9);
  static const Color _textDark     = Color(0xFF1A2B3C);

  // ── Dummy Data ────────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _sportCategories = [
    {
      'icon'     : Icons.sports_soccer_rounded,
      'name'     : 'Futsal',
      'count'    : '1 Lapangan',
      'bgColor'  : const Color(0xFFEEF0FF),
      'iconColor': const Color(0xFF5B6EF5),
    },
    {
      'icon'     : Icons.sports_basketball_rounded,
      'name'     : 'Basket',
      'count'    : '2 Lapangan',
      'bgColor'  : const Color(0xFFFFF3EE),
      'iconColor': const Color(0xFFF5883B),
    },
    {
      'icon'     : Icons.sports_tennis_rounded,
      'name'     : 'Badminton',
      'count'    : '2 Lapangan',
      'bgColor'  : const Color(0xFFEEF5FF),
      'iconColor': const Color(0xFF4A90D9),
    },
  ];

  final List<Map<String, dynamic>> _schedules = [
    {'time': '16:00', 'name': 'Lapangan Futsal A', 'status': 'Tersedia', 'price': 'Rp150.000'},
    {'time': '19:00', 'name': 'Badminton Court 3', 'status': 'Tersedia', 'price': 'Rp45.000'},
    {'time': '20:00', 'name': 'Basket Indoor',     'status': 'Tersedia', 'price': 'Rp200.000'},
  ];

  // ── Helper: Poppins TextStyle ─────────────────────────────────────────────────
  TextStyle _p({
    double size = 14,
    FontWeight weight = FontWeight.normal,
    Color color = _textDark,
    double spacing = 0,
    double height = 1.4,
  }) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: spacing,
      height: height,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 22),
              _buildHeader(),
              const SizedBox(height: 20),
              _buildFeaturedCard(),
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 26),
              _sectionTitle('Cabang Olahraga'),
              const SizedBox(height: 14),
              _buildSportCategories(),
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
              Text(
                'Halo, Candra! 👋',
                style: _p(size: 20, weight: FontWeight.bold, color: _primaryDark, height: 1.2),
              ),
              const SizedBox(height: 3),
              Text(
                'Siap berkeringat hari ini?',
                style: _p(size: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        _iconButton(Icons.notifications_outlined),
        const SizedBox(width: 10),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _primaryLight, width: 2.5),
            image: const DecorationImage(
              image: NetworkImage('https://i.pravatar.cc/150?img=47'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  Widget _iconButton(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Icon(icon, color: _primaryDark, size: 20),
    );
  }

  // ── Featured Card ─────────────────────────────────────────────────────────────
  Widget _buildFeaturedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF164D3C), Color(0xFF1F7A5E), Color(0xFF2EA07B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: _primaryMid.withOpacity(0.45), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Text(
              'REKOMENDASI UTAMA',
              style: _p(size: 10, weight: FontWeight.w600, color: Colors.white, spacing: 0.8),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Sport Center\nArenaHub',
            style: _p(size: 26, weight: FontWeight.bold, color: Colors.white, height: 1.2),
          ),
          const SizedBox(height: 14),
          _cardInfo(Icons.location_on_outlined, 'Jl. Atletik No. 123, Kota Malang'),
          const SizedBox(height: 6),
          _cardInfo(Icons.access_time_outlined, '08:00 – 22:00'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.booking),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Pesan Sekarang',
                    style: _p(size: 14, weight: FontWeight.w600, color: _primaryDark),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: const Icon(Icons.near_me_rounded, color: Colors.white, size: 22),
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
        Text(text, style: _p(size: 12, color: Colors.white70)),
      ],
    );
  }

  // ── Search Bar ────────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 20),
          const SizedBox(width: 10),
          Text(
            'Cari jenis olahraga atau lapangan...',
            style: _p(size: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  // ── Section Title ─────────────────────────────────────────────────────────────
  Widget _sectionTitle(String title) {
    return Text(title, style: _p(size: 16, weight: FontWeight.bold, color: _textDark));
  }

  // ── Sport Categories ──────────────────────────────────────────────────────────
  Widget _buildSportCategories() {
    return Row(
      children: List.generate(_sportCategories.length, (i) {
        final sport = _sportCategories[i];
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < _sportCategories.length - 1 ? 10 : 0),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: sport['bgColor'] as Color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(sport['icon'] as IconData, color: sport['iconColor'] as Color, size: 22),
                ),
                const SizedBox(height: 9),
                Text(
                  sport['name'] as String,
                  style: _p(size: 12, weight: FontWeight.w600, color: _textDark),
                ),
                const SizedBox(height: 2),
                Text(
                  sport['count'] as String,
                  style: _p(size: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ── Schedule List ─────────────────────────────────────────────────────────────
  Widget _buildScheduleList() {
    return Column(
      children: _schedules.map((s) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              // Time badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                decoration: BoxDecoration(
                  color: _primaryMid.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  s['time'] as String,
                  style: _p(size: 13, weight: FontWeight.bold, color: _primaryDark),
                ),
              ),
              const SizedBox(width: 14),
              // Name + status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s['name'] as String, style: _p(size: 13, weight: FontWeight.w600, color: _textDark)),
                    const SizedBox(height: 2),
                    Text(s['status'] as String, style: _p(size: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(s['price'] as String, style: _p(size: 13, weight: FontWeight.bold, color: _primaryDark)),
                  const SizedBox(height: 2),
                  Text('/ jam', style: _p(size: 11, color: Colors.grey.shade400)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Last Booking ──────────────────────────────────────────────────────────────
  Widget _buildLastBooking() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FUTSAL • MINGGU, 20 OKT',
                style: _p(size: 11, weight: FontWeight.w500, color: Colors.grey.shade500, spacing: 0.4),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _primaryMid.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'SELESAI',
                  style: _p(size: 10, weight: FontWeight.bold, color: _primaryDark, spacing: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 3.5,
                height: 38,
                decoration: BoxDecoration(color: _primaryMid, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(width: 12),
              Text(
                'ArenaHub – Lapangan B',
                style: _p(size: 15, weight: FontWeight.bold, color: _textDark),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 5),
                  Text('18:00 – 20:00 (2 Jam)', style: _p(size: 12, color: Colors.grey.shade500)),
                ],
              ),
              Text('Rp300.000', style: _p(size: 14, weight: FontWeight.bold, color: _textDark)),
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
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final isActive = _selectedNavIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedNavIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? _primaryMid.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        items[i]['icon'] as IconData,
                        color: isActive ? _primaryDark : Colors.grey.shade400,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i]['label'] as String,
                        style: _p(
                          size: 11,
                          weight: isActive ? FontWeight.w600 : FontWeight.normal,
                          color: isActive ? _primaryDark : Colors.grey.shade400,
                        ),
                      ),
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