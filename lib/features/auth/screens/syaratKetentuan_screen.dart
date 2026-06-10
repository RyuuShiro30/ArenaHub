import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  static const Color backgroundColor = Color(0xFFF3F4F7);
  static const Color navyDark = Color(0xFF1B2430);
  static const Color primaryBlue = Color(0xFF135B9D);
  static const Color accentGreen = Color(0xFF38B285);
  static const Color textGrey = Color(0xFF7D858D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: navyDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(Icons.sports_tennis, color: primaryBlue, size: 22),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Arena",
                    style: GoogleFonts.poppins(
                        color: navyDark, fontSize: 14, height: 1.1)),
                Text("Hub",
                    style: GoogleFonts.poppins(
                        color: navyDark,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        height: 1.1)),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// --- HEADER JUDUL ---
            Text(
              "Syarat &\nKetentuan.",
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Container(width: 48, height: 4, color: accentGreen),
            const SizedBox(height: 16),
            Text(
              "Kami menghargai kepercayaan Anda dan berkomitmen untuk melindungi privasi digital Anda dalam ekosistem ArenaHub.",
              style: GoogleFonts.poppins(
                  fontSize: 13, color: textGrey, height: 1.6),
            ),
            const SizedBox(height: 28),

            /// --- SECTION 1: Informasi Dasar ---
            _buildSectionCard(
              icon: Icons.shield_outlined,
              iconBgColor: primaryBlue,
              title: "Informasi Dasar",
              body:
                  "Kami mengumpulkan informasi yang Anda berikan langsung kepada kami saat membuat akun, termasuk nama, alamat email, dan nomor telepon untuk keperluan otentikasi atlet dan manajemen fasilitas.",
              tags: const ["IDENTITAS", "KONTAK"],
            ),

            const SizedBox(height: 16),

            /// --- SECTION 2: Data Lokasi (Single Tenant) ---
            _buildSectionCard(
              icon: Icons.location_on_outlined,
              iconBgColor: accentGreen,
              title: "Data Lokasi",
              body:
                  "ArenaHub merupakan platform penyedia fasilitas olahraga yang hanya beroperasi di satu lokasi eksklusif. Akses koordinat GPS perangkat Anda hanya digunakan untuk keperluan validasi presensi saat Anda tiba di area fasilitas kami, dan data ini tidak dibagikan kepada pihak ketiga.",
              tags: const [],
            ),

            const SizedBox(height: 16),

            /// --- SECTION 3: Keamanan Enkripsi ---
            _buildEncryptionCard(),

            const SizedBox(height: 28),

            /// --- SECTION 4: Hak-Hak Pengguna ---
            Text(
              "Hak-Hak Pengguna",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 14),
            _buildUserRight(
              label: "Akses",
              description:
                  "Anda berhak melihat semua data pribadi yang kami simpan.",
            ),
            const SizedBox(height: 12),
            _buildUserRight(
              label: "Koreksi",
              description:
                  "Anda dapat memperbarui data profil kapan saja melalui menu pengaturan.",
            ),

            const SizedBox(height: 28),

            /// --- SECTION 5: Ketentuan Registrasi Akun ---
            Text(
              "Ketentuan Registrasi Akun",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 14),

            _buildTermCard(
              number: "01",
              title: "Kelayakan Pengguna",
              content:
                  "Layanan ArenaHub hanya diperuntukkan bagi pengguna yang berusia minimal 17 tahun atau telah mendapat persetujuan dari orang tua/wali yang sah. Dengan mendaftar, Anda menyatakan bahwa data yang diberikan adalah benar dan akurat.",
            ),
            const SizedBox(height: 12),
            _buildTermCard(
              number: "02",
              title: "Keamanan Akun",
              content:
                  "Anda bertanggung jawab penuh atas kerahasiaan kata sandi akun Anda. Segera hubungi tim dukungan ArenaHub jika Anda mencurigai adanya akses tidak sah pada akun Anda. ArenaHub tidak akan pernah meminta kata sandi Anda melalui media apapun.",
            ),
            const SizedBox(height: 12),
            _buildTermCard(
              number: "03",
              title: "Data yang Diberikan",
              content:
                  "Pengguna wajib memberikan informasi yang valid dan terkini. ArenaHub berhak menangguhkan atau menghapus akun yang terbukti menggunakan informasi palsu, menyesatkan, atau melanggar hak pihak ketiga.",
            ),
            const SizedBox(height: 12),
            _buildTermCard(
              number: "04",
              title: "Penggunaan Layanan",
              content:
                  "Akun ArenaHub hanya boleh digunakan untuk keperluan pemesanan fasilitas olahraga yang sah. Dilarang keras menggunakan akun untuk tujuan komersial tanpa izin tertulis, melakukan tindakan yang merugikan pengguna lain, atau menyalahgunakan sistem pemesanan.",
            ),
            const SizedBox(height: 12),
            _buildTermCard(
              number: "05",
              title: "Perubahan Ketentuan",
              content:
                  "ArenaHub berhak mengubah syarat dan ketentuan ini sewaktu-waktu. Perubahan akan diberitahukan melalui notifikasi aplikasi atau email terdaftar. Penggunaan layanan yang berkelanjutan setelah perubahan dianggap sebagai persetujuan atas ketentuan baru.",
            ),

            const SizedBox(height: 32),

            /// --- TOMBOL SETUJU ---
            _buildAgreeButton(context),

            const SizedBox(height: 24),

            /// --- FOOTER ---
            Center(
              child: Text(
                "© 2026 ArenaHub. Semua Hak Dilindungi.",
                style: GoogleFonts.poppins(color: textGrey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // --- Widget: Kartu Section (Informasi Dasar, Data Lokasi) ---
  Widget _buildSectionCard({
    required IconData icon,
    required Color iconBgColor,
    required String title,
    required String body,
    required List<String> tags,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: navyDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            body,
            style: GoogleFonts.poppins(
                fontSize: 13, color: textGrey, height: 1.6),
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              children: tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: navyDark,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  // --- Widget: Kartu Keamanan Enkripsi (dark card) ---
  Widget _buildEncryptionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Keamanan Enkripsi",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Seluruh transaksi finansial dan data performa atlet dienkripsi menggunakan protokol SSL/TLS standar industri tingkat tinggi.",
            style: GoogleFonts.poppins(
                fontSize: 13, color: Colors.white.withOpacity(0.85), height: 1.6),
          ),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "STATUS PROTEKSI",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.7),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "99.9% Active",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accentGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_rounded,
                      color: Colors.white, size: 22),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget: Hak Pengguna Item ---
  Widget _buildUserRight(
      {required String label, required String description}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle_outline_rounded,
            color: accentGreen, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "$label: ",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: accentGreen,
                  ),
                ),
                TextSpan(
                  text: description,
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: textGrey, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Widget: Kartu Ketentuan Registrasi Bernomor ---
  Widget _buildTermCard(
      {required String number,
      required String title,
      required String content}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: primaryBlue.withOpacity(0.15),
              height: 1,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: navyDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: textGrey, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget: Tombol Setuju & Kembali ---
  Widget _buildAgreeButton(BuildContext context) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        onPressed: () => Navigator.pop(context),
        child: const Text(
          "Saya Mengerti & Setuju",
          style: TextStyle(
              fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}