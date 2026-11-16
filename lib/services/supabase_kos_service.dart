import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Service untuk menangani interaksi teknis langsung dengan Supabase PostgreSQL
/// melalui Supabase Client untuk entitas Kos.
///
/// Selaras dengan dokumen arsitektur (Subbab 1.1 - Service Layer dan Subbab 3.3).
class SupabaseKosService {
  final SupabaseClient? client;

  SupabaseKosService({this.client});

  /// Mengambil instance [SupabaseClient].
  /// Menggunakan client yang diinjeksi atau fallback ke [Supabase.instance.client].
  SupabaseClient get _supabaseClient => client ?? Supabase.instance.client;

  /// Mengambil seluruh data kos dari tabel `public.kos` secara publik.
  /// Diurutkan berdasarkan `created_at` descending (terbaru ke terlama).
  Future<List<Map<String, dynamic>>> fetchKosList() async {
    try {
      final response = await _supabaseClient
          .from('kos')
          .select()
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Gagal memuat data dari basis data: ${e.message}');
    } catch (e) {
      if (e is SocketException || e is TimeoutException) {
        rethrow;
      }
      throw Exception('Terjadi kesalahan saat memuat data kos: $e');
    }
  }

  /// Mengambil data kos berdasarkan kata kunci teks bebas yang mencocokkan
  /// kolom `name`, `area`, atau `address` menggunakan operator OR / ILIKE.
  /// Pola query sesuai docs/architecture.md Subbab 3.3:
  /// `or('name.ilike.%$keyword%,area.ilike.%$keyword%,address.ilike.%$keyword%')`
  Future<List<Map<String, dynamic>>> searchKos(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) {
      return fetchKosList();
    }

    try {
      final response = await _supabaseClient
          .from('kos')
          .select()
          .or(
            'name.ilike.%$trimmed%,area.ilike.%$trimmed%,address.ilike.%$trimmed%',
          )
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Gagal memuat data dari basis data: ${e.message}');
    } catch (e) {
      if (e is SocketException || e is TimeoutException) {
        rethrow;
      }
      throw Exception('Terjadi kesalahan saat mencari data kos: $e');
    }
  }

  /// Mengambil detail satu data kos berdasarkan [id] UUID.
  /// Mengembalikan `Map<String, dynamic>` jika ditemukan, atau `null` jika tidak ada.
  Future<Map<String, dynamic>?> fetchKosById(String id) async {
    try {
      final response = await _supabaseClient
          .from('kos')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return Map<String, dynamic>.from(response);
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Gagal memuat detail kos dari basis data: ${e.message}');
    } catch (e) {
      if (e is SocketException || e is TimeoutException) {
        rethrow;
      }
      throw Exception('Terjadi kesalahan saat memuat detail kos: $e');
    }
  }
}
