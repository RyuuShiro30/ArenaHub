import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class PromoPage extends StatelessWidget {
  const PromoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F4F7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A2D4F)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Kode Promo',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1A2D4F),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('promos')
            .where('aktif', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'Tidak ada promo tersedia',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          final promos = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: promos.length,
            itemBuilder: (context, index) {
              final data = promos[index].data() as Map<String, dynamic>;
              return PromoCard(data: data);
            },
          );
        },
      ),
    );
  }
}

class PromoCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const PromoCard({super.key, required this.data});

  String _formatExpired(dynamic expiredAt) {
    if (expiredAt == null) return '-';
    if (expiredAt is Timestamp) {
      final dt = expiredAt.toDate();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }
    return '-';
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return 'Rp 0';
    final num value = amount is num ? amount : num.tryParse(amount.toString()) ?? 0;
    return 'Rp ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  bool get _isExpired {
    final expiredAt = data['expiredAt'];
    if (expiredAt is Timestamp) {
      return expiredAt.toDate().isBefore(DateTime.now());
    }
    return false;
  }

  bool get _isHabis {
    final kuota = data['kuota'] ?? 0;
    final used = data['used'] ?? 0;
    return used >= kuota;
  }

  @override
  Widget build(BuildContext context) {
    final kode = data['kode']?.toString() ?? '';
    final diskon = data['diskon'] ?? 0;
    final kuota = data['kuota'] ?? 0;
    final used = data['used'] ?? 0;
    final sisa = kuota - used;
    final expired = _formatExpired(data['expiredAt']);
    final minTransaksi = _formatCurrency(data['minimalTransaksi']);
    final isUnavailable = _isExpired || _isHabis;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A2D4F).withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: isUnavailable ? 0.6 : 1.0,
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A2D4F), Color(0xFF1E3A5F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4DD9AC),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isUnavailable
                            ? (_isHabis ? 'KUOTA HABIS' : 'EXPIRED')
                            : 'FLASH DEAL',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A2D4F),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Diskon $diskon%',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Min. transaksi $minTransaksi',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              // Divider dashed
              Container(
                color: const Color(0xFF1A2D4F),
                child: Row(
                  children: [
                    const _CircleNotch(left: true),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return CustomPaint(
                            size: Size(constraints.maxWidth, 1),
                            painter: _DashedLinePainter(),
                          );
                        },
                      ),
                    ),
                    const _CircleNotch(left: false),
                  ],
                ),
              ),

              // Body
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A2D4F),
                ),
                child: Column(
                  children: [
                    // Kode + copy button
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                              ),
                            ),
                            child: Text(
                              kode,
                              style: GoogleFonts.sourceCodePro(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _CopyButton(kode: kode, disabled: isUnavailable),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Info baris
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _InfoChip(
                          icon: Icons.people_outline,
                          label: 'Sisa $sisa kuota',
                        ),
                        _InfoChip(
                          icon: Icons.calendar_today_outlined,
                          label: 'Berlaku s/d $expired',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CopyButton extends StatefulWidget {
  final String kode;
  final bool disabled;

  const _CopyButton({required this.kode, required this.disabled});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  void _onCopy() async {
    if (widget.disabled) return;
    await Clipboard.setData(ClipboardData(text: widget.kode));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onCopy,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _copied
              ? const Color(0xFF4DD9AC).withOpacity(0.85)
              : const Color(0xFF4DD9AC),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              _copied ? Icons.check : Icons.copy_rounded,
              size: 16,
              color: const Color(0xFF1A2D4F),
            ),
            const SizedBox(width: 6),
            Text(
              _copied ? 'Disalin!' : 'Salin',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A2D4F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.white54),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }
}

class _CircleNotch extends StatelessWidget {
  final bool left;
  const _CircleNotch({required this.left});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(left ? -12 : 12, 0),
      child: Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: Color(0xFFF2F4F7),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.5;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) => false;
}