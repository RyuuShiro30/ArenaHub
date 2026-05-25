import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// ══════════════════════════════════════════════════════════════════════════════
// MODEL
// ══════════════════════════════════════════════════════════════════════════════

enum StatusJadwal { tersedia, tidakTersedia, dipesan }

class JadwalModel {
  final String id;
  final String lapanganId;
  final String namaLapangan;
  final String jenisLapangan;
  final String imagePath;
  final DateTime tanggal;
  final String waktuMulai;
  final String waktuSelesai;
  final int harga;
  final StatusJadwal status;

  const JadwalModel({
    required this.id,
    required this.lapanganId,
    required this.namaLapangan,
    required this.jenisLapangan,
    required this.imagePath,
    required this.tanggal,
    required this.waktuMulai,
    required this.waktuSelesai,
    required this.harga,
    required this.status,
  });

  String get waktuOperasional => '$waktuMulai - $waktuSelesai';

  static StatusJadwal _parseStatus(String? s) {
    switch (s) {
      case 'tidak_tersedia': return StatusJadwal.tidakTersedia;
      case 'dipesan':        return StatusJadwal.dipesan;
      default:               return StatusJadwal.tersedia;
    }
  }

  static String statusToString(StatusJadwal s) {
    switch (s) {
      case StatusJadwal.tidakTersedia: return 'tidak_tersedia';
      case StatusJadwal.dipesan:       return 'dipesan';
      default:                         return 'tersedia';
    }
  }

  factory JadwalModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return JadwalModel(
      id:            doc.id,
      lapanganId:    d['lapangan_id']    ?? '',
      namaLapangan:  d['nama_lapangan']  ?? '',
      jenisLapangan: d['jenis_lapangan'] ?? '',
      imagePath:     d['image_url']      ?? '',
      tanggal:       (d['tanggal'] as Timestamp?)?.toDate() ?? DateTime.now(),
      waktuMulai:    d['waktu_mulai']    ?? '',
      waktuSelesai:  d['waktu_selesai']  ?? '',
      harga:         (d['harga'] ?? 0) is int
                         ? d['harga']
                         : int.tryParse(d['harga'].toString()) ?? 0,
      status:        _parseStatus(d['status']),
    );
  }

  Map<String, dynamic> toMap() => {
    'lapangan_id':       lapanganId,
    'nama_lapangan':     namaLapangan,
    'jenis_lapangan':    jenisLapangan,
    'image_url':         imagePath,
    'tanggal':           Timestamp.fromDate(tanggal),
    'waktu_mulai':       waktuMulai,
    'waktu_selesai':     waktuSelesai,
    'waktu_operasional': waktuOperasional,
    'harga':             harga,
    'status':            statusToString(status),
    'created_at':        FieldValue.serverTimestamp(),
  };
}

// ══════════════════════════════════════════════════════════════════════════════
// FILTER LANJUTAN MODEL
// ══════════════════════════════════════════════════════════════════════════════

enum FilterStatus { semua, tersedia, tidakTersedia, dipesan }

class FilterLanjutan {
  final FilterStatus status;
  final String? jamMulai;  // e.g. "06:00"
  final String? jamSelesai; // e.g. "12:00"

  const FilterLanjutan({
    this.status = FilterStatus.semua,
    this.jamMulai,
    this.jamSelesai,
  });

  bool get hasFilter =>
      status != FilterStatus.semua ||
      jamMulai != null ||
      jamSelesai != null;
}

// ══════════════════════════════════════════════════════════════════════════════
// SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class KelolaJadwalScreen extends StatefulWidget {
  const KelolaJadwalScreen({super.key});
  @override
  State<KelolaJadwalScreen> createState() => _KelolaJadwalScreenState();
}

class _KelolaJadwalScreenState extends State<KelolaJadwalScreen> {
  static const _primary   = Color(0xFF1565C0);
  static const _bgColor   = Color(0xFFF5F7FA);
  static const _textDark  = Color(0xFF1A1A2E);
  static const _borderCol = Color(0xFFDDE3EE);

  String _selectedLapanganId = '';
  late DateTimeRange _selectedRange;
  int _currentPage  = 1;
  final int _perPage = 5;
  FilterLanjutan _filter = const FilterLanjutan();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedRange = DateTimeRange(
        start: now, end: now.add(const Duration(days: 7)));
  }

  Stream<QuerySnapshot> get _jadwalStream {
    Query q = FirebaseFirestore.instance
        .collection('jadwal')
        .orderBy('tanggal');
    if (_selectedLapanganId.isNotEmpty) {
      q = q.where('lapangan_id', isEqualTo: _selectedLapanganId);
    }
    final startOfDay = DateTime(_selectedRange.start.year,
        _selectedRange.start.month, _selectedRange.start.day, 0, 0, 0);
    final endOfDay = DateTime(_selectedRange.end.year,
        _selectedRange.end.month, _selectedRange.end.day, 23, 59, 59);
    return q
        .where('tanggal',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('tanggal',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .snapshots();
  }

  // ── FIX #3: Sort urut tanggal + waktu mulai ───────────────────
  List<JadwalModel> _sortedList(List<JadwalModel> list) {
    final sorted = List<JadwalModel>.from(list);
    sorted.sort((a, b) {
      final tglCmp = a.tanggal.compareTo(b.tanggal);
      if (tglCmp != 0) return tglCmp;
      // Parse jam:menit untuk sort yang akurat
      final aParts = a.waktuMulai.split(':');
      final bParts = b.waktuMulai.split(':');
      final aMin = (int.tryParse(aParts[0]) ?? 0) * 60 +
          (int.tryParse(aParts.length > 1 ? aParts[1] : '0') ?? 0);
      final bMin = (int.tryParse(bParts[0]) ?? 0) * 60 +
          (int.tryParse(bParts.length > 1 ? bParts[1] : '0') ?? 0);
      return aMin.compareTo(bMin);
    });
    return sorted;
  }

  // ── Apply filter lanjutan ─────────────────────────────────────
  List<JadwalModel> _applyFilter(List<JadwalModel> list) {
    return list.where((j) {
      // Filter status
      if (_filter.status != FilterStatus.semua) {
        final target = switch (_filter.status) {
          FilterStatus.tersedia      => StatusJadwal.tersedia,
          FilterStatus.tidakTersedia => StatusJadwal.tidakTersedia,
          FilterStatus.dipesan       => StatusJadwal.dipesan,
          _                          => StatusJadwal.tersedia,
        };
        if (j.status != target) return false;
      }
      // Filter jam mulai
      if (_filter.jamMulai != null) {
        final fH = int.tryParse(_filter.jamMulai!.split(':')[0]) ?? 0;
        final jH = int.tryParse(j.waktuMulai.split(':')[0]) ?? 0;
        if (jH < fH) return false;
      }
      // Filter jam selesai
      if (_filter.jamSelesai != null) {
        final fH = int.tryParse(_filter.jamSelesai!.split(':')[0]) ?? 0;
        final jH = int.tryParse(j.waktuSelesai.split(':')[0]) ?? 0;
        if (jH > fH) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _updateStatus(String id, StatusJadwal s) =>
      FirebaseFirestore.instance
          .collection('jadwal')
          .doc(id)
          .update({'status': JadwalModel.statusToString(s)});

  Future<void> _deleteJadwal(JadwalModel j) async {
    await FirebaseFirestore.instance.collection('jadwal').doc(j.id).delete();
    if (mounted) _snack('Jadwal ${j.namaLapangan} berhasil dihapus', color: Colors.green.shade700);
  }

  void _snack(String msg, {Color color = Colors.black87}) =>
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: color));

  String _fmtTgl(DateTime dt) =>
      DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(dt);

  String _fmtRange(DateTimeRange r) =>
      '${DateFormat('d MMM yyyy', 'id_ID').format(r.start)} - '
      '${DateFormat('d MMM yyyy', 'id_ID').format(r.end)}';

  // ── FIX #5: Dialog Filter Lanjutan ───────────────────────────
  Future<void> _showFilterLanjutan() async {
    FilterStatus tempStatus = _filter.status;
    String? tempJamMulai    = _filter.jamMulai;
    String? tempJamSelesai  = _filter.jamSelesai;

    const jamOptions = [
      null,'06:00','07:00','08:00','09:00','10:00','11:00',
      '12:00','13:00','14:00','15:00','16:00','17:00',
      '18:00','19:00','20:00','21:00','22:00',
    ];

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Icon(Icons.tune_rounded, size: 20, color: Color(0xFF1565C0)),
            SizedBox(width: 8),
            Text('Filter Lanjutan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter Status
                const Text('Status Ketersediaan',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF444444))),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    _filterChip('Semua',        FilterStatus.semua,         tempStatus, (v) => setInner(() => tempStatus = v)),
                    _filterChip('Tersedia',     FilterStatus.tersedia,      tempStatus, (v) => setInner(() => tempStatus = v)),
                    _filterChip('Tidak Tersedia', FilterStatus.tidakTersedia, tempStatus, (v) => setInner(() => tempStatus = v)),
                    _filterChip('Dipesan',      FilterStatus.dipesan,       tempStatus, (v) => setInner(() => tempStatus = v)),
                  ],
                ),
                const SizedBox(height: 20),
                // Filter Rentang Jam
                const Text('Rentang Jam Operasional',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF444444))),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Dari jam', style: TextStyle(fontSize: 11.5, color: Color(0xFF9E9E9E))),
                    const SizedBox(height: 4),
                    _jamDropdown(tempJamMulai, jamOptions, (v) => setInner(() => tempJamMulai = v), hint: 'Semua'),
                  ])),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Sampai jam', style: TextStyle(fontSize: 11.5, color: Color(0xFF9E9E9E))),
                    const SizedBox(height: 4),
                    _jamDropdown(tempJamSelesai, jamOptions, (v) => setInner(() => tempJamSelesai = v), hint: 'Semua'),
                  ])),
                ]),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() { _filter = const FilterLanjutan(); _currentPage = 1; });
                Navigator.pop(ctx);
              },
              child: const Text('Reset', style: TextStyle(color: Color(0xFFE53935))),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: Color(0xFF9E9E9E))),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _filter = FilterLanjutan(
                    status: tempStatus,
                    jamMulai: tempJamMulai,
                    jamSelesai: tempJamSelesai,
                  );
                  _currentPage = 1;
                });
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: _primary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('Terapkan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, FilterStatus value, FilterStatus current, ValueChanged<FilterStatus> onTap) {
    final isActive = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? _primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? _primary : _borderCol),
        ),
        child: Text(label, style: TextStyle(
            fontSize: 12.5, fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : const Color(0xFF444444))),
      ),
    );
  }

  Widget _jamDropdown(String? value, List<String?> options,
      ValueChanged<String?> onChanged, {String hint = 'Pilih'}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
          border: Border.all(color: _borderCol),
          borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
          items: options.map((t) => DropdownMenuItem(
            value: t,
            child: Text(t ?? hint, style: const TextStyle(fontSize: 13)),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: StreamBuilder<QuerySnapshot>(
        stream: _jadwalStream,
        builder: (context, snap) {
          final rawList = snap.hasData
              ? snap.data!.docs.map((d) => JadwalModel.fromFirestore(d)).toList()
              : <JadwalModel>[];
          // FIX #3: sort dulu, lalu apply filter lanjutan
          final all = _applyFilter(_sortedList(rawList));

          final totalTersedia  = all.where((j) => j.status == StatusJadwal.tersedia).length;
          final totalTidak     = all.where((j) => j.status == StatusJadwal.tidakTersedia).length;
          final unitLapangan   = all.map((j) => j.lapanganId).toSet().length;
          final totalPages     = (all.length / _perPage).ceil().clamp(1, 9999);
          final start          = (_currentPage - 1) * _perPage;
          final end            = (start + _perPage).clamp(0, all.length);
          final pageItems      = all.sublist(start, end);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breadcrumb
                Row(children: [
                  Text('ARENAHUB', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade400, letterSpacing: 0.5)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.chevron_right_rounded, size: 14, color: Colors.grey.shade400)),
                  Text('MANAJEMEN JADWAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.5)),
                ]),
                const SizedBox(height: 12),

                // Title + FIX #1: button tanpa icon plus double
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Kelola Jadwal Lapangan',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _textDark)),
                    SizedBox(height: 6),
                    Text('Atur ketersediaan slot waktu untuk semua unit lapangan secara real-time.',
                        style: TextStyle(fontSize: 13.5, color: Color(0xFF9E9E9E))),
                  ]),
                  const Spacer(),
                  // FIX #1: hapus icon plus, cukup text saja
                  ElevatedButton(
                    onPressed: () => showDialog(
                        context: context,
                        builder: (_) => const _TambahJadwalDialog()),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0),
                    child: const Text('+ Tambah Jadwal Baru',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 28),

                // Stats
                if (snap.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator()
                else
                  Row(children: [
                    Expanded(child: _statsCard(icon: Icons.calendar_month_rounded, label: 'Total Slot', value: all.length.toString().padLeft(2, '0'), iconColor: _primary, iconBg: const Color(0xFFE3F2FD))),
                    const SizedBox(width: 16),
                    Expanded(child: _statsCard(icon: Icons.check_circle_outline_rounded, label: 'Tersedia', value: totalTersedia.toString().padLeft(2, '0'), iconColor: const Color(0xFF2E7D32), iconBg: const Color(0xFFE8F5E9))),
                    const SizedBox(width: 16),
                    Expanded(child: _statsCard(icon: Icons.cancel_outlined, label: 'Tidak Tersedia', value: totalTidak.toString().padLeft(2, '0'), iconColor: const Color(0xFFC62828), iconBg: const Color(0xFFFBE9E7))),
                    const SizedBox(width: 16),
                    Expanded(child: _statsCard(icon: Icons.sports_soccer_rounded, label: 'Unit Lapangan', value: unitLapangan.toString().padLeft(2, '0'), iconColor: Colors.white, iconBg: Colors.white, isHighlighted: true)),
                  ]),
                const SizedBox(height: 24),

                // Filter bar
                Row(children: [
                  _fLabel('PILIH LAPANGAN'),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 200,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('lapangan').snapshots(),
                      builder: (_, snap) {
                        final docs = snap.data?.docs ?? [];
                        return _inputBox(child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                          value: _selectedLapanganId, isExpanded: true,
                          style: const TextStyle(fontSize: 13, color: _textDark),
                          items: [
                            const DropdownMenuItem(value: '', child: Text('Semua Lapangan')),
                            ...docs.map((d) { final data = d.data() as Map<String, dynamic>; return DropdownMenuItem(value: d.id, child: Text(data['nama_lapangan'] ?? d.id, overflow: TextOverflow.ellipsis)); }),
                          ],
                          onChanged: (v) => setState(() { _selectedLapanganId = v ?? ''; _currentPage = 1; }),
                        )));
                      },
                    ),
                  ),
                  const SizedBox(width: 24),
                  _fLabel('RENTANG TANGGAL'),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context, firstDate: DateTime(2024), lastDate: DateTime(2027),
                        initialDateRange: _selectedRange,
                        builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _primary)), child: child!),
                      );
                      if (picked != null) setState(() { _selectedRange = picked; _currentPage = 1; });
                    },
                    child: _inputBox(child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.calendar_today_outlined, size: 15, color: Color(0xFF9E9E9E)),
                      const SizedBox(width: 8),
                      Text(_fmtRange(_selectedRange), style: const TextStyle(fontSize: 13, color: _textDark)),
                    ])),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () => _snack('Fitur ekspor segera hadir'),
                    icon: const Icon(Icons.download_outlined, size: 16),
                    label: const Text('Ekspor Data'),
                    style: OutlinedButton.styleFrom(foregroundColor: _textDark, side: const BorderSide(color: _borderCol), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 10),
                  // FIX #5: Filter Lanjutan buka dialog
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _showFilterLanjutan,
                        icon: const Icon(Icons.tune_rounded, size: 16),
                        label: const Text('Filter Lanjutan'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _filter.hasFilter ? _primary : const Color(0xFFEEF2FF),
                            foregroundColor: _filter.hasFilter ? Colors.white : _primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                      if (_filter.hasFilter)
                        Positioned(
                          top: -4, right: -4,
                          child: Container(
                            width: 10, height: 10,
                            decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle),
                          ),
                        ),
                    ],
                  ),
                ]),
                const SizedBox(height: 20),

                // Table
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8ECF0))),
                  child: Column(children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(children: [
                        _hCell('INFORMASI LAPANGAN', flex: 3),
                        _hCell('TANGGAL', flex: 2),
                        _hCell('WAKTU OPERASIONAL', flex: 2),
                        _hCell('STATUS KETERSEDIAAN', flex: 2),
                        _hCell('AKSI', flex: 1),
                      ]),
                    ),
                    const Divider(height: 1, color: Color(0xFFE8ECF0)),
                    if (pageItems.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: Column(children: [
                          Icon(Icons.calendar_today_outlined, size: 48, color: Color(0xFFCCCCCC)),
                          SizedBox(height: 12),
                          Text('Belum ada jadwal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF9E9E9E))),
                          SizedBox(height: 4),
                          Text('Tambah jadwal baru dengan tombol di atas', style: TextStyle(fontSize: 13, color: Color(0xFFBBBBBB))),
                        ])),
                      )
                    else
                      ...pageItems.asMap().entries.map((e) => Column(children: [
                        _tableRow(e.value),
                        if (e.key < pageItems.length - 1) const Divider(height: 1, color: Color(0xFFF5F5F5)),
                      ])),
                  ]),
                ),
                const SizedBox(height: 16),

                // FIX #4: Pagination yang benar — selalu tampilkan halaman aktif
                _buildPagination(all.length, totalPages),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── FIX #4: Pagination yang benar ────────────────────────────
  Widget _buildPagination(int totalItems, int totalPages) {
    final start = (_currentPage - 1) * _perPage + 1;
    final end   = (_currentPage * _perPage).clamp(0, totalItems);

    // Hitung range halaman yang ditampilkan (selalu include halaman aktif)
    List<int> pageNumbers = _getPageNumbers(totalPages);

    return Row(children: [
      Text('Menampilkan $start-$end dari $totalItems entri',
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF9E9E9E))),
      const Spacer(),
      _pgBtn(Icons.chevron_left_rounded,
          _currentPage > 1 ? () => setState(() => _currentPage--) : null),
      const SizedBox(width: 4),
      ...pageNumbers.map((pg) {
        if (pg == -1) {
          // Ellipsis
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('...', style: TextStyle(color: Color(0xFF9E9E9E))),
          );
        }
        final isActive = pg == _currentPage;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: GestureDetector(
            onTap: () => setState(() => _currentPage = pg),
            child: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                  color: isActive ? _primary : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isActive ? _primary : _borderCol)),
              child: Center(child: Text('$pg', style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : const Color(0xFF444444)))),
            ),
          ),
        );
      }),
      const SizedBox(width: 4),
      _pgBtn(Icons.chevron_right_rounded,
          _currentPage < totalPages ? () => setState(() => _currentPage++) : null),
    ]);
  }

  // Hasilkan list halaman dengan ellipsis yang selalu include halaman aktif
  List<int> _getPageNumbers(int totalPages) {
    if (totalPages <= 7) {
      return List.generate(totalPages, (i) => i + 1);
    }

    final current = _currentPage;
    final List<int> pages = [];

    // Selalu tampilkan halaman 1
    pages.add(1);

    if (current > 3) pages.add(-1); // ellipsis kiri

    // Tampilkan halaman sekitar halaman aktif
    for (int i = current - 1; i <= current + 1; i++) {
      if (i > 1 && i < totalPages) pages.add(i);
    }

    if (current < totalPages - 2) pages.add(-1); // ellipsis kanan

    // Selalu tampilkan halaman terakhir
    pages.add(totalPages);

    return pages;
  }

  // ── Widgets helpers ───────────────────────────────────────────

  Widget _statsCard({required IconData icon, required String label, required String value, required Color iconColor, required Color iconBg, bool isHighlighted = false}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(color: isHighlighted ? _primary : Colors.white, borderRadius: BorderRadius.circular(12), border: isHighlighted ? null : Border.all(color: const Color(0xFFE8ECF0)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: isHighlighted ? Colors.white.withOpacity(0.2) : iconBg, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 22, color: isHighlighted ? Colors.white : iconColor)),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isHighlighted ? Colors.white.withOpacity(0.8) : const Color(0xFF9E9E9E), letterSpacing: 0.3)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: isHighlighted ? Colors.white : _textDark)),
          ]),
        ]),
      );

  Widget _fLabel(String t) => Text(t, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF9E9E9E), letterSpacing: 0.5));
  Widget _inputBox({required Widget child}) => Container(height: 40, padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: _borderCol)), child: child);
  Widget _hCell(String t, {int flex = 1}) => Expanded(flex: flex, child: Text(t, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF9E9E9E), letterSpacing: 0.5)));

  Widget _tableRow(JadwalModel j) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(children: [
      Expanded(flex: 3, child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(8), child: j.imagePath.isNotEmpty
            ? Image.network(j.imagePath, width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _imgPH())
            : _imgPH()),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(j.namaLapangan, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _textDark)),
          Text('Indoor • ${j.jenisLapangan}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF9E9E9E))),
        ])),
      ])),
      Expanded(flex: 2, child: Text(_fmtTgl(j.tanggal), style: const TextStyle(fontSize: 13, color: Color(0xFF444444)))),
      Expanded(flex: 2, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(6)),
          child: Text(j.waktuOperasional, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1565C0))))),
      Expanded(flex: 2, child: _statusToggle(j)),
      Expanded(flex: 1, child: IconButton(
          tooltip: 'Hapus jadwal',
          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFE53935)),
          onPressed: () => _confirmDelete(j))),
    ]),
  );

  Widget _imgPH() => Container(
      width: 44, height: 44, color: const Color(0xFFE3EAF5),
      child: const Icon(Icons.sports_soccer_rounded, size: 22, color: Color(0xFF1565C0)));

  // ── FIX #2: Status toggle tanpa double icon ───────────────────
  Widget _statusToggle(JadwalModel j) {
    if (j.status == StatusJadwal.dipesan) {
      return _badge(
          label: 'Dipesan',
          icon: Icons.lock_outline_rounded,
          textColor: const Color(0xFFF57C00),
          bg: const Color(0xFFFFF3E0),
          border: const Color(0xFFFFCC02));
    }
    final isTersedia = j.status == StatusJadwal.tersedia;
    return GestureDetector(
      onTap: () => _updateStatus(j.id,
          isTersedia ? StatusJadwal.tidakTersedia : StatusJadwal.tersedia),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: isTersedia ? const Color(0xFFE8F5E9) : const Color(0xFFFBE9E7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isTersedia ? const Color(0xFF66BB6A) : const Color(0xFFEF9A9A))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          // FIX #2: tersedia = ceklis saja, tidak tersedia = X saja (tanpa lingkaran)
          Icon(
            isTersedia ? Icons.check_rounded : Icons.close_rounded,
            size: 14,
            color: isTersedia ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
          ),
          const SizedBox(width: 5),
          Text(
            isTersedia ? 'Tersedia' : 'Tidak Tersedia',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: isTersedia ? const Color(0xFF2E7D32) : const Color(0xFFC62828)),
          ),
        ]),
      ),
    );
  }

  Widget _badge({required String label, required IconData icon, required Color textColor, required Color bg, required Color border}) =>
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor)),
          ]));

  Future<void> _confirmDelete(JadwalModel j) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Text('Hapus Jadwal', style: TextStyle(fontWeight: FontWeight.w700)),
      content: Text('Hapus jadwal ${j.namaLapangan} (${j.waktuOperasional}) pada ${_fmtTgl(j.tanggal)}?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Hapus')),
      ],
    ));
    if (ok == true) await _deleteJadwal(j);
  }

  Widget _pgBtn(IconData icon, VoidCallback? onTap) => GestureDetector(
      onTap: onTap,
      child: Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: _borderCol)),
          child: Icon(icon, size: 20, color: onTap != null ? const Color(0xFF444444) : const Color(0xFFCCCCCC))));
}

// ══════════════════════════════════════════════════════════════════════════════
// DIALOG TAMBAH JADWAL
// ══════════════════════════════════════════════════════════════════════════════

class _TambahJadwalDialog extends StatefulWidget {
  const _TambahJadwalDialog();
  @override
  State<_TambahJadwalDialog> createState() => _TambahJadwalDialogState();
}

class _TambahJadwalDialogState extends State<_TambahJadwalDialog> {
  static const _primary   = Color(0xFF1565C0);
  static const _borderCol = Color(0xFFDDE3EE);

  bool    _isBulkMode   = true;
  String? _lapanganId;
  String  _namaLapangan = '';
  String  _jenisLapangan= '';
  String  _imagePath    = '';
  int     _harga        = 0;
  DateTime _tanggal     = DateTime.now();
  String  _waktuMulai   = '08:00';
  String  _waktuSelesai = '09:00';
  String  _jamBuka      = '06:00';
  String  _jamTutup     = '21:00';
  bool    _isSubmitting = false;

  final List<String> _slots = [
    '06:00','07:00','08:00','09:00','10:00','11:00',
    '12:00','13:00','14:00','15:00','16:00','17:00',
    '18:00','19:00','20:00','21:00','22:00',
  ];

  List<Map<String, String>> get _previewSlots {
    final List<Map<String, String>> result = [];
    final startH = int.tryParse(_jamBuka.split(':')[0]) ?? 6;
    final endH   = int.tryParse(_jamTutup.split(':')[0]) ?? 21;
    for (int h = startH; h < endH; h++) {
      result.add({
        'mulai':   '${h.toString().padLeft(2, '0')}:00',
        'selesai': '${(h + 1).toString().padLeft(2, '0')}:00',
      });
    }
    return result;
  }

  Future<void> _submit() async {
    if (_lapanganId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih lapangan terlebih dahulu')));
      return;
    }
    if (_isBulkMode && _previewSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jam buka harus lebih kecil dari jam tutup')));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      if (_isBulkMode) {
        for (final slot in _previewSlots) {
          final ref = FirebaseFirestore.instance.collection('jadwal').doc();
          batch.set(ref, JadwalModel(id: '', lapanganId: _lapanganId!, namaLapangan: _namaLapangan, jenisLapangan: _jenisLapangan, imagePath: _imagePath, tanggal: _tanggal, waktuMulai: slot['mulai']!, waktuSelesai: slot['selesai']!, harga: _harga, status: StatusJadwal.tersedia).toMap());
        }
      } else {
        final ref = FirebaseFirestore.instance.collection('jadwal').doc();
        batch.set(ref, JadwalModel(id: '', lapanganId: _lapanganId!, namaLapangan: _namaLapangan, jenisLapangan: _jenisLapangan, imagePath: _imagePath, tanggal: _tanggal, waktuMulai: _waktuMulai, waktuSelesai: _waktuSelesai, harga: _harga, status: StatusJadwal.tersedia).toMap());
      }
      await batch.commit();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isBulkMode ? '${_previewSlots.length} slot berhasil dibuat!' : 'Slot berhasil dibuat!'),
          backgroundColor: Colors.green.shade700,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _tanggal, firstDate: DateTime.now(), lastDate: DateTime(2027),
        builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _primary)), child: child!));
    if (picked != null) setState(() => _tanggal = picked);
  }

  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Container(
      width: 580, constraints: const BoxConstraints(maxHeight: 680),
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Tambah Jadwal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
          const Spacer(),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, size: 20)),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Expanded(child: _modeBtn(label: '⚡ Generate Otomatis', active: _isBulkMode, onTap: () => setState(() => _isBulkMode = true))),
            Expanded(child: _modeBtn(label: 'Satu Slot', active: !_isBulkMode, onTap: () => setState(() => _isBulkMode = false))),
          ]),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _lbl('Pilih Lapangan'), const SizedBox(height: 6),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('lapangan').snapshots(),
                builder: (_, snap) {
                  final docs = snap.data?.docs ?? [];
                  return _box(child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                    value: _lapanganId, isExpanded: true, hint: const Text('Pilih lapangan...'),
                    items: docs.map((d) { final data = d.data() as Map<String, dynamic>; return DropdownMenuItem(value: d.id, child: Text(data['nama_lapangan'] ?? d.id)); }).toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      final doc = docs.firstWhere((d) => d.id == v);
                      final data = doc.data() as Map<String, dynamic>;
                      setState(() {
                        _lapanganId = v; _namaLapangan = data['nama_lapangan'] ?? '';
                        _jenisLapangan = data['jenis_lapangan'] ?? '';
                        _imagePath = (data['foto'] as List?)?.isNotEmpty == true ? data['foto'][0] : '';
                        _harga = (data['harga'] ?? 0) is int ? data['harga'] : int.tryParse(data['harga'].toString()) ?? 0;
                      });
                    },
                  )));
                },
              ),
              const SizedBox(height: 14),
              _lbl('Tanggal'), const SizedBox(height: 6),
              GestureDetector(onTap: _pickDate, child: _box(child: Row(children: [
                const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF9E9E9E)),
                const SizedBox(width: 10),
                Text(DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_tanggal), style: const TextStyle(fontSize: 14)),
              ]))),
              const SizedBox(height: 14),
              if (_isBulkMode) ...[
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _lbl('Jam Buka'), const SizedBox(height: 6),
                    _box(child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: _jamBuka, isExpanded: true, items: _slots.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => _jamBuka = v ?? _jamBuka)))),
                  ])),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _lbl('Jam Tutup'), const SizedBox(height: 6),
                    _box(child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: _jamTutup, isExpanded: true, items: _slots.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => _jamTutup = v ?? _jamTutup)))),
                  ])),
                ]),
                const SizedBox(height: 14),
                if (_previewSlots.isNotEmpty) ...[
                  Row(children: [
                    const Text('Preview Slot', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF444444))),
                    const SizedBox(width: 8),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(20)),
                        child: Text('${_previewSlots.length} slot', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1565C0)))),
                  ]),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: _previewSlots.map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF66BB6A))),
                    child: Text('${s['mulai']} - ${s['selesai']}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32))),
                  )).toList()),
                ] else
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFFF3F3), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFFCDD2))),
                      child: const Text('Jam buka harus lebih kecil dari jam tutup', style: TextStyle(fontSize: 12, color: Color(0xFFC62828)))),
              ],
              if (!_isBulkMode) Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _lbl('Waktu Mulai'), const SizedBox(height: 6),
                  _box(child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: _waktuMulai, isExpanded: true, items: _slots.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => _waktuMulai = v ?? _waktuMulai)))),
                ])),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _lbl('Waktu Selesai'), const SizedBox(height: 6),
                  _box(child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: _waktuSelesai, isExpanded: true, items: _slots.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => _waktuSelesai = v ?? _waktuSelesai)))),
                ])),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          OutlinedButton(onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF444444), side: const BorderSide(color: _borderCol), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13)),
              child: const Text('Batal')),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13)),
            child: _isSubmitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(_isBulkMode ? 'Generate ${_previewSlots.length} Slot' : 'Simpan Slot', style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ]),
      ]),
    ),
  );

  Widget _modeBtn({required String label, required bool active, required VoidCallback onTap}) =>
      GestureDetector(onTap: onTap, child: AnimatedContainer(
        duration: const Duration(milliseconds: 160), height: 36,
        decoration: BoxDecoration(color: active ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(8),
            boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))] : []),
        child: Center(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? _primary : const Color(0xFF9E9E9E)))),
      ));

  Widget _lbl(String t) => Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF444444)));
  Widget _box({required Widget child}) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(border: Border.all(color: _borderCol), borderRadius: BorderRadius.circular(10)), child: child);
}