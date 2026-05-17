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
      case 'dipesan': return StatusJadwal.dipesan;
      default: return StatusJadwal.tersedia;
    }
  }

  static String statusToString(StatusJadwal s) {
    switch (s) {
      case StatusJadwal.tidakTersedia: return 'tidak_tersedia';
      case StatusJadwal.dipesan: return 'dipesan';
      default: return 'tersedia';
    }
  }

  factory JadwalModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return JadwalModel(
      id: doc.id,
      lapanganId: d['lapangan_id'] ?? '',
      namaLapangan: d['nama_lapangan'] ?? '',
      jenisLapangan: d['jenis_lapangan'] ?? '',
      imagePath: d['image_url'] ?? '',
      tanggal: (d['tanggal'] as Timestamp?)?.toDate() ?? DateTime.now(),
      waktuMulai: d['waktu_mulai'] ?? '',
      waktuSelesai: d['waktu_selesai'] ?? '',
      harga: (d['harga'] ?? 0) is int ? d['harga'] : int.tryParse(d['harga'].toString()) ?? 0,
      status: _parseStatus(d['status']),
    );
  }

  Map<String, dynamic> toMap() => {
    'lapangan_id': lapanganId,
    'nama_lapangan': namaLapangan,
    'jenis_lapangan': jenisLapangan,
    'image_url': imagePath,
    'tanggal': Timestamp.fromDate(tanggal),
    'waktu_mulai': waktuMulai,
    'waktu_selesai': waktuSelesai,
    'waktu_operasional': waktuOperasional,
    'harga': harga,
    'status': statusToString(status),
    'created_at': FieldValue.serverTimestamp(),
  };
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
  static const _primary = Color(0xFF1565C0);
  static const _bgColor = Color(0xFFF5F7FA);
  static const _textDark = Color(0xFF1A1A2E);
  static const _borderCol = Color(0xFFDDE3EE);

  String _selectedLapanganId = '';
  late DateTimeRange _selectedRange;
  int _currentPage = 1;
  final int _perPage = 5;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedRange = DateTimeRange(start: now, end: now.add(const Duration(days: 7)));
  }

  Stream<QuerySnapshot> get _jadwalStream {
    Query q = FirebaseFirestore.instance.collection('jadwal').orderBy('tanggal');
    if (_selectedLapanganId.isNotEmpty) { 
      q = q.where('lapangan_id', isEqualTo: _selectedLapanganId);
  }
  // ── Fix: pakai startOfDay dan endOfDay yang benar ──
  final startOfDay = DateTime(
    _selectedRange.start.year,
    _selectedRange.start.month,
    _selectedRange.start.day,
    0, 0, 0,
  );
  final endOfDay = DateTime(
    _selectedRange.end.year,
    _selectedRange.end.month,
    _selectedRange.end.day,
    23, 59, 59,
  );
    return q
        .where('tanggal', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('tanggal', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .snapshots();
  }

  Future<void> _updateStatus(String id, StatusJadwal s) =>
      FirebaseFirestore.instance.collection('jadwal').doc(id).update({'status': JadwalModel.statusToString(s)});

  Future<void> _deleteJadwal(JadwalModel j) async {
    await FirebaseFirestore.instance.collection('jadwal').doc(j.id).delete();
    if (mounted) _snack('Jadwal ${j.namaLapangan} berhasil dihapus', color: Colors.green.shade700);
  }

  void _snack(String msg, {Color color = Colors.black87}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));

  String _fmtTgl(DateTime dt) => DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(dt);
  String _fmtRange(DateTimeRange r) => '${DateFormat('d MMM yyyy', 'id_ID').format(r.start)} - ${DateFormat('d MMM yyyy', 'id_ID').format(r.end)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: StreamBuilder<QuerySnapshot>(
        stream: _jadwalStream,
        builder: (context, snap) {
          final all = snap.hasData
              ? snap.data!.docs.map((d) => JadwalModel.fromFirestore(d)).toList()
              : <JadwalModel>[];
          final totalTersedia = all.where((j) => j.status == StatusJadwal.tersedia).length;
          final totalTidak = all.where((j) => j.status == StatusJadwal.tidakTersedia).length;
          final unitLapangan = all.map((j) => j.lapanganId).toSet().length;
          final totalPages = (all.length / _perPage).ceil().clamp(1, 9999);
          final start = (_currentPage - 1) * _perPage;
          final end = (start + _perPage).clamp(0, all.length);
          final pageItems = all.sublist(start, end);

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
                // Title + button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Kelola Jadwal Lapangan', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _textDark)),
                      SizedBox(height: 6),
                      Text('Atur ketersediaan slot waktu untuk semua unit lapangan secara real-time.',
                          style: TextStyle(fontSize: 13.5, color: Color(0xFF9E9E9E))),
                    ]),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => showDialog(context: context, builder: (_) => _TambahJadwalDialog()),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('+ Tambah Jadwal Baru', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0,
                      ),
                    ),
                  ],
                ),
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
                  ElevatedButton.icon(
                    onPressed: () => _snack('Filter lanjutan segera hadir'),
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: const Text('Filter Lanjutan'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEEF2FF), foregroundColor: _primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(height: 20),
                // Table
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8ECF0))),
                  child: Column(children: [
                    // Header
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
                // Pagination
                Row(children: [
                  Text('Menampilkan ${(_currentPage - 1) * _perPage + 1}-${(_currentPage * _perPage).clamp(0, all.length)} dari ${all.length} entri',
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF9E9E9E))),
                  const Spacer(),
                  _pgBtn(Icons.chevron_left_rounded, _currentPage > 1 ? () => setState(() => _currentPage--) : null),
                  const SizedBox(width: 4),
                  ...List.generate(totalPages > 5 ? 5 : totalPages, (i) {
                    final pg = i + 1; final isActive = pg == _currentPage;
                    return Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: GestureDetector(
                      onTap: () => setState(() => _currentPage = pg),
                      child: Container(width: 34, height: 34, decoration: BoxDecoration(color: isActive ? _primary : Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: isActive ? _primary : _borderCol)),
                          child: Center(child: Text('$pg', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? Colors.white : const Color(0xFF444444))))),
                    ));
                  }),
                  if (totalPages > 5) ...[
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('...', style: TextStyle(color: Color(0xFF9E9E9E)))),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: GestureDetector(
                      onTap: () => setState(() => _currentPage = totalPages),
                      child: Container(width: 34, height: 34, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: _borderCol)),
                          child: Center(child: Text('$totalPages', style: const TextStyle(fontSize: 13, color: Color(0xFF444444))))),
                    )),
                  ],
                  const SizedBox(width: 4),
                  _pgBtn(Icons.chevron_right_rounded, _currentPage < totalPages ? () => setState(() => _currentPage++) : null),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }

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
      Expanded(flex: 2, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(6)), child: Text(j.waktuOperasional, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _primary)))),
      Expanded(flex: 2, child: _statusToggle(j)),
      Expanded(flex: 1, child: IconButton(tooltip: 'Hapus jadwal', icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFE53935)), onPressed: () => _confirmDelete(j))),
    ]),
  );

  Widget _imgPH() => Container(width: 44, height: 44, color: const Color(0xFFE3EAF5), child: const Icon(Icons.sports_soccer_rounded, size: 22, color: _primary));

  Widget _statusToggle(JadwalModel j) {
    if (j.status == StatusJadwal.dipesan) return _badge(label: 'Dipesan', icon: Icons.lock_outline_rounded, textColor: const Color(0xFFF57C00), bg: const Color(0xFFFFF3E0), border: const Color(0xFFFFCC02));
    final isTersedia = j.status == StatusJadwal.tersedia;
    return GestureDetector(
      onTap: () => _updateStatus(j.id, isTersedia ? StatusJadwal.tidakTersedia : StatusJadwal.tersedia),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: isTersedia ? const Color(0xFFE8F5E9) : const Color(0xFFFBE9E7), borderRadius: BorderRadius.circular(20), border: Border.all(color: isTersedia ? const Color(0xFF66BB6A) : const Color(0xFFEF9A9A))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(isTersedia ? Icons.check_circle_outline_rounded : Icons.cancel_outlined, size: 13, color: isTersedia ? const Color(0xFF2E7D32) : const Color(0xFFC62828)),
          const SizedBox(width: 5),
          Text(isTersedia ? '● Tersedia' : 'x Tidak Tersedia', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isTersedia ? const Color(0xFF2E7D32) : const Color(0xFFC62828))),
        ]),
      ),
    );
  }

  Widget _badge({required String label, required IconData icon, required Color textColor, required Color bg, required Color border}) =>
      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 13, color: textColor), const SizedBox(width: 5), Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor))]));

  Future<void> _confirmDelete(JadwalModel j) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Text('Hapus Jadwal', style: TextStyle(fontWeight: FontWeight.w700)),
      content: Text('Hapus jadwal ${j.namaLapangan} (${j.waktuOperasional}) pada ${_fmtTgl(j.tanggal)}?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Hapus')),
      ],
    ));
    if (ok == true) await _deleteJadwal(j);
  }

  Widget _pgBtn(IconData icon, VoidCallback? onTap) => GestureDetector(onTap: onTap, child: Container(width: 34, height: 34, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: _borderCol)), child: Icon(icon, size: 20, color: onTap != null ? const Color(0xFF444444) : const Color(0xFFCCCCCC))));
}

// ══════════════════════════════════════════════════════════════════════════════
// DIALOG TAMBAH JADWAL
// ══════════════════════════════════════════════════════════════════════════════

class _TambahJadwalDialog extends StatefulWidget {
  @override
  State<_TambahJadwalDialog> createState() => _TambahJadwalDialogState();
}

class _TambahJadwalDialogState extends State<_TambahJadwalDialog> {
  static const _primary = Color(0xFF1565C0);
  static const _borderCol = Color(0xFFDDE3EE);

  String? _lapanganId;
  String _namaLapangan = '';
  String _jenisLapangan = '';
  String _imagePath = '';
  int _harga = 0;
  DateTime _tanggal = DateTime.now();
  String _waktuMulai = '08:00';
  String _waktuSelesai = '09:00';
  bool _isSubmitting = false;

  final List<String> _slots = ['06:00','07:00','08:00','09:00','10:00','11:00','12:00','13:00','14:00','15:00','16:00','17:00','18:00','19:00','20:00','21:00','22:00'];

  Future<void> _submit() async {
    if (_lapanganId == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih lapangan terlebih dahulu'))); return; }
    setState(() => _isSubmitting = true);
    try {
      await FirebaseFirestore.instance.collection('jadwal').add(JadwalModel(id: '', lapanganId: _lapanganId!, namaLapangan: _namaLapangan, jenisLapangan: _jenisLapangan, imagePath: _imagePath, tanggal: _tanggal, waktuMulai: _waktuMulai, waktuSelesai: _waktuSelesai, harga: _harga, status: StatusJadwal.tersedia).toMap());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _tanggal, firstDate: DateTime.now(), lastDate: DateTime(2027), builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _primary)), child: child!));
    if (picked != null) setState(() => _tanggal = picked);
  }

  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Container(
      width: 560, padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Tambah Jadwal Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
          const Spacer(),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, size: 20)),
        ]),
        const SizedBox(height: 20),
        _lbl('Pilih Lapangan'),
        const SizedBox(height: 6),
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
        const SizedBox(height: 16),
        _lbl('Tanggal'),
        const SizedBox(height: 6),
        GestureDetector(onTap: _pickDate, child: _box(child: Row(children: [
          const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF9E9E9E)),
          const SizedBox(width: 10),
          Text(DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_tanggal), style: const TextStyle(fontSize: 14)),
        ]))),
        const SizedBox(height: 16),
        Row(children: [
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
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF444444), side: const BorderSide(color: _borderCol), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13)), child: const Text('Batal')),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13)),
            child: _isSubmitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Simpan Jadwal', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ]),
      ]),
    ),
  );

  Widget _lbl(String t) => Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF444444)));
  Widget _box({required Widget child}) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(border: Border.all(color: _borderCol), borderRadius: BorderRadius.circular(10)), child: child);
}