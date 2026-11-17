import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos_model.dart';
import 'package:kosfinder/providers/auth_provider.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/repositories/auth_repository.dart';
import 'package:kosfinder/repositories/kos_repository.dart';
import 'package:kosfinder/screens/kos_form_screen.dart';
import 'package:kosfinder/screens/owner_kos_screen.dart';
import 'package:kosfinder/widgets/owner_kos_card_widget.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockUpdateDeleteAuthRepository extends AuthRepository {
  User? mockUser;
  int logoutCallCount = 0;

  @override
  User? get currentUser => mockUser;

  @override
  bool get isAuthenticated => mockUser != null;

  @override
  Future<void> logout() async {
    logoutCallCount++;
    mockUser = null;
  }
}

class MockUpdateDeleteKosRepository extends KosRepository {
  List<KosModel> mockOwnerKos = [];
  Exception? errorToThrow;
  Completer<KosModel>? updateCompleter;
  Completer<void>? deleteCompleter;
  int updateCallCount = 0;
  int deleteCallCount = 0;
  KosModel? lastUpdatedKos;
  String? lastDeletedId;

  /// ID pengguna aktif untuk pengujian otorisasi kepemilikan (RLS)
  String? currentUserId;

  @override
  Future<List<KosModel>> getKosList() async => mockOwnerKos;

  @override
  Future<List<KosModel>> getOwnerKosList([String? ownerId]) async =>
      mockOwnerKos;

  @override
  Future<KosModel> updateKos(KosModel kos) async {
    updateCallCount++;
    lastUpdatedKos = kos;

    // Simulasi penegakan keamanan RLS: Pemilik B ditolak mengubah kos milik Pemilik A
    if (currentUserId != null && kos.ownerId != currentUserId) {
      throw const KosException(
        'Akses ditolak: Anda tidak memiliki izin untuk mengubah kos ini.',
      );
    }

    if (updateCompleter != null) {
      return updateCompleter!.future;
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return kos;
  }

  @override
  Future<void> deleteKos(String id) async {
    deleteCallCount++;
    lastDeletedId = id;

    // Cari kos yang akan dihapus
    final targetKos = mockOwnerKos.firstWhere(
      (k) => k.id == id,
      orElse: () => KosModel(
        id: id,
        ownerId: 'owner-uuid-1234',
        name: 'Target Kos',
        address: 'Alamat',
        area: 'Area',
        contactNumber: '081',
        pricePerMonth: 500000,
        description: 'Desc',
        availableRooms: 1,
        hasWifi: false,
        hasBathroomInside: false,
        hasParking: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    // Simulasi penegakan keamanan RLS: Pemilik B ditolak menghapus kos milik Pemilik A
    if (currentUserId != null && targetKos.ownerId != currentUserId) {
      throw const KosException(
        'Akses ditolak: Anda tidak memiliki izin untuk menghapus kos ini.',
      );
    }

    if (deleteCompleter != null) {
      return deleteCompleter!.future;
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    mockOwnerKos.removeWhere((k) => k.id == id);
  }
}

void main() {
  final sampleOwnerA = User.fromJson({
    'id': 'owner-uuid-1234',
    'app_metadata': <String, dynamic>{},
    'user_metadata': <String, dynamic>{},
    'aud': 'authenticated',
    'created_at': '2026-11-16T10:00:00.000Z',
    'email': 'pemilik.a@kos.com',
  })!;

  final sampleOwnerB = User.fromJson({
    'id': 'owner-uuid-5678',
    'app_metadata': <String, dynamic>{},
    'user_metadata': <String, dynamic>{},
    'aud': 'authenticated',
    'created_at': '2026-11-16T10:00:00.000Z',
    'email': 'pemilik.b@kos.com',
  })!;

  final sampleKosA = KosModel(
    id: 'kos-uuid-0001',
    ownerId: 'owner-uuid-1234',
    name: 'Kos Melati Singaraja',
    address: 'Jl. Udayana No. 11',
    area: 'Banyuasri',
    contactNumber: '081234567890',
    pricePerMonth: 850000,
    description: 'Kos nyaman dan bersih dekat kampus Undiksha.',
    availableRooms: 3,
    hasWifi: true,
    hasBathroomInside: true,
    hasParking: false,
    createdAt: DateTime.parse('2026-11-16T10:00:00.000Z'),
    updatedAt: DateTime.parse('2026-11-16T10:00:00.000Z'),
  );

  group('TASK-4.4: KosUpdateDelete Widget & RLS Tests', () {
    late MockUpdateDeleteAuthRepository mockAuthRepository;
    late MockUpdateDeleteKosRepository mockKosRepository;
    late AuthProvider authProvider;
    late KosProvider kosProvider;

    setUp(() {
      mockAuthRepository = MockUpdateDeleteAuthRepository();
      mockAuthRepository.mockUser = sampleOwnerA; // Default: Pemilik A login
      mockKosRepository = MockUpdateDeleteKosRepository();
      mockKosRepository.currentUserId = sampleOwnerA.id;
      mockKosRepository.mockOwnerKos = [sampleKosA];

      authProvider = AuthProvider(repository: mockAuthRepository);
      kosProvider = KosProvider(repository: mockKosRepository);
    });

    Widget createScreenUnderTest({Widget? child, WidgetTester? tester}) {
      if (tester != null) {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
      }
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<KosProvider>.value(value: kosProvider),
        ],
        child: MaterialApp(home: child ?? KosFormScreen(kos: sampleKosA)),
      );
    }

    testWidgets(
      '1. Form edit menampilkan seluruh field dengan data kos yang sudah terisi',
      (tester) async {
        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        // Verifikasi AppBar mode ubah
        expect(find.text('Ubah Kos'), findsOneWidget);

        // Verifikasi seluruh field terisi data awal kos
        expect(find.text('Kos Melati Singaraja'), findsOneWidget);
        expect(find.text('Jl. Udayana No. 11'), findsOneWidget);
        expect(find.text('Banyuasri'), findsOneWidget);
        expect(find.text('081234567890'), findsOneWidget);
        expect(find.text('850000'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        expect(
          find.text('Kos nyaman dan bersih dekat kampus Undiksha.'),
          findsOneWidget,
        );

        // Verifikasi tombol submit bertuliskan Simpan Perubahan
        expect(find.text('Simpan Perubahan'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Pengguna dapat mengubah harga kos dan menyimpan perubahan',
      (tester) async {
        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        final priceField = find.byKey(const Key('kos_form_price_field'));
        await tester.enterText(priceField, '950000');

        final saveBtn = find.byKey(const Key('btn_save_kos'));
        await tester.scrollUntilVisible(
          saveBtn,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        // Verifikasi repository dipanggil untuk updateKos
        expect(mockKosRepository.updateCallCount, 1);
        expect(mockKosRepository.lastUpdatedKos?.pricePerMonth, 950000);
        expect(find.text('Data kos berhasil diperbarui!'), findsOneWidget);
      },
    );

    testWidgets(
      '3. Pengguna dapat mengubah nomor kontak dan menyimpan perubahan',
      (tester) async {
        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        final contactField = find.byKey(const Key('kos_form_contact_field'));
        await tester.enterText(contactField, '089912345678');

        final saveBtn = find.byKey(const Key('btn_save_kos'));
        await tester.scrollUntilVisible(
          saveBtn,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        expect(mockKosRepository.updateCallCount, 1);
        expect(mockKosRepository.lastUpdatedKos?.contactNumber, '089912345678');
        expect(find.text('Data kos berhasil diperbarui!'), findsOneWidget);
      },
    );

    testWidgets(
      '4. Data terbaru berhasil dikirim melalui KosProvider.updateKos()',
      (tester) async {
        await tester.pumpWidget(createScreenUnderTest(tester: tester));
        await tester.pumpAndSettle();

        // Modifikasi seluruh field
        await tester.enterText(
          find.byKey(const Key('kos_form_name_field')),
          'Kos Melati Indah Baru',
        );
        await tester.enterText(
          find.byKey(const Key('kos_form_address_field')),
          'Jl. Udayana No. 99',
        );
        await tester.enterText(
          find.byKey(const Key('kos_form_area_field')),
          'Singaraja Tengah',
        );
        await tester.enterText(
          find.byKey(const Key('kos_form_contact_field')),
          '081987654321',
        );
        await tester.enterText(
          find.byKey(const Key('kos_form_price_field')),
          '1100000',
        );
        await tester.enterText(
          find.byKey(const Key('kos_form_rooms_field')),
          '5',
        );

        // Toggle checkbox parkir
        final parkingCheckbox = find.byKey(
          const Key('kos_form_parking_checkbox'),
        );
        await tester.ensureVisible(parkingCheckbox);
        await tester.tap(parkingCheckbox);

        await tester.enterText(
          find.byKey(const Key('kos_form_description_field')),
          'Deskripsi kos yang telah diperbarui.',
        );

        final saveBtn = find.byKey(const Key('btn_save_kos'));
        await tester.scrollUntilVisible(
          saveBtn,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        expect(mockKosRepository.updateCallCount, 1);
        final updated = mockKosRepository.lastUpdatedKos;
        expect(updated, isNotNull);
        expect(updated!.id, sampleKosA.id);
        expect(updated.ownerId, sampleKosA.ownerId);
        expect(updated.name, 'Kos Melati Indah Baru');
        expect(updated.address, 'Jl. Udayana No. 99');
        expect(updated.area, 'Singaraja Tengah');
        expect(updated.contactNumber, '081987654321');
        expect(updated.pricePerMonth, 1100000);
        expect(updated.availableRooms, 5);
        expect(updated.hasParking, isTrue);
        expect(updated.description, 'Deskripsi kos yang telah diperbarui.');
      },
    );

    testWidgets('5. Loading mencegah submit berulang', (tester) async {
      final completer = Completer<KosModel>();
      mockKosRepository.updateCompleter = completer;

      await tester.pumpWidget(createScreenUnderTest());
      await tester.pumpAndSettle();

      final saveBtn = find.byKey(const Key('btn_save_kos'));
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();

      // Submit pertama
      await tester.tap(saveBtn);
      await tester.pump();

      // Loading aktif
      expect(
        find.byKey(const Key('kos_form_loading_indicator')),
        findsOneWidget,
      );
      expect(mockKosRepository.updateCallCount, 1);

      // Submit kedua saat masih loading
      await tester.tap(saveBtn, warnIfMissed: false);
      await tester.pump();
      expect(mockKosRepository.updateCallCount, 1);

      // Selesaikan request
      completer.complete(sampleKosA);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('kos_form_loading_indicator')), findsNothing);
    });

    testWidgets(
      '6. Kegagalan update menampilkan pesan error dan mempertahankan input',
      (tester) async {
        mockKosRepository.errorToThrow = const KosException(
          'Gagal memperbarui kos pada basis data.',
        );

        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        final priceField = find.byKey(const Key('kos_form_price_field'));
        await tester.enterText(priceField, '1200000');

        final saveBtn = find.byKey(const Key('btn_save_kos'));
        await tester.scrollUntilVisible(
          saveBtn,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        expect(mockKosRepository.updateCallCount, 1);
        expect(
          find.text('Gagal memperbarui kos pada basis data.'),
          findsWidgets,
        );
        // Input tetap bertahan
        expect(find.text('1200000'), findsOneWidget);
      },
    );

    testWidgets('7. Tombol edit membuka formulir mode edit', (tester) async {
      await tester.pumpWidget(
        createScreenUnderTest(child: const OwnerKosScreen()),
      );
      await tester.pumpAndSettle();

      final editBtn = find.byKey(Key('btn_edit_kos_${sampleKosA.id}'));
      expect(editBtn, findsOneWidget);

      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      // Formulir terbuka dalam mode edit
      expect(find.byType(KosFormScreen), findsOneWidget);
      expect(find.text('Ubah Kos'), findsOneWidget);
      expect(find.text('Kos Melati Singaraja'), findsOneWidget);
      expect(find.text('Simpan Perubahan'), findsOneWidget);
    });

    testWidgets(
      '8. Tombol hapus menampilkan dialog konfirmasi dengan nama kos yang benar',
      (tester) async {
        await tester.pumpWidget(
          createScreenUnderTest(child: const OwnerKosScreen()),
        );
        await tester.pumpAndSettle();

        final deleteBtn = find.byKey(Key('btn_delete_kos_${sampleKosA.id}'));
        expect(deleteBtn, findsOneWidget);

        await tester.tap(deleteBtn);
        await tester.pumpAndSettle();

        // Verifikasi dialog konfirmasi
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Hapus Kos'), findsOneWidget);
        expect(
          find.text(
            'Apakah Anda yakin ingin menghapus "Kos Melati Singaraja"? Data kos yang dihapus tidak dapat dipulihkan kembali.',
          ),
          findsOneWidget,
        );
        expect(find.byKey(const Key('btn_cancel_delete')), findsOneWidget);
        expect(find.byKey(const Key('btn_confirm_delete')), findsOneWidget);
      },
    );

    testWidgets('9. Tombol Batal tidak menghapus data', (tester) async {
      await tester.pumpWidget(
        createScreenUnderTest(child: const OwnerKosScreen()),
      );
      await tester.pumpAndSettle();

      final deleteBtn = find.byKey(Key('btn_delete_kos_${sampleKosA.id}'));
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Tekan tombol Batal
      final cancelBtn = find.byKey(const Key('btn_cancel_delete'));
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      // Dialog tertutup, repository tidak dipanggil
      expect(find.byType(AlertDialog), findsNothing);
      expect(mockKosRepository.deleteCallCount, 0);
      expect(find.byType(OwnerKosCardWidget), findsOneWidget);
      expect(find.text('Kos Melati Singaraja'), findsOneWidget);
    });

    testWidgets('10. Tombol Ya, Hapus memanggil KosProvider.deleteKos()', (
      tester,
    ) async {
      await tester.pumpWidget(
        createScreenUnderTest(child: const OwnerKosScreen()),
      );
      await tester.pumpAndSettle();

      final deleteBtn = find.byKey(Key('btn_delete_kos_${sampleKosA.id}'));
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Tekan tombol Ya, Hapus
      final confirmBtn = find.byKey(const Key('btn_confirm_delete'));
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(mockKosRepository.deleteCallCount, 1);
      expect(mockKosRepository.lastDeletedId, sampleKosA.id);
      expect(
        find.text('Kos "Kos Melati Singaraja" berhasil dihapus.'),
        findsOneWidget,
      );
    });

    testWidgets(
      '11. Data kos hilang dari daftar setelah penghapusan berhasil',
      (tester) async {
        await tester.pumpWidget(
          createScreenUnderTest(child: const OwnerKosScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Kos Melati Singaraja'), findsOneWidget);

        final deleteBtn = find.byKey(Key('btn_delete_kos_${sampleKosA.id}'));
        await tester.tap(deleteBtn);
        await tester.pumpAndSettle();

        final confirmBtn = find.byKey(const Key('btn_confirm_delete'));
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        // Kos terhapus dari daftar, empty state muncul
        expect(find.byType(OwnerKosCardWidget), findsNothing);
        expect(find.text('Kos Melati Singaraja'), findsNothing);
        expect(find.text('Belum Ada Kos'), findsOneWidget);
      },
    );

    testWidgets('12. Kegagalan penghapusan menampilkan pesan error', (
      tester,
    ) async {
      mockKosRepository.errorToThrow = const KosException(
        'Gagal menghapus kos dari server.',
      );

      await tester.pumpWidget(
        createScreenUnderTest(child: const OwnerKosScreen()),
      );
      await tester.pumpAndSettle();

      final deleteBtn = find.byKey(Key('btn_delete_kos_${sampleKosA.id}'));
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      final confirmBtn = find.byKey(const Key('btn_confirm_delete'));
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(mockKosRepository.deleteCallCount, 1);
      expect(find.text('Gagal menghapus kos dari server.'), findsWidgets);

      // Data kos tetap ada di daftar
      expect(find.text('Kos Melati Singaraja'), findsOneWidget);
    });

    testWidgets('13. Pastikan pesan placeholder TASK-4.4 sudah tidak muncul', (
      tester,
    ) async {
      await tester.pumpWidget(
        createScreenUnderTest(child: const OwnerKosScreen()),
      );
      await tester.pumpAndSettle();

      // Pastikan string placeholder TASK-4.4 tidak ada
      expect(find.textContaining('akan tersedia pada TASK-4.4'), findsNothing);

      final editBtn = find.byKey(Key('btn_edit_kos_${sampleKosA.id}'));
      await tester.tap(editBtn);
      await tester.pumpAndSettle();
      expect(find.textContaining('akan tersedia pada TASK-4.4'), findsNothing);

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop();
      await tester.pumpAndSettle();

      final deleteBtn = find.byKey(Key('btn_delete_kos_${sampleKosA.id}'));
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();
      expect(find.textContaining('akan tersedia pada TASK-4.4'), findsNothing);
    });

    testWidgets(
      '14. Pastikan operasi edit dan hapus tidak dapat dilakukan oleh pengguna yang tidak memiliki hak kepemilikan',
      (tester) async {
        // Simulasikan pengguna Pemilik B yang mencoba mengubah & menghapus kos milik Pemilik A
        mockAuthRepository.mockUser = sampleOwnerB;
        mockKosRepository.currentUserId = sampleOwnerB.id; // Pemilik B

        await tester.pumpWidget(createScreenUnderTest(tester: tester));
        await tester.pumpAndSettle();

        // 14a. Pemilik B mencoba update kos milik Pemilik A
        final saveBtn = find.byKey(const Key('btn_save_kos'));
        await tester.scrollUntilVisible(
          saveBtn,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        // Pembaruan ditolak oleh aturan hak akses / RLS
        expect(mockKosRepository.updateCallCount, 1);
        expect(
          find.text(
            'Akses ditolak: Anda tidak memiliki izin untuk mengubah kos ini.',
          ),
          findsWidgets,
        );

        // 14b. Pemilik B mencoba menghapus kos milik Pemilik A
        await tester.pumpWidget(
          createScreenUnderTest(child: const OwnerKosScreen(), tester: tester),
        );
        await tester.pumpAndSettle();

        final deleteBtn = find.byKey(Key('btn_delete_kos_${sampleKosA.id}'));
        await tester.tap(deleteBtn);
        await tester.pumpAndSettle();

        final confirmBtn = find.byKey(const Key('btn_confirm_delete'));
        await tester.tap(confirmBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Penghapusan ditolak oleh aturan hak akses / RLS
        expect(mockKosRepository.deleteCallCount, 1);
        expect(
          find.text(
            'Akses ditolak: Anda tidak memiliki izin untuk menghapus kos ini.',
          ),
          findsOneWidget,
        );
        await tester.pumpAndSettle();

        // Kos tetap utuh di daftar
        expect(find.text('Kos Melati Singaraja'), findsOneWidget);
      },
    );
  });
}
