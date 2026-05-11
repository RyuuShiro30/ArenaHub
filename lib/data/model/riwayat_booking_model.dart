enum BookingStatus { aktif, selesai, dibatalkan }

class RiwayatBookingModel {
  final String bookingId;
  final String namaLapangan;
  final String kategori;
  final String tanggal;
  final String waktu;
  final int totalPembayaran;
  final BookingStatus status;
  final String imagePath;

  /// Only used when status == aktif
  final Duration? sisaWaktu;

  const RiwayatBookingModel({
    required this.bookingId,
    required this.namaLapangan,
    required this.kategori,
    required this.tanggal,
    required this.waktu,
    required this.totalPembayaran,
    required this.status,
    required this.imagePath,
    this.sisaWaktu,
  });
}