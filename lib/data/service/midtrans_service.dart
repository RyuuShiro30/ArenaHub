import 'dart:convert';
import 'package:http/http.dart' as http;

class MidtransService {
  static const String serverKey = 'YOUR_SERVER_KEY_HERE';
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
          base64Encode(utf8.encode('$serverKey:'));
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Basic $auth',
          'Content-Type': 'application/json',
        },
      );
      final data = jsonDecode(response.body);
      return data["redirect_url"];
    } catch (e) {
      return null;
    }
  }
}import 'dart:convert';
import 'package:http/http.dart' as http;

class MidtransService {
  static Future<String> createTransaction() async {
    final response = await http.post(
      Uri.parse("http://YOUR_IP:3000/create-transaction"),
    );
 

    final data = jsonDecode(response.body);
    return data["redirect_url"];
  }
}
