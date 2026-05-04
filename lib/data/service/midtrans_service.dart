import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MidtransService {
  final String serverKey = dotenv.env['MIDTRANS_SERVER_KEY'] ?? '';

  static const String baseUrl =
      'https://api.sandbox.midtrans.com/v2/charge';

  Future<String?> createTransaction({
    required String orderId,
    required int grossAmount,
    required String customerName,
    required String email,
    required String phone,
  }) async {
    try {
      // DEBUG
      print('Server Key: "$serverKey"');
      print('Server Key length: ${serverKey.length}');
      print('Gross Amount: $grossAmount');

      final String auth =
          'Basic ${base64Encode(utf8.encode('$serverKey:'))}';

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': auth,
        },
        body: jsonEncode({
          "payment_type": "qris",
          "transaction_details": {
            "order_id": orderId,
            "gross_amount": grossAmount,
          },
          "customer_details": {
            "first_name": customerName,
            "email": email,
            "phone": phone,
          },
          "qris": {
            "acquirer": "gopay"
          }
        }),
      );

      print('=== MIDTRANS RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        final data = jsonDecode(response.body);

        print('Parsed Data: $data');

        if (data['actions'] != null) {
          List actions = data['actions'];

          // Prioritas QR v2
          for (var action in actions) {
            if (action['name'] == 'generate-qr-code-v2') {
              print('QR V2 URL: ${action['url']}');
              return action['url'];
            }
          }

          // Fallback QR biasa
          for (var action in actions) {
            if (action['name'] == 'generate-qr-code') {
              print('QR URL: ${action['url']}');
              return action['url'];
            }
          }
        }

        print('QR URL tidak ditemukan');
      } else {
        print('ERROR: Status bukan 200/201');
      }

      return null;
    } catch (e) {
      print('EXCEPTION createTransaction: $e');
      return null;
    }
  }

  Future<String?> checkStatus(String orderId) async {
    try {
      final String auth =
          'Basic ${base64Encode(utf8.encode('$serverKey:'))}';

      final response = await http.get(
        Uri.parse(
          'https://api.sandbox.midtrans.com/v2/$orderId/status',
        ),
        headers: {
          'Authorization': auth,
          'Content-Type': 'application/json',
        },
      );

      print('=== CHECK STATUS RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return data['transaction_status'];
      }

      return null;
    } catch (e) {
      print('EXCEPTION checkStatus: $e');
      return null;
    }
  }
}