import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Global dark mode notifier (diakses juga dari main.dart) ───────────────────
final ValueNotifier<bool> darkModeNotifier = ValueNotifier(false);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifikasi = true;

  // ── Colors ───────────────────────────────────────────────────────────────────
  static const Color _primaryDark  = Color(0xFF0D2D6B);
  static const Color _primaryMid   = Color(0xFF1A4FAF);
  static const Color _accent       = Color(0xFF2563EB);

  TextStyle _p({
    double size = 14,
    FontWeight weight = FontWeight.normal,
    Color? color,
    double spacing = 0,
    double height = 1.4,
    bool isDark = false,
  }) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color ?? (isDark ? Colors.white : const Color(0xFF1A2B3C)),
      letterSpacing: spacing,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDark, _) {
        final bgColor      = isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F6F9);
        final cardColor    = isDark ? const Color(0xFF1E293B) : Colors.white;
        final textMain     = isDark ? Colors.white : const Color(0xFF1A2B3C);
        final textSub      = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
        final dividerColor = isDark ? Colors.white12 : Colors.grey.shade100;

        return Scaffold(
          backgroundColor: bgColor,
          body: Column(
            children: [
              // ── Gradient Header (extends behind status bar) ──────────────
              _buildGradientHeader(context),

              // ── Scrollable Content ───────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Stats
                      _buildStatsCard(cardColor, textSub, isDark),
                      const SizedBox(height: 24),

                      // AKUN
                      _sectionLabel('AKUN', textSub),
                      const SizedBox(height: 10),
                      _buildMenuCard(cardColor, dividerColor, [
                        _menuItem(Icons.person_outline_rounded,  'Informasi Pribadi', textMain, onTap: () {}),
                        _divider(dividerColor),
                        _menuItem(Icons.shield_outlined, 'Keamanan & Sandi', textMain, onTap: () {}),
                      ]),
                      const SizedBox(height: 24),

                      // PENGATURAN
                      _sectionLabel('PENGATURAN', textSub),
                      const SizedBox(height: 10),
                      _buildMenuCard(cardColor, dividerColor, [
                        _toggleItem(
                          Icons.notifications_outlined,
                          'Notifikasi',
                          _notifikasi,
                          textMain,
                          (val) => setState(() => _notifikasi = val),
                        ),
                        _divider(dividerColor),
                        // Dark mode toggle — pakai ValueNotifier
                        _toggleItem(
                          Icons.dark_mode_outlined,
                          'Mode Gelap',
                          isDark,
                          textMain,
                          (val) => darkModeNotifier.value = val,
                        ),
                      ]),
                      const SizedBox(height: 24),

                      // LAINNYA
                      _sectionLabel('LAINNYA', textSub),
                      const SizedBox(height: 10),
                      _buildMenuCard(cardColor, dividerColor, [
                        _menuItem(Icons.help_outline_rounded, 'Pusat Bantuan',    textMain, onTap: () {}),
                        _divider(dividerColor),
                        _menuItem(Icons.policy_outlined,      'Kebijakan Privasi', textMain, onTap: () {}),
                      ]),
                      const SizedBox(height: 28),

                      // Logout
                      _buildLogoutButton(),
                      const SizedBox(height: 16),

                      Center(
                        child: Text(
                          'Versi 2.4.1 (Build 108)',
                          style: _p(size: 12, color: textSub),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomNav(isDark),
        );
      },
    );
  }

  // ── Gradient Header ───────────────────────────────────────────────────────────
  Widget _buildGradientHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D3D6B), Color(0xFF1A6B8A), Color(0xFF1A8A6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top bar: back arrow + title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Back button kiri
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  // Judul tengah — putih & jelas
                  Text(
                    'Profil',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Avatar
            Stack(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.3),
                    border: Border.all(color: Colors.white.withOpacity(0.6), width: 3),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      'https://i.pravatar.cc/150?img=47',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4)],
                    ),
                    child: Icon(Icons.edit_rounded, size: 14, color: _primaryDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              'Candra Adi',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Candraadi12@gmail.com',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Stats Card ────────────────────────────────────────────────────────────────
  Widget _buildStatsCard(Color cardColor, Color textSub, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          _statItem('12', 'TOTAL BOOKING', textSub),
          _verticalDivider(isDark),
          _statItem('5',  'LAPANGAN',      textSub),
          _verticalDivider(isDark),
          _statItem('8',  'ULASAN',        textSub),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, Color labelColor) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: _accent)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500, color: labelColor, letterSpacing: 0.4)),
        ],
      ),
    );
  }

  Widget _verticalDivider(bool isDark) {
    return Container(width: 1, height: 36, color: isDark ? Colors.white12 : Colors.grey.shade200);
  }

  // ── Section Label ─────────────────────────────────────────────────────────────
  Widget _sectionLabel(String label, Color color) {
    return Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.8));
  }

  // ── Menu Card ─────────────────────────────────────────────────────────────────
  Widget _buildMenuCard(Color cardColor, Color dividerColor, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: children),
    );
  }

  Widget _menuItem(IconData icon, String title, Color textColor, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: _primaryMid, size: 22),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: textColor))),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _toggleItem(IconData icon, String title, bool value, Color textColor, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: _primaryMid, size: 22),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: textColor))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: _accent,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _divider(Color color) {
    return Divider(height: 1, thickness: 1, indent: 54, endIndent: 18, color: color);
  }

  // ── Logout ────────────────────────────────────────────────────────────────────
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
        label: Text('Keluar dari Akun', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.red)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.red, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  // ── Bottom Nav ────────────────────────────────────────────────────────────────
  Widget _buildBottomNav(bool isDark) {
    final navBg    = isDark ? const Color(0xFF1E293B) : Colors.white;
    final items = [
      {'icon': Icons.home_rounded,    'label': 'Beranda'},
      {'icon': Icons.search_rounded,  'label': 'Cari'},
      {'icon': Icons.history_rounded, 'label': 'Riwayat'},
      {'icon': Icons.person_rounded,  'label': 'Profil'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: navBg,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final isActive = i == 3;
              return GestureDetector(
                onTap: () { if (i == 0) Navigator.pop(context); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? _accent.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(items[i]['icon'] as IconData, color: isActive ? _primaryDark : Colors.grey.shade400, size: 24),
                      const SizedBox(height: 4),
                      Text(
                        items[i]['label'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          color: isActive ? _primaryDark : Colors.grey.shade400,
                        ),
                      ),
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