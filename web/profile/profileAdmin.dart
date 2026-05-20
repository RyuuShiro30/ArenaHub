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
  final _auth = FirebaseAuth.instance;

  // ── Colors ──────────────────────────────────────────────────────────────
  static const Color _blue     = Color(0xFF2563EB);
  static const Color _blueBg   = Color(0xFFEFF6FF);
  static const Color _blueLt   = Color(0xFFDBEAFE);
  static const Color _bg       = Color(0xFFF4F6F9);
  static const Color _white    = Color(0xFFFFFFFF);
  static const Color _text     = Color(0xFF1A2B3C);
  static const Color _muted    = Color(0xFF6B7280);
  static const Color _border   = Color(0xFFE5E7EB);
  static const Color _red      = Color(0xFFEF4444);
  static const Color _green    = Color(0xFF22C55E);

  // ── Controllers ────────────────────────────────────────────────────────
  final _namaController  = TextEditingController();
  final _emailController = TextEditingController();
  final _sandiController = TextEditingController();

  // ── State ──────────────────────────────────────────────────────────────
  bool _obscureSandi = true;
  bool _loading      = true;
  bool _saving       = false;

  String _namaAwal  = '';
  String _emailAwal = '';
  String _status    = 'Aktif';
  String _level     = 'Super';
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

  // ── Fetch admin profile from Firestore ─────────────────────────────────
  Future<void> _fetchAdminProfile() async {
    try {
      // Try to get admin profile from admin_profile collection
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
            _namaController.text  = _namaAwal;
            _emailController.text = _emailAwal;
            _loading = false;
          });
        }
      } else {
        // Create default admin profile document
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
          _namaController.text  = _namaAwal;
          _emailController.text = _emailAwal;
          _loading = false;
        });
      }
    }
  }

  // ── Save changes to Firestore ──────────────────────────────────────────
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
      // Update Firestore document
      if (_adminDocId != null) {
        await _firestore.collection('admin_profile').doc(_adminDocId).update({
          'fullName':  nama,
          'email':     email,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Update password if provided
      if (sandi.isNotEmpty) {
        if (sandi.length < 8) {
          _showSnackBar('Kata sandi minimal 8 karakter', isError: true);
          setState(() => _saving = false);
          return;
        }

        final user = _auth.currentUser;
        if (user != null) {
          await user.updatePassword(sandi);
        }
      }

      if (mounted) {
        setState(() {
          _namaAwal  = nama;
          _emailAwal = email;
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

  // ── Reset form ─────────────────────────────────────────────────────────
  void _batalkan() {
    setState(() {
      _namaController.text  = _namaAwal;
      _emailController.text = _emailAwal;
      _sandiController.clear();
    });
  }

  // ── Snackbar ───────────────────────────────────────────────────────────
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

  // ── Logout ─────────────────────────────────────────────────────────────
  void _keluarSesi() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Keluar Sesi?', style: _t(size: 16, weight: FontWeight.w700)),
        content: Text(
          'Anda akan keluar dari semua perangkat yang terhubung.',
          style: _t(size: 13, color: _muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: _t(size: 14, color: _muted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _auth.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('Keluar', style: _t(size: 14, weight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Text style helper ──────────────────────────────────────────────────
  TextStyle _t({double size = 14, FontWeight weight = FontWeight.normal,
      Color color = _text, double spacing = 0}) =>
      GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: weight,
          color: color, letterSpacing: spacing);

  // ── BUILD ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _blue));
    }

    return Material(
      color: _bg,
      child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────
          Text('Profil Saya',
              style: _t(size: 24, weight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Kelola informasi akun dan preferensi keamanan Anda di ArenaHub.',
              style: _t(size: 14, color: _muted)),
          const SizedBox(height: 28),

          // ── Main content: Profile Card + Detail Form ────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── LEFT: Profile Card ─────────────────────────────────
              SizedBox(
                width: 300,
                child: _buildProfileCard(),
              ),
              const SizedBox(width: 24),

              // ─── RIGHT: Detail Information ──────────────────────────
              Expanded(child: _buildDetailForm()),
            ],
          ),

          const SizedBox(height: 24),

          // ── Logout Section ──────────────────────────────────────────
          Align(
            alignment: Alignment.centerRight,
            child: _buildLogoutCard(),
          ),
        ],
      ),
      ),
    );
  }

  // ── Profile Card (Left Side) ───────────────────────────────────────────
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
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _blueBg,
                  border: Border.all(color: _blue.withOpacity(0.3), width: 3),
                ),
                child: const Icon(Icons.person_rounded, size: 56, color: Color(0xFF93B4F0)),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: _white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: _blue.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.edit_rounded, size: 15, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Name
          Text(
            _namaAwal,
            style: _t(size: 18, weight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // Email
          Text(
            _emailAwal,
            style: _t(size: 13, color: _muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Status & Level badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBadge('Status', _status, _blue),
              const SizedBox(width: 24),
              _buildBadge('Level', _level, _blue),
            ],
          ),
          const SizedBox(height: 24),

          // Security note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _blueBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _blueLt),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: _blue, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Catatan Keamanan',
                          style: _t(size: 13, weight: FontWeight.w700, color: _blue)),
                      const SizedBox(height: 6),
                      Text(
                        'Pastikan kata sandi Anda memiliki minimal 8 karakter dengan kombinasi angka dan simbol untuk keamanan maksimal.',
                        style: _t(size: 12, color: _muted, spacing: 0.1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Badge ──────────────────────────────────────────────────────────────
  Widget _buildBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: _t(size: 12, weight: FontWeight.w600, color: color)),
        const SizedBox(height: 4),
        Text(value, style: _t(size: 15, weight: FontWeight.w800, color: _text)),
      ],
    );
  }

  // ── Detail Form (Right Side) ───────────────────────────────────────────
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
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detail Informasi',
              style: _t(size: 20, weight: FontWeight.w700)),
          const SizedBox(height: 28),

          // Nama Lengkap
          _buildLabel('Nama Lengkap'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _namaController,
            icon: Icons.person_outline_rounded,
            hint: 'Masukkan nama lengkap',
          ),
          const SizedBox(height: 22),

          // Alamat Email
          _buildLabel('Alamat Email'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _emailController,
            icon: Icons.email_outlined,
            hint: 'Masukkan alamat email',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 22),

          // Kata Sandi Baru
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
                color: _muted,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureSandi = !_obscureSandi),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Kosongkan jika tidak ingin mengubah kata sandi.',
            style: _t(size: 12, color: _muted),
          ),
          const SizedBox(height: 32),

          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Batalkan
              OutlinedButton(
                onPressed: _batalkan,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _border),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Batalkan',
                    style: _t(size: 14, weight: FontWeight.w600, color: _text)),
              ),
              const SizedBox(width: 14),

              // Simpan Perubahan
              ElevatedButton(
                onPressed: _saving ? null : _simpanPerubahan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  disabledBackgroundColor: _blue.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
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
                        style: _t(size: 14, weight: FontWeight.w600, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Label ──────────────────────────────────────────────────────────────
  Widget _buildLabel(String text) {
    return Text(text, style: _t(size: 13, weight: FontWeight.w600));
  }

  // ── TextField ──────────────────────────────────────────────────────────
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
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        ),
      ),
    );
  }

  // ── Logout Card ────────────────────────────────────────────────────────
  Widget _buildLogoutCard() {
    return Container(
      width: 380,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.logout_rounded, color: _red, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Keluar Sesi',
                    style: _t(size: 14, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Keluar dari semua perangkat yang terhubung.',
                    style: _t(size: 12, color: _muted)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _keluarSesi,
                  child: Text('Keluar Sekarang',
                      style: _t(size: 13, weight: FontWeight.w700, color: _red)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
