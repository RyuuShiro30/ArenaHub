import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import '../dashboard/dashboardAdmin.dart';
import 'kelola_lapangan.dart';
import '../booking/kelola_booking.dart'; 
import '../kelola_jadwal/kelolaJadwal.dart';
import '../promo/kelola_promo.dart';
import '../profile/profileAdmin.dart';
import '../auth/login.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddFieldScreen extends StatefulWidget {
  // Parameter opsional untuk mode edit — null berarti mode tambah baru
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

  static const Color _blue = Color(0xFF2563EB); // Warna biru utama sesuai Kelola Lapangan

  bool _isStatusOn = true;
  int _selectedJamMulaiHour = 6;
  int _selectedJamSelesaiHour = 21;
  String _selectedJenisFloor = 'Lantai Kayu';
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

  final List<String> _tipeLapangan = ['Futsal Rumput', 'Futsal Sintetis', 'Bulutangkis', 'Basket', 'Tenis', 'Padel'];
  final List<String> _daftarJenisLantai = ['Lantai Kayu', 'Vinil', 'Interlock', 'Karet'];
  final ImagePicker _picker = ImagePicker();
  final String cloudName = "dewncgzjd";
  final String uploadPreset = "add_field";
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Apakah mode edit?
  bool get _isEditMode => widget.fieldToEdit != null;

  @override
  void initState() {
    super.initState();
    // Jika mode edit, pre-fill semua field dengan data existing
    if (_isEditMode) {
      final f = widget.fieldToEdit!;
      _nameController.text = f.name;
      _priceController.text = f.price.toString();
      _descController.text = f.description;
      _selectedType = _tipeLapangan.contains(f.type) ? f.type : null;
      _isStatusOn = f.status == 'Aktif';
      _selectedJamMulaiHour = f.jamBuka;
      _selectedJamSelesaiHour = f.jamTutup;
      _selectedJenisFloor = _daftarJenisLantai.contains(f.jenisFloor)
          ? f.jenisFloor
          : 'Lantai Kayu';
      _kapasitasController.text =
          f.kapasitas > 0 ? f.kapasitas.toString() : '';
      _lokasiController.text = f.lokasi;
      _uploadedImages.addAll(f.images);

      // Pre-fill fasilitas dari data existing (jika ada)
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

  IconData _getIconFromKeyword(String text) {
    String cleanText = text.toLowerCase();
    if (cleanText.contains('wifi') || cleanText.contains('internet')) return Icons.wifi;
    if (cleanText.contains('minum') || cleanText.contains('air') || cleanText.contains('water')) return Icons.water_drop_outlined;
    if (cleanText.contains('ganti') || cleanText.contains('baju')) return Icons.door_sliding_outlined;
    if (cleanText.contains('parkir') || cleanText.contains('mobil')) return Icons.local_parking;
    if (cleanText.contains('kantin') || cleanText.contains('makan') || cleanText.contains('kafe')) return Icons.restaurant;
    if (cleanText.contains('musholla') || cleanText.contains('sholat') || cleanText.contains('mesjid')) return Icons.mosque;
    if (cleanText.contains('toilet') || cleanText.contains('wc') || cleanText.contains('kamar mandi')) return Icons.wc;
    if (cleanText.contains('shower')) return Icons.shower;
    if (cleanText.contains('ac') || cleanText.contains('kipas')) return Icons.ac_unit;
    if (cleanText.contains('tribun') || cleanText.contains('duduk')) return Icons.chair;
    return Icons.star_border_rounded;
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Batal memilih gambar.")),
        );
        return;
      }

      setState(() => _isUploading = true);

      String? mimeType = lookupMimeType(image.path);
      mimeType ??= 'image/jpeg';
      final mimeTypeData = mimeType.split('/');

      final cloudinaryUrl = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
      );

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
                  isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                  size: 54,
                  color: isSuccess ? Colors.green[600] : Colors.red[600],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isSuccess ? "Unggah Berhasil!" : "Unggah Gagal!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isSuccess ? Colors.green[800] : Colors.red[800],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isSuccess
                    ? "Foto lapangan berhasil diupload ke Cloudinary dan disimpan ke Firebase."
                    : "Koneksi gagal atau upload bermasalah.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuccess ? Colors.green[600] : Colors.red[600],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Mengerti",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showImagePreviewDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl.startsWith('http')
                      ? Image.network(imageUrl, fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Text("Gagal memuat gambar preview")))
                      : Image.file(File(imageUrl), fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Text("Gagal memuat gambar preview"))),
                ),
              ),
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
            const Text("Form Tambah Fasilitas", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                "Sistem akan mendeteksi ikon otomatis berdasarkan kata kunci (cth: WiFi, Kantin, Toilet, AC, Parkir).",
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: facilityController,
              decoration: InputDecoration(
                labelText: "Nama Fasilitas",
                hintText: "Masukkan nama fasilitas standar...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.star_outline_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              if (facilityController.text.isNotEmpty) {
                String inputName = facilityController.text;
                setState(() {
                  _facilities.add({
                    'icon': _getIconFromKeyword(inputName),
                    'label': inputName,
                  });
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Simpan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 480,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.blue[700],
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("PENGATURAN JAM OPERASIONAL",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 11,
                                  fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          const SizedBox(height: 4),
                          Text(
                            "Interval: ${tempTutup.toString().padLeft(2, '0')}:00 (Tutup) s/d ${tempBuka.toString().padLeft(2, '0')}:00 (Buka)",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text("JAM BUKA",
                                    style: TextStyle(
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(height: 12),
                                Container(
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: ListWheelScrollView.useDelegate(
                                    controller: FixedExtentScrollController(initialItem: tempBuka),
                                    itemExtent: 40,
                                    perspective: 0.005,
                                    diameterRatio: 1.2,
                                    physics: const FixedExtentScrollPhysics(),
                                    onSelectedItemChanged: (index) {
                                      setDialogState(() => tempBuka = index);
                                    },
                                    childDelegate: ListWheelChildBuilderDelegate(
                                      childCount: 24,
                                      builder: (context, index) {
                                        final isSelected = tempBuka == index;
                                        return Center(
                                          child: Text(
                                            "${index.toString().padLeft(2, '0')}:00 WIB",
                                            style: TextStyle(
                                              fontSize: isSelected ? 16 : 14,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? Colors.blue[700]
                                                  : Colors.black54,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              children: [
                                Text("JAM TUTUP",
                                    style: TextStyle(
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(height: 12),
                                Container(
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: ListWheelScrollView.useDelegate(
                                    controller:
                                        FixedExtentScrollController(initialItem: tempTutup),
                                    itemExtent: 40,
                                    perspective: 0.005,
                                    diameterRatio: 1.2,
                                    physics: const FixedExtentScrollPhysics(),
                                    onSelectedItemChanged: (index) {
                                      setDialogState(() => tempTutup = index);
                                    },
                                    childDelegate: ListWheelChildBuilderDelegate(
                                      childCount: 24,
                                      builder: (context, index) {
                                        final isSelected = tempTutup == index;
                                        return Center(
                                          child: Text(
                                            "${index.toString().padLeft(2, '0')}:00 WIB",
                                            style: TextStyle(
                                              fontSize: isSelected ? 16 : 14,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? Colors.blue[700]
                                                  : Colors.black54,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedJamMulaiHour = tempBuka;
                                _selectedJamSelesaiHour = tempTutup;
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
                            child: const Text("Terapkan",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteFacilityDialog(int index, String label) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text("Hapus Fasilitas?", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
            "Apakah Anda yakin ingin menghapus fasilitas '$label' dari daftar standar lapangan ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal",
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _facilities.removeAt(index));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Hapus",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _redirectToKelolaLapangan() {
    Navigator.pop(context);
  }

  Future<void> _saveField() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      try {
        final data = {
          // IDENTITAS LAPANGAN
          'nama_lapangan': _nameController.text,
          'jenis_lapangan': _selectedType ?? 'Lainnya',

          // HARGA
          'harga': int.tryParse(
                _priceController.text.replaceAll(
                  RegExp(r'[^0-9]'),
                  '',
                ),
              ) ??
              0,

          // DESKRIPSI
          'deskripsi_lapangan': _descController.text,

          // STATUS
          'status': _isStatusOn ? 'Aktif' : 'Non-Aktif',

          // JAM OPERASIONAL
          'jam_buka': _selectedJamMulaiHour,
          'jam_tutup': _selectedJamSelesaiHour,

          // DETAIL LAPANGAN
          'jenis_floor': _selectedJenisFloor,
          'kapasitas':
              int.tryParse(_kapasitasController.text) ?? 0,
          'lokasi': _lokasiController.text,

          // FOTO LAPANGAN
          'foto': _uploadedImages,

          // FOTO UTAMA
          'image_url': _uploadedImages.isNotEmpty
              ? _uploadedImages.first
              : '',

          // FASILITAS + ICON
         'fasilitas': _facilities.map((f) {
          return {
            'nama': f['label'] ?? '',
            'label': f['label'] ?? '',
            'icon_url': '',
          };
        }).toList(),

          // DEFAULT RATING
          'rating_rata': 0.0,
          'jumlah_ulasan': 0,
        };

        if (_isEditMode) {
          // MODE EDIT
          await _firestore
              .collection('lapangan')
              .doc(widget.fieldToEdit!.id)
              .update({
            ...data,
            'updated_at': FieldValue.serverTimestamp(),
          });

          // AKTIVITAS EDIT
          await _firestore
              .collection('aktivitas_lapangan')
              .add({
            'activity_type': 'update',
            'title':
                'Lapangan diperbarui: ${_nameController.text}',
            'subtitle':
                'Admin memperbarui informasi lapangan',
            'timestamp': FieldValue.serverTimestamp(),
          });
        } else {
          // MODE TAMBAH BARU
          await _firestore.collection('lapangan').add({
            ...data,
            'created_at': FieldValue.serverTimestamp(),
          });

          // AKTIVITAS TAMBAH
          await _firestore
              .collection('aktivitas_lapangan')
              .add({
            'activity_type': 'add',
            'title':
                'Lapangan baru ditambahkan: ${_nameController.text}',
            'subtitle':
                'Admin menambahkan lapangan ke inventaris',
            'timestamp': FieldValue.serverTimestamp(),
          });
        }

        _redirectToKelolaLapangan();
      } catch (e) {
        debugPrint("Error saving field: $e");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Gagal menyimpan lapangan: $e",
            ),
          ),
        );
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SIDEBAR LOKAL (Sama persis seperti di kelola_lapangan.dart)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _sidebar() {
    return Container(
      width: 240,
      // 💡 Perbaikan: color dan border dipindahkan ke dalam BoxDecoration
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Icon(Icons.sports_soccer, color: _blue, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Sportify',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _sidebarItem(
            icon: Icons.dashboard_outlined,
            title: 'Dashboard',
            active: false,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
              );
            },
          ),
          _sidebarItem(
            icon: Icons.sports_soccer,
            title: 'Kelola Lapangan',
            active: true,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const KelolaLapanganScreen()),
              );
            },
          ),
          _sidebarItem(
            icon: Icons.calendar_month_outlined,
            title: 'Kelola Booking',
            active: false,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const KelolaBookingScreen()),
              );
            },
          ),
          _sidebarItem(
            icon: Icons.schedule,
            title: 'Kelola Jadwal',
            active: false,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const KelolaJadwalScreen()),
              );
            },
          ),
          _sidebarItem(
            icon: Icons.discount_outlined,
            title: 'Kelola Promo',
            active: false,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const KelolaPromoScreen()),
              );
            },
          ),
          _sidebarItem(
            icon: Icons.person_outline,
            title: 'Profile Admin',
            active: false,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfileAdminScreen()),
              );
            },
          ),
          const Spacer(),
          _sidebarItem(
            icon: Icons.logout,
            title: 'Keluar',
            active: false,
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const AdminLoginPage()),
                (route) => false,
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sidebarItem({
    required IconData icon,
    required String title,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFEFF6FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(
                icon,
                color: active ? _blue : Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: active ? _blue : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE), 
      body: Row(
        children: [
          // 🔑 PANGGIL SIDEBAR LOKAL DI SINI
          _sidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopNavbar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderActionRow(),
                          const SizedBox(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  children: [
                                    _buildMainInfoCard(),
                                    const SizedBox(height: 16),
                                    _buildAvailabilityCard(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildMediaCard(),
                                    const SizedBox(height: 16),
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
        ],
      ),
    );
  }

  Widget _buildTopNavbar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
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
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _isEditMode
                  ? "Perbarui detail informasi lapangan yang sudah ada."
                  : "Input detail informasi lapangan untuk memperbarui katalog pada tahun 2026.",
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton(
              onPressed: _redirectToKelolaLapangan,
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text("Batal", style: TextStyle(fontSize: 13)),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveField,
              icon: _isSaving
                  ? const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save, size: 18),
              label: Text(_isSaving
                  ? "Menyimpan..."
                  : _isEditMode
                      ? "Simpan Perubahan"
                      : "Simpan Lapangan", style: const TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _buildMainInfoCard() {
    return Card(
      elevation: 0.5,
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text("Informasi Utama",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("NAMA LAPANGAN",
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: "Contoh: Lapangan Utama A",
                          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("TIPE LAPANGAN",
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                        items: _tipeLapangan
                            .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedType = val),
                        decoration: InputDecoration(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text("HARGA SEWA (PER JAM)",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _priceController,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: "Masukkan harga sewa...",
                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            Text("DESKRIPSI LAPANGAN",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              maxLines: 3,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: "Masukkan deskripsi fasilitas dan kondisi lapangan...",
                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaCard() {
    return Card(
      elevation: 0.5,
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.image_outlined, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text("Media Lapangan",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: _isUploading ? null : _pickAndUploadImage,
                  child: CustomPaint(
                    painter: DashedBorderPainter(color: Colors.blue.shade200, radius: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: _isUploading
                            ? const CircularProgressIndicator()
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                        color: Colors.blue.shade50, shape: BoxShape.circle),
                                    child: Icon(Icons.cloud_upload_outlined,
                                        color: Colors.blue[700], size: 24),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text("Unggah Foto",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  const Text(
                                      "Drag and drop file atau klik\nuntuk memilih. Maks. 5MB\n(JPG/PNG)",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 10, height: 1.4)),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(3, (index) {
                    if (index < _uploadedImages.length) {
                      final imagePath = _uploadedImages[index];
                      return Stack(
                        children: [
                          GestureDetector(
                            onTap: () => _showImagePreviewDialog(imagePath),
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: imagePath.startsWith('http')
                                    ? Image.network(imagePath, fit: BoxFit.cover)
                                    : Image.file(File(imagePath), fit: BoxFit.cover),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => setState(() => _uploadedImages.removeAt(index)),
                              child: Container(
                                decoration: const BoxDecoration(
                                    color: Colors.black54, shape: BoxShape.circle),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(Icons.close, size: 10, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    } else if (index == _uploadedImages.length) {
                      return GestureDetector(
                        onTap: _isUploading ? null : _pickAndUploadImage,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Icon(Icons.add, color: Colors.blue[700]),
                        ),
                      );
                    } else {
                      return Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Icon(Icons.image_outlined, color: Colors.grey[300]),
                      );
                    }
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityCard() {
    return Card(
      elevation: 0.5,
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Ketersediaan",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () => setState(() => _isStatusOn = !_isStatusOn),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: _isStatusOn ? Colors.green : Colors.grey,
                            shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(_isStatusOn ? "Aktif" : "Non-Aktif",
                          style: TextStyle(
                              fontSize: 12,
                              color: _isStatusOn ? Colors.green : Colors.grey,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _showInteractiveTimePickerDialog,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("JAM OPERASIONAL",
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                          const SizedBox(height: 6),
                          Text(
                              "${_selectedJamMulaiHour.toString().padLeft(2, '0')}:00 - ${_selectedJamSelesaiHour.toString().padLeft(2, '0')}:00 WIB",
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text("JENIS FLOOR",
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600)),
                        ),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isDense: true,
                            isExpanded: true,
                            value: _selectedJenisFloor,
                            icon: const Icon(Icons.keyboard_arrow_down,
                                size: 16, color: Colors.grey),
                            items: _daftarJenisLantai
                                .map((floor) => DropdownMenuItem(
                                    value: floor,
                                    child: Text(floor,
                                        style: const TextStyle(
                                            fontSize: 13, fontWeight: FontWeight.bold))))
                                .toList(),
                            onChanged: (val) => setState(() => _selectedJenisFloor = val!),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text("KAPASITAS (ORANG)",
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600)),
                        ),
                        TextFormField(
                          controller: _kapasitasController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                            border: InputBorder.none,
                            hintText: "Contoh: 10",
                            hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text("LOKASI",
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600)),
                        ),
                        TextFormField(
                          controller: _lokasiController,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                            border: InputBorder.none,
                            hintText: "Contoh: Indoor / Lt. 2",
                            hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilitiesCard() {
    return Card(
      elevation: 0.5,
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Fasilitas Standar",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _showAddFacilityDialog,
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text("Tambah", style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue[700],
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_facilities.length, (index) {
                final facility = _facilities[index];
                return Chip(
                  backgroundColor: Colors.blue.shade50,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  avatar: Icon(facility['icon'] as IconData, size: 14, color: Colors.blue[700]),
                  label: Text(facility['label'] ?? facility['nama'] ?? '',
                      style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                  deleteIcon: Icon(Icons.close, size: 14, color: Colors.blue[700]),
                    onDeleted: () => _showDeleteFacilityDialog(index, facility['label'] ?? facility['nama'] ?? '', ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedBorderPainter({
    required this.color,
    this.radius = 8.0,
    this.strokeWidth = 2.0,
    this.dashWidth = 6.0,
    this.dashSpace = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ));

    Path dashPath = Path();
    for (final measurePath in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < measurePath.length) {
        dashPath.addPath(
          measurePath.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace;
  }
}