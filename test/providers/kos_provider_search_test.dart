import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos_model.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/repositories/kos_repository.dart';
import 'package:kosfinder/services/supabase_kos_service.dart';

/// Mock implementasi [SupabaseKosService] untuk pengujian repository & provider.
/// Mensimulasikan query Supabase OR / ILIKE 3 kolom:
/// `or('name.ilike.%$keyword%,area.ilike.%$keyword%,address.ilike.%$keyword%')`
class MockSupabaseKosService extends SupabaseKosService {
  List<Map<String, dynamic>>? mockKosListResponse;
  Exception? errorToThrow;
  String? lastSearchKeyword;
  int searchKosCallCount = 0;
  int fetchKosListCallCount = 0;

  @override
  Future<List<Map<String, dynamic>>> fetchKosList() async {
    fetchKosListCallCount++;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return mockKosListResponse ?? [];
  }

  @override
  Future<List<Map<String, dynamic>>> searchKos(String keyword) async {
    searchKosCallCount++;
    lastSearchKeyword = keyword;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }

    final trimmed = keyword.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return fetchKosList();
    }

    // Simulasi query Supabase: or('name.ilike.%$trimmed%,area.ilike.%$trimmed%,address.ilike.%$trimmed%')
    final all = mockKosListResponse ?? [];
    return all.where((map) {
      final name = (map['name'] as String? ?? '').toLowerCase();
      final area = (map['area'] as String? ?? '').toLowerCase();
      final address = (map['address'] as String? ?? '').toLowerCase();
      return name.contains(trimmed) ||
          area.contains(trimmed) ||
          address.contains(trimmed);
    }).toList();
  }
}

void main() {
  group('TASK-2.1: Pencarian 3 Kolom (Name, Area, Address) via Supabase OR/ILIKE & Filter Repository', () {
    late MockSupabaseKosService mockService;
    late KosRepository repository;
    late KosProvider provider;

    // Dataset kos untuk pengujian pencarian dan filter
    final kos1 = <String, dynamic>{
      'id': '11111111-1111-1111-1111-111111111111',
      'owner_id': '00000000-0000-0000-0000-000000000001',
      'name': 'Kos Melati Singaraja',
      'address': 'Jl. Udayana No. 11',
      'area': 'Banyuasri Singaraja',
      'contact_number': '081234567891',
      'price_per_month': 850000,
      'description': 'Dekat kampus Undiksha Singaraja.',
      'available_rooms': 3,
      'has_wifi': true,
      'has_bathroom_inside': true,
      'has_parking': false,
      'created_at': '2026-11-16T08:00:00.000Z',
      'updated_at': '2026-11-16T08:00:00.000Z',
    };

    final kos2 = <String, dynamic>{
      'id': '22222222-2222-2222-2222-222222222222',
      'owner_id': '00000000-0000-0000-0000-000000000002',
      'name': 'Kos Mawar Denpasar',
      'address': 'Jl. Diponegoro No. 88',
      'area': 'Denpasar Barat',
      'contact_number': '081234567892',
      'price_per_month': 1500000,
      'description': 'Dekat pusat perbelanjaan Denpasar.',
      'available_rooms': 2,
      'has_wifi': true,
      'has_bathroom_inside': true,
      'has_parking': true,
      'created_at': '2026-11-16T09:00:00.000Z',
      'updated_at': '2026-11-16T09:00:00.000Z',
    };

    final kos3 = <String, dynamic>{
      'id': '33333333-3333-3333-3333-333333333333',
      'owner_id': '00000000-0000-0000-0000-000000000003',
      'name': 'Kos Cempaka Murah',
      'address': 'Jl. Ahmad Yani No. 12, Singaraja',
      'area': 'Kaliuntu',
      'contact_number': '081234567893',
      'price_per_month': 600000,
      'description': 'Kos hemat tanpa wifi.',
      'available_rooms': 1,
      'has_wifi': false,
      'has_bathroom_inside': false,
      'has_parking': true,
      'created_at': '2026-11-16T10:00:00.000Z',
      'updated_at': '2026-11-16T10:00:00.000Z',
    };

    final kos4 = <String, dynamic>{
      'id': '44444444-4444-4444-4444-444444444444',
      'owner_id': '00000000-0000-0000-0000-000000000004',
      'name': 'Kos Mewah Denpasar',
      'address': 'Jl. Sudirman No. 99, Denpasar',
      'area': 'Renon',
      'contact_number': '081234567894',
      'price_per_month': 2500000,
      'description': 'Kos eksklusif fasilitas lengkap.',
      'available_rooms': 5,
      'has_wifi': true,
      'has_bathroom_inside': true,
      'has_parking': true,
      'created_at': '2026-11-16T11:00:00.000Z',
      'updated_at': '2026-11-16T11:00:00.000Z',
    };

    setUp(() {
      mockService = MockSupabaseKosService();
      mockService.mockKosListResponse = [kos1, kos2, kos3, kos4];
      repository = KosRepository(kosService: mockService);
      provider = KosProvider(repository: repository);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // PENGUJIAN 1: Pencarian Berdasarkan Nama Kos ("Mawar" vs "mawar")
    // ─────────────────────────────────────────────────────────────────────────
    test('1. Kata "Mawar" dapat menemukan Kos Mawar dan "mawar" menghasilkan data yang sama persis', () async {
      // Cari dengan huruf kapital "Mawar"
      await provider.fetchKosListFiltered(keyword: 'Mawar');
      final resultCapital = List<KosModel>.from(provider.kosList);
      expect(mockService.searchKosCallCount, equals(1));
      expect(mockService.lastSearchKeyword, equals('Mawar'));
      expect(resultCapital.length, equals(1));
      expect(resultCapital.first.name, equals('Kos Mawar Denpasar'));

      // Cari dengan huruf kecil "mawar"
      await provider.fetchKosListFiltered(keyword: 'mawar');
      final resultLower = List<KosModel>.from(provider.kosList);
      expect(mockService.searchKosCallCount, equals(2));
      expect(mockService.lastSearchKeyword, equals('mawar'));
      expect(resultLower.length, equals(1));
      expect(resultLower.first.name, equals('Kos Mawar Denpasar'));

      // Verifikasi hasil keduanya identik
      expect(resultLower.first.id, equals(resultCapital.first.id));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // PENGUJIAN 2: Pencarian Area Tetap Berfungsi Case-Insensitive
    // ─────────────────────────────────────────────────────────────────────────
    test('2. Pencarian area tetap berfungsi ("singaraja" vs "Singaraja") via query Supabase OR / ILIKE', () async {
      await provider.fetchKosListFiltered(keyword: 'singaraja');
      final resultLower = List<KosModel>.from(provider.kosList);

      await provider.fetchKosListFiltered(keyword: 'Singaraja');
      final resultCapital = List<KosModel>.from(provider.kosList);

      expect(resultLower.isNotEmpty, isTrue);
      expect(resultLower.length, equals(resultCapital.length));
      final idsLower = resultLower.map((k) => k.id).toList();
      final idsCapital = resultCapital.map((k) => k.id).toList();
      expect(idsLower, equals(idsCapital));

      // kos1 (area: "Banyuasri Singaraja") dan kos3 (address: "... Singaraja")
      expect(idsLower, contains(kos1['id']));
      expect(idsLower, contains(kos3['id']));
      expect(idsLower, isNot(contains(kos2['id'])));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // PENGUJIAN 3: Pencarian Berdasarkan Alamat Tetap Berfungsi
    // ─────────────────────────────────────────────────────────────────────────
    test(
      '3. Pencarian alamat tetap berfungsi mencocokkan kolom address',
      () async {
        await provider.fetchKosListFiltered(keyword: 'Diponegoro');
        expect(provider.kosList.length, equals(1));
        expect(provider.kosList.first.name, equals('Kos Mawar Denpasar'));
        expect(provider.kosList.first.address, contains('Diponegoro'));

        await provider.fetchKosListFiltered(keyword: 'Udayana');
        expect(provider.kosList.length, equals(1));
        expect(provider.kosList.first.name, equals('Kos Melati Singaraja'));
        expect(provider.kosList.first.address, contains('Udayana'));
      },
    );

    // ─────────────────────────────────────────────────────────────────────────
    // PENGUJIAN 4: Filter Harga Maksimum Rp 1.500.000 pada Repository
    // ─────────────────────────────────────────────────────────────────────────
    test('4. Uji filter harga maksimum Rp 1.500.000 diterapkan pada lapisan Repository', () async {
      await provider.fetchKosListFiltered(maxPrice: 1500000);

      expect(mockService.fetchKosListCallCount, equals(1));
      // kos1 (850rb), kos2 (1.5jt), kos3 (600rb) <= 1.500.000 -> 3 lolos
      // kos4 (2.5jt) > 1.500.000 -> ditolak
      expect(provider.kosList.length, equals(3));
      for (final kos in provider.kosList) {
        expect(kos.pricePerMonth, lessThanOrEqualTo(1500000));
      }
      final ids = provider.kosList.map((k) => k.id).toList();
      expect(ids, isNot(contains(kos4['id'])));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // PENGUJIAN 5: Kombinasi Fasilitas WiFi dan Kamar Mandi Dalam (Kondisi AND)
    // ─────────────────────────────────────────────────────────────────────────
    test('5. Uji kombinasi fasilitas WiFi dan kamar mandi dalam (kondisi AND) pada Repository', () async {
      await provider.fetchKosListFiltered(
        mustHaveWifi: true,
        mustHaveBathroom: true,
      );

      // kos1, kos2, kos4 memiliki WiFi dan Kamar Mandi Dalam
      // kos3 tidak memiliki keduanya
      expect(provider.kosList.length, equals(3));
      for (final kos in provider.kosList) {
        expect(kos.hasWifi, isTrue);
        expect(kos.hasBathroomInside, isTrue);
      }
      final ids = provider.kosList.map((k) => k.id).toList();
      expect(ids, isNot(contains(kos3['id'])));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // PENGUJIAN 6: Filter Kombinasi Lengkap (Nama/Area + Harga + Fasilitas)
    // ─────────────────────────────────────────────────────────────────────────
    test('6. Uji filter kombinasi lengkap: nama "Mawar", harga <= 1.500.000, WiFi + Kamar Mandi Dalam + Parkir', () async {
      await provider.fetchKosListFiltered(
        keyword: 'Mawar',
        maxPrice: 1500000,
        mustHaveWifi: true,
        mustHaveBathroom: true,
        mustHaveParking: true,
      );

      expect(mockService.lastSearchKeyword, equals('Mawar'));
      expect(provider.kosList.length, equals(1));
      expect(provider.kosList.first.id, equals(kos2['id']));
      expect(provider.kosList.first.name, equals('Kos Mawar Denpasar'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // PENGUJIAN 7: Pencarian Tanpa Hasil (AC02-2, AC03-2)
    // ─────────────────────────────────────────────────────────────────────────
    test(
      '7. Pencarian tanpa hasil menampilkan daftar kosong tanpa error',
      () async {
        await provider.fetchKosListFiltered(keyword: 'NamaKosTidakAda');

        expect(provider.kosList.isEmpty, isTrue);
        expect(provider.errorMessage, isNull);
        expect(provider.isFiltered, isTrue);
        expect(provider.searchKeyword, equals('NamaKosTidakAda'));

        // Filter harga terlalu rendah
        await provider.fetchKosListFiltered(maxPrice: 50000);
        expect(provider.kosList.isEmpty, isTrue);
        expect(provider.errorMessage, isNull);
      },
    );

    // ─────────────────────────────────────────────────────────────────────────
    // PENGUJIAN 8: Pencarian Tetap Mempertahankan Loading, Error, dan Retry
    // ─────────────────────────────────────────────────────────────────────────
    test(
      '8. Pencarian tetap mempertahankan loading, error, dan retry',
      () async {
        // Simulasi error jaringan saat pencarian
        mockService.errorToThrow = const SocketException('Koneksi terputus');

        await provider.fetchKosListFiltered(
          keyword: 'Mawar',
          maxPrice: 2000000,
          mustHaveWifi: true,
        );

        expect(provider.kosList.isEmpty, isTrue);
        expect(provider.errorMessage, isNotNull);
        expect(
          provider.errorMessage,
          contains(
            'Gagal memuat data kos. Silakan periksa koneksi internet Anda.',
          ),
        );
        // State parameter filter tetap dipertahankan
        expect(provider.isFiltered, isTrue);
        expect(provider.searchKeyword, equals('Mawar'));
        expect(provider.maxPrice, equals(2000000));
        expect(provider.filterWifi, isTrue);

        // Sembuhkan koneksi dan jalankan retry
        mockService.errorToThrow = null;
        await provider.retryFetchKosList();

        // Hasil retry: kos2 (Kos Mawar Denpasar) berhasil dimuat
        expect(provider.kosList.length, equals(1));
        expect(provider.kosList.first.id, equals(kos2['id']));
        expect(provider.errorMessage, isNull);
      },
    );

    // ─────────────────────────────────────────────────────────────────────────
    // PENGUJIAN 9: clearFilter() Mengembalikan Semua Data
    // ─────────────────────────────────────────────────────────────────────────
    test(
      '9. clearFilter() mereset seluruh parameter dan menampilkan semua kos',
      () async {
        await provider.fetchKosListFiltered(keyword: 'Mawar', maxPrice: 700000);
        expect(provider.isFiltered, isTrue);

        await provider.clearFilter();

        expect(provider.kosList.length, equals(4));
        expect(provider.isFiltered, isFalse);
        expect(provider.searchKeyword, isEmpty);
        expect(provider.maxPrice, isNull);
        expect(provider.filterWifi, isFalse);
        expect(provider.filterBathroom, isFalse);
        expect(provider.filterParking, isFalse);
      },
    );

    // ─────────────────────────────────────────────────────────────────────────
    // PENGUJIAN 10: Pengujian Unit Langsung pada KosRepository
    // ─────────────────────────────────────────────────────────────────────────
    test('10. KosRepository.getKosListFiltered() memanggil searchKos untuk keyword 3 kolom', () async {
      final result = await repository.getKosListFiltered(
        keyword: 'Mawar',
        mustHaveParking: true,
      );

      expect(mockService.searchKosCallCount, equals(1));
      expect(mockService.lastSearchKeyword, equals('Mawar'));
      expect(result.length, equals(1));
      expect(result.first.name, equals('Kos Mawar Denpasar'));
    });
  });
}
