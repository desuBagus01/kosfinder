import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/repositories/auth_repository.dart';
import 'package:kosfinder/services/supabase_auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fake implementation dari [SupabaseAuthService] untuk unit test tanpa backend sungguhan.
class FakeSupabaseAuthService extends SupabaseAuthService {
  User? mockCurrentUser;
  Session? mockCurrentSession;
  Exception? errorToThrow;
  int signUpCallCount = 0;
  int signInCallCount = 0;
  int signOutCallCount = 0;
  String? lastEmailPassed;
  String? lastPasswordPassed;

  @override
  User? get currentUser => mockCurrentUser;

  @override
  Session? get currentSession => mockCurrentSession;

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    signUpCallCount++;
    lastEmailPassed = email;
    lastPasswordPassed = password;

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

    return AuthResponse(user: mockCurrentUser);
  }

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    signInCallCount++;
    lastEmailPassed = email;
    lastPasswordPassed = password;

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

    return AuthResponse(user: mockCurrentUser);
  }

  @override
  Future<void> signOut() async {
    signOutCallCount++;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    mockCurrentUser = null;
    mockCurrentSession = null;
  }
}

void main() {
  group('AuthRepository Unit Tests', () {
    late FakeSupabaseAuthService fakeService;
    late AuthRepository authRepository;

    setUp(() {
      fakeService = FakeSupabaseAuthService();
      authRepository = AuthRepository(authService: fakeService);
    });

    // ── 1. Registrasi Berhasil ─────────────────────────────────────────────
    test(
      '1. Registrasi berhasil mengembalikan data User yang sesuai (AC05-1)',
      () async {
        final user = await authRepository.register(
          email: 'pemilik@example.com',
          password: 'password123',
        );

        expect(user.id, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');
        expect(user.email, 'pemilik@example.com');
        expect(fakeService.signUpCallCount, 1);
        expect(fakeService.lastEmailPassed, 'pemilik@example.com');
        expect(fakeService.lastPasswordPassed, 'password123');
      },
    );

    // ── 2. Registrasi Gagal (Validasi & Duplikasi) ──────────────────────────
    test(
      '2.1 Registrasi gagal jika format email kosong atau tidak valid (AC05-2)',
      () async {
        // Email kosong
        expect(
          () => authRepository.register(email: '', password: 'password123'),
          throwsA(
            isA<AuthRepoException>().having(
              (e) => e.message,
              'message',
              'Email tidak boleh kosong',
            ),
          ),
        );

        // Email tidak ada domain / format salah
        expect(
          () => authRepository.register(
            email: 'bukanemail',
            password: 'password123',
          ),
          throwsA(
            isA<AuthRepoException>().having(
              (e) => e.message,
              'message',
              'Format email tidak valid',
            ),
          ),
        );

        expect(fakeService.signUpCallCount, 0);
      },
    );

    test(
      '2.2 Registrasi gagal jika kata sandi kosong atau kurang dari 6 karakter',
      () async {
        // Password kosong
        expect(
          () =>
              authRepository.register(email: 'user@example.com', password: ''),
          throwsA(
            isA<AuthRepoException>().having(
              (e) => e.message,
              'message',
              'Kata sandi tidak boleh kosong',
            ),
          ),
        );

        // Password < 6 karakter
        expect(
          () => authRepository.register(
            email: 'user@example.com',
            password: '123',
          ),
          throwsA(
            isA<AuthRepoException>().having(
              (e) => e.message,
              'message',
              'Kata sandi minimal 6 karakter',
            ),
          ),
        );

        expect(fakeService.signUpCallCount, 0);
      },
    );

    test('2.3 Registrasi gagal dengan pesan ramah saat email sudah terdaftar sebelumnya (AC05-2)', () async {
      fakeService.errorToThrow = const AuthException(
        'User already registered',
        statusCode: '400',
      );

      expect(
        () => authRepository.register(
          email: 'terdaftar@example.com',
          password: 'password123',
        ),
        throwsA(
          isA<AuthRepoException>().having(
            (e) => e.message,
            'message',
            contains('Email sudah terdaftar'),
          ),
        ),
      );
    });

    // ── 3. Login Berhasil ──────────────────────────────────────────────────
    test(
      '3. Login berhasil mengembalikan data User dan membuka sesi (AC05-3)',
      () async {
        final user = await authRepository.login(
          email: 'pemilik@example.com',
          password: 'password123',
        );

        expect(user.id, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');
        expect(user.email, 'pemilik@example.com');
        expect(fakeService.signInCallCount, 1);
        expect(authRepository.isAuthenticated, isTrue);
      },
    );

    // ── 4. Login Gagal Karena Kredensial Salah ──────────────────────────────
    test('4. Login gagal karena kredensial salah menghasilkan pesan aman terstandar (AC05-4)', () async {
      fakeService.errorToThrow = const AuthException(
        'Invalid login credentials',
        statusCode: '400',
      );

      expect(
        () => authRepository.login(
          email: 'pemilik@example.com',
          password: 'passwordsalah',
        ),
        throwsA(
          isA<AuthRepoException>().having(
            (e) => e.message,
            'message',
            'Email atau kata sandi yang Anda masukkan salah',
          ),
        ),
      );
    });

    test('4.1 Login gagal jika email atau password kosong', () async {
      expect(
        () => authRepository.login(email: '', password: '123'),
        throwsA(
          isA<AuthRepoException>().having(
            (e) => e.message,
            'message',
            'Email dan kata sandi tidak boleh kosong',
          ),
        ),
      );
    });

    // ── 5. Logout Berhasil ─────────────────────────────────────────────────
    test('5. Logout berhasil menghapus sesi login pengguna (AC05-5)', () async {
      // Set kondisi login
      fakeService.mockCurrentUser = User.fromJson({
        'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'app_metadata': <String, dynamic>{},
        'user_metadata': <String, dynamic>{},
        'aud': 'authenticated',
        'created_at': '2026-11-16T10:00:00.000Z',
        'email': 'pemilik@example.com',
      });
      expect(authRepository.isAuthenticated, isTrue);

      await authRepository.logout();

      expect(fakeService.signOutCallCount, 1);
      expect(authRepository.currentUser, isNull);
      expect(authRepository.isAuthenticated, isFalse);
    });

    // ── 6 & 7. Pemeriksaan currentUser ─────────────────────────────────────
    test('6. Mengambil currentUser ketika pengguna sudah login mengembalikan data User', () {
      fakeService.mockCurrentUser = User.fromJson({
        'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'app_metadata': <String, dynamic>{},
        'user_metadata': <String, dynamic>{},
        'aud': 'authenticated',
        'created_at': '2026-11-16T10:00:00.000Z',
        'email': 'pemilik@example.com',
      });

      final user = authRepository.currentUser;
      expect(user, isNotNull);
      expect(user!.email, 'pemilik@example.com');
      expect(authRepository.isAuthenticated, isTrue);
    });

    test('7. currentUser bernilai null ketika pengguna belum login', () {
      fakeService.mockCurrentUser = null;

      expect(authRepository.currentUser, isNull);
      expect(authRepository.isAuthenticated, isFalse);
    });

    // ── 8. Penanganan Error Jaringan dan Supabase (AC05-6) ──────────────────
    test('8.1 Penanganan SocketException saat login menghasilkan pesan koneksi terstandar (AC05-6)', () async {
      fakeService.errorToThrow = const SocketException('Network unreachable');

      expect(
        () => authRepository.login(
          email: 'pemilik@example.com',
          password: 'password123',
        ),
        throwsA(
          isA<AuthRepoException>().having(
            (e) => e.message,
            'message',
            contains('Gagal terhubung ke server autentikasi'),
          ),
        ),
      );
    });

    test('8.2 Penanganan TimeoutException saat registrasi menghasilkan pesan timeout (AC05-6)', () async {
      fakeService.errorToThrow = TimeoutException('Connection timed out');

      expect(
        () => authRepository.register(
          email: 'pemilik@example.com',
          password: 'password123',
        ),
        throwsA(
          isA<AuthRepoException>().having(
            (e) => e.message,
            'message',
            contains('Koneksi waktu habis'),
          ),
        ),
      );
    });

    test('8.3 Penanganan error tak terduga dibungkus dengan rapi ke AuthRepoException', () async {
      fakeService.errorToThrow = Exception('Internal server glitch');

      expect(
        () => authRepository.register(
          email: 'pemilik@example.com',
          password: 'password123',
        ),
        throwsA(isA<AuthRepoException>()),
      );
    });

    test('8.4 Method alias (signUp, signInWithPassword, signOut) berfungsi identik', () async {
      final user = await authRepository.signUp(
        email: 'alias@example.com',
        password: 'password123',
      );
      expect(user.email, 'alias@example.com');

      final userLogin = await authRepository.signInWithPassword(
        email: 'alias@example.com',
        password: 'password123',
      );
      expect(userLogin.email, 'alias@example.com');

      await authRepository.signOut();
      expect(authRepository.currentUser, isNull);
    });
  });
}
