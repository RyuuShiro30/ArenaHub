import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileAdminScreen extends StatefulWidget {
  const ProfileAdminScreen({super.key});

  @override
  State<ProfileAdminScreen> createState() => _ProfileAdminScreenState();
}

class _ProfileAdminScreenState extends State<ProfileAdminScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth      = FirebaseAuth.instance;

  // ── Colors ───────────────────────────────────────────────────────────────
  static const Color _blue   = Color(0xFF2563EB);
  static const Color _blueBg = Color(0xFFEFF6FF);
  static const Color _blueLt = Color(0xFFDBEAFE);
  static const Color _bg     = Color(0xFFF4F6F9);
  static const Color _white  = Color(0xFFFFFFFF);
  static const Color _text   = Color(0xFF1A2B3C);
  static const Color _muted  = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _red    = Color(0xFFEF4444);
  static const Color _green  = Color(0xFF22C55E);

  // ── Sidebar state ────────────────────────────────────────────────────────
  bool _expanded    = true; // collapsed by default
  int  _selectedNav = 4; // Profil = index 4

  static const double _collapsedW = 56;
  static const double _expandedW  = 220;

  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.dashboard_rounded,           'label': 'Dashboard'},
    {'icon': Icons.confirmation_number_outlined, 'label': 'Kelola Booking'},
    {'icon': Icons.sports_soccer_rounded,       'label': 'Kelola Lapangan'},
    {'icon': Icons.event_note_outlined,         'label': 'Kelola Jadwal'},
    {'icon': Icons.person_outline_rounded,      'label': 'Profil'},
  ];

  // ── Controllers ──────────────────────────────────────────────────────────
  final _namaController  = TextEditingController();
  final _emailController = TextEditingController();
  final _sandiController = TextEditingController();

  // ── State ─────────────────────────────────────────────────────────────────
  bool _obscureSandi = true;
  bool _loading      = true;
  bool _saving       = false;

  String _namaAwal    = '';
  String _emailAwal   = '';
  String _adminName   = 'Admin';
  String _adminRole   = 'Administrator';
  String _status      = 'Aktif';
  String _level       = 'Super';
  String? _adminDocId;

  @override
  void initState() {
    super.initState();
    _fetchAdminProfile();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _sandiController.dispose();
    super.dispose();
  }

  // ── Fetch ─────────────────────────────────────────────────────────────────
  Future<void> _fetchAdminProfile() async {
    try {
      final snapshot = await _firestore
          .collection('admin_profile')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc  = snapshot.docs.first;
        final data = doc.data();
        _adminDocId = doc.id;
        if (mounted) {
          setState(() {
            _namaAwal  = data['fullName'] ?? 'Admin ArenaHub';
            _emailAwal = data['email']    ?? 'administrator@arenahub.com';
            _status    = data['status']   ?? 'Aktif';
            _level     = data['level']    ?? 'Super';
            _adminName = _namaAwal;
            _adminRole = _level;
            _namaController.text  = _namaAwal;
            _emailController.text = _emailAwal;
            _loading = false;
          });
        }
      } else {
        final docRef = await _firestore.collection('admin_profile').add({
          'fullName':  'Admin ArenaHub',
          'email':     'administrator@arenahub.com',
          'status':    'Aktif',
          'level':     'Super',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        _adminDocId = docRef.id;
        if (mounted) {
          setState(() {
            _namaAwal  = 'Admin ArenaHub';
            _emailAwal = 'administrator@arenahub.com';
            _adminName = _namaAwal;
            _namaController.text  = _namaAwal;
            _emailController.text = _emailAwal;
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _namaAwal  = 'Admin ArenaHub';
          _emailAwal = 'administrator@arenahub.com';
          _adminName = _namaAwal;
          _namaController.text  = _namaAwal;
          _emailController.text = _emailAwal;
          _loading = false;
        });
      }
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  Future<void> _simpanPerubahan() async {
    if (_saving) return;
    final nama  = _namaController.text.trim();
    final email = _emailController.text.trim();
    final sandi = _sandiController.text.trim();

    if (nama.isEmpty || email.isEmpty) {
      _showSnackBar('Nama dan Email tidak boleh kosong', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      if (_adminDocId != null) {
        await _firestore.collection('admin_profile').doc(_adminDocId).update({
          'fullName':  nama,
          'email':     email,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      if (sandi.isNotEmpty) {
        if (sandi.length < 8) {
          _showSnackBar('Kata sandi minimal 8 karakter', isError: true);
          setState(() => _saving = false);
          return;
        }
        final user = _auth.currentUser;
        if (user != null) await user.updatePassword(sandi);
      }
      if (mounted) {
        setState(() {
          _namaAwal  = nama;
          _emailAwal = email;
          _adminName = nama;
          _sandiController.clear();
          _saving = false;
        });
        _showSnackBar('Profil berhasil diperbarui!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _showSnackBar('Gagal menyimpan: ${e.toString()}', isError: true);
      }
    }
  }

  void _batalkan() {
    setState(() {
      _namaController.text  = _namaAwal;
      _emailController.text = _emailAwal;
      _sandiController.clear();
    });
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Keluar dari Akun?',
            style: _t(size: 16, weight: FontWeight.w700)),
        content: Text('Kamu akan keluar dari panel admin.',
            style: _t(size: 13, color: _muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: _t(size: 14, color: _muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('Keluar',
                style: _t(size: 14, weight: FontWeight.w600,
                    color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, '/login', (route) => false);
      }
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: Colors.white, size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: _t(size: 13, color: Colors.white))),
        ]),
        backgroundColor: isError ? _red : _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _initials(String name) {
    final p = name.trim().split(' ');
    return p.length >= 2
        ? '${p[0][0]}${p[1][0]}'.toUpperCase()
        : name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  TextStyle _t({double size = 14, FontWeight weight = FontWeight.normal,
      Color color = _text, double spacing = 0}) =>
      GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: weight,
          color: color, letterSpacing: spacing);

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Row(children: [
        ClipRect(child: _buildSidebar()),
        Expanded(
          child: Column(children: [
            _buildTopBar(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _blue))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Text('Profil Saya',
                              style: _t(size: 24, weight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text(
                            'Kelola informasi akun dan preferensi keamanan Anda di ArenaHub.',
                            style: _t(size: 14, color: _muted),
                          ),
                          const SizedBox(height: 28),

                          // Main content
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: 300, child: _buildProfileCard()),
                              const SizedBox(width: 24),
                              Expanded(child: _buildDetailForm()),
                            ],
                          ),

                        ],
                      ),
                    ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── SIDEBAR ───────────────────────────────────────────────────────────────
  Widget _buildSidebar() {
    return ClipRect(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        width: _expanded ? _expandedW : _collapsedW,
        color: _white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Container(
                height: 64,
                padding: EdgeInsets.symmetric(
                    horizontal: _expanded ? 14 : 10),
                decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: _border))),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                        color: _blue,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.sports_soccer_rounded,
                        color: Colors.white, size: 20),
                  ),
                  AnimatedOpacity(
                    opacity: _expanded ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: SizedBox(
                      width: _expandedW - 36 - 14 - 14,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ArenaHub',
                                style: _t(size: 14, weight: FontWeight.w800,
                                    color: _blue),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text('PANEL ADMINISTRASI',
                                style: _t(size: 8, weight: FontWeight.w600,
                                    color: _muted, spacing: 0.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ),
                  ),
                ]),
              ),

            const SizedBox(height: 12),

            // Nav items
            ...List.generate(_navItems.length, (i) {
              final active = _selectedNav == i;
              final item   = _navItems[i];
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedNav = i);
                  // Navigasi ke halaman lain sesuai index
                  if (i != 4) {
                    final route = _navRoutes[i];
                    if (route != null) {
                      Navigator.pushReplacementNamed(context, route);
                    }
                  }
                },
                child: Container(
                  margin: EdgeInsets.symmetric(
                      horizontal: _expanded ? 8 : 4, vertical: 2),
                  padding: EdgeInsets.symmetric(
                      horizontal: _expanded ? 10 : 4, vertical: 10),
                  decoration: BoxDecoration(
                    color: active ? _blueBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 3, height: 20,
                        margin: EdgeInsets.only(right: _expanded ? 7 : 2),
                        decoration: BoxDecoration(
                          color: active ? _blue : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Icon(item['icon'] as IconData,
                          color: active ? _blue : _muted, size: 20),
                      AnimatedOpacity(
                        opacity: _expanded ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 150),
                        child: SizedBox(
                          width: _expanded ? _expandedW - 80 : 0,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Text(item['label'] as String,
                                style: _t(size: 13,
                                    weight: active
                                        ? FontWeight.w700 : FontWeight.w500,
                                    color: active ? _blue : _muted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const Spacer(),

            // ── Logout button ─────────────────────────────────────────
            GestureDetector(
              onTap: _logout,
              child: Container(
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 3, height: 20),
                    const SizedBox(width: 6),
                    const Icon(Icons.logout_rounded,
                        color: Color(0xFFEF4444), size: 20),
                    AnimatedOpacity(
                      opacity: _expanded ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 150),
                      child: SizedBox(
                        width: _expanded ? _expandedW - 80 : 0,
                        child: const Padding(
                          padding: EdgeInsets.only(left: 10),
                          child: Text('Keluar',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFEF4444),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Admin info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: _border))),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: _blue),
                    child: Center(
                      child: Text(_initials(_adminName),
                          style: _t(size: 13, weight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: _expanded ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: SizedBox(
                      width: _expanded ? _expandedW - 36 - 12 - 12 - 10 : 0,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_adminName,
                                style: _t(size: 12, weight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text(_adminRole,
                                style: _t(size: 10, color: _muted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

  // Route map — sesuaikan dengan named routes di app kamu
  static const Map<int, String> _navRoutes = {
    0: '/admin-dashboard',
    1: '/admin-booking',
    2: '/admin-lapangan',
    3: '/admin-jadwal',
    4: '/admin-profil',
  };

  // ── TOP BAR ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      height: 60, color: _white,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(children: [
        Text('Profil', style: _t(size: 17, weight: FontWeight.w700)),
        const Spacer(),
      ]),
    );
  }

  // ── PROFILE CARD ──────────────────────────────────────────────────────────
  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: [
        // Avatar
        Stack(children: [
          Container(
            width: 110, height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _blueBg,
              border: Border.all(color: _blue.withOpacity(0.3), width: 3),
            ),
            child: const Icon(Icons.person_rounded,
                size: 56, color: Color(0xFF93B4F0)),
          ),
          Positioned(
            bottom: 4, right: 4,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: _blue,
                shape: BoxShape.circle,
                border: Border.all(color: _white, width: 2.5),
                boxShadow: [
                  BoxShadow(color: _blue.withOpacity(0.3),
                      blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.edit_rounded,
                  size: 15, color: Colors.white),
            ),
          ),
        ]),
        const SizedBox(height: 18),

        Text(_namaAwal,
            style: _t(size: 18, weight: FontWeight.w700),
            textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(_emailAwal,
            style: _t(size: 13, color: _muted),
            textAlign: TextAlign.center),
        const SizedBox(height: 20),

        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _buildBadge('Status', _status, _blue),
          const SizedBox(width: 24),
          _buildBadge('Level', _level, _blue),
        ]),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _blueBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _blueLt),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline_rounded, color: _blue, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Catatan Keamanan',
                      style: _t(size: 13, weight: FontWeight.w700,
                          color: _blue)),
                  const SizedBox(height: 6),
                  Text(
                    'Pastikan kata sandi Anda memiliki minimal 8 karakter dengan kombinasi angka dan simbol.',
                    style: _t(size: 12, color: _muted, spacing: 0.1),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildBadge(String label, String value, Color color) {
    return Column(children: [
      Text(label,
          style: _t(size: 12, weight: FontWeight.w600, color: color)),
      const SizedBox(height: 4),
      Text(value,
          style: _t(size: 15, weight: FontWeight.w800, color: _text)),
    ]);
  }

  // ── DETAIL FORM ───────────────────────────────────────────────────────────
  Widget _buildDetailForm() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Detail Informasi',
            style: _t(size: 20, weight: FontWeight.w700)),
        const SizedBox(height: 28),

        _buildLabel('Nama Lengkap'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _namaController,
          icon: Icons.person_outline_rounded,
          hint: 'Masukkan nama lengkap',
        ),
        const SizedBox(height: 22),

        _buildLabel('Alamat Email'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _emailController,
          icon: Icons.email_outlined,
          hint: 'Masukkan alamat email',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 22),

        _buildLabel('Kata Sandi Baru'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _sandiController,
          icon: Icons.lock_outline_rounded,
          hint: '••••••••••••',
          obscure: _obscureSandi,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureSandi
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: _muted, size: 20,
            ),
            onPressed: () =>
                setState(() => _obscureSandi = !_obscureSandi),
          ),
        ),
        const SizedBox(height: 6),
        Text('Kosongkan jika tidak ingin mengubah kata sandi.',
            style: _t(size: 12, color: _muted)),
        const SizedBox(height: 32),

        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          OutlinedButton(
            onPressed: _batalkan,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _border),
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Batalkan',
                style: _t(size: 14, weight: FontWeight.w600,
                    color: _text)),
          ),
          const SizedBox(width: 14),
          ElevatedButton(
            onPressed: _saving ? null : _simpanPerubahan,
            style: ElevatedButton.styleFrom(
              backgroundColor: _blue,
              disabledBackgroundColor: _blue.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: _saving
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text('Simpan Perubahan',
                    style: _t(size: 14, weight: FontWeight.w600,
                        color: Colors.white)),
          ),
        ]),
      ]),
    );
  }

  Widget _buildLabel(String text) =>
      Text(text, style: _t(size: 13, weight: FontWeight.w600));

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        color: _white,
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: _t(size: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: _t(size: 14, color: _muted),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(icon, size: 20, color: _muted),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        ),
      ),
    );
  }


}