import 'package:cloud_firestore/cloud_firestore.dart';
class BookingData {
  final String lapanganId;
  final String namaLapangan;
  final String imagePath;
  final DateTime tanggal;
  final List<String> selectedTimes;
  final int hargaPerJam;
  final int biayaLayanan;

  const BookingData({
    required this.lapanganId,
    required this.namaLapangan,
    required this.imagePath,
    required this.tanggal,
    required this.selectedTimes,
    required this.hargaPerJam,
    required this.biayaLayanan,
  });

  int get durasiJam => selectedTimes.length;

  int get subtotal => hargaPerJam * durasiJam;

  String get tanggalDisplay {
    const bulan = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${tanggal.day} ${bulan[tanggal.month]} ${tanggal.year}';
  }

  String get waktuDisplay {
    if (selectedTimes.isEmpty) return '-';
    
    final jamMulai = selectedTimes.first.split(' - ').first;
    final jamSelesai = selectedTimes.last.split(' - ').last;
    
    return '$jamMulai s/d $jamSelesai ($durasiJam Jam)';
  }
}

class PromoData {
  final String kode;
  final String deskripsi;
  final int diskon;

  final bool isActive;
  final DateTime expiredAt;
  final int minTransaksi;
  final int kuota;

  PromoData({
    required this.kode,
    required this.deskripsi,
    required this.diskon,
    required this.isActive,
    required this.expiredAt,
    required this.minTransaksi,
    required this.kuota,
  });

  factory PromoData.fromFirestore(Map<String, dynamic> map) {
    return PromoData(
      kode: map['kode'] ?? '',
      deskripsi: map['deskripsi'] ?? '',
      diskon: map['diskon'] ?? 0,

      isActive: map['aktif'] ?? false,

      expiredAt:
          (map['expiredAt'] as Timestamp).toDate(),

      minTransaksi: map['minimalTransaksi'] ?? 0,
      kuota: map['kuota'] ?? 0,
    );
  }
}