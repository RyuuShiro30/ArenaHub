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
  });
}