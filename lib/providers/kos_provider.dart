import 'package:flutter/foundation.dart';

import '../models/kos_model.dart';
import '../repositories/kos_repository.dart';

/// Provider untuk mengelola status publik aplikasi KosFinder.
/// Berperan sebagai penghubung antara UI (Screen) dan Data (KosRepository)
/// sesuai pola arsitektur Screen - Provider - Repository - Service.
///
/// Versi ini menambahkan dukungan pencarian teks bebas (FR02) dan filter
/// kombinasi harga + fasilitas (FR03, FR04) sesuai TASK-2.1.
class KosProvider extends ChangeNotifier {
  final KosRepository _repository;

  int _activeListRequests = 0;
  int _activeDetailRequests = 0;
  String? _errorMessage;
  List<KosModel> _kosList = [];
  KosModel? _selectedKos;

  // ── State Pencarian dan Filter ──────────────────────────────────────────
  String _searchKeyword = '';
  int? _maxPrice;
  bool _filterWifi = false;
  bool _filterBathroom = false;
  bool _filterParking = false;

  /// Apakah saat ini sedang menampilkan hasil pencarian/filter (bukan daftar penuh).
  bool _isFiltered = false;

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

  /// Daftar seluruh data kos yang dapat dilihat oleh publik (hasil pencarian/filter atau semua).
  List<KosModel> get kosList => List.unmodifiable(_kosList);

  /// Rincian detail kos yang sedang dibuka saat ini.
  KosModel? get selectedKos => _selectedKos;

  // ── Getter State Filter ─────────────────────────────────────────────────

  /// Kata kunci pencarian yang saat ini aktif.
  String get searchKeyword => _searchKeyword;

  /// Batas harga maksimum yang saat ini aktif, atau `null` jika tidak ada.
  int? get maxPrice => _maxPrice;

  /// Apakah filter WiFi sedang aktif.
  bool get filterWifi => _filterWifi;

  /// Apakah filter Kamar Mandi Dalam sedang aktif.
  bool get filterBathroom => _filterBathroom;

  /// Apakah filter Parkir sedang aktif.
  bool get filterParking => _filterParking;

  /// Apakah tampilan saat ini merupakan hasil pencarian/filter (bukan daftar penuh).
  bool get isFiltered => _isFiltered;

  // ── Method Utama ────────────────────────────────────────────────────────

  /// Mengambil seluruh data kos publik dari [KosRepository].
  /// Menggunakan request counter untuk menghindari race condition jika terdapat
  /// beberapa pemanggilan daftar yang berjalan secara bersamaan.
  Future<void> fetchKosList() async {
    _activeListRequests++;
    _errorMessage = null;
    notifyListeners();

    try {
      _kosList = await _repository.getKosList();
      _isFiltered = false;
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
  /// Jika sebelumnya sedang dalam mode filter, ulangi pencarian/filter yang sama.
  Future<void> retryFetchKosList() async {
    if (_isFiltered) {
      await fetchKosListFiltered(
        keyword: _searchKeyword,
        maxPrice: _maxPrice,
        mustHaveWifi: _filterWifi,
        mustHaveBathroom: _filterBathroom,
        mustHaveParking: _filterParking,
      );
    } else {
      await fetchKosList();
    }
  }

  // ── Method Pencarian & Filter (TASK-2.1) ────────────────────────────────

  /// Mengambil daftar kos dengan pencarian teks bebas dan/atau filter kombinasi.
  ///
  /// - [keyword]: Kata kunci untuk mencocokkan kolom `name`, `area`, atau `address`
  ///   secara *case-insensitive*. String kosong berarti tidak ada filter kata kunci.
  /// - [maxPrice]: Batas harga maksimum per bulan. `null` berarti tidak ada batas.
  /// - [mustHaveWifi]: Jika `true`, hanya kos dengan WiFi yang ditampilkan.
  /// - [mustHaveBathroom]: Jika `true`, hanya kos dengan kamar mandi dalam yang ditampilkan.
  /// - [mustHaveParking]: Jika `true`, hanya kos dengan parkir yang ditampilkan.
  ///
  /// Memenuhi FR02 (pencarian nama/area/alamat), FR03 (filter harga), FR04 (filter fasilitas).
  /// Memenuhi AC02-1, AC02-2, AC02-3, AC03-1, AC03-2.
  Future<void> fetchKosListFiltered({
    String keyword = '',
    int? maxPrice,
    bool mustHaveWifi = false,
    bool mustHaveBathroom = false,
    bool mustHaveParking = false,
  }) async {
    // Simpan state filter agar bisa digunakan oleh retryFetchKosList
    _searchKeyword = keyword.trim();
    _maxPrice = maxPrice;
    _filterWifi = mustHaveWifi;
    _filterBathroom = mustHaveBathroom;
    _filterParking = mustHaveParking;
    _isFiltered = true;

    _activeListRequests++;
    _errorMessage = null;
    notifyListeners();

    try {
      _kosList = await _repository.getKosListFiltered(
        keyword: _searchKeyword,
        maxPrice: maxPrice,
        mustHaveWifi: mustHaveWifi,
        mustHaveBathroom: mustHaveBathroom,
        mustHaveParking: mustHaveParking,
      );
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

  /// Menghapus seluruh filter dan kata kunci pencarian, lalu mengambil ulang
  /// seluruh daftar kos publik tanpa filter.
  Future<void> clearFilter() async {
    _searchKeyword = '';
    _maxPrice = null;
    _filterWifi = false;
    _filterBathroom = false;
    _filterParking = false;
    _isFiltered = false;
    await fetchKosList();
  }
}
