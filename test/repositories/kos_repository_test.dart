import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/repositories/kos_repository.dart';
import 'package:kosfinder/services/supabase_kos_service.dart';

/// Mock implementasi [SupabaseKosService] untuk pengujian unit tanpa koneksi eksternal.
class MockSupabaseKosService extends SupabaseKosService {
  List<Map<String, dynamic>>? mockKosListResponse;
  Map<String, dynamic>? mockKosDetailResponse;
  Exception? errorToThrow;

  @override
  Future<List<Map<String, dynamic>>> fetchKosList() async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return mockKosListResponse ?? [];
  }

  @override
  Future<Map<String, dynamic>?> fetchKosById(String id) async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return mockKosDetailResponse;
  }
}

void main() {
  group('KosRepository Unit Tests', () {
    late MockSupabaseKosService mockService;
    late KosRepository repository;

    final sampleKosMap = <String, dynamic>{
      'id': 'a1111111-1111-1111-1111-111111111111',
      'owner_id': 'b2222222-2222-2222-2222-222222222222',
      'name': 'Kos Bunga Mawar',
      'address': 'Jl. Ahmad Yani No. 45',
      'area': 'Banyuasri',
      'contact_number': '081234567899',
      'price_per_month': 750000,
      'description': 'Kos nyaman, listrik gratis, dekat pusat kota.',
      'available_rooms': 2,
      'has_wifi': true,
      'has_bathroom_inside': false,
      'has_parking': true,
      'created_at': '2026-11-16T08:00:00.000Z',
      'updated_at': '2026-11-16T08:00:00.000Z',
    };

    setUp(() {
      mockService = MockSupabaseKosService();
      repository = KosRepository(kosService: mockService);
    });

    group('getKosList()', () {
      test(
        '1. Mengambil seluruh data kos berhasil dan dipetakan ke KosModel',
        () async {
          mockService.mockKosListResponse = [sampleKosMap];

          final result = await repository.getKosList();

          expect(result, hasLength(1));
          final kos = result.first;
          expect(kos.id, 'a1111111-1111-1111-1111-111111111111');
          expect(kos.name, 'Kos Bunga Mawar');
          expect(kos.pricePerMonth, 750000);
          expect(kos.hasWifi, isTrue);
          expect(kos.availableRooms, 2);
        },
      );

      test(
        '2. Mengembalikan list kosong jika belum ada data kos yang terdaftar',
        () async {
          mockService.mockKosListResponse = [];

          final result = await repository.getKosList();

          expect(result, isEmpty);
        },
      );

      test('3. Menangani kegagalan jaringan (SocketException) dengan pesan terstandar', () async {
        mockService.errorToThrow = const SocketException(
          'No Internet Connection',
        );

        expect(
          () => repository.getKosList(),
          throwsA(
            isA<KosException>().having(
              (e) => e.message,
              'message',
              contains('Silakan periksa koneksi internet Anda'),
            ),
          ),
        );
      });

      test('4. Menangani kegagalan batas waktu (TimeoutException) dengan pesan terstandar', () async {
        mockService.errorToThrow = TimeoutException('Connection timed out');

        expect(
          () => repository.getKosList(),
          throwsA(
            isA<KosException>().having(
              (e) => e.message,
              'message',
              contains('Koneksi waktu habis saat memuat data kos'),
            ),
          ),
        );
      });

      test('5. Menangani data cacat/rusak dari server dengan pesan kesalahan format', () async {
        // Data tanpa field wajib 'id' akan menyebabkan KosModel melempar FormatException
        mockService.mockKosListResponse = [
          <String, dynamic>{'name': 'Kos Rusak'},
        ];

        expect(
          () => repository.getKosList(),
          throwsA(
            isA<KosException>().having(
              (e) => e.message,
              'message',
              contains('Format data kos dari server tidak valid'),
            ),
          ),
        );
      });
    });

    group('getKosDetailById()', () {
      test(
        '1. Mengambil detail kos berdasarkan ID berhasil jika ditemukan',
        () async {
          mockService.mockKosDetailResponse = sampleKosMap;

          final result = await repository.getKosDetailById(
            'a1111111-1111-1111-1111-111111111111',
          );

          expect(result, isNotNull);
          expect(result!.id, 'a1111111-1111-1111-1111-111111111111');
          expect(result.name, 'Kos Bunga Mawar');
          expect(result.area, 'Banyuasri');
          expect(result.contactNumber, '081234567899');
        },
      );

      test(
        '2. Mengembalikan null jika kos tidak ditemukan atau sudah dihapus',
        () async {
          mockService.mockKosDetailResponse = null;

          final result = await repository.getKosDetailById('non-existent-uuid');

          expect(result, isNull);
        },
      );

      test(
        '3. Melempar ArgumentError jika ID kos yang diberikan kosong',
        () async {
          expect(() => repository.getKosDetailById('   '), throwsArgumentError);
        },
      );

      test('4. Menangani kegagalan jaringan saat memuat detail kos dengan pesan terstandar', () async {
        mockService.errorToThrow = const SocketException('Connection lost');

        expect(
          () => repository.getKosDetailById(
            'a1111111-1111-1111-1111-111111111111',
          ),
          throwsA(
            isA<KosException>().having(
              (e) => e.message,
              'message',
              contains('Gagal memuat detail kos. Periksa koneksi Anda.'),
            ),
          ),
        );
      });
    });
  });
}
