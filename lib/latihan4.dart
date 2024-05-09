import 'package:flutter/material.dart'; // Mengimpor material design library dari Flutter untuk membangun UI
import 'package:http/http.dart'
    as http; // Mengimpor paket untuk melakukan HTTP requests
import 'dart:convert'; // Mengimpor paket Dart untuk konversi data JSON
import 'package:url_launcher/url_launcher.dart'; // Mengimpor paket untuk meluncurkan URL di browser atau aplikasi pihak ketiga
import 'package:provider/provider.dart'; // Mengimpor paket provider untuk state management pada aplikasi ini

// Fungsi utama untuk menjalankan aplikasi
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => UniversitasProvider(),
      child: MyApp(),
    ),
  );
}

// Widget MyApp yang merupakan root dari aplikasi
class MyApp extends StatelessWidget {
  // Method build yang membangun widget
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Universitas di ASEAN', // Judul aplikasi
      home: UniversitasListPage(), // Menentukan homepage aplikasi
    );
  }
}

// Mendefinisikan struktur data untuk Universitas
class Universitas {
  final String name; // Nama universitas
  final String website; // Website universitas

  // Constructor yang meminta parameter nama dan website
  Universitas({required this.name, required this.website});

  // Factory constructor untuk membuat instance University dari data JSON
  factory Universitas.fromJson(Map<String, dynamic> json) {
    return Universitas(
      name: json['name'] ?? "Nama Tidak Tersedia",
      website: json['web_pages'] != null && json['web_pages'].isNotEmpty
          ? json['web_pages'][0] // Mengambil URL pertama dari array web_pages
          : "Situs Web Tidak Tersedia", // Default jika tidak ada website
    );
  }
}

// Provider untuk mengelola data universitas
class UniversitasProvider with ChangeNotifier {
  List<Universitas> _universities = []; // Daftar untuk menyimpan universitas
  String _currentCountry = 'Indonesia'; // Negara yang dipilih saat ini

  List<Universitas> get universities =>
      _universities; // Getter untuk daftar universitas
  String get currentCountry =>
      _currentCountry; // Getter untuk negara yang dipilih

  // Method untuk mengubah negara yang dipilih dan memuat universitas
  void setCountry(String country) {
    _currentCountry = country;
    fetchUniversities();
  }

  // Method asinkron untuk memuat data universitas dari API
  Future<void> fetchUniversities() async {
    final response = await http.get(Uri.parse(
        'http://universities.hipolabs.com/search?country=$_currentCountry'));
    // Memeriksa jika response berhasil
    if (response.statusCode == 200) {
      // Decode response body menjadi JSON
      List jsonResponse = json.decode(response.body);
      // Mengonversi JSON menjadi daftar universitas
      _universities =
          jsonResponse.map((data) => Universitas.fromJson(data)).toList();
      notifyListeners();
    } else {
      throw Exception('Gagal memuat universitas');
    }
  }
}

// Widget stateless untuk halaman list universitas
class UniversitasListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar dengan judul halaman
      appBar: AppBar(
        title: Text(
            "Universitas di ${Provider.of<UniversitasProvider>(context).currentCountry}"), // Judul AppBar
      ),
      // Body menggunakan kolom memungkinkan penempatan widget secara vertikal
      body: Column(
        // Children di dalam Column memungkinkan lebih dari satu widget
        children: [
          // DropdownButton untuk memilih negara
          DropdownButton<String>(
            // Nilai yang saat ini dipilih di dropdown
            value: Provider.of<UniversitasProvider>(context).currentCountry,
            items: <String>[
              // Daftar negara yang akan ditampilkan di dropdown
              'Indonesia',
              'Malaysia',
              'Singapura',
              'Thailand',
              'Filipina',
              'Vietnam'
              // Mapping setiap string menjadi DropdownMenuItem
            ].map<DropdownMenuItem<String>>((String value) {
              // Membuat item dropdown
              return DropdownMenuItem<String>(
                value: value, // Nilai yang diwakili item
                child: Text(value), // Tampilan teks dari item
              );
            }).toList(), // Konversi hasil mapping menjadi list
            // Fungsi callback yang terpanggil ketika item dipilih
            onChanged: (newValue) {
              // Cek jika nilai baru tidak null
              if (newValue != null) {
                Provider.of<UniversitasProvider>(context, listen: false)
                    .setCountry(newValue);
              }
            },
          ),
          // Widget Expanded mengambil ruang yang tersisa di kolom
          Expanded(
            child: Consumer<UniversitasProvider>(
              // Membangun UI berdasarkan state dari provider
              builder: (context, provider, child) {
                // ListView.builder untuk membuat daftar yang bisa di-scroll
                return ListView.builder(
                  // Jumlah item dalam list sesuai dengan jumlah universitas
                  itemCount: provider.universities.length,
                  // Pembangun item individual
                  itemBuilder: (context, index) {
                    // Universitas pada posisi index tertentu
                    var university = provider.universities[index];
                    // ListTile untuk setiap universitas
                    return ListTile(
                      title: Center(child: Text(university.name)),
                      subtitle: Center(
                        // Widget GestureDetector digunakan untuk menangkap gestur tap
                        child: GestureDetector(
                          // Fungsi onTap diatur untuk memanggil _launchURL ketika teks URL diklik
                          onTap: () => _launchURL(university.website),
                          child: Text(
                            university.website,
                            // Untuk mengatur desain link website universitas
                            style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk membuka URL di browser eksternal atau aplikasi yang sesuai.
  void _launchURL(String url) async {
    // Cek apakah URL dapat dibuka.
    if (await canLaunch(url)) {
      // Buka URL jika valid dan dapat diakses.
      await launch(url);
    } else {
      // Lempar eksepsi jika URL tidak dapat dibuka.
      throw 'Could not launch $url';
    }
  }
}
