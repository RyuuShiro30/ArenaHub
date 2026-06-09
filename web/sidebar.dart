import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_notifiers.dart';
import 'auth/login.dart';

import 'dashboard/dashboardAdmin.dart';
import 'booking/kelola_booking.dart';
import 'booking/kelola_refund.dart';
import 'field/kelola_lapangan.dart';
import 'kelola_jadwal/kelolaJadwal.dart';
import 'profile/profileAdmin.dart';
import 'promo/kelola_promo.dart';

class AdminSidebar extends StatefulWidget {
  final int currentIndex;
  
  const AdminSidebar({super.key, required this.currentIndex});

  @override
  State<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const Color _blue   = Color(0xFF2563EB);
  static const Color _blueBg = Color(0xFFEFF6FF);
  static const Color _white  = Color(0xFFFFFFFF);
  static const Color _text   = Color(0xFF1A2B3C);
  static const Color _muted  = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);

  final bool _expanded = true;
  static const double _collapsedW = 56;
  static const double _expandedW  = 220;

  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.dashboard_rounded,            'label': 'Dashboard'},
    {'icon': Icons.confirmation_number_outlined, 'label': 'Kelola Booking'},
    {'icon': Icons.assignment_return_outlined,   'label': 'Kelola Refund'},
    {'icon': Icons.percent_rounded,              'label': 'Kelola Promo'},
    {'icon': Icons.event_note_outlined,          'label': 'Kelola Jadwal'},
    {'icon': Icons.sports_soccer_rounded,        'label': 'Kelola Lapangan'},
    {'icon': Icons.person_outline_rounded,       'label': 'Profil'},
  ];

  TextStyle _t({double size = 14, FontWeight weight = FontWeight.normal,
      Color color = _text, double spacing = 0}) =>
      GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: weight,
          color: color, letterSpacing: spacing);

  String _initials(String name) {
    final p = name.trim().split(' ');
    return p.length >= 2
        ? '${p[0][0]}${p[1][0]}'.toUpperCase()
        : name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  void _navigateTo(int index) {
    if (widget.currentIndex == index) return; 

    Widget nextScreen;
    switch (index) {
      case 0: nextScreen = const AdminDashboardScreen(); break;
      case 1: nextScreen = const KelolaBookingScreen(); break;
      case 2: nextScreen = const KelolaRefundScreen(); break;
      case 3: nextScreen = const KelolaPromoScreen(); break;
      case 4: nextScreen = const KelolaJadwalScreen(); break;
      case 5: nextScreen = const KelolaLapanganScreen(); break;
      case 6: nextScreen = const ProfileAdminScreen(); break;
      default: return;
    }

    Navigator.pushReplacement(
      context, 
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => nextScreen,
        transitionDuration: Duration.zero, 
        reverseTransitionDuration: Duration.zero,
      )
    );
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Keluar dari Akun?', style: _t(size: 16, weight: FontWeight.w700)),
        content: Text('Kamu akan keluar dari panel admin.', style: _t(size: 13, color: _muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: _t(size: 14, color: _muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('Keluar', style: _t(size: 14, weight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminLoginPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        width: _expanded ? _expandedW : _collapsedW,
        color: _white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                height: 64,
                padding: EdgeInsets.symmetric(horizontal: _expanded ? 14 : 10),
                decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: _border))),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                        color: _blue,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.sports_soccer_rounded,
                        color: Colors.white, size: 20),
                  ),
                  AnimatedOpacity(
                    opacity: _expanded ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: SizedBox(
                      width: _expandedW - 36 - 14 - 14,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ArenaHub',
                                style: _t(size: 14, weight: FontWeight.w800, color: _blue),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('PANEL ADMINISTRASI',
                                style: _t(size: 8, weight: FontWeight.w600,
                                    color: _muted, spacing: 0.5),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ),
                  ),
                ])),
            const SizedBox(height: 12),
            ...List.generate(_navItems.length, (i) {
              final active = widget.currentIndex == i;
              final item   = _navItems[i];
              return GestureDetector(
                onTap: () => _navigateTo(i),
                child: Container(
                  margin: EdgeInsets.symmetric(
                      horizontal: _expanded ? 8 : 4, vertical: 2),
                  padding: EdgeInsets.symmetric(
                      horizontal: _expanded ? 10 : 4, vertical: 10),
                  decoration: BoxDecoration(
                    color: active ? _blueBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 3, height: 20,
                      margin: EdgeInsets.only(right: _expanded ? 7 : 2),
                      decoration: BoxDecoration(
                        color: active ? _blue : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Icon(item['icon'] as IconData,
                        color: active ? _blue : _muted, size: 20),
                    AnimatedOpacity(
                      opacity: _expanded ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 150),
                      child: SizedBox(
                        width: _expanded ? _expandedW - 80 : 0,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Text(item['label'] as String,
                              style: _t(size: 13,
                                  weight: active ? FontWeight.w700 : FontWeight.w500,
                                  color: active ? _blue : _muted),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ),
                  ]),
                ),
              );
            }),
            const Spacer(),
            GestureDetector(
              onTap: _logout,
              child: Container(
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const SizedBox(width: 3, height: 20),
                  const SizedBox(width: 6),
                  const Icon(Icons.logout_rounded,
                      color: Color(0xFFEF4444), size: 20),
                  AnimatedOpacity(
                    opacity: _expanded ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: SizedBox(
                      width: _expanded ? _expandedW - 80 : 0,
                      child: const Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: Text('Keluar',
                            style: TextStyle(fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFEF4444)),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: _border))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                ValueListenableBuilder<String?>(
                  valueListenable: adminPhotoNotifier,
                  builder: (_, photoUrl, __) {
                    return ValueListenableBuilder<String>(
                      valueListenable: adminNameNotifier,
                      builder: (_, name, __) {
                        return Container(
                          width: 36, height: 36,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: _blue),
                          child: ClipOval(
                            child: photoUrl != null
                                ? Image.network(
                                    photoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Center(
                                      child: Text(_initials(name),
                                          style: _t(size: 13,
                                              weight: FontWeight.w700,
                                              color: Colors.white)),
                                    ),
                                  )
                                : Center(
                                    child: Text(_initials(name),
                                        style: _t(size: 13,
                                            weight: FontWeight.w700,
                                            color: Colors.white)),
                                  ),
                          ),
                        );
                      },
                    );
                  },
                ),
                AnimatedOpacity(
                  opacity: _expanded ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: SizedBox(
                    width: _expanded ? _expandedW - 36 - 12 - 12 - 10 : 0,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ValueListenableBuilder<String>(
                            valueListenable: adminNameNotifier,
                            builder: (_, name, __) => Text(name,
                                style: _t(size: 12, weight: FontWeight.w700),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          ValueListenableBuilder<String>(
                            valueListenable: adminRoleNotifier,
                            builder: (_, role, __) => Text(role,
                                style: _t(size: 10, color: _muted),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}