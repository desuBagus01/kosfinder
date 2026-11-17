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
  int _activeOwnerListRequests = 0;
  int _activeCrudRequests = 0;
  String? _errorMessage;
  List<KosModel> _kosList = [];
  List<KosModel> _ownerKosList = [];
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

  /// Menunjukkan apakah ada proses pemuatan data yang sedang berlangsung (daftar, detail, daftar pemilik, atau CRUD).
  bool get isLoading =>
      isLoadingList || isLoadingDetail || isLoadingOwnerList || isLoadingCrud;

  /// Menunjukkan apakah pemuatan daftar kos sedang berlangsung.
  bool get isLoadingList => _activeListRequests > 0;

  /// Menunjukkan apakah pemuatan rincian detail kos sedang berlangsung.
  bool get isLoadingDetail => _activeDetailRequests > 0;

  /// Menunjukkan apakah pemuatan daftar kos milik pemilik sedang berlangsung.
  bool get isLoadingOwnerList => _activeOwnerListRequests > 0;

  /// Menunjukkan apakah ada operasi CRUD kos yang sedang diproses.
  bool get isLoadingCrud => _activeCrudRequests > 0;

  /// Menyimpan pesan kesalahan jika operasi gagal, atau `null` jika tidak ada galat.
  String? get errorMessage => _errorMessage;

  /// Daftar seluruh data kos yang dapat dilihat oleh publik (hasil pencarian/filter atau semua).
  List<KosModel> get kosList => List.unmodifiable(_kosList);

  /// Daftar kos yang dimiliki oleh pemilik yang sedang login.
  List<KosModel> get ownerKosList => List.unmodifiable(_ownerKosList);

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

  // ── Method Pencarian & Filter ───────────────────────────────────────────

  /// Mengambil daftar kos dengan pencarian teks bebas dan/atau filter kombinasi.
  Future<void> fetchKosListFiltered({
    String keyword = '',
    int? maxPrice,
    bool mustHaveWifi = false,
    bool mustHaveBathroom = false,
    bool mustHaveParking = false,
  }) async {
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

  /// Menghapus pesan kesalahan yang aktif.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
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

  // ── Method Operasi CRUD Pemilik Kos ─────────────────────────────────────

  /// Mengambil daftar kos yang dimiliki oleh pemilik kos yang sedang login.
  Future<void> fetchOwnerKosList([String? ownerId]) async {
    _activeOwnerListRequests++;
    _errorMessage = null;
    notifyListeners();

    try {
      _ownerKosList = await _repository.getOwnerKosList(ownerId);
    } catch (e) {
      _ownerKosList = [];
      _errorMessage = e.toString();
    } finally {
      if (_activeOwnerListRequests > 0) {
        _activeOwnerListRequests--;
      }
      notifyListeners();
    }
  }

  /// Menambahkan kos baru milik pengguna yang sedang login.
  Future<bool> createKos(KosModel kos) async {
    _activeCrudRequests++;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await _repository.createKos(kos);
      _ownerKosList = [
        created,
        ..._ownerKosList.where((k) => k.id != created.id),
      ];
      if (_kosList.isNotEmpty) {
        _kosList = [created, ..._kosList.where((k) => k.id != created.id)];
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      if (_activeCrudRequests > 0) {
        _activeCrudRequests--;
      }
      notifyListeners();
    }
  }

  /// Memperbarui data kos milik sendiri.
  Future<bool> updateKos(KosModel kos) async {
    _activeCrudRequests++;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _repository.updateKos(kos);

      final ownerIndex = _ownerKosList.indexWhere((k) => k.id == updated.id);
      if (ownerIndex != -1) {
        _ownerKosList = List<KosModel>.from(_ownerKosList)
          ..[ownerIndex] = updated;
      }

      final listIndex = _kosList.indexWhere((k) => k.id == updated.id);
      if (listIndex != -1) {
        _kosList = List<KosModel>.from(_kosList)..[listIndex] = updated;
      }

      if (_selectedKos?.id == updated.id) {
        _selectedKos = updated;
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      if (_activeCrudRequests > 0) {
        _activeCrudRequests--;
      }
      notifyListeners();
    }
  }

  /// Memperbarui jumlah kamar tersedia milik sendiri berdasarkan [kosId].
  /// Setelah berhasil, menyinkronkan data pada [ownerKosList], [kosList] publik,
  /// dan [selectedKos] (jika sedang dibuka).
  /// Mengembalikan `true` jika berhasil, atau `false` jika gagal.
  Future<bool> updateAvailableRooms(String kosId, int newRooms) async {
    if (newRooms < 0) {
      _errorMessage = 'Jumlah kamar tidak boleh kurang dari 0';
      notifyListeners();
      return false;
    }

    _activeCrudRequests++;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _repository.updateAvailableRooms(kosId, newRooms);

      // Sinkronkan daftar pemilik
      final ownerIndex = _ownerKosList.indexWhere((k) => k.id == updated.id);
      if (ownerIndex != -1) {
        _ownerKosList = List<KosModel>.from(_ownerKosList)
          ..[ownerIndex] = updated;
      }

      // Sinkronkan daftar publik
      final listIndex = _kosList.indexWhere((k) => k.id == updated.id);
      if (listIndex != -1) {
        _kosList = List<KosModel>.from(_kosList)..[listIndex] = updated;
      }

      // Sinkronkan detail jika yang diperbarui adalah kos yang sedang dipilih
      if (_selectedKos?.id == updated.id) {
        _selectedKos = updated;
      }

      return true;
    } catch (e) {
      if (e is ArgumentError) {
        _errorMessage = e.message?.toString() ?? e.toString();
      } else {
        _errorMessage = e.toString();
      }
      return false;
    } finally {
      if (_activeCrudRequests > 0) {
        _activeCrudRequests--;
      }
      notifyListeners();
    }
  }

  /// Menghapus kos milik sendiri berdasarkan [id] UUID.
  Future<bool> deleteKos(String id) async {
    _activeCrudRequests++;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteKos(id);

      _ownerKosList = _ownerKosList.where((k) => k.id != id).toList();
      _kosList = _kosList.where((k) => k.id != id).toList();

      if (_selectedKos?.id == id) {
        _selectedKos = null;
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      if (_activeCrudRequests > 0) {
        _activeCrudRequests--;
      }
      notifyListeners();
    }
  }
}
