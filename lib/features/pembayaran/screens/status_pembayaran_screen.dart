import 'package:flutter/material.dart';
import '../../../data/model/status_pembayaran_model.dart';
import '../widgets/payment_success_header.dart';
import '../widgets/payment_info_banner.dart';
import '../widgets/payment_detail_card.dart';
import '../widgets/payment_action_buttons.dart';

class StatusPembayaranScreen extends StatelessWidget {
  final StatusPembayaranModel data;

  const StatusPembayaranScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const PaymentSuccessHeader(),
            const SizedBox(height: 16),
            const PaymentInfoBanner(),
            const SizedBox(height: 16),
            PaymentDetailCard(data: data),
            const SizedBox(height: 24),
            PaymentActionButtons(
              onLihatDetail: () {
                // TODO: navigate to booking detail
              },
              onKembaliBerada: () =>
                  Navigator.of(context).popUntil((r) => r.isFirst),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back,
            color: Color(0xFF1A1A2E), size: 22),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: const Text(
        'Status Pembayaran',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A2E),
        ),
      ),
      centerTitle: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: const Color(0xFFEEEEEE), height: 1),
      ),
    );
  }
}