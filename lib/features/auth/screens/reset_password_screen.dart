import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Controller untuk mengambil input Email
  final TextEditingController emailController = TextEditingController();

  final Color backgroundColor = const Color(0xFFF3F4F7); 
  final Color navyDark = const Color(0xFF1B2430);      
  final Color primaryBlue = const Color(0xFF135B9D);   
  final Color accentGreen = const Color(0xFF38B285);   
  final Color textGrey = const Color(0xFF7D858D);      
  final Color inputBg = Colors.white;                 

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleResetPassword() {
    String email = emailController.text.trim();

    // 1. Validasi Kosong
    if (email.isEmpty) {
      _showSnackBar(context, "Email tidak boleh kosong");
      return;
    }

    // 2. Validasi Format Email 
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showSnackBar(context, "Format email tidak valid");
      return;
    }

    // Jika lolos validasi
    print("Permintaan Reset Password dikirim ke: $email");
    // Di sini nanti Rani bisa tambahkan integrasi Firebase/API
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: medicalPadding(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                /// --- HEADER ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new, color: navyDark, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Row(
                      children: [
                        Icon(Icons.sports_volleyball, color: primaryBlue, size: 28),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Arena", style: TextStyle(color: navyDark, fontSize: 18, height: 1.1)),
                            Text("Hub", style: TextStyle(color: navyDark, fontSize: 18, fontWeight: FontWeight.bold, height: 1.1)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 48), 
                  ],
                ),

                const SizedBox(height: 50),

                /// --- 1. JUDUL & DESKRIPSI ---
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Lupa Password",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: navyDark,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Silahkan isi email di bawah dan kami akan membantu untuk memperbarui password kamu",
                      style: TextStyle(
                        fontSize: 15,
                        color: textGrey,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                _buildLabel("Email"),
                const SizedBox(height: 8),
                _buildShadowedInput(
                  controller: emailController,
                  hintText: "Masukkan Email",
                  icon: Icons.email_outlined,
                ),

                const SizedBox(height: 40),

                _buildResetButton(context),

                const SizedBox(height: 40),

                Row(
                  children: [
                    Expanded(child: Divider(color: textGrey.withOpacity(0.3), thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text("atau", style: TextStyle(color: textGrey.withOpacity(0.6))),
                    ),
                    Expanded(child: Divider(color: textGrey.withOpacity(0.3), thickness: 1)),
                  ],
                ),

                const SizedBox(height: 40),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Belum punya akun? ", style: TextStyle(color: textGrey)),
                    GestureDetector(
                      onTap: () {
                        print("Navigasi ke Daftar Sekarang");
                      },
                      child: Text(
                        "Daftar sekarang",
                        style: TextStyle(color: accentGreen, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 50),

                _buildFooter(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Widget Helper ---

  Widget _buildLabel(String text) {
    return Text(text, style: TextStyle(color: navyDark, fontWeight: FontWeight.w600));
  }

  Widget _buildShadowedInput({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        // PENAMBAHAN: Keyboard khusus email
        keyboardType: TextInputType.emailAddress, 
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: textGrey.withOpacity(0.6)),
          prefixIcon: Icon(icon, color: textGrey),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildResetButton(BuildContext context) {
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        onPressed: _handleResetPassword, // Memanggil fungsi validasi di atas
        child: const Text(
          "Reset Password",
          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.help_outline, color: textGrey, size: 24),
            const SizedBox(width: 24),
            Icon(Icons.language_outlined, color: textGrey, size: 24),
            const SizedBox(width: 24),
            Icon(Icons.info_outline, color: textGrey, size: 24),
          ],
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            "© 2026 ArenaHub. Semua Hak Dilindungi.",
            style: TextStyle(color: textGrey, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget medicalPadding({required Widget child}) => child;
}