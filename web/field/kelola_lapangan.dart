import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_field.dart';

// --- DATA MODELS ---
class FieldItem {
  final String id;
  final String name;
  final String type;
  final int price;
  final String status;
  final String description;
  final int jamBuka;
  final int jamTutup;
  final String jenisFloor;
  final int kapasitas;
  final String lokasi;
  final List<String> fasilitas;
  final List<String> images;

  FieldItem({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.status,
    this.description = '',
    this.jamBuka = 6,
    this.jamTutup = 21,
    this.jenisFloor = '',
    this.kapasitas = 0,
    this.lokasi = '',
    this.fasilitas = const [],
    this.images = const [],
  });

  factory FieldItem.fromFirestore(DocumentSnapshot doc) {
  Map<String, dynamic> data =
      doc.data() as Map<String, dynamic>;

  return FieldItem(
    id: doc.id,

    // nama lapangan
    name: data['name'] ??
        data['nama_lapangan'] ??
        'Tanpa Nama',

    // jenis lapangan
    type: data['type'] ??
        data['jenis_lapangan'] ??
        'Lainnya',

    // harga
    price: (data['price'] ?? data['harga'] ?? 0) is int
        ? (data['price'] ?? data['harga'] ?? 0)
        : int.tryParse(
                (data['price'] ?? data['harga'])
                    .toString()) ??
            0,

    // status
    status: data['status'] ?? 'Aktif',

    // deskripsi
    description: data['description'] ??
        data['deskripsi_lapangan'] ??
        '',

    // jam operasional
    jamBuka: data['jam_buka'] ?? 6,
    jamTutup: data['jam_tutup'] ?? 21,

    // jenis floor
    jenisFloor: data['jenis_floor'] ?? '',

    // kapasitas
    kapasitas: (data['kapasitas'] ?? 0) is int
        ? data['kapasitas']
        : int.tryParse(
                data['kapasitas'].toString()) ??
            0,

    // lokasi
    lokasi: data['lokasi'] ?? '',

    // fasilitas
    fasilitas: data['fasilitas'] != null
    ? (data['fasilitas'] as List)
        .map((e) => e.toString())
        .toList()
    : [],

images: data['foto'] != null
    ? (data['foto'] as List)
        .map((e) {
          // kalau langsung string url
          if (e is String) {
            return e;
          }

          // kalau object/map
          if (e is Map<String, dynamic>) {
            return e['url']?.toString() ?? '';
          }

          return '';
        })
        .where((e) => e.isNotEmpty)
        .toList()
    : (data['image_url'] != null
        ? [data['image_url'].toString()]
        : []),
  );
  }
}

class ActivityItem {
  final String title;
  final String subtitle;
  final Color dotColor;

  ActivityItem({
    required this.title,
    required this.subtitle,
    required this.dotColor,
  });

  factory ActivityItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    Color color = Colors.blue;
    if (data['activity_type'] == 'update') color = Colors.orange;
    if (data['activity_type'] == 'delete') color = Colors.red;
    if (data['activity_type'] == 'maintenance') color = Colors.grey;

    return ActivityItem(
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      dotColor: color,
    );
  }
}

// --- DETAIL LAPANGAN SCREEN ---
class DetailLapanganScreen extends StatelessWidget {
  final FieldItem field;

  const DetailLapanganScreen({super.key, required this.field});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          // SIDEBAR
          Container(
            width: 250,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("ArenaHub",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue)),
                const Text("PANEL ADMINISTRASI",
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        letterSpacing: 1.5)),
                const SizedBox(height: 40),
                _buildSidebarItem(Icons.dashboard_outlined, "Dashboard", false),
                _buildSidebarItem(
                    Icons.book_online_outlined, "Kelola Booking", false),
                _buildSidebarItem(
                    Icons.sports_soccer_outlined, "Kelola Lapangan", true),
                _buildSidebarItem(
                    Icons.calendar_month_outlined, "Kelola Jadwal", false),
                _buildSidebarItem(Icons.person_outline, "Profil", false),
                const Spacer(),
                const Divider(),
                const ListTile(
                  leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person, color: Colors.white)),
                  title: Text("Admin Utama",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text("Administrator",
                      style: TextStyle(fontSize: 11)),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),

          // MAIN CONTENT
          Expanded(
            child: Column(
              children: [
                // TOP BAR
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Cari data booking...",
                            prefixIcon: const Icon(Icons.search,
                                color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.settings_outlined, color: Colors.grey),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HEADER
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(field.name,
                                    style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                const Text("Detail informasi lapangan",
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: field.status == 'Aktif'
                                        ? Colors.green[50]
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: field.status == 'Aktif'
                                            ? Colors.green
                                            : Colors.grey),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.circle,
                                          size: 10,
                                          color: field.status == 'Aktif'
                                              ? Colors.green
                                              : Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(field.status,
                                          style: TextStyle(
                                              color: field.status == 'Aktif'
                                                  ? Colors.green
                                                  : Colors.grey,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Kembali"),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // LEFT COLUMN
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  // INFO UTAMA
                                  Card(
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        side: BorderSide(
                                            color: Colors.grey.shade200)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(Icons.info_outline,
                                                  color: Colors.blue),
                                              SizedBox(width: 8),
                                              Text("Informasi Utama",
                                                  style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ],
                                          ),
                                          const SizedBox(height: 24),
                                          _infoRow(
                                              "Nama Lapangan", field.name),
                                          _infoRow(
                                              "Tipe Lapangan", field.type),
                                          _infoRow("Harga Sewa / Jam",
                                              "Rp ${field.price}"),
                                          if (field.description.isNotEmpty)
                                            _infoRow("Deskripsi",
                                                field.description),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  // KETERSEDIAAN
                                  Card(
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        side: BorderSide(
                                            color: Colors.grey.shade200)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text("Ketersediaan",
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight:
                                                      FontWeight.bold)),
                                          const SizedBox(height: 24),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _infoBox(
                                                  "JAM OPERASIONAL",
                                                  "${field.jamBuka.toString().padLeft(2, '0')}:00 - ${field.jamTutup.toString().padLeft(2, '0')}:00 WIB",
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: _infoBox(
                                                    "JENIS FLOOR",
                                                    field.jenisFloor.isNotEmpty
                                                        ? field.jenisFloor
                                                        : "-"),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _infoBox(
                                                    "KAPASITAS",
                                                    field.kapasitas > 0
                                                        ? "${field.kapasitas} Orang"
                                                        : "-"),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: _infoBox(
                                                    "LOKASI",
                                                    field.lokasi.isNotEmpty
                                                        ? field.lokasi
                                                        : "-"),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),

                            // RIGHT COLUMN
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  // MEDIA
                                  Card(
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        side: BorderSide(
                                            color: Colors.grey.shade200)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(Icons.image_outlined,
                                                  color: Colors.blue),
                                              SizedBox(width: 8),
                                              Text("Media Lapangan",
                                                  style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          field.images.isEmpty
                                              ? Container(
                                                  width: double.infinity,
                                                  height: 120,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[100],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: const Center(
                                                    child: Text(
                                                        "Belum ada foto",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.grey)),
                                                  ),
                                                )
                                              : Column(
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      child: Image.network(
                                                        field.images.first,
                                                        width: double.infinity,
                                                        height: 160,
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (c, e, s) =>
                                                                Container(
                                                          height: 160,
                                                          color:
                                                              Colors.grey[200],
                                                          child: const Icon(
                                                              Icons.broken_image,
                                                              color:
                                                                  Colors.grey),
                                                        ),
                                                      ),
                                                    ),
                                                    if (field.images.length >
                                                        1) ...[
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        children: field.images
                                                            .skip(1)
                                                            .take(2)
                                                            .map((url) =>
                                                                Expanded(
                                                                  child:
                                                                      Padding(
                                                                    padding: const EdgeInsets
                                                                        .only(
                                                                        right:
                                                                            4),
                                                                    child:
                                                                        ClipRRect(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              6),
                                                                      child: Image
                                                                          .network(
                                                                        url,
                                                                        height:
                                                                            70,
                                                                        fit: BoxFit
                                                                            .cover,
                                                                        errorBuilder: (c,
                                                                                e,
                                                                                s) =>
                                                                            Container(
                                                                          height:
                                                                              70,
                                                                          color:
                                                                              Colors.grey[200],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ))
                                                            .toList(),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  // FASILITAS
                                  Card(
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        side: BorderSide(
                                            color: Colors.grey.shade200)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text("Fasilitas Standar",
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight:
                                                      FontWeight.bold)),
                                          const SizedBox(height: 16),
                                          field.fasilitas.isEmpty
                                              ? const Text(
                                                  "Belum ada fasilitas.",
                                                  style: TextStyle(
                                                      color: Colors.grey))
                                              : Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children: field.fasilitas
                                                      .map((f) => Chip(
                                                            backgroundColor:
                                                                Colors
                                                                    .blue
                                                                    .shade50,
                                                            side: BorderSide
                                                                .none,
                                                            label: Text(
                                                              f,
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .blue[700],
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                          ))
                                                      .toList(),
                                                ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.blue[50] : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? const Border(left: BorderSide(color: Colors.blue, width: 4))
            : null,
      ),
      child: ListTile(
        leading:
            Icon(icon, color: isActive ? Colors.blue : Colors.grey[700]),
        title: Text(title,
            style: TextStyle(
                color: isActive ? Colors.blue : Colors.grey[800],
                fontWeight:
                    isActive ? FontWeight.bold : FontWeight.normal)),
        onTap: () {},
      ),
    );
  }
}

// --- MAIN SCREEN ---
class KelolaLapanganScreen extends StatefulWidget {
  const KelolaLapanganScreen({super.key});

  @override
  State<KelolaLapanganScreen> createState() => _KelolaLapanganScreenState();
}

class _KelolaLapanganScreenState extends State<KelolaLapanganScreen> {
  final CollectionReference fieldsCollection =
      FirebaseFirestore.instance.collection('lapangan');
  final CollectionReference activitiesCollection =
      FirebaseFirestore.instance.collection('aktivitas_lapangan');

  // Filter state
  String? _filterType;
  String? _filterPrice; // 'asc' | 'desc'

  void _navigateToAddField() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddFieldScreen()),
    );
  }

  // Catat aktivitas ke koleksi terpisah
  Future<void> _logActivity(
      String type, String title, String subtitle) async {
    await FirebaseFirestore.instance
        .collection('aktivitas_lapangan')
        .add({
      'activity_type': type,
      'title': title,
      'subtitle': subtitle,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Hapus lapangan
  Future<void> _deleteField(FieldItem field) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text("Hapus Lapangan?",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
            "Apakah Anda yakin ingin menghapus lapangan '${field.name}'? Tindakan ini tidak dapat dibatalkan."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal",
                style: TextStyle(
                    color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Hapus",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await fieldsCollection.doc(field.id).delete();
      await _logActivity(
        'delete',
        'Lapangan dihapus: ${field.name}',
        'Admin menghapus lapangan dari inventaris',
      );
    }
  }

  // Toggle status aktif/non-aktif
  Future<void> _toggleStatus(FieldItem field) async {
    final newStatus = field.status == 'Aktif' ? 'Non-Aktif' : 'Aktif';
    await fieldsCollection.doc(field.id).update({'status': newStatus});
    await _logActivity(
      'update',
      'Status diperbarui: ${field.name}',
      'Status diubah menjadi $newStatus',
    );
  }

  // Menu aksi (⋯)
  void _showActionMenu(
      BuildContext context, FieldItem field, Offset offset) {
    final List<PopupMenuEntry<String>> menuItems = [
      PopupMenuItem<String>(
        value: 'detail',
        child: const Row(
          children: [
            Icon(Icons.visibility_outlined, size: 18, color: Colors.blue),
            SizedBox(width: 8),
            Text("Lihat Detail"),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'edit',
        child: const Row(
          children: [
            Icon(Icons.edit_outlined, size: 18, color: Colors.orange),
            SizedBox(width: 8),
            Text("Edit Lapangan"),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'toggle',
        child: Row(
          children: [
            Icon(
              field.status == 'Aktif'
                  ? Icons.pause_circle_outline
                  : Icons.play_circle_outline,
              size: 18,
              color:
                  field.status == 'Aktif' ? Colors.grey : Colors.green,
            ),
            const SizedBox(width: 8),
            Text(field.status == 'Aktif' ? "Non-Aktifkan" : "Aktifkan"),
          ],
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem<String>(
        value: 'delete',
        child: const Row(
          children: [
            Icon(Icons.delete_outline, size: 18, color: Colors.red),
            SizedBox(width: 8),
            Text("Hapus", style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    ];

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
          offset.dx, offset.dy, offset.dx + 1, offset.dy + 1),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: menuItems,
    ).then((value) async {
      if (value == null) return;
      switch (value) {
        case 'detail':
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => DetailLapanganScreen(field: field)),
          );
          break;
        case 'edit':
          if (!context.mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AddFieldScreen(fieldToEdit: field)),
          );
          await _logActivity(
            'update',
            'Lapangan diperbarui: ${field.name}',
            'Admin memperbarui informasi lapangan',
          );
          break;
        case 'toggle':
          await _toggleStatus(field);
          break;
        case 'delete':
          if (!context.mounted) return;
          await _deleteField(field);
          break;
      }
    });
  }

  // ─── FILTER DIALOG ────────────────────────────────────────────────────────
  // Mengganti Stack+Positioned dengan showDialog agar tidak ada overflow/clip
  void _showFilterDialog(
      BuildContext context, List<String> availableTypes) async {
    // Variabel lokal di dalam dialog — tidak mengubah state sampai "Terapkan"
    String? tempType = _filterType;
    String? tempPrice = _filterPrice;

    await showDialog(
      context: context,
      barrierColor: Colors.transparent, // backdrop transparan seperti dropdown
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Stack(
              children: [
                // Tap di luar untuk menutup
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(color: Colors.transparent),
                ),
                // Panel filter — posisi kanan atas area konten
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    // Sesuaikan padding top agar muncul di bawah tombol Filter
                    padding: const EdgeInsets.only(top: 160, right: 108),
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 280,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Filter Lapangan",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pop(ctx),
                                  child: const Icon(Icons.close,
                                      size: 18, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Jenis Lapangan
                            const Text(
                              "JENIS LAPANGAN",
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: tempType ?? '',
                              isExpanded: true,
                              decoration: InputDecoration(
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(8)),
                                isDense: true,
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: '',
                                  child: Text("Semua Jenis",
                                      style:
                                          TextStyle(fontSize: 13)),
                                ),
                                ...availableTypes.map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t,
                                        style: const TextStyle(
                                            fontSize: 13)),
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                setDialogState(() {
                                  tempType = (val == '') ? null : val;
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            // Urutkan Harga
                            const Text(
                              "URUTKAN HARGA",
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: tempPrice ?? '',
                              isExpanded: true,
                              decoration: InputDecoration(
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(8)),
                                isDense: true,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: '',
                                  child: Text("Default",
                                      style:
                                          TextStyle(fontSize: 13)),
                                ),
                                DropdownMenuItem(
                                  value: 'asc',
                                  child: Text("Harga Terendah",
                                      style:
                                          TextStyle(fontSize: 13)),
                                ),
                                DropdownMenuItem(
                                  value: 'desc',
                                  child: Text("Harga Tertinggi",
                                      style:
                                          TextStyle(fontSize: 13)),
                                ),
                              ],
                              onChanged: (val) {
                                setDialogState(() {
                                  tempPrice = (val == '') ? null : val;
                                });
                              },
                            ),
                            const SizedBox(height: 20),

                            // Tombol aksi
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _filterType = null;
                                      _filterPrice = null;
                                    });
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text("Reset",
                                      style: TextStyle(
                                          color: Colors.grey)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _filterType = tempType;
                                      _filterPrice = tempPrice;
                                    });
                                    Navigator.pop(ctx);
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[700]),
                                  child: const Text("Terapkan",
                                      style: TextStyle(
                                          color: Colors.white)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<FieldItem> _applyFilter(List<FieldItem> fields) {
    List<FieldItem> result = List.from(fields);

    if (_filterType != null && _filterType!.isNotEmpty) {
      result = result.where((f) => f.type == _filterType).toList();
    }

    if (_filterPrice == 'asc') {
      result.sort((a, b) => a.price.compareTo(b.price));
    } else if (_filterPrice == 'desc') {
      result.sort((a, b) => b.price.compareTo(a.price));
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SIDEBAR
          Container(
            width: 250,
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("ArenaHub",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue)),
                const Text("PANEL ADMINISTRASI",
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        letterSpacing: 1.5)),
                const SizedBox(height: 40),
                _buildSidebarItem(
                    Icons.dashboard_outlined, "Dashboard", false),
                _buildSidebarItem(
                    Icons.book_online_outlined, "Kelola Booking", false),
                _buildSidebarItem(
                    Icons.sports_soccer_outlined, "Kelola Lapangan", true),
                _buildSidebarItem(
                    Icons.calendar_month_outlined, "Kelola Jadwal", false),
                _buildSidebarItem(Icons.person_outline, "Profil", false),
                const Spacer(),
                const Divider(),
                const ListTile(
                  leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person, color: Colors.white)),
                  title: Text("Admin Utama",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text("Administrator",
                      style: TextStyle(fontSize: 11)),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),

          // MAIN CONTENT
          Expanded(
            child: Column(
              children: [
                // TOP BAR
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Cari data booking...",
                            prefixIcon: const Icon(Icons.search,
                                color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.settings_outlined,
                          color: Colors.grey),
                    ],
                  ),
                ),

                // STREAMBUILDER CONTENT
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: fieldsCollection.snapshots(),
                    builder: (context, fieldSnapshot) {
                      if (fieldSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (fieldSnapshot.hasError) {
                        return const Center(
                            child: Text(
                                "Terjadi kesalahan saat memuat data."));
                      }

                      List<FieldItem> allFields = fieldSnapshot.data!.docs
                          .map((doc) => FieldItem.fromFirestore(doc))
                          .toList();

                      List<FieldItem> filteredFields =
                          _applyFilter(allFields);

                      int totalLapangan = allFields.length;
                      int tersedia = allFields
                          .where((f) => f.status == "Aktif")
                          .length;
                      int kategori =
                          allFields.map((f) => f.type).toSet().length;

                      // Semua tipe unik untuk dropdown filter
                      List<String> availableTypes =
                          allFields.map((f) => f.type).toSet().toList();

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // HEADER
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text("Kelola Lapangan",
                                        style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(height: 4),
                                    Text(
                                        "Manajemen inventaris lapangan olahraga ArenaHub",
                                        style: TextStyle(
                                            color: Colors.grey)),
                                  ],
                                ),
                                ElevatedButton.icon(
                                  onPressed: _navigateToAddField,
                                  icon: const Icon(Icons.add),
                                  label:
                                      const Text("TAMBAH LAPANGAN BARU"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[700],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 16),
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 24),

                            // SUMMARY CARDS
                            Row(
                              children: [
                                _buildSummaryCard(
                                    "Total Lapangan",
                                    totalLapangan.toString(),
                                    Icons.stadium,
                                    "+2 Bulan ini"),
                                const SizedBox(width: 16),
                                _buildSummaryCard(
                                    "Tersedia",
                                    tersedia.toString(),
                                    Icons.check_circle_outline,
                                    null),
                                const SizedBox(width: 16),
                                _buildSummaryCard(
                                    "Kategori",
                                    kategori.toString(),
                                    Icons.layers_outlined,
                                    null),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // INVENTORY LIST
                            Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  side: BorderSide(
                                      color: Colors.grey.shade200)),
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text("Daftar Inventaris",
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight:
                                                    FontWeight.bold)),
                                        Row(
                                          children: [
                                            // ─── TOMBOL FILTER ───────────
                                            OutlinedButton.icon(
                                              onPressed: () =>
                                                  _showFilterDialog(
                                                      context,
                                                      availableTypes),
                                              icon: const Icon(
                                                  Icons.filter_list,
                                                  size: 16),
                                              label: Row(
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                children: [
                                                  const Text("Filter"),
                                                  if (_filterType !=
                                                          null ||
                                                      _filterPrice != null)
                                                    Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                              left: 6),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 6,
                                                          vertical: 2),
                                                      decoration:
                                                          BoxDecoration(
                                                        color:
                                                            Colors.blue[700],
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                      child: const Text(
                                                          "Aktif",
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .white,
                                                              fontSize:
                                                                  10)),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            OutlinedButton.icon(
                                                onPressed: () {},
                                                icon: const Icon(
                                                    Icons.download,
                                                    size: 16),
                                                label: const Text(
                                                    "Ekspor")),
                                          ],
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    filteredFields.isEmpty
                                        ? const Center(
                                            child: Padding(
                                              padding:
                                                  EdgeInsets.all(32.0),
                                              child: Text(
                                                  "Belum ada data lapangan.",
                                                  style: TextStyle(
                                                      color: Colors.grey)),
                                            ),
                                          )
                                        : SizedBox(
                                            width: double.infinity,
                                            child: DataTable(
                                              headingTextStyle:
                                                  const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.grey),
                                              columns: const [
                                                DataColumn(
                                                    label:
                                                        Text('LAPANGAN')),
                                                DataColumn(
                                                    label: Text('TIPE')),
                                                DataColumn(
                                                    label: Text(
                                                        'HARGA SEWA /JAM')),
                                                DataColumn(
                                                    label:
                                                        Text('STATUS')),
                                                DataColumn(
                                                    label: Text('AKSI')),
                                              ],
                                              rows: filteredFields
                                                  .map((field) =>
                                                      _buildDataRowCell(
                                                          field))
                                                  .toList(),
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // RECENT ACTIVITY
                            StreamBuilder<QuerySnapshot>(
                              stream: activitiesCollection
                                  .orderBy('timestamp',
                                      descending: true)
                                  .limit(5)
                                  .snapshots(),
                              builder: (context, actSnapshot) {
                                if (actSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child:
                                          CircularProgressIndicator());
                                }

                                List<ActivityItem> activities =
                                    actSnapshot.hasData
                                        ? actSnapshot.data!.docs
                                            .map((doc) =>
                                                ActivityItem
                                                    .fromFirestore(doc))
                                            .toList()
                                        : [];

                                return Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      side: BorderSide(
                                          color: Colors.grey.shade200)),
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.all(24.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text("Aktivitas Terakhir",
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight:
                                                    FontWeight.bold)),
                                        const SizedBox(height: 16),
                                        activities.isEmpty
                                            ? const Text(
                                                "Belum ada aktivitas tercatat.",
                                                style: TextStyle(
                                                    color: Colors.grey))
                                            : Column(
                                                children: activities
                                                    .map((act) => Padding(
                                                          padding: const EdgeInsets
                                                              .only(
                                                              bottom:
                                                                  16.0),
                                                          child: Row(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Padding(
                                                                padding: const EdgeInsets
                                                                    .only(
                                                                    top:
                                                                        4.0),
                                                                child: Icon(
                                                                    Icons
                                                                        .circle,
                                                                    size:
                                                                        12,
                                                                    color: act
                                                                        .dotColor),
                                                              ),
                                                              const SizedBox(
                                                                  width:
                                                                      12),
                                                              Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Text(
                                                                      act.title,
                                                                      style: const TextStyle(
                                                                          fontWeight:
                                                                              FontWeight.bold)),
                                                                  Text(
                                                                      act.subtitle,
                                                                      style: const TextStyle(
                                                                          color: Colors
                                                                              .grey,
                                                                          fontSize:
                                                                              12)),
                                                                ],
                                                              )
                                                            ],
                                                          ),
                                                        ))
                                                    .toList(),
                                              ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  DataRow _buildDataRowCell(FieldItem field) {
    return DataRow(cells: [
      DataCell(
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => DetailLapanganScreen(field: field)),
            );
          },
          borderRadius: BorderRadius.circular(6),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8)),
                child: field.images.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(field.images.first,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Icon(
                                Icons.sports,
                                color: Colors.grey)),
                      )
                    : const Icon(Icons.sports, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(field.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                          decoration: TextDecoration.underline)),
                  Text("ID: ${field.id}",
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 11)),
                ],
              )
            ],
          ),
        ),
      ),
      DataCell(Chip(
          label: Text(field.type,
              style: const TextStyle(fontSize: 12)),
          backgroundColor: Colors.blue[50],
          side: BorderSide.none)),
      DataCell(Text("Rp ${field.price}")),
      DataCell(Row(
        children: [
          Icon(Icons.circle,
              size: 10,
              color:
                  field.status == "Aktif" ? Colors.green : Colors.grey),
          const SizedBox(width: 6),
          Text(field.status,
              style: TextStyle(
                  color: field.status == "Aktif"
                      ? Colors.green
                      : Colors.grey)),
        ],
      )),
      DataCell(
        GestureDetector(
          onTapDown: (details) {
            _showActionMenu(context, field, details.globalPosition);
          },
          child: const Icon(Icons.more_horiz, color: Colors.grey),
        ),
      ),
    ]);
  }

  Widget _buildSidebarItem(IconData icon, String title, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.blue[50] : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? const Border(
                left: BorderSide(color: Colors.blue, width: 4))
            : null,
      ),
      child: ListTile(
        leading: Icon(icon,
            color: isActive ? Colors.blue : Colors.grey[700]),
        title: Text(title,
            style: TextStyle(
                color: isActive ? Colors.blue : Colors.grey[800],
                fontWeight: isActive
                    ? FontWeight.bold
                    : FontWeight.normal)),
        onTap: () {},
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, String? subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: Colors.blue),
                ),
                if (subtitle != null)
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
