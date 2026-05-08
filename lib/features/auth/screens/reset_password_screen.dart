import 'package:flutter/material.dart';
import 'register_screen.dart'; 
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
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

  // Fungsi untuk handle pengiriman email reset password
  Future<void> _handleResetPassword() async {
    String email = emailController.text.trim();

    if (email.isEmpty) {
      _showSnackBar(context, "Email tidak boleh kosong");
      return;
    }

    try {
      // Proses kirim email via Firebase
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Link reset password telah dikirim ke email Anda"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Kembali ke login screen setelah berhasil
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });

    } on FirebaseAuthException catch (e) {
      String message = "Terjadi kesalahan";
      if (e.code == 'user-not-found') message = "User tidak ditemukan";
      _showSnackBar(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              Text(
                "Lupa Password",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: navyDark),
              ),
              const SizedBox(height: 16),
              Text(
                "Silahkan isi email di bawah dan kami akan mengirimkan link untuk mengatur ulang password kamu.",
                style: TextStyle(fontSize: 15, color: textGrey),
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
              _buildResetButton(),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Belum punya akun? ", style: TextStyle(color: textGrey)),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: TextStyle(color: navyDark, fontWeight: FontWeight.w600));
  }

  Widget _buildShadowedInput({required TextEditingController controller, required String hintText, required IconData icon}) {
    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, color: textGrey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        onPressed: _handleResetPassword,
        child: const Text("Reset Password", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Text("© 2026 ArenaHub. Semua Hak Dilindungi.", style: TextStyle(color: textGrey, fontSize: 12)),
    );
  }
}