// lib/data/model/lapangan_model.dart

class LapanganModel {
  final String id;
  final String namaLapangan;
  final String nama; // fasilitas tambahan, e.g. "Kamar Mandi"
  final String jenisLapangan;
  final String jenisFloor;
  final String lokasi;
  final int harga;
  final int kapasitas;
  final double rating;
  final String mapsUrl;
  final String iconUrl;
  final List<String> foto;

  const LapanganModel({
    required this.id,
    required this.namaLapangan,
    required this.nama,
    required this.jenisLapangan,
    required this.jenisFloor,
    required this.lokasi,
    required this.harga,
    required this.kapasitas,
    required this.rating,
    required this.mapsUrl,
    required this.iconUrl,
    required this.foto,
  });

  factory LapanganModel.fromFirestore(Map<String, dynamic> data, String id) {
    return LapanganModel(
      id: id,
      namaLapangan: data['nama_lapangan'] ?? '',
      nama: data['nama'] ?? '',
      jenisLapangan: data['jenis_lapangan'] ?? '',
      jenisFloor: data['jenis_floor'] ?? '',
      lokasi: data['lokasi'] ?? '',
      harga: (data['harga'] as num?)?.toInt() ?? 0,
      kapasitas: (data['kapasitas'] as num?)?.toInt() ?? 0,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      mapsUrl: data['maps_url'] ?? '',
      iconUrl: data['icon_url'] ?? '',
      foto: List<String>.from(data['foto'] ?? []),
    );
  }

  bool isFullOnDate(DateTime date) => false;
}