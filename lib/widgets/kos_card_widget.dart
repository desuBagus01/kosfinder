import 'package:flutter/material.dart';

import '../models/kos_model.dart';
import '../theme/app_theme.dart';

/// Widget kartu kos untuk menampilkan ringkasan informasi kos pada daftar publik.
/// Mengadopsi prinsip desain Modern Minimalist dengan Blue Theme.
/// Memenuhi FR01, US01, dan AC01-1.
class KosCardWidget extends StatelessWidget {
  final KosModel kos;
  final VoidCallback? onTap;

  const KosCardWidget({super.key, required this.kos, this.onTap});

  /// Memformat angka harga bulanan ke format Rupiah standar (contoh: "Rp 850.000/bulan")
  /// tanpa menambahkan dependensi pustaka eksternal.
  static String formatPrice(int price) {
    final priceString = price.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < priceString.length; i++) {
      if (i > 0 && (priceString.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(priceString[i]);
    }
    return 'Rp ${buffer.toString()}/bulan';
  }

  @override
  Widget build(BuildContext context) {
    final isFull = kos.availableRooms == 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Baris Header: Nama Kos & Badge Ketersediaan Kamar ───────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        kos.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                const SizedBox(height: 8),

                // ── Baris Lokasi: Area Kos ──────────────────────────────────
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        kos.area,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // ── Baris Bawah: Harga Sewa Bulanan & Indikator Fasilitas ────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      formatPrice(kos.pricePerMonth),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    // Indikator fasilitas ringkas
                    Row(
                      children: [
                        if (kos.hasWifi)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(
                              Icons.wifi_rounded,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        if (kos.hasBathroomInside)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(
                              Icons.bathtub_outlined,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        if (kos.hasParking)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(
                              Icons.local_parking_rounded,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
