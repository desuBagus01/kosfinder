import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Modal bottom sheet untuk menyaring daftar kos berdasarkan harga maksimum
/// per bulan dan fasilitas tetap (WiFi, Kamar Mandi Dalam, Parkir).
///
/// Memenuhi FR03, FR04, US03, AC03-1, AC03-2, dan NFR04.
class KosFilterBottomSheet extends StatefulWidget {
  final int? initialMaxPrice;
  final bool initialWifi;
  final bool initialBathroom;
  final bool initialParking;
  final void Function({
    int? maxPrice,
    required bool mustHaveWifi,
    required bool mustHaveBathroom,
    required bool mustHaveParking,
  })
  onApply;
  final VoidCallback? onReset;

  const KosFilterBottomSheet({
    super.key,
    this.initialMaxPrice,
    this.initialWifi = false,
    this.initialBathroom = false,
    this.initialParking = false,
    required this.onApply,
    this.onReset,
  });

  @override
  State<KosFilterBottomSheet> createState() => _KosFilterBottomSheetState();
}

class _KosFilterBottomSheetState extends State<KosFilterBottomSheet> {
  late final TextEditingController _priceController;
  late bool _mustHaveWifi;
  late bool _mustHaveBathroom;
  late bool _mustHaveParking;
  String? _priceError;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.initialMaxPrice != null
          ? widget.initialMaxPrice.toString()
          : '',
    );
    _mustHaveWifi = widget.initialWifi;
    _mustHaveBathroom = widget.initialBathroom;
    _mustHaveParking = widget.initialParking;
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final text = _priceController.text.trim();
    int? maxPrice;

    if (text.isNotEmpty) {
      final parsed = int.tryParse(text);
      if (parsed == null) {
        setState(() {
          _priceError = 'Masukkan nominal angka yang valid';
        });
        return;
      }
      if (parsed < 0) {
        setState(() {
          _priceError = 'Harga tidak boleh negatif';
        });
        return;
      }
      maxPrice = parsed;
    }

    setState(() {
      _priceError = null;
    });

    widget.onApply(
      maxPrice: maxPrice,
      mustHaveWifi: _mustHaveWifi,
      mustHaveBathroom: _mustHaveBathroom,
      mustHaveParking: _mustHaveParking,
    );
  }

  void _resetLocalFilter() {
    setState(() {
      _priceController.clear();
      _mustHaveWifi = false;
      _mustHaveBathroom = false;
      _mustHaveParking = false;
      _priceError = null;
    });
    if (widget.onReset != null) {
      widget.onReset!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: AppColors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: bottomInset + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Drag Handle ────────────────────────────────────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Header Modal ───────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Filter Kos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _resetLocalFilter,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text(
                      'Reset',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 18),

              // ── Input Harga Maksimum Bulanan ───────────────────────────────
              const Text(
                'Harga Maksimum per Bulan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tentukan batas biaya sewa bulanan dalam Rupiah (Rp/bulan)',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('filter_max_price_input'),
                controller: _priceController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*')),
                ],
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  prefixStyle: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  hintText: 'Contoh: 1500000',
                  errorText: _priceError,
                  helperText: 'Kosongkan jika tanpa batasan harga',
                  helperStyle: const TextStyle(fontSize: 11),
                ),
                onChanged: (_) {
                  if (_priceError != null) {
                    setState(() {
                      _priceError = null;
                    });
                  }
                },
              ),

              const SizedBox(height: 22),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // ── Fasilitas Tetap (Checkbox) ─────────────────────────────────
              const Text(
                'Fasilitas Kos',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Hanya tampilkan kos yang memiliki seluruh fasilitas yang dicentang',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),

              // Checkbox WiFi
              CheckboxListTile(
                key: const Key('filter_checkbox_wifi'),
                value: _mustHaveWifi,
                onChanged: (val) {
                  setState(() {
                    _mustHaveWifi = val ?? false;
                  });
                },
                title: const Text(
                  'WiFi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                secondary: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _mustHaveWifi
                        ? AppColors.primaryLight
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.wifi,
                    size: 18,
                    color: _mustHaveWifi
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
                controlAffinity: ListTileControlAffinity.trailing,
              ),

              // Checkbox Kamar Mandi Dalam
              CheckboxListTile(
                key: const Key('filter_checkbox_bathroom'),
                value: _mustHaveBathroom,
                onChanged: (val) {
                  setState(() {
                    _mustHaveBathroom = val ?? false;
                  });
                },
                title: const Text(
                  'Kamar Mandi Dalam',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                secondary: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _mustHaveBathroom
                        ? AppColors.primaryLight
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.bathtub_outlined,
                    size: 18,
                    color: _mustHaveBathroom
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
                controlAffinity: ListTileControlAffinity.trailing,
              ),

              // Checkbox Parkir
              CheckboxListTile(
                key: const Key('filter_checkbox_parking'),
                value: _mustHaveParking,
                onChanged: (val) {
                  setState(() {
                    _mustHaveParking = val ?? false;
                  });
                },
                title: const Text(
                  'Parkir',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                secondary: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _mustHaveParking
                        ? AppColors.primaryLight
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.local_parking_rounded,
                    size: 18,
                    color: _mustHaveParking
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
                controlAffinity: ListTileControlAffinity.trailing,
              ),

              const SizedBox(height: 24),

              // ── Tombol Terapkan Filter ────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  key: const Key('btn_apply_filter'),
                  onPressed: _applyFilter,
                  icon: const Icon(Icons.check, size: 20),
                  label: const Text('Terapkan Filter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
