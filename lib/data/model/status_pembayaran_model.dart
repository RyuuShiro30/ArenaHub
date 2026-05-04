class StatusPembayaranModel {
  final String nomorBooking;
  final String namaLapangan;
  final String jadwalHari;
  final String jadwalTanggal;
  final String jadwalWaktu;
  final String durasiJam;
  final String metodePembayaran;
  final int totalPembayaran;
  final bool isPaid;
 
  const StatusPembayaranModel({
    required this.nomorBooking,
    required this.namaLapangan,
    required this.jadwalHari,
    required this.jadwalTanggal,
    required this.jadwalWaktu,
    required this.durasiJam,
    required this.metodePembayaran,
    required this.totalPembayaran,
    this.isPaid = true,
  });
}