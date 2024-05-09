import 'package:flutter/material.dart'; // Mengimpor material design library dari Flutter untuk membangun UI
import 'package:http/http.dart'
    as http; // Mengimpor paket untuk melakukan HTTP requests
import 'dart:convert'; // Mengimpor paket Dart untuk konversi data JSON
import 'package:url_launcher/url_launcher.dart'; // Mengimpor paket untuk meluncurkan URL di browser atau aplikasi pihak ketiga
import 'package:flutter_bloc/flutter_bloc.dart'; // Mengimpor paket bloc (cubit) untuk state management pada aplikasi ini

// Fungsi utama untuk menjalankan aplikasi
void main() => runApp(const MyApp());

// Widget MyApp yang merupakan root dari aplikasi
class MyApp extends StatelessWidget {
  // Konstruktor kelas MyApp
  const MyApp({Key? key}) : super(key: key);
  // Method build yang membangun widget
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // BlocProvider adalah widget yang menyediakan sebuah cubit atau bloc kepada subtree
      home: BlocProvider(
        // Instance dari UniversitasCubit
        create: (_) => UniversitasCubit(),
        // Anak dari BlocProvider yang  memiliki akses ke instance UniversitasCubit
        child: const UniversitasListPage(),
      ),
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

// Cubit untuk mengelola data universitas
class UniversitasCubit extends Cubit<List<Universitas>> {
  // Konstruktor untuk memulai state awal Cubit dengan list kosong dari Universitas
  UniversitasCubit() : super([]);
  String _currentCountry = 'Indonesia'; // Negara yang dipilih saat ini
  // Fungsi untuk memuat universitas dari API berdasarkan negara yang diberikan
  void fetchUniversities(String country) async {
    _currentCountry = country;
    final response = await http.get(
        Uri.parse('http://universities.hipolabs.com/search?country=$country'));
    // Memeriksa jika response berhasil
    if (response.statusCode == 200) {
      // Decode response body menjadi JSON
      List jsonResponse = json.decode(response.body);
      // Mengonversi JSON menjadi daftar universitas
      List<Universitas> universities =
          jsonResponse.map((data) => Universitas.fromJson(data)).toList();
      emit(universities);
    } else {
      throw Exception('Gagal memuat universitas');
    }
  }
}

// Widget stateless untuk halaman list universitas
class UniversitasListPage extends StatelessWidget {
  const UniversitasListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar dengan judul halaman
      appBar: AppBar(
        title: Text(
            "Universitas di ${context.read<UniversitasCubit>()._currentCountry}"), // Judul AppBar
      ),
      // Body menggunakan kolom memungkinkan penempatan widget secara vertikal
      body: Column(
        // Children di dalam Column memungkinkan lebih dari satu widget
        children: [
          // DropdownButton untuk memilih negara
          DropdownButton<String>(
            // Nilai yang saat ini dipilih di dropdown
            value: context.read<UniversitasCubit>()._currentCountry,
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
                context.read<UniversitasCubit>().fetchUniversities(newValue);
              }
            },
          ),
          // Widget Expanded mengambil ruang yang tersisa di kolom
          Expanded(
            child: BlocBuilder<UniversitasCubit, List<Universitas>>(
              builder: (context, universities) {
                // ListView.builder untuk membuat daftar yang bisa di-scroll
                return ListView.builder(
                  // Jumlah item dalam list sesuai dengan jumlah universitas
                  itemCount: universities.length,
                  // Pembangun item individual
                  itemBuilder: (context, index) {
                    // Universitas pada posisi index tertentu
                    var university = universities[index];
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
