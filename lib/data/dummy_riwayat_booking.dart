import 'model/riwayat_booking_model.dart';

final List<RiwayatBookingModel> dummyRiwayatBooking = [
  RiwayatBookingModel(
    bookingId: 'AH-9821',
    namaLapangan: 'Lapangan Futsal A',
    kategori: 'FUTSAL',
    tanggal: '24 Maret 2026',
    waktu: '19:00 - 20:00',
    totalPembayaran: 130000,
    status: BookingStatus.aktif,
    imagePath:
        'https://images.unsplash.com/photo-1577223625816-7546f13df25d?w=600',
    sisaWaktu: const Duration(hours: 2, minutes: 15, seconds: 0),
  ),
  RiwayatBookingModel(
    bookingId: 'AH-8712',
    namaLapangan: 'lapangan Basket A',
    kategori: 'BASKETBALL',
    tanggal: '15 Maret 2026',
    waktu: '16:00 - 18:00',
    totalPembayaran: 240000,
    status: BookingStatus.selesai,
    imagePath:
        'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=600',
  ),
  RiwayatBookingModel(
    bookingId: 'AH-7611',
    namaLapangan: 'Lapangan Bulutangkis A',
    kategori: 'BADMINTON',
    tanggal: '12 Maret 2026',
    waktu: '20:00 - 21:00',
    totalPembayaran: 80000,
    status: BookingStatus.dibatalkan,
    imagePath:
        'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=600',
  ),
];
