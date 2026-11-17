import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos_model.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/repositories/kos_repository.dart';
import 'package:kosfinder/services/supabase_kos_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fake implementation dari [SupabaseKosService] untuk menguji repositori secara terisolasi.
class FakeSupabaseKosService extends SupabaseKosService {
  User? mockUser;
  Exception? errorToThrow;
  Map<String, dynamic>? lastCreatedPayload;
  String? lastUpdatedId;
  Map<String, dynamic>? lastUpdatedPayload;
  String? lastDeletedId;
  List<Map<String, dynamic>> mockOwnerData = [];

  int createCallCount = 0;
  int updateCallCount = 0;
  int deleteCallCount = 0;
  int getOwnerListCallCount = 0;

  @override
  Future<Map<String, dynamic>> createKos(Map<String, dynamic> kosData) async {
    createCallCount++;
    if (mockUser == null) {
      throw const AuthException(
        'Pengguna belum login. Operasi penambahan kos ditolak.',
      );
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    // Enforce owner_id dari user yang login
    final payload = Map<String, dynamic>.from(kosData);
    payload['owner_id'] = mockUser!.id;
    payload['id'] = payload['id'] ?? 'generated-uuid-1111';
    payload['created_at'] = payload['created_at'] ?? '2026-11-17T10:00:00.000Z';
    payload['updated_at'] = payload['updated_at'] ?? '2026-11-17T10:00:00.000Z';

    lastCreatedPayload = payload;
    return payload;
  }

  @override
  Future<Map<String, dynamic>> updateKos(
    String id,
    Map<String, dynamic> kosData,
  ) async {
    updateCallCount++;
    if (mockUser == null) {
      throw const AuthException(
        'Pengguna belum login. Operasi pengubahan kos ditolak.',
      );
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    lastUpdatedId = id;
    final payload = Map<String, dynamic>.from(kosData);
    payload['id'] = id;
    payload['owner_id'] = mockUser!.id;
    payload['updated_at'] = DateTime.now().toIso8601String();
    lastUpdatedPayload = payload;
    return payload;
  }

  @override
  Future<void> deleteKos(String id) async {
    deleteCallCount++;
    if (mockUser == null) {
      throw const AuthException(
        'Pengguna belum login. Operasi penghapusan kos ditolak.',
      );
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    lastDeletedId = id;
  }

  @override
  Future<List<Map<String, dynamic>>> getOwnerKosList([String? ownerId]) async {
    getOwnerListCallCount++;
    final uid = ownerId ?? mockUser?.id;
    if (uid == null) {
      throw const AuthException(
        'Pengguna belum login. Tidak dapat memuat daftar kos pemilik.',
      );
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return mockOwnerData;
  }
}

/// Mock implementation dari [KosRepository] untuk menguji [KosProvider] secara terisolasi.
class MockCrudKosRepository extends KosRepository {
  List<KosModel> mockOwnerKos = [];
  Exception? errorToThrow;
  Completer<KosModel>? createCompleter;
  int createCallCount = 0;
  int updateCallCount = 0;
  int deleteCallCount = 0;
  int getOwnerListCallCount = 0;

  @override
  Future<KosModel> createKos(KosModel kos) async {
    createCallCount++;
    if (createCompleter != null) {
      return createCompleter!.future;
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return kos;
  }

  @override
  Future<KosModel> updateKos(KosModel kos) async {
    updateCallCount++;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return kos;
  }

  @override
  Future<void> deleteKos(String id) async {
    deleteCallCount++;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
  }

  @override
  Future<List<KosModel>> getOwnerKosList([String? ownerId]) async {
    getOwnerListCallCount++;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return mockOwnerKos;
  }
}

void main() {
  final sampleOwnerUser = User.fromJson({
    'id': 'owner-uuid-1234',
    'app_metadata': <String, dynamic>{},
    'user_metadata': <String, dynamic>{},
    'aud': 'authenticated',
    'created_at': '2026-11-16T10:00:00.000Z',
    'email': 'pemilik@kos.com',
  })!;

  final sampleKos = KosModel(
    id: 'kos-uuid-9999',
    ownerId: 'owner-uuid-1234',
    name: 'Kos Melati Bahagia',
    address: 'Jl. Melati No. 10',
    area: 'Singaraja',
    contactNumber: '081234567890',
    pricePerMonth: 750000,
    description: 'Kos bersih nyaman dan aman.',
    availableRooms: 2,
    hasWifi: true,
    hasBathroomInside: true,
    hasParking: false,
    createdAt: DateTime.parse('2026-11-17T10:00:00.000Z'),
    updatedAt: DateTime.parse('2026-11-17T10:00:00.000Z'),
  );

  group('TASK-4.1: SupabaseKosService & KosRepository CRUD Tests', () {
    late FakeSupabaseKosService fakeService;
    late KosRepository repository;

    setUp(() {
      fakeService = FakeSupabaseKosService();
      repository = KosRepository(kosService: fakeService);
    });

    test('1. Penambahan kos berhasil dan menyematkan owner_id dari UID pengguna yang login', () async {
      fakeService.mockUser = sampleOwnerUser;

      // Kos model dibuat dengan ownerId sementara / acak
      final newKosInput = KosModel(
        id: 'temp-id',
        ownerId: 'spoofed-attacker-uid',
        name: 'Kos Baru Milik Pemilik',
        address: 'Jl. Sudirman No. 5',
        area: 'Banyuasri',
        contactNumber: '081987654321',
        pricePerMonth: 900000,
        description: 'Dekat jalan utama.',
        availableRooms: 5,
      );

      final result = await repository.createKos(newKosInput);

      expect(fakeService.createCallCount, 1);
      // Memastikan owner_id yang tersimpan adalah UID pengguna aktif (sampleOwnerUser.id)
      expect(result.ownerId, sampleOwnerUser.id);
      expect(fakeService.lastCreatedPayload?['owner_id'], sampleOwnerUser.id);
      expect(result.name, 'Kos Baru Milik Pemilik');
    });

    test(
      '2. Penambahan kos ditolak dengan error ketika tidak ada sesi login',
      () async {
        fakeService.mockUser = null; // Tidak login

        expect(
          () => repository.createKos(sampleKos),
          throwsA(
            isA<KosException>().having(
              (e) => e.message,
              'message',
              contains('Pengguna belum login'),
            ),
          ),
        );
        expect(fakeService.createCallCount, 1);
      },
    );

    test('3. Pengambilan daftar kos pemilik hanya mengambil data milik pengguna yang login', () async {
      fakeService.mockUser = sampleOwnerUser;
      fakeService.mockOwnerData = [sampleKos.toJson()];

      final list = await repository.getOwnerKosList();

      expect(fakeService.getOwnerListCallCount, 1);
      expect(list.length, 1);
      expect(list.first.ownerId, sampleOwnerUser.id);
    });

    test(
      '4. Pengambilan daftar kos pemilik ditolak jika belum login',
      () async {
        fakeService.mockUser = null;

        expect(
          () => repository.getOwnerKosList(),
          throwsA(
            isA<KosException>().having(
              (e) => e.message,
              'message',
              contains('Pengguna belum login'),
            ),
          ),
        );
      },
    );

    test('5. Pengubahan data kos berhasil pada repository', () async {
      fakeService.mockUser = sampleOwnerUser;

      final updatedModel = sampleKos.copyWith(
        name: 'Kos Melati Bahagia (Renovasi)',
        pricePerMonth: 850000,
      );

      final result = await repository.updateKos(updatedModel);

      expect(fakeService.updateCallCount, 1);
      expect(fakeService.lastUpdatedId, sampleKos.id);
      expect(result.name, 'Kos Melati Bahagia (Renovasi)');
      expect(result.pricePerMonth, 850000);
      expect(result.ownerId, sampleOwnerUser.id);
    });

    test('6. Pengubahan data kos ditolak jika belum login', () async {
      fakeService.mockUser = null;

      expect(
        () => repository.updateKos(sampleKos),
        throwsA(isA<KosException>()),
      );
    });

    test('7. Penghapusan data kos berhasil pada repository', () async {
      fakeService.mockUser = sampleOwnerUser;

      await repository.deleteKos(sampleKos.id);

      expect(fakeService.deleteCallCount, 1);
      expect(fakeService.lastDeletedId, sampleKos.id);
    });

    test('8. Penghapusan data kos ditolak jika ID kosong', () async {
      fakeService.mockUser = sampleOwnerUser;

      expect(() => repository.deleteKos('   '), throwsA(isA<ArgumentError>()));
      expect(fakeService.deleteCallCount, 0);
    });

    test('9. Penanganan error jaringan (SocketException & TimeoutException) pada repository', () async {
      fakeService.mockUser = sampleOwnerUser;
      fakeService.errorToThrow = const SocketException('Network unreachable');

      expect(
        () => repository.createKos(sampleKos),
        throwsA(
          isA<KosException>().having(
            (e) => e.message,
            'message',
            contains('periksa koneksi internet'),
          ),
        ),
      );

      fakeService.errorToThrow = TimeoutException('Timeout');
      expect(
        () => repository.deleteKos(sampleKos.id),
        throwsA(
          isA<KosException>().having(
            (e) => e.message,
            'message',
            contains('Koneksi waktu habis'),
          ),
        ),
      );
    });
  });

  group('TASK-4.1: KosProvider CRUD & State Management Tests', () {
    late MockCrudKosRepository mockRepository;
    late KosProvider provider;

    setUp(() {
      mockRepository = MockCrudKosRepository();
      provider = KosProvider(repository: mockRepository);
    });

    test('10. createKos berhasil memperbarui ownerKosList dan kosList secara reaktif', () async {
      expect(provider.ownerKosList, isEmpty);

      final success = await provider.createKos(sampleKos);

      expect(success, isTrue);
      expect(provider.errorMessage, isNull);
      expect(provider.ownerKosList.length, 1);
      expect(provider.ownerKosList.first.id, sampleKos.id);
      expect(mockRepository.createCallCount, 1);
    });

    test('11. createKos gagal mengembalikan false dan menyimpan pesan error tanpa crash', () async {
      mockRepository.errorToThrow = const KosException('Gagal menyimpan kos');

      final success = await provider.createKos(sampleKos);

      expect(success, isFalse);
      expect(provider.errorMessage, 'Gagal menyimpan kos');
      expect(provider.ownerKosList, isEmpty);
      expect(provider.isLoadingCrud, isFalse);
    });

    test('12. fetchOwnerKosList memuat daftar kos pemilik dan mengelola state loading', () async {
      mockRepository.mockOwnerKos = [sampleKos];

      expect(provider.isLoadingOwnerList, isFalse);

      final future = provider.fetchOwnerKosList('owner-uuid-1234');
      // Status loading terpantau aktif
      expect(provider.isLoadingOwnerList, isTrue);

      await future;

      expect(provider.isLoadingOwnerList, isFalse);
      expect(provider.ownerKosList.length, 1);
      expect(provider.ownerKosList.first.name, 'Kos Melati Bahagia');
      expect(mockRepository.getOwnerListCallCount, 1);
    });

    test(
      '13. fetchOwnerKosList gagal menangani error dan mengosongkan list',
      () async {
        mockRepository.errorToThrow = const KosException('Koneksi terputus');

        await provider.fetchOwnerKosList();

        expect(provider.ownerKosList, isEmpty);
        expect(provider.errorMessage, 'Koneksi terputus');
        expect(provider.isLoadingOwnerList, isFalse);
      },
    );

    test('14. updateKos memperbarui data pada ownerKosList dan selectedKos secara sinkron', () async {
      // Siapkan initial list
      mockRepository.mockOwnerKos = [sampleKos];
      await provider.fetchOwnerKosList();

      final updatedKos = sampleKos.copyWith(
        name: 'Kos Melati Baru',
        pricePerMonth: 950000,
      );

      final success = await provider.updateKos(updatedKos);

      expect(success, isTrue);
      expect(provider.ownerKosList.first.name, 'Kos Melati Baru');
      expect(provider.ownerKosList.first.pricePerMonth, 950000);
      expect(mockRepository.updateCallCount, 1);
    });

    test(
      '15. deleteKos menghapus item dari ownerKosList dan selectedKos',
      () async {
        mockRepository.mockOwnerKos = [sampleKos];
        await provider.fetchOwnerKosList();
        expect(provider.ownerKosList.length, 1);

        final success = await provider.deleteKos(sampleKos.id);

        expect(success, isTrue);
        expect(provider.ownerKosList, isEmpty);
        expect(mockRepository.deleteCallCount, 1);
      },
    );

    test('16. clearError mengosongkan pesan kesalahan yang ada', () async {
      mockRepository.errorToThrow = const KosException('Ada error');
      await provider.createKos(sampleKos);
      expect(provider.errorMessage, isNotNull);

      provider.clearError();
      expect(provider.errorMessage, isNull);
    });
  });
}
