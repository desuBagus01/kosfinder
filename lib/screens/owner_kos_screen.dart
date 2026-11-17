import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/kos_model.dart';
import '../providers/auth_provider.dart';
import '../providers/kos_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/owner_kos_card_widget.dart';
import 'kos_list_screen.dart';
import 'login_screen.dart';

/// Halaman kelola kos pemilik (`OwnerKosScreen`).
/// Menampilkan seluruh data kos milik pemilik yang sedang login,
/// tombol "Tambah Kos", tombol aksi Edit, Hapus, dan tombol Logout.
/// Memenuhi FR09, FR10, FR11, FR12, US05, US06, US07, AC05-5, AC07-1, AC07-2, dan NFR04.
class OwnerKosScreen extends StatefulWidget {
  const OwnerKosScreen({super.key});

  @override
  State<OwnerKosScreen> createState() => _OwnerKosScreenState();
}

class _OwnerKosScreenState extends State<OwnerKosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        context.read<KosProvider>().fetchOwnerKosList(auth.currentUser?.id);
      }
    });
  }

  void _loadOwnerKos() {
    final auth = context.read<AuthProvider>();
    context.read<KosProvider>().fetchOwnerKosList(auth.currentUser?.id);
  }

  Future<void> _handleLogout() async {
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Anda telah keluar.'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const KosListScreen()),
      );
    }
  }

  void _handleAddKos() {
    // Placeholder navigasi/formulir tambah kos (akan diimplementasikan penuh pada TASK-4.3)
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Formulir tambah kos akan tersedia pada TASK-4.3.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleEditKos(KosModel kos) {
    // Placeholder navigasi ubah kos (akan diimplementasikan penuh pada TASK-4.4)
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Form ubah "${kos.name}" akan tersedia pada TASK-4.4.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleDeleteKos(KosModel kos) {
    // Placeholder konfirmasi dan penghapusan kos (akan diimplementasikan penuh pada TASK-4.4)
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Konfirmasi hapus "${kos.name}" akan tersedia pada TASK-4.4.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // ── 1. Proteksi Akses: Pengguna yang belum login dibatasi ─────────────────
    if (!auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Kelola Kos Pemilik')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.errorLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 48,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Akses Dibatasi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Anda harus masuk terlebih dahulu untuk mengakses halaman kelola kos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  key: const Key('btn_auth_required_login'),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Masuk ke Akun'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── 2. Tampilan Pengguna Terautentikasi ──────────────────────────────────
    final kosProvider = context.watch<KosProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Kelola Kos Pemilik',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
        actions: [
          TextButton.icon(
            key: const Key('btn_owner_logout'),
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('btn_add_kos'),
        onPressed: _handleAddKos,
        icon: const Icon(Icons.add),
        label: const Text(
          'Tambah Kos',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(child: _buildBody(kosProvider)),
    );
  }

  Widget _buildBody(KosProvider kosProvider) {
    // ── A. Status Loading ───────────────────────────────────────────────────
    if (kosProvider.isLoadingOwnerList) {
      return const Center(
        child: CircularProgressIndicator(
          key: Key('owner_loading_indicator'),
          strokeWidth: 2.5,
        ),
      );
    }

    // ── B. Status Error / Gangguan Jaringan ─────────────────────────────────
    if (kosProvider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.errorLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  size: 40,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Gagal Memuat Data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                kosProvider.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                key: const Key('btn_retry_owner_kos'),
                onPressed: _loadOwnerKos,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    // ── C. Empty State: Pemilik Belum Memiliki Kos ─────────────────────────
    if (kosProvider.ownerKosList.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.apartment_outlined,
                  size: 54,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Belum Ada Kos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Anda belum mempublikasikan data kos. Mulai kelola ketersediaan kamar dan publikasikan kos Anda sekarang.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                key: const Key('btn_add_kos_empty'),
                onPressed: _handleAddKos,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Tambah Kos Sekarang'),
              ),
            ],
          ),
        ),
      );
    }

    // ── D. Daftar Kos Milik Pemilik ─────────────────────────────────────────
    final ownerKosList = kosProvider.ownerKosList;

    return RefreshIndicator(
      onRefresh: () async => _loadOwnerKos(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: ownerKosList.length,
        itemBuilder: (context, index) {
          final kos = ownerKosList[index];
          return OwnerKosCardWidget(
            key: Key('owner_kos_card_${kos.id}'),
            kos: kos,
            onEdit: () => _handleEditKos(kos),
            onDelete: () => _handleDeleteKos(kos),
          );
        },
      ),
    );
  }
}
