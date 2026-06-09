import 'package:flutter/material.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../admin_notifiers.dart';
import '../auth/login.dart';
import 'kelola_lapangan.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../sidebar.dart'; // IMPORT SIDEBAR BARU

class AddFieldScreen extends StatefulWidget {
  final FieldItem? fieldToEdit;

  const AddFieldScreen({super.key, this.fieldToEdit});

  @override
  State<AddFieldScreen> createState() => _AddFieldScreenState();
}

class _AddFieldScreenState extends State<AddFieldScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String? _selectedType;

  bool _isStatusOn = true;
  int _selectedJamMulaiHour = 6;
  int _selectedJamSelesaiHour = 21;
  String _selectedJenisLantai = 'Lantai Kayu';
  final TextEditingController _kapasitasController = TextEditingController();
  final TextEditingController _lokasiController = TextEditingController();
  bool _isUploading = false;
  bool _isSaving = false;

  final List<String> _uploadedImages = [];

  final List<Map<String, dynamic>> _facilities = [
    {'icon': Icons.wifi, 'label': 'WiFi'},
    {'icon': Icons.water_drop_outlined, 'label': 'Air Minum'},
    {'icon': Icons.door_sliding_outlined, 'label': 'Ruang Ganti'},
    {'icon': Icons.local_parking, 'label': 'Parkir Luas'},
  ];

  final List<String> _tipeLapangan = [
    'Futsal Rumput',
    'Futsal Sintetis',
    'Badminton',
    'Basket',
    'Tennis',
    'Padel'
  ];
  
  final List<String> _daftarJenisLantai = [
    'Lantai Kayu',
    'Vinyl',
    'Interlock',
    'Karet',
    'Rumput Sintetis',
    'Terazzo Epoxy',
    'Hard Court',
  ];
  
  final ImagePicker _picker = ImagePicker();
  final String cloudName = "dewncgzjd";
  final String uploadPreset = "add_field";
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool get _isEditMode => widget.fieldToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final f = widget.fieldToEdit!;
      _nameController.text = f.name;
      _priceController.text = f.price.toString();
      _descController.text = f.description;
      _selectedType = _tipeLapangan.contains(f.type) ? f.type : null;
      _isStatusOn = f.status == 'Aktif';
      _selectedJamMulaiHour = f.jamBuka;
      _selectedJamSelesaiHour = f.jamTutup;
      _selectedJenisLantai = _daftarJenisLantai.contains(f.jenisFloor)
          ? f.jenisFloor
          : 'Lantai Kayu';
      _kapasitasController.text = f.kapasitas > 0 ? f.kapasitas.toString() : '';
      _lokasiController.text = f.lokasi;
      _uploadedImages.addAll(f.images);

      if (f.fasilitas.isNotEmpty) {
        _facilities.clear();
        for (final label in f.fasilitas) {
          _facilities.add({
            'icon': _getIconFromKeyword(label),
            'label': label,
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _kapasitasController.dispose();
    _lokasiController.dispose();
    super.dispose();
  }

  // PENGECEKAN PERUBAHAN DATA UNTUK MODE EDIT
  bool _checkIfChanged() {
    if (!mounted || widget.fieldToEdit == null) return false;
    final f = widget.fieldToEdit!;
    
    final currentPrice = int.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final currentCapacity = int.tryParse(_kapasitasController.text) ?? 0;
    final currentStatus = _isStatusOn ? 'Aktif' : 'Non-Aktif';
    final currentFacilities = _facilities.map((fac) => fac['label'].toString()).toList();
    
    bool facilitiesChanged = currentFacilities.join(',') != f.fasilitas.join(',');
    bool imagesChanged = _uploadedImages.join(',') != f.images.join(',');

    if (_nameController.text != f.name ||
        _selectedType != f.type ||
        currentPrice != f.price ||
        _descController.text != f.description ||
        currentStatus != f.status ||
        _selectedJamMulaiHour != f.jamBuka ||
        _selectedJamSelesaiHour != f.jamTutup ||
        _selectedJenisLantai != f.jenisFloor ||
        currentCapacity != f.kapasitas ||
        _lokasiController.text != f.lokasi ||
        facilitiesChanged ||
        imagesChanged) {
      return true;
    }
    return false;
  }

  // FUNGSI LOG AKTIVITAS
  Future<void> _logActivity(String type, String title, String subtitle, String fieldType) async {
    await FirebaseFirestore.instance.collection('aktivitas_lapangan').add({
      'activity_type': type,
      'title': title,
      'subtitle': subtitle,
      'field_type': fieldType,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  IconData _getIconFromKeyword(String text) {
    String cleanText = text.toLowerCase();
    if (cleanText.contains('wifi') || cleanText.contains('internet')) {
      return Icons.wifi;
    }
    if (cleanText.contains('minum') ||
        cleanText.contains('air') ||
        cleanText.contains('water')) {
      return Icons.water_drop_outlined;
    }
    if (cleanText.contains('ganti') || cleanText.contains('baju')) {
      return Icons.door_sliding_outlined;
    }
    if (cleanText.contains('parkir') || cleanText.contains('mobil')) {
      return Icons.local_parking;
    }
    if (cleanText.contains('kantin') ||
        cleanText.contains('makan') ||
        cleanText.contains('kafe')) {
      return Icons.restaurant;
    }
    if (cleanText.contains('musala') ||
        cleanText.contains('sholat') ||
        cleanText.contains('mesjid')) {
      return Icons.mosque;
    }
    if (cleanText.contains('toilet') ||
        cleanText.contains('wc') ||
        cleanText.contains('kamar mandi')) {
      return Icons.wc;
    }
    if (cleanText.contains('shower')) return Icons.shower;
    if (cleanText.contains('ac') || cleanText.contains('kipas')) {
      return Icons.ac_unit;
    }
    if (cleanText.contains('tribun') || cleanText.contains('duduk'))
    if (cleanText.contains('net') || cleanText.contains('raket'))
    if (cleanText.contains('bola') || cleanText.contains('ball'))
    if (cleanText.contains('lampu') || cleanText.contains('lighting')) 
    if (cleanText.contains('ring') || cleanText.contains('audio')){
      return Icons.chair;
    }
    return Icons.star_border_rounded;
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      String? mimeType = lookupMimeType(image.path);
      mimeType ??= 'image/jpeg';
      final mimeTypeData = mimeType.split('/');

      final cloudinaryUrl =
          Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

      final request = http.MultipartRequest("POST", cloudinaryUrl);
      request.fields['upload_preset'] = uploadPreset;

      final bytes = await image.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: image.name,
          contentType: MediaType(
            mimeTypeData[0],
            mimeTypeData.length > 1 ? mimeTypeData[1] : 'jpeg',
          ),
        ),
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final data = json.decode(responseData);
        final imageUrl = data['secure_url'];
        setState(() => _uploadedImages.add(imageUrl));
        _showUploadStatusPopup(true);
      } else {
        _showUploadStatusPopup(false);
      }
    } catch (e) {
      debugPrint("UPLOAD ERROR: $e");
      _showUploadStatusPopup(false);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showUploadStatusPopup(bool isSuccess) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSuccess ? Colors.green[50] : Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess
                      ? Icons.check_circle_rounded
                      : Icons.error_outline_rounded,
                  size: 54,
                  color: isSuccess ? Colors.green[600] : Colors.red[600],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isSuccess ? "Unggah Berhasil!" : "Unggah Gagal!",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSuccess ? Colors.green[800] : Colors.red[800],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isSuccess
                    ? "Foto lapangan berhasil diupload ke Cloudinary."
                    : "Koneksi gagal atau upload bermasalah.",
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isSuccess ? Colors.green[600] : Colors.red[600],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text("Mengerti",
                      style: GoogleFonts.plusJakartaSans(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showAddFacilityDialog() {
    TextEditingController facilityController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.add_box_rounded, color: Colors.blue[700]),
            const SizedBox(width: 8),
            Text("Tambah Fasilitas",
                style:
                    GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ],
        ),
        content: TextField(
          controller: facilityController,
          decoration: InputDecoration(
            labelText: "Nama Fasilitas",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              if (facilityController.text.isNotEmpty) {
                setState(() {
                  _facilities.add({
                    'icon': _getIconFromKeyword(facilityController.text),
                    'label': facilityController.text,
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Simpan"),
          )
        ],
      ),
    );
  }

  void _showInteractiveTimePickerDialog() {
    int tempTutup = _selectedJamSelesaiHour;
    int tempBuka = _selectedJamMulaiHour;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Jam Operasional",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text("BUKA"),
                          DropdownButton<int>(
                            value: tempBuka,
                            items: List.generate(
                                24,
                                (i) => DropdownMenuItem(
                                    value: i, child: Text("$i:00"))),
                            onChanged: (v) =>
                                setDialogState(() => tempBuka = v!),
                          ),
                        ],
                      ),
                    ),
                    const Text("-"),
                    Expanded(
                      child: Column(
                        children: [
                          const Text("TUTUP"),
                          DropdownButton<int>(
                            value: tempTutup,
                            items: List.generate(
                                24,
                                (i) => DropdownMenuItem(
                                    value: i, child: Text("$i:00"))),
                            onChanged: (v) =>
                                setDialogState(() => tempTutup = v!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedJamMulaiHour = tempBuka;
                      _selectedJamSelesaiHour = tempTutup;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("Terapkan"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _redirectToKelolaLapangan() {
    Navigator.pop(context); // MENGGUNAKAN POP AGAR TIDAK MERUSAK STATE SEBELUMNYA
  }

  Future<void> _saveField() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      try {
        final data = {
          'nama_lapangan': _nameController.text,
          'jenis_lapangan': _selectedType ?? 'Lainnya',
          'harga': int.tryParse(
                  _priceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
              0,
          'deskripsi_lapangan': _descController.text,
          'status': _isStatusOn ? 'Aktif' : 'Non-Aktif',
          'jam_buka': _selectedJamMulaiHour,
          'jam_tutup': _selectedJamSelesaiHour,
          'jenis_floor': _selectedJenisLantai,
          'kapasitas': int.tryParse(_kapasitasController.text) ?? 0,
          'lokasi': _lokasiController.text,
          'foto': _uploadedImages,
          'fasilitas': _facilities.map((f) => f['label']).toList(),
        };

        if (_isEditMode) {
          if (!_checkIfChanged()) {
            // Jika tidak ada perubahan, langsung kembali tanpa eksekusi database
            Navigator.pop(context);
            return;
          }
          data['updated_at'] = FieldValue.serverTimestamp();
          await _firestore
              .collection('lapangan')
              .doc(widget.fieldToEdit!.id)
              .update(data);
              
          // CATAT AKTIVITAS UPDATE
          await _logActivity(
            'update', 
            'Lapangan diperbarui: ${_nameController.text}', 
            'Admin memperbarui informasi lapangan', 
            _selectedType ?? 'Lainnya'
          );
        } else {
          data['created_at'] = FieldValue.serverTimestamp(); // Agar terhitung pada bulan ini
          await _firestore.collection('lapangan').add(data);
          
          // CATAT AKTIVITAS ADD
          await _logActivity(
            'add', 
            'Lapangan baru ditambahkan: ${_nameController.text}', 
            'Admin menambahkan lapangan ke inventaris', 
            _selectedType ?? 'Lainnya'
          );
        }
        
        if(mounted) Navigator.pop(context, true); // Mengirim trigger reload
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      } finally {
        if(mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
          0xFFF4F6F9), // Background utama Abu-abu sangat muda (Light Mode)
      body: Row(
        children: [
          const AdminSidebar(currentIndex: 5), // SIDEBAR
          Expanded(
            child: Container(
              color: const Color(0xFFF4F6F9), // Latar konten Light Mode
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeaderActionRow(),
                            const SizedBox(height: 32),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    children: [
                                      _buildMainInfoCard(),
                                      const SizedBox(height: 24),
                                      _buildAvailabilityCard(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    children: [
                                      _buildMediaCard(),
                                      const SizedBox(height: 24),
                                      _buildFacilitiesCard(),
                                    ],
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
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

  Widget _buildHeaderActionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditMode ? "Edit Lapangan" : "Tambah Lapangan Baru",
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: const Color(
                      0xFF0F172A)), // TEKS GELAP SESUAI DESAIN TERANG
            ),
            const SizedBox(height: 4),
            Text(
              "Input detail informasi lapangan untuk memperbarui katalog pada tahun 2026.",
              style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF64748B), // TEKS ABU-ABU SESUAI DESAIN
                  fontSize: 14),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton(
              onPressed: _redirectToKelolaLapangan,
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                      color: Color(0xFFCBD5E1)), // BORDER ABU-ABU
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF475569), // TEKS ABU GELAP
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: Text("Batal",
                  style:
                      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveField,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_alt_rounded,
                      size: 18, color: Colors.white),
              label: Text(
                _isSaving ? "Menyimpan..." : "Simpan Lapangan",
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB), // BIRU UTAMA
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _buildMainInfoCard() {
    return _cardWrapper(
      icon: Icons.info_outline_rounded,
      title: "Informasi Utama",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: _inputLabel("NAMA LAPANGAN", _nameController,
                      hint: "Contoh: Lapangan Utama A")),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("TIPE LAPANGAN", style: _labelStyle()),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedType,
                      items: _tipeLapangan
                          .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedType = v),
                      decoration: _inputDecoration(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _inputLabel("HARGA SEWA (PER JAM)", _priceController,
              hint: "Masukkan harga sewa..."),
          const SizedBox(height: 20),
          _inputLabel("DESKRIPSI LAPANGAN", _descController,
              hint: "Masukkan deskripsi fasilitas dan kondisi lapangan...",
              maxLines: 4),
        ],
      ),
    );
  }

  Widget _buildAvailabilityCard() {
    return _cardWrapper(
      icon: Icons.event_available_rounded,
      title: "Ketersediaan",
      trailing: Row(
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: Color(0xFF22C55E), shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text("Aktif",
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF22C55E))),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("JAM OPERASIONAL", style: _labelStyle()),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _showInteractiveTimePickerDialog,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                "${_selectedJamMulaiHour.toString().padLeft(2, '0')}:00 - ${_selectedJamSelesaiHour.toString().padLeft(2, '0')}:00 WIB",
                                style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF334155))),
                            const Icon(Icons.keyboard_arrow_down,
                                size: 20, color: Color(0xFF64748B)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("JENIS LANTAI", style: _labelStyle()),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedJenisLantai,
                      items: _daftarJenisLantai
                          .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedJenisLantai = v!),
                      decoration: _inputDecoration(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _inputLabel("KAPASITAS (ORANG)", _kapasitasController,
                      hint: "Contoh: 10")),
              const SizedBox(width: 16),
              Expanded(
                  child: _inputLabel("LOKASI", _lokasiController,
                      hint: "Contoh: Indoor / Lt. 2")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaCard() {
    return _cardWrapper(
      icon: Icons.image_outlined,
      title: "Media Lapangan",
      child: Column(
        children: [
          GestureDetector(
            onTap: _isUploading ? null : _pickAndUploadImage,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                // BORDER BIRU MUDA UNTUK AREA UPLOAD
                border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
              ),
              child: Column(
                children: [
                  const Icon(Icons.cloud_upload_outlined,
                      color: Color(0xFF2563EB), size: 32),
                  const SizedBox(height: 12),
                  Text("Unggah Foto",
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: const Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  Text(
                      "Drag and drop file atau klik\nuntuk memilih. Maks. 5MB\n(JPG/PNG)",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF94A3B8), fontSize: 11)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _mediaBox(isAdd: true),
              const SizedBox(width: 12),
              // MENAMPILKAN PLACEHOLDER BOX JIKA KOSONG
              if (_uploadedImages.isEmpty) ...[
                _mediaBox(),
                const SizedBox(width: 12),
                _mediaBox(),
              ] else ...[
                ..._uploadedImages.map((img) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _mediaBox(imageUrl: img),
                    )),
              ]
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFacilitiesCard() {
    return _cardWrapper(
      icon: Icons.star_outline_rounded,
      title: "Fasilitas Standar",
      trailing: TextButton.icon(
        onPressed: _showAddFacilityDialog,
        icon: const Icon(Icons.add, size: 16),
        label: const Text("Tambah"),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _facilities
            .map((f) => Chip(
                  backgroundColor: const Color(0xFFEFF6FF),
                  avatar: Icon(f['icon'] as IconData,
                      size: 14, color: const Color(0xFF2563EB)),
                  label: Text(f['label'],
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2563EB))),
                  onDeleted: () => setState(() => _facilities.remove(f)),
                  deleteIcon: const Icon(Icons.close,
                      size: 12, color: Color(0xFF94A3B8)),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ))
            .toList(),
      ),
    );
  }

  Widget _cardWrapper(
      {required IconData icon,
      required String title,
      required Widget child,
      Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: const Color(0xFFE2E8F0)) // Border sangat tipis
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color(0xFF2563EB), size: 20),
                  const SizedBox(width: 10),
                  Text(title,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A))),
                ],
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _inputLabel(String label, TextEditingController controller,
      {String? hint, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle()),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF334155)),
          decoration: _inputDecoration(hint: hint),
          validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
        ),
      ],
    );
  }

  TextStyle _labelStyle() => GoogleFonts.plusJakartaSans(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF94A3B8));

  InputDecoration _inputDecoration({String? hint, Color? fillColor}) =>
      InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: fillColor ?? Colors.white, // Default box putih
        hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8)),
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2563EB))),
      );

  Widget _mediaBox({bool isAdd = false, String? imageUrl}) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0))),
      child: isAdd
          ? const Icon(Icons.add, color: Color(0xFF2563EB))
          : imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(imageUrl, fit: BoxFit.cover))
              : const Icon(Icons.image_outlined, color: Color(0xFFCBD5E1)),
    );
  }
}