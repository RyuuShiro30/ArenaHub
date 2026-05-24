import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // ── Schedule notif dari data Firestore ────────────────────────────────────
  // Dipanggil saat user aktifkan toggle notifikasi
  Future<void> scheduleAllBookingReminders() async {
    try {
      // Batalkan semua notif lama dulu
      await _plugin.cancelAll();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Ambil email user
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final email = userDoc.data()?['email'] ?? user.email ?? '';

      if (email.isEmpty) return;

      // Ambil semua booking user yang akan datang
      final now = DateTime.now();
      final todayStr = '${now.year}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';

      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('email', isEqualTo: email)
          .where('status_pembayaran', whereIn: [
            'sudah dibayar',
            'pembayaran selesai',
            'selesai',
            'pending',
          ])
          .get();

      int notifId = 1000; // mulai dari ID 1000

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final tanggalMain = data['tanggal_main']?.toString() ?? '';
        final jamMain = data['jam_main']?.toString() ?? '';
        final namaLapangan =
            data['nama_lapangan']?.toString() ?? 'Lapangan';

        // Skip kalau tanggal sudah lewat
        if (tanggalMain.isEmpty || tanggalMain.compareTo(todayStr) < 0) {
          continue;
        }

        await _scheduleReminder(
          id: notifId++,
          namaLapangan: namaLapangan,
          tanggalMain: tanggalMain,
          jamMain: jamMain,
        );
      }

      print('✅ Semua notif booking berhasil dijadwalkan');
    } catch (e) {
      print('❌ Error scheduleAllBookingReminders: $e');
    }
  }

  // ── Schedule 1 notif ──────────────────────────────────────────────────────
  Future<void> _scheduleReminder({
    required int id,
    required String namaLapangan,
    required String tanggalMain, // "2026-05-23"
    required String jamMain, // "08.00 - 09.00" atau "08.00 - 09.00, 09.00 - 10.00"
  }) async {
    try {
      // Ambil jam pertama
      final firstSlot = jamMain.split(',').first.trim();
      final jamStr = firstSlot.split(' - ').first.trim(); // "08.00"
      final jamParts = jamStr.replaceAll('.', ':').split(':');

      if (jamParts.length < 2) return;

      final hour = int.tryParse(jamParts[0]) ?? 0;
      final minute = int.tryParse(jamParts[1]) ?? 0;

      final dateParts = tanggalMain.split('-');
      if (dateParts.length < 3) return;

      final year = int.tryParse(dateParts[0]) ?? 0;
      final month = int.tryParse(dateParts[1]) ?? 0;
      final day = int.tryParse(dateParts[2]) ?? 0;

      // Waktu main
      final waktuMain = tz.TZDateTime(
        tz.getLocation('Asia/Jakarta'),
        year,
        month,
        day,
        hour,
        minute,
      );

      // Notif 2 jam sebelum main
      final waktuNotif = waktuMain.subtract(const Duration(hours: 2));

      // Skip kalau sudah lewat
      if (waktuNotif.isBefore(tz.TZDateTime.now(tz.local))) return;

      const androidDetails = AndroidNotificationDetails(
        'booking_reminder',
        'Pengingat Booking',
        channelDescription: 'Notifikasi pengingat 2 jam sebelum main',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      await _plugin.zonedSchedule(
        id,
        '⏰ Pengingat Booking ArenaHub',
        '$namaLapangan mulai dalam 2 jam! Jangan sampai telat ya 🏃',
        waktuNotif,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      print('✅ Notif dijadwalkan: $waktuNotif → $namaLapangan');
    } catch (e) {
      print('❌ Error _scheduleReminder: $e');
    }
  }

  // ── Batalkan semua notif (saat toggle OFF) ────────────────────────────────
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    print('🔕 Semua notif dibatalkan');
  }
}
