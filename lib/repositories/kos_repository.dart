import 'dart:async';
import 'dart:io';

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
      throw KosException(
        'Gagal memuat detail kos. Periksa koneksi Anda.',
        e,
      );
    } on TimeoutException catch (e) {
      throw KosException(
        'Koneksi waktu habis saat memuat detail kos. Silakan coba kembali.',
        e,
      );
    } on FormatException catch (e) {
      throw KosException(
        'Format data detail kos tidak valid: ${e.message}',
        e,
      );
    } on KosException {
      rethrow;
    } catch (e) {
      throw KosException(
        'Gagal memuat detail kos. Terjadi kesalahan pada server.',
        e,
      );
    }
  }
}
