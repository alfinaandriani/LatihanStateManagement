import 'package:flutter/material.dart'; // Mengimpor material design library dari Flutter untuk membangun UI
import 'package:http/http.dart'
    as http; // Mengimpor paket untuk melakukan HTTP requests
import 'dart:convert'; // Mengimpor paket Dart untuk konversi data JSON
import 'package:url_launcher/url_launcher.dart'; // Mengimpor paket untuk meluncurkan URL di browser atau aplikasi pihak ketiga
import 'package:flutter_bloc/flutter_bloc.dart'; // Mengimpor paket bloc untuk state management pada aplikasi ini

void main() => runApp(const MyApp()); // Fungsi utama untuk menjalankan aplikasi

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BlocProvider(
        create: (_) => UniversitasBloc(),
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

// Membuat kelas abstrak sebagai base class untuk semua event yang berhubungan dengan universitas
abstract class UniversitasEvent {}

// Event untuk memicu pengambilan data universitas dari API berdasarkan negara
class FetchUniversities extends UniversitasEvent {
  final String country; // Negara target dari mana universitas akan diambil
  FetchUniversities(this.country); // Konstruktor yang menginisialisasi negara
}

// Membuat kelas abstrak sebagai base class untuk semua state yang mungkin dalam BLoC universitas
abstract class UniversityState {}

// State awal BLoC, sebelum ada interaksi atau operasi yang dilakukan
class UniversityInitial extends UniversityState {}

// State yang menandakan data universitas sedang dalam proses pengambilan
class UniversitasLoading extends UniversityState {}

// State yang menandakan data universitas telah berhasil dimuat
class UniversityLoaded extends UniversityState {
  // Daftar universitas yang berhasil dimuat
  final List<Universitas> universities;
  final String selectedCountry; // Negara yang universitasnya dimuat
  // Konstruktor untuk menginisialisasi data universitas dan negara
  UniversityLoaded(this.universities, this.selectedCountry);
}

// State yang menandakan terjadi kesalahan dalam pengambilan data universitas
class UniversityError extends UniversityState {
  final String message; // Pesan kesalahan yang menjelaskan apa yang salah
  // Konstruktor yang menginisialisasi pesan kesalahan
  UniversityError(this.message);
}

// Bloc untuk mengelola data universitas
class UniversitasBloc extends Bloc<UniversitasEvent, UniversityState> {
  // Konstruktor UniversitasBloc dengan state awal
  UniversitasBloc() : super(UniversityInitial()) {
    // Menangani event FetchUniversities
    on<FetchUniversities>((event, emit) async {
      emit(UniversitasLoading());
      // Mengirimkan state loading sebelum melakukan permintaan HTTP
      try {
        final response = await http.get(Uri.parse(
            'http://universities.hipolabs.com/search?country=${event.country}'));
        // Memeriksa jika response berhasil
        if (response.statusCode == 200) {
          // Decode response body menjadi JSON
          List jsonResponse = json.decode(response.body);
          // Mengonversi JSON menjadi daftar universitas
          List<Universitas> universities =
              jsonResponse.map((data) => Universitas.fromJson(data)).toList();
          emit(UniversityLoaded(universities, event.country));
        } else {
          emit(UniversityError("Gagal memuat universitas"));
        }
      } catch (e) {
        emit(UniversityError(e.toString()));
      }
    });
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
        title: BlocBuilder<UniversitasBloc, UniversityState>(
          builder: (context, state) {
            if (state is UniversityLoaded) {
              return Text("Universitas di ${state.selectedCountry}");
            } else {
              return Text("Universitas di ASEAN");
            }
          },
        ),
      ),
      // Body menggunakan kolom memungkinkan penempatan widget secara vertikal
      body: Column(
        // Children di dalam Column memungkinkan lebih dari satu widget
        children: [
          // DropdownButton untuk memilih negara
          DropdownButton<String>(
            value: (context.watch<UniversitasBloc>().state is UniversityLoaded)
                ? (context.read<UniversitasBloc>().state as UniversityLoaded)
                    .selectedCountry
                : 'Indonesia',
            items: [
              // Daftar negara yang akan ditampilkan di dropdown
              'Indonesia',
              'Malaysia',
              'Singapura',
              'Thailand',
              'Filipina',
              'Vietnam'
            ].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                context
                    .read<UniversitasBloc>()
                    .add(FetchUniversities(newValue));
              }
            },
          ),
          // Widget Expanded mengambil ruang yang tersisa di kolom
          Expanded(
            child: BlocBuilder<UniversitasBloc, UniversityState>(
              builder: (context, state) {
                if (state is UniversitasLoading) {
                  return const CircularProgressIndicator();
                } else if (state is UniversityLoaded) {
                  // ListView.builder untuk membuat daftar yang bisa di-scroll
                  return ListView.builder(
                    // Jumlah item dalam list sesuai dengan jumlah universitas
                    itemCount: state.universities.length,
                    // Pembangun item individual
                    itemBuilder: (context, index) {
                      // Universitas pada posisi index tertentu
                      var university = state.universities[index];
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
                } else if (state is UniversityError) {
                  return Center(child: Text(state.message));
                }
                return const Center(child: Text("Pilih Negara"));
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
