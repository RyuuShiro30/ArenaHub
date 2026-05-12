import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controllers to retrieve input values
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // --- FUNGSI VALIDASI ---
  bool _validateInputs() {
    // 1. Validasi Nama Lengkap
    if (fullNameController.text.trim().isEmpty) {
      _showSnackBar("Nama lengkap tidak boleh kosong");
      return false;
    }

    // 2. Validasi Email
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailController.text)) {
      _showSnackBar("Format email tidak valid");
      return false;
    }
    // 3. Validasi Nomor Telepon
    if (phoneController.text.length < 10 || !RegExp(r'^[0-9]+$').hasMatch(phoneController.text)) {
      _showSnackBar("Nomor telepon tidak valid (minimal 10 digit angka)");
      return false;
    }
    // 4. Validasi Password
    String password = passwordController.text;
    if (password.length < 8 || 
        !RegExp(r'^(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$').hasMatch(password)) {
      _showSnackBar("Password minimal 8 karakter dengan kombinasi huruf besar, angka, dan simbol(!@#\$&*)");
      return false;
    }
    // 5. Validasi Konfirmasi Password
    if (confirmPasswordController.text != password) {
      _showSnackBar("Konfirmasi password tidak cocok");
      return false;
    }
    // 6. Validasi Checkbox
    if (!_agreedToTerms) {
      _showSnackBar("Anda harus menyetujui Syarat & Ketentuan");
      return false;
    }
    return true; //lolos validasi
  }

  // Helper untuk menampilkan pesan error
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.greenAccent),
    );
  }

  // State variables for interactivity
  bool _obscurePassword = true; // For Password field
  bool _obscureConfirmPassword = true; // For Confirm Password field
  bool _agreedToTerms = false; // For Checkbox

  // --- PALET WARNA ---
  final Color backgroundColor = const Color(0xFFF3F4F7); // Abu-abu sangat muda (Medium UI)
  final Color navyDark = const Color(0xFF1B2430);      // Warna Teks Judul
  final Color primaryBlue = const Color(0xFF135B9D);   // Warna Ikon & Tombol
  final Color accentGreen = const Color(0xFF38B285);   // Warna Link Syarat
  final Color textGrey = const Color(0xFF7D858D);      // Warna Label & Hint
  final Color inputBg = Colors.white;

  @override
  void dispose() {
    // Disposal is important for memory management
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
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
              /// --- HEADER (Logo Arena Hub) ---
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Ikon Tenis Sesuai Gambar
                    Icon(Icons.sports_tennis, color: primaryBlue, size: 28),
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
              ),

              const SizedBox(height: 30),

              /// --- 1. BANNER DUMBBELL & TEKS ---
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 342, // Sesuai ukuran banner login
                    height: 224, // Sesuai ukuran banner login
                    decoration: BoxDecoration(
                      color: Colors.grey[200], // Background terang di dalam banner
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1), // Opacity disamakan dengan login
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center, // Ikon & teks di tengah vertikal
                        children: [
                          // Ikon Dumbbell Besar
                          Icon(
                            Icons.fitness_center_outlined, 
                            color: primaryBlue, 
                            size: 80,
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              "Booking lapangan jadi lebih mudah",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20, // Sedikit disesuaikan agar pas di kotak 224
                                fontWeight: FontWeight.bold,
                                color: navyDark,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              /// --- 2. FORM INPUT ---

              _buildLabel("Nama Lengkap"),
              const SizedBox(height: 8),
              _buildShadowedInput(
                
                controller: fullNameController,
                hintText: "Masukkan nama lengkap Anda",
                icon: Icons.person_outline,
              ),
              

              const SizedBox(height: 20),

              _buildLabel("Email"),
              const SizedBox(height: 8),
              _buildShadowedInput(
                controller: emailController,
                hintText: "user@email.com",
                icon: Icons.email_outlined,
              ),

              const SizedBox(height: 20),

              _buildLabel("Nomor Telepon"),
              const SizedBox(height: 8),
              _buildShadowedInput(
                controller: phoneController,
                hintText: "0812xxxxxxxx",
                icon: Icons.phone_outlined,
              ),

              const SizedBox(height: 20),

              _buildLabel("Password"),
                const SizedBox(height: 8),
                _buildShadowedInput(
                  controller: passwordController,
                  hintText: "Masukkan Password",
                  icon: Icons.lock_outline,
                  obscure: _obscurePassword,
                  suffix: _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, 
                  onSuffixPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),

              const SizedBox(height: 20),

             _buildLabel("Konfirmasi Password"),
                const SizedBox(height: 8),
                _buildShadowedInput(
                  controller: confirmPasswordController,
                  hintText: "Ulangi password Anda",
                  icon: Icons.verified_user_outlined,
                  obscure: _obscureConfirmPassword,
                  // UBAH BAGIAN INI:
                  suffix: _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  onSuffixPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),

              const SizedBox(height: 30),

              /// --- 3. CHECKBOX & TERMS OF USE ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (bool? newValue) {
                      setState(() {
                        _agreedToTerms = newValue!;
                      });
                    },
                    activeColor: primaryBlue,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: RichText(
                        text: TextSpan(
                          text: "Saya menyetujui ",
                          style: GoogleFonts.poppins(color: textGrey, fontSize: 14, letterSpacing: 0.5),
                          children: [
                            TextSpan(
                              text: "Syarat & Ketentuan ",
                              style: TextStyle(color: accentGreen, fontWeight: FontWeight.bold),
                              // TODO: Add recognized for navigation
                            ),
                            TextSpan(text: "ArenaHub", style: TextStyle(color: textGrey, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              /// --- 4. BUTTON DAFTAR SEKARANG ---
              _buildDaftarButton(context),

              const SizedBox(height: 30),

              /// --- 5. SUDAH PUNYA AKUN? ---
              // ... bagian kode lainnya tetap sama ...

              /// --- 5. SUDAH PUNYA AKUN? ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Sudah punya akun? ", style: TextStyle(color: textGrey)),
                  GestureDetector(
                    onTap: () {
                      // PERBAIKAN: Gunakan pushReplacementNamed jika kamu pakai routes, 
                      // atau pushReplacement jika manual agar tidak menumpuk halaman.
                      // Jika kamu menggunakan penamaan route di main.dart:
                      Navigator.pushReplacementNamed(context, '/login'); 
                      
                      // ATAU jika kamu ingin kembali ke halaman sebelumnya (jika yakin dari login):
                      // if (Navigator.canPop(context)) {
                      //   Navigator.pop(context);
                      // } else {
                      //   Navigator.pushReplacementNamed(context, '/login');
                      // }
                    },
                    child: Text(
                      "Masuk di sini",
                      style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),


              const SizedBox(height: 50),

              /// --- 6. FOOTER (HELP, GLOBAL, INFO) ---
              _buildFooter(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: TextStyle(color: navyDark, fontWeight: FontWeight.w600));
  }

  Widget _buildShadowedInput({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscure = false,
    IconData? suffix,
    VoidCallback? onSuffixPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), // Shadow samar
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        // INI YANG BARU:
        keyboardType: icon == Icons.email_outlined 
            ? TextInputType.emailAddress 
            : (icon == Icons.phone_outlined ? TextInputType.phone : TextInputType.text),
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: textGrey.withOpacity(0.6)),
          prefixIcon: Icon(icon, color: textGrey),
          // Ikon Mata dengan Toggle (View/Hide)
          suffixIcon: suffix != null
              ? IconButton(
                  icon: Icon(suffix, color: textGrey),
                  onPressed: onSuffixPressed,
                )
              : null,
          filled: true,
          fillColor: Colors.transparent, // Warna sudah di Container
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildDaftarButton(BuildContext context) {
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
        onPressed: () async {
          if (!_validateInputs()) return;

          try {
            UserCredential userCredential =
                await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim(),
            );

            User? user = userCredential.user;

            if (user != null) {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .set({
                'uid': user.uid,
                'fullName': fullNameController.text.trim(),
                'email': emailController.text.trim(),
                'phone': phoneController.text.trim(),
                'createdAt': FieldValue.serverTimestamp(),
              });
            }

            _showSnackBar("Registrasi berhasil");

            Navigator.pop(context);
          } on FirebaseAuthException catch (e) {
            // Print tetap ada buat kamu cek di terminal VS Code
            print("REGISTER ERROR CODE: ${e.code}"); 
            
            String pesanUser;
            
            // Mapping error code ke bahasa Indonesia yang ramah
            switch (e.code) {
              case 'email-already-in-use':
                pesanUser = "Email sudah terdaftar. Yuk, langsung login aja!";
                break;
              case 'weak-password':
                pesanUser = "Wah, password-mu terlalu lemah. Coba kombinasi lain ya.";
                break;
              case 'network-request-failed':
                pesanUser = "Cek koneksi internetmu dulu ya.";
                break;
              default:
                pesanUser = "Ups! Terjadi kesalahan: ${e.message}";
            }

            // Panggil snackbar (otomatis merah karena tidak isi parameter color)
            _showSnackBar(pesanUser);
          }
        },
        child: const Text(
          "Daftar Sekarang",
          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // --- Widget Footer di bagian bawah ---
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
}