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

class MockLoginAuthRepository extends AuthRepository {
  Exception? errorToThrow;
  Completer<User>? loginCompleter;
  int loginCallCount = 0;
  int logoutCallCount = 0;
  String? lastEmailPassed;
  String? lastPasswordPassed;
  User? mockCurrentUser;

  @override
  User? get currentUser => mockCurrentUser;

  @override
  bool get isAuthenticated => mockCurrentUser != null;

  @override
  Future<User> login({required String email, required String password}) async {
    loginCallCount++;
    lastEmailPassed = email;
    lastPasswordPassed = password;

    if (loginCompleter != null) {
      return loginCompleter!.future;
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    final user = User.fromJson({
      'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
      'aud': 'authenticated',
      'created_at': '2026-11-16T10:00:00.000Z',
      'email': email,
    })!;
    mockCurrentUser = user;
    return user;
  }

  @override
  Future<void> logout() async {
    logoutCallCount++;
    mockCurrentUser = null;
  }
}

class MockLoginKosRepository extends KosRepository {
  @override
  Future<List<KosModel>> getKosList() async => [];
}

void main() {
  group('LoginScreen Widget Tests (TASK-3.4)', () {
    late MockLoginAuthRepository mockAuthRepository;
    late MockLoginKosRepository mockKosRepository;
    late AuthProvider authProvider;
    late KosProvider kosProvider;

    setUp(() {
      mockAuthRepository = MockLoginAuthRepository();
      mockKosRepository = MockLoginKosRepository();
      authProvider = AuthProvider(repository: mockAuthRepository);
      kosProvider = KosProvider(repository: mockKosRepository);
    });

    Widget createScreenUnderTest({String? successMessage}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<KosProvider>.value(value: kosProvider),
        ],
        child: MaterialApp(home: LoginScreen(successMessage: successMessage)),
      );
    }

    testWidgets(
      '1. Halaman login menampilkan elemen lengkap: judul, deskripsi, form, tombol login, tombol kembali, dan tautan daftar',
      (tester) async {
        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Login Pemilik'), findsWidgets);
        expect(
          find.text(
            'Masuk menggunakan akun yang sudah didaftarkan untuk mengelola publikasi dan ketersediaan kos Anda.',
          ),
          findsOneWidget,
        );
        expect(find.byKey(const Key('login_email_field')), findsOneWidget);
        expect(find.byKey(const Key('login_password_field')), findsOneWidget);
        expect(find.byKey(const Key('btn_login')), findsOneWidget);
        expect(find.text('Masuk'), findsWidgets);
        expect(find.byKey(const Key('btn_nav_register')), findsOneWidget);
        expect(find.text('Daftar'), findsOneWidget);
        expect(find.byKey(const Key('btn_back_to_kos_list')), findsOneWidget);
      },
    );

    testWidgets(
      '2. Banner sukses registrasi ditampilkan jika successMessage diberikan',
      (tester) async {
        const message =
            'Pendaftaran berhasil. Silakan masuk menggunakan akun Anda.';
        await tester.pumpWidget(createScreenUnderTest(successMessage: message));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('login_success_banner')), findsOneWidget);
        expect(find.text(message), findsOneWidget);
      },
    );

    testWidgets(
      '3. Fitur toggle tampilkan/sembunyikan kata sandi berfungsi dengan baik',
      (tester) async {
        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        // Cari widget password field
        final passwordFinder = find.byKey(const Key('login_password_field'));
        TextField textField = tester.widget<TextField>(
          find.descendant(of: passwordFinder, matching: find.byType(TextField)),
        );
        expect(textField.obscureText, isTrue);

        // Ketuk tombol toggle visibility
        await tester.tap(find.byKey(const Key('login_password_toggle')));
        await tester.pumpAndSettle();

        textField = tester.widget<TextField>(
          find.descendant(of: passwordFinder, matching: find.byType(TextField)),
        );
        expect(textField.obscureText, isFalse);

        // Ketuk kembali untuk menyembunyikan
        await tester.tap(find.byKey(const Key('login_password_toggle')));
        await tester.pumpAndSettle();

        textField = tester.widget<TextField>(
          find.descendant(of: passwordFinder, matching: find.byType(TextField)),
        );
        expect(textField.obscureText, isTrue);
      },
    );

    testWidgets(
      '4. Validasi email kosong menampilkan pesan kesalahan spesifik',
      (tester) async {
        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        // Kosongkan email, isi password
        await tester.enterText(
          find.byKey(const Key('login_password_field')),
          'password123',
        );
        await tester.tap(find.byKey(const Key('btn_login')));
        await tester.pumpAndSettle();

        expect(find.text('Email tidak boleh kosong'), findsOneWidget);
        expect(mockAuthRepository.loginCallCount, 0);
      },
    );

    testWidgets(
      '5. Validasi format email tidak valid menampilkan pesan kesalahan',
      (tester) async {
        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('login_email_field')),
          'bukan-email-valid',
        );
        await tester.enterText(
          find.byKey(const Key('login_password_field')),
          'password123',
        );
        await tester.tap(find.byKey(const Key('btn_login')));
        await tester.pumpAndSettle();

        expect(find.text('Format email tidak valid'), findsOneWidget);
        expect(mockAuthRepository.loginCallCount, 0);
      },
    );

    testWidgets(
      '6. Validasi password kosong menampilkan pesan kesalahan spesifik',
      (tester) async {
        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('login_email_field')),
          'pemilik@kos.com',
        );
        await tester.tap(find.byKey(const Key('btn_login')));
        await tester.pumpAndSettle();

        expect(find.text('Kata sandi tidak boleh kosong'), findsOneWidget);
        expect(mockAuthRepository.loginCallCount, 0);
      },
    );

    testWidgets(
      '7. Login gagal: menampilkan pesan kesalahan dan form input tetap utuh (NFR03)',
      (tester) async {
        mockAuthRepository.errorToThrow = const AuthRepoException(
          'Email atau kata sandi yang Anda masukkan salah',
        );

        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('login_email_field')),
          'salah@kos.com',
        );
        await tester.enterText(
          find.byKey(const Key('login_password_field')),
          'passwordsalah',
        );

        await tester.tap(find.byKey(const Key('btn_login')));
        await tester.pumpAndSettle();

        // Verifikasi login dipanggil satu kali
        expect(mockAuthRepository.loginCallCount, 1);

        // Verifikasi pesan kesalahan muncul di UI
        expect(
          find.text('Email atau kata sandi yang Anda masukkan salah'),
          findsWidgets,
        );

        // Verifikasi isian formulir tidak hilang (NFR03)
        expect(find.text('salah@kos.com'), findsOneWidget);
        expect(find.text('passwordsalah'), findsOneWidget);
      },
    );

    testWidgets(
      '8. Indikator loading muncul saat login berlangsung dan mencegah submit berulang',
      (tester) async {
        final completer = Completer<User>();
        mockAuthRepository.loginCompleter = completer;

        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('login_email_field')),
          'pemilik@kos.com',
        );
        await tester.enterText(
          find.byKey(const Key('login_password_field')),
          'password123',
        );

        // Submit pertama kali
        await tester.tap(find.byKey(const Key('btn_login')));
        await tester.pump();

        // Verifikasi indikator loading aktif
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(mockAuthRepository.loginCallCount, 1);

        // Coba ketuk tombol login kembali saat proses loading masih berjalan
        await tester.tap(
          find.byKey(const Key('btn_login')),
          warnIfMissed: false,
        );
        await tester.pump();

        // Jumlah panggilan harus tetap 1 (mencegah submit berulang)
        expect(mockAuthRepository.loginCallCount, 1);

        // Selesaikan future
        completer.complete(
          User.fromJson({
            'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
            'app_metadata': <String, dynamic>{},
            'user_metadata': <String, dynamic>{},
            'aud': 'authenticated',
            'created_at': '2026-11-16T10:00:00.000Z',
            'email': 'pemilik@kos.com',
          })!,
        );
        await tester.pumpAndSettle();

        // Loading selesai
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets(
      '9. Login berhasil: menampilkan konfirmasi autentikasi dan mengarahkan kembali ke daftar kos',
      (tester) async {
        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('login_email_field')),
          'pemilik@kos.com',
        );
        await tester.enterText(
          find.byKey(const Key('login_password_field')),
          'password123',
        );

        await tester.tap(find.byKey(const Key('btn_login')));
        await tester.pumpAndSettle();

        // Verifikasi repository dipanggil dengan email & password yang tepat
        expect(mockAuthRepository.loginCallCount, 1);
        expect(mockAuthRepository.lastEmailPassed, 'pemilik@kos.com');
        expect(mockAuthRepository.lastPasswordPassed, 'password123');

        // Verifikasi konfirmasi autentikasi berhasil (SnackBar)
        expect(
          find.text('Login berhasil. Selamat datang kembali!'),
          findsOneWidget,
        );

        // Verifikasi navigasi kembali ke KosListScreen
        expect(find.byType(KosListScreen), findsOneWidget);
        expect(find.text('KosFinder'), findsOneWidget);
      },
    );

    testWidgets(
      '10. Mengetuk tautan Daftar mengarahkan pengguna ke RegisterScreen',
      (tester) async {
        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('btn_nav_register')), findsOneWidget);
        await tester.tap(find.byKey(const Key('btn_nav_register')));
        await tester.pumpAndSettle();

        expect(find.byType(RegisterScreen), findsOneWidget);
        expect(find.text('Daftar Akun Pemilik'), findsOneWidget);
      },
    );

    testWidgets(
      '11. Mengetuk tombol Kembali ke Daftar Kos mengarahkan kembali ke KosListScreen',
      (tester) async {
        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        final backButton = find.byKey(const Key('btn_back_to_kos_list'));
        await tester.ensureVisible(backButton);
        await tester.pumpAndSettle();

        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        expect(find.byType(KosListScreen), findsOneWidget);
      },
    );

    testWidgets(
      '12. Mengetuk ikon tombol kembali di AppBar mengarahkan kembali ke KosListScreen',
      (tester) async {
        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        final appBarBackButton = find.byTooltip('Kembali');
        expect(appBarBackButton, findsOneWidget);
        await tester.tap(appBarBackButton);
        await tester.pumpAndSettle();

        expect(find.byType(KosListScreen), findsOneWidget);
      },
    );
  });
}
