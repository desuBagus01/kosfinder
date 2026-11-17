import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos_model.dart';
import 'package:kosfinder/providers/auth_provider.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/repositories/auth_repository.dart';
import 'package:kosfinder/repositories/kos_repository.dart';
import 'package:kosfinder/screens/kos_form_screen.dart';
import 'package:kosfinder/screens/login_screen.dart';
import 'package:kosfinder/screens/owner_kos_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockFormAuthRepository extends AuthRepository {
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

class MockFormKosRepository extends KosRepository {
  List<KosModel> mockOwnerKos = [];
  Exception? errorToThrow;
  Completer<KosModel>? createCompleter;
  int createCallCount = 0;
  KosModel? lastCreatedKos;

  @override
  Future<List<KosModel>> getKosList() async => [];

  @override
  Future<List<KosModel>> getOwnerKosList([String? ownerId]) async =>
      mockOwnerKos;

  @override
  Future<KosModel> createKos(KosModel kos) async {
    createCallCount++;
    lastCreatedKos = kos;
    if (createCompleter != null) {
      return createCompleter!.future;
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return kos;
  }
}

void main() {
  final sampleOwner = User.fromJson({
    'id': 'owner-uuid-1234',
    'app_metadata': <String, dynamic>{},
    'user_metadata': <String, dynamic>{},
    'aud': 'authenticated',
    'created_at': '2026-11-16T10:00:00.000Z',
    'email': 'pemilik@kos.com',
  })!;

  final sampleKos = KosModel(
    id: 'kos-uuid-0001',
    ownerId: 'owner-uuid-1234',
    name: 'Kos Melati Singaraja',
    address: 'Jl. Udayana No. 11',
    area: 'Banyuasri',
    contactNumber: '081234567890',
    pricePerMonth: 850000,
    description: 'Kos nyaman dan bersih.',
    availableRooms: 3,
    hasWifi: true,
    hasBathroomInside: true,
    hasParking: false,
    createdAt: DateTime.parse('2026-11-16T10:00:00.000Z'),
    updatedAt: DateTime.parse('2026-11-16T10:00:00.000Z'),
  );

  group('TASK-4.3: KosFormScreen Widget Tests (Mode Tambah Kos)', () {
    late MockFormAuthRepository mockAuthRepository;
    late MockFormKosRepository mockKosRepository;
    late AuthProvider authProvider;
    late KosProvider kosProvider;

    setUp(() {
      mockAuthRepository = MockFormAuthRepository();
      mockAuthRepository.mockUser = sampleOwner; // default: logged in
      mockKosRepository = MockFormKosRepository();
      authProvider = AuthProvider(repository: mockAuthRepository);
      kosProvider = KosProvider(repository: mockKosRepository);
    });

    Widget createScreenUnderTest({Widget? child}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<KosProvider>.value(value: kosProvider),
        ],
        child: MaterialApp(home: child ?? const KosFormScreen()),
      );
    }

    testWidgets('1. Formulir menampilkan seluruh field yang diwajibkan', (
      tester,
    ) async {
      await tester.pumpWidget(createScreenUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Tambah Kos Baru'), findsOneWidget);
      expect(find.byKey(const Key('kos_form_name_field')), findsOneWidget);
      expect(find.byKey(const Key('kos_form_address_field')), findsOneWidget);
      expect(find.byKey(const Key('kos_form_area_field')), findsOneWidget);
      expect(find.byKey(const Key('kos_form_contact_field')), findsOneWidget);
      expect(find.byKey(const Key('kos_form_price_field')), findsOneWidget);
      expect(find.byKey(const Key('kos_form_rooms_field')), findsOneWidget);
      expect(find.byKey(const Key('kos_form_wifi_checkbox')), findsOneWidget);
      expect(
        find.byKey(const Key('kos_form_bathroom_checkbox')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('kos_form_parking_checkbox')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('kos_form_description_field')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('btn_save_kos')), findsOneWidget);
    });

    testWidgets(
      '2. Submit dengan field wajib kosong menampilkan pesan validasi',
      (tester) async {
        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        final saveBtn = find.byKey(const Key('btn_save_kos'));
        await tester.ensureVisible(saveBtn);
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        expect(find.text('Nama kos wajib diisi'), findsOneWidget);
        expect(find.text('Alamat lengkap wajib diisi'), findsOneWidget);
        expect(find.text('Area kos wajib diisi'), findsOneWidget);
        expect(find.text('Nomor kontak wajib diisi'), findsOneWidget);
        expect(find.text('Harga sewa bulanan wajib diisi'), findsOneWidget);
        expect(find.text('Jumlah kamar tersedia wajib diisi'), findsOneWidget);
        expect(find.text('Deskripsi kos wajib diisi'), findsOneWidget);

        // Memastikan tidak ada pengiriman data ke repository
        expect(mockKosRepository.createCallCount, 0);
      },
    );

    testWidgets('3. Harga negatif ditolak dengan pesan validasi', (
      tester,
    ) async {
      await tester.pumpWidget(createScreenUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('kos_form_price_field')),
        '-500000',
      );

      final saveBtn = find.byKey(const Key('btn_save_kos'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Harga sewa tidak boleh bernilai negatif'),
        findsOneWidget,
      );
      expect(mockKosRepository.createCallCount, 0);
    });

    testWidgets('4. Harga bukan angka ditolak dengan pesan validasi', (
      tester,
    ) async {
      await tester.pumpWidget(createScreenUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('kos_form_price_field')),
        'delapanratus',
      );

      final saveBtn = find.byKey(const Key('btn_save_kos'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.text('Harga sewa harus berupa angka valid'), findsOneWidget);
      expect(mockKosRepository.createCallCount, 0);
    });

    testWidgets('5. Jumlah kamar negatif ditolak dengan pesan validasi', (
      tester,
    ) async {
      await tester.pumpWidget(createScreenUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('kos_form_rooms_field')),
        '-1',
      );

      final saveBtn = find.byKey(const Key('btn_save_kos'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Jumlah kamar tidak boleh bernilai negatif'),
        findsOneWidget,
      );
      expect(mockKosRepository.createCallCount, 0);
    });

    testWidgets(
      '6. Jumlah kamar bukan bilangan bulat ditolak dengan pesan validasi',
      (tester) async {
        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('kos_form_rooms_field')),
          'tiga',
        );

        final saveBtn = find.byKey(const Key('btn_save_kos'));
        await tester.ensureVisible(saveBtn);
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        expect(
          find.text('Jumlah kamar harus berupa bilangan bulat'),
          findsOneWidget,
        );
        expect(mockKosRepository.createCallCount, 0);
      },
    );

    testWidgets(
      '7. Data valid berhasil dikirim melalui KosProvider.createKos()',
      (tester) async {
        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        // Mengisi seluruh field wajib dengan data valid
        await tester.enterText(
          find.byKey(const Key('kos_form_name_field')),
          'Kos Singaraja Indah',
        );
        await tester.enterText(
          find.byKey(const Key('kos_form_address_field')),
          'Jl. Ngurah Rai No. 8',
        );
        await tester.enterText(
          find.byKey(const Key('kos_form_area_field')),
          'Singaraja Kota',
        );
        await tester.enterText(
          find.byKey(const Key('kos_form_contact_field')),
          '081298765432',
        );
        await tester.enterText(
          find.byKey(const Key('kos_form_price_field')),
          '950000',
        );
        await tester.enterText(
          find.byKey(const Key('kos_form_rooms_field')),
          '4',
        );

        // Centang fasilitas
        final wifiCheckbox = find.byKey(const Key('kos_form_wifi_checkbox'));
        await tester.ensureVisible(wifiCheckbox);
        await tester.tap(wifiCheckbox);

        final parkingCheckbox = find.byKey(
          const Key('kos_form_parking_checkbox'),
        );
        await tester.ensureVisible(parkingCheckbox);
        await tester.tap(parkingCheckbox);

        await tester.enterText(
          find.byKey(const Key('kos_form_description_field')),
          'Kos strategis dekat pusat kota dan kampus.',
        );

        // Submit form
        final saveBtn = find.byKey(const Key('btn_save_kos'));
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -400),
        );
        await tester.pumpAndSettle();
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        // Verifikasi pemanggilan repositori
        expect(mockKosRepository.createCallCount, 1);
        final created = mockKosRepository.lastCreatedKos;
        expect(created, isNotNull);
        expect(created!.name, 'Kos Singaraja Indah');
        expect(created.address, 'Jl. Ngurah Rai No. 8');
        expect(created.area, 'Singaraja Kota');
        expect(created.contactNumber, '081298765432');
        expect(created.pricePerMonth, 950000);
        expect(created.availableRooms, 4);
        expect(created.hasWifi, isTrue);
        expect(created.hasBathroomInside, isFalse);
        expect(created.hasParking, isTrue);
        expect(
          created.description,
          'Kos strategis dekat pusat kota dan kampus.',
        );

        // Verifikasi konfirmasi sukses SnackBar
        expect(find.text('Kos berhasil ditambahkan!'), findsOneWidget);
      },
    );

    testWidgets('8. Proses loading mencegah submit berulang', (tester) async {
      final completer = Completer<KosModel>();
      mockKosRepository.createCompleter = completer;

      await tester.pumpWidget(createScreenUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('kos_form_name_field')),
        'Kos Mawar',
      );
      await tester.enterText(
        find.byKey(const Key('kos_form_address_field')),
        'Jl. Mawar No. 1',
      );
      await tester.enterText(
        find.byKey(const Key('kos_form_area_field')),
        'Banyuasri',
      );
      await tester.enterText(
        find.byKey(const Key('kos_form_contact_field')),
        '081234567890',
      );
      await tester.enterText(
        find.byKey(const Key('kos_form_price_field')),
        '700000',
      );
      await tester.enterText(
        find.byKey(const Key('kos_form_rooms_field')),
        '2',
      );
      await tester.enterText(
        find.byKey(const Key('kos_form_description_field')),
        'Kos nyaman dan asri.',
      );

      final saveBtn = find.byKey(const Key('btn_save_kos'));
      await tester.ensureVisible(saveBtn);

      // Submit pertama
      await tester.tap(saveBtn);
      await tester.pump();

      // Verifikasi indikator loading aktif
      expect(
        find.byKey(const Key('kos_form_loading_indicator')),
        findsOneWidget,
      );
      expect(mockKosRepository.createCallCount, 1);

      // Tekan tombol lagi saat loading aktif
      await tester.tap(saveBtn, warnIfMissed: false);
      await tester.pump();

      // Call count harus tetap 1 (mencegah submit ganda)
      expect(mockKosRepository.createCallCount, 1);

      // Selesaikan future
      completer.complete(sampleKos);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('kos_form_loading_indicator')), findsNothing);
    });

    testWidgets(
      '9. Kegagalan penyimpanan menampilkan error dan mempertahankan input',
      (tester) async {
        mockKosRepository.errorToThrow = const KosException(
          'Gagal menambahkan kos ke server.',
        );

        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('kos_form_name_field')),
          'Kos Gagal Simpan',
        );
        await tester.enterText(
          find.byKey(const Key('kos_form_address_field')),
          'Jl. Kenanga No. 5',
        );
        await tester.enterText(
          find.byKey(const Key('kos_form_area_field')),
          'Kaliuntu',
        );
        await tester.enterText(
          find.byKey(const Key('kos_form_contact_field')),
          '081987654321',
        );
        await tester.enterText(
          find.byKey(const Key('kos_form_price_field')),
          '800000',
        );
        await tester.enterText(
          find.byKey(const Key('kos_form_rooms_field')),
          '1',
        );
        await tester.enterText(
          find.byKey(const Key('kos_form_description_field')),
          'Deskripsi yang tidak boleh hilang.',
        );

        final saveBtn = find.byKey(const Key('btn_save_kos'));
        await tester.ensureVisible(saveBtn);
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        // Verifikasi pemanggilan repositori
        expect(mockKosRepository.createCallCount, 1);

        // Verifikasi pesan kesalahan muncul di UI
        expect(find.text('Gagal menambahkan kos ke server.'), findsWidgets);

        // Verifikasi seluruh input tetap terjaga (NFR03)
        expect(find.text('Kos Gagal Simpan'), findsOneWidget);
        expect(find.text('Jl. Kenanga No. 5'), findsOneWidget);
        expect(find.text('Kaliuntu'), findsOneWidget);
        expect(find.text('081987654321'), findsOneWidget);
        expect(find.text('800000'), findsOneWidget);
        expect(find.text('1'), findsOneWidget);
        expect(find.text('Deskripsi yang tidak boleh hilang.'), findsOneWidget);
      },
    );

    testWidgets('10. Pengguna belum login tidak dapat menggunakan formulir', (
      tester,
    ) async {
      mockAuthRepository.mockUser = null; // Belum login
      authProvider = AuthProvider(repository: mockAuthRepository);

      await tester.pumpWidget(createScreenUnderTest());
      await tester.pumpAndSettle();

      // Pengguna diarahkan ke LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Login Pemilik'), findsWidgets);

      // Formulir dan tombol simpan tidak dapat diakses
      expect(find.byType(KosFormScreen), findsNothing);
      expect(find.byKey(const Key('kos_form_name_field')), findsNothing);
      expect(find.byKey(const Key('btn_save_kos')), findsNothing);
    });

    testWidgets('11. Tombol Tambah Kos pada OwnerKosScreen membuka formulir', (
      tester,
    ) async {
      mockKosRepository.mockOwnerKos = [sampleKos];

      await tester.pumpWidget(
        createScreenUnderTest(child: const OwnerKosScreen()),
      );
      await tester.pumpAndSettle();

      final addBtn = find.byKey(const Key('btn_add_kos'));
      expect(addBtn, findsOneWidget);

      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      // Verifikasi berhasil navigasi ke KosFormScreen
      expect(find.byType(KosFormScreen), findsOneWidget);
      expect(find.text('Tambah Kos Baru'), findsOneWidget);
      expect(find.byKey(const Key('btn_save_kos')), findsOneWidget);
    });

    testWidgets(
      '12. Tombol Tambah Kos pada empty state juga membuka formulir',
      (tester) async {
        mockKosRepository.mockOwnerKos = []; // Kosong

        await tester.pumpWidget(
          createScreenUnderTest(child: const OwnerKosScreen()),
        );
        await tester.pumpAndSettle();

        final addEmptyBtn = find.byKey(const Key('btn_add_kos_empty'));
        expect(addEmptyBtn, findsOneWidget);

        await tester.tap(addEmptyBtn);
        await tester.pumpAndSettle();

        // Verifikasi berhasil navigasi ke KosFormScreen
        expect(find.byType(KosFormScreen), findsOneWidget);
        expect(find.text('Tambah Kos Baru'), findsOneWidget);
        expect(find.byKey(const Key('btn_save_kos')), findsOneWidget);
      },
    );
  });
}
