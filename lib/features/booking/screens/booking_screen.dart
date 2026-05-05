import 'package:flutter/material.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Booking Lapangan"),
      ),

      body: ListView(
        children: const [

          ListTile(
            title: Text("Lapangan Futsal A"),
            subtitle: Text("Rp 100.000 / jam"),
          ),

          ListTile(
            title: Text("Lapangan Badminton"),
            subtitle: Text("Rp 50.000 / jam"),
          ),

          ListTile(
            title: Text("Lapangan Basket"),
            subtitle: Text("Rp 80.000 / jam"),
          ),

        ],
      ),
    );
  }
}