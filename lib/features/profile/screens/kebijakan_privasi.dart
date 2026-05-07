import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KebijakanPrivasiScreen extends StatelessWidget {
  const KebijakanPrivasiScreen({super.key});

  static const Color _primaryDark = Color(0xFF0D2D6B);
  static const Color _accent      = Color(0xFF1A4FAF);
  static const Color _green       = Color(0xFF1A6B4A);
  static const Color _bgColor     = Color(0xFFF4F6F9);
  static const Color _textDark    = Color(0xFF1A2B3C);

  TextStyle _p({double size = 14, FontWeight weight = FontWeight.normal,
      Color color = _textDark, double spacing = 0, double height = 1.5}) {
    return GoogleFonts.poppins(fontSize: size, fontWeight: weight,
        color: color, letterSpacing: spacing, height: height);
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
                  Text('Kebijakan Privasi', style: _p(size: 17, weight: FontWeight.w600)),
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
                    const SizedBox(height: 32),

                    // ── Hero Title ────────────────────────────────────────
                    Text(
                      'Keamanan\nData Anda.',
                      style: _p(
                        size: 32,
                        weight: FontWeight.bold,
                        color: _primaryDark,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Green underline
                    Container(width: 50, height: 4,
                        decoration: BoxDecoration(
                          color: _green,
                          borderRadius: BorderRadius.circular(2),
                        )),
                    const SizedBox(height: 20),

                    // ── Intro text ────────────────────────────────────────
                    Text(
                      'Terakhir diperbarui: 24 Maret 2026. Kami menghargai kepercayaan Anda dan berkomitmen untuk melindungi privasi digital anda dalam ekosistem ArenaHub.',
                      style: _p(size: 13, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 28),

                    // ── Informasi Dasar card ──────────────────────────────
                    _buildInfoCard(
                      icon: Icons.shield_outlined,
                      iconColor: _accent,
                      title: 'Informasi Dasar',
                      content: 'Kami mengumpulkan informasi yang Anda berikan langsung kepada kami saat membuat akun, termasuk nama, alamat email, dan nomor telepon untuk keperluan otentikasi atlet dan manajemen fasilitas.',
                      tags: ['IDENTITAS', 'KONTAK'],
                    ),
                    const SizedBox(height: 16),

                    // ── Data Lokasi card ──────────────────────────────────
                    _buildInfoCard(
                      icon: Icons.location_on_outlined,
                      iconColor: _green,
                      title: 'Data Lokasi',
                      content: 'Untuk memberikan layanan pemesanan arena yang akurat, aplikasi kami memerlukan akses ke koordinat GPS perangkat Anda. Data ini digunakan secara eksklusif untuk menemukan fasilitas terdekat dan tidak dibagikan kepada pihak ketiga untuk tujuan pemasaran.',
                      tags: [],
                    ),
                    const SizedBox(height: 16),

                    // ── Keamanan Enkripsi card (dark) ─────────────────────
                    _buildEnkripsiCard(),
                    const SizedBox(height: 28),

                    // ── Hak-Hak Pengguna ──────────────────────────────────
                    _buildHakPengguna(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Info Card (white) ─────────────────────────────────────────────────────────
  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    required List<String> tags,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + Title
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Text(title, style: _p(size: 15, weight: FontWeight.bold, color: iconColor)),
            ],
          ),
          const SizedBox(height: 14),
          Text(content, style: _p(size: 13, color: Colors.grey.shade700)),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              children: tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _bgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(tag, style: _p(size: 10, weight: FontWeight.w600,
                    color: Colors.grey.shade600, spacing: 0.5)),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ── Enkripsi Card (dark blue) ─────────────────────────────────────────────────
  Widget _buildEnkripsiCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2D6B), Color(0xFF1A4FAF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Keamanan Enkripsi',
              style: _p(size: 16, weight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          Text(
            'Seluruh transaksi finansial dan data performa atlet dienkripsi menggunakan protokol SSL/TLS standar industri tingkat tinggi.',
            style: _p(size: 13, color: Colors.white70),
          ),
          const SizedBox(height: 18),

          // Status Proteksi bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('STATUS PROTEKSI',
                          style: _p(size: 10, weight: FontWeight.w600,
                              color: Colors.white60, spacing: 0.8)),
                      const SizedBox(height: 4),
                      Text('99.9% Active',
                          style: _p(size: 18, weight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: _green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.lock_rounded, color: Colors.white, size: 22),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Hak-Hak Pengguna ─────────────────────────────────────────────────────────
  Widget _buildHakPengguna() {
    final List<Map<String, String>> hak = [
      {
        'title'  : 'Akses:',
        'content': 'Anda berhak melihat semua data pribadi yang kami simpan.',
      },
      {
        'title'  : 'Koreksi:',
        'content': 'Anda dapat memperbarui data profil kapan saja melalui menu pengaturan.',
      },
      {
        'title'  : 'Penghapusan:',
        'content': 'Anda dapat mengajukan permohonan penghapusan akun permanen.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hak-Hak Pengguna',
            style: _p(size: 16, weight: FontWeight.bold, color: _primaryDark)),
        const SizedBox(height: 16),
        ...hak.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle_rounded, color: _green, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${item['title']} ',
                        style: _p(size: 13, weight: FontWeight.bold, color: _textDark),
                      ),
                      TextSpan(
                        text: item['content'],
                        style: _p(size: 13, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}