import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Pastikan import ini sesuai dengan nama project di pubspec.yaml kamu
import 'package:appbookinglapangan/main.dart'; 

void main() {
  testWidgets('ArenaHub Login Screen UI Test', (WidgetTester tester) async {
    // 1. Build aplikasi kita. 
    // Hapus 'const' jika MyApp() memunculkan eror merah di bawahnya.
    await tester.pumpWidget(const MyApp()); 

    // 2. Karena sekarang kita punya halaman Login, mari kita cek 
    // apakah teks "Selamat Datang Kembali!" muncul di layar.
    expect(find.text('Selamat Datang Kembali!'), findsOneWidget);

    // 3. Cek apakah tombol "Masuk" ada.
    expect(find.text('Masuk'), findsOneWidget);

    // 4. Cek keberadaan field input (Opsional)
    expect(find.byIcon(Icons.email_outlined), findsOneWidget);
  });
}