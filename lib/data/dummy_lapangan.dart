import 'model/lapangan_model.dart';

final List<LapanganModel> dummyLapangan = [
  LapanganModel(
    kategori: 'FUTSAL',
    nama: 'Lapangan Futsal – A',
    lokasi: 'Kota Malang',
    jarak: 1.2,
    hargaPerJam: 150000,
    minOrang: 10,
    maxOrang: 12,
    adaKamarMandi: true,
    adaParkir: true,
    slotTersedia: ['16:00', '17:00', '20:00'],
    slotTambahan: 2,
    imagePath:
        'https://images.unsplash.com/photo-1577223625816-7546f13df25d?w=600',
    bookedSlots: {
      '2025-07-15': ['16:00', '17:00'],
      '2025-07-16': ['16:00', '17:00', '20:00'], // penuh
      '2025-07-20': ['20:00'],
    },
  ),
  LapanganModel(
    kategori: 'BADMINTON',
    nama: 'Gedung Olahraga Smash',
    lokasi: 'Kota Malang',
    jarak: 1.2,
    hargaPerJam: 65000,
    minOrang: 2,
    maxOrang: 4,
    adaKamarMandi: false,
    adaParkir: false,
    slotTersedia: ['19:00', '21:00'],
    slotTambahan: 0,
    imagePath:
        'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=600',
    bookedSlots: {
      '2025-07-15': ['19:00'],
      '2025-07-18': ['19:00', '21:00'], // penuh
    },
  ),
  LapanganModel(
    kategori: 'BASKET',
    nama: 'Lapangan Basket GOR',
    lokasi: 'Kota Malang',
    jarak: 2.0,
    hargaPerJam: 100000,
    minOrang: 8,
    maxOrang: 10,
    adaKamarMandi: true,
    adaParkir: true,
    slotTersedia: ['07:00', '09:00', '15:00'],
    slotTambahan: 1,
    imagePath:
        'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=600',
    bookedSlots: {
      '2025-07-15': ['07:00'],
      '2025-07-17': ['07:00', '09:00', '15:00'], // penuh
    },
  ),
];