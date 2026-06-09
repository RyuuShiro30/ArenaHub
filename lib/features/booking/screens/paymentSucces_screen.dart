import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:appbookinglapangan/features/riwayat/screens/detail_riwayat.dart';

class PaymentSuccessPage extends StatefulWidget {
  const PaymentSuccessPage({super.key});

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  late Future<Map<String, dynamic>> _bookingFuture;
  String orderId         = '';
  String selectedJamMain = '';
  bool _isInit           = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final dynamic args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        orderId         = args['orderId'] ?? '';
        selectedJamMain = args['jamMain'] ?? '';
      } else if (args is String) {
        orderId = args;
      }
      if (orderId.isNotEmpty) {
        _bookingFuture =
            _processPaymentAndFetchData(orderId, selectedJamMain);
      }
      _isInit = true;
    }
  }

  // ── Update jadwal collection → 'dipesan' ─────────────────────
  Future<void> _updateJadwalStatus({
    required String lapanganId,
    required String tanggalMainStr, // yyyy-MM-dd
    required String jamMain,        // "10:00 - 11:00, 11:00 - 12:00"
  }) async {
    try {
      final tanggal = DateTime.tryParse(tanggalMainStr);
      if (tanggal == null) return;

      final startOfDay =
          DateTime(tanggal.year, tanggal.month, tanggal.day, 0, 0, 0);
      final endOfDay =
          DateTime(tanggal.year, tanggal.month, tanggal.day, 23, 59, 59);

      // Parse slots — normalize titik → titik dua
      final rawSlots = jamMain
          .split(',')
          .map((s) => s.trim().replaceAll('.', ':'))
          .where((s) => s.isNotEmpty)
          .toSet();

      if (rawSlots.isEmpty) return;

      final snap = await FirebaseFirestore.instance
          .collection('jadwal')
          .where('lapangan_id', isEqualTo: lapanganId)
          .where('tanggal',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('tanggal',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      if (snap.docs.isEmpty) return;

      final batch     = FirebaseFirestore.instance.batch();
      int updateCount = 0;

      for (final doc in snap.docs) {
        final data    = doc.data();
        final waktuOp = (data['waktu_operasional'] as String? ?? '')
            .trim()
            .replaceAll('.', ':');

        if (rawSlots.contains(waktuOp)) {
          batch.update(doc.reference, {'status': 'dipesan'});
          updateCount++;
        }
      }

      if (updateCount > 0) await batch.commit();

      debugPrint(
          '_updateJadwalStatus: $lapanganId | $tanggalMainStr | $rawSlots → $updateCount slot diupdate');
    } catch (e) {
      debugPrint('_updateJadwalStatus error: $e');
    }
  }

  // ── Proses payment & fetch data ───────────────────────────────
  Future<Map<String, dynamic>> _processPaymentAndFetchData(
      String id, String jamMainInput) async {
    final docRef =
        FirebaseFirestore.instance.collection('bookings').doc(id);
    final snapshot = await docRef.get();
    List<DocumentSnapshot> children = [];

    if (!snapshot.exists) {
      return {'parent': snapshot, 'children': children};
    }

    final bookingData = snapshot.data() as Map<String, dynamic>;

    String currentStatus = bookingData['status_pembayaran'] ?? '';
    bool isFinal = currentStatus == 'pembayaran selesai' ||
        currentStatus == 'gagal';

    // Data parent booking
    final String namaLapangan = bookingData['nama_lapangan'] ?? '';
    final String tanggalMain  = bookingData['tanggal_main']  ?? '';
    final String lapanganId   = bookingData['lapangan_id']   ?? '';
    final String jamMain      = jamMainInput.isNotEmpty
        ? jamMainInput
        : (bookingData['jam_main'] ?? '');
    final int childCount      = bookingData['child_count']   ?? 0;

    // Cek duplikasi
    bool isDuplicate = false;
    if (!isFinal) {
      final duplicateQuery = await FirebaseFirestore.instance
          .collection('bookings')
          .where('nama_lapangan',    isEqualTo: namaLapangan)
          .where('tanggal_main',     isEqualTo: tanggalMain)
          .where('jam_main',         isEqualTo: jamMain)
          .where('status_pembayaran', isEqualTo: 'pembayaran selesai')
          .get();
      isDuplicate = duplicateQuery.docs.any((doc) => doc.id != id);
    }

    final String newStatus = isFinal
        ? currentStatus
        : (isDuplicate ? 'gagal' : 'pembayaran selesai');

    // ── Update parent booking ─────────────────────────────────
    if (!isFinal) {
      await docRef.update({
        'status_pembayaran': newStatus,
        'jam_main':          jamMain,
      });

      // ── Update jadwal PARENT (lapangan pertama) ────────────
      if (newStatus == 'pembayaran selesai' &&
          lapanganId.isNotEmpty &&
          tanggalMain.isNotEmpty &&
          jamMain.isNotEmpty) {
        await _updateJadwalStatus(
          lapanganId:     lapanganId,
          tanggalMainStr: tanggalMain,
          jamMain:        jamMain,
        );
      }
    }

    // ── Update + collect child bookings ───────────────────────
    if (childCount > 0) {
      for (int i = 0; i < childCount; i++) {
        final childDocId = '${id}_$i';
        final childRef   = FirebaseFirestore.instance
            .collection('bookings')
            .doc(childDocId);

        if (!isFinal) {
          await childRef.update({
            'status_pembayaran': newStatus,
            'status': newStatus == 'pembayaran selesai'
                ? 'confirmed'
                : 'gagal',
          });

          // ── Update jadwal CHILD (lapangan tambahan) ────────
          // FIX: ambil data child lalu update jadwal masing-masing
          if (newStatus == 'pembayaran selesai') {
            final childSnap = await childRef.get();
            if (childSnap.exists) {
              final childData =
                  childSnap.data() as Map<String, dynamic>;
              final String cLapanganId =
                  childData['lapangan_id'] ?? '';
              final String cTanggalMain =
                  childData['tanggal_main'] ?? '';
              final String cJamMain =
                  (childData['jam_main'] ??
                          childData['selected_times'] ??
                          '')
                      .toString();

              if (cLapanganId.isNotEmpty &&
                  cTanggalMain.isNotEmpty &&
                  cJamMain.isNotEmpty) {
                await _updateJadwalStatus(
                  lapanganId:     cLapanganId,
                  tanggalMainStr: cTanggalMain,
                  jamMain:        cJamMain,
                );
              }
            }
          }
        }

        // Collect child doc untuk tampilan UI
        final childDoc = await childRef.get();
        if (childDoc.exists) children.add(childDoc);
      }
    }

    final updatedSnapshot = await docRef.get();
    return {'parent': updatedSnapshot, 'children': children};
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Status Pembayaran',
            style: TextStyle(
                color: Color(0xFF1A237E),
                fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: orderId.isEmpty
          ? _buildErrorState(context, 'ID Pesanan tidak valid')
          : FutureBuilder<Map<String, dynamic>>(
              future: _bookingFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                if (!snapshot.hasData ||
                    !(snapshot.data!['parent'] as DocumentSnapshot)
                        .exists) {
                  return _buildErrorState(
                      context, 'Data pembayaran tidak ditemukan');
                }

                final parentDoc =
                    snapshot.data!['parent'] as DocumentSnapshot;
                final childrenDocs = snapshot.data!['children']
                    as List<DocumentSnapshot>;
                final data =
                    parentDoc.data() as Map<String, dynamic>;

                return _buildSuccessUI(
                  context,
                  bookingId:        data['order_id'] ?? orderId,
                  namaLapangan:     data['nama_lapangan'] ?? 'Lapangan',
                  formattedDate:    _fmtTanggal(data['tanggal_booking']),
                  jamMain:          data['jam_main'] ?? '-',
                  totalHarga:       (data['total_harga'] as num?)?.toInt() ?? 0,
                  statusPembayaran: data['status_pembayaran'] ?? 'pending',
                  children:         childrenDocs,
                );
              },
            ),
    );
  }

  String _fmtTanggal(dynamic v) {
    if (v == null) return '-';
    DateTime dt;
    if (v is Timestamp) {
      dt = v.toDate();
    } else if (v is String) {
      dt = DateTime.tryParse(v) ?? DateTime.now();
    } else {
      return '-';
    }
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(dt);
  }

  Widget _buildSuccessUI(
    BuildContext context, {
    required String bookingId,
    required String namaLapangan,
    required String formattedDate,
    required String jamMain,
    required int totalHarga,
    required String statusPembayaran,
    required List<DocumentSnapshot> children,
  }) {
    final bool isSuccess = statusPembayaran == 'pembayaran selesai';

    final String labelBadge   = isSuccess ? 'LUNAS' : 'GAGAL';
    final Color colorText     = isSuccess ? Colors.blue : Colors.red;
    final Color colorBg       =
        isSuccess ? Colors.blue.shade50 : Colors.red.shade50;
    final String headerTitle  =
        isSuccess ? 'Pembayaran Berhasil!' : 'Pembayaran Gagal';
    final String headerSub    = isSuccess
        ? 'Booking lapangan kamu sudah dikonfirmasi'
        : 'Maaf, pembayaran gagal karena jadwal sudah terisi';
    final IconData headerIcon =
        isSuccess ? Icons.check_circle : Icons.cancel;
    final Color headerIconColor =
        isSuccess ? const Color(0xFF2D958E) : Colors.red;
    final Color headerBgColor =
        isSuccess ? const Color(0xFFF0F9F8) : Colors.red.shade50;

    return SingleChildScrollView(
      child: Column(children: [
        // Header
        Container(
          width: double.infinity,
          color: headerBgColor,
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Column(children: [
            Icon(headerIcon, size: 80, color: headerIconColor),
            const SizedBox(height: 16),
            Text(headerTitle,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1))),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 4),
              child: Text(headerSub,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey)),
            ),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            // Kartu detail
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                  const Text('NOMOR BOOKING',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: colorBg,
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(labelBadge,
                        style: TextStyle(
                            fontSize: 10,
                            color: colorText,
                            fontWeight: FontWeight.bold)),
                  ),
                ]),
                Text(bookingId,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(height: 30),

                // Single lapangan
                if (children.isEmpty) ...[
                  _rowInfo('Nama Lapangan', namaLapangan),
                  _rowInfo('Jadwal', formattedDate, isMulti: true),
                  _rowInfo('Jam Main', jamMain),
                ] else ...[
                  // Multi lapangan
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('Detail Lapangan & Jadwal',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold)),
                  ),
                  ...children.map((childDoc) {
                    final cd =
                        childDoc.data() as Map<String, dynamic>;
                    final cNama =
                        cd['nama_lapangan'] ?? 'Lapangan';
                    final cTglRaw =
                        cd['tanggal_main'] ?? cd['tanggal'] ?? '';
                    final cTgl = cTglRaw.isNotEmpty &&
                            DateTime.tryParse(cTglRaw) != null
                        ? DateFormat('EEEE, d MMMM yyyy', 'id_ID')
                            .format(DateTime.parse(cTglRaw))
                        : cTglRaw;
                    final cJam = cd['jam_main'] ?? '-';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFFE9ECEF))),
                      child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                        Text(cNama,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D47A1),
                                fontSize: 14)),
                        const SizedBox(height: 6),
                        Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                          const Text('Jadwal',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey)),
                          Flexible(
                              child: Text(cTgl,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight:
                                          FontWeight.bold),
                                  textAlign: TextAlign.right)),
                        ]),
                        const SizedBox(height: 4),
                        Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                          const Text('Jam Main',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey)),
                          Flexible(
                              child: Text(cJam,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight:
                                          FontWeight.bold),
                                  textAlign: TextAlign.right)),
                        ]),
                      ]),
                    );
                  }),
                ],

                _rowInfo('Metode Pembayaran', 'QRIS'),
                const Divider(height: 30),
                Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                  const Text('Total Pembayaran',
                      style:
                          TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    'IDR ${NumberFormat('#,###', 'id_ID').format(totalHarga)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D47A1),
                        fontSize: 18),
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => DetailRiwayatPage(
                          bookingId: bookingId))),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
              child: const Text('Lihat Detail Booking',
                  style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context, '/home', (route) => false),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side:
                    const BorderSide(color: Color(0xFF0D47A1)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
              child: const Text('Kembali ke Beranda',
                  style: TextStyle(
                      color: Color(0xFF0D47A1),
                      fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _rowInfo(String label, String value,
      {bool isMulti = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: isMulti
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 10),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style:
                    const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline,
              size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kembali'),
          ),
        ],
      ),
    );
  }
}