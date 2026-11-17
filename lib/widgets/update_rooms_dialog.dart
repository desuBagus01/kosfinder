import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/kos_model.dart';
import '../providers/kos_provider.dart';
import '../theme/app_theme.dart';

/// Dialog untuk memperbarui jumlah kamar tersedia milik pemilik kos.
/// Menerima [kos] sebagai data kos yang akan diperbarui.
/// Memenuhi FR13, US08, AC08-1 hingga AC08-5.
class UpdateRoomsDialog extends StatefulWidget {
  final KosModel kos;

  const UpdateRoomsDialog({super.key, required this.kos});

  @override
  State<UpdateRoomsDialog> createState() => _UpdateRoomsDialogState();
}

class _UpdateRoomsDialogState extends State<UpdateRoomsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _roomsController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _roomsController = TextEditingController(
      text: widget.kos.availableRooms.toString(),
    );
  }

  @override
  void dispose() {
    _roomsController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final newRooms = int.tryParse(_roomsController.text.trim());
    if (newRooms == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final provider = context.read<KosProvider>();
    final success = await provider.updateAvailableRooms(
      widget.kos.id,
      newRooms,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jumlah kamar berhasil diperbarui!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final errMsg =
          provider.errorMessage ?? 'Gagal memperbarui ketersediaan kamar.';
      provider.clearError();
      setState(() {
        _isLoading = false;
        _errorMessage = errMsg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hotel_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Perbarui Ketersediaan Kamar',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nama kos
            Text(
              widget.kos.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Kamar saat ini: ${widget.kos.availableRooms} kamar',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            // Input jumlah kamar baru
            TextFormField(
              key: const Key('update_rooms_input'),
              controller: _roomsController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'Jumlah Kamar Tersedia',
                hintText: 'Contoh: 5',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.door_front_door_outlined),
                suffixText: 'kamar',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Jumlah kamar tidak boleh kosong.';
                }
                final parsed = int.tryParse(value.trim());
                if (parsed == null) {
                  return 'Masukkan angka yang valid.';
                }
                if (parsed < 0) {
                  return 'Jumlah kamar tidak boleh kurang dari 0';
                }
                return null;
              },
            ),
            // Pesan error dari server
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 13, color: AppColors.error),
              ),
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        OutlinedButton(
          key: const Key('btn_cancel_update_rooms'),
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          key: const Key('btn_save_update_rooms'),
          onPressed: _isLoading ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  key: Key('update_rooms_loading_indicator'),
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
