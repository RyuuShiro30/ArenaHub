import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../../../../routes/app_routes.dart';
import '../../profile/screens/profile_screen.dart';
import '../../auth/screens/pencarian_lapangan_screen.dart';
import '../../riwayat/screens/riwayat_booking_screen.dart';
import '../../booking/screens/pilih_jadwal.dart';
import '../../keranjang/cart_manager.dart';
import '../../keranjang/keranjang.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String _fullName = '';
  String _userEmail = '';
  bool _loadingUser = true;

  static const Color _primaryDark = Color(0xFF0D2D6B);
  static const Color _accent = Color(0xFF2563EB);
  static const Color _bgColor = Color(0xFFF4F6F9);
  static const Color _textDark = Color(0xFF1A2B3C);

  @override
  void initState() {
    super.initState();
    tz_data.initializeTimeZones();
    _fetchUserData();
  }

  DateTime _nowWib() {
    final wib = tz.getLocation('Asia/Jakarta');
    final nowWib = tz.TZDateTime.now(wib);
    return DateTime(nowWib.year, nowWib.month, nowWib.day, nowWib.hour,
        nowWib.minute, nowWib.second);
  }

  String _todayWibStr() => DateFormat('yyyy-MM-dd').format(_nowWib());

  double _slotEndHour(String slot) {
    final part = slot.split(' - ').last.trim();
    final segments = part.split('.');
    final hour = int.tryParse(segments[0]) ?? 0;
    final minute = int.tryParse(segments.length > 1 ? segments[1] : '0') ?? 0;
    return hour + minute / 60.0;
  }

  double _slotStartHour(String slot) {
    final part = slot.split(' - ').first.trim();
    final segments = part.split('.');
    final hour = int.tryParse(segments[0]) ?? 0;
    final minute = int.tryParse(segments.length > 1 ? segments[1] : '0') ?? 0;
    return hour + minute / 60.0;
  }

  static const List<String> _allSlots = [
    "06.00 - 07.00",
    "07.00 - 08.00",
    "08.00 - 09.00",
    "09.00 - 10.00",
    "10.00 - 11.00",
    "11.00 - 12.00",
    "12.00 - 13.00",
    "13.00 - 14.00",
    "14.00 - 15.00",
    "15.00 - 16.00",
    "16.00 - 17.00",
    "17.00 - 18.00",
    "18.00 - 19.00",
    "19.00 - 20.00",
    "20.00 - 21.00",
  ];

  List<String> _availableSlotsToday() {
    final nowWib = _nowWib();
    final currentHour = nowWib.hour + nowWib.minute / 60.0;
    return _allSlots.where((slot) => _slotEndHour(slot) > currentHour).toList();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        final photoUrl = data['photoUrl'] as String?;
        setState(() {
          _fullName = data['fullName'] ?? 'User';
          _userEmail = data['email'] ?? user.email ?? '';
          _loadingUser = false;
        });
        profileNameNotifier.value = _fullName;
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
    } catch (_) {
      return '';
    }
  }

  String _formatHarga(dynamic harga) {
    try {
      final num = int.parse(harga.toString());
      return 'Rp${NumberFormat('#,###', 'id_ID').format(num)}';
    } catch (_) {
      return 'Rp$harga';
    }
  }

  String _formatStatus(String? status) {
    final s = status?.toLowerCase() ?? '';
    if (s == 'paid' || s == 'selesai' || s.contains('selesai')) {
      return 'SELESAI';
    }
    if (s == 'pending') return 'PENDING';
    if (s == 'cancelled' || s == 'batal' || s.contains('gagal')) {
      return 'DIBATALKAN';
    }
    return (status ?? '').toUpperCase();
  }

  Color _statusColor(String? status) {
    final s = status?.toLowerCase() ?? '';
    if (s == 'paid' || s == 'selesai' || s.contains('selesai')) return _accent;
    if (s == 'pending') return Colors.orange;
    if (s == 'cancelled' || s == 'batal' || s.contains('gagal')) {
      return Colors.red;
    }
    return _accent;
  }

  TextStyle _p(
      {double size = 14,
      FontWeight weight = FontWeight.normal,
      Color color = _textDark,
      double spacing = 0,
      double height = 1.4}) {
    return GoogleFonts.poppins(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: spacing,
        height: height);
  }

  @override
  Widget build(BuildContext context) {
    // FIX: canPop false + onPopInvokedWithResult hanya reset tab,
    // tidak allow pop keluar dari HomeScreen sama sekali.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // Kalau bukan di tab Beranda, kembali ke Beranda dulu
        if (_selectedNavIndex != 0) {
          setState(() => _selectedNavIndex = 0);
        }
        // canPop: false memastikan tidak pernah pop keluar HomeScreen
      },
      child: Scaffold(
        backgroundColor: _bgColor,
        body: SafeArea(
          child: IndexedStack(
            index: _selectedNavIndex,
            children: [
              // ── Tab 0: Beranda ──────────────────────────────
              Column(children: [
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
              ]),
              // ── Tab 1: Cari ─────────────────────────────────
              // PopScope(canPop:false) mencegah child screen nge-pop HomeScreen
              PopScope(
                canPop: false,
                onPopInvokedWithResult: (_, __) =>
                    setState(() => _selectedNavIndex = 0),
                child: const PencarianLapanganScreen(),
              ),
              // ── Tab 2: Keranjang ─────────────────────────────
              PopScope(
                canPop: false,
                onPopInvokedWithResult: (_, __) =>
                    setState(() => _selectedNavIndex = 0),
                child: KeranjangPage(
                onTambahLapangan: () => setState(() => _selectedNavIndex = 1),
              ),
              ),
              // ── Tab 3: Riwayat ──────────────────────────────
              PopScope(
                canPop: false,
                onPopInvokedWithResult: (_, __) =>
                    setState(() => _selectedNavIndex = 0),
                child: const RiwayatBookingScreen(),
              ),
              // ── Tab 4: Profil ────────────────────────────────
              PopScope(
                canPop: false,
                onPopInvokedWithResult: (_, __) =>
                    setState(() => _selectedNavIndex = 0),
                child: const ProfileScreen(isTab: true),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _loadingUser
              ? Container(
                  width: 160,
                  height: 22,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8)))
              : ValueListenableBuilder<String>(
                  valueListenable: profileNameNotifier,
                  builder: (context, notifierName, _) {
                    final displayName =
                        notifierName.isNotEmpty ? notifierName : _fullName;
                    return Text('Halo, $displayName!',
                        style: _p(
                            size: 22,
                            weight: FontWeight.bold,
                            color: _primaryDark,
                            height: 1.2));
                  }),
          const SizedBox(height: 3),
          Text('Siap berkeringat hari ini?',
              style: _p(size: 13, color: Colors.grey.shade500)),
        ]),
      ),
      ValueListenableBuilder<String?>(
        valueListenable: profilePhotoNotifier,
        builder: (context, fotoUrl, _) {
          return Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]),
            child: ClipOval(
              child: fotoUrl != null
                  ? Image.network(fotoUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Center(
                            child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _accent.withOpacity(0.5))));
                      },
                      errorBuilder: (_, __, ___) => Icon(Icons.person_rounded,
                          color: Colors.grey.shade400, size: 24))
                  : Icon(Icons.person_rounded,
                      color: Colors.grey.shade400, size: 24),
            ),
          );
        },
      ),
    ]);
  }

  Widget _buildFeaturedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D3D4A), Color(0xFF1A6B5A), Color(0xFF2A9B7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF1A6B5A).withOpacity(0.45),
              blurRadius: 24,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.25))),
          child: Text('REKOMENDASI UTAMA',
              style: _p(
                  size: 10,
                  weight: FontWeight.w600,
                  color: Colors.white,
                  spacing: 0.8)),
        ),
        const SizedBox(height: 14),
        Text('Sport Center\nArenaHub',
            style: _p(
                size: 26,
                weight: FontWeight.bold,
                color: Colors.white,
                height: 1.2)),
        const SizedBox(height: 14),
        _cardInfo(
            Icons.location_on_outlined, 'Jl. Raya Karanglo No.84, Malang'),
        const SizedBox(height: 6),
        _cardInfo(Icons.access_time_outlined, '06.00 - 22.00'),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
              child: ElevatedButton(
            // FIX: Ganti Navigator.pushNamed → pindah ke tab Cari (index 1)
            onPressed: () => setState(() => _selectedNavIndex = 1),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0D3D4A),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0),
            child: Text('Pesan Sekarang',
                style: _p(
                    size: 14,
                    weight: FontWeight.w600,
                    color: const Color(0xFF0D3D4A))),
          )),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _openMaps,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3))),
              child: const Icon(Icons.near_me_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _cardInfo(IconData icon, String text) => Row(children: [
        Icon(icon, color: Colors.white70, size: 15),
        const SizedBox(width: 7),
        Expanded(
            child: Text(text,
                style: _p(size: 12, color: Colors.white70),
                maxLines: 1,
                overflow: TextOverflow.ellipsis)),
      ]);

  Widget _sectionTitle(String title) => Text(title,
      style: _p(size: 16, weight: FontWeight.bold, color: _textDark));

  Widget _buildSportGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('lapangan').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
              child: Text('Tidak ada cabang olahraga',
                  style: _p(color: Colors.grey)));
        }
        final Map<String, Map<String, dynamic>> uniqueJenis = {};
        for (final doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
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
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1),
          itemCount: categories.length,
          itemBuilder: (context, i) {
            final data = categories[i];
            final name = data['jenis_lapangan'] as String? ?? '';
            final fotoList = data['foto'] as List<dynamic>?;
            final imageUrl = (fotoList != null && fotoList.isNotEmpty)
                ? fotoList[0] as String
                : data['image_url'] as String? ?? '';
            Color cardColor;
            switch (name.toLowerCase()) {
              case 'futsal':
                cardColor = const Color(0xFF0D2D6B);
                break;
              case 'basket':
                cardColor = const Color(0xFF8B3A0F);
                break;
              case 'bulutangkis':
                cardColor = const Color(0xFF1A3A6E);
                break;
              case 'padel':
                cardColor = const Color(0xFF1A5C3A);
                break;
              default:
                cardColor = const Color(0xFF2D2D2D);
            }
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(fit: StackFit.expand, children: [
                imageUrl.isNotEmpty
                    ? Image.network(imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: cardColor))
                    : Container(color: cardColor),
                Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                  Colors.transparent,
                  cardColor.withOpacity(0.88)
                ], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
                Positioned(
                    bottom: 14,
                    left: 14,
                    child: Text(name,
                        style: _p(
                            size: 15,
                            weight: FontWeight.bold,
                            color: Colors.white))),
              ]),
            );
          },
        );
      },
    );
  }

  Widget _buildScheduleList() {
  final now        = _nowWib();
  final todayStr   = _todayWibStr();
  final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
  final endOfDay   = DateTime(now.year, now.month, now.day, 23, 59, 59);

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

      // Buat map lapangan untuk lookup
      final lapanganMap = <String, Map<String, dynamic>>{};
      for (final lapDoc in lapSnap.data!.docs) {
        lapanganMap[lapDoc.id] = {
          ...lapDoc.data() as Map<String, dynamic>,
          'id': lapDoc.id,
        };
      }

      return StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('jadwal')
            .where('tanggal', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('tanggal', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
            .snapshots(),
        builder: (context, jadwalSnap) {
          if (!jadwalSnap.hasData) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('bookings')
                .where('tanggal', isEqualTo: todayStr)
                .where('status', whereIn: ['confirmed', 'pending'])
                .snapshots(),
            builder: (context, bookSnap) {
              // Kumpulkan slot yang sudah dipesan per lapangan
              final bookedSlots = <String, Set<String>>{};
              if (bookSnap.hasData) {
                for (final doc in bookSnap.data!.docs) {
                  final data  = doc.data() as Map<String, dynamic>;
                  final lapId = data['lapangan_id']?.toString() ?? '';
                  if (lapId.isEmpty) continue;
                  final slots = data['slots'] ?? data['selected_times'];
                  final set   = bookedSlots.putIfAbsent(lapId, () => {});
                  if (slots is List) {
                    set.addAll(slots.map((e) => e.toString()));
                  }
                }
              }

              // Filter jadwal tersedia & belum dipesan & belum lewat
              final currentHour = now.hour + now.minute / 60.0;
              final allJadwal = jadwalSnap.data!.docs
                  .map((doc) => doc.data() as Map<String, dynamic>)
                  .where((d) {
                    final lapId  = d['lapangan_id']?.toString() ?? '';
                    final mulai  = d['waktu_mulai']?.toString()  ?? '';
                    final selesai = d['waktu_selesai']?.toString() ?? '';
                    final status = d['status']?.toString() ?? '';
                    if (lapId.isEmpty || mulai.isEmpty) return false;
                    if (lapanganMap[lapId] == null) return false;
                    if (status != 'tersedia') return false;

                    // Cek slot sudah lewat
                    final parts   = selesai.split(':');
                    final endHour = (int.tryParse(parts[0]) ?? 0) +
                        (int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0) / 60.0;
                    if (endHour <= currentHour) return false;

                    // Cek slot sudah dipesan
                    final slot   = '${mulai.replaceAll(':', '.')} - ${selesai.replaceAll(':', '.')}';
                    final booked = bookedSlots[lapId] ?? {};
                    return !booked.contains(slot);
                  })
                  .toList();

              // Sort by waktu_mulai
              allJadwal.sort((a, b) {
                final aTime  = (a['waktu_mulai'] ?? '00:00').toString();
                final bTime  = (b['waktu_mulai'] ?? '00:00').toString();
                final aParts = aTime.split(':');
                final bParts = bTime.split(':');
                final aMin   = int.parse(aParts[0]) * 60 + int.parse(aParts.length > 1 ? aParts[1] : '0');
                final bMin   = int.parse(bParts[0]) * 60 + int.parse(bParts.length > 1 ? bParts[1] : '0');
                return aMin.compareTo(bMin);
              });

              // Group by lapangan, ambil slot paling awal per lapangan
              final earliestByLapangan = <String, Map<String, dynamic>>{};
              for (final d in allJadwal) {
                final lapId = d['lapangan_id']?.toString() ?? '';
                if (!earliestByLapangan.containsKey(lapId)) {
                  earliestByLapangan[lapId] = d;
                }
              }

              final items = <Map<String, dynamic>>[];
              for (final entry in earliestByLapangan.entries) {
                final lapId   = entry.key;
                final jadwal  = entry.value;
                final lapData = lapanganMap[lapId]!;
                final fotoList = lapData['foto'] as List<dynamic>?;
                final mulai   = jadwal['waktu_mulai']?.toString() ?? '';
                final selesai = jadwal['waktu_selesai']?.toString() ?? '';
                final slot    = '${mulai.replaceAll(':', '.')} - ${selesai.replaceAll(':', '.')}';

                items.add({
                  'id'         : lapId,
                  'nama'       : lapData['nama_lapangan']  ?? 'Lapangan',
                  'jenis'      : lapData['jenis_lapangan'] ?? '',
                  'harga'      : (lapData['harga'] as num?)?.toInt() ?? 0,
                  'slot'       : slot,
                  'jenis_floor': lapData['jenis_floor']    ?? '',
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
                children: items.map((item) => GestureDetector(
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => PilihJadwalPage(
                      lapanganId   : item['id'],
                      namaLapangan : item['nama'],
                      jenisLapangan: item['jenis'],
                      jenisFloor   : item['jenis_floor'],
                      fotoUrl      : item['foto'],
                      pricePerHour : item['harga'],
                    ))),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(item['slot'],
                            style: _p(size: 12, weight: FontWeight.bold,
                                color: _primaryDark)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['nama'], style: _p(size: 13,
                              weight: FontWeight.w600, color: _textDark)),
                          const SizedBox(height: 2),
                          Text(item['jenis'], style: _p(size: 11,
                              color: Colors.grey.shade500)),
                        ],
                      )),
                      Column(crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(NumberFormat.currency(locale: 'id_ID',
                              symbol: 'Rp ', decimalDigits: 0).format(item['harga']),
                              style: _p(size: 13, weight: FontWeight.bold,
                                  color: _accent)),
                          const SizedBox(height: 2),
                          Text('/ jam', style: _p(size: 11,
                              color: Colors.grey.shade400)),
                        ]),
                    ]),
                  ),
                )).toList(),
              );
            },
          );
        },
      );
    },
  );
}

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
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16)),
                  child: const Center(child: CircularProgressIndicator()));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ]),
                child: Center(
                    child: Text('Belum ada booking',
                        style: _p(size: 13, color: Colors.grey.shade400))),
              );
            }
            final booking =
                snapshot.data!.docs.first.data() as Map<String, dynamic>;
            final namaLapangan = booking['nama_lapangan'] ?? '-';
            final tanggal = booking['tanggal_booking'];
            final totalHarga = booking['total_harga'] ?? 0;
            final status = booking['status_pembayaran'] ?? '';
            final customerName = booking['customer_name'] ?? '';
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ]),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child: Text(_formatTanggal(tanggal),
                                  style: _p(
                                      size: 11,
                                      weight: FontWeight.w500,
                                      color: Colors.grey.shade500,
                                      spacing: 0.4))),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: _statusColor(status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(_formatStatus(status),
                                style: _p(
                                    size: 10,
                                    weight: FontWeight.bold,
                                    color: _statusColor(status),
                                    spacing: 0.4)),
                          ),
                        ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Container(
                          width: 3.5,
                          height: 38,
                          decoration: BoxDecoration(
                              color: _accent,
                              borderRadius: BorderRadius.circular(4))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(namaLapangan,
                              style: _p(
                                  size: 15,
                                  weight: FontWeight.bold,
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
                                style:
                                    _p(size: 12, color: Colors.grey.shade500)),
                          ]),
                          Text(_formatHarga(totalHarga),
                              style: _p(
                                  size: 14,
                                  weight: FontWeight.bold,
                                  color: _textDark)),
                        ]),
                  ]),
            );
          },
        );
      },
    );
  }

  // ── Bottom Nav — 5 tab dengan Keranjang ──────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, -4))
      ]),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_rounded, 'Beranda'),
              _navItem(1, Icons.search_rounded, 'Cari'),
              _navItemCart(),
              _navItem(3, Icons.history_rounded, 'Riwayat'),
              _navItem(4, Icons.person_rounded, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isActive = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedNavIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: isActive ? _accent.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              color: isActive ? _primaryDark : Colors.grey.shade400, size: 24),
          const SizedBox(height: 4),
          Text(label,
              style: _p(
                  size: 11,
                  weight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive ? _primaryDark : Colors.grey.shade400)),
        ]),
      ),
    );
  }

  // Tab Keranjang dengan badge jumlah slot
  Widget _navItemCart() {
    final isActive = _selectedNavIndex == 2;
    return GestureDetector(
      onTap: () => setState(() => _selectedNavIndex = 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: isActive ? _accent.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ValueListenableBuilder<List<KeranjangItem>>(
            valueListenable: CartManager.instance.itemsNotifier,
            builder: (_, items, __) {
              final totalSlot = CartManager.instance.totalSlot;
              return Stack(clipBehavior: Clip.none, children: [
                Icon(Icons.shopping_cart_rounded,
                    color: isActive ? _primaryDark : Colors.grey.shade400,
                    size: 24),
                if (totalSlot > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text('$totalSlot',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center),
                    ),
                  ),
              ]);
            },
          ),
          const SizedBox(height: 4),
          Text('Keranjang',
              style: _p(
                  size: 11,
                  weight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive ? _primaryDark : Colors.grey.shade400)),
        ]),
      ),
    );
  }
}