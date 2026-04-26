import 'dart:convert';
import 'package:http/http.dart' as http;

class MidtransService {
  static const String serverKey = 'YOUR-SERVER-KEY';

  // Base URL Midtrans Sandbox
  static const String baseUrl = 'https://app.sandbox.midtrans.com/snap/v1/transactions';

  Future<String?> createTransaction({
    required String orderId,
    required int grossAmount,
    required String customerName,
    required String email,
    required String phone,
  }) async {
    try {
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
          "transaction_details": {
            "order_id": orderId,
            "gross_amount": grossAmount,
          },
          "customer_details": {
            "first_name": customerName,
            "email": email,
            "phone": phone,
          }
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);

        return data['redirect_url'];
      } else {
        print('Midtrans Error: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception Midtrans: $e');
      return null;
    }
  }
}
