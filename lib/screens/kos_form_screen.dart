import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/kos_model.dart';
import '../providers/auth_provider.dart';
import '../providers/kos_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

/// Halaman formulir data kos (`KosFormScreen`) - Mode Tambah & Mode Ubah.
/// Memungkinkan pemilik kos yang telah terautentikasi untuk mempublikasikan data kos baru
/// atau memperbarui informasi kos miliknya sendiri.
/// Memenuhi FR10, FR11, US06, US07, AC06-1, AC06-2, AC06-3, AC06-4, AC07-1, AC07-2, NFR03, dan NFR04.
class KosFormScreen extends StatefulWidget {
  final KosModel? kos;

  const KosFormScreen({super.key, this.kos});

  @override
  State<KosFormScreen> createState() => _KosFormScreenState();
}

class _KosFormScreenState extends State<KosFormScreen> {
  final _formKey = GlobalKey<FormState>();

  bool get isEditMode => widget.kos != null;

  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _areaController;
  late final TextEditingController _contactController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _roomsController;

  bool _hasWifi = false;
  bool _hasBathroomInside = false;
  bool _hasParking = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.kos?.name ?? '');
    _addressController = TextEditingController(text: widget.kos?.address ?? '');
    _areaController = TextEditingController(text: widget.kos?.area ?? '');
    _contactController = TextEditingController(
      text: widget.kos?.contactNumber ?? '',
    );
    _priceController = TextEditingController(
      text: widget.kos != null ? widget.kos!.pricePerMonth.toString() : '',
    );
    _descriptionController = TextEditingController(
      text: widget.kos?.description ?? '',
    );
    _roomsController = TextEditingController(
      text: widget.kos != null ? widget.kos!.availableRooms.toString() : '',
    );

    _hasWifi = widget.kos?.hasWifi ?? false;
    _hasBathroomInside = widget.kos?.hasBathroomInside ?? false;
    _hasParking = widget.kos?.hasParking ?? false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (!auth.isAuthenticated) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        context.read<KosProvider>().clearError();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _contactController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _roomsController.dispose();
    super.dispose();
  }

  /// Menghasilkan UUID v4 acak berbasis standar RFC 4122 tanpa dependensi eksternal.
  String _generateUuidV4() {
    final random = math.Random();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // Versi 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // Variant RFC 4122
    return [
      bytes
          .sublist(0, 4)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(),
      bytes
          .sublist(4, 6)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(),
      bytes
          .sublist(6, 8)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(),
      bytes
          .sublist(8, 10)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(),
      bytes
          .sublist(10, 16)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(),
    ].join('-');
  }

  Future<void> _submitForm() async {
    // 1. Validasi Autentikasi Pemilik
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditMode
                ? 'Anda harus login untuk mengubah data kos.'
                : 'Anda harus login untuk menambahkan kos.',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    // 2. Validasi Formulir
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final kosProvider = context.read<KosProvider>();
    if (kosProvider.isLoadingCrud) {
      return; // Mencegah submit berulang saat proses berlangsung
    }

    final price = int.parse(_priceController.text.trim());
    final rooms = int.parse(_roomsController.text.trim());

    if (isEditMode) {
      // 3a. Mode Ubah: Pertahankan ID dan ownerId asli dari kos yang sedang diedit
      final updatedKos = widget.kos!.copyWith(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        area: _areaController.text.trim(),
        contactNumber: _contactController.text.trim(),
        pricePerMonth: price,
        description: _descriptionController.text.trim(),
        availableRooms: rooms,
        hasWifi: _hasWifi,
        hasBathroomInside: _hasBathroomInside,
        hasParking: _hasParking,
        updatedAt: DateTime.now(),
      );

      final success = await kosProvider.updateKos(updatedKos);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            key: Key('kos_update_success_snackbar'),
            content: Text('Data kos berhasil diperbarui!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      } else {
        // Tampilkan error notification, pertahankan input pengguna (NFR03)
        final errorMsg =
            kosProvider.errorMessage ??
            'Gagal memperbarui kos. Silakan coba kembali.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // 3b. Mode Tambah: Bangun objek KosModel baru
      // Catatan Keamanan: ownerId TIDAK diambil dari input pengguna, melainkan dari sesi login pengguna aktif.
      final newKos = KosModel(
        id: _generateUuidV4(),
        ownerId: authProvider.currentUser?.id ?? 'pending-owner',
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        area: _areaController.text.trim(),
        contactNumber: _contactController.text.trim(),
        pricePerMonth: price,
        description: _descriptionController.text.trim(),
        availableRooms: rooms,
        hasWifi: _hasWifi,
        hasBathroomInside: _hasBathroomInside,
        hasParking: _hasParking,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await kosProvider.createKos(newKos);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            key: Key('kos_create_success_snackbar'),
            content: Text('Kos berhasil ditambahkan!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      } else {
        // Tampilkan error notification, pertahankan input pengguna (NFR03)
        final errorMsg =
            kosProvider.errorMessage ??
            'Gagal menambahkan kos. Silakan coba kembali.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Proteksi Akses: Jika belum login, tampilkan layar Akses Dibatasi
    if (!auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(isEditMode ? 'Ubah Kos' : 'Tambah Kos Baru'),
        ),
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
                Text(
                  isEditMode
                      ? 'Anda harus masuk terlebih dahulu untuk mengubah data kos.'
                      : 'Anda harus masuk terlebih dahulu untuk menambahkan kos baru.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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

    final kosProvider = context.watch<KosProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isEditMode ? 'Ubah Kos' : 'Tambah Kos Baru',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Banner Error dari Provider (jika ada kegagalan) ──────────
                if (kosProvider.errorMessage != null &&
                    !kosProvider.isLoadingCrud) ...[
                  Container(
                    key: const Key('kos_form_error_banner'),
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.errorBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            kosProvider.errorMessage!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── 1. Nama Kos ──────────────────────────────────────────────
                _buildFieldLabel('Nama Kos'),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('kos_form_name_field'),
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: Kos Melati Singaraja',
                    prefixIcon: Icon(Icons.apartment_rounded, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama kos wajib diisi';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // ── 2. Alamat Lengkap ────────────────────────────────────────
                _buildFieldLabel('Alamat Lengkap'),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('kos_form_address_field'),
                  controller: _addressController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: Jl. Udayana No. 11',
                    prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Alamat lengkap wajib diisi';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // ── 3. Area ──────────────────────────────────────────────────
                _buildFieldLabel('Area / Wilayah'),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('kos_form_area_field'),
                  controller: _areaController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: Banyuasri',
                    prefixIcon: Icon(Icons.map_outlined, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Area kos wajib diisi';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // ── 4. Nomor Telepon / WhatsApp Aktif ────────────────────────
                _buildFieldLabel('Nomor Telepon / WhatsApp Aktif'),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('kos_form_contact_field'),
                  controller: _contactController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: 081234567890',
                    prefixIcon: Icon(Icons.phone_outlined, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nomor kontak wajib diisi';
                    }
                    if (value.trim().length < 8) {
                      return 'Nomor kontak minimal 8 digit';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // ── 5. Harga Sewa Bulanan (Rp/bulan) ─────────────────────────
                _buildFieldLabel('Harga Sewa Bulanan (Rp)'),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('kos_form_price_field'),
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: 850000',
                    prefixText: 'Rp ',
                    prefixIcon: Icon(Icons.payments_outlined, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Harga sewa bulanan wajib diisi';
                    }
                    final parsed = int.tryParse(value.trim());
                    if (parsed == null) {
                      return 'Harga sewa harus berupa angka valid';
                    }
                    if (parsed < 0) {
                      return 'Harga sewa tidak boleh bernilai negatif';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // ── 6. Jumlah Kamar Tersedia ──────────────────────────────────
                _buildFieldLabel('Jumlah Kamar Tersedia'),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('kos_form_rooms_field'),
                  controller: _roomsController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: 3',
                    prefixIcon: Icon(Icons.meeting_room_outlined, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Jumlah kamar tersedia wajib diisi';
                    }
                    final parsed = int.tryParse(value.trim());
                    if (parsed == null) {
                      return 'Jumlah kamar harus berupa bilangan bulat';
                    }
                    if (parsed < 0) {
                      return 'Jumlah kamar tidak boleh bernilai negatif';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 22),

                // ── 7. Fasilitas Pilihan Tetap (Checkbox) ─────────────────────
                _buildFieldLabel('Fasilitas Kos (Pilihan Tetap)'),
                const SizedBox(height: 6),
                Material(
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          key: const Key('kos_form_wifi_checkbox'),
                          value: _hasWifi,
                          onChanged: (val) {
                            setState(() {
                              _hasWifi = val ?? false;
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
                          secondary: const Icon(
                            Icons.wifi,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppColors.primary,
                        ),
                        const Divider(height: 1),
                        CheckboxListTile(
                          key: const Key('kos_form_bathroom_checkbox'),
                          value: _hasBathroomInside,
                          onChanged: (val) {
                            setState(() {
                              _hasBathroomInside = val ?? false;
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
                          secondary: const Icon(
                            Icons.bathtub_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppColors.primary,
                        ),
                        const Divider(height: 1),
                        CheckboxListTile(
                          key: const Key('kos_form_parking_checkbox'),
                          value: _hasParking,
                          onChanged: (val) {
                            setState(() {
                              _hasParking = val ?? false;
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
                          secondary: const Icon(
                            Icons.local_parking_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ── 8. Deskripsi Kos ─────────────────────────────────────────
                _buildFieldLabel('Deskripsi Kos'),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('kos_form_description_field'),
                  controller: _descriptionController,
                  maxLines: 4,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: 'Jelaskan fasilitas, lingkungan sekitar, dan ketentuan kos secara jelas...',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Deskripsi kos wajib diisi';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // ── 9. Tombol Simpan ─────────────────────────────────────────
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    key: const Key('btn_save_kos'),
                    onPressed: kosProvider.isLoadingCrud ? null : _submitForm,
                    child: kosProvider.isLoadingCrud
                        ? const SizedBox(
                            key: Key('kos_form_loading_indicator'),
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Text(isEditMode ? 'Simpan Perubahan' : 'Simpan Kos'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}
