class LapanganModel {
  final String kategori;
  final String nama;
  final String lokasi;
  final double jarak;
  final int hargaPerJam;
  final int? minOrang;
  final int? maxOrang;
  final bool adaKamarMandi;
  final bool adaParkir;
  final List<String> slotTersedia;
  final int slotTambahan;
  final String imagePath;
  final Map<String, List<String>> bookedSlots;

  const LapanganModel({
    required this.kategori,
    required this.nama,
    required this.lokasi,
    required this.jarak,
    required this.hargaPerJam,
    this.minOrang,
    this.maxOrang,
    this.adaKamarMandi = false,
    this.adaParkir = false,
    required this.slotTersedia,
    this.slotTambahan = 0,
    required this.imagePath,
    this.bookedSlots = const {},
  });

  /// Returns list of booked time slots for the given date.
  List<String> bookedSlotsForDate(DateTime date) {
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return bookedSlots[key] ?? [];
  }

  /// Returns true if ALL available slots are booked on the given date.
  bool isFullOnDate(DateTime date) {
    final booked = bookedSlotsForDate(date);
    return slotTersedia.every((s) => booked.contains(s));
  }
}