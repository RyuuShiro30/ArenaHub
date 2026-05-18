import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
<<<<<<< Updated upstream
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
=======
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
>>>>>>> Stashed changes

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

  // ── Simpan ke cloudinary ───────────────────────────────────────────────
  static const String _cloudName    = 'dewncgzjd';
  static const String _uploadPreset = 'profile_upload';
  // ─────────────────────────────────────────────────────────────────────────

  late TextEditingController _namaController;
  late TextEditingController _emailController;
  late TextEditingController _teleponController;

<<<<<<< Updated upstream
  late String _savedNama;
  late String _savedEmail;
  late String _savedTelepon;
  String?     _savedFotoPath;   // URL Cloudinary atau null
  String?     _currentFotoPath; // path lokal (File baru) atau URL lama

  bool _isLoading = false;
=======
  late String  _savedNama;
  late String  _savedEmail;
  late String  _savedTelepon;
  String?      _savedFotoPath;
  String?      _currentFotoPath;   // path lokal (File)
  String?      _fotoUrl;           // URL dari Firebase Storage

  bool _isUploading = false;
>>>>>>> Stashed changes

  final ImagePicker _picker = ImagePicker();

  bool get _hasUnsavedChanges =>
      _namaController.text    != _savedNama    ||
      _emailController.text   != _savedEmail   ||
      _teleponController.text != _savedTelepon ||
      _currentFotoPath        != _savedFotoPath;

  // true jika _currentFotoPath adalah path lokal (foto baru dipilih, belum diupload)
  bool get _isLocalFile =>
      _currentFotoPath != null && !_currentFotoPath!.startsWith('http');

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

<<<<<<< Updated upstream
  TextStyle _p({
    double size = 14,
    FontWeight weight = FontWeight.normal,
    Color color = _textDark,
    double spacing = 0,
  }) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: spacing,
    );
=======
  TextStyle _p({double size = 14, FontWeight weight = FontWeight.normal,
      Color color = _textDark, double spacing = 0}) {
    return GoogleFonts.poppins(fontSize: size, fontWeight: weight,
        color: color, letterSpacing: spacing);
>>>>>>> Stashed changes
  }

  // ── Widget foto (lokal atau URL) ──────────────────────────────────────────
  Widget _buildFotoWidget() {
    if (_currentFotoPath == null) {
      return const Icon(Icons.person, size: 56, color: Colors.grey);
    }
    if (_isLocalFile) {
      return Image.file(File(_currentFotoPath!), fit: BoxFit.cover);
    }
    return Image.network(
      _currentFotoPath!,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      },
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.person, size: 56, color: Colors.grey),
    );
  }

  // ── Pilih foto ────────────────────────────────────────────────────────────
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
            Text('Ganti Foto Profil',
                style: _p(size: 16, weight: FontWeight.bold)),
            const SizedBox(height: 20),

            // Kamera
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _iconTile(Icons.camera_alt_rounded, _accent),
              title: Text('Ambil dari Kamera',
                  style: _p(size: 14, weight: FontWeight.w500)),
              onTap: () async {
                Navigator.pop(context);
                final XFile? foto = await _picker.pickImage(
<<<<<<< Updated upstream
                  source: ImageSource.camera,
                  imageQuality: 80,
                );
=======
                    source: ImageSource.camera, imageQuality: 80);
>>>>>>> Stashed changes
                if (foto != null) setState(() => _currentFotoPath = foto.path);
              },
            ),
            const Divider(),

            // Galeri
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _iconTile(Icons.photo_library_rounded, _accent),
              title: Text('Pilih dari Galeri',
                  style: _p(size: 14, weight: FontWeight.w500)),
              onTap: () async {
                Navigator.pop(context);
                final XFile? foto = await _picker.pickImage(
<<<<<<< Updated upstream
                  source: ImageSource.gallery,
                  imageQuality: 80,
                );
=======
                    source: ImageSource.gallery, imageQuality: 80);
>>>>>>> Stashed changes
                if (foto != null) setState(() => _currentFotoPath = foto.path);
              },
            ),

            // Hapus foto
            if (_currentFotoPath != null) ...[
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _iconTile(
                    Icons.delete_outline_rounded, Colors.red.shade400,
                    bg: Colors.red.shade50),
                title: Text('Hapus Foto',
                    style: _p(
                        size: 14,
                        weight: FontWeight.w500,
                        color: Colors.red.shade400)),
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

<<<<<<< Updated upstream
  Widget _iconTile(IconData icon, Color iconColor, {Color? bg}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bg ?? _accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: iconColor, size: 22),
    );
=======
  // ── Upload foto ke Firebase Storage ──────────────────────────────────────────
  Future<String?> _uploadFoto(String filePath) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final file = File(filePath);
      final ref  = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('${user.uid}.jpg');

      setState(() => _isUploading = true);
      final uploadTask = await ref.putFile(file);
      final url = await uploadTask.ref.getDownloadURL();
      return url;
    } catch (e) {
      return null;
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ── Simpan ke Firestore + Firebase Storage ────────────────────────────────────
  void _simpan() async {
    setState(() => _isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      // Upload foto baru ke Firebase Storage kalau ada perubahan foto
      String? newFotoUrl = _fotoUrl;
      if (_currentFotoPath != null && _currentFotoPath != _savedFotoPath) {
        newFotoUrl = await _uploadFoto(_currentFotoPath!);
      }

      // Simpan nama, telepon, dan foto URL ke Firestore
      if (user != null) {
        final Map<String, dynamic> updateData = {
          'fullName': _namaController.text.trim(),
          'phone'   : _teleponController.text.trim(),
        };
        if (newFotoUrl != null) {
          updateData['fotoUrl'] = newFotoUrl;
        }
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update(updateData);
      }

      setState(() {
        _savedNama     = _namaController.text.trim();
        _savedEmail    = _emailController.text.trim();
        _savedTelepon  = _teleponController.text.trim();
        _savedFotoPath = _currentFotoPath;
        _fotoUrl       = newFotoUrl;
      });

      if (mounted) {
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan. Coba lagi.',
                style: _p(size: 13, color: Colors.white)),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
>>>>>>> Stashed changes
  }

  // ── Upload ke Cloudinary ──────────────────────────────────────────────────
  Future<String?> _uploadToCloudinary(String localPath) async {
    final cloudinary = CloudinaryPublic(
      _cloudName,
      _uploadPreset,
      cache: false,
    );

    final response = await cloudinary.uploadFile(
      CloudinaryFile.fromFile(
        localPath,
        folder: 'profile_photos',
        resourceType: CloudinaryResourceType.Image,
      ),
    );

    return response.secureUrl;
  }

  // ── Simpan ────────────────────────────────────────────────────────────────
  Future<void> _simpan() async {
    if (_isLoading) return;

    final nama    = _namaController.text.trim();
    final email   = _emailController.text.trim();
    final telepon = _teleponController.text.trim();

    setState(() => _isLoading = true);

    String? fotoUrl = _savedFotoPath; // default: pakai URL lama

    // Upload ke Cloudinary hanya kalau ada foto baru (path lokal)
    if (_isLocalFile) {
      try {
        fotoUrl = await _uploadToCloudinary(_currentFotoPath!);
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal upload foto: $e',
                  style: _p(size: 13, color: Colors.white)),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
        return;
      }
    }

    // Jika foto dihapus (null) → hapus juga di Firestore
    if (_currentFotoPath == null) fotoUrl = null;

    // Simpan ke Firestore
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'fullName': nama,
          'phone'   : telepon,
          'photoUrl': fotoUrl ?? FieldValue.delete(),
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan data: $e',
                style: _p(size: 13, color: Colors.white)),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
      return;
    }

    // Update state lokal
    setState(() {
      _savedNama       = nama;
      _savedEmail      = email;
      _savedTelepon    = telepon;
      _savedFotoPath   = fotoUrl;
      _currentFotoPath = fotoUrl;
      _isLoading       = false;
    });

    if (mounted) {
      Navigator.pop<Map<String, String?>>(context, {
        'nama'   : _savedNama,
        'email'  : _savedEmail,
        'telepon': _savedTelepon,
        'foto'   : _savedFotoPath,
      });
    }
  }

  // ── Back handler ──────────────────────────────────────────────────────────
  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges) {
      await showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.5),
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
<<<<<<< Updated upstream
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                      color: Colors.red.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.warning_amber_rounded,
                      color: Colors.red, size: 28),
=======
                  width: 52, height: 52,
                  decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
>>>>>>> Stashed changes
                ),
                const SizedBox(height: 16),
                Text('Simpan perubahan?',
                    style: _p(size: 16, weight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Anda memiliki perubahan yang\nbelum disimpan.',
                    textAlign: TextAlign.center,
                    style: _p(size: 13, color: Colors.grey.shade600)),
                const SizedBox(height: 22),

                // Ya — simpan dulu lalu keluar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
<<<<<<< Updated upstream
                      _simpan(); // simpan + otomatis pop setelah selesai
=======
                      _savedNama     = _namaController.text.trim();
                      _savedEmail    = _emailController.text.trim();
                      _savedTelepon  = _teleponController.text.trim();
                      _savedFotoPath = _currentFotoPath;
                      Navigator.pop<Map<String, String?>>(context, {
                        'nama'   : _savedNama,
                        'email'  : _savedEmail,
                        'telepon': _savedTelepon,
                        'foto'   : _savedFotoPath,
                        'fotoUrl': _fotoUrl,
                      });
>>>>>>> Stashed changes
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
<<<<<<< Updated upstream
                    child: Text('Ya',
                        style: _p(
                            size: 14,
                            weight: FontWeight.w600,
                            color: Colors.white)),
=======
                    child: Text('Ya', style: _p(size: 14, weight: FontWeight.w600, color: Colors.white)),
>>>>>>> Stashed changes
                  ),
                ),
                const SizedBox(height: 10),

                // Tidak — buang perubahan, keluar
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
                        'fotoUrl': _fotoUrl,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F1F1),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
<<<<<<< Updated upstream
                    child: Text('Tidak',
                        style: _p(
                            size: 14,
                            weight: FontWeight.w500,
                            color: _textDark)),
=======
                    child: Text('Tidak', style: _p(size: 14, weight: FontWeight.w500, color: _textDark)),
>>>>>>> Stashed changes
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
      'fotoUrl': _fotoUrl,
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
          child: Stack(
            children: [
              Column(
                children: [
                  // ── Top Bar ──────────────────────────────────────────────
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 4),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_rounded,
                                color: _primaryDark),
                            onPressed: _onWillPop,
                          ),
                        ),
                        Text('Informasi Pribadi',
                            style: _p(size: 17, weight: FontWeight.w600)),
                      ],
                    ),
<<<<<<< Updated upstream
                  ),
=======
                    Text('Informasi Pribadi', style: _p(size: 17, weight: FontWeight.w600)),
                  ],
                ),
              ),
>>>>>>> Stashed changes

                  // ── Form ─────────────────────────────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 32),

<<<<<<< Updated upstream
                          // Avatar
                          Center(
                            child: GestureDetector(
                              onTap: _isLoading ? null : _pilihFoto,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey.shade200,
                                      border: _isLocalFile
                                          ? Border.all(
                                              color: Colors.orange,
                                              width: 3)
                                          : null,
                                    ),
                                    child: ClipOval(
                                      child: _buildFotoWidget(),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: _accent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white,
                                            width: 2),
                                      ),
                                      child: const Icon(
                                          Icons.edit_rounded,
                                          size: 16,
                                          color: Colors.white),
                                    ),
                                  ),
                                ],
=======
                      // Avatar
                      Center(
                        child: GestureDetector(
                          onTap: _isUploading ? null : _pilihFoto,
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
                                  child: _isUploading
                                      ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                                      : _currentFotoPath != null
                                          ? Image.file(File(_currentFotoPath!), fit: BoxFit.cover)
                                          : _fotoUrl != null
                                              ? Image.network(_fotoUrl!, fit: BoxFit.cover)
                                              : const Icon(Icons.person, size: 56, color: Colors.grey),
                                ),
                              ),
                              Positioned(
                                bottom: 0, right: 0,
                                child: Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(
                                    color: _accent, shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                                ),
>>>>>>> Stashed changes
                              ),
                            ),
                          ),
<<<<<<< Updated upstream
                          const SizedBox(height: 8),
                          Center(
                            child: Text('Ganti Foto Profil',
                                style: _p(size: 13, color: _accent)),
=======
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(child: Text('Ganti Foto Profil', style: _p(size: 13, color: _accent))),
                      if (_currentFotoPath != _savedFotoPath)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('⚠ Foto belum disimpan',
                                style: _p(size: 11, color: Colors.orange.shade700)),
>>>>>>> Stashed changes
                          ),
                          if (_isLocalFile)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('⚠ Foto belum disimpan',
                                    style: _p(
                                        size: 11,
                                        color:
                                            Colors.orange.shade700)),
                              ),
                            ),
                          const SizedBox(height: 32),

                          // Nama Lengkap
                          Text('Nama Lengkap',
                              style: _p(
                                  size: 13,
                                  weight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _namaController,
                            hint: 'Masukkan nama lengkap',
                            suffix: Icon(Icons.person_outline_rounded,
                                color: Colors.grey.shade400, size: 20),
                          ),
                          const SizedBox(height: 20),

                          // Email
                          Text('Email',
                              style: _p(
                                  size: 13,
                                  weight: FontWeight.w500)),
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
                          Text('Nomor Telepon',
                              style: _p(
                                  size: 13,
                                  weight: FontWeight.w500)),
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

                  // ── Tombol Simpan ─────────────────────────────────────────
                  Container(
                    padding:
                        const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    color: _bgColor,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _simpan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          disabledBackgroundColor:
                              _accent.withOpacity(0.6),
                          padding: const EdgeInsets.symmetric(
                              vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                ),
                              )
                            : Text('Simpan',
                                style: _p(
                                    size: 15,
                                    weight: FontWeight.w600,
                                    color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),

              // ── Full-screen loading overlay ───────────────────────────────
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.25),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                              color: _accent),
                          const SizedBox(height: 16),
                          Text(
                            _isLocalFile
                                ? 'Mengupload foto...'
                                : 'Menyimpan data...',
                            style: _p(size: 14, weight: FontWeight.w500),
                          ),
                        ],
                      ),
<<<<<<< Updated upstream
                    ),
=======
                      const SizedBox(height: 20),

                      // Email (read only)
                      Text('Email', style: _p(size: 13, weight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _emailController,
                        hint: 'Masukkan email',
                        keyboardType: TextInputType.emailAddress,
                        readOnly: true, // email tidak bisa diubah
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
                    onPressed: _isUploading ? null : _simpan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Simpan',
                            style: _p(size: 15, weight: FontWeight.w600, color: Colors.white)),
>>>>>>> Stashed changes
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
    bool readOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: readOnly ? Colors.grey.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(12),
<<<<<<< Updated upstream
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
=======
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 6, offset: const Offset(0, 2))],
>>>>>>> Stashed changes
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
<<<<<<< Updated upstream
        enabled: !_isLoading,
        style: _p(size: 14),
=======
        readOnly: readOnly,
        style: _p(size: 14, color: readOnly ? Colors.grey.shade500 : _textDark),
>>>>>>> Stashed changes
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: _p(size: 14, color: Colors.grey.shade400),
          suffixIcon: suffix,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          filled: true,
<<<<<<< Updated upstream
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
=======
          fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
>>>>>>> Stashed changes
        ),
      ),
    );
  }
}