import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/providers/auth_provider.dart';
import 'package:kosfinder/repositories/auth_repository.dart';
import 'package:kosfinder/screens/login_screen.dart';
import 'package:kosfinder/screens/register_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockRegisterAuthRepository extends AuthRepository {
  Exception? errorToThrow;
  Completer<User>? registerCompleter;
  int registerCallCount = 0;
  String? lastEmailPassed;
  String? lastPasswordPassed;

  @override
  User? get currentUser => null;

  @override
  bool get isAuthenticated => false;

  @override
  Future<User> register({
    required String email,
    required String password,
  }) async {
    registerCallCount++;
    lastEmailPassed = email;
    lastPasswordPassed = password;

    if (registerCompleter != null) {
      return registerCompleter!.future;
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return User.fromJson({
      'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
      'aud': 'authenticated',
      'created_at': '2026-11-16T10:00:00.000Z',
      'email': email,
    })!;
  }
}

void main() {
  group('RegisterScreen Widget Tests', () {
    late MockRegisterAuthRepository mockRepository;
    late AuthProvider authProvider;

    setUp(() {
      mockRepository = MockRegisterAuthRepository();
      authProvider = AuthProvider(repository: mockRepository);
    });

    Widget createScreenUnderTest() {
      return ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider,
        child: const MaterialApp(home: RegisterScreen()),
      );
    }

    testWidgets(
      '1. Halaman registrasi berhasil ditampilkan dengan judul dan deskripsi',
      (tester) async {
        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Daftar Akun Pemilik'), findsOneWidget);
        expect(
          find.text(
            'Daftarkan akun pemilik untuk mulai mempublikasikan dan mengelola ketersediaan kamar kos Anda.',
          ),
          findsOneWidget,
        );
        expect(find.byKey(const Key('btn_register')), findsOneWidget);
      },
    );

    testWidgets(
      '2. Form hanya memiliki 2 input (email dan password) tanpa nama atau telepon',
      (tester) async {
        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        // Memastikan hanya ada dua TextFormField
        expect(find.byType(TextFormField), findsNWidgets(2));
        expect(find.byKey(const Key('register_email_field')), findsOneWidget);
        expect(
          find.byKey(const Key('register_password_field')),
          findsOneWidget,
        );

        // Memastikan tidak ada field nama lengkap atau nomor telepon
        expect(find.text('Nama Lengkap'), findsNothing);
        expect(find.text('Nomor Telepon'), findsNothing);
        expect(find.text('Nomor WhatsApp'), findsNothing);
      },
    );

    testWidgets(
      '3. Submit form kosong menampilkan pesan validasi lokal yang sesuai',
      (tester) async {
        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('btn_register')));
        await tester.pumpAndSettle();

        expect(find.text('Email tidak boleh kosong'), findsOneWidget);
        expect(find.text('Kata sandi tidak boleh kosong'), findsOneWidget);
        expect(mockRepository.registerCallCount, 0);
      },
    );

    testWidgets('4. Email dengan format tidak valid ditolak', (tester) async {
      await tester.pumpWidget(createScreenUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('register_email_field')),
        'emailtidaksah',
      );
      await tester.enterText(
        find.byKey(const Key('register_password_field')),
        'password123',
      );
      await tester.tap(find.byKey(const Key('btn_register')));
      await tester.pumpAndSettle();

      expect(find.text('Format email tidak valid'), findsOneWidget);
      expect(mockRepository.registerCallCount, 0);
    });

    testWidgets('5. Password kurang dari 6 karakter ditolak', (tester) async {
      await tester.pumpWidget(createScreenUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('register_email_field')),
        'pemilik@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('register_password_field')),
        '12345',
      );
      await tester.tap(find.byKey(const Key('btn_register')));
      await tester.pumpAndSettle();

      expect(find.text('Kata sandi minimal 6 karakter'), findsOneWidget);
      expect(mockRepository.registerCallCount, 0);
    });

    testWidgets(
      '6. Tombol tampil/sembunyikan password berfungsi dengan benar',
      (tester) async {
        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        // Status awal: password tersamarkan (obscureText = true)
        TextField passwordField = tester.widget<TextField>(
          find.descendant(
            of: find.byKey(const Key('register_password_field')),
            matching: find.byType(TextField),
          ),
        );
        expect(passwordField.obscureText, isTrue);

        // Ketuk tombol toggle visibilitas
        await tester.tap(find.byKey(const Key('register_password_toggle')));
        await tester.pumpAndSettle();

        // Status berubah: password terlihat (obscureText = false)
        passwordField = tester.widget<TextField>(
          find.descendant(
            of: find.byKey(const Key('register_password_field')),
            matching: find.byType(TextField),
          ),
        );
        expect(passwordField.obscureText, isFalse);

        // Ketuk kembali tombol toggle visibilitas
        await tester.tap(find.byKey(const Key('register_password_toggle')));
        await tester.pumpAndSettle();

        passwordField = tester.widget<TextField>(
          find.descendant(
            of: find.byKey(const Key('register_password_field')),
            matching: find.byType(TextField),
          ),
        );
        expect(passwordField.obscureText, isTrue);
      },
    );

    testWidgets(
      '7 & 8. Registrasi berhasil mengarahkan pengguna ke LoginScreen dengan pesan sukses',
      (tester) async {
        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('register_email_field')),
          'pemilik@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('register_password_field')),
          'password123',
        );

        await tester.tap(find.byKey(const Key('btn_register')));
        await tester.pumpAndSettle();

        // Berpindah ke LoginScreen
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(RegisterScreen), findsNothing);

        // Memastikan pesan sukses tampil di LoginScreen
        expect(
          find.text(
            'Pendaftaran berhasil. Silakan masuk menggunakan akun Anda.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '9. Registrasi gagal karena email duplikat menampilkan pesan error',
      (tester) async {
        mockRepository.errorToThrow = const AuthRepoException(
          'Email sudah terdaftar. Silakan gunakan email lain atau masuk ke akun Anda.',
        );

        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('register_email_field')),
          'terdaftar@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('register_password_field')),
          'password123',
        );

        await tester.tap(find.byKey(const Key('btn_register')));
        await tester.pumpAndSettle();

        // Layar tetap di RegisterScreen
        expect(find.byType(RegisterScreen), findsOneWidget);
        expect(find.byType(LoginScreen), findsNothing);

        // Pesan error muncul
        expect(
          find.text(
            'Email sudah terdaftar. Silakan gunakan email lain atau masuk ke akun Anda.',
          ),
          findsWidgets, // muncul di banner dan/atau snackbar
        );
      },
    );

    testWidgets(
      '10. Registrasi gagal karena gangguan jaringan menampilkan pesan error',
      (tester) async {
        mockRepository.errorToThrow = const AuthRepoException(
          'Gagal terhubung ke server autentikasi. Silakan periksa koneksi internet Anda.',
          SocketException('No connection'),
        );

        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('register_email_field')),
          'offline@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('register_password_field')),
          'password123',
        );

        await tester.tap(find.byKey(const Key('btn_register')));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Gagal terhubung ke server autentikasi. Silakan periksa koneksi internet Anda.',
          ),
          findsWidgets,
        );
      },
    );

    testWidgets(
      '11. Isian email dan password tetap tersedia setelah registrasi gagal (NFR03)',
      (tester) async {
        mockRepository.errorToThrow = const AuthRepoException(
          'Gagal terhubung ke server autentikasi. Silakan periksa koneksi internet Anda.',
        );

        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('register_email_field')),
          'tetapada@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('register_password_field')),
          'passwordAman123',
        );

        await tester.tap(find.byKey(const Key('btn_register')));
        await tester.pumpAndSettle();

        // Verifikasi isian tidak terhapus
        final emailField = tester.widget<TextField>(
          find.descendant(
            of: find.byKey(const Key('register_email_field')),
            matching: find.byType(TextField),
          ),
        );
        final passwordField = tester.widget<TextField>(
          find.descendant(
            of: find.byKey(const Key('register_password_field')),
            matching: find.byType(TextField),
          ),
        );

        expect(emailField.controller?.text, 'tetapada@example.com');
        expect(passwordField.controller?.text, 'passwordAman123');
      },
    );

    testWidgets(
      '12. Tombol Daftar tidak dapat diklik berulang saat proses loading berlangsung',
      (tester) async {
        final completer = Completer<User>();
        mockRepository.registerCompleter = completer;

        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('register_email_field')),
          'loading@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('register_password_field')),
          'password123',
        );

        // Ketuk pertama kali untuk memulai registrasi
        await tester.tap(find.byKey(const Key('btn_register')));
        await tester.pump(); // Render state loading

        // Memastikan indikator loading aktif dan tombol disable (onPressed null)
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        final elevatedButton = tester.widget<ElevatedButton>(
          find.byKey(const Key('btn_register')),
        );
        expect(elevatedButton.onPressed, isNull);

        // Mencoba ketukan kedua kali saat masih loading
        await tester.tap(find.byKey(const Key('btn_register')));
        await tester.pump();

        // Jumlah pemanggilan repository tetap 1
        expect(mockRepository.registerCallCount, 1);

        // Selesaikan proses registrasi
        completer.complete(
          User.fromJson({
            'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
            'app_metadata': <String, dynamic>{},
            'user_metadata': <String, dynamic>{},
            'aud': 'authenticated',
            'created_at': '2026-11-16T10:00:00.000Z',
            'email': 'loading@example.com',
          })!,
        );
        await tester.pumpAndSettle();

        expect(find.byType(LoginScreen), findsOneWidget);
      },
    );

    testWidgets('13. Ketuk tautan Masuk mengarahkan pengguna ke LoginScreen', (
      tester,
    ) async {
      await tester.pumpWidget(createScreenUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Masuk'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(RegisterScreen), findsNothing);
    });
  });
}
