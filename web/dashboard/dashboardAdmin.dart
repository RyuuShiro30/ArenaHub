import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../admin_notifiers.dart';
import 'package:excel/excel.dart' hide Border;
import 'dart:math' show min;
import 'dart:html' as html;
import '../sidebar.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth      = FirebaseAuth.instance;

  static const Color _blue   = Color(0xFF2563EB);
  static const Color _blueBg = Color(0xFFEFF6FF);
  static const Color _bg     = Color(0xFFF4F6F9);
  static const Color _white  = Color(0xFFFFFFFF);
  static const Color _text   = Color(0xFF1A2B3C);
  static const Color _muted  = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _green  = Color(0xFF22C55E);
  static const Color _orange = Color(0xFFF59E0B);

  String _adminName = 'Admin';
  String _adminRole = 'Administrator';

  @override
  void initState() {
    super.initState();
    _fetchAdminSession();
  }

  Future<void> _fetchAdminSession() async {
    try {
      final snap = await _firestore.collection('admin_profile').limit(1).get();
      if (snap.docs.isNotEmpty && mounted) {
        final data  = snap.docs.first.data();
        final nama  = data['fullName'] ?? 'Admin';
        final role  = data['level']   ?? 'Administrator';
        final photo = data['photoUrl'] as String?;
        setState(() {
          _adminName = nama;
          _adminRole = role;
        });
        adminNameNotifier.value  = nama;
        adminRoleNotifier.value  = role;
        adminPhotoNotifier.value = photo;
      }
    } catch (_) {}
  }

  bool _isSuccess(String s) {
    final v = s.toLowerCase().trim();
    return v == 'pembayaran selesai' || v == 'selesai' ||
        v == 'paid' || v == 'lunas' || v.contains('selesai');
  }

  bool _isPending(String s) {
    final v = s.toLowerCase().trim();
    return v == 'pending' || v == 'menunggu' || v.contains('pending');
  }

  bool _isGagal(String s) {
    final v = s.toLowerCase().trim();
    return v == 'gagal' || v == 'cancelled' || v == 'batal' ||
        v.contains('gagal') || v.contains('cancel') || v.contains('batal');
  }

  String _rp(double v) =>
      'Rp ${NumberFormat('#,###', 'id_ID').format(v.toInt())}';

  String _waktu(dynamic ts) {
    if (ts == null) return '-';
    try {
      final dt  = (ts as Timestamp).toDate();
      final now = DateTime.now();
      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        return 'Hari Ini, ${DateFormat('HH:mm').format(dt)}';
      }
      final tmr = now.add(const Duration(days: 1));
      if (dt.day == tmr.day && dt.month == tmr.month) {
        return 'Esok, ${DateFormat('HH:mm').format(dt)}';
      }
      return DateFormat('d MMM, HH:mm', 'id_ID').format(dt);
    } catch (_) { return '-'; }
  }

  String _initials(String name) {
    final p = name.trim().split(' ');
    return p.length >= 2
        ? '${p[0][0]}${p[1][0]}'.toUpperCase()
        : name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color _sc(String? s) {
    if (s == null) return _muted;
    if (_isSuccess(s)) return _blue;
    if (_isPending(s)) return _orange;
    if (_isGagal(s)) return const Color(0xFFEF4444);
    return _muted;
  }

  String _sl(String? s) {
    if (s == null) return '-';
    if (_isSuccess(s)) return 'SELESAI';
    if (_isPending(s)) return 'PENDING';
    if (_isGagal(s)) return 'GAGAL';
    return s.toUpperCase();
  }

  TextStyle _t({double size = 14, FontWeight weight = FontWeight.normal,
      Color color = _text, double spacing = 0}) =>
      GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: weight,
          color: color, letterSpacing: spacing);

  Future<void> _exportExcel() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final now   = DateTime.now();
      final start = DateTime(now.year, now.month, 1);
      final end   = DateTime(now.year, now.month + 1, 1);

      final snap = await _firestore
          .collection('bookings')
          .where('tanggal_booking', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('tanggal_booking', isLessThan: Timestamp.fromDate(end))
          .orderBy('tanggal_booking', descending: true)
          .get();

      final excelFile = Excel.createExcel();
      final sheet = excelFile['Laporan Booking'];
      excelFile.delete('Sheet1');

      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#2563EB'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        textWrapping: TextWrapping.WrapText,
      );
      final titleStyle = CellStyle(
        bold: true,
        fontSize: 14,
        fontColorHex: ExcelColor.fromHexString('#1A2B3C'),
      );
      final subStyle = CellStyle(
        fontSize: 10,
        fontColorHex: ExcelColor.fromHexString('#6B7280'),
      );
      final currencyStyle = CellStyle(numberFormat: NumFormat.defaultNumeric);
      final successStyle = CellStyle(
        fontColorHex: ExcelColor.fromHexString('#22C55E'),
        bold: true,
      );
      final pendingStyle = CellStyle(
        fontColorHex: ExcelColor.fromHexString('#F59E0B'),
        bold: true,
      );
      final gagalStyle = CellStyle(
        fontColorHex: ExcelColor.fromHexString('#EF4444'),
        bold: true,
      );

      const bulan = [
        '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];

      sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('G1'));
      sheet.cell(CellIndex.indexByString('A1')).value =
          TextCellValue('LAPORAN BOOKING BULANAN - ${bulan[now.month].toUpperCase()} ${now.year}');
      sheet.cell(CellIndex.indexByString('A1')).cellStyle = titleStyle;

      sheet.merge(CellIndex.indexByString('A2'), CellIndex.indexByString('G2'));
      sheet.cell(CellIndex.indexByString('A2')).value =
          TextCellValue('Digenerate pada: ${DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(now)}');
      sheet.cell(CellIndex.indexByString('A2')).cellStyle = subStyle;

      final headers = ['No', 'ID Booking', 'Nama Pelanggan', 'Lapangan',
          'Tanggal Booking', 'Total Harga (Rp)', 'Status'];
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 3));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      double grandTotal = 0;
      int successCount = 0, pendingCount = 0, gagalCount = 0;

      for (int i = 0; i < snap.docs.length; i++) {
        final data   = snap.docs[i].data();
        final docId  = snap.docs[i].id;
        final status = (data['status_pembayaran'] ?? data['status'] ?? '').toString();
        final total  = double.tryParse(data['total_harga']?.toString() ?? '0') ?? 0;
        final ts     = data['tanggal_booking'] as Timestamp?;
        final tglStr = ts != null
            ? DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(ts.toDate())
            : '-';

        if (_isSuccess(status))      { grandTotal += total; successCount++; }
        else if (_isPending(status)) pendingCount++;
        else if (_isGagal(status))   gagalCount++;

        final row = i + 4;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = IntCellValue(i + 1);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
            TextCellValue('#${docId.substring(0, min(8, docId.length)).toUpperCase()}');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value =
            TextCellValue(data['customer_name']?.toString() ?? '-');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value =
            TextCellValue(data['nama_lapangan']?.toString() ?? '-');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value =
            TextCellValue(tglStr);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
          ..value = DoubleCellValue(total)
          ..cellStyle = currencyStyle;

        final statusCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row));
        statusCell.value = TextCellValue(_sl(status));
        statusCell.cellStyle = _isSuccess(status) ? successStyle
            : _isPending(status) ? pendingStyle
            : _isGagal(status)   ? gagalStyle
            : CellStyle();
      }

      final refundSnap = await _firestore
    .collection('refund_requests')
    .where('status_refund', isEqualTo: 'disetujui')
    .get();

double totalRefund = 0;
for (final doc in refundSnap.docs) {
  final data      = doc.data();
  final harga     = double.tryParse(data['total_harga']?.toString() ?? '0') ?? 0;
  final createdAt = data['created_at'];
  if (createdAt != null) {
    final dt = (createdAt as Timestamp).toDate();
    if (dt.isAfter(start) && dt.isBefore(end)) {
      totalRefund += harga * 0.75; // 75% dari harga asli
    }
  }
}
final pendapatanBersih = grandTotal - totalRefund;

  final summaryRow = snap.docs.length + 5;

  // Baris 1: Pendapatan Kotor
  sheet.merge(
    CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow),
    CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: summaryRow),
  );
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow)).value =
      TextCellValue('TOTAL PENDAPATAN KOTOR');
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow)).cellStyle =
      CellStyle(bold: true, fontColorHex: ExcelColor.fromHexString('#2563EB'));
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: summaryRow)).value =
      DoubleCellValue(grandTotal);
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: summaryRow)).cellStyle =
      CellStyle(bold: true, fontColorHex: ExcelColor.fromHexString('#2563EB'),
          numberFormat: NumFormat.defaultNumeric);

  // Baris 2: Total Refund
  final refundRow = summaryRow + 1;
  sheet.merge(
    CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: refundRow),
    CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: refundRow),
  );
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: refundRow)).value =
      TextCellValue('TOTAL REFUND (75%)');
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: refundRow)).cellStyle =
      CellStyle(bold: true, fontColorHex: ExcelColor.fromHexString('#EF4444'));
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: refundRow)).value =
      DoubleCellValue(-totalRefund);
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: refundRow)).cellStyle =
      CellStyle(bold: true, fontColorHex: ExcelColor.fromHexString('#EF4444'),
          numberFormat: NumFormat.defaultNumeric);

  // Baris 3: Pendapatan Bersih
  final bersihRow = summaryRow + 2;
  sheet.merge(
    CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: bersihRow),
    CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: bersihRow),
  );
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: bersihRow)).value =
      TextCellValue('PENDAPATAN BERSIH');
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: bersihRow)).cellStyle =
      CellStyle(bold: true, fontColorHex: ExcelColor.fromHexString('#22C55E'));
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: bersihRow)).value =
      DoubleCellValue(pendapatanBersih);
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: bersihRow)).cellStyle =
      CellStyle(bold: true, fontColorHex: ExcelColor.fromHexString('#22C55E'),
          numberFormat: NumFormat.defaultNumeric);

  // Baris 4: Ringkasan status
  final s2 = summaryRow + 3;
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: s2)).value =
      TextCellValue('Selesai: $successCount  |  Pending: $pendingCount  |  Gagal: $gagalCount');
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: s2)).cellStyle =
      CellStyle(italic: true, fontColorHex: ExcelColor.fromHexString('#6B7280'));

  sheet.setColumnWidth(0, 6);
  sheet.setColumnWidth(1, 14);
  sheet.setColumnWidth(2, 24);
  sheet.setColumnWidth(3, 20);
  sheet.setColumnWidth(4, 22);
  sheet.setColumnWidth(5, 20);
  sheet.setColumnWidth(6, 14);

      final bytes = excelFile.encode();
      if (bytes == null) throw Exception('Gagal encode Excel');

      final fileName = 'Laporan_Booking_${bulan[now.month]}_${now.year}.xlsx';
      final blob = html.Blob([bytes],
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url    = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengekspor laporan: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Row(children: [
        const AdminSidebar(currentIndex: 0),
        Expanded(child: _buildDashboardStreams()),
      ]),
    );
  }

  Widget _buildDashboardStreams() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('bookings').snapshots(),
      builder: (context, bookingSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('lapangan').snapshots(),
          builder: (context, lapanganSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, userSnap) {
                return StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('refund_requests').snapshots(),
                  builder: (context, refundSnap) {
                    final now        = DateTime.now();
                    final start      = DateTime(now.year, now.month, 1);
                    final startLast  = DateTime(now.year, now.month - 1, 1);
                    final endLast    = DateTime(now.year, now.month, 1);
                    final end        = DateTime(now.year, now.month + 1, 1);
                    final todayStart = DateTime(now.year, now.month, now.day);
                    final todayEnd   = todayStart.add(const Duration(days: 1));

                    final isLoading =
                        (bookingSnap.connectionState == ConnectionState.waiting && !bookingSnap.hasData) ||
                        (lapanganSnap.connectionState == ConnectionState.waiting && !lapanganSnap.hasData) ||
                        (userSnap.connectionState == ConnectionState.waiting && !userSnap.hasData);

                    final allBookings = bookingSnap.hasData
                        ? bookingSnap.data!.docs
                            .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
                            .toList()
                        : <Map<String, dynamic>>[];

                    final todayStr = '${now.year}-'
                        '${now.month.toString().padLeft(2, '0')}-'
                        '${now.day.toString().padLeft(2, '0')}';

                    final bookingHariIni = allBookings.where((b) {
                      final tanggalMain = b['tanggal_main']?.toString() ?? '';
                      if (tanggalMain.isNotEmpty) return tanggalMain == todayStr;
                      final ts = b['tanggal_booking'];
                      if (ts == null) return false;
                      final dt = (ts as Timestamp).toDate();
                      return dt.isAfter(todayStart) && dt.isBefore(todayEnd);
                    }).length;

                    double pendapatanIni = 0, pendapatanLalu = 0;
                    for (final b in allBookings) {
                      final ts = b['tanggal_booking'];
                      if (ts == null) continue;
                      final dt     = (ts as Timestamp).toDate();
                      final harga  = double.tryParse(b['total_harga']?.toString() ?? '0') ?? 0;
                      final status = (b['status_pembayaran'] ?? '').toString();
                      if (_isSuccess(status) && dt.isAfter(start) && dt.isBefore(end))
                        pendapatanIni += harga;
                      if (_isSuccess(status) && dt.isAfter(startLast) && dt.isBefore(endLast))
                        pendapatanLalu += harga;
                    }

                    double totalRefundIni = 0;
                    if (refundSnap.hasData) {
                      for (final doc in refundSnap.data!.docs) {
                        final data      = doc.data() as Map<String, dynamic>;
                        final status    = (data['status_refund'] ?? '').toString().toLowerCase();
                        final harga     = double.tryParse(data['total_harga']?.toString() ?? '0') ?? 0;
                        final createdAt = data['created_at'];
                        if (status == 'disetujui' && createdAt != null) {
                          final dt = (createdAt as Timestamp).toDate();
                          if (dt.isAfter(start) && dt.isBefore(end)) {
                            totalRefundIni += harga * 0.75; // 75% dari harga asli
                          }
                        }
                      }
                    }
                    final pendapatanBersih = pendapatanIni - totalRefundIni;

                    final last24h = DateTime.now().subtract(const Duration(hours: 24));
                    final sorted = List<Map<String, dynamic>>.from(allBookings)
                      ..sort((a, b) {
                        final ta = a['tanggal_booking'];
                        final tb = b['tanggal_booking'];
                        if (ta == null || tb == null) return 0;
                        return (tb as Timestamp).compareTo(ta as Timestamp);
                      });

                    final bookingList = sorted.where((b) {
                      final ts = b['tanggal_booking'];
                      if (ts == null) return false;
                      final docId   = b['id'].toString();
                      final isChild = RegExp(r'_\d+$').hasMatch(docId);
                      return !isChild && (ts as Timestamp).toDate().isAfter(last24h);
                    }).take(10).toList();

                    final pelangganBaru = userSnap.hasData
                        ? userSnap.data!.docs.where((d) {
                            final data = d.data() as Map<String, dynamic>;
                            final ts   = data['createdAt'];
                            if (ts == null) return false;
                            return (ts as Timestamp).toDate().isAfter(start);
                          }).length
                        : 0;

                    return Column(children: [
                      _buildTopBar(),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(child: _buildPerformaCard(
                                      pendapatanIni: pendapatanBersih,
                                      totalRefund: totalRefundIni,
                                      isLoading: isLoading,
                                    )),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildPelangganCard(total: pelangganBaru)),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildBookingAktifCard(
                                      total: bookingHariIni,
                                      isLoading: isLoading,
                                    )),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildTableBooking(
                                bookingList: bookingList,
                                isLoading: isLoading,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 60, color: _white,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(children: [
        Text('Dashboard', style: _t(size: 17, weight: FontWeight.w700)),
        const Spacer(),
      ]),
    );
  }

  Widget _buildPerformaCard({
    required double pendapatanIni,
    required double totalRefund,
    required bool isLoading,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PERFORMA BULAN INI',
              style: _t(size: 11, weight: FontWeight.w700, color: _blue, spacing: 0.6)),
          const SizedBox(height: 10),
          isLoading
              ? _shimmer(w: 160, h: 28)
              : Text(_rp(pendapatanIni),
                  style: _t(size: 26, weight: FontWeight.w800)),
          if (!isLoading && totalRefund > 0) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.arrow_downward_rounded,
                  size: 13, color: Color(0xFFEF4444)),
              const SizedBox(width: 4),
              Text('Refund: -${_rp(totalRefund)}',
                  style: _t(size: 11, color: const Color(0xFFEF4444))),
            ]),
            const SizedBox(height: 2),
            Text('Pendapatan kotor: ${_rp(pendapatanIni + totalRefund)}',
                style: _t(size: 10, color: _muted)),
          ],
          const Spacer(),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : _exportExcel,
              icon: const Icon(Icons.download_rounded, size: 16, color: Colors.white),
              label: Text('Unduh Laporan',
                  style: _t(size: 13, weight: FontWeight.w600, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                disabledBackgroundColor: _blue.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingAktifCard({required int total, required bool isLoading}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 16),
        Text('BOOKING AKTIF HARI INI',
            style: _t(size: 11, weight: FontWeight.w700, color: Colors.white70, spacing: 0.5)),
        const SizedBox(height: 8),
        isLoading
            ? _shimmer(w: 60, h: 36, dark: true)
            : Text(total.toString(),
                style: _t(size: 40, weight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 6),
        Text('Data diperbarui secara real-time',
            style: _t(size: 12, color: Colors.white70)),
      ]),
    );
  }

  Widget _buildPelangganCard({required int total}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PELANGGAN BARU',
            style: _t(size: 11, weight: FontWeight.w700, color: _muted, spacing: 0.5)),
        const SizedBox(height: 14),
        Row(children: [
          Text('+$total', style: _t(size: 28, weight: FontWeight.w800)),
          const SizedBox(width: 12),
          SizedBox(
            height: 30, width: 70,
            child: Stack(children: [
              _av('BP', 0), _av('SM', 22), _av('AK', 44),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        Text('Bulan ini', style: _t(size: 11, color: _muted)),
      ]),
    );
  }

  Widget _av(String init, double left) {
    final colors = [_blue, const Color(0xFF7C3AED), const Color(0xFF059669)];
    final idx    = init.hashCode.abs() % colors.length;
    return Positioned(
      left: left,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
            color: colors[idx],
            shape: BoxShape.circle,
            border: Border.all(color: _white, width: 2)),
        child: Center(child: Text(init,
            style: _t(size: 9, weight: FontWeight.w700, color: Colors.white))),
      ),
    );
  }

  Widget _buildTableBooking({
    required List<Map<String, dynamic>> bookingList,
    required bool isLoading,
  }) {
    return Container(
      decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border)),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Booking Terbaru', style: _t(size: 15, weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('Daftar transaksi 24 jam terakhir', style: _t(size: 12, color: _muted)),
            ]),
            const Spacer(),
          ]),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(children: [
            _th('PELANGGAN', 4), _th('LAYANAN', 3),
            _th('WAKTU', 2), _th('TOTAL', 2),
            _th('STATUS', 2),
          ]),
        ),
        const SizedBox(height: 8),
        const Divider(color: _border, height: 1),
        if (isLoading)
          const Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())
        else if (bookingList.isEmpty)
          Padding(padding: const EdgeInsets.all(32),
              child: Text('Tidak ada data booking', style: _t(size: 13, color: _muted)))
        else
          ...bookingList.map(_buildRow),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _th(String label, int flex) => Expanded(
    flex: flex,
    child: Text(label, style: _t(size: 11, weight: FontWeight.w700, color: _muted, spacing: 0.4)),
  );

  Widget _buildRow(Map<String, dynamic> b) {
    final name   = b['customer_name']  ?? '-';
    final lap    = b['nama_lapangan']  ?? '-';
    final dur    = b['durasi']         ?? '';
    final waktu  = _waktu(b['tanggal_booking']);
    final total  = double.tryParse(b['total_harga'].toString()) ?? 0;
    final status = b['status_pembayaran'] ?? b['status'] ?? '';
    final dc     = _sc(status);
    final docId  = (b['order_id'] ?? b['id'] ?? '').toString();
    final shortId = docId.toUpperCase();

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(flex: 4, child: Row(children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(color: _blueBg, borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text(_initials(name),
                    style: _t(size: 12, weight: FontWeight.w700, color: _blue))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: _t(size: 13, weight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('ID: #$shortId', style: _t(size: 10, color: _muted),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
            ])),
            Expanded(flex: 3,
                child: Text(dur.toString().isNotEmpty ? '$lap ($dur Jam)' : lap,
                    style: _t(size: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
            Expanded(flex: 2,
                child: Text(waktu, style: _t(size: 13),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
            Expanded(flex: 2,
                child: Text(_rp(total),
                    style: _t(size: 13, weight: FontWeight.w700),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
            Expanded(flex: 2,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: dc.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(_sl(status),
                        style: _t(size: 11, weight: FontWeight.w700, color: dc),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const Divider(color: _border, height: 1, indent: 24, endIndent: 24),
    ]);
  }

  Widget _shimmer({required double w, required double h, bool dark = false}) =>
      Container(
        width: w, height: h,
        decoration: BoxDecoration(
          color: dark ? Colors.white.withOpacity(0.2) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
      );
}