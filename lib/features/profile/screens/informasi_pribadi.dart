import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  State<InformasiPribadiScreen> createState() =>
      _InformasiPribadiScreenState();
}

class _InformasiPribadiScreenState
    extends State<InformasiPribadiScreen> {
  static const Color _primaryDark =
      Color(0xFF0D2D6B);

  static const Color _accent =
      Color(0xFF1A4FAF);

  static const Color _bgColor =
      Color(0xFFF4F6F9);

  static const Color _textDark =
      Color(0xFF1A2B3C);

  late TextEditingController
      _namaController;

  late TextEditingController
      _emailController;

  late TextEditingController
      _teleponController;

  late String _savedNama;
  late String _savedEmail;
  late String _savedTelepon;

  String? _savedFotoPath;
  String? _currentFotoPath;
  String? _fotoUrl;

  bool _isUploading = false;

  final ImagePicker _picker =
      ImagePicker();

  bool get _hasUnsavedChanges =>
      _namaController.text !=
          _savedNama ||
      _emailController.text !=
          _savedEmail ||
      _teleponController.text !=
          _savedTelepon ||
      _currentFotoPath !=
          _savedFotoPath;

  bool get _isLocalFile =>
      _currentFotoPath != null &&
      !_currentFotoPath!
          .startsWith('http');

  @override
  void initState() {
    super.initState();

    _namaController =
        TextEditingController(
      text: widget.initialNama,
    );

    _emailController =
        TextEditingController(
      text: widget.initialEmail,
    );

    _teleponController =
        TextEditingController(
      text:
          widget.initialTelepon,
    );

    _savedNama =
        widget.initialNama;

    _savedEmail =
        widget.initialEmail;

    _savedTelepon =
        widget.initialTelepon;

    _savedFotoPath =
        widget.initialFotoPath;

    _currentFotoPath =
        widget.initialFotoPath;

    _fotoUrl =
        widget.initialFotoPath;

    _namaController
        .addListener(
            () => setState(() {}));

    _emailController
        .addListener(
            () => setState(() {}));

    _teleponController
        .addListener(
            () => setState(() {}));
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
    FontWeight weight =
        FontWeight.normal,
    Color color = _textDark,
    double spacing = 0,
  }) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: spacing,
    );
  }

  Widget _iconTile(
    IconData icon,
    Color iconColor, {
    Color? bg,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color:
            bg ??
                _accent
                    .withOpacity(
                        0.1),
        borderRadius:
            BorderRadius.circular(
                10),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 22,
      ),
    );
  }

  Widget _buildFotoWidget() {
    if (_currentFotoPath ==
        null) {
      return const Icon(
        Icons.person,
        size: 56,
        color: Colors.grey,
      );
    }

    if (_isLocalFile) {
      return Image.file(
        File(_currentFotoPath!),
        fit: BoxFit.cover,
      );
    }

    return Image.network(
      _currentFotoPath!,
      fit: BoxFit.cover,
      loadingBuilder:
          (_, child, progress) {
        if (progress == null) {
          return child;
        }

        return const Center(
          child:
              CircularProgressIndicator(
            strokeWidth: 2,
          ),
        );
      },
      errorBuilder:
          (_, __, ___) {
        return const Icon(
          Icons.person,
          size: 56,
          color: Colors.grey,
        );
      },
    );
  }

  void _pilihFoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.white,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (_) => Padding(
        padding:
            const EdgeInsets.all(
                24),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            Text(
              'Ganti Foto Profil',
              style: _p(
                size: 16,
                weight:
                    FontWeight
                        .bold,
              ),
            ),

            const SizedBox(
                height: 20),

            ListTile(
              contentPadding:
                  EdgeInsets.zero,
              leading:
                  _iconTile(
                Icons
                    .camera_alt_rounded,
                _accent,
              ),
              title: Text(
                'Ambil dari Kamera',
                style: _p(
                  size: 14,
                  weight:
                      FontWeight
                          .w500,
                ),
              ),
              onTap: () async {
                Navigator.pop(
                    context);

                final XFile?
                    foto =
                    await _picker
                        .pickImage(
                  source:
                      ImageSource
                          .camera,
                  imageQuality:
                      80,
                );

                if (foto !=
                    null) {
                  setState(() {
                    _currentFotoPath =
                        foto.path;
                  });
                }
              },
            ),

            const Divider(),

            ListTile(
              contentPadding:
                  EdgeInsets.zero,
              leading:
                  _iconTile(
                Icons
                    .photo_library_rounded,
                _accent,
              ),
              title: Text(
                'Pilih dari Galeri',
                style: _p(
                  size: 14,
                  weight:
                      FontWeight
                          .w500,
                ),
              ),
              onTap: () async {
                Navigator.pop(
                    context);

                final XFile?
                    foto =
                    await _picker
                        .pickImage(
                  source:
                      ImageSource
                          .gallery,
                  imageQuality:
                      80,
                );

                if (foto !=
                    null) {
                  setState(() {
                    _currentFotoPath =
                        foto.path;
                  });
                }
              },
            ),

            if (_currentFotoPath !=
                null) ...[
              const Divider(),

              ListTile(
                contentPadding:
                    EdgeInsets.zero,
                leading:
                    _iconTile(
                  Icons
                      .delete_outline_rounded,
                  Colors
                      .red
                      .shade400,
                  bg: Colors
                      .red
                      .shade50,
                ),
                title: Text(
                  'Hapus Foto',
                  style: _p(
                    size: 14,
                    weight:
                        FontWeight
                            .w500,
                    color: Colors
                        .red
                        .shade400,
                  ),
                ),
                onTap: () {
                  Navigator.pop(
                      context);

                  setState(() {
                    _currentFotoPath =
                        null;
                  });
                },
              ),
            ],

            const SizedBox(
                height: 8),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadFoto(
      String filePath) async {
    try {
      final user =
          FirebaseAuth.instance
              .currentUser;

      if (user == null) {
        return null;
      }

      final file =
          File(filePath);

      final ref =
          FirebaseStorage
              .instance
              .ref()
              .child(
                  'profile_photos')
              .child(
                  '${user.uid}.jpg');

      final uploadTask =
          await ref.putFile(
              file);

      final url =
          await uploadTask
              .ref
              .getDownloadURL();

      return url;
    } catch (e) {
      return null;
    }
  }

  Future<void> _simpan() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final user =
          FirebaseAuth.instance
              .currentUser;

      String? newFotoUrl =
          _fotoUrl;

      if (_isLocalFile &&
          _currentFotoPath !=
              null) {
        newFotoUrl =
            await _uploadFoto(
          _currentFotoPath!,
        );
      }

      if (user != null) {
        final Map<String,
                dynamic>
            updateData = {
          'fullName':
              _namaController
                  .text
                  .trim(),
          'phone':
              _teleponController
                  .text
                  .trim(),
        };

        if (_currentFotoPath ==
            null) {
          updateData[
                  'fotoUrl'] =
              FieldValue
                  .delete();
        } else if (newFotoUrl !=
            null) {
          updateData[
                  'fotoUrl'] =
              newFotoUrl;
        }

        await FirebaseFirestore
            .instance
            .collection(
                'users')
            .doc(user.uid)
            .update(updateData);
      }

      setState(() {
        _savedNama =
            _namaController.text
                .trim();

        _savedEmail =
            _emailController.text
                .trim();

        _savedTelepon =
            _teleponController
                .text
                .trim();

        _savedFotoPath =
            newFotoUrl;

        _currentFotoPath =
            newFotoUrl;

        _fotoUrl =
            newFotoUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(
                context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Perubahan berhasil disimpan!',
              style: _p(
                size: 13,
                color: Colors
                    .white,
              ),
            ),
            backgroundColor:
                _accent,
          ),
        );

        Navigator.pop(
          context,
          {
            'nama':
                _savedNama,
            'email':
                _savedEmail,
            'telepon':
                _savedTelepon,
            'foto':
                _fotoUrl,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
                context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menyimpan data',
              style: _p(
                size: 13,
                color: Colors
                    .white,
              ),
            ),
            backgroundColor:
                Colors.red
                    .shade600,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading =
              false;
        });
      }
    }
  }

  @override
  Widget build(
      BuildContext context) {
    return Scaffold(
      backgroundColor:
          _bgColor,
      appBar: AppBar(
        backgroundColor:
            Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme:
            const IconThemeData(
          color: _primaryDark,
        ),
        title: Text(
          'Informasi Pribadi',
          style: _p(
            size: 16,
            weight:
                FontWeight.w600,
          ),
        ),
      ),
      body:
          SingleChildScrollView(
        padding:
            const EdgeInsets.all(
                20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pilihFoto,
              child: Stack(
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration:
                        BoxDecoration(
                      shape: BoxShape
                          .circle,
                      color: Colors
                          .grey
                          .shade200,
                    ),
                    clipBehavior:
                        Clip.antiAlias,
                    child:
                        _buildFotoWidget(),
                  ),

                  Positioned(
                    bottom: 0,
                    right: 0,
                    child:
                        Container(
                      padding:
                          const EdgeInsets
                              .all(8),
                      decoration:
                          BoxDecoration(
                        color:
                            _accent,
                        shape: BoxShape
                            .circle,
                      ),
                      child:
                          const Icon(
                        Icons.edit,
                        size: 16,
                        color: Colors
                            .white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
                height: 30),

            TextField(
              controller:
                  _namaController,
              decoration:
                  const InputDecoration(
                labelText:
                    'Nama Lengkap',
              ),
            ),

            const SizedBox(
                height: 18),

            TextField(
              controller:
                  _emailController,
              enabled: false,
              decoration:
                  const InputDecoration(
                labelText:
                    'Email',
              ),
            ),

            const SizedBox(
                height: 18),

            TextField(
              controller:
                  _teleponController,
              decoration:
                  const InputDecoration(
                labelText:
                    'Nomor Telepon',
              ),
            ),

            const SizedBox(
                height: 32),

            SizedBox(
              width:
                  double.infinity,
              height: 52,
              child:
                  ElevatedButton(
                onPressed:
                    _isUploading
                        ? null
                        : _simpan,
                style:
                    ElevatedButton
                        .styleFrom(
                  backgroundColor:
                      _accent,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                            14),
                  ),
                ),
                child:
                    _isUploading
                        ? const CircularProgressIndicator(
                            color: Colors
                                .white,
                          )
                        : Text(
                            'Simpan',
                            style: _p(
                              size: 14,
                              weight:
                                  FontWeight.w600,
                              color: Colors
                                  .white,
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}