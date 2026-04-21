import 'dart:convert';
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
