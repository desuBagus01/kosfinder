import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/kos_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/kos_card_widget.dart';

/// Halaman rincian detail kos KosFinder.
/// Menampilkan seluruh informasi lengkap kos dan kontak pemilik tanpa kewajiban login.
/// Mengadopsi prinsip desain Modern Minimalist dengan Blue Theme.
/// Memenuhi FR05, FR06, US04, AC04-1, AC04-2, AC04-3, NFR04.
class KosDetailScreen extends StatefulWidget {
  final String kosId;

  const KosDetailScreen({super.key, required this.kosId});

  /// Menormalisasi nomor telepon Indonesia dari format `08...` menjadi `628...`
  /// agar kompatibel dengan deep link WhatsApp (wa.me).
  static String normalizeWhatsAppNumber(String number) {
    final digits = number.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.startsWith('08')) {
      return '62${digits.substring(1)}';
    }
    if (digits.startsWith('8') && digits.length >= 9) {
      return '62$digits';
    }
    return digits;
  }

  @override
  State<KosDetailScreen> createState() => _KosDetailScreenState();
}

class _KosDetailScreenState extends State<KosDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Memulai pemuatan detail kos saat halaman pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KosProvider>().fetchKosDetail(widget.kosId);
    });
  }

  /// Membuka aplikasi telepon dengan nomor pemilik kos.
  Future<void> _launchPhone(BuildContext context, String number) async {
    final digits = number.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$digits');
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat membuka aplikasi telepon.'),
          ),
        );
      }
    }
  }

  /// Membuka percakapan WhatsApp dengan nomor pemilik kos.
  Future<void> _launchWhatsApp(BuildContext context, String number) async {
    final waNumber = KosDetailScreen.normalizeWhatsAppNumber(number);
    final uri = Uri.parse('https://wa.me/$waNumber');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tidak dapat membuka WhatsApp. Pastikan WhatsApp sudah terpasang.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Kos',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Consumer<KosProvider>(
        builder: (context, provider, child) {
          // 1. Kondisi Sedang Memuat Data
          if (provider.isLoadingDetail) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          // 2. Kondisi Gagal Memuat atau Kos Tidak Ditemukan
          if (provider.errorMessage != null && provider.selectedKos == null) {
            final isNotFound = provider.errorMessage!.contains(
              'tidak ditemukan atau sudah tidak tersedia',
            );
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isNotFound
                            ? AppColors.warningLight
                            : AppColors.errorLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isNotFound ? Icons.search_off : Icons.wifi_off_rounded,
                        size: 48,
                        color: isNotFound ? AppColors.warning : AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      isNotFound ? 'Kos Tidak Ditemukan' : 'Gangguan Koneksi',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isNotFound
                          ? 'Kos tidak ditemukan atau sudah tidak tersedia'
                          : provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, size: 20),
                      label: const Text('Kembali'),
                    ),
                  ],
                ),
              ),
            );
          }

          // 3. Kondisi Sukses: Tampilkan Rincian Kos
          final kos = provider.selectedKos;
          if (kos == null) {
            return const SizedBox.shrink();
          }

          final isFull = kos.availableRooms == 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Nama & Badge Ketersediaan Kamar ──────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        kos.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: isFull
                          ? 'Kamar Penuh'
                          : 'Kamar Tersedia: ${kos.availableRooms} kamar',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isFull
                              ? AppColors.errorLight
                              : AppColors.successLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isFull
                                ? AppColors.errorBorder
                                : AppColors.successBorder,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          isFull
                              ? 'Kamar Penuh'
                              : 'Sisa ${kos.availableRooms} kamar',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isFull ? AppColors.error : AppColors.success,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Highlight Harga Bulanan ──────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFBFDBFE),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tarif Sewa',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      Text(
                        KosCardWidget.formatPrice(kos.pricePerMonth),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),

                // ── Alamat & Area ────────────────────────────────────────
                _SectionTitle(icon: Icons.location_on, label: 'Alamat'),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kos.address,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Area: ${kos.area}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Fasilitas ────────────────────────────────────────────
                _SectionTitle(icon: Icons.star_outline, label: 'Fasilitas'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FacilityChip(
                      label: 'WiFi',
                      icon: Icons.wifi,
                      active: kos.hasWifi,
                    ),
                    _FacilityChip(
                      label: 'Kamar Mandi Dalam',
                      icon: Icons.bathtub_outlined,
                      active: kos.hasBathroomInside,
                    ),
                    _FacilityChip(
                      label: 'Parkir',
                      icon: Icons.local_parking,
                      active: kos.hasParking,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Deskripsi ────────────────────────────────────────────
                _SectionTitle(
                  icon: Icons.description_outlined,
                  label: 'Deskripsi',
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    kos.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Kontak Pemilik ───────────────────────────────────────
                const Divider(),
                _SectionTitle(
                  icon: Icons.phone_outlined,
                  label: 'Kontak Pemilik',
                ),
                const SizedBox(height: 10),
                // Tampilan nomor kontak
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.phone,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          kos.contactNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Tombol Aksi: Telepon & WhatsApp
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('btn_phone'),
                        onPressed: () =>
                            _launchPhone(context, kos.contactNumber),
                        icon: const Icon(Icons.call, size: 18),
                        label: const Text('Telepon'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        key: const Key('btn_whatsapp'),
                        onPressed: () =>
                            _launchWhatsApp(context, kos.contactNumber),
                        icon: const Icon(Icons.chat, size: 18),
                        label: const Text('WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 48),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'Hubungi pemilik melalui telepon atau WhatsApp secara langsung.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Widget judul seksi pada halaman detail kos.
class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Widget chip indikator fasilitas kos.
class _FacilityChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;

  const _FacilityChip({
    required this.label,
    required this.icon,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppColors.primaryLight : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? const Color(0xFFBFDBFE) : AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: active ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? AppColors.primaryDark : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
