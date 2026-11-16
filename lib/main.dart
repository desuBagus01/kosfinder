import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/kos_provider.dart';
import 'screens/kos_list_screen.dart';

void main() {
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
