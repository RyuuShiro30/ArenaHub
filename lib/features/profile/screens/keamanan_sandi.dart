import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class KeamananSandiScreen extends StatefulWidget {
  const KeamananSandiScreen({super.key});

  @override
  State<KeamananSandiScreen> createState() => _KeamananSandiScreenState();
}

class _KeamananSandiScreenState extends State<KeamananSandiScreen> {
  static const Color _primaryDark = Color(0xFF0D2D6B);
  static const Color _accent      = Color(0xFF1A4FAF);
  static const Color _bgColor     = Color(0xFFF4F6F9);
  static const Color _textDark    = Color(0xFF1A2B3C);

  final TextEditingController _sandiLamaController    = TextEditingController();
  final TextEditingController _sandiBaruController    = TextEditingController();
  final TextEditingController _konfirmasiController   = TextEditingController();

  bool _showSandiLama  = false;
  bool _showSandiBaru  = false;
  bool _showKonfirmasi = false;
  bool _isLoading      = false;

  bool get _hasChanges =>
      _sandiLamaController.text.isNotEmpty  ||
      _sandiBaruController.text.isNotEmpty  ||
      _konfirmasiController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _sandiLamaController.addListener(()  => setState(() {}));
    _sandiBaruController.addListener(()  => setState(() {}));
    _konfirmasiController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _sandiLamaController.dispose();
    _sandiBaruController.dispose();
    _konfirmasiController.dispose();
    super.dispose();
  }

  TextStyle _p({double size = 14, FontWeight weight = FontWeight.normal,
      Color color = _textDark, double spacing = 0}) {
    return GoogleFonts.poppins(fontSize: size, fontWeight: weight,
        color: color, letterSpacing: spacing);
  }

  // ── Simpan Perubahan Password via Firebase ────────────────────────────────────
  Future<void> _simpanPerubahan() async {
    if (_sandiLamaController.text.isEmpty) {
      _showError('Kata sandi lama tidak boleh kosong!');
      return;
    }
    if (_sandiBaruController.text.length < 8) {
      _showError('Kata sandi baru minimal 8 karakter!');
      return;
    }
    if (_sandiBaruController.text != _konfirmasiController.text) {
      _showError('Konfirmasi kata sandi tidak cocok!');
      return;
    }
    if (_sandiLamaController.text == _sandiBaruController.text) {
      _showError('Kata sandi baru harus berbeda dari sandi lama!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        _showError('User tidak ditemukan!');
        return;
      }

      // Step 1: Re-authenticate dengan sandi lama
      final credential = EmailAuthProvider.credential(
        email:    user.email!,
        password: _sandiLamaController.text,
      );
      await user.reauthenticateWithCredential(credential);

      // Step 2: Update ke sandi baru
      await user.updatePassword(_sandiBaruController.text);

      // Step 3: Bersihkan field & tampilkan snackbar sukses (tanpa logout)
      _sandiLamaController.clear();
      _sandiBaruController.clear();
      _konfirmasiController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text('Kata sandi berhasil diubah!',
                    style: _p(size: 13, color: Colors.white)),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            duration: const Duration(seconds: 2),
          ),
        );
<<<<<<< Updated upstream
        // Kembali ke ProfileScreen setelah SnackBar tampil
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) Navigator.pop(context);
=======
>>>>>>> Stashed changes
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          _showError('Kata sandi lama salah!');
          break;
        case 'weak-password':
          _showError('Kata sandi baru terlalu lemah!');
          break;
        case 'requires-recent-login':
          _showError('Sesi habis. Silakan login ulang.');
          break;
        default:
          _showError('Gagal mengubah kata sandi. Coba lagi.');
      }
    } catch (e) {
      _showError('Terjadi kesalahan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: _p(size: 13, color: Colors.white))),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_hasChanges) {
      await showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.5),
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                ),
                const SizedBox(height: 16),
                Text('Simpan perubahan?', style: _p(size: 16, weight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Anda memiliki perubahan yang\nbelum disimpan.',
                    textAlign: TextAlign.center,
                    style: _p(size: 13, color: Colors.grey.shade600)),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _simpanPerubahan();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text('Ya', style: _p(size: 14, weight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F1F1),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text('Tidak', style: _p(size: 14, weight: FontWeight.w500, color: _textDark)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top Bar ──────────────────────────────────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: _primaryDark),
                        onPressed: () async {
                          if (await _onWillPop()) Navigator.pop(context);
                        },
                      ),
                    ),
                    Text('Keamanan & Sandi', style: _p(size: 17, weight: FontWeight.w600)),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),

                      // Hero Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0D2D6B), Color(0xFF1A4FAF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 46, height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.shield_rounded,
                                  color: Colors.greenAccent, size: 26),
                            ),
                            const SizedBox(height: 16),
                            Text('Keamanan & Sandi',
                                style: _p(size: 20, weight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 8),
                            Text(
                              'Lindungi akun Anda dengan\nmemperbarui kata sandi secara berkala.',
                              style: _p(size: 13, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      Text('Kata Sandi Lama', style: _p(size: 13, weight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      _buildPasswordField(
                        controller: _sandiLamaController,
                        hint: 'Masukkan sandi lama',
                        isVisible: _showSandiLama,
                        onToggle: () => setState(() => _showSandiLama = !_showSandiLama),
                      ),
                      const SizedBox(height: 20),

                      Text('Kata Sandi Baru', style: _p(size: 13, weight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      _buildPasswordField(
                        controller: _sandiBaruController,
                        hint: 'Buat sandi baru',
                        isVisible: _showSandiBaru,
                        onToggle: () => setState(() => _showSandiBaru = !_showSandiBaru),
                      ),
                      const SizedBox(height: 20),

                      Text('Konfirmasi Kata Sandi Baru',
                          style: _p(size: 13, weight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      _buildPasswordField(
                        controller: _konfirmasiController,
                        hint: 'Ulangi sandi baru',
                        isVisible: _showKonfirmasi,
                        onToggle: () => setState(() => _showKonfirmasi = !_showKonfirmasi),
                      ),
                      const SizedBox(height: 24),

                      // Tips
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF3FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFCDD8FF), width: 1),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded, color: _accent, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('TIPS KEAMANAN',
                                      style: _p(size: 11, weight: FontWeight.bold,
                                          color: _accent, spacing: 0.5)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Gunakan minimal 8 karakter dengan kombinasi angka, huruf besar, dan simbol untuk keamanan maksimal.',
                                    style: _p(size: 12, color: const Color(0xFF3A4A6B)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // ── Tombol Simpan ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                color: _bgColor,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _simpanPerubahan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text('Simpan Perubahan',
                            style: _p(size: 15, weight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: controller,
        obscureText: !isVisible,
        style: _p(size: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: _p(size: 14, color: Colors.grey.shade400),
          suffixIcon: IconButton(
            icon: Icon(
              isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: Colors.grey.shade400, size: 20,
            ),
            onPressed: onToggle,
          ),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          filled: true, fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}