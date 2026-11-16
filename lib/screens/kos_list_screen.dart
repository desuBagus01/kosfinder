import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/kos_model.dart';
import '../providers/kos_provider.dart';
import '../widgets/kos_card_widget.dart';
import 'kos_detail_screen.dart';

/// Halaman utama aplikasi KosFinder yang menampilkan daftar seluruh kos secara publik.
/// Pengguna (pencari kos) dapat melihat daftar kos tanpa perlu melakukan login.
/// Memenuhi FR01, US01, AC01-1, AC01-2, AC01-3, NFR03, NFR04, dan NFR05.
class KosListScreen extends StatefulWidget {
  const KosListScreen({super.key});

  @override
  State<KosListScreen> createState() => _KosListScreenState();
}

class _KosListScreenState extends State<KosListScreen> {
  @override
  void initState() {
    super.initState();
    // Memulai pemuatan daftar kos saat halaman pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<KosProvider>();
      if (provider.kosList.isEmpty && !provider.isLoadingList) {
        provider.fetchKosList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'KosFinder',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About',
            onPressed: () {
              try {
                Navigator.pushNamed(context, '/about');
              } catch (_) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    settings: const RouteSettings(name: '/about'),
                    builder: (context) => Scaffold(
                      appBar: AppBar(
                        title: const Text('About'),
                      ),
                      body: const Center(
                        child: Text(
                          '2415051014 - Gede Supadma',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Consumer<KosProvider>(
        builder: (context, provider, child) {
          // 1. Kondisi Sedang Memuat Data (Loading State < 200 ms)
          if (provider.isLoadingList && provider.kosList.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // 2. Kondisi Terjadi Kesalahan / Gangguan Koneksi (Error State & Retry)
          if (provider.errorMessage != null && provider.kosList.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 64,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        provider.retryFetchKosList();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          // 3. Kondisi Data Kosong (Empty State)
          if (provider.kosList.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.home_work_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum ada kos yang terdaftar saat ini',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // 4. Kondisi Sukses Menampilkan Daftar Kos
          return RefreshIndicator(
            onRefresh: () => provider.fetchKosList(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: provider.kosList.length,
              itemBuilder: (context, index) {
                final kos = provider.kosList[index];
                return KosCardWidget(
                  kos: kos,
                  onTap: () => _navigateToDetail(context, kos),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Navigasi ke halaman detail kos berdasarkan ID kos yang dipilih.
  void _navigateToDetail(BuildContext context, KosModel kos) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KosDetailScreen(kosId: kos.id),
      ),
    );
  }
}
