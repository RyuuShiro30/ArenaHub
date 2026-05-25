import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../routes/app_routes.dart';
import '../../profile/screens/profile_screen.dart';
import '../../auth/screens/pencarian_lapangan_screen.dart';
import '../../riwayat/screens/riwayat_booking_screen.dart';
import '../../booking/screens/pilih_jadwal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;

  final _auth      = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String _fullName    = '';
  String _userEmail   = '';
  bool   _loadingUser = true;

  static const Color _primaryDark = Color(0xFF0D2D6B);
  static const Color _accent      = Color(0xFF2563EB);
  static const Color _bgColor     = Color(0xFFF4F6F9);
  static const Color _textDark    = Color(0xFF1A2B3C);

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data     = doc.data()!;
        final photoUrl = data['photoUrl'] as String?;

        setState(() {
          _fullName    = data['fullName'] ?? 'User';
          _userEmail   = data['email']    ?? user.email ?? '';
          _loadingUser = false;
        });

        profileNameNotifier.value  = _fullName;
        profilePhotoNotifier.value = photoUrl;
      }
    } catch (e) {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  Future<void> _openMaps() async {
    final Uri mapsUri = Uri.parse('geo:0,0?q=Unggul+Sport+Center+Malang');
    await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
  }

  String _formatTanggal(dynamic tanggal) {
    try {
      if (tanggal is Timestamp) {
        final dt = tanggal.toDate();
        return DateFormat('EEEE, d MMM yyyy', 'id_ID').format(dt).toUpperCase();
      }
      return tanggal.toString();
    } catch (_) { return ''; }
  }

  String _formatHarga(dynamic harga) {
    try {
      final num = int.parse(harga.toString());
      return 'Rp${NumberFormat('#,###', 'id_ID').format(num)}';
    } catch (_) { return 'Rp$harga'; }
  }

  String _formatStatus(String? status) {
    final s = status?.toLowerCase() ?? '';
    if (s == 'paid' || s == 'selesai' || s.contains('selesai')) return 'SELESAI';
    if (s == 'pending') return 'PENDING';
    if (s == 'cancelled' || s == 'batal' || s.contains('gagal')) return 'DIBATALKAN';
    return (status ?? '').toUpperCase();
  }

  Color _statusColor(String? status) {
    final s = status?.toLowerCase() ?? '';
    if (s == 'paid' || s == 'selesai' || s.contains('selesai')) return _accent;
    if (s == 'pending') return Colors.orange;
    if (s == 'cancelled' || s == 'batal' || s.contains('gagal')) return Colors.red;
    return _accent;
  }

  TextStyle _p({
    double size = 14,
    FontWeight weight = FontWeight.normal,
    Color color = _textDark,
    double spacing = 0,
    double height = 1.4,
  }) {
    return GoogleFonts.poppins(
      fontSize: size, fontWeight: weight,
      color: color, letterSpacing: spacing, height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (_selectedNavIndex != 0) {
          setState(() => _selectedNavIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: _bgColor,
        body: SafeArea(
          child: IndexedStack(
            index: _selectedNavIndex,
            children: [
              // Tab 0 - Beranda
              Column(
                children: [
                  Container(
                    color: _bgColor,
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                    child: _buildHeader(),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFeaturedCard(),
                          const SizedBox(height: 26),
                          _sectionTitle('Cabang Olahraga'),
                          const SizedBox(height: 14),
                          _buildSportGrid(),
                          const SizedBox(height: 26),
                          _sectionTitle('Jadwal Tersedia Hari Ini'),
                          const SizedBox(height: 14),
                          _buildScheduleList(),
                          const SizedBox(height: 26),
                          _sectionTitle('Booking Terakhirku'),
                          const SizedBox(height: 14),
                          _buildLastBooking(),
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Tab 1 - Cari
              const PencarianLapanganScreen(),
              // Tab 2 - Riwayat
              const RiwayatBookingScreen(),
              // Tab 3 - Profil
              const ProfileScreen(isTab: true),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _loadingUser
                  ? Container(
                      width: 160, height: 22,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    )
                  : ValueListenableBuilder<String>(
                      valueListenable: profileNameNotifier,
                      builder: (context, notifierName, _) {
                        final displayName = notifierName.isNotEmpty
                            ? notifierName : _fullName;
                        return Text('Halo, $displayName!',
                            style: _p(size: 22, weight: FontWeight.bold,
                                color: _primaryDark, height: 1.2));
                      },
                    ),
              const SizedBox(height: 3),
              Text('Siap berkeringat hari ini?',
                  style: _p(size: 13, color: Colors.grey.shade500)),
            ],
          ),
        ),
        ValueListenableBuilder<String?>(
          valueListenable: profilePhotoNotifier,
          builder: (context, fotoUrl, _) {
            return Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.07),
                      blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: ClipOval(
                child: fotoUrl != null
                    ? Image.network(fotoUrl, fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Center(
                            child: SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2,
                                  color: _accent.withOpacity(0.5))),
                          );
                        },
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.person_rounded,
                                color: Colors.grey.shade400, size: 24))
                    : Icon(Icons.person_rounded,
                        color: Colors.grey.shade400, size: 24),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Featured Card ─────────────────────────────────────────────────────────
  Widget _buildFeaturedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D3D4A), Color(0xFF1A6B5A), Color(0xFF2A9B7A)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1A6B5A).withOpacity(0.45),
              blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Text('REKOMENDASI UTAMA',
                style: _p(size: 10, weight: FontWeight.w600,
                    color: Colors.white, spacing: 0.8)),
          ),
          const SizedBox(height: 14),
          Text('Sport Center\nArenaHub',
              style: _p(size: 26, weight: FontWeight.bold,
                  color: Colors.white, height: 1.2)),
          const SizedBox(height: 14),
          _cardInfo(Icons.location_on_outlined, 'Jl. Raya Karanglo No.84, Malang'),
          const SizedBox(height: 6),
          _cardInfo(Icons.access_time_outlined, '06.00 - 22.00'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.cariLapangan),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0D3D4A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('Pesan Sekarang',
                      style: _p(size: 14, weight: FontWeight.w600,
                          color: const Color(0xFF0D3D4A))),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _openMaps,
                child: Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.near_me_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 15),
        const SizedBox(width: 7),
        Expanded(child: Text(text,
            style: _p(size: 12, color: Colors.white70),
            maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _sectionTitle(String title) =>
      Text(title, style: _p(size: 16, weight: FontWeight.bold, color: _textDark));

  // ── Sport Grid — StreamBuilder ─────────────────────────────────────────────
  Widget _buildSportGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('lapangan').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('Tidak ada cabang olahraga',
              style: _p(color: Colors.grey)));
        }

        final Map<String, Map<String, dynamic>> uniqueJenis = {};
        for (final doc in snapshot.data!.docs) {
          final data  = doc.data() as Map<String, dynamic>;
          final jenis = data['jenis_lapangan'] as String? ?? '';
          if (jenis.isNotEmpty && !uniqueJenis.containsKey(jenis)) {
            uniqueJenis[jenis] = data;
          }
        }

        final categories = uniqueJenis.values.toList();

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 12,
            mainAxisSpacing: 12, childAspectRatio: 1.1,
          ),
          itemCount: categories.length,
          itemBuilder: (context, i) {
            final data     = categories[i];
            final name     = data['jenis_lapangan'] as String? ?? '';
            final fotoList = data['foto'] as List<dynamic>?;
            final imageUrl = (fotoList != null && fotoList.isNotEmpty)
                ? fotoList[0] as String
                : data['image_url'] as String? ?? '';

            Color cardColor;
            switch (name.toLowerCase()) {
              case 'futsal':      cardColor = const Color(0xFF0D2D6B); break;
              case 'basket':      cardColor = const Color(0xFF8B3A0F); break;
              case 'bulutangkis': cardColor = const Color(0xFF1A3A6E); break;
              case 'padel':       cardColor = const Color(0xFF1A5C3A); break;
              default:            cardColor = const Color(0xFF2D2D2D);
            }

            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageUrl.isNotEmpty
                      ? Image.network(imageUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: cardColor))
                      : Container(color: cardColor),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, cardColor.withOpacity(0.88)],
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(bottom: 14, left: 14,
                    child: Text(name,
                        style: _p(size: 15, weight: FontWeight.bold,
                            color: Colors.white))),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Schedule List — StreamBuilder real-time ───────────────────────────────
// Ganti seluruh method _buildScheduleList() di home_screen.dart dengan ini:

Widget _buildScheduleList() {
  final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

  return StreamBuilder<QuerySnapshot>(
    stream: _firestore.collection('lapangan').snapshots(),
    builder: (context, lapSnap) {
      if (lapSnap.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      }
      if (!lapSnap.hasData || lapSnap.data!.docs.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(14)),
          child: Center(child: Text('Tidak ada jadwal tersedia hari ini',
              style: _p(color: Colors.grey))),
        );
      }

      return StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('jadwal')
            .where('status', isEqualTo: 'tersedia')
            .snapshots(),
        builder: (context, jadwalSnap) {
          if (!jadwalSnap.hasData) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('bookings')
                .where('tanggal_main', isEqualTo: todayStr)
                .snapshots(),
            builder: (context, bookSnap) {
              // Kumpulkan slot yang sudah dipesan per lapangan
              final bookedSlots = <String, Set<String>>{};
              if (bookSnap.hasData) {
                const validStatuses = {
                  'sudah dibayar', 'pembayaran selesai', 'confirmed', 'pending',
                };
                for (final doc in bookSnap.data!.docs) {
                  final data  = doc.data() as Map<String, dynamic>;
                  final lapId = data['lapangan_id']?.toString() ?? '';
                  final spay  = data['status_pembayaran']?.toString().toLowerCase() ?? '';
                  final salt  = data['status']?.toString().toLowerCase() ?? '';
                  if (!validStatuses.contains(spay) && !validStatuses.contains(salt)) continue;

                  final slotField = data['slots'] ?? data['selected_times'] ?? data['jam_main'];
                  final set = bookedSlots.putIfAbsent(lapId, () => {});
                  if (slotField is List) {
                    set.addAll(slotField.map((e) => e.toString()));
                  } else if (slotField is String && slotField.isNotEmpty) {
                    set.addAll(slotField.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
                  }
                }
              }

              // Map lapangan untuk lookup
              final lapanganMap = <String, Map<String, dynamic>>{};
              for (final lapDoc in lapSnap.data!.docs) {
                lapanganMap[lapDoc.id] = lapDoc.data() as Map<String, dynamic>;
              }

              // Filter slot yang belum dipesan dari collection jadwal
              final allJadwal = jadwalSnap.data!.docs
                  .map((doc) => doc.data() as Map<String, dynamic>)
                  .where((d) {
                    final lapId = d['lapangan_id']?.toString() ?? '';
                    final slot  = d['waktu_operasional']?.toString() ?? '';
                    if (lapId.isEmpty || slot.isEmpty) return false;
                    if (lapanganMap[lapId] == null) return false;
                    final booked = bookedSlots[lapId] ?? {};
                    return !booked.contains(slot);
                  })
                  .toList();

              // Sort by waktu_mulai
              allJadwal.sort((a, b) {
                try {
                  final aTime  = (a['waktu_mulai'] ?? '00:00').toString();
                  final bTime  = (b['waktu_mulai'] ?? '00:00').toString();
                  final aParts = aTime.split(':');
                  final bParts = bTime.split(':');
                  final aMin   = int.parse(aParts[0]) * 60 + int.parse(aParts[1]);
                  final bMin   = int.parse(bParts[0]) * 60 + int.parse(bParts[1]);
                  return aMin.compareTo(bMin);
                } catch (_) { return 0; }
              });

              // Ambil slot paling awal per lapangan
              final earliestByLapangan = <String, Map<String, dynamic>>{};
              for (final jadwalData in allJadwal) {
                final lapId = jadwalData['lapangan_id']?.toString() ?? '';
                if (!earliestByLapangan.containsKey(lapId)) {
                  earliestByLapangan[lapId] = jadwalData;
                }
              }

              // Bangun items max 4 lapangan
              final items = <Map<String, dynamic>>[];
              for (final entry in earliestByLapangan.entries) {
                final lapId      = entry.key;
                final jadwalData = entry.value;
                final lapData    = lapanganMap[lapId]!;
                final fotoList   = lapData['foto'] as List<dynamic>?;

                items.add({
                  'id'         : lapId,
                  'nama'       : lapData['nama_lapangan']        ?? 'Lapangan',
                  'jenis'      : lapData['jenis_lapangan']       ?? '',
                  'harga'      : (lapData['harga'] as num?)?.toInt() ?? 0,
                  'slot'       : jadwalData['waktu_operasional'] ?? '-',
                  'jenis_floor': lapData['jenis_floor']          ?? '',
                  'foto'       : (fotoList != null && fotoList.isNotEmpty)
                      ? fotoList[0].toString()
                      : lapData['image_url']?.toString() ?? '',
                });
                if (items.length >= 4) break;
              }

              if (items.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(14)),
                  child: Center(child: Text('Tidak ada jadwal tersedia hari ini',
                      style: _p(color: Colors.grey))),
                );
              }

              return Column(
                children: items.map((item) {
                  return GestureDetector(
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => PilihJadwalPage(
                        lapanganId   : item['id'],
                        namaLapangan : item['nama'],
                        jenisLapangan: item['jenis'],
                        jenisFloor   : item['jenis_floor'],
                        fotoUrl      : item['foto'],
                        pricePerHour : item['harga'],
                      )),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 11, vertical: 9),
                            decoration: BoxDecoration(
                              color: _accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(item['slot'],
                                style: _p(size: 12, weight: FontWeight.bold,
                                    color: _primaryDark)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['nama'],
                                    style: _p(size: 13,
                                        weight: FontWeight.w600,
                                        color: _textDark)),
                                const SizedBox(height: 2),
                                Text(item['jenis'],
                                    style: _p(size: 11,
                                        color: Colors.grey.shade500)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                NumberFormat.currency(locale: 'id_ID',
                                    symbol: 'Rp ', decimalDigits: 0)
                                    .format(item['harga']),
                                style: _p(size: 13, weight: FontWeight.bold,
                                    color: _accent),
                              ),
                              const SizedBox(height: 2),
                              Text('/ jam',
                                  style: _p(size: 11,
                                      color: Colors.grey.shade400)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      );
    },
  );
}

  // ── Last Booking — StreamBuilder real-time ────────────────────────────────
  Widget _buildLastBooking() {
    final user = _auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(user.uid)
          .collection('bookings')
          .snapshots(),
      builder: (context, _) {
        // Gunakan stream dari root bookings collection by email
        return StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('bookings')
              .where('email', isEqualTo: _userEmail)
              .orderBy('tanggal_booking', descending: true)
              .limit(1)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 100,
                decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Center(child: Text('Belum ada booking',
                    style: _p(size: 13, color: Colors.grey.shade400))),
              );
            }

            final booking      = snapshot.data!.docs.first.data()
                as Map<String, dynamic>;
            final namaLapangan = booking['nama_lapangan']     ?? '-';
            final tanggal      = booking['tanggal_booking'];
            final totalHarga   = booking['total_harga']       ?? 0;
            final status       = booking['status_pembayaran'] ?? '';
            final customerName = booking['customer_name']     ?? '';

            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(_formatTanggal(tanggal),
                          style: _p(size: 11, weight: FontWeight.w500,
                              color: Colors.grey.shade500, spacing: 0.4))),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(_formatStatus(status),
                            style: _p(size: 10, weight: FontWeight.bold,
                                color: _statusColor(status), spacing: 0.4)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Container(
                      width: 3.5, height: 38,
                      decoration: BoxDecoration(color: _accent,
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(namaLapangan,
                        style: _p(size: 15, weight: FontWeight.bold,
                            color: _textDark))),
                  ]),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Icon(Icons.person_outline_rounded,
                            size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 5),
                        Text(customerName,
                            style: _p(size: 12, color: Colors.grey.shade500)),
                      ]),
                      Text(_formatHarga(totalHarga),
                          style: _p(size: 14, weight: FontWeight.bold,
                              color: _textDark)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Bottom Nav ────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_rounded,    'label': 'Beranda'},
      {'icon': Icons.search_rounded,  'label': 'Cari'},
      {'icon': Icons.history_rounded, 'label': 'Riwayat'},
      {'icon': Icons.person_rounded,  'label': 'Profil'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08),
            blurRadius: 14, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final isActive = _selectedNavIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedNavIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? _accent.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(items[i]['icon'] as IconData,
                          color: isActive ? _primaryDark
                              : Colors.grey.shade400, size: 24),
                      const SizedBox(height: 4),
                      Text(items[i]['label'] as String,
                          style: _p(size: 11,
                              weight: isActive ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isActive ? _primaryDark
                                  : Colors.grey.shade400)),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}