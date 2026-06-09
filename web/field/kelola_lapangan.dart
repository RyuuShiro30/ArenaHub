import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'add_field.dart';
import '../sidebar.dart'; // IMPORT SIDEBAR BARU

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
  final DateTime? createdAt;

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
    this.createdAt,
  });

  factory FieldItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    DateTime? parsedDate;
    dynamic rawDate = data['created_at'] ?? data['createdAt'] ?? data['timestamp'];
    if (rawDate != null) {
      if (rawDate is Timestamp) {
        parsedDate = rawDate.toDate();
      } else if (rawDate is String) {
        parsedDate = DateTime.tryParse(rawDate);
      }
    }

    return FieldItem(
      id: doc.id,
      name: data['name'] ?? data['nama_lapangan'] ?? 'Tanpa Nama',
      type: data['type'] ?? data['jenis_lapangan'] ?? 'Lainnya',
      price: (data['price'] ?? data['harga'] ?? 0) is int
          ? (data['price'] ?? data['harga'] ?? 0)
          : int.tryParse((data['price'] ?? data['harga']).toString()) ?? 0,
      status: data['status'] ?? 'Aktif',
      description: data['description'] ?? data['deskripsi_lapangan'] ?? '',
      jamBuka: data['jam_buka'] ?? 6,
      jamTutup: data['jam_tutup'] ?? 21,
      jenisFloor: data['jenis_floor'] ?? '',
      kapasitas: (data['kapasitas'] ?? 0) is int
          ? data['kapasitas']
          : int.tryParse(data['kapasitas'].toString()) ?? 0,
      lokasi: data['lokasi'] ?? '',
      fasilitas: data['fasilitas'] != null
          ? (data['fasilitas'] as List).map((e) => e.toString()).toList()
          : [],
      images: data['foto'] != null
          ? (data['foto'] as List)
              .map((e) {
                if (e is String) return e;
                if (e is Map<String, dynamic>) {
                  return e['url']?.toString() ?? '';
                }
                return '';
              })
              .where((e) => e.isNotEmpty)
              .toList()
          : (data['image_url'] != null ? [data['image_url'].toString()] : []),
      createdAt: parsedDate,
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
    String activityType = (data['activity_type'] ?? '').toString().toLowerCase();
    Color color = Colors.grey;

    if (activityType == 'update') {
      color = Colors.orange;
    } else if (activityType == 'delete') {
      color = Colors.red;
    } else if (activityType == 'create' || activityType == 'add') { // Menyesuaikan dengan permintaan
      color = Colors.blue;
    }

    return ActivityItem(
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      dotColor: color,
    );
  }
}

class KelolaLapanganScreen extends StatefulWidget {
  const KelolaLapanganScreen({super.key});

  @override
  State<KelolaLapanganScreen> createState() => _KelolaLapanganScreenState();
}

class _KelolaLapanganScreenState extends State<KelolaLapanganScreen> {
  static const Color _blue = Color(0xFF2563EB);

  final CollectionReference fieldsCollection =
      FirebaseFirestore.instance.collection('lapangan');
  final CollectionReference activitiesCollection =
      FirebaseFirestore.instance.collection('aktivitas_lapangan');

  String? _filterType;
  String? _filterPrice;

  int _currentPage = 0;
  final int _itemsPerPage = 4;

  String formatRupiahAkuntansi(int amount) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 2);
    return formatter.format(amount);
  }

  Color _getCategoryBgColor(String type) {
    String t = type.toLowerCase();
    if (t.contains('futsal')) return Colors.blue.shade50;
    if (t.contains('bulutangkis') || t.contains('badminton')) {
      return Colors.orange.shade50;
    }
    if (t.contains('basket')) return Colors.purple.shade50;
    if (t.contains('padel')) return Colors.green.shade50;
    return Colors.grey.shade100;
  }

  Color _getCategoryTextColor(String type) {
    String t = type.toLowerCase();
    if (t.contains('futsal')) return Colors.blue.shade700;
    if (t.contains('bulutangkis') || t.contains('badminton')) {
      return Colors.orange.shade700;
    }
    if (t.contains('basket')) return Colors.purple.shade700;
    if (t.contains('padel')) return Colors.green.shade700;
    return Colors.grey.shade700;
  }

  void _navigateToAddField() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddFieldScreen()),
    );
  }

  Future<void> _logActivity(
    String type,
    String title,
    String subtitle, [
    String fieldType = '',
  ]) async {
    await FirebaseFirestore.instance.collection('aktivitas_lapangan').add({
      'activity_type': type,
      'title': title,
      'subtitle': subtitle,
      'field_type': fieldType,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _deleteField(FieldItem field) async {
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text("Hapus Lapangan?",
                style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          "Apakah Anda yakin ingin menghapus lapangan '${field.name}'? Tindakan ini tidak dapat dibatalkan.",
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Batal",
                style: GoogleFonts.inter(
                    color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text("Hapus",
                style: GoogleFonts.inter(
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
        field.type,
      );
    }
  }

  Future<void> _toggleStatus(FieldItem field) async {
    final newStatus = field.status == 'Aktif' ? 'Non-Aktif' : 'Aktif';
    await fieldsCollection.doc(field.id).update({'status': newStatus});
    await _logActivity(
      'update',
      'Status diperbarui: ${field.name}',
      'Status diubah menjadi $newStatus',
      field.type,
    );
  }

  void _showActionMenu(BuildContext context, FieldItem field, Offset offset) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
          offset.dx, offset.dy, offset.dx + 1, offset.dy + 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: [
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(children: [
            const Icon(Icons.edit_outlined, size: 18, color: Colors.orange),
            const SizedBox(width: 8),
            Text("Edit Lapangan", style: GoogleFonts.inter(fontSize: 13))
          ]),
        ),
        PopupMenuItem<String>(
          value: 'toggle',
          child: Row(children: [
            Icon(
              field.status == 'Aktif'
                  ? Icons.pause_circle_outline
                  : Icons.play_circle_outline,
              size: 18,
              color: field.status == 'Aktif' ? Colors.grey : Colors.green,
            ),
            const SizedBox(width: 8),
            Text(field.status == 'Aktif' ? "Non-Aktifkan" : "Aktifkan",
                style: GoogleFonts.inter(fontSize: 13))
          ]),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(children: [
            const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            const SizedBox(width: 8),
            Text("Hapus",
                style: GoogleFonts.inter(fontSize: 13, color: Colors.red))
          ]),
        ),
      ],
    ).then((value) async {
      if (value == null) return;
      switch (value) {
        case 'edit':
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AddFieldScreen(fieldToEdit: field)),
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

  void _showFilterDialog(
      BuildContext context, List<String> availableTypes) async {
    String? tempFilterType = _filterType;
    String? tempFilterPrice = _filterPrice;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text("Filter Lapangan",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Tipe Lapangan",
                  style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label:
                        Text("Semua", style: GoogleFonts.inter(fontSize: 12)),
                    selected: tempFilterType == null || tempFilterType!.isEmpty,
                    onSelected: (_) =>
                        setDialogState(() => tempFilterType = null),
                  ),
                  ...availableTypes.map((type) => FilterChip(
                        label:
                            Text(type, style: GoogleFonts.inter(fontSize: 12)),
                        selected: tempFilterType == type,
                        onSelected: (_) =>
                            setDialogState(() => tempFilterType = type),
                      )),
                ],
              ),
              const SizedBox(height: 16),
              Text("Urutkan Harga",
                  style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label:
                        Text("Default", style: GoogleFonts.inter(fontSize: 12)),
                    selected:
                        tempFilterPrice == null || tempFilterPrice!.isEmpty,
                    onSelected: (_) =>
                        setDialogState(() => tempFilterPrice = null),
                  ),
                  FilterChip(
                    label: Text("Termurah",
                        style: GoogleFonts.inter(fontSize: 12)),
                    selected: tempFilterPrice == 'asc',
                    onSelected: (_) =>
                        setDialogState(() => tempFilterPrice = 'asc'),
                  ),
                  FilterChip(
                    label: Text("Termahal",
                        style: GoogleFonts.inter(fontSize: 12)),
                    selected: tempFilterPrice == 'desc',
                    onSelected: (_) =>
                        setDialogState(() => tempFilterPrice = 'desc'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Batal",
                  style: GoogleFonts.inter(
                      color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _filterType = tempFilterType;
                  _filterPrice = tempFilterPrice;
                  _currentPage = 0;
                });
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: _blue),
              child: Text("Terapkan",
                  style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
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
        children: [
          const AdminSidebar(currentIndex: 5), // SIDEBAR
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: fieldsCollection.snapshots(),
              builder: (context, fieldSnapshot) {
                if (fieldSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<FieldItem> allFields = fieldSnapshot.hasData
                    ? fieldSnapshot.data!.docs
                        .map((doc) => FieldItem.fromFirestore(doc))
                        .toList()
                    : [];

                List<FieldItem> filteredFields = _applyFilter(allFields);

                int addedThisMonth = 0;
                final now = DateTime.now();
                for (var f in allFields) {
                  if (f.createdAt != null &&
                      f.createdAt!.month == now.month &&
                      f.createdAt!.year == now.year) {
                    addedThisMonth++;
                  }
                }

                int totalLapangan = allFields.length;
                int tersedia =
                    allFields.where((f) => f.status == "Aktif").length;
                int kategori = allFields.map((f) => f.type).toSet().length;
                List<String> availableTypes =
                    allFields.map((f) => f.type).toSet().toList();

                int totalPages = (filteredFields.length / _itemsPerPage).ceil();
                if (_currentPage >= totalPages && totalPages > 0) {
                  _currentPage = totalPages - 1;
                }
                List<FieldItem> paginatedFields = filteredFields
                    .skip(_currentPage * _itemsPerPage)
                    .take(_itemsPerPage)
                    .toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Kelola Lapangan",
                                  style: GoogleFonts.inter(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF111827))),
                              const SizedBox(height: 2),
                              Text(
                                  "Manajemen inventaris lapangan olahraga ArenaHub",
                                  style: GoogleFonts.inter(
                                      color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: _navigateToAddField,
                            icon: const Icon(Icons.add, size: 16),
                            label: Text("TAMBAH LAPANGAN",
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold, fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildSummaryCard(
                            "Total Lapangan",
                            totalLapangan.toString(),
                            Icons.stadium_outlined,
                            "+$addedThisMonth Bulan ini",
                          ),
                          const SizedBox(width: 16),
                          _buildSummaryCard("Tersedia", tersedia.toString(),
                              Icons.check_circle_outline, null),
                          const SizedBox(width: 16),
                          _buildSummaryCard("Kategori", kategori.toString(),
                              Icons.layers_outlined, null),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildWhiteCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Daftar Inventaris",
                                    style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold)),
                                OutlinedButton.icon(
                                  onPressed: () => _showFilterDialog(
                                      context, availableTypes),
                                  icon: const Icon(Icons.filter_list, size: 16),
                                  label: Text("Filter",
                                      style: GoogleFonts.inter(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    side:
                                        BorderSide(color: Colors.grey.shade300),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            filteredFields.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Text("Belum ada data lapangan.",
                                          style: GoogleFonts.inter(
                                              color: Colors.grey)),
                                    ),
                                  )
                                : Column(
                                    children: [
                                      Theme(
                                        data: Theme.of(context).copyWith(
                                          dataTableTheme: DataTableThemeData(
                                            headingRowColor:
                                                WidgetStateProperty.all(
                                                    Colors.white),
                                            dataRowColor:
                                                WidgetStateProperty.all(
                                                    Colors.white),
                                          ),
                                        ),
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: DataTable(
                                            headingRowHeight: 40,
                                            dataRowMinHeight: 52,
                                            dataRowMaxHeight: 60,
                                            horizontalMargin: 0,
                                            columnSpacing: 16,
                                            headingRowColor:
                                                WidgetStateProperty.all(
                                                    Colors.white),
                                            headingTextStyle: GoogleFonts.inter(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[600],
                                              fontSize: 11,
                                            ),
                                            columns: const [
                                              DataColumn(
                                                  label: Text('LAPANGAN')),
                                              DataColumn(label: Text('TIPE')),
                                              DataColumn(
                                                  label:
                                                      Text('HARGA SEWA/JAM')),
                                              DataColumn(label: Text('STATUS')),
                                              DataColumn(label: Text('AKSI')),
                                            ],
                                            rows: paginatedFields
                                                .map((field) =>
                                                    _buildDataRow(field))
                                                .toList(),
                                          ),
                                        ),
                                      ),
                                      const Divider(
                                          height: 1, color: Color(0xFFE5E7EB)),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Menampilkan ${paginatedFields.length} dari ${filteredFields.length} data",
                                            style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: Colors.grey),
                                          ),
                                          _buildPaginationControls(totalPages),
                                        ],
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<QuerySnapshot>(
                        stream: activitiesCollection
                            .orderBy('timestamp', descending: true)
                            .limit(3)
                            .snapshots(),
                        builder: (context, actSnapshot) {
                          if (actSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          List<ActivityItem> activities = actSnapshot.hasData
                              ? actSnapshot.data!.docs
                                  .map((doc) => ActivityItem.fromFirestore(doc))
                                  .toList()
                              : [];

                          return _buildWhiteCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Aktivitas Terakhir",
                                    style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 16),
                                activities.isEmpty
                                    ? Text(
                                        "Belum ada aktivitas tercatat.",
                                        style: GoogleFonts.inter(
                                            color: Colors.grey),
                                      )
                                    : Column(
                                        children: activities
                                            .map(
                                              (act) => Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 12.0),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 5.0),
                                                      child: Icon(
                                                        Icons.circle,
                                                        size: 8,
                                                        color: act.dotColor,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          act.title,
                                                          style:
                                                              GoogleFonts.inter(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 12),
                                                        ),
                                                        Text(
                                                          act.subtitle,
                                                          style:
                                                              GoogleFonts.inter(
                                                                  color: Colors
                                                                      .grey,
                                                                  fontSize: 11),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    if (totalPages <= 0) totalPages = 1;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPageNavButton(
          icon: Icons.chevron_left,
          enabled: _currentPage > 0,
          onTap: () => setState(() => _currentPage--),
        ),
        const SizedBox(width: 4),
        ...List.generate(totalPages, (index) {
          if (totalPages > 5) {
            if (index != 0 &&
                index != totalPages - 1 &&
                (index < _currentPage - 1 || index > _currentPage + 1)) {
              if (index == 1 || index == totalPages - 2) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text("...",
                      style:
                          GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                );
              }
              return const SizedBox.shrink();
            }
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _buildPageNumberButton(index, totalPages),
          );
        }),
        const SizedBox(width: 4),
        _buildPageNavButton(
          icon: Icons.chevron_right,
          enabled: _currentPage < totalPages - 1,
          onTap: () => setState(() => _currentPage++),
        ),
      ],
    );
  }

  Widget _buildPageNavButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: enabled ? Colors.grey.shade300 : Colors.grey.shade200,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? Colors.black87 : Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildPageNumberButton(int pageIndex, int totalPages) {
    final bool isActive = _currentPage == pageIndex;
    return GestureDetector(
      onTap: () => setState(() => _currentPage = pageIndex),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isActive ? _blue : Colors.white,
          border: Border.all(
            color: isActive ? _blue : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            "${pageIndex + 1}",
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWhiteCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  DataRow _buildDataRow(FieldItem field) {
    return DataRow(
      color: WidgetStateProperty.all(Colors.white),
      cells: [
        DataCell(
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8)),
                child: field.images.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          field.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const Icon(Icons.sports,
                              color: Colors.grey, size: 18),
                        ),
                      )
                    : const Icon(Icons.sports, color: Colors.grey, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(field.name,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF111827),
                          fontSize: 12)),
                  Text("ID: ${field.id}",
                      style:
                          GoogleFonts.inter(color: Colors.grey, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getCategoryBgColor(field.type),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              field.type,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _getCategoryTextColor(field.type),
              ),
            ),
          ),
        ),
        DataCell(Text(
          formatRupiahAkuntansi(field.price),
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        )),
        DataCell(Row(
          children: [
            Icon(Icons.circle,
                size: 8,
                color: field.status == "Aktif" ? Colors.green : Colors.grey),
            const SizedBox(width: 6),
            Text(
              field.status,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: field.status == "Aktif" ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.w500),
            ),
          ],
        )),
        DataCell(
          GestureDetector(
            onTapDown: (details) =>
                _showActionMenu(context, field, details.globalPosition),
            child: const Icon(Icons.more_horiz, color: Colors.grey, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, String? subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: _blue, size: 16),
                ),
                if (subtitle != null)
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(title,
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 2),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}