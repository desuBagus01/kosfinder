import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos_model.dart';
import 'package:kosfinder/providers/auth_provider.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/repositories/auth_repository.dart';
import 'package:kosfinder/repositories/kos_repository.dart';
import 'package:kosfinder/screens/kos_list_screen.dart';
import 'package:kosfinder/screens/owner_kos_screen.dart';
import 'package:kosfinder/widgets/owner_kos_card_widget.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockOwnerAuthRepository extends AuthRepository {
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

class MockOwnerKosRepository extends KosRepository {
  List<KosModel> mockOwnerKos = [];
  Exception? errorToThrow;
  Completer<List<KosModel>>? ownerListCompleter;
  int getOwnerListCallCount = 0;
  int deleteCallCount = 0;
  String? lastDeletedId;

  @override
  Future<List<KosModel>> getKosList() async => [];

  @override
  Future<List<KosModel>> getOwnerKosList([String? ownerId]) async {
    getOwnerListCallCount++;
    if (ownerListCompleter != null) {
      return ownerListCompleter!.future;
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return mockOwnerKos;
  }

  @override
  Future<void> deleteKos(String id) async {
    deleteCallCount++;
    lastDeletedId = id;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
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

  final sampleKosList = [
    KosModel(
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
    ),
    KosModel(
      id: 'kos-uuid-0002',
      ownerId: 'owner-uuid-1234',
      name: 'Kos Kenanga Undiksha',
      address: 'Jl. Sudirman No. 45',
      area: 'Kaliuntu',
      contactNumber: '081987654321',
      pricePerMonth: 1200000,
      description: 'Dekat kampus, fasilitas lengkap.',
      availableRooms: 0, // Kamar penuh
      hasWifi: true,
      hasBathroomInside: true,
      hasParking: true,
    ),
  ];

  group('TASK-4.2: OwnerKosScreen Widget Tests', () {
    late MockOwnerAuthRepository mockAuthRepository;
    late MockOwnerKosRepository mockKosRepository;
    late AuthProvider authProvider;
    late KosProvider kosProvider;

    setUp(() {
      mockAuthRepository = MockOwnerAuthRepository();
      mockKosRepository = MockOwnerKosRepository();
      authProvider = AuthProvider(repository: mockAuthRepository);
      kosProvider = KosProvider(repository: mockKosRepository);
    });

    Widget createScreenUnderTest() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<KosProvider>.value(value: kosProvider),
        ],
        child: const MaterialApp(home: OwnerKosScreen()),
      );
    }

    testWidgets(
      '1. Pengguna yang belum login tidak dapat mengakses halaman dashboard (Akses Dibatasi)',
      (tester) async {
        // mockUser is null -> belum login
        mockAuthRepository.mockUser = null;
        authProvider = AuthProvider(repository: mockAuthRepository);

        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Akses Dibatasi'), findsOneWidget);
        expect(
          find.text(
            'Anda harus masuk terlebih dahulu untuk mengakses halaman kelola kos.',
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('btn_auth_required_login')),
          findsOneWidget,
        );
        // Memastikan kartu kos dan tombol kelola tidak dirender
        expect(find.byType(OwnerKosCardWidget), findsNothing);
        expect(find.byKey(const Key('btn_add_kos')), findsNothing);
      },
    );

    testWidgets('2. Loading indicator tampil saat daftar kos sedang dimuat', (
      tester,
    ) async {
      mockAuthRepository.mockUser = sampleOwner;
      authProvider = AuthProvider(repository: mockAuthRepository);

      final completer = Completer<List<KosModel>>();
      mockKosRepository.ownerListCompleter = completer;

      await tester.pumpWidget(createScreenUnderTest());
      await tester.pump();

      // Verifikasi indikator loading aktif
      expect(find.byKey(const Key('owner_loading_indicator')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Selesaikan future
      completer.complete(sampleKosList);
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(OwnerKosCardWidget), findsNWidgets(2));
    });

    testWidgets(
      '3. Daftar kos milik pengguna berhasil ditampilkan dengan kartu lengkap',
      (tester) async {
        mockAuthRepository.mockUser = sampleOwner;
        authProvider = AuthProvider(repository: mockAuthRepository);
        mockKosRepository.mockOwnerKos = sampleKosList;

        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Kelola Kos Pemilik'), findsOneWidget);
        expect(find.byType(OwnerKosCardWidget), findsNWidgets(2));
        expect(find.text('Kos Melati Singaraja'), findsOneWidget);
        expect(find.text('Kos Kenanga Undiksha'), findsOneWidget);
        expect(find.text('Rp 850.000/bulan'), findsOneWidget);
        expect(find.text('Rp 1.200.000/bulan'), findsOneWidget);
        expect(find.text('Sisa 3 kamar'), findsOneWidget);
        expect(find.text('Kamar Penuh'), findsOneWidget);
      },
    );

    testWidgets(
      '4. Empty state tampil informatif jika pemilik belum memiliki kos',
      (tester) async {
        mockAuthRepository.mockUser = sampleOwner;
        authProvider = AuthProvider(repository: mockAuthRepository);
        mockKosRepository.mockOwnerKos = []; // Belum ada kos

        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Belum Ada Kos'), findsOneWidget);
        expect(
          find.text(
            'Anda belum mempublikasikan data kos. Mulai kelola ketersediaan kamar dan publikasikan kos Anda sekarang.',
          ),
          findsOneWidget,
        );
        expect(find.byKey(const Key('btn_add_kos_empty')), findsOneWidget);
        expect(find.byType(OwnerKosCardWidget), findsNothing);
      },
    );

    testWidgets(
      '5. Pesan error dan tombol Retry tampil ketika pengambilan data gagal',
      (tester) async {
        mockAuthRepository.mockUser = sampleOwner;
        authProvider = AuthProvider(repository: mockAuthRepository);
        mockKosRepository.errorToThrow = const KosException(
          'Gagal memuat data dari server.',
        );

        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Gagal Memuat Data'), findsOneWidget);
        expect(find.text('Gagal memuat data dari server.'), findsOneWidget);
        expect(find.byKey(const Key('btn_retry_owner_kos')), findsOneWidget);

        // Uji tombol Retry
        mockKosRepository.errorToThrow = null;
        mockKosRepository.mockOwnerKos = sampleKosList;

        await tester.tap(find.byKey(const Key('btn_retry_owner_kos')));
        await tester.pumpAndSettle();

        expect(find.byType(OwnerKosCardWidget), findsNWidgets(2));
        expect(find.text('Kos Melati Singaraja'), findsOneWidget);
      },
    );

    testWidgets('6. Tombol Tambah Kos tersedia pada halaman kelola kos', (
      tester,
    ) async {
      mockAuthRepository.mockUser = sampleOwner;
      authProvider = AuthProvider(repository: mockAuthRepository);
      mockKosRepository.mockOwnerKos = sampleKosList;

      await tester.pumpWidget(createScreenUnderTest());
      await tester.pumpAndSettle();

      final addBtn = find.byKey(const Key('btn_add_kos'));
      expect(addBtn, findsOneWidget);
      expect(find.text('Tambah Kos'), findsOneWidget);

      // Ketuk tombol Tambah Kos
      await tester.tap(addBtn);
      await tester.pump();

      expect(
        find.text('Formulir tambah kos akan tersedia pada TASK-4.3.'),
        findsOneWidget,
      );
    });

    testWidgets(
      '7. Tombol Edit dan Hapus tersedia pada setiap kartu kos dan dapat diklik',
      (tester) async {
        mockAuthRepository.mockUser = sampleOwner;
        authProvider = AuthProvider(repository: mockAuthRepository);
        mockKosRepository.mockOwnerKos = [sampleKosList.first];

        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        final editBtn = find.byKey(
          Key('btn_edit_kos_${sampleKosList.first.id}'),
        );
        final deleteBtn = find.byKey(
          Key('btn_delete_kos_${sampleKosList.first.id}'),
        );

        expect(editBtn, findsOneWidget);
        expect(deleteBtn, findsOneWidget);
        expect(find.text('Edit'), findsOneWidget);
        expect(find.text('Hapus'), findsOneWidget);

        // Ketuk Edit
        await tester.tap(editBtn);
        await tester.pump();
        expect(
          find.text(
            'Form ubah "Kos Melati Singaraja" akan tersedia pada TASK-4.4.',
          ),
          findsOneWidget,
        );

        // Ketuk Hapus
        await tester.tap(deleteBtn);
        await tester.pump();
        expect(mockKosRepository.deleteCallCount, 0);
        expect(
          find.text(
            'Konfirmasi hapus "Kos Melati Singaraja" akan tersedia pada TASK-4.4.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '8. Tombol Logout memanggil proses logout pada AuthProvider dan mengarahkan ke KosListScreen',
      (tester) async {
        mockAuthRepository.mockUser = sampleOwner;
        authProvider = AuthProvider(repository: mockAuthRepository);
        mockKosRepository.mockOwnerKos = sampleKosList;

        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        final logoutBtn = find.byKey(const Key('btn_owner_logout'));
        expect(logoutBtn, findsOneWidget);
        expect(find.text('Logout'), findsOneWidget);

        await tester.tap(logoutBtn);
        await tester.pumpAndSettle();

        expect(mockAuthRepository.logoutCallCount, 1);
        expect(authProvider.isAuthenticated, isFalse);
        expect(find.byType(KosListScreen), findsOneWidget);
      },
    );
  });
}
