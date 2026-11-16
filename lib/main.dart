import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/kos_provider.dart';
import 'screens/kos_list_screen.dart';

Future<void> main() async {
  // 1. Pastikan binding Flutter siap sebelum operasi asynchronous
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Muat konfigurasi dari file .env
  await dotenv.load(fileName: '.env');

  // 3. Ambil dan validasi konfigurasi Supabase
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseKey = dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? '';

  if (supabaseUrl.isEmpty) {
    throw StateError(
      'SUPABASE_URL tidak ditemukan atau kosong di file .env. '
      'Pastikan file .env sudah dikonfigurasi dengan benar.',
    );
  }
  if (supabaseKey.isEmpty) {
    throw StateError(
      'SUPABASE_PUBLISHABLE_KEY tidak ditemukan atau kosong di file .env. '
      'Pastikan file .env sudah dikonfigurasi dengan benar.',
    );
  }

  // 4. Inisialisasi Supabase menggunakan publishableKey (supabase_flutter ^2.x)
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseKey,
  );

  // 5. Jalankan aplikasi
  runApp(const MyApp());
}

/// Widget root aplikasi KosFinder.
class MyApp extends StatelessWidget {
  final Widget? home;
  const MyApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => KosProvider(),
      child: MaterialApp(
        title: 'KosFinder',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        initialRoute: home != null ? null : '/',
        home: home,
        routes: {
          '/': (context) => const KosListScreen(),
          '/about': (context) => const AboutPage(),
        },
      ),
    );
  }
}

/// Halaman About yang memuat identitas pengembang aplikasi.
/// Sesuai mandat AGENTS.md Subbab 6:
/// NIM: 2415051014
/// Nama: Gede Supadma
/// Format Tampilan: 2415051014 - Gede Supadma
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('About'),
      ),
      body: const Center(
        child: Text(
          '2415051014 - Gede Supadma',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
