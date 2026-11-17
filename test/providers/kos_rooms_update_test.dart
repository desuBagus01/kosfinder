import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos_model.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/repositories/kos_repository.dart';
import 'package:kosfinder/services/supabase_kos_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fake implementation dari [SupabaseKosService] untuk pengujian unit pembaruan kamar.
class FakeSupabaseKosServiceForRooms extends SupabaseKosService {
  User? mockUser;
  Exception? errorToThrow;
  String? lastUpdatedKosId;
  int? lastUpdatedRooms;
  Map<String, dynamic>? mockResponseData;

  @override
  Future<Map<String, dynamic>> updateAvailableRooms(
    String kosId,
    int newRooms,
  ) async {
    if (mockUser == null) {
      throw const AuthException(
        'Pengguna belum login. Operasi pembaruan kamar ditolak.',
      );
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    if (newRooms < 0) {
      throw ArgumentError('Jumlah kamar tidak boleh kurang dari 0');
    }

    lastUpdatedKosId = kosId;
    lastUpdatedRooms = newRooms;

    if (mockResponseData != null) {
      final updated = Map<String, dynamic>.from(mockResponseData!);
      updated['available_rooms'] = newRooms;
      updated['updated_at'] = DateTime.now().toIso8601String();
      return updated;
    }

    return {
      'id': kosId,
      'owner_id': mockUser!.id,
      'name': 'Kos Melati Singaraja',
      'address': 'Jl. Ahmad Yani No. 12',
      'area': 'Banyuasri',
      'contact_number': '081234567890',
      'price_per_month': 850000,
      'description': 'Kos bersih dan nyaman.',
      'available_rooms': newRooms,
      'has_wifi': true,
      'has_bathroom_inside': true,
      'has_parking': true,
      'created_at': '2026-11-17T08:00:00.000Z',
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

void main() {
  group('TASK-5.1: updateAvailableRooms Unit Tests', () {
    late FakeSupabaseKosServiceForRooms fakeService;
    late KosRepository repository;
    late KosProvider provider;

    final mockOwnerUser = User(
      id: 'owner-uuid-1111',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    );

    final initialKos = KosModel(
      id: 'kos-uuid-001',
      ownerId: 'owner-uuid-1111',
      name: 'Kos Melati Singaraja',
      address: 'Jl. Ahmad Yani No. 12',
      area: 'Banyuasri',
      contactNumber: '081234567890',
      pricePerMonth: 850000,
      description: 'Kos bersih dan nyaman.',
      availableRooms: 5,
      hasWifi: true,
      hasBathroomInside: true,
      hasParking: true,
    );

    setUp(() {
      fakeService = FakeSupabaseKosServiceForRooms();
      fakeService.mockUser = mockOwnerUser;
      fakeService.mockResponseData = initialKos.toJson();
      repository = KosRepository(kosService: fakeService);
      provider = KosProvider(repository: repository);
    });

    test('1. Jumlah kamar berhasil diperbarui dari 5 menjadi 2', () async {
      final result = await repository.updateAvailableRooms('kos-uuid-001', 2);

      expect(result.availableRooms, equals(2));
      expect(fakeService.lastUpdatedKosId, equals('kos-uuid-001'));
      expect(fakeService.lastUpdatedRooms, equals(2));
    });

    test('2. Jumlah kamar 0 (Kamar Penuh) berhasil disimpan', () async {
      final result = await repository.updateAvailableRooms('kos-uuid-001', 0);

      expect(result.availableRooms, equals(0));
      expect(fakeService.lastUpdatedRooms, equals(0));
    });

    test('3. Jumlah kamar negatif ditolak dengan pesan kesalahan', () async {
      // Uji pada Repository
      expect(
        () => repository.updateAvailableRooms('kos-uuid-001', -1),
        throwsA(
          isA<KosException>().having(
            (e) => e.message,
            'message',
            'Jumlah kamar tidak boleh kurang dari 0',
          ),
        ),
      );

      // Uji pada Provider
      final success = await provider.updateAvailableRooms('kos-uuid-001', -1);
      expect(success, isFalse);
      expect(
        provider.errorMessage,
        equals('Jumlah kamar tidak boleh kurang dari 0'),
      );
    });

    test('4. Pengguna yang belum login tidak dapat memperbarui kamar', () async {
      fakeService.mockUser = null; // Simulasi belum login

      // Repository melempar KosException
      expect(
        () => repository.updateAvailableRooms('kos-uuid-001', 3),
        throwsA(isA<KosException>()),
      );

      // Provider mengembalikan false dan menyimpan pesan error
      final success = await provider.updateAvailableRooms('kos-uuid-001', 3);
      expect(success, isFalse);
      expect(provider.errorMessage, isNotNull);
      expect(provider.errorMessage, contains('belum login'));
    });

    test('5. Pemilik tidak dapat memperbarui kos milik pengguna lain (RLS)', () async {
      // Simulasi backend merespons error otorisasi RLS (PostgrestException / 403)
      fakeService.errorToThrow = const PostgrestException(
        message: 'Tidak ada baris yang diperbarui karena pembatasan kepemilikan RLS.',
        code: '42501',
      );

      expect(
        () => repository.updateAvailableRooms('kos-other-owner', 3),
        throwsA(isA<KosException>()),
      );

      final success = await provider.updateAvailableRooms('kos-other-owner', 3);
      expect(success, isFalse);
      expect(provider.errorMessage, isNotNull);
    });

    test('6. State Provider diperbarui setelah operasi berhasil (ownerKosList, kosList, selectedKos)', () async {
      // Siapkan data awal di dalam provider
      await provider.createKos(initialKos);
      await provider.fetchKosDetail('kos-uuid-001');

      expect(provider.ownerKosList.first.availableRooms, equals(5));
      expect(provider.selectedKos?.availableRooms, equals(5));

      // Lakukan pembaruan jumlah kamar
      final success = await provider.updateAvailableRooms('kos-uuid-001', 2);

      expect(success, isTrue);
      expect(provider.errorMessage, isNull);
      expect(provider.ownerKosList.first.availableRooms, equals(2));
      expect(provider.selectedKos?.availableRooms, equals(2));
    });

    test('7. State Provider tidak berubah ketika operasi gagal', () async {
      // Siapkan data awal di dalam provider
      await provider.createKos(initialKos);
      expect(provider.ownerKosList.first.availableRooms, equals(5));

      // Pasang error pada service
      fakeService.errorToThrow = const PostgrestException(
        message: 'Gagal memperbarui',
      );

      final success = await provider.updateAvailableRooms('kos-uuid-001', 2);

      expect(success, isFalse);
      expect(provider.errorMessage, isNotNull);
      // State ownerKosList tetap 5 (tidak berubah)
      expect(provider.ownerKosList.first.availableRooms, equals(5));
    });
  });
}
