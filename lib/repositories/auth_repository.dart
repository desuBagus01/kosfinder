import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_auth_service.dart';

/// Exception khusus untuk menangani kesalahan operasional pada repositori autentikasi.
/// Menyediakan pesan kesalahan terstandar yang ramah dan aman bagi pengguna.
class AuthRepoException implements Exception {
  final String message;
  final dynamic originalError;

  const AuthRepoException(this.message, [this.originalError]);

  @override
  String toString() => message;
}

/// Alias untuk kemudahan penulisan dan kompatibilitas
typedef KosAuthException = AuthRepoException;

/// Repositori untuk manajemen autentikasi pemilik kos.
/// Berperan sebagai lapisan abstraksi antara [SupabaseAuthService] dan Provider/State Management.
/// Bertugas mengelola alur registrasi, login, logout, dan status sesi pengguna aktif,
/// serta memvalidasi data masukan secara aman tanpa menyimpan kata sandi.
///
/// Selaras dengan dokumen arsitektur (Subbab 1.1 - Repository Layer).
/// Memenuhi FR07, FR08, FR09, US05, AC05-1, AC05-2, AC05-3, AC05-4, AC05-5, AC05-6, NFR01, dan NFR02.
class AuthRepository {
  final SupabaseAuthService _service;

  AuthRepository({SupabaseAuthService? authService})
    : _service = authService ?? SupabaseAuthService();

  /// Mengambil data pengguna ([User]) yang sedang login saat ini.
  /// Mengembalikan `null` jika pengguna belum login atau sesi telah berakhir.
  User? get currentUser => _service.currentUser;

  /// Memeriksa apakah ada sesi login pengguna yang sedang aktif.
  bool get isAuthenticated => currentUser != null;

  /// Mengambil sesi aktif pengguna ([Session]) jika tersedia.
  Session? get currentSession => _service.currentSession;

  /// Mendaftarkan akun pemilik baru menggunakan email dan kata sandi.
  ///
  /// Memvalidasi format email dan panjang kata sandi sebelum mengirim request ke backend.
  /// Mengembalikan objek [User] dari Supabase Auth jika registrasi berhasil.
  /// Melempar [AuthRepoException] dengan pesan ramah pengguna jika validasi gagal,
  /// email telah terdaftar sebelumnya, atau terjadi gangguan koneksi.
  ///
  /// Memenuhi FR07, US05, AC05-1, AC05-2, AC05-6, dan NFR01.
  Future<User> register({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();

    // 1. Validasi lokal input email
    if (trimmedEmail.isEmpty) {
      throw const AuthRepoException('Email tidak boleh kosong');
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(trimmedEmail)) {
      throw const AuthRepoException('Format email tidak valid');
    }

    // 2. Validasi lokal input kata sandi
    if (password.isEmpty) {
      throw const AuthRepoException('Kata sandi tidak boleh kosong');
    }
    if (password.length < 6) {
      throw const AuthRepoException('Kata sandi minimal 6 karakter');
    }

    // 3. Eksekusi registrasi via service
    try {
      final response = await _service.signUp(
        email: trimmedEmail,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw const AuthRepoException(
          'Pendaftaran akun gagal: data pengguna tidak diterima dari server.',
        );
      }
      return user;
    } on SocketException catch (e) {
      throw AuthRepoException(
        'Gagal terhubung ke server autentikasi. Silakan periksa koneksi internet Anda.',
        e,
      );
    } on TimeoutException catch (e) {
      throw AuthRepoException(
        'Koneksi waktu habis saat menghubungi server autentikasi. Silakan coba kembali.',
        e,
      );
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('already registered') ||
          msg.contains('user already exists') ||
          msg.contains('already in use')) {
        throw AuthRepoException(
          'Email sudah terdaftar. Silakan gunakan email lain atau masuk ke akun Anda.',
          e,
        );
      }
      throw AuthRepoException(e.message, e);
    } on AuthRepoException {
      rethrow;
    } catch (e) {
      throw AuthRepoException('Terjadi kesalahan saat pendaftaran akun: $e', e);
    }
  }

  /// Masuk ke akun pemilik menggunakan email dan kata sandi yang valid.
  ///
  /// Mengembalikan objek [User] jika kredensial valid.
  /// Melempar [AuthRepoException] dengan pesan terstandar:
  /// *"Email atau kata sandi yang Anda masukkan salah"* jika kredensial tidak cocok (AC05-4).
  ///
  /// Memenuhi FR08, US05, AC05-3, AC05-4, AC05-6, dan NFR01.
  Future<User> login({required String email, required String password}) async {
    final trimmedEmail = email.trim();

    // 1. Validasi lokal kelengkapan input
    if (trimmedEmail.isEmpty || password.isEmpty) {
      throw const AuthRepoException('Email dan kata sandi tidak boleh kosong');
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(trimmedEmail)) {
      throw const AuthRepoException('Format email tidak valid');
    }

    // 2. Eksekusi login via service
    try {
      final response = await _service.signInWithPassword(
        email: trimmedEmail,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw const AuthRepoException(
          'Gagal masuk: data pengguna tidak diterima dari server.',
        );
      }
      return user;
    } on SocketException catch (e) {
      throw AuthRepoException(
        'Gagal terhubung ke server autentikasi. Silakan periksa koneksi internet Anda.',
        e,
      );
    } on TimeoutException catch (e) {
      throw AuthRepoException(
        'Koneksi waktu habis saat menghubungi server autentikasi. Silakan coba kembali.',
        e,
      );
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      // Standarisasi error kredensial salah sesuai AC05-4
      if (msg.contains('invalid login credentials') ||
          msg.contains('invalid_credentials') ||
          msg.contains('invalid credential') ||
          msg.contains('invalid email or password') ||
          msg.contains('user not found') ||
          msg.contains('wrong password') ||
          e.statusCode == '400') {
        throw AuthRepoException(
          'Email atau kata sandi yang Anda masukkan salah',
          e,
        );
      }
      throw AuthRepoException(e.message, e);
    } on AuthRepoException {
      rethrow;
    } catch (e) {
      throw AuthRepoException('Terjadi kesalahan saat masuk ke akun: $e', e);
    }
  }

  /// Keluar dari akun pemilik kos dan menghapus sesi aktif.
  ///
  /// Memenuhi FR09, US05, AC05-5, dan NFR01.
  Future<void> logout() async {
    try {
      await _service.signOut();
    } on SocketException catch (e) {
      throw AuthRepoException(
        'Gagal terhubung ke server autentikasi. Silakan periksa koneksi internet Anda.',
        e,
      );
    } on TimeoutException catch (e) {
      throw AuthRepoException(
        'Koneksi waktu habis saat menghubungi server autentikasi. Silakan coba kembali.',
        e,
      );
    } on AuthException catch (e) {
      throw AuthRepoException(e.message, e);
    } on AuthRepoException {
      rethrow;
    } catch (e) {
      throw AuthRepoException('Terjadi kesalahan saat keluar akun: $e', e);
    }
  }

  /// Alias untuk register ([signUp])
  Future<User> signUp({required String email, required String password}) =>
      register(email: email, password: password);

  /// Alias untuk login ([signInWithPassword])
  Future<User> signInWithPassword({
    required String email,
    required String password,
  }) => login(email: email, password: password);

  /// Alias untuk logout ([signOut])
  Future<void> signOut() => logout();
}
