import 'package:flutter/material.dart';
import '../models/kos_model.dart';

/// Widget kartu kos untuk menampilkan ringkasan informasi kos pada daftar publik.
/// Memenuhi FR01, US01, dan AC01-1.
class KosCardWidget extends StatelessWidget {
  final KosModel kos;
  final VoidCallback? onTap;

  const KosCardWidget({
    super.key,
    required this.kos,
    this.onTap,
  });

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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris Nama Kos dan Badge Ketersediaan Kamar
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      kos.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isFull
                          ? Colors.red.shade100
                          : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isFull
                          ? 'Kamar Penuh'
                          : 'Sisa ${kos.availableRooms} kamar',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isFull
                            ? Colors.red.shade800
                            : Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Baris Area Kos
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      kos.area,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Baris Harga Sewa per Bulan
              Text(
                formatPrice(kos.pricePerMonth),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
