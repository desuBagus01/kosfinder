import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/kos_provider.dart';
import '../widgets/kos_card_widget.dart';

/// Halaman rincian detail kos KosFinder.
/// Menampilkan seluruh informasi lengkap kos dan kontak pemilik tanpa kewajiban login.
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
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<KosProvider>(
        builder: (context, provider, child) {
          // 1. Kondisi Sedang Memuat Data
          if (provider.isLoadingDetail) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // 2. Kondisi Gagal Memuat atau Kos Tidak Ditemukan
          if (provider.errorMessage != null && provider.selectedKos == null) {
            final isNotFound = provider.errorMessage!
                .contains('tidak ditemukan atau sudah tidak tersedia');
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isNotFound ? Icons.search_off : Icons.wifi_off_rounded,
                      size: 64,
                      color: isNotFound
                          ? Colors.orange.shade400
                          : Colors.red.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isNotFound
                          ? 'Kos tidak ditemukan atau sudah tidak tersedia'
                          : provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
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
            padding: const EdgeInsets.all(20),
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
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isFull
                            ? Colors.red.shade100
                            : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isFull ? 'Kamar Penuh' : 'Sisa ${kos.availableRooms} kamar',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isFull
                              ? Colors.red.shade800
                              : Colors.green.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ── Harga Per Bulan ──────────────────────────────────────
                Text(
                  KosCardWidget.formatPrice(kos.pricePerMonth),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),

                // ── Alamat ───────────────────────────────────────────────
                _SectionTitle(icon: Icons.location_on, label: 'Alamat'),
                const SizedBox(height: 6),
                Text(
                  kos.address,
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  'Area: ${kos.area}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Fasilitas ────────────────────────────────────────────
                _SectionTitle(icon: Icons.star_outline, label: 'Fasilitas'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
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
                _SectionTitle(icon: Icons.description_outlined, label: 'Deskripsi'),
                const SizedBox(height: 6),
                Text(
                  kos.description,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 20),

                // ── Kontak Pemilik ───────────────────────────────────────
                const Divider(),
                _SectionTitle(
                  icon: Icons.phone_outlined,
                  label: 'Kontak Pemilik',
                ),
                const SizedBox(height: 8),
                // Tampilan nomor
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.phone, color: Colors.grey.shade700),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          kos.contactNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Tombol Telepon dan WhatsApp
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('btn_phone'),
                        onPressed: () =>
                            _launchPhone(context, kos.contactNumber),
                        icon: const Icon(Icons.call),
                        label: const Text('Telepon'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        key: const Key('btn_whatsapp'),
                        onPressed: () =>
                            _launchWhatsApp(context, kos.contactNumber),
                        icon: const Icon(Icons.chat),
                        label: const Text('WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Hubungi pemilik melalui telepon atau WhatsApp secara langsung.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
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
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? Colors.green.shade300 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: active ? Colors.green.shade700 : Colors.grey.shade400,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: active ? Colors.green.shade800 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
