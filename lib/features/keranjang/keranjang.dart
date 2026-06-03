import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'cart_manager.dart';
import '../booking/screens/form_booking.dart';
import '../../../../routes/app_routes.dart';

class KeranjangPage extends StatefulWidget {
  const KeranjangPage({super.key});

  @override
  State<KeranjangPage> createState() => _KeranjangPageState();
}

class _KeranjangPageState extends State<KeranjangPage> {
  static const Color _primaryBlue = Color(0xFF0B4E89);
  static const Color _green       = Color(0xFF1A8C6A);
  static const Color _bgColor     = Color(0xFFF5F6FA);
  static const Color _red         = Color(0xFFE53935);

  String _formatCurrency(int amount) => NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);

  String _formatTanggal(DateTime dt) =>
      DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(dt);

  @override
  Widget build(BuildContext context) {
    return PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) {
    if (didPop) return;
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context, AppRoutes.home, (route) => false);
    }
  },
  child: Scaffold(
    backgroundColor: _bgColor,
    appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _primaryBlue, size: 20),
          onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushNamedAndRemoveUntil(
              context, AppRoutes.home, (route) => false);
          }
        },
        ),
        title: ValueListenableBuilder<List<KeranjangItem>>(
          valueListenable: CartManager.instance.itemsNotifier,
          builder: (_, items, __) => Text(
            'Keranjang (${CartManager.instance.totalSlot} slot)',
            style: const TextStyle(
                color: _primaryBlue,
                fontWeight: FontWeight.w700,
                fontSize: 18),
          ),
        ),
        actions: [
          ValueListenableBuilder<List<KeranjangItem>>(
            valueListenable: CartManager.instance.itemsNotifier,
            builder: (_, items, __) {
              if (items.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: _konfirmasiHapusSemua,
                child: const Text('Hapus Semua',
                    style: TextStyle(
                        color: _red,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<List<KeranjangItem>>(
        valueListenable: CartManager.instance.itemsNotifier,
        builder: (_, items, __) {
          if (items.isEmpty) return _buildEmptyState();

          return Column(
            children: [
              // ── List item keranjang ──────────────────────────
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _buildKartuItem(items[i]),
                ),
              ),

              // ── Bottom bar ───────────────────────────────────
              _buildBottomBar(items),
            ],
          );
        },
      ),
  ),
    );
  }

  // ── Kartu item ──────────────────────────────────────────────
  Widget _buildKartuItem(KeranjangItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header lapangan
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: item.fotoUrl.isNotEmpty
                      ? Image.network(item.fotoUrl,
                          width: 56, height: 56, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder())
                      : _placeholder(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.namaLapangan,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: const Color(0xFF1A1A2E))),
                      Text(
                          '${item.jenisLapangan} • ${item.jenisFloor}',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade500)),
                      const SizedBox(height: 2),
                      Text(_formatTanggal(item.selectedDate),
                          style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              color: _primaryBlue,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                // Hapus item
                IconButton(
                  onPressed: () => _hapusItem(item),
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: _red, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          // Slot yang dipilih
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Slot yang dipilih:',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: item.selectedTimes.map((slot) {
                    return GestureDetector(
                      onTap: () => _hapusSlot(item, slot),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: _green.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(slot,
                                style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: _green)),
                            const SizedBox(width: 5),
                            Icon(Icons.close_rounded,
                                size: 13,
                                color: _green.withOpacity(0.7)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          // Subtotal + tombol checkout item ini
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${item.selectedTimes.length} slot × ${_formatCurrency(item.pricePerHour)}',
                        style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: Colors.grey.shade500)),
                    Text(_formatCurrency(item.subtotal),
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _primaryBlue)),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => _checkoutItem(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('Checkout',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom bar ──────────────────────────────────────────────
  Widget _buildBottomBar(List<KeranjangItem> items) {
    final total = CartManager.instance.totalHarga;

    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 14, 16, MediaQuery.of(context).padding.bottom + 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x14000000),
              blurRadius: 12,
              offset: Offset(0, -4))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ringkasan total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total (${CartManager.instance.totalSlot} slot):',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey.shade600)),
              Text(_formatCurrency(total),
                  style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _primaryBlue)),
            ],
          ),
          const SizedBox(height: 12),
          // Tombol Checkout Sekarang
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final cartItems = List<KeranjangItem>.from(items);
                CartManager.instance.clear();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FormBookingPage(
                      bookingItems: cartItems,
                      serviceFee: 5000,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Checkout Sekarang',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
          const SizedBox(height: 10),
          // Tombol tambah lapangan lain
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Kembali ke home → tab Cari (index 1)
                Navigator.of(context).popUntil(
                  (route) => route.isFirst,
                );
                // Setelah pop ke home, trigger switch tab ke Cari
                // Menggunakan global key atau callback jika diperlukan
                // Untuk sekarang cukup pop ke home screen
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('Tambah Lapangan Lain',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryBlue,
                side: const BorderSide(color: _primaryBlue, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ─────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Keranjang kosong',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade400)),
          const SizedBox(height: 8),
          Text('Pilih lapangan dan slot waktu terlebih dahulu',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey.shade400)),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.search_rounded, size: 18),
            label: Text('Cari Lapangan',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions ─────────────────────────────────────────────────

  void _checkoutItem(KeranjangItem item) {
    // Hapus item dari keranjang dulu, lalu ke FormBooking
    CartManager.instance.hapus(item.key);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormBookingPage(
          bookingItems:  [item],
          serviceFee:    5000,
        ),
      ),
    );
  }

  void _hapusItem(KeranjangItem item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Hapus item?',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text(
            'Hapus ${item.namaLapangan} dari keranjang?',
            style: const TextStyle(fontSize: 13, color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              CartManager.instance.hapus(item.key);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _red, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _hapusSlot(KeranjangItem item, String slot) {
    final updated =
        item.selectedTimes.where((s) => s != slot).toList();
    CartManager.instance.updateSlot(item.key, updated);
  }

  void _konfirmasiHapusSemua() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Kosongkan keranjang?',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: const Text('Semua item akan dihapus dari keranjang.',
            style: TextStyle(fontSize: 13, color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              CartManager.instance.clear();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _red, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
            color: const Color(0xFFE3EAF5),
            borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.sports_soccer_rounded,
            color: Color(0xFF1B4E82), size: 24),
      );
}