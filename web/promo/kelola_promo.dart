import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../sidebar.dart';

class KelolaPromoScreen extends StatefulWidget {
  const KelolaPromoScreen({super.key});
  @override
  State<KelolaPromoScreen> createState() => _KelolaPromoScreenState();
}

class _KelolaPromoScreenState extends State<KelolaPromoScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _searchCtrl = TextEditingController();
  String _search = '';
  DateTime? _filterDate;
  bool get _hasFilter => _filterDate != null;

  static const Color _blue   = Color(0xFF2563EB);
  static const Color _blueBg = Color(0xFFEFF6FF);
  static const Color _bg     = Color(0xFFF4F6F9);
  static const Color _white  = Color(0xFFFFFFFF);
  static const Color _text   = Color(0xFF1A2B3C);
  static const Color _muted  = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _green  = Color(0xFF22C55E);
  static const Color _orange = Color(0xFFF59E0B);
  static const Color _red    = Color(0xFFEF4444);

  TextStyle _t({double size = 14, FontWeight weight = FontWeight.normal,
      Color color = _text, double spacing = 0}) =>
      GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: weight,
          color: color, letterSpacing: spacing);

  String _rp(dynamic v) {
    final d = double.tryParse(v?.toString() ?? '0') ?? 0;
    return 'Rp ${NumberFormat('#,###', 'id_ID').format(d.toInt())}';
  }

  String _tanggal(dynamic v) {
    if (v == null) return '-';
    if (v is Timestamp) {
      return DateFormat('d MMMM yyyy', 'id_ID').format(v.toDate());
    }
    if (v is String) {
      try { return DateFormat('d MMMM yyyy', 'id_ID').format(DateTime.parse(v)); }
      catch (_) { return v; }
    }
    return '-';
  }

  bool _isExpired(dynamic expiredAt) {
    if (expiredAt == null) return false;
    DateTime? dt;
    if (expiredAt is Timestamp) dt = expiredAt.toDate();
    if (expiredAt is String) {
      try { dt = DateTime.parse(expiredAt); } catch (_) {}
    }
    if (dt == null) return false;
    return dt.isBefore(DateTime.now());
  }

  String get _filterLabel => _filterDate != null
      ? DateFormat('d MMMM yyyy', 'id_ID').format(_filterDate!)
      : '';

  bool _matchesFilter(Map<String, dynamic> p) {
    if (!_hasFilter) return true;
    final exp = p['expiredAt'];
    DateTime? dt;
    if (exp is Timestamp) dt = exp.toDate();
    if (exp is String) { try { dt = DateTime.parse(exp); } catch (_) {} }
    if (dt == null) return false;
    return dt.year == _filterDate!.year &&
           dt.month == _filterDate!.month &&
           dt.day == _filterDate!.day;
  }

  Map<String, dynamic> _calcStats(List<Map<String, dynamic>> all) {
    int total = all.length, aktif = 0, expired = 0, totalUsed = 0;
    for (final p in all) {
      final isAktif = p['aktif'] == true;
      final isExp   = _isExpired(p['expiredAt']);
      if (isAktif && !isExp) aktif++;
      if (isExp) expired++;
      totalUsed += int.tryParse(p['used']?.toString() ?? '0') ?? 0;
    }
    return {'total': total, 'aktif': aktif, 'expired': expired, 'used': totalUsed};
  }

  void _showFilter() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) setState(() => _filterDate = picked);
  }

// form tambah/edit
  void _showForm({Map<String, dynamic>? promo}) {
    final isEdit = promo != null;
    final kodeCtrl   = TextEditingController(text: promo?['kode'] ?? '');
    final diskonCtrl = TextEditingController(
        text: promo?['diskon']?.toString() ?? '');
    final kuotaCtrl  = TextEditingController(
        text: promo?['kuota']?.toString() ?? '');
    final minCtrl    = TextEditingController(
        text: promo?['minimalTransaksi']?.toString() ?? '');
    bool aktif = promo?['aktif'] ?? true;

    DateTime? expiredAt;
    final rawExp = promo?['expiredAt'];
    if (rawExp is Timestamp) expiredAt = rawExp.toDate();
    if (rawExp is String) {
      try { expiredAt = DateTime.parse(rawExp); } catch (_) {}
    }

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: formKey,
                child: Column(mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Header
                  Row(children: [
                    Text(isEdit ? 'Edit Promo' : 'Tambah Promo',
                        style: _t(size: 17, weight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx)),
                  ]),
                  const SizedBox(height: 20),

                  // Kode
                  _formField(
                    label: 'Kode Promo',
                    controller: kodeCtrl,
                    hint: 'Contoh: ARENA10',
                    validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 14),

                  // Diskon & Kuota
                  Row(children: [
                    Expanded(child: _formField(
                      label: 'Diskon (Rp)',
                      controller: diskonCtrl,
                      hint: '10000',
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _formField(
                      label: 'Kuota',
                      controller: kuotaCtrl,
                      hint: '100',
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                    )),
                  ]),
                  const SizedBox(height: 14),

                  // Minimal Transaksi
                  _formField(
                    label: 'Minimal Transaksi (Rp)',
                    controller: minCtrl,
                    hint: '50000',
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),

                  // Expired At
                  Text('Tanggal Kadaluarsa',
                      style: _t(size: 12, weight: FontWeight.w600, color: _muted)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: expiredAt ?? now,
                        firstDate: now,
                        lastDate: DateTime(now.year + 5),
                        locale: const Locale('id', 'ID'),
                      );
                      if (picked != null) setDlg(() => expiredAt = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                          color: _bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: expiredAt != null ? _blue : _border)),
                      child: Row(children: [
                        Icon(Icons.calendar_today_rounded, size: 18,
                            color: expiredAt != null ? _blue : _muted),
                        const SizedBox(width: 10),
                        Text(
                          expiredAt != null
                              ? DateFormat('d MMMM yyyy', 'id_ID').format(expiredAt!)
                              : 'Pilih tanggal kadaluarsa',
                          style: _t(size: 13,
                              color: expiredAt != null ? _text : _muted),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Status Aktif
                  Row(children: [
                    Text('Status Aktif',
                        style: _t(size: 12, weight: FontWeight.w600, color: _muted)),
                    const Spacer(),
                    Switch(
                      value: aktif,
                      activeThumbColor: _blue,
                      onChanged: (v) => setDlg(() => aktif = v),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Tombol simpan
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        if (expiredAt == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Pilih tanggal kadaluarsa dulu',
                                style: _t(color: Colors.white))),
                          );
                          return;
                        }
                        final data = {
                          'kode'             : kodeCtrl.text.trim().toUpperCase(),
                          'diskon'           : int.tryParse(diskonCtrl.text) ?? 0,
                          'kuota'            : int.tryParse(kuotaCtrl.text) ?? 0,
                          'minimalTransaksi' : int.tryParse(minCtrl.text) ?? 0,
                          'expiredAt'        : Timestamp.fromDate(expiredAt!),
                          'aktif'            : aktif,
                        };
                        if (isEdit) {
                          await _firestore.collection('promos')
                              .doc(promo['id']).update(data);
                        } else {
                          data['used'] = 0;
                          await _firestore.collection('promos').add(data);
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _blue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Promo',
                          style: _t(size: 14, weight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: _t(size: 12, weight: FontWeight.w600, color: _muted)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        validator: validator,
        style: _t(size: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: _t(size: 13, color: _muted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _blue)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _red)),
          filled: true,
          fillColor: _bg,
        ),
      ),
    ]);
  }

//   hapus
  void _confirmDelete(Map<String, dynamic> p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Promo?',
            style: _t(size: 16, weight: FontWeight.w700)),
        content: Text('Promo ${p['kode']} akan dihapus permanen.',
            style: _t(size: 13, color: _muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: _t(size: 14, color: _muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('Hapus',
                style: _t(size: 14, weight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _firestore.collection('promos').doc(p['id']).delete();
    }
  }

  // build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Row( // <-- PENAMBAHAN ROW DAN SIDEBAR DI SINI
        children: [
          const AdminSidebar(currentIndex: 3), // PANGGIL SIDEBAR, INDEX 3 UNTUK KELOLA PROMO
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('promos').snapshots(),
              builder: (ctx, snap) {
                final all = snap.hasData
                    ? snap.data!.docs
                        .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
                        .toList()
                    : <Map<String, dynamic>>[];

                final dateFiltered = all.where(_matchesFilter).toList();
                final filtered = _search.isEmpty
                    ? dateFiltered
                    : dateFiltered.where((p) {
                        final kode = (p['kode'] ?? '').toString().toLowerCase();
                        return kode.contains(_search.toLowerCase());
                      }).toList();

                final stats = _calcStats(all);

                return Column(children: [
                  // Top Bar
                  _buildTopBar(),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Row(
                            children: [
                                Text(
                                'Kelola Promo',
                                style: _t(size: 22, weight: FontWeight.w800),
                                ),

                                const Spacer(),

                                GestureDetector(
                                onTap: () => _showForm(),
                                child: Container(
                                    padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                    color: _blue,
                                    borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                        const Icon(
                                        Icons.add_rounded,
                                        size: 18,
                                        color: Colors.white,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                        'Tambah Promo',
                                        style: _t(
                                            size: 13,
                                            weight: FontWeight.w600,
                                            color: Colors.white,
                                        ),
                                        ),
                                    ],
                                    ),
                                ),
                                ),
                            ],
                            ),

                            const SizedBox(height: 8),

                            Text(
                            'Kelola kode promo dan diskon untuk pengguna ArenaHub.',
                            style: _t(size: 13, color: _muted),
                            ),

                            const SizedBox(height: 8),


                          // Stat Cards
                          Row(children: [
                            _statCard(icon: Icons.local_offer_outlined,
                                iconColor: _blue, label: 'Total Promo',
                                value: stats['total'].toString()),
                            const SizedBox(width: 12),
                            _statCard(icon: Icons.check_circle_outline_rounded,
                                iconColor: _green, label: 'Promo Aktif',
                                value: stats['aktif'].toString()),
                            const SizedBox(width: 12),
                            _statCard(icon: Icons.timelapse_rounded,
                                iconColor: _orange, label: 'Sudah Kadaluarsa',
                                value: stats['expired'].toString()),
                            const SizedBox(width: 12),
                            _statCard(icon: Icons.people_outline_rounded,
                                iconColor: _blue, label: 'Total Pemakaian',
                                value: stats['used'].toString()),
                          ]),
                          const SizedBox(height: 20),

                          _buildTable(filtered, snap.connectionState),
                        ],
                      ),
                    ),
                  ),
                ]);
              },
            ),
          ),
        ],
      ),
    );
  }

    Widget _buildTopBar() {
        return Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            decoration: const BoxDecoration(
            color: _white,
            border: Border(bottom: BorderSide(color: _border)),
            ),
            child: Row(
            children: [
                Text(
                'Kelola Promo',
                style: _t(size: 17, weight: FontWeight.w700),
                ),
            ],
            ),
        );
    }

  Widget _statCard({required IconData icon, required Color iconColor,
      required String label, required String value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: _white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 14),
          Text(label, style: _t(size: 11, color: _muted,
              weight: FontWeight.w600, spacing: 0.4)),
          const SizedBox(height: 6),
          Text(value, style: _t(size: 24, weight: FontWeight.w800),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  Widget _buildTable(List<Map<String, dynamic>> list, ConnectionState state) {
    return Container(
      decoration: BoxDecoration(color: _white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border)),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Daftar Promo',
                    style: _t(size: 15, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Semua kode promo',
                    style: _t(size: 12, color: _muted)),
              ]),
              const Spacer(),
              // Search
              Container(
                width: 240, height: 38,
                decoration: BoxDecoration(color: _bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _border)),
                child: Row(children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.search_rounded, size: 18, color: _muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _search = v),
                      style: _t(size: 13),
                      decoration: InputDecoration(
                        hintText: 'Cari kode promo...',
                        hintStyle: _t(size: 13, color: _muted),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_search.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        setState(() => _search = '');
                      },
                      child: const Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Icon(Icons.close_rounded, size: 16, color: _muted),
                      ),
                    ),
                ]),
              ),
              const SizedBox(width: 8),
              // Filter
              GestureDetector(
                onTap: _showFilter,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _hasFilter ? _blue : _white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _hasFilter ? _blue : _border),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.filter_list_rounded, size: 15,
                        color: _hasFilter ? Colors.white : _text),
                    const SizedBox(width: 6),
                    Text('Filter', style: _t(size: 13, weight: FontWeight.w600,
                        color: _hasFilter ? Colors.white : _text)),
                  ]),
                ),
              ),
            ]),

            // Badge filter aktif
            if (_hasFilter)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: _blueBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _blue.withOpacity(0.3))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.calendar_today_rounded, size: 13, color: _blue),
                    const SizedBox(width: 5),
                    Text(_filterLabel,
                        style: _t(size: 12, weight: FontWeight.w600, color: _blue)),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => setState(() => _filterDate = null),
                      child: const Icon(Icons.close_rounded, size: 14, color: _blue),
                    ),
                  ]),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 16),
        const Divider(color: _border, height: 1),

        if (state == ConnectionState.waiting)
          const Padding(padding: EdgeInsets.all(40),
              child: CircularProgressIndicator())
        else if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.all(40),
            child: Column(children: [
              const Icon(Icons.local_offer_outlined, size: 48, color: _muted),
              const SizedBox(height: 12),
              Text('Tidak ada promo', style: _t(size: 14, color: _muted)),
            ]),
          )
        else ...[
          _tableHeader(),
          ...list.map(_tableRow),
        ],

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _border))),
          child: Row(children: [
            Text('Menampilkan ${list.length} entri',
                style: _t(size: 12, color: _muted)),
          ]),
        ),
      ]),
    );
  }

  Widget _tableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(children: [
        _th('KODE', 2),
        _th('DISKON', 2),
        _th('MIN. TRANSAKSI', 2),
        _th('KUOTA / USED', 2),
        _th('KADALUARSA', 2),
        _th('STATUS', 2),
        _th('AKSI', 2),
      ]),
    );
  }

  Widget _th(String label, int flex) => Expanded(
    flex: flex,
    child: Text(label, style: _t(size: 11, weight: FontWeight.w700,
        color: _muted, spacing: 0.4)),
  );

  Widget _tableRow(Map<String, dynamic> p) {
    final kode     = p['kode'] ?? '-';
    final diskon   = _rp(p['diskon']);
    final minTrx   = _rp(p['minimalTransaksi']);
    final kuota    = p['kuota']?.toString() ?? '0';
    final used     = p['used']?.toString() ?? '0';
    final expired  = _tanggal(p['expiredAt']);
    final isAktif  = p['aktif'] == true;
    final isExp    = _isExpired(p['expiredAt']);

    // Status: kadaluarsa > nonaktif > aktif
    final statusLabel = isExp ? 'Kadaluarsa' : isAktif ? 'Aktif' : 'Nonaktif';
    final statusColor = isExp ? _orange : isAktif ? _green : _muted;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(children: [
          // Kode
            Expanded(flex: 2, child: Text(kode,
                style: _t(size: 13, weight: FontWeight.w600, color: _text,),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
            ),
            ),

          // Diskon
          Expanded(flex: 2, child: Text(diskon,
              style: _t(size: 13, weight: FontWeight.w600),
              maxLines: 1, overflow: TextOverflow.ellipsis)),

          // Min Transaksi
          Expanded(flex: 2, child: Text(minTrx,
              style: _t(size: 13), maxLines: 1,
              overflow: TextOverflow.ellipsis)),

          // Kuota / Used
          Expanded(flex: 2, child: Text('$used / $kuota',
              style: _t(size: 13), maxLines: 1,
              overflow: TextOverflow.ellipsis)),

          // Kadaluarsa
          Expanded(flex: 2, child: Text(expired,
              style: _t(size: 13), maxLines: 1,
              overflow: TextOverflow.ellipsis)),

          // Status badge
          Expanded(flex: 2, child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6,
                    decoration: BoxDecoration(
                        color: statusColor, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(statusLabel,
                    style: _t(size: 11, weight: FontWeight.w700,
                        color: statusColor)),
              ]),
            ),
          )),

          // Aksi
          Expanded(flex: 2, child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _iconBtn(Icons.edit_outlined, _blue, () => _showForm(promo: p)),
              const SizedBox(width: 4),
              _iconBtn(Icons.delete_outline_rounded, _red, () => _confirmDelete(p)),
            ],
          )),
        ]),
      ),
      const Divider(color: _border, height: 1, indent: 24, endIndent: 24),
    ]);
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) =>
      IconButton(
        icon: Icon(icon, size: 18, color: color),
        onPressed: onTap,
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
        splashRadius: 18,
      );
}