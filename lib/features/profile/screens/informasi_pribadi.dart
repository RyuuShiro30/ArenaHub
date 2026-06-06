import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

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

  // ── Cloudinary config ─────────────────────────────────────
  static const String _cloudName    = 'dewncgzjd';
  static const String _uploadPreset = 'admin_profile';

  late TextEditingController _namaController;
  late TextEditingController _emailController;
  late TextEditingController _teleponController;

  late String _savedNama;
  late String _savedEmail;
  late String _savedTelepon;

  String? _savedFotoPath;
  String? _currentFotoPath;
  String? _fotoUrl;

  bool _isUploading = false;

  final ImagePicker _picker = ImagePicker();

  bool get _hasUnsavedChanges =>
      _namaController.text != _savedNama ||
      _teleponController.text != _savedTelepon ||
      _currentFotoPath != _savedFotoPath;

  bool get _isLocalFile =>
      _currentFotoPath != null && !_currentFotoPath!.startsWith('http');

  @override
  void initState() {
    super.initState();
    _namaController    = TextEditingController(text: widget.initialNama);
    _emailController   = TextEditingController(text: widget.initialEmail);
    _teleponController = TextEditingController(text: widget.initialTelepon);

    _savedNama       = widget.initialNama;
    _savedEmail      = widget.initialEmail;
    _savedTelepon    = widget.initialTelepon;
    _savedFotoPath   = widget.initialFotoPath;
    _currentFotoPath = widget.initialFotoPath;
    _fotoUrl         = widget.initialFotoPath;

    _namaController.addListener(() => setState(() {}));
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
      fontSize: size, fontWeight: weight,
      color: color, letterSpacing: spacing,
    );
  }

  Widget _iconTile(IconData icon, Color iconColor, {Color? bg}) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: bg ?? _accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: iconColor, size: 22),
    );
  }

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
            child: CircularProgressIndicator(strokeWidth: 2));
      },
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.person, size: 56, color: Colors.grey),
    );
  }

  void _pilihFoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ganti Foto Profil',
                style: _p(size: 16, weight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _iconTile(Icons.camera_alt_rounded, _accent),
              title: Text('Ambil dari Kamera',
                  style: _p(size: 14, weight: FontWeight.w500)),
              onTap: () async {
                Navigator.pop(ctx);
                final foto = await _picker.pickImage(
                    source: ImageSource.camera, imageQuality: 80);
                if (foto != null) {
                  setState(() => _currentFotoPath = foto.path);
                }
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _iconTile(Icons.photo_library_rounded, _accent),
              title: Text('Pilih dari Galeri',
                  style: _p(size: 14, weight: FontWeight.w500)),
              onTap: () async {
                Navigator.pop(ctx);
                final foto = await _picker.pickImage(
                    source: ImageSource.gallery, imageQuality: 80);
                if (foto != null) {
                  setState(() => _currentFotoPath = foto.path);
                }
              },
            ),
            if (_currentFotoPath != null) ...[
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _iconTile(Icons.delete_outline_rounded,
                    Colors.red.shade400,
                    bg: Colors.red.shade50),
                title: Text('Hapus Foto',
                    style: _p(
                        size: 14,
                        weight: FontWeight.w500,
                        color: Colors.red.shade400)),
                onTap: () {
                  Navigator.pop(ctx);
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

  // ── Upload ke Cloudinary ──────────────────────────────────
  Future<String?> _uploadFotoCloudinary(String filePath) async {
    try {
      final file  = File(filePath);
      final bytes = await file.readAsBytes();
      final ext   = filePath.split('.').last.toLowerCase();

      final uri     = Uri.parse(
          'https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'user_photo.$ext',
          contentType: MediaType('image', ext),
        ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['secure_url'] as String;
      } else {
        debugPrint('Cloudinary error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  Future<void> _simpan() async {
    setState(() => _isUploading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      String? newFotoUrl = _fotoUrl;

      // Upload ke Cloudinary hanya jika foto baru dipilih (file lokal)
      if (_isLocalFile && _currentFotoPath != null) {
        newFotoUrl = await _uploadFotoCloudinary(_currentFotoPath!);
        if (newFotoUrl == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Gagal mengupload foto, coba lagi.',
                  style: _p(size: 13, color: Colors.white)),
              backgroundColor: Colors.red.shade600,
            ));
          }
          setState(() => _isUploading = false);
          return;
        }
      }

      // Simpan ke Firestore
      if (user != null) {
        final updateData = <String, dynamic>{
          'fullName': _namaController.text.trim(),
          'phone'   : _teleponController.text.trim(),
        };

        if (_currentFotoPath == null) {
          updateData['photoUrl'] = FieldValue.delete();
        } else if (newFotoUrl != null) {
          updateData['photoUrl'] = newFotoUrl;
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update(updateData);
      }

      // Update state lokal agar UI langsung reflect perubahan
      setState(() {
        _savedNama       = _namaController.text.trim();
        _savedEmail      = _emailController.text.trim();
        _savedTelepon    = _teleponController.text.trim();
        _savedFotoPath   = newFotoUrl;
        _currentFotoPath = newFotoUrl;
        _fotoUrl         = newFotoUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Perubahan berhasil disimpan!',
              style: _p(size: 13, color: Colors.white)),
          backgroundColor: _accent,
        ));
        // Kirim data terbaru ke halaman sebelumnya (profil/homescreen)
        Navigator.pop(context, {
          'nama'   : _savedNama,
          'email'  : _savedEmail,
          'telepon': _savedTelepon,
          'foto'   : _fotoUrl,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal menyimpan data: $e',
              style: _p(size: 13, color: Colors.white)),
          backgroundColor: Colors.red.shade600,
        ));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Perubahan belum disimpan',
            style: _p(size: 16, weight: FontWeight.w700)),
        content: Text(
            'Kamu memiliki perubahan yang belum disimpan. Yakin ingin keluar?',
            style: _p(size: 13, color: Colors.grey.shade600)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: _p(size: 14, color: _accent)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('Keluar',
                style: _p(size: 14,
                    weight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: _bgColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: _primaryDark),
          title: Text('Informasi Pribadi',
              style: _p(size: 16, weight: FontWeight.w600)),
          actions: [
            if (_hasUnsavedChanges)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: Colors.orange.shade200),
                    ),
                    child: Text('Belum disimpan',
                        style: _p(
                            size: 11,
                            weight: FontWeight.w600,
                            color: Colors.orange.shade700)),
                  ),
                ),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // ── Avatar ────────────────────────────────────
              GestureDetector(
                onTap: _pilihFoto,
                child: Column(children: [
                  Stack(children: [
                    Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade200,
                        border: _currentFotoPath != _savedFotoPath
                            ? Border.all(
                                color: Colors.orange, width: 2.5)
                            : null,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildFotoWidget(),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                            color: _accent, shape: BoxShape.circle),
                        child: const Icon(Icons.edit,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Text('Ganti Foto Profil',
                      style: _p(
                          size: 13,
                          color: _primaryDark,
                          weight: FontWeight.w500)),
                ]),
              ),

              const SizedBox(height: 28),

              _buildField(
                label: 'Nama Lengkap',
                controller: _namaController,
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 16),

              _buildField(
                label: 'Email',
                controller: _emailController,
                icon: Icons.email_outlined,
                enabled: false,
              ),
              const SizedBox(height: 16),

              _buildField(
                label: 'Nomor Telepon',
                controller: _teleponController,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 32),

              AnimatedOpacity(
                opacity: _hasUnsavedChanges ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (_isUploading || !_hasUnsavedChanges)
                        ? null
                        : _simpan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      disabledBackgroundColor:
                          _accent.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isUploading
                        ? const CircularProgressIndicator(
                            color: Colors.white)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_hasUnsavedChanges) ...[
                                const Icon(Icons.save_rounded,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                              ],
                              Text('Simpan',
                                  style: _p(
                                      size: 14,
                                      weight: FontWeight.w600,
                                      color: Colors.white)),
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isChanged = enabled &&
        ((controller == _namaController &&
                controller.text != _savedNama) ||
            (controller == _teleponController &&
                controller.text != _savedTelepon));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(label,
              style: _p(
                  size: 13,
                  weight: FontWeight.w600,
                  color: _primaryDark)),
          if (isChanged) ...[
            const SizedBox(width: 6),
            Container(
              width: 6, height: 6,
              decoration: const BoxDecoration(
                  color: Colors.orange, shape: BoxShape.circle),
            ),
          ],
        ]),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isChanged
                  ? Colors.orange.shade300
                  : Colors.grey.shade200,
              width: isChanged ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            style: _p(
                size: 14,
                color: enabled ? _textDark : Colors.grey.shade400),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              suffixIcon: Icon(icon,
                  color: isChanged
                      ? Colors.orange.shade400
                      : Colors.grey.shade400,
                  size: 20),
            ),
          ),
        ),
      ],
    );
  }
}