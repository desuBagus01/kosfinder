import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/providers/auth_provider.dart';
import 'package:kosfinder/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mock implementasi [AuthRepository] untuk menguji [AuthProvider] secara terisolasi.
class MockAuthRepository extends AuthRepository {
  User? mockCurrentUser;
  Exception? errorToThrow;
  Completer<User>? loginCompleter;
  Completer<User>? registerCompleter;
  Completer<void>? logoutCompleter;
  int loginCallCount = 0;
  int registerCallCount = 0;
  int logoutCallCount = 0;
  String? lastEmail;
  String? lastPassword;

  @override
  User? get currentUser => mockCurrentUser;

  @override
  bool get isAuthenticated => mockCurrentUser != null;

  @override
  Future<User> login({required String email, required String password}) async {
    loginCallCount++;
    lastEmail = email;
    lastPassword = password;
    if (loginCompleter != null) {
      return loginCompleter!.future;
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    mockCurrentUser = User.fromJson({
      'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
      'aud': 'authenticated',
      'created_at': '2026-11-16T10:00:00.000Z',
      'email': email,
    });
    return mockCurrentUser!;
  }

  @override
  Future<User> register({
    required String email,
    required String password,
  }) async {
    registerCallCount++;
    lastEmail = email;
    lastPassword = password;
    if (registerCompleter != null) {
      return registerCompleter!.future;
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    mockCurrentUser = User.fromJson({
      'id': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
      'aud': 'authenticated',
      'created_at': '2026-11-16T10:00:00.000Z',
      'email': email,
    });
    return mockCurrentUser!;
  }

  @override
  Future<void> logout() async {
    logoutCallCount++;
    if (logoutCompleter != null) {
      return logoutCompleter!.future;
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    mockCurrentUser = null;
  }
}

void main() {
  group('AuthProvider Unit Tests', () {
    late MockAuthRepository mockRepository;
    late AuthProvider authProvider;

    setUp(() {
      mockRepository = MockAuthRepository();
      authProvider = AuthProvider(repository: mockRepository);
    });

    // ── 1 & 2. Inisialisasi Provider ───────────────────────────────────────
    test('1. Inisialisasi Provider ketika belum login menghasilkan state awal yang bersih', () {
      expect(authProvider.currentUser, isNull);
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.isLoading, isFalse);
      expect(authProvider.errorMessage, isNull);
    });

    test(
      '2. Inisialisasi Provider ketika pengguna sudah login memuat currentUser',
      () {
        final existingUser = User.fromJson({
          'id': '11111111-1111-1111-1111-111111111111',
          'app_metadata': <String, dynamic>{},
          'user_metadata': <String, dynamic>{},
          'aud': 'authenticated',
          'created_at': '2026-11-16T10:00:00.000Z',
          'email': 'sudahlogin@example.com',
        });
        mockRepository.mockCurrentUser = existingUser;

        final providerWithSession = AuthProvider(repository: mockRepository);

        expect(providerWithSession.currentUser, isNotNull);
        expect(
          providerWithSession.currentUser?.email,
          'sudahlogin@example.com',
        );
        expect(providerWithSession.isAuthenticated, isTrue);
        expect(providerWithSession.isLoading, isFalse);
        expect(providerWithSession.errorMessage, isNull);
      },
    );

    // ── 3, 4, 5, 6. Alur Login ─────────────────────────────────────────────
    test('3 & 4. Login berhasil memperbarui currentUser dan isAuthenticated menjadi true', () async {
      int notifyCount = 0;
      authProvider.addListener(() => notifyCount++);

      final success = await authProvider.login(
        'pemilik@example.com',
        'password123',
      );

      expect(success, isTrue);
      expect(authProvider.currentUser, isNotNull);
      expect(authProvider.currentUser?.email, 'pemilik@example.com');
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.isLoading, isFalse);
      expect(authProvider.errorMessage, isNull);
      expect(
        notifyCount,
        greaterThanOrEqualTo(2),
      ); // minimal: loading true, lalu loading false
    });

    test('5 & 6. Login gagal menetapkan errorMessage dan mengembalikan isLoading ke false', () async {
      mockRepository.errorToThrow = const AuthRepoException(
        'Email atau kata sandi yang Anda masukkan salah',
      );

      int notifyCount = 0;
      authProvider.addListener(() => notifyCount++);

      final success = await authProvider.login(
        'pemilik@example.com',
        'passwordsalah',
      );

      expect(success, isFalse);
      expect(authProvider.currentUser, isNull);
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.isLoading, isFalse);
      expect(
        authProvider.errorMessage,
        'Email atau kata sandi yang Anda masukkan salah',
      );
      expect(notifyCount, greaterThanOrEqualTo(2));
    });

    test('Transisi isLoading terpantau true selama proses login asynchronous berlangsung', () async {
      final completer = Completer<User>();
      mockRepository.loginCompleter = completer;

      expect(authProvider.isLoading, isFalse);

      final loginFuture = authProvider.login(
        'pemilik@example.com',
        'password123',
      );

      // Sesaat setelah dipanggil, loading harus true
      expect(authProvider.isLoading, isTrue);

      completer.complete(
        User.fromJson({
          'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          'app_metadata': <String, dynamic>{},
          'user_metadata': <String, dynamic>{},
          'aud': 'authenticated',
          'created_at': '2026-11-16T10:00:00.000Z',
          'email': 'pemilik@example.com',
        }),
      );

      await loginFuture;

      expect(authProvider.isLoading, isFalse);
    });

    // ── 7 & 8. Alur Registrasi ─────────────────────────────────────────────
    test('7. Registrasi berhasil mengembalikan isLoading ke false dan errorMessage null', () async {
      final success = await authProvider.register(
        'baru@example.com',
        'password123',
      );

      expect(success, isTrue);
      expect(authProvider.isLoading, isFalse);
      expect(authProvider.errorMessage, isNull);
      expect(mockRepository.registerCallCount, 1);
    });

    test('8. Registrasi gagal menampilkan pesan error dan mengembalikan isLoading ke false', () async {
      mockRepository.errorToThrow = const AuthRepoException(
        'Email sudah terdaftar. Silakan gunakan email lain atau masuk ke akun Anda.',
      );

      final success = await authProvider.register(
        'duplikat@example.com',
        'password123',
      );

      expect(success, isFalse);
      expect(authProvider.isLoading, isFalse);
      expect(authProvider.errorMessage, contains('Email sudah terdaftar'));
    });

    // ── 9, 10, 11. Alur Logout ─────────────────────────────────────────────
    test('9 & 10. Logout berhasil menghapus currentUser dan mengubah isAuthenticated ke false', () async {
      // Login terlebih dahulu
      await authProvider.login('pemilik@example.com', 'password123');
      expect(authProvider.isAuthenticated, isTrue);

      final logoutSuccess = await authProvider.logout();

      expect(logoutSuccess, isTrue);
      expect(authProvider.currentUser, isNull);
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.isLoading, isFalse);
      expect(authProvider.errorMessage, isNull);
      expect(mockRepository.logoutCallCount, 1);
    });

    test('11. Logout gagal ditangani tanpa membuat aplikasi crash', () async {
      await authProvider.login('pemilik@example.com', 'password123');

      mockRepository.errorToThrow = const AuthRepoException(
        'Gagal keluar dari sesi akun',
      );

      final logoutSuccess = await authProvider.logout();

      expect(logoutSuccess, isFalse);
      expect(authProvider.isLoading, isFalse);
      expect(authProvider.errorMessage, 'Gagal keluar dari sesi akun');
    });

    // ── 12. clearError ─────────────────────────────────────────────────────
    test('12. clearError menghapus pesan kesalahan yang aktif', () async {
      mockRepository.errorToThrow = const AuthRepoException('Error percobaan');
      await authProvider.login('test@example.com', 'password123');

      expect(authProvider.errorMessage, 'Error percobaan');

      int notifyCount = 0;
      authProvider.addListener(() => notifyCount++);

      authProvider.clearError();

      expect(authProvider.errorMessage, isNull);
      expect(notifyCount, 1);
    });

    // ── 13. refreshCurrentUser ─────────────────────────────────────────────
    test('13. refreshCurrentUser memperbarui status sesi dari repository', () {
      expect(authProvider.currentUser, isNull);

      final newUser = User.fromJson({
        'id': '99999999-9999-9999-9999-999999999999',
        'app_metadata': <String, dynamic>{},
        'user_metadata': <String, dynamic>{},
        'aud': 'authenticated',
        'created_at': '2026-11-16T10:00:00.000Z',
        'email': 'fresh@example.com',
      });
      mockRepository.mockCurrentUser = newUser;

      int notifyCount = 0;
      authProvider.addListener(() => notifyCount++);

      authProvider.refreshCurrentUser();

      expect(authProvider.currentUser?.email, 'fresh@example.com');
      expect(authProvider.isAuthenticated, isTrue);
      expect(notifyCount, 1);
    });

    // ── 14. Penanganan Error Jaringan (NFR03 & AC05-6) ──────────────────────
    test(
      '14. Penanganan kegagalan jaringan saat autentikasi tidak membuat crash',
      () async {
        mockRepository.errorToThrow = const AuthRepoException(
          'Gagal terhubung ke server autentikasi. Silakan periksa koneksi internet Anda.',
          SocketException('No connection'),
        );

        final loginSuccess = await authProvider.login(
          'pemilik@example.com',
          'password123',
        );

        expect(loginSuccess, isFalse);
        expect(authProvider.isLoading, isFalse);
        expect(
          authProvider.errorMessage,
          contains('Gagal terhubung ke server autentikasi'),
        );
      },
    );
  });
}
