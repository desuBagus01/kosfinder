import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Service untuk menangani interaksi teknis langsung dengan Supabase Auth
/// melalui Supabase Client untuk autentikasi pemilik kos.
///
/// Selaras dengan dokumen arsitektur (Subbab 1.1 - Service Layer dan Subbab 2.1).
/// Memenuhi FR07, FR08, FR09, US05, AC05-1, AC05-3, AC05-5, NFR01, dan NFR02.
class SupabaseAuthService {
  final SupabaseClient? client;

  SupabaseAuthService({this.client});

  /// Mengambil instance [SupabaseClient].
  /// Menggunakan client yang diinjeksi atau fallback ke [Supabase.instance.client].
  SupabaseClient get _supabaseClient => client ?? Supabase.instance.client;

  /// Mengambil data pengguna yang saat ini sedang login.
  /// Mengembalikan `null` jika tidak ada sesi login yang aktif atau client belum diinisialisasi.
  User? get currentUser {
    try {
      return _supabaseClient.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Mengambil data sesi pengguna yang saat ini sedang aktif.
  /// Mengembalikan `null` jika tidak ada sesi aktif atau client belum diinisialisasi.
  Session? get currentSession {
    try {
      return _supabaseClient.auth.currentSession;
    } catch (_) {
      return null;
    }
  }

  /// Mendaftarkan akun pemilik baru menggunakan email dan kata sandi.
  ///
  /// Melempar [AuthException] jika terjadi kesalahan autentikasi Supabase.
  /// Melempar [SocketException] atau [TimeoutException] jika terjadi gangguan koneksi jaringan.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } on AuthException {
      rethrow;
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } catch (e) {
      if (e is SocketException || e is TimeoutException) {
        rethrow;
      }
      throw Exception('Terjadi kesalahan pada layanan registrasi Supabase: $e');
    }
  }

  /// Masuk ke akun pemilik menggunakan email dan kata sandi.
  ///
  /// Melempar [AuthException] jika terjadi kesalahan autentikasi Supabase (misal kredensial salah).
  /// Melempar [SocketException] atau [TimeoutException] jika terjadi gangguan koneksi jaringan.
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException {
      rethrow;
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } catch (e) {
      if (e is SocketException || e is TimeoutException) {
        rethrow;
      }
      throw Exception('Terjadi kesalahan pada layanan login Supabase: $e');
    }
  }

  /// Keluar dari sesi login pemilik yang aktif dan menghapus token autentikasi.
  ///
  /// Melempar [AuthException] jika terjadi kesalahan pada Supabase Auth.
  /// Melempar [SocketException] atau [TimeoutException] jika terjadi gangguan koneksi jaringan.
  Future<void> signOut() async {
    try {
      await _supabaseClient.auth.signOut();
    } on AuthException {
      rethrow;
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } catch (e) {
      if (e is SocketException || e is TimeoutException) {
        rethrow;
      }
      throw Exception('Terjadi kesalahan pada layanan logout Supabase: $e');
    }
  }
}
