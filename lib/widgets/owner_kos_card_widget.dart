import 'package:flutter/material.dart';

import '../models/kos_model.dart';
import '../theme/app_theme.dart';
import 'update_rooms_dialog.dart';

/// Widget kartu kos untuk halaman pengelolaan kos pemilik (`OwnerKosScreen`).
/// Menampilkan informasi lengkap kos beserta tombol aksi Update Kamar, Edit, dan Hapus.
/// Mengadopsi prinsip desain Modern Minimalist dengan Blue Theme.
/// Memenuhi FR09, FR10, FR11, FR12, FR13, US05, US06, US07, US08, AC08-1, AC08-3.
class OwnerKosCardWidget extends StatelessWidget {
  final KosModel kos;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onUpdateRooms;
  final VoidCallback? onTap;

  const OwnerKosCardWidget({
    super.key,
    required this.kos,
    this.onEdit,
    this.onDelete,
    this.onUpdateRooms,
    this.onTap,
  });

  /// Memformat angka harga bulanan ke format Rupiah standar (contoh: "Rp 850.000/bulan")
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

  void _showUpdateRoomsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => UpdateRoomsDialog(kos: kos),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFull = kos.availableRooms == 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

                // ── Baris Lokasi: Area & Alamat ─────────────────────────────
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
                        '${kos.area} • ${kos.address}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Baris Harga & Fasilitas ─────────────────────────────────
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
                    // Indikator fasilitas yang tersedia
                    Row(
                      children: [
                        if (kos.hasWifi)
                          _buildFacilityChip(Icons.wifi_rounded, 'WiFi'),
                        if (kos.hasBathroomInside)
                          _buildFacilityChip(
                            Icons.bathtub_outlined,
                            'K. Mandi Dalam',
                          ),
                        if (kos.hasParking)
                          _buildFacilityChip(
                            Icons.local_parking_rounded,
                            'Parkir',
                          ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // ── Baris Tombol Aksi: Update Kamar, Edit & Hapus ───────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      key: Key('btn_update_rooms_${kos.id}'),
                      onPressed: onUpdateRooms ??
                          () => _showUpdateRoomsDialog(context),
                      icon: const Icon(Icons.hotel_outlined, size: 16),
                      label: const Text('Update Kamar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      key: Key('btn_edit_kos_${kos.id}'),
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      key: Key('btn_delete_kos_${kos.id}'),
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text('Hapus'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.errorBorder),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
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

  Widget _buildFacilityChip(IconData icon, String tooltip) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 14, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
