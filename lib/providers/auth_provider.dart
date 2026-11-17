import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/auth_repository.dart';

/// Provider untuk mengelola status autentikasi dan sesi pemilik kos.
/// Berperan sebagai penghubung antara UI (Login/Register/Owner Screens) dan Data ([AuthRepository])
/// sesuai pola arsitektur Screen - Provider - Repository - Service.
///
/// Memenuhi FR07, FR08, FR09, US05, AC05-1, AC05-3, AC05-4, AC05-5, AC05-6, NFR01, NFR02, dan NFR03.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({AuthRepository? repository})
    : _repository = repository ?? AuthRepository() {
    // Inisialisasi status sesi saat ini dari repository
    try {
      _currentUser = _repository.currentUser;
    } catch (_) {
      _currentUser = null;
    }
  }

  /// Data pengguna yang sedang terautentikasi / login saat ini.
  /// Bernilai `null` jika pengguna belum login atau sesi telah berakhir.
  User? get currentUser => _currentUser;

  /// Status apakah ada pemilik kos yang sedang login aktif.
  bool get isAuthenticated => _currentUser != null;

  /// Status apakah sedang ada proses autentikasi (login, register, atau logout) berlangsung.
  bool get isLoading => _isLoading;

  /// Pesan kesalahan yang terjadi selama proses autentikasi, atau `null` jika tidak ada error.
  String? get errorMessage => _errorMessage;

  /// Melakukan login pemilik kos menggunakan [email] dan [password].
  ///
  /// Memperbarui [currentUser] dan [isAuthenticated] menjadi `true` jika berhasil.
  /// Menangkap [AuthRepoException] dan galat lainnya tanpa membuat aplikasi crash,
  /// serta menyimpan pesan ramah pengguna pada [errorMessage].
  ///
  /// Sesuai NFR03, Provider tidak mengelola isian form login sehingga input pengguna
  /// pada UI tetap terjaga dan tidak hilang saat terjadi kesalahan jaringan.
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _repository.login(email: email, password: password);
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Mendaftarkan akun pemilik kos baru menggunakan [email] dan [password].
  ///
  /// Menjaga [isLoading] aktif selama proses pendaftaran.
  /// Menangkap [AuthRepoException] dan menyimpan pesan pada [errorMessage] jika gagal.
  Future<bool> register(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.register(email: email, password: password);
      // Sinkronkan status pengguna jika registrasi langsung membuat sesi
      _currentUser = _repository.currentUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Melakukan logout akun pemilik kos dan menghapus sesi aktif.
  ///
  /// Mengatur [currentUser] kembali menjadi `null` dan [isAuthenticated] menjadi `false`.
  Future<bool> logout() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.logout();
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Menghapus pesan kesalahan aktif saat ini.
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Menyegarkan status pengguna saat ini langsung dari [AuthRepository].
  void refreshCurrentUser() {
    final freshUser = _repository.currentUser;
    if (_currentUser?.id != freshUser?.id ||
        _currentUser?.email != freshUser?.email) {
      _currentUser = freshUser;
      notifyListeners();
    } else {
      _currentUser = freshUser;
    }
  }
}
