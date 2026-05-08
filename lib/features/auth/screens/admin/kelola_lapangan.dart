import 'package:flutter/material.dart'; // Perbaikan: Hapus tanda titik dua (:)

class KelolaLapanganPage extends StatefulWidget {
  const KelolaLapanganPage({super.key});

  @override
  State<KelolaLapanganPage> createState() => _KelolaLapanganPageState();
}

class _KelolaLapanganPageState extends State<KelolaLapanganPage> {
  String selectedJenis = 'Futsal';
  bool hargaBerbeda = true;
  bool lapanganAktif = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF003366)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tambah Lapangan',
          style: TextStyle(color: Color(0xFF003366), fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Simpan', style: TextStyle(color: Color(0xFF003366))),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Tambah Foto Lapangan", style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            
            // Photo Upload Grid (5 Boxes)
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return Container(
                    width: 80,
                    decoration: BoxDecoration(
                      color: index == 0 ? Colors.transparent : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: index == 0 ? Border.all(color: const Color(0xFF003366), style: BorderStyle.solid) : null,
                    ),
                    child: Icon(Icons.add_a_photo_outlined, color: index == 0 ? const Color(0xFF003366) : Colors.grey),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Preview Section
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(
                  image: NetworkImage('https://placeholder.com/field_preview.jpg'), 
                  fit: BoxFit.cover,
                ),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility_outlined, size: 18),
                      SizedBox(width: 8),
                      Text("Preview Lapangan"),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            _buildSectionCard(
              title: "Informasi Dasar",
              icon: Icons.info_outline,
              child: Column(
                children: [
                  _buildTextField("NAMA LAPANGAN", "Contoh: Arena Futsal A"),
                  _buildDropdownField("JENIS LAPANGAN"),
                  _buildTextField("KAPASITAS PEMAIN", "10", suffix: "Orang"),
                  _buildTextField("DESKRIPSI", "Ceritakan keunggulan lapangan ini...", isMultiline: true),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _buildSectionCard(
              title: "Harga Sewa",
              icon: Icons.payments_outlined,
              child: Column(
                children: [
                  _buildTextField("HARGA PER JAM (BASE)", "Rp 150.000"),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Harga Berbeda per Waktu"),
                      Switch(
                        value: hargaBerbeda,
                        onChanged: (val) => setState(() => hargaBerbeda = val),
                        activeThumbColor: const Color(0xFF003366),
                      ),
                    ],
                  ),
                  if (hargaBerbeda) ...[
                    _buildTimePriceRow(Icons.wb_sunny_outlined, "PAGI (06:00 - 12:00)", "Rp 120.000"),
                    _buildTimePriceRow(Icons.wb_sunny, "SIANG (12:00 - 18:00)", "Rp 150.000"),
                    _buildTimePriceRow(Icons.nightlight_round, "MALAM (18:00 - 24:00)", "Rp 200.000"),
                  ]
                ],
              ),
            ),

            const SizedBox(height: 16),

            _buildSectionCard(
              title: "Fasilitas",
              icon: Icons.flag_outlined,
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                children: [
                  _buildFasilitasItem("Parkir", true),
                  _buildFasilitasItem("Toilet", false),
                  _buildFasilitasItem("Kantin", true),
                  _buildFasilitasItem("WiFi", false),
                  _buildFasilitasItem("Ruang Ganti", false),
                  _buildFasilitasItem("Mushola", true),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.circle, color: lapanganAktif ? Colors.green : Colors.grey, size: 12),
                      const SizedBox(width: 8),
                      const Text("Lapangan Aktif", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Switch(
                    value: lapanganAktif,
                    onChanged: (val) => setState(() => lapanganAktif = val),
                    activeThumbColor: Colors.teal,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {},
                // CARA YANG BENAR
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003366),
                  shape: RoundedRectangleBorder( // Pakai ini sebagai pembungkus
                    borderRadius: BorderRadius.circular(12), // Baru masukkan radiusnya di sini
                  ),
                ),
                child: const Text("Simpan Lapangan", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // HELPER METHODS (Pastikan ini ada di dalam class _KelolaLapanganPageState)
  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: const Color(0xFF003366)),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003366))),
          ]),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, {bool isMultiline = false, String? suffix}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          TextFormField(
            maxLines: isMultiline ? 3 : 1,
            decoration: InputDecoration(
              hintText: hint,
              suffixText: suffix,
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          DropdownButtonFormField(
            initialValue: selectedJenis,
            items: ['Futsal', 'Basket', 'Badminton'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (val) => setState(() => selectedJenis = val.toString()),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePriceRow(IconData icon, String label, String price) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Icon(icon, size: 18, color: Colors.orange),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 12)),
            ]),
            Text(price, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003366))),
          ],
        ),
      ),
    );
  }

  Widget _buildFasilitasItem(String label, bool isSelected) {
    return Row(
      children: [
        Checkbox(
          value: isSelected,
          onChanged: (val) {},
          shape: const CircleBorder(),
          activeColor: Colors.teal,
        ),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}