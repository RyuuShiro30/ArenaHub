import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'konfirmasi_booking.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/model/booking_model.dart';
import '../../keranjang/cart_manager.dart';
import 'promo.dart';

class FormBookingPage extends StatefulWidget {
  final List<KeranjangItem> bookingItems;
  final int serviceFee;

  const FormBookingPage({
    super.key,
    required this.bookingItems,
    required this.serviceFee,
  });

  @override
  State<FormBookingPage> createState() => _FormBookingPageState();
}

class _FormBookingPageState extends State<FormBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _teleponController = TextEditingController();
  final _catatanController = TextEditingController();
  final _promoController = TextEditingController();

  // ── data user login ──
  String _namaUser = '';
  String _teleponUser = '';
  String _emailUser = '';
  bool _isLoadingUser = true;
  bool _addAsPemesan = true; // toggle default ON

  PromoData? _promoAktif;
  String? _promoError;
  bool _isLoading = false;

  static const Color _primaryColor = Color(0xFF135B9D);
  static const Color _accentColor = Color(0xFF2196F3);
  static const Color _successColor = Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _teleponController.dispose();
    _catatanController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  // ── fetch data user dari Firestore ──

  Future<void> _fetchUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() => _isLoadingUser = false);
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        final map = doc.data()!;
        setState(() {
          _namaUser = map['fullName'] ?? map['nama'] ?? map['name'] ?? '';
          _teleponUser = map['phone'] ?? map['telepon'] ?? '';
          _emailUser = map['email'] ??
              FirebaseAuth.instance.currentUser?.email ?? '';
          _isLoadingUser = false;
        });

        // auto-isi form karena toggle default ON
        _applyUserToForm();
      } else {
        setState(() {
          _emailUser =
              FirebaseAuth.instance.currentUser?.email ?? '';
          _isLoadingUser = false;
        });
      }
    } catch (_) {
      setState(() => _isLoadingUser = false);
    }
  }

  // ── terapkan / hapus data user ke form ──

  void _applyUserToForm() {
    _namaController.text = _namaUser;
    _teleponController.text = _teleponUser;
  }

  void _clearForm() {
    _namaController.clear();
    _teleponController.clear();
  }

  void _onToggleAddAsPemesan(bool val) {
    setState(() => _addAsPemesan = val);
    if (val) {
      _applyUserToForm();
    } else {
      _clearForm();
    }
  }

  // ── kalkulasi harga ──

  int get _subtotal => widget.bookingItems.fold(0, (total, item) => total + item.subtotal);
  int get _diskon => _promoAktif?.diskon ?? 0;
  int get _total => _subtotal + widget.serviceFee - _diskon;

  String _getNamaBulan(int month) {
    const bulan = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return bulan[month];
  }

  String _formatRupiah(int nominal) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'IDR ',
      decimalDigits: 0,
    ).format(nominal);
  }

  // ── promo logic ──

  Future<void> _terapkanPromo() async {
    final kode = _promoController.text.trim().toUpperCase();
    if (kode.isEmpty) {
      setState(() {
        _promoError = 'Masukkan kode promo terlebih dahulu';
        _promoAktif = null;
      });
      return;
    }
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('promos')
          .where('kode', isEqualTo: kode)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() { _promoAktif = null; _promoError = 'Kode promo tidak valid'; });
        return;
      }
      final promo = PromoData.fromFirestore(snapshot.docs.first.data());
      if (!promo.isActive) {
        setState(() { _promoAktif = null; _promoError = 'Promo sedang tidak aktif'; });
        return;
      }
      if (promo.expiredAt.isBefore(DateTime.now())) {
        setState(() { _promoAktif = null; _promoError = 'Promo sudah expired'; });
        return;
      }
      if (_subtotal < promo.minTransaksi) {
        setState(() {
          _promoAktif = null;
          _promoError = 'Minimal transaksi ${_formatRupiah(promo.minTransaksi)}';
        });
        return;
      }
      if (promo.kuota <= 0) {
        setState(() { _promoAktif = null; _promoError = 'Kuota promo habis'; });
        return;
      }
      setState(() { _promoAktif = promo; _promoError = null; });
    } catch (_) {
      setState(() { _promoAktif = null; _promoError = 'Terjadi kesalahan'; });
    }
  }

  void _hapusPromo() {
    setState(() {
      _promoController.clear();
      _promoAktif = null;
      _promoError = null;
    });
  }

  // ── submit ──

  Future<void> _konfirmasiBooking() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final String nama = _addAsPemesan ? _namaUser : _namaController.text.trim();
    final String telepon = _addAsPemesan ? _teleponUser : _teleponController.text.trim();

    if (nama.isEmpty || telepon.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data profil Anda belum lengkap. Silakan matikan toggle "Tambahkan sebagai pemesan" untuk mengisi data manual.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KonfirmasiBookingPage(
          data: KonfirmasiData(
            bookingItems: widget.bookingItems,
            biayaLayanan: widget.serviceFee,
            namaPemesan: nama,
            nomorTelepon: telepon,
            catatan: _catatanController.text.trim(),
            promo: _promoAktif,
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: _buildDaftarLapangan()),
            SliverToBoxAdapter(child: _buildSeksiOrderDetail()),
            SliverToBoxAdapter(child: _buildSeksiDataPemesan()),
            SliverToBoxAdapter(child: _buildSeksiPromo()),
            SliverToBoxAdapter(child: _buildSeksiRincianHarga()),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      bottomNavigationBar: _buildTombolKonfirmasi(),
    );
  }

  // ── app bar ──

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: _primaryColor, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Detail Booking',
        style: TextStyle(
            color: _primaryColor, fontWeight: FontWeight.w900, fontSize: 18),
      ),
      centerTitle: false,
    );
  }

  // ── daftar lapangan ──

  Widget _buildDaftarLapangan() {
    return Column(
      children: widget.bookingItems.map((item) {
        final tanggalDisplay = '${item.selectedDate.day} ${_getNamaBulan(item.selectedDate.month)} ${item.selectedDate.year}';
        final jamMulai = item.selectedTimes.first.split(' - ').first;
        final jamSelesai = item.selectedTimes.last.split(' - ').last;
        final waktuDisplay = '$jamMulai s/d $jamSelesai (${item.selectedTimes.length} Jam)';

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: item.fotoUrl.isNotEmpty
                      ? Image.network(
                          item.fotoUrl,
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const _PlaceholderGambarMini(),
                        )
                      : const _PlaceholderGambarMini(),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.namaLapangan,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 13, color: _primaryColor),
                          const SizedBox(width: 6),
                          Text(tanggalDisplay, style: const TextStyle(fontSize: 12.5, color: Color(0xFF555555))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 13, color: _primaryColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(waktuDisplay, style: const TextStyle(fontSize: 12.5, color: Color(0xFF555555))),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── ORDER DETAIL ──

  Widget _buildSeksiOrderDetail() {
    return _Kartu(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SeksiJudul('Order Detail'),
          const SizedBox(height: 14),
          if (_isLoadingUser)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else ...[
            _OrderDetailRow(
              icon: Icons.person_outline_rounded,
              label: 'Nama',
              value: _namaUser.isNotEmpty ? _namaUser : '-',
            ),
            const SizedBox(height: 8),
            _OrderDetailRow(
              icon: Icons.phone_outlined,
              label: 'Telepon',
              value: _teleponUser.isNotEmpty ? _teleponUser : '-',
            ),
            const SizedBox(height: 8),
            _OrderDetailRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: _emailUser.isNotEmpty ? _emailUser : '-',
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFEEEEEE)),
            ),
            // toggle
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tambahkan sebagai pemesan',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Data kamu akan otomatis diisi ke form',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _addAsPemesan,
                  onChanged: _onToggleAddAsPemesan,
                  activeColor: _primaryColor,
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14, color: _primaryColor),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Konfirmasi booking akan dikirim ke email di atas.',
                    style: TextStyle(fontSize: 12, color: _primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── data pemesan ──

  Widget _buildSeksiDataPemesan() {
    return _Kartu(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SeksiJudul('Data Pemesan'),
              const Spacer(),
              if (!_addAsPemesan)
                GestureDetector(
                  onTap: () {
                    setState(() => _addAsPemesan = true);
                    _applyUserToForm();
                  },
                  child: const Text(
                    'Pakai data saya',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _primaryColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (!_addAsPemesan) ...[
            _InputField(
              label: 'Nama Lengkap',
              hint: 'Masukkan nama',
              controller: _namaController,
              validator: (v) {
                if (_addAsPemesan) return null;
                return (v == null || v.trim().isEmpty)
                    ? 'Nama tidak boleh kosong'
                    : null;
              },
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
              ],
            ),
            const SizedBox(height: 14),
            _InputField(
              label: 'Nomor Telepon',
              hint: 'Contoh: 08123456789',
              controller: _teleponController,
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (_addAsPemesan) return null;
                if (v == null || v.trim().isEmpty) {
                  return 'Nomor telepon tidak boleh kosong';
                }
                if (v.trim().length < 10) {
                  return 'Nomor telepon minimal 10 digit';
                }
                return null;
              },
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 14),
          ],
          _InputField(
            label: 'Catatan (Opsional)',
            hint: 'Contoh: Tolong siapkan rompi tambahan',
            controller: _catatanController,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  // ── promo ──

  Widget _buildSeksiPromo() {
    return _Kartu(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4E82).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.confirmation_number_outlined,
                    color: _primaryColor, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('Kode Promo',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF1A1A2E))),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const PromoPage())),
                child: const Text('Lihat Promo',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _primaryColor,
                        decoration: TextDecoration.underline)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _promoController,
                  textCapitalization: TextCapitalization.characters,
                  enabled: _promoAktif == null,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                     hintText: 'Punya kode promo?',
                    hintStyle:
                        TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    filled: true,
                    fillColor: _promoAktif != null
                        ? const Color(0xFFF0F0F0)
                        : const Color(0xFFF5F7FA),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: _accentColor, width: 1.5)),
                    errorText: _promoError,
                    errorStyle: const TextStyle(fontSize: 12),
                    suffixIcon: _promoAktif != null
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: Colors.grey, size: 18),
                            onPressed: _hapusPromo,
                          )
                        : null,
                  ),
                  onChanged: (_) {
                    if (_promoError != null) setState(() => _promoError = null);
                  },
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed:
                      _promoAktif == null ? _terapkanPromo : _hapusPromo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _promoAktif == null
                        ? _primaryColor
                        : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: Text(
                    _promoAktif == null ? 'TERAPKAN' : 'HAPUS',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
          if (_promoAktif != null) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _successColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: _successColor.withOpacity(0.3), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: _successColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_promoAktif!.deskripsi} Hemat ${_formatRupiah(_promoAktif!.diskon)}',
                      style: const TextStyle(
                          color: _successColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── rincian harga ──

  Widget _buildSeksiRincianHarga() {
    return _Kartu(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SeksiJudul('Rincian Harga'),
          const SizedBox(height: 16),
          ...widget.bookingItems.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _BarisPricing(
                label: '${item.namaLapangan} (${item.selectedTimes.length} Jam)',
                nilai: _formatRupiah(item.subtotal),
              ),
            );
          }),
          const SizedBox(height: 8),
          _BarisPricing(
              label: 'Biaya Layanan', nilai: _formatRupiah(widget.serviceFee)),
          if (_diskon > 0) ...[
            const SizedBox(height: 8),
            _BarisPricing(
              label: 'Diskon (${_promoAktif!.kode})',
              nilai: '- ${_formatRupiah(_diskon)}',
              warnaNilai: _successColor,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFEEEEEE)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Pembayaran',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF1A1A2E))),
              Text(_formatRupiah(_total),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: _primaryColor)),
            ],
          ),
        ],
      ),
    );
  }

  // ── tombol konfirmasi ──

  Widget _buildTombolKonfirmasi() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -4))
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _konfirmasiBooking,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _primaryColor.withOpacity(0.6),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : const Text('Konfirmasi Booking',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════
// WIDGETS
// ══════════════════════════════════════

class _OrderDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _OrderDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1B4E82)),
        const SizedBox(width: 10),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF666666)),
          ),
        ),
        const Text(' : ',
            style: TextStyle(fontSize: 13.5, color: Color(0xFF666666))),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ),
      ],
    );
  }
}

class _Kartu extends StatelessWidget {
  final Widget child;
  final EdgeInsets margin;
  const _Kartu({required this.child, required this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SeksiJudul extends StatelessWidget {
  final String text;
  const _SeksiJudul(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E)));
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  const _InputField({
    required this.label,
    required this.hint,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333))),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          inputFormatters: inputFormatters,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF5F7FA),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFF2196F3), width: 1.5)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFFE53935), width: 1.5)),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFFE53935), width: 1.5)),
          ),
        ),
      ],
    );
  }
}

class _BarisPricing extends StatelessWidget {
  final String label;
  final String nilai;
  final Color? warnaNilai;

  const _BarisPricing({required this.label, required this.nilai, this.warnaNilai});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF666666))),
        Text(nilai,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: warnaNilai ?? const Color(0xFF1A1A2E))),
      ],
    );
  }
}

class _PlaceholderGambarMini extends StatelessWidget {
  const _PlaceholderGambarMini();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      width: 80,
      color: const Color(0xFFE3EAF5),
      child: const Center(
        child: Icon(Icons.sports_soccer_rounded,
            size: 28, color: Color(0xFF1B4E82)),
      ),
    );
  }
}