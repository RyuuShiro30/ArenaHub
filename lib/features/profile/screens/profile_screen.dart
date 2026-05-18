import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'informasi_pribadi.dart';
import 'keamanan_sandi.dart';
import 'pusat_bantuan.dart';
import 'kebijakan_privasi.dart';
import '../../../../routes/app_routes.dart';

<<<<<<< Updated upstream
final ValueNotifier<bool>    darkModeNotifier     = ValueNotifier(false);
final ValueNotifier<String?> profilePhotoNotifier = ValueNotifier(null);
final ValueNotifier<String>  profileNameNotifier  = ValueNotifier('');
=======
final ValueNotifier<bool> darkModeNotifier = ValueNotifier(false);
>>>>>>> Stashed changes

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
<<<<<<< Updated upstream
  bool _notifikasi       = true;
  int  _selectedNavIndex = 3;

  final _auth      = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

=======
  bool _notifikasi      = true;
  int  _selectedNavIndex = 3;

  // ── Firebase ──────────────────────────────────────────────────────────────────
  final _auth      = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // ── User Data dari Firebase ───────────────────────────────────────────────────
>>>>>>> Stashed changes
  String  _nama         = '';
  String  _email        = '';
  String  _telepon      = '';
  String? _fotoPath;
  int     _totalBooking = 0;
<<<<<<< Updated upstream
  int     _totalUlasan  = 0; // ← dari collection ulasan, field user_id
=======
>>>>>>> Stashed changes
  bool    _loadingUser  = true;

  static const Color _primaryDark = Color(0xFF0D2D6B);
  static const Color _primaryMid  = Color(0xFF1A4FAF);
  static const Color _accent      = Color(0xFF2563EB);
  static const Color _bgColor     = Color(0xFFF4F6F9);
  static const Color _textDark    = Color(0xFF1A2B3C);

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

<<<<<<< Updated upstream
  // ── Fetch data user + booking + ulasan dari Firestore ────────────────────
=======
  // ── Fetch data user dari Firestore ────────────────────────────────────────────
>>>>>>> Stashed changes
  Future<void> _fetchUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

<<<<<<< Updated upstream
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data     = doc.data()!;
        final email    = data['email'] ?? user.email ?? '';
        final photoUrl = data['photoUrl'] as String?;
=======
      // Ambil data profil
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        final email = data['email'] ?? user.email ?? '';
>>>>>>> Stashed changes

        // Hitung total booking berdasarkan email
        final bookingQuery = await _firestore
            .collection('bookings')
            .where('email', isEqualTo: email)
            .get();

<<<<<<< Updated upstream
        // Hitung total ulasan berdasarkan user_id ← field dari Firestore
        final ulasanQuery = await _firestore
            .collection('ulasan')
            .where('user_id', isEqualTo: user.uid)
            .get();

        if (mounted) {
          setState(() {
            _nama         = data['fullName'] ?? '';
            _email        = email;
            _telepon      = data['phone']    ?? '';
            _fotoPath     = photoUrl;
            _totalBooking = bookingQuery.docs.length;
            _totalUlasan  = ulasanQuery.docs.length; // ← real dari Firestore
            _loadingUser  = false;
          });

          profileNameNotifier.value  = _nama;
          profilePhotoNotifier.value = _fotoPath;
        }
=======
        setState(() {
          _nama         = data['fullName'] ?? '';
          _email        = email;
          _telepon      = data['phone']    ?? '';
          _totalBooking = bookingQuery.docs.length;
          _loadingUser  = false;
        });
>>>>>>> Stashed changes
      }
    } catch (e) {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

<<<<<<< Updated upstream
  // ── Helper: tampilkan foto dari URL Cloudinary ────────────────────────────
  Widget _buildFotoWidget({double size = 90}) {
    if (_fotoPath == null) {
      return Icon(Icons.person, size: size * 0.55, color: Colors.white);
    }
    return Image.network(
      _fotoPath!,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white.withOpacity(0.8),
          ),
        );
      },
      errorBuilder: (_, __, ___) =>
          Icon(Icons.person, size: size * 0.55, color: Colors.white),
    );
  }

=======
>>>>>>> Stashed changes
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

  // ── Navigate ke Informasi Pribadi ─────────────────────────────────────────
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

    if (result != null && mounted) {
      setState(() {
        _nama     = result['nama']    ?? _nama;
        _email    = result['email']   ?? _email;
        _telepon  = result['telepon'] ?? _telepon;
        _fotoPath = result['foto'];
      });

      profileNameNotifier.value  = _nama;
      profilePhotoNotifier.value = _fotoPath;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text('Profil berhasil diperbarui!',
                  style: _p(size: 13, color: Colors.white)),
            ],
          ),
          backgroundColor: _accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

<<<<<<< Updated upstream
  // ── Logout ────────────────────────────────────────────────────────────────
=======
  // ── Logout ────────────────────────────────────────────────────────────────────
>>>>>>> Stashed changes
  void _logout() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
<<<<<<< Updated upstream
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
=======
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
>>>>>>> Stashed changes
        title: Text('Keluar dari Akun?',
            style: _p(size: 16, weight: FontWeight.bold)),
        content: Text('Kamu akan keluar dari akun ini.',
            style: _p(size: 13, color: Colors.grey.shade600)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: _p(size: 14, color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _auth.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
<<<<<<< Updated upstream
                    context, '/login', (route) => false);
=======
                  context, '/login', (route) => false,
                );
>>>>>>> Stashed changes
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
<<<<<<< Updated upstream
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('Keluar',
                style: _p(
                    size: 14,
                    weight: FontWeight.w600,
                    color: Colors.white)),
=======
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('Keluar', style: _p(size: 14, weight: FontWeight.w600, color: Colors.white)),
>>>>>>> Stashed changes
          ),
        ],
      ),
    );
  }

<<<<<<< Updated upstream
=======
  // ── Bottom Nav ────────────────────────────────────────────────────────────────
>>>>>>> Stashed changes
  void _onNavTap(int index) {
    if (index == _selectedNavIndex) return;
    switch (index) {
      case 0:
<<<<<<< Updated upstream
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.home, (route) => false);
        return;
      case 1:
        Navigator.pushNamed(context, AppRoutes.cariLapangan);
        return;
      case 2:
        Navigator.pushNamed(context, AppRoutes.riwayatBooking);
        return;
=======
        // TODO: uncomment setelah merge
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
        break;
      case 1:
        // TODO: uncomment setelah merge
        break;
      case 2:
        // TODO: uncomment setelah merge
        break;
>>>>>>> Stashed changes
      case 3:
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
<<<<<<< Updated upstream
=======
          // ── STICKY: Top bar putih ─────────────────────────────────────────
>>>>>>> Stashed changes
          SafeArea(
            bottom: false,
            child: Container(
              color: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: _primaryDark),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
<<<<<<< Updated upstream
                  Text('Profil',
                      style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: _textDark)),
=======
                  Text('Profil', style: GoogleFonts.poppins(
                    fontSize: 17, fontWeight: FontWeight.w600, color: _textDark,
                  )),
>>>>>>> Stashed changes
                ],
              ),
            ),
          ),
<<<<<<< Updated upstream
=======

          // ── SCROLL: Gradient + Content ────────────────────────────────────
>>>>>>> Stashed changes
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildGradientSection(),
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
<<<<<<< Updated upstream
                          _menuItem(Icons.person_outline_rounded,
                              'Informasi Pribadi',
                              onTap: _goToInformasiPribadi),
                          _divider(),
                          _menuItem(Icons.shield_outlined,
                              'Keamanan & Sandi',
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          KeamananSandiScreen()))),
=======
                          _menuItem(Icons.person_outline_rounded, 'Informasi Pribadi',
                              onTap: _goToInformasiPribadi),
                          _divider(),
                          _menuItem(Icons.shield_outlined, 'Keamanan & Sandi',
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => KeamananSandiScreen()))),
>>>>>>> Stashed changes
                        ]),
                        const SizedBox(height: 24),
                        _sectionLabel('PENGATURAN'),
                        const SizedBox(height: 10),
                        _buildMenuCard([
<<<<<<< Updated upstream
                          _toggleItem(
                              Icons.notifications_outlined,
                              'Notifikasi',
                              _notifikasi,
                              (val) =>
                                  setState(() => _notifikasi = val)),
=======
                          _toggleItem(Icons.notifications_outlined, 'Notifikasi',
                              _notifikasi, (val) => setState(() => _notifikasi = val)),
>>>>>>> Stashed changes
                        ]),
                        const SizedBox(height: 24),
                        _sectionLabel('LAINNYA'),
                        const SizedBox(height: 10),
                        _buildMenuCard([
<<<<<<< Updated upstream
                          _menuItem(Icons.help_outline_rounded,
                              'Pusat Bantuan',
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          PusatBantuanScreen()))),
                          _divider(),
                          _menuItem(Icons.policy_outlined,
                              'Kebijakan Privasi',
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          KebijakanPrivasiScreen()))),
=======
                          _menuItem(Icons.help_outline_rounded, 'Pusat Bantuan',
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => PusatBantuanScreen()))),
                          _divider(),
                          _menuItem(Icons.policy_outlined, 'Kebijakan Privasi',
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => KebijakanPrivasiScreen()))),
>>>>>>> Stashed changes
                        ]),
                        const SizedBox(height: 28),
                        _buildLogoutButton(),
                        const SizedBox(height: 16),
                        Center(
                          child: Text('Versi 2.4.1 (Build 108)',
<<<<<<< Updated upstream
                              style: _p(
                                  size: 12,
                                  color: Colors.grey.shade400)),
=======
                              style: _p(size: 12, color: Colors.grey.shade400)),
>>>>>>> Stashed changes
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
    );
  }

<<<<<<< Updated upstream
  // ── Gradient Section ──────────────────────────────────────────────────────
=======
  // ── Gradient Section ──────────────────────────────────────────────────────────
>>>>>>> Stashed changes
  Widget _buildGradientSection() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0D3D6B),
            Color(0xFF1A6B8A),
            Color(0xFF1A8A6B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.only(top: 20, bottom: 24),
      child: Column(
        children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.3),
              border: Border.all(
                  color: Colors.white.withOpacity(0.6), width: 3),
            ),
            child: ClipOval(child: _buildFotoWidget(size: 90)),
          ),
          const SizedBox(height: 12),
          _loadingUser
<<<<<<< Updated upstream
              ? Container(
                  width: 120, height: 18,
=======
              ? Container(width: 120, height: 18,
>>>>>>> Stashed changes
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ))
<<<<<<< Updated upstream
              : Text(_nama,
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
          const SizedBox(height: 4),
          _loadingUser
              ? Container(
                  width: 160, height: 14,
=======
              : Text(_nama, style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          _loadingUser
              ? Container(width: 160, height: 14,
>>>>>>> Stashed changes
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ))
<<<<<<< Updated upstream
              : Text(_email,
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.white70)),
=======
              : Text(_email, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70)),
>>>>>>> Stashed changes
        ],
      ),
    );
  }

<<<<<<< Updated upstream
  // ── Stats Card ────────────────────────────────────────────────────────────
=======
  // ── Stats Card (dari Firebase) ────────────────────────────────────────────────
>>>>>>> Stashed changes
  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
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
      child: Row(
        children: [
          _statItem(
            _loadingUser ? '-' : _totalBooking.toString(),
            'TOTAL BOOKING',
          ),
          Container(width: 1, height: 36, color: Colors.grey.shade200),
          _statItem(
            _loadingUser ? '-' : _totalUlasan.toString(), // ← real data
            'ULASAN',
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _accent)),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.4)),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(label,
        style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 0.8));
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
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
      child: Column(children: children),
    );
  }

  Widget _menuItem(IconData icon, String title,
      {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: _primaryMid, size: 22),
            const SizedBox(width: 14),
            Expanded(
                child: Text(title,
                    style: _p(size: 14, weight: FontWeight.w500))),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade400, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _toggleItem(IconData icon, String title, bool value,
      ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: _primaryMid, size: 22),
          const SizedBox(width: 14),
          Expanded(
              child: Text(title,
                  style: _p(size: 14, weight: FontWeight.w500))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: _accent,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _divider() {
<<<<<<< Updated upstream
    return Divider(
        height: 1,
        thickness: 1,
        indent: 54,
        endIndent: 18,
        color: Colors.grey.shade100);
=======
    return Divider(height: 1, thickness: 1, indent: 54, endIndent: 18, color: Colors.grey.shade100);
>>>>>>> Stashed changes
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
<<<<<<< Updated upstream
        onPressed: _logout,
        icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
        label: Text('Keluar dari Akun',
            style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.red)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.red, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
=======
        onPressed: _logout, // ← sekarang pakai Firebase signOut
        icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
        label: Text('Keluar dari Akun', style: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w600, color: Colors.red,
        )),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.red, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

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
                      Icon(items[i]['icon'] as IconData,
                          color: isActive ? _primaryDark : Colors.grey.shade400, size: 24),
                      const SizedBox(height: 4),
                      Text(items[i]['label'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                            color: isActive ? _primaryDark : Colors.grey.shade400,
                          )),
                    ],
                  ),
                ),
              );
            }),
          ),
>>>>>>> Stashed changes
        ),
      ),
    );
  }
}