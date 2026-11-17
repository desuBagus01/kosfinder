import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/kos_model.dart';
import '../providers/auth_provider.dart';
import '../providers/kos_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/kos_card_widget.dart';
import '../widgets/kos_filter_bottom_sheet.dart';
import 'kos_detail_screen.dart';
import 'login_screen.dart';

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
    final provider = context.read<KosProvider>();
    provider.fetchKosListFiltered(
      keyword: _searchController.text,
      maxPrice: provider.maxPrice,
      mustHaveWifi: provider.filterWifi,
      mustHaveBathroom: provider.filterBathroom,
      mustHaveParking: provider.filterParking,
    );
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<KosProvider>().clearFilter();
  }

  /// Membuka lembar modal filter (KosFilterBottomSheet) untuk menyaring kos
  /// berdasarkan harga maksimum dan fasilitas (WiFi, Kamar Mandi Dalam, Parkir).
  void _openFilterBottomSheet(BuildContext context) {
    final provider = context.read<KosProvider>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return KosFilterBottomSheet(
          initialMaxPrice: provider.maxPrice,
          initialWifi: provider.filterWifi,
          initialBathroom: provider.filterBathroom,
          initialParking: provider.filterParking,
          onApply:
              ({
                int? maxPrice,
                required bool mustHaveWifi,
                required bool mustHaveBathroom,
                required bool mustHaveParking,
              }) {
                Navigator.pop(bottomSheetContext);
                provider.fetchKosListFiltered(
                  keyword: _searchController.text,
                  maxPrice: maxPrice,
                  mustHaveWifi: mustHaveWifi,
                  mustHaveBathroom: mustHaveBathroom,
                  mustHaveParking: mustHaveParking,
                );
              },
          onReset: () {
            // Callback saat tombol reset ditekan di dalam modal sheet
          },
        );
      },
    );
  }

  /// Navigasi ke halaman detail kos berdasarkan ID kos yang dipilih.
  void _navigateToDetail(BuildContext context, KosModel kos) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => KosDetailScreen(kosId: kos.id)),
    );
  }

  /// Membangun tombol navigasi autentikasi pada AppBar.
  /// Menyesuaikan tampilan secara reaktif berdasarkan status login pengguna di [AuthProvider]:
  /// - Belum login: menampilkan tombol "Masuk" (key: btn_nav_login) menuju [LoginScreen].
  /// - Sudah login: menampilkan tombol "Keluar" (key: btn_nav_logout) untuk melakukan logout.
  Widget _buildAuthButton(BuildContext context) {
    AuthProvider? authProvider;
    try {
      authProvider = Provider.of<AuthProvider>(context);
    } catch (_) {
      authProvider = null;
    }

    final isAuthenticated = authProvider?.isAuthenticated ?? false;

    if (isAuthenticated) {
      return TextButton.icon(
        key: const Key('btn_nav_logout'),
        onPressed: () async {
          await authProvider?.logout();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Anda telah keluar.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text(
          'Keluar',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.error,
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
      );
    }

    return TextButton.icon(
      key: const Key('btn_nav_login'),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      },
      icon: const Icon(Icons.login_rounded, size: 18),
      label: const Text('Masuk', style: TextStyle(fontWeight: FontWeight.w700)),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
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
          _buildAuthButton(context),
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
          // ── Search Bar Input Teks Bebas & Filter Button ───────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
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
                const SizedBox(width: 10),
                Consumer<KosProvider>(
                  builder: (context, provider, _) {
                    final hasFilter =
                        provider.maxPrice != null ||
                        provider.filterWifi ||
                        provider.filterBathroom ||
                        provider.filterParking;
                    return Tooltip(
                      message: 'Filter',
                      child: Material(
                        color: hasFilter
                            ? AppColors.primary
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          key: const Key('btn_open_filter'),
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _openFilterBottomSheet(context),
                          child: Container(
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: hasFilter
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Icon(
                              Icons.tune_rounded,
                              size: 22,
                              color: hasFilter
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
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
                  final hasActiveFilter =
                      provider.maxPrice != null ||
                      provider.filterWifi ||
                      provider.filterBathroom ||
                      provider.filterParking;
                  final hasKeyword = provider.searchKeyword.isNotEmpty;

                  String emptySubtitle =
                      'Belum ada kos yang terdaftar saat ini';
                  if (hasActiveFilter) {
                    emptySubtitle = 'Tidak ada kos yang cocok dengan kriteria filter tersebut';
                  } else if (hasKeyword) {
                    emptySubtitle =
                        "Tidak ditemukan kos di area '${provider.searchKeyword}'";
                  }

                  String resetButtonLabel = 'Reset Pencarian';
                  if (hasActiveFilter && !hasKeyword) {
                    resetButtonLabel = 'Reset Filter';
                  } else if (hasActiveFilter && hasKeyword) {
                    resetButtonLabel = 'Reset Filter & Pencarian';
                  }

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
                            emptySubtitle,
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
                              label: Text(resetButtonLabel),
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
