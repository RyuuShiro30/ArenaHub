import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;
import 'package:http_parser/http_parser.dart';

import '../sidebar.dart';
import '../admin_notifiers.dart';

class ProfileAdminScreen extends StatefulWidget {
  final void Function(bool)? onChangesUpdated; 
  const ProfileAdminScreen({super.key, this.onChangesUpdated});
  @override
  State<ProfileAdminScreen> createState() => _ProfileAdminScreenState();
}

class _ProfileAdminScreenState extends State<ProfileAdminScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth      = FirebaseAuth.instance;

  static const String _cloudName    = 'dewncgzjd';
  static const String _uploadPreset = 'admin_profile';

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

  final _namaController  = TextEditingController();
  final _emailController = TextEditingController();
  final _sandiController = TextEditingController();

  bool    _obscureSandi  = true;
  bool    _loading       = true;
  bool    _saving        = false;
  bool    _uploadingFoto = false;

  String  _namaAwal   = '';
  String  _emailAwal  = '';
  String  _adminName  = 'Admin';
  String  _adminRole  = 'Administrator';
  String  _status     = 'Aktif';
  String  _level      = 'Super';
  String? _adminDocId;
  String? _fotoUrl;

  bool get _adaPerubahan =>
      _namaController.text.trim() != _namaAwal ||
      _sandiController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _fetchAdminProfile();
    _namaController.addListener(_notifyChanges);
    _sandiController.addListener(_notifyChanges);
  }

  void _notifyChanges() {
    widget.onChangesUpdated?.call(_adaPerubahan);
    // Update notifier global agar sidebar bisa membacanya
    adminHasUnsavedChangesNotifier.value = _adaPerubahan;
  }

  @override
  void dispose() {
    // Reset notifier saat halaman ini ditutup
    adminHasUnsavedChangesNotifier.value = false;
    _namaController.dispose();
    _emailController.dispose();
    _sandiController.dispose();
    super.dispose();
  }

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
            _emailAwal = data['email']    ?? '';
            _status    = _formatStatus(data['status'] ?? 'active');
            _level     = data['level']   ?? 'Super';
            _adminName = _namaAwal;
            _adminRole = _level;
            _fotoUrl   = data['photoUrl'] as String?;
            _namaController.text  = _namaAwal;
            _emailController.text = _emailAwal;
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatStatus(String s) {
    switch (s.toLowerCase()) {
      case 'active': case 'aktif': return 'Aktif';
      case 'inactive': case 'nonaktif': return 'Nonaktif';
      default: return s;
    }
  }

  Future<void> _pilihDanUploadFoto() async {
    setState(() => _uploadingFoto = true);

    try {
      final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
      uploadInput.click();

      await uploadInput.onChange.first;
      if (uploadInput.files == null || uploadInput.files!.isEmpty) {
        setState(() => _uploadingFoto = false);
        return;
      }

      final file   = uploadInput.files!.first;
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;

      final bytes  = reader.result as List<int>;
      final uri    = Uri.parse(
          'https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'admin_photo.jpg',
          contentType: MediaType('image', 'jpeg'),
        ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final url  = data['secure_url'] as String;

        if (_adminDocId != null) {
          await _firestore
              .collection('admin_profile')
              .doc(_adminDocId)
              .update({
            'photoUrl' : url,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        if (mounted) {
          setState(() {
            _fotoUrl       = url;
            _uploadingFoto = false;
          });
          adminPhotoNotifier.value = url;
          _showSnackBar('Foto profil berhasil diperbarui!');
        }
      } else {
        print('CLOUDINARY ERROR: ${response.body}');
        throw Exception('Upload gagal: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingFoto = false);
        _showSnackBar('Gagal upload foto: $e', isError: true);
      }
    }
  }

  Future<void> _hapusFoto() async {
    // Tidak ada foto untuk dihapus
    if (_fotoUrl == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: _red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete_outline_rounded, color: _red, size: 26),
        ),
        title: Text('Hapus Foto Profil?',
            style: _t(size: 16, weight: FontWeight.w700),
            textAlign: TextAlign.center),
        content: Text(
          'Foto profil akan dihapus dan diganti dengan avatar default.',
          style: _t(size: 13, color: _muted),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _border),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Batal', style: _t(size: 13, weight: FontWeight.w600, color: _muted)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Hapus', style: _t(size: 13, weight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _uploadingFoto = true);
    try {
      if (_adminDocId != null) {
        await _firestore
            .collection('admin_profile')
            .doc(_adminDocId)
            .update({
          'photoUrl' : FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      if (mounted) {
        setState(() {
          _fotoUrl       = null;
          _uploadingFoto = false;
        });
        adminPhotoNotifier.value = null;
        _showSnackBar('Foto profil berhasil dihapus.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingFoto = false);
        _showSnackBar('Gagal menghapus foto: $e', isError: true);
      }
    }
  }

  Future<void> _simpanPerubahan() async {
    if (_saving) return;

    final nama  = _namaController.text.trim();
    final sandi = _sandiController.text.trim();

    if (nama.isEmpty) {
      _showSnackBar('Nama tidak boleh kosong', isError: true);
      return;
    }

    setState(() => _saving = true);

    try {
      if (_adminDocId != null) {
        await _firestore
            .collection('admin_profile')
            .doc(_adminDocId)
            .update({
          'fullName' : nama,
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
          _adminName = nama;
          _sandiController.clear();
          _saving = false;
        });
        _showSnackBar('Profil berhasil diperbarui!');
        adminNameNotifier.value = nama;
        adminRoleNotifier.value = _level;
        widget.onChangesUpdated?.call(false);
        adminHasUnsavedChangesNotifier.value = false;
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
    widget.onChangesUpdated?.call(false);
    adminHasUnsavedChangesNotifier.value = false;
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(isError
              ? Icons.error_outline_rounded
              : Icons.check_circle_rounded,
              color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(msg,
              style: _t(size: 13, color: Colors.white))),
        ]),
        backgroundColor: isError ? _red : _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  TextStyle _t({double size = 14, FontWeight weight = FontWeight.normal,
      Color color = _text, double spacing = 0}) =>
      GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: weight,
          color: color, letterSpacing: spacing);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Row(
        children: [
          const AdminSidebar(currentIndex: 6), // SIDEBAR
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator(color: _blue))
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Profil Saya', style: _t(size: 24, weight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(
                        'Kelola informasi akun dan preferensi keamanan Anda di ArenaHub.',
                        style: _t(size: 14, color: _muted),
                      ),
                      const SizedBox(height: 28),
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
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _blueBg,
                border: Border.all(
                    color: _blue.withOpacity(0.3), width: 3),
              ),
              child: ClipOval(
                child: _uploadingFoto
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: _blue, strokeWidth: 2))
                    : _fotoUrl != null
                        ? Image.network(_fotoUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Icon(Icons.person_rounded,
                                    size: 56,
                                    color: _blue.withOpacity(0.4)))
                        : Icon(Icons.person_rounded,
                            size: 56,
                            color: _blue.withOpacity(0.4)),
              ),
            ),
            // Tombol pensil — kanan bawah, membuka popup menu
            Positioned(
              bottom: 4, right: 4,
              child: _uploadingFoto
                  ? Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: _blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: _white, width: 2.5),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        ),
                      ),
                    )
                  : PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'ganti') _pilihDanUploadFoto();
                        if (value == 'hapus') _hapusFoto();
                      },
                      offset: const Offset(0, -100),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 6,
                      color: _white,
                      tooltip: 'Edit foto profil',
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'ganti',
                          height: 48,
                          child: Row(children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: _blueBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.camera_alt_rounded,
                                  size: 17, color: _blue),
                            ),
                            const SizedBox(width: 10),
                            Text('Ganti Foto',
                                style: _t(size: 13, weight: FontWeight.w600)),
                          ]),
                        ),
                        if (_fotoUrl != null)
                          PopupMenuItem(
                            value: 'hapus',
                            height: 48,
                            child: Row(children: [
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: _red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.delete_outline_rounded,
                                    size: 17, color: _red),
                              ),
                              const SizedBox(width: 10),
                              Text('Hapus Foto',
                                  style: _t(size: 13,
                                      weight: FontWeight.w600, color: _red)),
                            ]),
                          ),
                      ],
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
                            size: 14, color: Colors.white),
                      ),
                    ),
            ),
          ],
        ),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: _blue, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Catatan Keamanan',
                        style: _t(size: 13,
                            weight: FontWeight.w700, color: _blue)),
                    const SizedBox(height: 6),
                    Text(
                      'Pastikan kata sandi Anda memiliki minimal 8 karakter dengan kombinasi angka dan simbol.',
                      style: _t(size: 12, color: _muted, spacing: 0.1),
                    ),
                  ],
                ),
              ),
            ],
          ),
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

  Widget _buildDetailForm() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          _buildEmailReadOnly(),
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

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () async {
                  if (!_adaPerubahan) return;
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      title: Text('Buang Perubahan?',
                          style: _t(size: 16, weight: FontWeight.w700)),
                      content: Text(
                          'Semua perubahan yang belum disimpan akan hilang.',
                          style: _t(size: 13, color: _muted)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Kembali',
                              style: _t(size: 14, color: _muted)),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _red,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('Buang',
                              style: _t(size: 14,
                                  weight: FontWeight.w600,
                                  color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) _batalkan();
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _border),
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
                            strokeWidth: 2, color: Colors.white))
                    : Text('Simpan Perubahan',
                        style: _t(size: 14, weight: FontWeight.w600,
                            color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
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

  Widget _buildEmailReadOnly() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        color: const Color(0xFFF9FAFB), // latar abu-abu
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      child: Row(children: [
        Icon(Icons.email_outlined, size: 20, color: _muted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _emailAwal.isNotEmpty ? _emailAwal : '-',
            style: _t(size: 14, color: _muted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }
}