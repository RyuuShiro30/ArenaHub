import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class PusatBantuanScreen extends StatefulWidget {
  const PusatBantuanScreen({super.key});

  @override
  State<PusatBantuanScreen> createState() => _PusatBantuanScreenState();
}

class _PusatBantuanScreenState extends State<PusatBantuanScreen> {
  // ── Colors ───────────────────────────────────────────────────────────────────
  static const Color _primaryDark = Color(0xFF0D2D6B);
  static const Color _accent      = Color(0xFF1A4FAF);
  static const Color _bgColor     = Color(0xFFF4F6F9);
  static const Color _textDark    = Color(0xFF1A2B3C);
  static const Color _green       = Color(0xFF1A6B4A);

  // ── State accordion ───────────────────────────────────────────────────────────
  bool _tentangExpanded = false;

  final List<Map<String, dynamic>> _faqList = [
    {
      'question': 'Bagaimana cara mengubah profil?',
      'answer'  : 'Masuk ke menu Profil, klik Edit Profil, ubah data Anda, lalu klik Simpan.',
      'expanded': false,
    },
    {
      'question': 'Bagaimana cara mengubah kata sandi?',
      'answer'  : 'Masuk ke menu Profil, pilih Keamanan & Sandi, masukkan sandi lama dan baru, lalu klik Simpan.',
      'expanded': false,
    },
    {
      'question': 'Bagaimana cara melakukan booking lapangan?',
      'answer'  : 'Pilih lapangan yang tersedia, tentukan tanggal dan waktu, lalu klik Pesan Sekarang dan selesaikan pembayaran.',
      'expanded': false,
    },
    {
      'question': 'Bagaimana cara membatalkan booking?',
      'answer'  : 'Buka menu Riwayat, pilih booking yang ingin dibatalkan, lalu klik tombol Batalkan Booking.',
      'expanded': false,
    },
  ];

  TextStyle _p({double size = 14, FontWeight weight = FontWeight.normal,
      Color color = _textDark, double spacing = 0, double height = 1.5}) {
    return GoogleFonts.poppins(fontSize: size, fontWeight: weight,
        color: color, letterSpacing: spacing, height: height);
  }

  // ── Buka email ────────────────────────────────────────────────────────────────
  void _hubungiEmail() {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.email_outlined, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Text('Fitur email akan segera tersedia!',
              style: _p(size: 13, color: Colors.white)),
        ],
      ),
      backgroundColor: _green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      duration: const Duration(seconds: 2),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar putih ─────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: _primaryDark),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Text('Pusat Bantuan', style: _p(size: 17, weight: FontWeight.w600)),
                ],
              ),
            ),

            // ── Scrollable Content ────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // ── Hero Banner ───────────────────────────────────────
                    _buildHeroBanner(),
                    const SizedBox(height: 24),

                    // ── Tentang Arena Hub (accordion) ─────────────────────
                    _buildTentangSection(),
                    const SizedBox(height: 20),

                    // ── FAQ Section ───────────────────────────────────────
                    _buildFaqSection(),
                    const SizedBox(height: 28),

                    // ── Hubungi Kami card ─────────────────────────────────
                    _buildHubungiCard(),
                    const SizedBox(height: 20),

                    // ── Footer ────────────────────────────────────────────
                    Center(
                      child: Text('© 2026 ArenaHub',
                          style: _p(size: 12, color: Colors.grey.shade400)),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero Banner ───────────────────────────────────────────────────────────────
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      height: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2D6B), Color(0xFF1A4FAF), Color(0xFF1A6B8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -20, top: -20,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            right: 30, bottom: -30,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
          // Text
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Halo! Apa yang bisa kami\nbantu hari ini?',
                  style: _p(size: 18, weight: FontWeight.bold, color: Colors.white, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tentang Arena Hub (single accordion) ─────────────────────────────────────
  Widget _buildTentangSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row (clickable)
        InkWell(
          onTap: () => setState(() => _tentangExpanded = !_tentangExpanded),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: _accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Tentang Arena Hub',
                      style: _p(size: 15, weight: FontWeight.w600, color: _accent)),
                ),
                Icon(
                  _tentangExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: _accent, size: 22,
                ),
              ],
            ),
          ),
        ),

        // Expanded content
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04),
                    blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Text(
              'ArenaHub adalah platform booking lapangan olahraga terintegrasi yang memudahkan atlet untuk menemukan dan memesan fasilitas olahraga terbaik di sekitar mereka.',
              style: _p(size: 13, color: Colors.grey.shade700),
            ),
          ),
          crossFadeState: _tentangExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }

  // ── FAQ Section ───────────────────────────────────────────────────────────────
  Widget _buildFaqSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Row(
          children: [
            Icon(Icons.quiz_outlined, color: _accent, size: 20),
            const SizedBox(width: 8),
            Text('Pertanyaan Umum (FAQ)',
                style: _p(size: 15, weight: FontWeight.w600, color: _accent)),
          ],
        ),
        const SizedBox(height: 14),

        // FAQ accordion items
        ...List.generate(_faqList.length, (i) {
          final item = _faqList[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04),
                    blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                title: Text(
                  item['question'] as String,
                  style: _p(size: 13, weight: FontWeight.w600, color: _textDark),
                ),
                trailing: Icon(
                  item['expanded'] as bool
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: _primaryDark, size: 22,
                ),
                onExpansionChanged: (expanded) {
                  setState(() => _faqList[i]['expanded'] = expanded);
                },
                children: [
                  Text(
                    item['answer'] as String,
                    style: _p(size: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Hubungi Kami Card ─────────────────────────────────────────────────────────
  Widget _buildHubungiCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          // Icon
          Container(
            width: 56, height: 56,
            decoration: const BoxDecoration(
              color: _primaryDark,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.headset_mic_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 14),
          Text('Hubungi Kami',
              style: _p(size: 16, weight: FontWeight.bold, color: _primaryDark)),
          const SizedBox(height: 6),
          Text(
            'Jika Anda butuh bantuan lebih lanjut,\nsilakan hubungi kami.',
            textAlign: TextAlign.center,
            style: _p(size: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 18),
          // Hubungi Disini button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _hubungiEmail,
              icon: const Icon(Icons.email_outlined, color: Colors.white, size: 18),
              label: Text('Hubungi Disini',
                  style: _p(size: 14, weight: FontWeight.w600, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}