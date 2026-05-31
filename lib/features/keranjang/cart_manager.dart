import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════════════════
// MODEL ITEM KERANJANG
// ══════════════════════════════════════════════════════════════════════════════

class KeranjangItem {
  final String lapanganId;
  final String namaLapangan;
  final String jenisLapangan;
  final String jenisFloor;
  final String fotoUrl;
  final int pricePerHour;
  final DateTime selectedDate;
  final List<String> selectedTimes;

  KeranjangItem({
    required this.lapanganId,
    required this.namaLapangan,
    required this.jenisLapangan,
    required this.jenisFloor,
    required this.fotoUrl,
    required this.pricePerHour,
    required this.selectedDate,
    required this.selectedTimes,
  });

  int get subtotal => pricePerHour * selectedTimes.length;

  // Key unik: lapanganId + tanggal — untuk merge slot lapangan yang sama di hari yang sama
  String get key =>
      '${lapanganId}_${selectedDate.year}${selectedDate.month.toString().padLeft(2, '0')}${selectedDate.day.toString().padLeft(2, '0')}';

  KeranjangItem copyWith({List<String>? selectedTimes}) {
    return KeranjangItem(
      lapanganId:    lapanganId,
      namaLapangan:  namaLapangan,
      jenisLapangan: jenisLapangan,
      jenisFloor:    jenisFloor,
      fotoUrl:       fotoUrl,
      pricePerHour:  pricePerHour,
      selectedDate:  selectedDate,
      selectedTimes: selectedTimes ?? this.selectedTimes,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CART MANAGER — Singleton global, persist selama sesi
// ══════════════════════════════════════════════════════════════════════════════

class CartManager {
  CartManager._();
  static final CartManager instance = CartManager._();

  // Notifier agar UI bisa listen perubahan
  final ValueNotifier<List<KeranjangItem>> itemsNotifier =
      ValueNotifier<List<KeranjangItem>>([]);

  List<KeranjangItem> get items => itemsNotifier.value;
  int get totalItems => items.length;
  int get totalSlot => items.fold(0, (sum, i) => sum + i.selectedTimes.length);
  int get totalHarga => items.fold(0, (sum, i) => sum + i.subtotal);

  // Tambah / merge item ke keranjang
  // Kalau lapangan + tanggal yang sama sudah ada → merge slot-nya
  void tambah(KeranjangItem newItem) {
    final current = List<KeranjangItem>.from(items);
    final idx = current.indexWhere((i) => i.key == newItem.key);

    if (idx >= 0) {
      // Merge: gabung selectedTimes, hindari duplikat
      final merged = {
        ...current[idx].selectedTimes,
        ...newItem.selectedTimes,
      }.toList();
      current[idx] = current[idx].copyWith(selectedTimes: merged);
    } else {
      current.add(newItem);
    }

    itemsNotifier.value = current;
  }

  // Hapus satu item dari keranjang
  void hapus(String key) {
    itemsNotifier.value =
        items.where((i) => i.key != key).toList();
  }

  // Update slot untuk item tertentu (misal user hapus 1 slot dari keranjang)
  void updateSlot(String key, List<String> newSlots) {
    final current = List<KeranjangItem>.from(items);
    final idx = current.indexWhere((i) => i.key == key);
    if (idx < 0) return;

    if (newSlots.isEmpty) {
      current.removeAt(idx);
    } else {
      current[idx] = current[idx].copyWith(selectedTimes: newSlots);
    }
    itemsNotifier.value = current;
  }

  // Kosongkan semua
  void clear() => itemsNotifier.value = [];
}