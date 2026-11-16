import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos_model.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/repositories/kos_repository.dart';

/// Mock implementasi [KosRepository] untuk menguji [KosProvider] secara terisolasi.
class MockKosRepository extends KosRepository {
  List<KosModel>? mockKosList;
  KosModel? mockKosDetail;
  Exception? errorToThrow;
  Completer<List<KosModel>>? listCompleter;
  Completer<KosModel?>? detailCompleter;
  final List<Completer<List<KosModel>>> multipleListCompleters = [];
  int getKosListCallCount = 0;
  int getKosDetailCallCount = 0;

  @override
  Future<List<KosModel>> getKosList() async {
    getKosListCallCount++;
    if (multipleListCompleters.isNotEmpty) {
      final index = getKosListCallCount - 1;
      if (index < multipleListCompleters.length) {
        return multipleListCompleters[index].future;
      }
    }
    if (listCompleter != null) {
      return listCompleter!.future;
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return mockKosList ?? [];
  }

  @override
  Future<KosModel?> getKosDetailById(String id) async {
    getKosDetailCallCount++;
    if (detailCompleter != null) {
      return detailCompleter!.future;
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return mockKosDetail;
  }
}

void main() {
  group('KosProvider Unit Tests', () {
    late MockKosRepository mockRepository;
    late KosProvider provider;

    final sampleKos = KosModel(
      id: 'c1111111-1111-1111-1111-111111111111',
      ownerId: 'd2222222-2222-2222-2222-222222222222',
      name: 'Kos Singaraja Indah',
      address: 'Jl. Ngurah Rai No. 20',
      area: 'Singaraja Kota',
      contactNumber: '081999888777',
      pricePerMonth: 650000,
      description: 'Kos strategis dekat fasilitas umum.',
      availableRooms: 1,
      hasWifi: true,
      hasBathroomInside: true,
      hasParking: true,
      createdAt: DateTime.parse('2026-11-16T08:00:00.000Z'),
      updatedAt: DateTime.parse('2026-11-16T08:00:00.000Z'),
    );

    setUp(() {
      mockRepository = MockKosRepository();
      provider = KosProvider(repository: mockRepository);
    });

    test('1. Kondisi awal Provider memiliki nilai default yang benar', () {
      expect(provider.isLoading, isFalse);
      expect(provider.isLoadingList, isFalse);
      expect(provider.isLoadingDetail, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.kosList, isEmpty);
      expect(provider.selectedKos, isNull);
    });

    test('2. Transisi loading terpantau dengan benar saat pengambilan data dimulai dan selesai', () async {
      final completer = Completer<List<KosModel>>();
      mockRepository.listCompleter = completer;

      // Panggil pengambilan data tanpa menunggu (future masih pending)
      final future = provider.fetchKosList();

      // Verifikasi status saat sedang memuat
      expect(provider.isLoading, isTrue);
      expect(provider.isLoadingList, isTrue);
      expect(provider.errorMessage, isNull);

      // Selesaikan future dengan data
      completer.complete([sampleKos]);
      await future;

      // Verifikasi status setelah selesai
      expect(provider.isLoading, isFalse);
      expect(provider.isLoadingList, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.kosList, hasLength(1));
    });

    test('3. Pengambilan daftar kos berhasil mengisi kosList dan membersihkan error', () async {
      mockRepository.mockKosList = [sampleKos];

      await provider.fetchKosList();

      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.kosList, hasLength(1));
      expect(provider.kosList.first.name, 'Kos Singaraja Indah');
    });

    test('4. Penanganan daftar kos kosong tetap berhasil tanpa menimbulkan pesan error', () async {
      mockRepository.mockKosList = [];

      await provider.fetchKosList();

      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.kosList, isEmpty);
    });

    test('5. Penanganan kegagalan jaringan saat memuat daftar kos memperbarui errorMessage', () async {
      mockRepository.errorToThrow = const KosException(
        'Gagal memuat data kos. Silakan periksa koneksi internet Anda.',
      );

      await provider.fetchKosList();

      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, 'Gagal memuat data kos. Silakan periksa koneksi internet Anda.');
      expect(provider.kosList, isEmpty);
    });

    test('6. Pengambilan ulang data yang gagal mengosongkan kosList agar data lama tidak tertampil', () async {
      // Tahap 1: Pengambilan awal berhasil
      mockRepository.mockKosList = [sampleKos];
      await provider.fetchKosList();
      expect(provider.kosList, hasLength(1));
      expect(provider.errorMessage, isNull);

      // Tahap 2: Pengambilan ulang (refresh/retry) mengalami kegagalan jaringan
      mockRepository.errorToThrow = const KosException(
        'Koneksi terputus saat memperbarui data.',
      );
      await provider.fetchKosList();

      // Verifikasi: kosList harus dikosongkan agar data lama tidak dianggap hasil terbaru
      expect(provider.kosList, isEmpty);
      expect(provider.errorMessage, 'Koneksi terputus saat memperbarui data.');
      expect(provider.isLoading, isFalse);
    });

    test('7. Pengambilan detail kos berhasil memperbarui selectedKos', () async {
      mockRepository.mockKosDetail = sampleKos;

      await provider.fetchKosDetail('c1111111-1111-1111-1111-111111111111');

      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.selectedKos, equals(sampleKos));
    });

    test('8. Pengambilan detail kos yang tidak ditemukan mengeset pesan not found', () async {
      mockRepository.mockKosDetail = null;

      await provider.fetchKosDetail('unknown-id');

      expect(provider.isLoading, isFalse);
      expect(provider.selectedKos, isNull);
      expect(provider.errorMessage, 'Kos tidak ditemukan atau sudah tidak tersedia.');
    });

    test('9. Pengambilan detail kos yang gagal karena error jaringan memperbarui errorMessage dan mengosongkan selectedKos', () async {
      mockRepository.errorToThrow = const KosException(
        'Gagal memuat detail kos. Periksa koneksi Anda.',
      );

      await provider.fetchKosDetail('c1111111-1111-1111-1111-111111111111');

      expect(provider.isLoading, isFalse);
      expect(provider.selectedKos, isNull);
      expect(provider.errorMessage, 'Gagal memuat detail kos. Periksa koneksi Anda.');
    });

    test('10. Operasi asynchronous daftar dan detail yang berjalan bersamaan tidak menyebabkan benturan status loading', () async {
      final listCompleter = Completer<List<KosModel>>();
      final detailCompleter = Completer<KosModel?>();
      mockRepository.listCompleter = listCompleter;
      mockRepository.detailCompleter = detailCompleter;

      // Jalankan kedua operasi bersamaan
      final listFuture = provider.fetchKosList();
      final detailFuture = provider.fetchKosDetail('c1111111-1111-1111-1111-111111111111');

      // Verifikasi keduanya aktif memuat
      expect(provider.isLoading, isTrue);
      expect(provider.isLoadingList, isTrue);
      expect(provider.isLoadingDetail, isTrue);

      // Selesaikan operasi detail terlebih dahulu
      detailCompleter.complete(sampleKos);
      await detailFuture;

      // Verifikasi: detail selesai, tetapi daftar MASIH memuat, sehingga isLoading umum HARUS tetap true
      expect(provider.isLoadingDetail, isFalse);
      expect(provider.isLoadingList, isTrue);
      expect(provider.isLoading, isTrue, reason: 'isLoading tidak boleh false jika masih ada operasi daftar yang berjalan');
      expect(provider.selectedKos, equals(sampleKos));

      // Selesaikan operasi daftar
      listCompleter.complete([sampleKos]);
      await listFuture;

      // Verifikasi: seluruh operasi selesai, isLoading menjadi false
      expect(provider.isLoadingList, isFalse);
      expect(provider.isLoadingDetail, isFalse);
      expect(provider.isLoading, isFalse);
      expect(provider.kosList, hasLength(1));
    });

    test('11. Dua permintaan fetchKosList() bersamaan dicegah dari race condition menggunakan request counter', () async {
      final completer1 = Completer<List<KosModel>>();
      final completer2 = Completer<List<KosModel>>();
      mockRepository.multipleListCompleters.addAll([completer1, completer2]);

      // Panggil pemanggilan pertama
      final future1 = provider.fetchKosList();
      expect(provider.isLoadingList, isTrue);
      expect(provider.isLoading, isTrue);

      // Panggil pemanggilan kedua saat yang pertama masih pending
      final future2 = provider.fetchKosList();
      expect(provider.isLoadingList, isTrue);
      expect(provider.isLoading, isTrue);

      // Selesaikan pemanggilan pertama lebih dahulu
      completer1.complete([sampleKos]);
      await future1;

      // Verifikasi: pemanggilan pertama selesai, namun pemanggilan kedua masih berjalan
      // isLoadingList dan isLoading HARUS tetap true
      expect(
        provider.isLoadingList,
        isTrue,
        reason: 'isLoadingList harus tetap true karena pemanggilan kedua masih berjalan',
      );
      expect(
        provider.isLoading,
        isTrue,
        reason: 'isLoading harus tetap true karena pemanggilan kedua masih berjalan',
      );

      // Selesaikan pemanggilan kedua
      completer2.complete([sampleKos]);
      await future2;

      // Verifikasi: seluruh pemanggilan daftar selesai, status loading menjadi false
      expect(provider.isLoadingList, isFalse);
      expect(provider.isLoading, isFalse);
    });

    test('12. Retry memanggil ulang pengambilan daftar kos publik', () async {
      mockRepository.mockKosList = [sampleKos];

      await provider.retryFetchKosList();

      expect(mockRepository.getKosListCallCount, 1);
      expect(provider.kosList, hasLength(1));

      // Panggil retry kedua kali
      await provider.retryFetchKosList();
      expect(mockRepository.getKosListCallCount, 2);
    });
  });
}
