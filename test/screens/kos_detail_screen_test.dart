import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos_model.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/repositories/kos_repository.dart';
import 'package:kosfinder/screens/kos_detail_screen.dart';
import 'package:kosfinder/screens/kos_list_screen.dart';
import 'package:provider/provider.dart';

/// Mock repository untuk mengendalikan data yang disajikan ke [KosProvider].
class MockKosRepository extends KosRepository {
  List<KosModel>? mockKosList;
  KosModel? mockKosDetail;
  Exception? errorToThrow;

  /// Jika diset, [getKosDetailById] akan menunggu completer ini sebelum return.
  /// Digunakan untuk menguji kondisi loading sementara future belum selesai.
  Completer<KosModel?>? detailCompleter;

  @override
  Future<List<KosModel>> getKosList() async {
    if (errorToThrow != null) throw errorToThrow!;
    return mockKosList ?? [];
  }

  @override
  Future<KosModel?> getKosDetailById(String id) async {
    if (errorToThrow != null) throw errorToThrow!;
    if (detailCompleter != null) return detailCompleter!.future;
    return mockKosDetail;
  }
}

void main() {
  final sampleKos = KosModel(
    id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    ownerId: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    name: 'Kos Melati Singaraja',
    address: 'Jl. Udayana No. 11, Singaraja, Bali',
    area: 'Banyuasri',
    contactNumber: '081234567890',
    pricePerMonth: 850000,
    description: 'Kos nyaman, bersih, dan dekat kampus Undiksha Singaraja.',
    availableRooms: 3,
    hasWifi: true,
    hasBathroomInside: true,
    hasParking: false,
    createdAt: DateTime.parse('2026-11-16T10:00:00.000Z'),
    updatedAt: DateTime.parse('2026-11-16T10:00:00.000Z'),
  );

  final fullKos = KosModel(
    id: 'cccccccc-cccc-cccc-cccc-cccccccccccc',
    ownerId: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    name: 'Kos Kenanga Penuh',
    address: 'Jl. Sudirman No. 55',
    area: 'Kaliuntu',
    contactNumber: '081999888777',
    pricePerMonth: 1200000,
    description: 'Kos premium dekat pusat kota.',
    availableRooms: 0, // Kamar Penuh
    hasWifi: true,
    hasBathroomInside: true,
    hasParking: true,
    createdAt: DateTime.parse('2026-11-16T11:00:00.000Z'),
    updatedAt: DateTime.parse('2026-11-16T11:00:00.000Z'),
  );

  group('KosDetailScreen Widget Tests', () {
    late MockKosRepository mockRepository;
    late KosProvider provider;

    setUp(() {
      mockRepository = MockKosRepository();
      provider = KosProvider(repository: mockRepository);
    });

    Widget buildDetailScreen(String kosId) {
      return ChangeNotifierProvider<KosProvider>.value(
        value: provider,
        child: MaterialApp(home: KosDetailScreen(kosId: kosId)),
      );
    }

    Widget buildListScreen() {
      return ChangeNotifierProvider<KosProvider>.value(
        value: provider,
        child: const MaterialApp(home: KosListScreen()),
      );
    }

    testWidgets(
      '1. Navigasi dari daftar ke detail berjalan saat kartu kos ditekan (AC04-1)',
      (tester) async {
        mockRepository.mockKosList = [sampleKos];
        mockRepository.mockKosDetail = sampleKos;

        await tester.pumpWidget(buildListScreen());
        await tester.pumpAndSettle();

        // Verifikasi kartu kos tampil di daftar
        expect(find.text('Kos Melati Singaraja'), findsOneWidget);

        // Ketuk kartu kos untuk navigasi ke halaman detail
        await tester.tap(find.text('Kos Melati Singaraja'));
        await tester.pumpAndSettle();

        // Verifikasi halaman detail berhasil dibuka
        expect(find.byType(KosDetailScreen), findsOneWidget);
        expect(find.text('Detail Kos'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Seluruh 7 komponen rincian kos tampil lengkap tanpa login (AC04-1)',
      (tester) async {
        mockRepository.mockKosDetail = sampleKos;

        await tester.pumpWidget(buildDetailScreen(sampleKos.id));
        await tester.pumpAndSettle();

        // 1. Nama kos
        expect(find.text('Kos Melati Singaraja'), findsOneWidget);
        // 2. Alamat lengkap
        expect(
          find.text('Jl. Udayana No. 11, Singaraja, Bali'),
          findsOneWidget,
        );
        // 3. Harga per bulan (Rp/bulan)
        expect(find.text('Rp 850.000/bulan'), findsOneWidget);
        // 4. Fasilitas WiFi (aktif)
        expect(find.text('WiFi'), findsOneWidget);
        // 5. Fasilitas Kamar Mandi Dalam (aktif)
        expect(find.text('Kamar Mandi Dalam'), findsOneWidget);
        // 6. Fasilitas Parkir
        expect(find.text('Parkir'), findsOneWidget);
        // 7. Deskripsi kos
        expect(
          find.text('Kos nyaman, bersih, dan dekat kampus Undiksha Singaraja.'),
          findsOneWidget,
        );
        // 8. Jumlah kamar tersedia
        expect(find.text('Sisa 3 kamar'), findsOneWidget);
        // 9. Nomor kontak pemilik (FR06, US04 poin ke-7)
        expect(find.text('081234567890'), findsOneWidget);

        // Verifikasi tidak ada dialog atau hambatan login
        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets(
      '3. Status "Kamar Penuh" tampil ketika available_rooms bernilai 0',
      (tester) async {
        mockRepository.mockKosDetail = fullKos;

        await tester.pumpWidget(buildDetailScreen(fullKos.id));
        await tester.pumpAndSettle();

        // Verifikasi badge Kamar Penuh muncul pada halaman detail
        expect(find.text('Kamar Penuh'), findsOneWidget);
        expect(find.text('Sisa 0 kamar'), findsNothing);
      },
    );

    testWidgets(
      '4. Pesan "tidak ditemukan" dan tombol Kembali muncul ketika ID kos tidak ada (AC04-2)',
      (tester) async {
        // null dikembalikan oleh mock → kos tidak ditemukan
        mockRepository.mockKosDetail = null;

        await tester.pumpWidget(buildDetailScreen('id-tidak-ada'));
        await tester.pumpAndSettle();

        // Verifikasi pesan not found
        expect(
          find.text('Kos tidak ditemukan atau sudah tidak tersedia'),
          findsOneWidget,
        );
        // Verifikasi tombol Kembali tersedia
        expect(find.widgetWithText(ElevatedButton, 'Kembali'), findsOneWidget);
      },
    );

    testWidgets(
      '5. Pesan error jaringan dan tombol Kembali muncul saat koneksi gagal (AC04-3)',
      (tester) async {
        mockRepository.errorToThrow = const KosException(
          'Gagal memuat detail kos. Periksa koneksi Anda.',
        );

        await tester.pumpWidget(buildDetailScreen(sampleKos.id));
        await tester.pumpAndSettle();

        // Verifikasi pesan error jaringan muncul
        expect(
          find.text('Gagal memuat detail kos. Periksa koneksi Anda.'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
        // Verifikasi tombol Kembali tersedia
        expect(find.widgetWithText(ElevatedButton, 'Kembali'), findsOneWidget);
      },
    );

    testWidgets('6. Indikator loading muncul saat detail kos sedang diambil', (
      tester,
    ) async {
      // Gunakan Completer agar getKosDetailById belum selesai
      // sehingga isLoadingDetail tetap true saat kita memeriksa widget.
      final completer = Completer<KosModel?>();
      mockRepository.detailCompleter = completer;

      await tester.pumpWidget(buildDetailScreen(sampleKos.id));
      // pump pertama: render frame awal + jalankan addPostFrameCallback
      // → fetchKosDetail() mulai, _activeDetailRequests bertambah, isLoadingDetail = true
      await tester.pump();

      // Verifikasi indikator loading tampil (future belum selesai)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Selesaikan completer agar tidak ada resource leak
      completer.complete(null);
      await tester.pumpAndSettle();
    });

    testWidgets(
      '7. Fasilitas yang tidak tersedia ditampilkan sebagai chip non-aktif',
      (tester) async {
        // sampleKos: hasWifi=true, hasBathroomInside=true, hasParking=false
        mockRepository.mockKosDetail = sampleKos;

        await tester.pumpWidget(buildDetailScreen(sampleKos.id));
        await tester.pumpAndSettle();

        // Verifikasi semua 3 chip fasilitas tetap tampil (baik aktif maupun tidak aktif)
        expect(find.text('WiFi'), findsOneWidget);
        expect(find.text('Kamar Mandi Dalam'), findsOneWidget);
        expect(find.text('Parkir'), findsOneWidget);
      },
    );

    testWidgets('8. Tombol Telepon dan WhatsApp tampil di halaman detail (FR06)', (tester) async {
      mockRepository.mockKosDetail = sampleKos;

      await tester.pumpWidget(buildDetailScreen(sampleKos.id));
      await tester.pumpAndSettle();

      // Verifikasi kedua tombol kontak tampil
      expect(find.byKey(const Key('btn_phone')), findsOneWidget);
      expect(find.byKey(const Key('btn_whatsapp')), findsOneWidget);
      expect(find.text('Telepon'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
    });
  });

  // ─── Unit test normalisasi nomor WhatsApp ────────────────────────────────
  group('normalizeWhatsAppNumber Unit Tests', () {
    test('9. Nomor 08xxx dinormalisasi menjadi 628xxx', () {
      expect(
        KosDetailScreen.normalizeWhatsAppNumber('081234567890'),
        equals('6281234567890'),
      );
    });

    test('10. Nomor 8xxx (tanpa awalan 0) ditambahkan awalan 62', () {
      expect(
        KosDetailScreen.normalizeWhatsAppNumber('81234567890'),
        equals('6281234567890'),
      );
    });

    test('11. Nomor yang sudah berawalan 62 tidak diubah', () {
      expect(
        KosDetailScreen.normalizeWhatsAppNumber('6281234567890'),
        equals('6281234567890'),
      );
    });

    test('12. Karakter non-digit dihapus sebelum normalisasi', () {
      expect(
        KosDetailScreen.normalizeWhatsAppNumber('+62 812-3456-7890'),
        equals('6281234567890'),
      );
    });

    test('13. Nomor 081999888777 dinormalisasi menjadi 6281999888777', () {
      expect(
        KosDetailScreen.normalizeWhatsAppNumber('081999888777'),
        equals('6281999888777'),
      );
    });
  });
}
