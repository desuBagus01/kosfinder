import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/auth_provider.dart';
import 'providers/kos_provider.dart';
import 'repositories/auth_repository.dart';
import 'screens/kos_list_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // 1. Pastikan binding Flutter siap sebelum operasi asynchronous
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Ambil konfigurasi Supabase dari environment variable (--dart-define) atau file .env
  String supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
  String supabaseKey = const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    try {
      await dotenv.load(fileName: '.env');
      supabaseUrl = supabaseUrl.isNotEmpty
          ? supabaseUrl
          : (dotenv.env['SUPABASE_URL'] ?? '');
      supabaseKey = supabaseKey.isNotEmpty
          ? supabaseKey
          : (dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? '');
    } catch (_) {
      // File .env mungkin tidak tersedia di lingkungan build tertentu
    }
  }

  if (supabaseUrl.isEmpty) {
    throw StateError(
      'SUPABASE_URL tidak ditemukan atau kosong. '
      'Pastikan file .env sudah dikonfigurasi atau gunakan parameter build --dart-define=SUPABASE_URL=...',
    );
  }
  if (supabaseKey.isEmpty) {
    throw StateError(
      'SUPABASE_PUBLISHABLE_KEY tidak ditemukan atau kosong. '
      'Pastikan file .env sudah dikonfigurasi atau gunakan parameter build --dart-define=SUPABASE_PUBLISHABLE_KEY=...',
    );
  }

  // 4. Inisialisasi Supabase menggunakan publishableKey (supabase_flutter ^2.x)
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);

  // 5. Jalankan aplikasi
  runApp(const MyApp());
}

/// Widget root aplikasi KosFinder.
class MyApp extends StatelessWidget {
  final Widget? home;
  const MyApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => KosProvider()),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(repository: AuthRepository()),
        ),
      ],
      child: MaterialApp(
        title: 'KosFinder',
        theme: AppTheme.lightTheme,
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
      appBar: AppBar(title: const Text('About')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Logo / Icon Aplikasi
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
              ),
              child: const Icon(
                Icons.apartment_rounded,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'KosFinder',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Temukan Kos Nyaman Tanpa Ribet',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 28),

            // Kartu Identitas Pengembang
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x080F172A),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Identitas Pengembang',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      '2415051014 - Gede Supadma',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Informasi Versi
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'Versi 0.1.0',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
