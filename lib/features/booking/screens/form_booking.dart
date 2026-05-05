import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'konfirmasi_booking.dart';

import '../../../data/model/booking_model.dart';

class FormBookingPage extends StatefulWidget {
  final BookingData booking;

  const FormBookingPage({super.key, required this.booking});

  @override
  State<FormBookingPage> createState() => _FormBookingPageState();
}

class _FormBookingPageState extends State<FormBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _teleponController = TextEditingController();
  final _catatanController = TextEditingController();
  final _promoController = TextEditingController();

  PromoData? _promoAktif;
  String? _promoError;
  bool _isLoading = false;

  static const Color _primaryColor = Color(0xFF135B9D);
  static const Color _accentColor = Color(0xFF2196F3);
  static const Color _successColor = Color(0xFF4CAF50);
  static const Color _errorColor = Color(0xFFE53935);

  @override
  void dispose() {
    _namaController.dispose();
    _teleponController.dispose();
    _catatanController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  // ─── Kalkulasi harga ─────────────────────────────────────────────────────

  int get _subtotal => widget.booking.hargaPerJam * widget.booking.durasiJam;
  int get _diskon => _promoAktif?.diskon ?? 0;
  int get _total => _subtotal - _diskon;

  String _formatRupiah(int nominal) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'IDR ',
      decimalDigits: 0,
    ).format(nominal);
  }

  // ─── Logic promo ─────────────────────────────────────────────────────────

  void _terapkanPromo() {
    final kode = _promoController.text.trim().toUpperCase();

    if (kode.isEmpty) {
      setState(() {
        _promoError = 'Masukkan kode promo terlebih dahulu';
        _promoAktif = null;
      });
      return;
    }

    // Cari promo — pakai where().cast() agar tidak butuh extension firstOrNull
    // TODO: Ganti dengan API call ke backend saat database sudah siap
    PromoData? promo;
    for (final p in daftarPromo) {
      if (p.kode == kode) {
        promo = p;
        break;
      }
    }

    setState(() {
      if (promo != null) {
        _promoAktif = promo;
        _promoError = null;
      } else {
        _promoAktif = null;
        _promoError = 'Kode promo tidak valid';
      }
    });
  }

  void _hapusPromo() {
    setState(() {
      _promoController.clear();
      _promoAktif = null;
      _promoError = null;
    });
  }

  // ─── Submit booking ───────────────────────────────────────────────────────

  // ─── Submit booking ───────────────────────────────────────────────────────

  Future<void> _konfirmasiBooking() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KonfirmasiBookingPage(
          data: KonfirmasiData(
            booking: widget.booking,
            namaPemesan: _namaController.text.trim(),
            nomorTelepon: _teleponController.text.trim(),
            catatan: _catatanController.text.trim(),
            promo: _promoAktif,
            biayaLayanan: 5000,
          ),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: _buildKartuLapangan()),
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

  // ─── App Bar ──────────────────────────────────────────────────────────────

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
          color: _primaryColor,
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
      centerTitle: false,
    );
  }

  // ─── Kartu Info Lapangan ──────────────────────────────────────────────────

  Widget _buildKartuLapangan() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use — ganti ke withValues kalau Flutter >= 3.27
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: widget.booking.imagePath.startsWith('http')
                ? Image.network(
                    widget.booking.imagePath,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _PlaceholderGambar(),
                  )
                : Image.asset(
                    widget.booking.imagePath,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _PlaceholderGambar(),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.booking.namaLapangan,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.calendar_today_rounded,
                  text: widget.booking.tanggalDisplay,
                ),
                const SizedBox(height: 6),
                _InfoRow(
                  icon: Icons.access_time_rounded,
                  text: widget.booking.waktuDisplay,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Seksi Data Pemesan ───────────────────────────────────────────────────

  Widget _buildSeksiDataPemesan() {
    return _Kartu(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SeksiJudul('Data Pemesan'),
          const SizedBox(height: 16),
          _InputField(
            label: 'Nama Lengkap',
            hint: 'Masukkan nama',
            controller: _namaController,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Nama tidak boleh kosong'
                : null,
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

  // ─── Seksi Promo ─────────────────────────────────────────────────────────

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
              const Text(
                'Kode Promo',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Color(0xFF1A1A2E),
                ),
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
                  enabled: _promoAktif == null, // dikunci kalau promo aktif
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
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: _accentColor, width: 1.5),
                    ),
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
                    if (_promoError != null) {
                      setState(() => _promoError = null);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _promoAktif == null ? _terapkanPromo : _hapusPromo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _promoAktif == null ? _primaryColor : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
                border:
                    Border.all(color: _successColor.withOpacity(0.3), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: _successColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_promoAktif!.deskripsi} · Hemat ${_formatRupiah(_promoAktif!.diskon)}',
                      style: const TextStyle(
                        color: _successColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
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

  // ─── Seksi Rincian Harga ──────────────────────────────────────────────────

  Widget _buildSeksiRincianHarga() {
    return _Kartu(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SeksiJudul('Rincian Harga'),
          const SizedBox(height: 16),
          _BarisPricing(
            label: 'Harga per jam',
            nilai: _formatRupiah(widget.booking.hargaPerJam),
          ),
          const SizedBox(height: 8),
          _BarisPricing(
            label: 'Durasi',
            nilai: '${widget.booking.durasiJam} Jam',
          ),
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
              const Text(
                'Total Pembayaran',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              Text(
                _formatRupiah(_total),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Tombol Konfirmasi ────────────────────────────────────────────────────

  Widget _buildTombolKonfirmasi() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
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
              : const Text(
                  'Konfirmasi Booking',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );
  }
}

// ─── Widget Pembantu ─────────────────────────────────────────────────────────

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
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A2E),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF1B4E82)),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 14, color: Color(0xFF555555)),
        ),
      ],
    );
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
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
            hintStyle:
                TextStyle(color: Colors.grey.shade400, fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF5F7FA),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF2196F3), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFE53935), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFE53935), width: 1.5),
            ),
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

  const _BarisPricing({
    required this.label,
    required this.nilai,
    this.warnaNilai,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF666666))),
        Text(
          nilai,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: warnaNilai ?? const Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }
}

class _PlaceholderGambar extends StatelessWidget {
  const _PlaceholderGambar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      color: const Color(0xFFE3EAF5),
      child: const Center(
        child: Icon(Icons.sports_soccer_rounded,
            size: 48, color: Color(0xFF1B4E82)),
      ),
    );
  }
}