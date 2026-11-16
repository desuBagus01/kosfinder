import 'package:flutter/foundation.dart';

import '../models/kos_model.dart';
import '../repositories/kos_repository.dart';

/// Provider untuk mengelola status publik aplikasi KosFinder.
/// Berperan sebagai penghubung antara UI (Screen) dan Data (KosRepository)
/// sesuai pola arsitektur Screen - Provider - Repository - Service.
class KosProvider extends ChangeNotifier {
  final KosRepository _repository;

  int _activeListRequests = 0;
  int _activeDetailRequests = 0;
  String? _errorMessage;
  List<KosModel> _kosList = [];
  KosModel? _selectedKos;

  KosProvider({KosRepository? repository})
      : _repository = repository ?? KosRepository();

  /// Menunjukkan apakah ada proses pemuatan data yang sedang berlangsung (daftar atau detail).
  bool get isLoading => isLoadingList || isLoadingDetail;

  /// Menunjukkan apakah pemuatan daftar kos sedang berlangsung.
  bool get isLoadingList => _activeListRequests > 0;

  /// Menunjukkan apakah pemuatan rincian detail kos sedang berlangsung.
  bool get isLoadingDetail => _activeDetailRequests > 0;

  /// Menyimpan pesan kesalahan jika operasi gagal, atau `null` jika tidak ada galat.
  String? get errorMessage => _errorMessage;

  /// Daftar seluruh data kos yang dapat dilihat oleh publik.
  List<KosModel> get kosList => List.unmodifiable(_kosList);

  /// Rincian detail kos yang sedang dibuka saat ini.
  KosModel? get selectedKos => _selectedKos;

  /// Mengambil seluruh data kos publik dari [KosRepository].
  /// Menggunakan request counter untuk menghindari race condition jika terdapat
  /// beberapa pemanggilan daftar yang berjalan secara bersamaan.
  Future<void> fetchKosList() async {
    _activeListRequests++;
    _errorMessage = null;
    notifyListeners();

    try {
      _kosList = await _repository.getKosList();
    } catch (e) {
      _kosList = [];
      _errorMessage = e.toString();
    } finally {
      if (_activeListRequests > 0) {
        _activeListRequests--;
      }
      notifyListeners();
    }
  }

  /// Mengambil rincian detail kos berdasarkan [id] UUID.
  /// Menggunakan request counter untuk menghindari race condition jika terdapat
  /// beberapa pemanggilan detail yang berjalan secara bersamaan.
  Future<void> fetchKosDetail(String id) async {
    _activeDetailRequests++;
    _errorMessage = null;
    _selectedKos = null;
    notifyListeners();

    try {
      final kos = await _repository.getKosDetailById(id);
      if (kos == null) {
        _errorMessage = 'Kos tidak ditemukan atau sudah tidak tersedia.';
      } else {
        _selectedKos = kos;
      }
    } catch (e) {
      _selectedKos = null;
      _errorMessage = e.toString();
    } finally {
      if (_activeDetailRequests > 0) {
        _activeDetailRequests--;
      }
      notifyListeners();
    }
  }

  /// Mengulangi proses pemuatan daftar kos publik (Retry).
  Future<void> retryFetchKosList() async {
    await fetchKosList();
  }
}
