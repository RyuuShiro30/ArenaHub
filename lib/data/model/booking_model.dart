import 'package:flutter/material.dart';

/// Data lapangan + jadwal yang dikirim dari halaman Pilih Jadwal
class BookingData {
  final String namaLapangan;
  final String imagePath;
  final DateTime tanggal;
  final TimeOfDay jamMulai;
  final TimeOfDay jamSelesai;
  final int hargaPerJam;      

  const BookingData({
    required this.namaLapangan,
    required this.imagePath,
    required this.tanggal,
    required this.jamMulai,
    required this.jamSelesai,
    required this.hargaPerJam,
  });

  int get durasiJam {
    final mulai = jamMulai.hour * 60 + jamMulai.minute;
    final selesai = jamSelesai.hour * 60 + jamSelesai.minute;
    return ((selesai - mulai) / 60).round();
  }

  String get waktuDisplay {
    String fmt(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return '${fmt(jamMulai)} - ${fmt(jamSelesai)} ($durasiJam Jam)';
  }

  String get tanggalDisplay {
    const bulan = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${tanggal.day} ${bulan[tanggal.month]} ${tanggal.year}';
  }
}

class PromoData {
  final String kode;
  final String deskripsi;
  final int diskon;

  const PromoData({
    required this.kode,
    required this.deskripsi,
    required this.diskon,
  });
}

/// TODO: Ganti dengan fetch dari API/Supabase saat backend sudah siap.
const List<PromoData> daftarPromo = [
  PromoData(kode: 'ARENAJAGO', deskripsi: 'Diskon member baru', diskon: 25000),
  PromoData(kode: 'WEEKEND10', deskripsi: 'Promo akhir pekan', diskon: 15000),
];