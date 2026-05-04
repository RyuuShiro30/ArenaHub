import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'informasi_pribadi.dart';
import 'keamanan_sandi.dart';
import 'pusat_bantuan.dart';
import 'kebijakan_privasi.dart';

// TODO: import halaman lain setelah merge
// import '../../home/screens/home_screen.dart';
// import '../../search/screens/search_screen.dart';
// import '../../riwayat/screens/riwayat_screen.dart';

final ValueNotifier<bool> darkModeNotifier = ValueNotifier(false);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool    _notifikasi       = true;
  int     _selectedNavIndex = 3;

  // ── User Data ─────────────────────────────────────────────────────────────────
  String  _nama    = 'Candra Adi';
  String  _email   = 'Candraadi12@gmail.com';
  String  _telepon = '+62 812-3456-7890';
  String? _fotoPath;

  // ── Colors ───────────────────────────────────────────────────────────────────
  static const Color _primaryDark = Color(0xFF0D2D6B);
  static const Color _primaryMid  = Color(0xFF1A4FAF);
  static const Color _accent      = Color(0xFF2563EB);
  static const Color _bgColor     = Color(0xFFF4F6F9);
  static const Color _textDark    = Color(0xFF1A2B3C);

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

  // ── Navigate ke Informasi Pribadi ─────────────────────────────────────────────
  void _goToInformasiPribadi() async {
    final result = await Navigator.push<Map<String, String?>>(
      context,
      MaterialPageRoute(
        builder: (_) => InformasiPribadiScreen(
          initialNama:     _nama,
          initialEmail:    _email,
          initialTelepon:  _telepon,
          initialFotoPath: _fotoPath,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _nama     = result['nama']    ?? _nama;
        _email    = result['email']   ?? _email;
        _telepon  = result['telepon'] ?? _telepon;
        _fotoPath = result['foto'];
      });
    }
  }

  // ── Bottom Nav ────────────────────────────────────────────────────────────────
  // CARA FUNGSIINNYA SETELAH MERGE:
  // 1. Uncomment import halaman di atas
  // 2. Ganti comment TODO di bawah dengan Navigator.pushReplacement ke halaman tujuan
  // Contoh untuk Beranda:
  //   Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
  void _onNavTap(int index) {
    if (index == _selectedNavIndex) return;

    switch (index) {
      case 0:
        // TODO: uncomment setelah merge
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (_) => HomeScreen()),
        // );
        break;
      case 1:
        // TODO: uncomment setelah merge
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (_) => SearchScreen()),
        // );
        break;
      case 2:
        // TODO: uncomment setelah merge
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (_) => RiwayatScreen()),
        // );
        break;
      case 3:
        // Sudah di profil
        break;
    }

    setState(() => _selectedNavIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Column(
        children: [
          // ── STICKY: Top bar putih ─────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: _primaryDark),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Text(
                    'Profil',
                    style: GoogleFonts.poppins(
                      fontSize: 17, fontWeight: FontWeight.w600, color: _textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── SCROLL: Gradient + Content ────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Gradient avatar (ikut scroll)
                  _buildGradientSection(),

                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _buildStatsCard(),
                        const SizedBox(height: 24),
                        _sectionLabel('AKUN'),
                        const SizedBox(height: 10),
                        _buildMenuCard([
                          _menuItem(
                            Icons.person_outline_rounded,
                            'Informasi Pribadi',
                            onTap: _goToInformasiPribadi,
                          ),
                          _divider(),
                          _menuItem(
                            Icons.shield_outlined,
                            'Keamanan & Sandi',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => KeamananSandiScreen()),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 24),
                        _sectionLabel('PENGATURAN'),
                        const SizedBox(height: 10),
                        _buildMenuCard([
                          _toggleItem(
                            Icons.notifications_outlined,
                            'Notifikasi',
                            _notifikasi,
                            (val) => setState(() => _notifikasi = val),
                          ),
                        ]),
                        const SizedBox(height: 24),
                        _sectionLabel('LAINNYA'),
                        const SizedBox(height: 10),
                        _buildMenuCard([
                          _menuItem(
                            Icons.help_outline_rounded,
                            'Pusat Bantuan',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => PusatBantuanScreen()),
                            ),
                          ),
                          _divider(),
                          _menuItem(
                            Icons.policy_outlined,
                            'Kebijakan Privasi',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => KebijakanPrivasiScreen()),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 28),
                        _buildLogoutButton(),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'Versi 2.4.1 (Build 108)',
                            style: _p(size: 12, color: Colors.grey.shade400),
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Gradient Section (ikut scroll) ───────────────────────────────────────────
  Widget _buildGradientSection() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D3D6B), Color(0xFF1A6B8A), Color(0xFF1A8A6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.only(top: 20, bottom: 24),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.3),
              border: Border.all(color: Colors.white.withOpacity(0.6), width: 3),
            ),
            child: ClipOval(
              child: _fotoPath != null
                  ? Image.file(File(_fotoPath!), fit: BoxFit.cover)
                  : const Icon(Icons.person, size: 50, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _nama,
            style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _email,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // ── Stats Card ────────────────────────────────────────────────────────────────
  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2),
        )],
      ),
      child: Row(
        children: [
          _statItem('12', 'TOTAL BOOKING'),
          Container(width: 1, height: 36, color: Colors.grey.shade200),
          _statItem('0', 'ULASAN'),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: GoogleFonts.poppins(
            fontSize: 22, fontWeight: FontWeight.bold, color: _accent,
          )),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.poppins(
            fontSize: 10, fontWeight: FontWeight.w500,
            color: Colors.grey.shade500, letterSpacing: 0.4,
          )),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(label, style: GoogleFonts.poppins(
      fontSize: 11, fontWeight: FontWeight.w600,
      color: Colors.grey.shade500, letterSpacing: 0.8,
    ));
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2),
        )],
      ),
      child: Column(children: children),
    );
  }

  Widget _menuItem(IconData icon, String title, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: _primaryMid, size: 22),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: _p(size: 14, weight: FontWeight.w500))),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _toggleItem(IconData icon, String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: _primaryMid, size: 22),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: _p(size: 14, weight: FontWeight.w500))),
          Switch(
            value: value, onChanged: onChanged,
            activeColor: Colors.white, activeTrackColor: _accent,
            inactiveThumbColor: Colors.white, inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1, thickness: 1, indent: 54, endIndent: 18, color: Colors.grey.shade100,
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
        label: Text(
          'Keluar dari Akun',
          style: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w600, color: Colors.red,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.red, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
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
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, -4),
        )],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final isActive = _selectedNavIndex == i;
              return GestureDetector(
                onTap: () => _onNavTap(i),
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
                      Icon(
                        items[i]['icon'] as IconData,
                        color: isActive ? _primaryDark : Colors.grey.shade400,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i]['label'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
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