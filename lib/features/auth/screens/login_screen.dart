import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'reset_password_screen.dart';
import 'package:appbookinglapangan/features/home/screens/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  final Color backgroundColor = const Color(0xFFF3F4F7);
  final Color navyDark = const Color(0xFF1B2430);
  final Color primaryBlue = const Color(0xFF135B9D);
  final Color accentGreen = const Color(0xFF38B285);
  final Color textGrey = const Color(0xFF7D858D);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(BuildContext context) async {
    String input = emailController.text.trim();
    String password = passwordController.text;
    String emailToLogin = input; 

    if (input.isEmpty || password.isEmpty) {
      _showSnackBar(context, "Email/Nomor Telepon dan kata sandi tidak boleh kosong");
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (RegExp(r'^[0-9]+$').hasMatch(input)) {
        var userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: input)
            .get();

        if (userQuery.docs.isNotEmpty) {
          emailToLogin = userQuery.docs.first.get('email');
        } else {
          _showSnackBar(context, "Nomor telepon tidak terdaftar");
          setState(() => _isLoading = false);
          return;
        }
      }

      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailToLogin,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
        await userDoc.update({'lastLogin': FieldValue.serverTimestamp()});
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Terjadi kesalahan";
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        errorMessage = "Akun tidak ditemukan atau format salah";
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMessage = "Kata sandi salah";
      } else {
        errorMessage = e.message ?? "Login gagal";
      }
      
      _showSnackBar(context, errorMessage);
    } catch (e) {
      _showSnackBar(context, "Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // --- HEADER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: primaryBlue, shape: BoxShape.circle),
                        child: const Center(child: Icon(Icons.sports_soccer, color: Colors.white, size: 22)),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Arena", style: TextStyle(color: navyDark, fontSize: 18, height: 1.1)),
                          Text("Hub", style: TextStyle(color: navyDark, fontSize: 18, fontWeight: FontWeight.bold, height: 1.1)),
                        ],
                      ),
                    ],
                  ),
                  Icon(Icons.help_outline, color: navyDark, size: 28),
                ],
              ),

              const SizedBox(height: 32),

              // --- BANNER IMAGE ---
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Center(
                  child: Container(
                    width: 342, height: 224,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/images/sports_collage.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300], child: const Icon(Icons.image, size: 50, color: Colors.grey)),
                      ),
                    ),
                  ),
                ),
              ),

              Center(child: Text("Selamat Datang!", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: navyDark))),
              const SizedBox(height: 8),
              Center(child: Text("Masuk ke akun ArenaHub Anda", style: TextStyle(color: textGrey, fontSize: 15))),

              const SizedBox(height: 32),

              _buildLabel("Email atau Nomor Telepon"),
              const SizedBox(height: 8),
              _buildShadowedInput(controller: emailController, hintText: "Contoh: 0812XXXXXXXX atau user@email.com", icon: Icons.email_outlined),

              const SizedBox(height: 20),

              _buildLabel("Kata Sandi"),
              const SizedBox(height: 8),
              _buildShadowedInput(
                controller: passwordController,
                hintText: "Masukkan kata sandi",
                icon: Icons.lock_outline,
                obscure: _obscurePassword,
                suffix: _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                onSuffixPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),

              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen())),
                  child: Text("Lupa Kata Sandi?", style: TextStyle(color: accentGreen, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 32),

              _buildLoginButton(),

              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[300])),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text("atau", style: TextStyle(color: textGrey))),
                  Expanded(child: Divider(color: Colors.grey[300])),
                ],
              ),

              const SizedBox(height: 25),
              
              // --- TOMBOL GOOGLE SESUAI GAMBAR ---
              _googleLoginButton(),

              const SizedBox(height: 35),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Belum punya akun? ", style: TextStyle(color: textGrey)),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                    child: Text("Daftar sekarang", style: TextStyle(color: accentGreen, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(child: Text("© 2026 ARENAHUB", style: TextStyle(color: textGrey.withOpacity(0.6), fontSize: 12, letterSpacing: 1.2))),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text, style: TextStyle(color: textGrey, fontWeight: FontWeight.w600, fontSize: 14));

  Widget _buildShadowedInput({required TextEditingController controller, required String hintText, required IconData icon, bool obscure = false, IconData? suffix, VoidCallback? onSuffixPressed}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, color: textGrey),
          suffixIcon: suffix != null ? IconButton(icon: Icon(suffix, color: textGrey), onPressed: onSuffixPressed) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      height: 55,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
        onPressed: _isLoading ? null : () => _handleLogin(context),
        child: _isLoading 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
            : const Text("Masuk", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _googleLoginButton() {
    return InkWell(
      onTap: () {
        // Logika Google Sign In kamu di sini
      },
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25), // Dibuat lebih membulat sesuai gambar
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3c/Google_Favicon_2025.svg/1280px-Google_Favicon_2025.svg.png',
              height: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              "Google",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}