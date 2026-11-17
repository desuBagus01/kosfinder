import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/kos_model.dart';
import '../services/supabase_kos_service.dart';

/// Exception khusus untuk menangani kesalahan operasional pada repositori Kos.
class KosException implements Exception {
  final String message;
  final dynamic originalError;

  const KosException(this.message, [this.originalError]);

  @override
  String toString() => message;
}

/// Repositori untuk entitas Kos.
/// Berperan sebagai lapisan abstraksi antara Service (Supabase) dan Provider/State Management.
/// Bertugas mengonversi data mentah menjadi [KosModel], menangani validasi, dan standarisasi error.
///
/// Selaras dengan dokumen arsitektur (Subbab 1.1 - Repository Layer).
class KosRepository {
  final SupabaseKosService _service;

  KosRepository({SupabaseKosService? kosService})
    : _service = kosService ?? SupabaseKosService();

  /// Mengambil seluruh data kos publik.
  /// Mengembalikan list kosong `[]` jika belum ada kos yang terdaftar.
  /// Melempar [KosException] jika terjadi gangguan koneksi internet atau kegagalan query.
  Future<List<KosModel>> getKosList() async {
    try {
      final rawList = await _service.fetchKosList();
      return rawList.map((map) => KosModel.fromJson(map)).toList();
    } on SocketException catch (e) {
      throw KosException(
        'Gagal memuat data kos. Silakan periksa koneksi internet Anda.',
        e,
      );
    } on TimeoutException catch (e) {
      throw KosException(
        'Koneksi waktu habis saat memuat data kos. Silakan coba kembali.',
        e,
      );
    } on FormatException catch (e) {
      throw KosException(
        'Format data kos dari server tidak valid: ${e.message}',
        e,
      );
    } on KosException {
      rethrow;
    } catch (e) {
      throw KosException(
        'Gagal memuat data kos. Terjadi kesalahan pada server.',
        e,
      );
    }
  }

  /// Mengambil rincian detail kos berdasarkan [id] UUID.
  /// Mengembalikan [KosModel] jika ditemukan, atau `null` jika kos sudah dihapus / tidak ditemukan.
  /// Melempar [ArgumentError] jika [id] kosong.
  /// Melempar [KosException] jika terjadi gangguan jaringan saat memuat detail kos.
  Future<KosModel?> getKosDetailById(String id) async {
    final trimmedId = id.trim();
    if (trimmedId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'ID kos tidak boleh kosong.');
    }

    try {
      final rawData = await _service.fetchKosById(trimmedId);
      if (rawData == null) {
        return null;
      }
      return KosModel.fromJson(rawData);
    } on SocketException catch (e) {
      throw KosException('Gagal memuat detail kos. Periksa koneksi Anda.', e);
    } on TimeoutException catch (e) {
      throw KosException(
        'Koneksi waktu habis saat memuat detail kos. Silakan coba kembali.',
        e,
      );
    } on FormatException catch (e) {
      throw KosException('Format data detail kos tidak valid: ${e.message}', e);
    } on KosException {
      rethrow;
    } catch (e) {
      throw KosException(
        'Gagal memuat detail kos. Terjadi kesalahan pada server.',
        e,
      );
    }
  }

  /// Mengambil daftar kos dengan pencarian kata kunci nama/area/alamat via Supabase OR / ILIKE
  /// serta filter kombinasi harga dan fasilitas pada lapisan Repository.
  Future<List<KosModel>> getKosListFiltered({
    String keyword = '',
    int? maxPrice,
    bool mustHaveWifi = false,
    bool mustHaveBathroom = false,
    bool mustHaveParking = false,
  }) async {
    final trimmedKeyword = keyword.trim();

    List<KosModel> kosList;
    try {
      final List<Map<String, dynamic>> rawList;
      if (trimmedKeyword.isNotEmpty) {
        rawList = await _service.searchKos(trimmedKeyword);
      } else {
        rawList = await _service.fetchKosList();
      }
      kosList = rawList.map((map) => KosModel.fromJson(map)).toList();
    } on SocketException catch (e) {
      throw KosException(
        'Gagal memuat data kos. Silakan periksa koneksi internet Anda.',
        e,
      );
    } on TimeoutException catch (e) {
      throw KosException(
        'Koneksi waktu habis saat memuat data kos. Silakan coba kembali.',
        e,
      );
    } on FormatException catch (e) {
      throw KosException(
        'Format data kos dari server tidak valid: ${e.message}',
        e,
      );
    } on KosException {
      rethrow;
    } catch (e) {
      throw KosException(
        'Gagal memuat data kos. Terjadi kesalahan pada server.',
        e,
      );
    }

    // Terapkan filter harga dan fasilitas pada Repository dengan kondisi AND
    return kosList.where((kos) {
      if (maxPrice != null && kos.pricePerMonth > maxPrice) return false;
      if (mustHaveWifi && !kos.hasWifi) return false;
      if (mustHaveBathroom && !kos.hasBathroomInside) return false;
      if (mustHaveParking && !kos.hasParking) return false;
      return true;
    }).toList();
  }

  /// Menambahkan data kos baru ke basis data.
  Future<KosModel> createKos(KosModel kos) async {
    try {
      final rawData = await _service.createKos(kos.toJson());
      return KosModel.fromJson(rawData);
    } on SocketException catch (e) {
      throw KosException(
        'Gagal menambahkan kos. Silakan periksa koneksi internet Anda.',
        e,
      );
    } on TimeoutException catch (e) {
      throw KosException(
        'Koneksi waktu habis saat menambahkan kos. Silakan coba kembali.',
        e,
      );
    } on AuthException catch (e) {
      throw KosException(e.message, e);
    } on FormatException catch (e) {
      throw KosException(
        'Format data kos dari server tidak valid: ${e.message}',
        e,
      );
    } on KosException {
      rethrow;
    } catch (e) {
      throw KosException('Gagal menambahkan kos: $e', e);
    }
  }

  /// Memperbarui data kos yang ada pada basis data.
  Future<KosModel> updateKos(KosModel kos) async {
    try {
      final rawData = await _service.updateKos(kos.id, kos.toJson());
      return KosModel.fromJson(rawData);
    } on SocketException catch (e) {
      throw KosException(
        'Gagal memperbarui kos. Silakan periksa koneksi internet Anda.',
        e,
      );
    } on TimeoutException catch (e) {
      throw KosException(
        'Koneksi waktu habis saat memperbarui kos. Silakan coba kembali.',
        e,
      );
    } on AuthException catch (e) {
      throw KosException(e.message, e);
    } on FormatException catch (e) {
      throw KosException(
        'Format data kos dari server tidak valid: ${e.message}',
        e,
      );
    } on KosException {
      rethrow;
    } catch (e) {
      throw KosException('Gagal memperbarui kos: $e', e);
    }
  }

  /// Menghapus data kos berdasarkan [id] UUID.
  Future<void> deleteKos(String id) async {
    final trimmedId = id.trim();
    if (trimmedId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'ID kos tidak boleh kosong.');
    }

    try {
      await _service.deleteKos(trimmedId);
    } on SocketException catch (e) {
      throw KosException(
        'Gagal menghapus kos. Silakan periksa koneksi internet Anda.',
        e,
      );
    } on TimeoutException catch (e) {
      throw KosException(
        'Koneksi waktu habis saat menghapus kos. Silakan coba kembali.',
        e,
      );
    } on AuthException catch (e) {
      throw KosException(e.message, e);
    } on KosException {
      rethrow;
    } catch (e) {
      throw KosException('Gagal menghapus kos: $e', e);
    }
  }

  /// Memperbarui jumlah kamar tersedia milik pemilik yang sedang login.
  /// Melempar [ArgumentError] jika [kosId] kosong.
  /// Melempar [KosException] jika pembaruan gagal, kamar negatif, atau pengguna belum login.
  Future<KosModel> updateAvailableRooms(String kosId, int newRooms) async {
    final trimmedId = kosId.trim();
    if (trimmedId.isEmpty) {
      throw ArgumentError.value(kosId, 'kosId', 'ID kos tidak boleh kosong.');
    }
    if (newRooms < 0) {
      throw const KosException('Jumlah kamar tidak boleh kurang dari 0');
    }

    try {
      final rawData = await _service.updateAvailableRooms(trimmedId, newRooms);
      return KosModel.fromJson(rawData);
    } on ArgumentError {
      rethrow;
    } on SocketException catch (e) {
      throw KosException(
        'Gagal memperbarui ketersediaan kamar. Silakan periksa koneksi internet Anda.',
        e,
      );
    } on TimeoutException catch (e) {
      throw KosException(
        'Koneksi waktu habis saat memperbarui ketersediaan kamar. Silakan coba kembali.',
        e,
      );
    } on AuthException catch (e) {
      throw KosException(e.message, e);
    } on FormatException catch (e) {
      throw KosException(
        'Format data kos dari server tidak valid: ${e.message}',
        e,
      );
    } on KosException {
      rethrow;
    } catch (e) {
      throw KosException('Gagal memperbarui ketersediaan kamar: $e', e);
    }
  }

  /// Mengambil seluruh data kos milik pemilik yang sedang login dari [SupabaseKosService].
  /// Mengembalikan list kosong `[]` jika pemilik belum memiliki kos.
  /// Melempar [KosException] jika terjadi kegagalan jaringan atau belum login.
  Future<List<KosModel>> getOwnerKosList([String? ownerId]) async {
    try {
      final rawList = await _service.getOwnerKosList(ownerId);
      return rawList.map((map) => KosModel.fromJson(map)).toList();
    } on SocketException catch (e) {
      throw KosException(
        'Gagal memuat daftar kos pemilik. Silakan periksa koneksi internet Anda.',
        e,
      );
    } on TimeoutException catch (e) {
      throw KosException(
        'Koneksi waktu habis saat memuat daftar kos pemilik. Silakan coba kembali.',
        e,
      );
    } on AuthException catch (e) {
      throw KosException(e.message, e);
    } on FormatException catch (e) {
      throw KosException(
        'Format data kos pemilik dari server tidak valid: ${e.message}',
        e,
      );
    } on KosException {
      rethrow;
    } catch (e) {
      throw KosException('Gagal memuat daftar kos pemilik: $e', e);
    }
  }
}
