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

  /// Menambahkan data kos baru ke tabel `public.kos`.
  /// Wajib memeriksa sesi login pengguna aktif melalui Supabase Auth.
  /// Menolak operasi dengan melempar [AuthException] jika tidak ada sesi login.
  /// Nilai `owner_id` mutlak diambil dari `currentUser.id` untuk mencegah manipulasi client.
  Future<Map<String, dynamic>> createKos(Map<String, dynamic> kosData) async {
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) {
      throw const AuthException(
        'Pengguna belum login. Operasi penambahan kos ditolak.',
      );
    }

    final payload = Map<String, dynamic>.from(kosData);
    // Mutlak gunakan UID pengguna yang sedang terautentikasi (mencegah manipulasi client)
    payload['owner_id'] = currentUser.id;
    if (payload['id'] == null ||
        (payload['id'] is String && (payload['id'] as String).trim().isEmpty)) {
      payload.remove('id');
    }

    try {
      final response = await _supabaseClient
          .from('kos')
          .insert(payload)
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Gagal menambahkan kos ke basis data: ${e.message}');
    } catch (e) {
      if (e is SocketException || e is TimeoutException || e is AuthException) {
        rethrow;
      }
      throw Exception('Terjadi kesalahan saat menambahkan kos: $e');
    }
  }

  /// Memperbarui data kos pada tabel `public.kos`.
  /// Memeriksa sesi login pengguna aktif dan memastikan update hanya memengaruhi
  /// baris data milik pengguna yang sedang login (`owner_id == currentUser.id`).
  Future<Map<String, dynamic>> updateKos(
    String id,
    Map<String, dynamic> kosData,
  ) async {
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) {
      throw const AuthException(
        'Pengguna belum login. Operasi pengubahan kos ditolak.',
      );
    }

    final payload = Map<String, dynamic>.from(kosData);
    payload.remove('id'); // ID tidak dapat diubah
    payload['owner_id'] =
        currentUser.id; // Menjamin owner_id tidak dapat dipalsukan
    payload['updated_at'] = DateTime.now().toIso8601String();

    try {
      final response = await _supabaseClient
          .from('kos')
          .update(payload)
          .eq('id', id)
          .eq('owner_id', currentUser.id)
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Gagal memperbarui kos di basis data: ${e.message}');
    } catch (e) {
      if (e is SocketException || e is TimeoutException || e is AuthException) {
        rethrow;
      }
      throw Exception('Terjadi kesalahan saat memperbarui kos: $e');
    }
  }

  /// Menghapus data kos dari tabel `public.kos`.
  /// Memeriksa sesi login pengguna aktif dan memastikan penghapusan hanya memengaruhi
  /// baris data milik pengguna yang sedang login (`owner_id == currentUser.id`).
  Future<void> deleteKos(String id) async {
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) {
      throw const AuthException(
        'Pengguna belum login. Operasi penghapusan kos ditolak.',
      );
    }

    try {
      await _supabaseClient
          .from('kos')
          .delete()
          .eq('id', id)
          .eq('owner_id', currentUser.id);
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('Gagal menghapus kos dari basis data: ${e.message}');
    } catch (e) {
      if (e is SocketException || e is TimeoutException || e is AuthException) {
        rethrow;
      }
      throw Exception('Terjadi kesalahan saat menghapus kos: $e');
    }
  }

  /// Memperbarui jumlah kamar tersedia pada tabel `public.kos`.
  /// Memeriksa sesi login pengguna aktif dan memastikan update hanya memengaruhi
  /// baris data milik pengguna yang sedang login (`owner_id == currentUser.id`).
  /// Melempar [AuthException] jika pengguna belum login.
  /// Melempar [ArgumentError] jika [newRooms] negatif.
  Future<Map<String, dynamic>> updateAvailableRooms(
    String kosId,
    int newRooms,
  ) async {
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) {
      throw const AuthException(
        'Pengguna belum login. Operasi pembaruan kamar ditolak.',
      );
    }

    if (newRooms < 0) {
      throw ArgumentError('Jumlah kamar tidak boleh kurang dari 0');
    }

    try {
      final response = await _supabaseClient
          .from('kos')
          .update({
            'available_rooms': newRooms,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', kosId)
          .eq('owner_id', currentUser.id)
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception(
        'Gagal memperbarui ketersediaan kamar di basis data: ${e.message}',
      );
    } catch (e) {
      if (e is SocketException ||
          e is TimeoutException ||
          e is AuthException ||
          e is ArgumentError) {
        rethrow;
      }
      throw Exception(
        'Terjadi kesalahan saat memperbarui ketersediaan kamar: $e',
      );
    }
  }

  /// Mengambil daftar kos yang dimiliki oleh pemilik tertentu dari tabel `public.kos`.
  /// Jika [ownerId] tidak disertakan, mengambil ID pengguna aktif dari Supabase Auth.
  /// Diurutkan berdasarkan `created_at` descending.
  Future<List<Map<String, dynamic>>> getOwnerKosList([String? ownerId]) async {
    final uid = ownerId ?? _supabaseClient.auth.currentUser?.id;
    if (uid == null) {
      throw const AuthException(
        'Pengguna belum login. Tidak dapat memuat daftar kos pemilik.',
      );
    }

    try {
      final response = await _supabaseClient
          .from('kos')
          .select()
          .eq('owner_id', uid)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception(
        'Gagal memuat daftar kos pemilik dari basis data: ${e.message}',
      );
    } catch (e) {
      if (e is SocketException || e is TimeoutException || e is AuthException) {
        rethrow;
      }
      throw Exception('Terjadi kesalahan saat memuat daftar kos pemilik: $e');
    }
  }
}
