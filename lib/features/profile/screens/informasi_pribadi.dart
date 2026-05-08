import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class InformasiPribadiScreen extends StatefulWidget {
  final String initialNama;
  final String initialEmail;
  final String initialTelepon;
  final String? initialFotoPath;

  const InformasiPribadiScreen({
    super.key,
    required this.initialNama,
    required this.initialEmail,
    required this.initialTelepon,
    this.initialFotoPath,
  });

  @override
  State<InformasiPribadiScreen> createState() => _InformasiPribadiScreenState();
}

class _InformasiPribadiScreenState extends State<InformasiPribadiScreen> {
  static const Color _primaryDark = Color(0xFF0D2D6B);
  static const Color _accent      = Color(0xFF1A4FAF);
  static const Color _bgColor     = Color(0xFFF4F6F9);
  static const Color _textDark    = Color(0xFF1A2B3C);

  late TextEditingController _namaController;
  late TextEditingController _emailController;
  late TextEditingController _teleponController;

  late String  _savedNama;
  late String  _savedEmail;
  late String  _savedTelepon;
  String?      _savedFotoPath;
  String?      _currentFotoPath;

  final ImagePicker _picker = ImagePicker();

  bool get _hasUnsavedChanges =>
      _namaController.text    != _savedNama       ||
      _emailController.text   != _savedEmail      ||
      _teleponController.text != _savedTelepon    ||
      _currentFotoPath        != _savedFotoPath;

  @override
  void initState() {
    super.initState();
    _namaController    = TextEditingController(text: widget.initialNama);
    _emailController   = TextEditingController(text: widget.initialEmail);
    _teleponController = TextEditingController(text: widget.initialTelepon);
    _savedNama         = widget.initialNama;
    _savedEmail        = widget.initialEmail;
    _savedTelepon      = widget.initialTelepon;
    _savedFotoPath     = widget.initialFotoPath;
    _currentFotoPath   = widget.initialFotoPath;
    _namaController.addListener(()    => setState(() {}));
    _emailController.addListener(()   => setState(() {}));
    _teleponController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _teleponController.dispose();
    super.dispose();
  }

  TextStyle _p({
    double size = 14,
    FontWeight weight = FontWeight.normal,
    Color color = _textDark,
    double spacing = 0,
  }) {
    return GoogleFonts.poppins(
        fontSize: size, fontWeight: weight, color: color, letterSpacing: spacing);
  }

  // ── Pilih foto ────────────────────────────────────────────────────────────────
  void _pilihFoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ganti Foto Profil', style: _p(size: 16, weight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.camera_alt_rounded, color: _accent, size: 22),
              ),
              title: Text('Ambil dari Kamera', style: _p(size: 14, weight: FontWeight.w500)),
              onTap: () async {
                Navigator.pop(context);
                final XFile? foto = await _picker.pickImage(
                  source: ImageSource.camera, imageQuality: 80,
                );
                if (foto != null) setState(() => _currentFotoPath = foto.path);
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.photo_library_rounded, color: _accent, size: 22),
              ),
              title: Text('Pilih dari Galeri', style: _p(size: 14, weight: FontWeight.w500)),
              onTap: () async {
                Navigator.pop(context);
                final XFile? foto = await _picker.pickImage(
                  source: ImageSource.gallery, imageQuality: 80,
                );
                if (foto != null) setState(() => _currentFotoPath = foto.path);
              },
            ),
            if (_currentFotoPath != null) ...[
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 22),
                ),
                title: Text('Hapus Foto',
                    style: _p(size: 14, weight: FontWeight.w500, color: Colors.red.shade400)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentFotoPath = null);
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Simpan ────────────────────────────────────────────────────────────────────
  void _simpan() {
    setState(() {
      _savedNama     = _namaController.text.trim();
      _savedEmail    = _emailController.text.trim();
      _savedTelepon  = _teleponController.text.trim();
      _savedFotoPath = _currentFotoPath;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text('Perubahan berhasil disimpan!',
                style: _p(size: 13, color: Colors.white)),
          ],
        ),
        backgroundColor: _accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Back handler ──────────────────────────────────────────────────────────────
  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges) {
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
                  decoration: BoxDecoration(
                      color: Colors.red.shade50, shape: BoxShape.circle),
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
                      _savedNama     = _namaController.text.trim();
                      _savedEmail    = _emailController.text.trim();
                      _savedTelepon  = _teleponController.text.trim();
                      _savedFotoPath = _currentFotoPath;
                      Navigator.pop<Map<String, String?>>(context, {
                        'nama'   : _savedNama,
                        'email'  : _savedEmail,
                        'telepon': _savedTelepon,
                        'foto'   : _savedFotoPath,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text('Ya',
                        style: _p(size: 14, weight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop<Map<String, String?>>(context, {
                        'nama'   : _savedNama,
                        'email'  : _savedEmail,
                        'telepon': _savedTelepon,
                        'foto'   : _savedFotoPath,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F1F1),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text('Tidak',
                        style: _p(size: 14, weight: FontWeight.w500, color: _textDark)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return false;
    }
    Navigator.pop<Map<String, String?>>(context, {
      'nama'   : _savedNama,
      'email'  : _savedEmail,
      'telepon': _savedTelepon,
      'foto'   : _savedFotoPath,
    });
    return false;
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
                        onPressed: _onWillPop,
                      ),
                    ),
                    Text('Informasi Pribadi',
                        style: _p(size: 17, weight: FontWeight.w600)),
                  ],
                ),
              ),

              // ── Form ─────────────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),

                      // Avatar — polosan, tap untuk ganti
                      Center(
                        child: GestureDetector(
                          onTap: _pilihFoto,
                          child: Stack(
                            children: [
                              Container(
                                width: 100, height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.shade200,
                                  border: _currentFotoPath != _savedFotoPath
                                      ? Border.all(color: Colors.orange, width: 3)
                                      : null,
                                ),
                                child: ClipOval(
                                  child: _currentFotoPath != null
                                      ? Image.file(
                                          File(_currentFotoPath!),
                                          fit: BoxFit.cover,
                                        )
                                      : const Icon(
                                          Icons.person,
                                          size: 56,
                                          color: Colors.grey,
                                        ),
                                ),
                              ),
                              Positioned(
                                bottom: 0, right: 0,
                                child: Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(
                                    color: _accent,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.edit_rounded,
                                      size: 16, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text('Ganti Foto Profil',
                            style: _p(size: 13, color: _accent)),
                      ),
                      if (_currentFotoPath != _savedFotoPath)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('⚠ Foto belum disimpan',
                                style: _p(size: 11, color: Colors.orange.shade700)),
                          ),
                        ),
                      const SizedBox(height: 32),

                      // Nama Lengkap
                      Text('Nama Lengkap', style: _p(size: 13, weight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _namaController,
                        hint: 'Masukkan nama lengkap',
                        suffix: Icon(Icons.person_outline_rounded,
                            color: Colors.grey.shade400, size: 20),
                      ),
                      const SizedBox(height: 20),

                      // Email
                      Text('Email', style: _p(size: 13, weight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _emailController,
                        hint: 'Masukkan email',
                        keyboardType: TextInputType.emailAddress,
                        suffix: Icon(Icons.email_outlined,
                            color: Colors.grey.shade400, size: 20),
                      ),
                      const SizedBox(height: 20),

                      // Nomor Telepon
                      Text('Nomor Telepon', style: _p(size: 13, weight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _teleponController,
                        hint: 'Masukkan nomor telepon',
                        keyboardType: TextInputType.phone,
                        suffix: Icon(Icons.phone_outlined,
                            color: Colors.grey.shade400, size: 20),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // ── Tombol Simpan ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                color: _bgColor,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _simpan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text('Simpan',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        )],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: _p(size: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: _p(size: 14, color: Colors.grey.shade400),
          suffixIcon: suffix,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}