import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/kos_model.dart';
import '../providers/kos_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/kos_card_widget.dart';
import 'kos_detail_screen.dart';

/// Halaman utama aplikasi KosFinder yang menampilkan daftar seluruh kos secara publik.
/// Mengadopsi prinsip desain Modern Minimalist dengan Blue Theme.
/// Memenuhi FR01, FR02, US01, US02, AC01-1, AC01-2, AC01-3, NFR03, NFR04, dan NFR05.
class KosListScreen extends StatefulWidget {
  const KosListScreen({super.key});

  @override
  State<KosListScreen> createState() => _KosListScreenState();
}

class _KosListScreenState extends State<KosListScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // Memulai pemuatan daftar kos saat halaman pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<KosProvider>();
      if (provider.kosList.isEmpty && !provider.isLoadingList) {
        provider.fetchKosList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchKos() {
    context.read<KosProvider>().fetchKosListFiltered(
      keyword: _searchController.text,
    );
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<KosProvider>().clearFilter();
  }

  /// Navigasi ke halaman detail kos berdasarkan ID kos yang dipilih.
  void _navigateToDetail(BuildContext context, KosModel kos) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => KosDetailScreen(kosId: kos.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.apartment_rounded,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'KosFinder',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
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
                      appBar: AppBar(title: const Text('About')),
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
      body: Column(
        children: [
          // ── Search Bar Input Teks Bebas ──────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: TextField(
              key: const ValueKey('kos-search-field'),
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Cari nama kos, area, atau alamat...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        tooltip: 'Hapus teks',
                        onPressed: _clearSearch,
                      ),
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      tooltip: 'Cari',
                      onPressed: _searchKos,
                    ),
                  ],
                ),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _searchKos(),
            ),
          ),

          // ── Konten Utama (Consumer KosProvider) ──────────────────────────
          Expanded(
            child: Consumer<KosProvider>(
              builder: (context, provider, child) {
                // 1. Kondisi Sedang Memuat Data (Loading State < 200 ms)
                if (provider.isLoadingList && provider.kosList.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                // 2. Kondisi Terjadi Kesalahan / Gangguan Koneksi (Error State & Retry)
                if (provider.errorMessage != null && provider.kosList.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: AppColors.errorLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.wifi_off_rounded,
                              size: 48,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Gangguan Koneksi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            provider.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              provider.retryFetchKosList();
                            },
                            icon: const Icon(Icons.refresh, size: 20),
                            label: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // 3. Kondisi Data Kosong (Empty State)
                if (provider.kosList.isEmpty) {
                  final isFiltered = provider.isFiltered;
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFiltered
                                  ? Icons.search_off_rounded
                                  : Icons.home_work_outlined,
                              size: 48,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            isFiltered
                                ? 'Kos Tidak Ditemukan'
                                : 'Belum Ada Kos Terdaftar',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isFiltered
                                ? "Tidak ditemukan kos di area '${provider.searchKeyword}'"
                                : 'Belum ada kos yang terdaftar saat ini',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          if (isFiltered) ...[
                            const SizedBox(height: 20),
                            OutlinedButton.icon(
                              onPressed: _clearSearch,
                              icon: const Icon(Icons.clear_all, size: 18),
                              label: const Text('Reset Pencarian'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                // 4. Kondisi Sukses Menampilkan Daftar Kos
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => provider.isFiltered
                      ? provider.retryFetchKosList()
                      : provider.fetchKosList(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 10),
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
          ),
        ],
      ),
    );
  }
}
