import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos_model.dart';
import 'package:kosfinder/providers/auth_provider.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/repositories/auth_repository.dart';
import 'package:kosfinder/repositories/kos_repository.dart';
import 'package:kosfinder/screens/kos_list_screen.dart';
import 'package:kosfinder/screens/login_screen.dart';
import 'package:kosfinder/screens/register_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mock repository untuk mengontrol data yang disajikan ke [KosProvider].
class MockKosRepository extends KosRepository {
  List<KosModel>? mockKosList;
  Exception? errorToThrow;
  Completer<List<KosModel>>? listCompleter;
  int getKosListCallCount = 0;

  @override
  Future<List<KosModel>> getKosList() async {
    getKosListCallCount++;
    if (listCompleter != null) {
      return listCompleter!.future;
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return mockKosList ?? [];
  }
}

class MockListAuthRepository extends AuthRepository {
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

void main() {
  group('KosListScreen Widget Tests', () {
    late MockKosRepository mockRepository;
    late MockListAuthRepository mockAuthRepository;
    late KosProvider kosProvider;
    late AuthProvider authProvider;

    final sampleKosList = [
      KosModel(
        id: '11111111-1111-1111-1111-111111111111',
        ownerId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
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
      ),
      KosModel(
        id: '22222222-2222-2222-2222-222222222222',
        ownerId: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
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
        createdAt: DateTime.parse('2026-11-16T11:00:00.000Z'),
        updatedAt: DateTime.parse('2026-11-16T11:00:00.000Z'),
      ),
    ];

    setUp(() {
      mockRepository = MockKosRepository();
      mockAuthRepository = MockListAuthRepository();
      kosProvider = KosProvider(repository: mockRepository);
      authProvider = AuthProvider(repository: mockAuthRepository);
    });

    Widget createWidgetUnderTest() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<KosProvider>.value(value: kosProvider),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ],
        child: const MaterialApp(home: KosListScreen()),
      );
    }

    testWidgets(
      '1. Menampilkan daftar kartu kos publik tanpa kewajiban login (AC01-1)',
      (tester) async {
        mockRepository.mockKosList = sampleKosList;

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Verifikasi judul AppBar
        expect(find.text('KosFinder'), findsOneWidget);

        // Verifikasi informasi pada kartu kos pertama
        expect(find.text('Kos Melati Singaraja'), findsOneWidget);
        expect(find.text('Banyuasri'), findsOneWidget);
        expect(find.text('Rp 850.000/bulan'), findsOneWidget);
        expect(find.text('Sisa 3 kamar'), findsOneWidget);

        // Verifikasi informasi pada kartu kos kedua (Kamar penuh)
        expect(find.text('Kos Kenanga Undiksha'), findsOneWidget);
        expect(find.text('Kaliuntu'), findsOneWidget);
        expect(find.text('Rp 1.200.000/bulan'), findsOneWidget);
        expect(find.text('Kamar Penuh'), findsOneWidget);

        // Pastikan tidak ada dialog login yang muncul atau menghalangi akses tamu
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.text('Login'), findsNothing);
      },
    );

    testWidgets(
      '2. Menampilkan status kosong informatif saat belum ada kos terdaftar (AC01-2)',
      (tester) async {
        mockRepository.mockKosList = [];

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Verifikasi pesan empty state
        expect(
          find.text('Belum ada kos yang terdaftar saat ini'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.home_work_outlined), findsOneWidget);
      },
    );

    testWidgets(
      '3. Menampilkan pesan error jaringan dan tombol Retry saat koneksi gagal (AC01-3)',
      (tester) async {
        mockRepository.errorToThrow = const KosException(
          'Gagal memuat data kos. Silakan periksa koneksi internet Anda.',
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Verifikasi tampilan error
        expect(
          find.text(
            'Gagal memuat data kos. Silakan periksa koneksi internet Anda.',
          ),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
        expect(
          find.widgetWithText(ElevatedButton, 'Coba Lagi'),
          findsOneWidget,
        );

        // Simulasi penekanan tombol Retry setelah koneksi pulih
        mockRepository.errorToThrow = null;
        mockRepository.mockKosList = sampleKosList;

        await tester.tap(find.widgetWithText(ElevatedButton, 'Coba Lagi'));
        await tester.pumpAndSettle();

        // Verifikasi data berhasil dimuat setelah Retry
        expect(find.text('Kos Melati Singaraja'), findsOneWidget);
        expect(
          find.text(
            'Gagal memuat data kos. Silakan periksa koneksi internet Anda.',
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      '4. Menampilkan indikator loading saat data sedang dimuat (NFR05)',
      (tester) async {
        final completer = Completer<List<KosModel>>();
        mockRepository.listCompleter = completer;

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump(); // Frame pertama saat loading aktif

        // Verifikasi indikator loading aktif
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Selesaikan future
        completer.complete(sampleKosList);
        await tester.pumpAndSettle();

        // Verifikasi indikator loading hilang dan kartu kos muncul
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Kos Melati Singaraja'), findsOneWidget);
      },
    );

    testWidgets(
      '5. Navigasi menuju halaman About menampilkan identitas mahasiswa (AGENTS.md)',
      (tester) async {
        mockRepository.mockKosList = sampleKosList;

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Cari ikon info di AppBar
        expect(find.byIcon(Icons.info_outline), findsOneWidget);

        // Ketuk tombol info
        await tester.tap(find.byIcon(Icons.info_outline));
        await tester.pumpAndSettle();

        // Verifikasi navigasi ke AboutPage dan verifikasi identitas baku
        expect(find.text('About'), findsOneWidget);
        expect(find.text('2415051014 - Gede Supadma'), findsOneWidget);
      },
    );

    testWidgets(
      '6. Mengetuk tombol Masuk pada AppBar mengarahkan ke LoginScreen dan dapat menuju RegisterScreen',
      (tester) async {
        mockRepository.mockKosList = sampleKosList;

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Cari tombol Masuk di AppBar
        expect(find.byKey(const Key('btn_nav_login')), findsOneWidget);
        expect(find.text('Masuk'), findsOneWidget);

        // Ketuk tombol Masuk
        await tester.tap(find.byKey(const Key('btn_nav_login')));
        await tester.pumpAndSettle();

        // Verifikasi berhasil navigasi ke LoginScreen
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.text('Login Pemilik'), findsWidgets);

        // Verifikasi tautan Daftar mengarah ke RegisterScreen
        expect(find.byKey(const Key('btn_nav_register')), findsOneWidget);
        await tester.tap(find.byKey(const Key('btn_nav_register')));
        await tester.pumpAndSettle();

        expect(find.byType(RegisterScreen), findsOneWidget);
        expect(find.text('Daftar Akun Pemilik'), findsOneWidget);
      },
    );

    testWidgets('7. Menampilkan tombol Masuk ketika pengguna belum login', (
      tester,
    ) async {
      mockRepository.mockKosList = sampleKosList;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_nav_login')), findsOneWidget);
      expect(find.text('Masuk'), findsOneWidget);
      expect(find.byKey(const Key('btn_nav_logout')), findsNothing);
    });

    testWidgets(
      '8. Tombol di AppBar berubah menjadi Keluar secara reaktif setelah login',
      (tester) async {
        mockRepository.mockKosList = sampleKosList;

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Awalnya menampilkan Masuk
        expect(find.byKey(const Key('btn_nav_login')), findsOneWidget);
        expect(find.byKey(const Key('btn_nav_logout')), findsNothing);

        // Simulasikan status login berhasil diperbarui pada AuthProvider
        mockAuthRepository.mockUser = User.fromJson({
          'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          'app_metadata': <String, dynamic>{},
          'user_metadata': <String, dynamic>{},
          'aud': 'authenticated',
          'created_at': '2026-11-16T10:00:00.000Z',
          'email': 'pemilik@kos.com',
        });
        authProvider.refreshCurrentUser();
        await tester.pumpAndSettle();

        // Tombol berubah menjadi Keluar
        expect(find.byKey(const Key('btn_nav_login')), findsNothing);
        expect(find.byKey(const Key('btn_nav_logout')), findsOneWidget);
        expect(find.text('Keluar'), findsOneWidget);
      },
    );

    testWidgets(
      '9. Mengetuk tombol Keluar menjalankan logout dan mengubah tombol kembali menjadi Masuk',
      (tester) async {
        mockRepository.mockKosList = sampleKosList;
        mockAuthRepository.mockUser = User.fromJson({
          'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          'app_metadata': <String, dynamic>{},
          'user_metadata': <String, dynamic>{},
          'aud': 'authenticated',
          'created_at': '2026-11-16T10:00:00.000Z',
          'email': 'pemilik@kos.com',
        });
        authProvider = AuthProvider(repository: mockAuthRepository);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Tombol saat ini adalah Keluar
        expect(find.byKey(const Key('btn_nav_logout')), findsOneWidget);
        expect(find.text('Keluar'), findsOneWidget);

        // Ketuk tombol Keluar
        await tester.tap(find.byKey(const Key('btn_nav_logout')));
        await tester.pumpAndSettle();

        // Verifikasi logout terpanggil pada repositori
        expect(mockAuthRepository.logoutCallCount, 1);
        expect(authProvider.isAuthenticated, isFalse);

        // Verifikasi notifikasi SnackBar muncul
        expect(find.text('Anda telah keluar.'), findsOneWidget);

        // Verifikasi tombol kembali menjadi Masuk
        expect(find.byKey(const Key('btn_nav_logout')), findsNothing);
        expect(find.byKey(const Key('btn_nav_login')), findsOneWidget);
        expect(find.text('Masuk'), findsOneWidget);
      },
    );
  });
}
