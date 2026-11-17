import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos_model.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/repositories/kos_repository.dart';
import 'package:kosfinder/services/supabase_kos_service.dart';
import 'package:kosfinder/widgets/owner_kos_card_widget.dart';
import 'package:kosfinder/widgets/update_rooms_dialog.dart';
import 'package:provider/provider.dart';

/// Fake Service khusus pengujian widget UpdateRoomsDialog.
class FakeServiceForDialogTest extends SupabaseKosService {
  int updateCallCount = 0;
  int? lastNewRooms;
  Completer<Map<String, dynamic>>? asyncCompleter;
  Exception? errorToThrow;

  @override
  Future<Map<String, dynamic>> updateAvailableRooms(
    String kosId,
    int newRooms,
  ) async {
    updateCallCount++;
    lastNewRooms = newRooms;

    if (asyncCompleter != null) {
      return asyncCompleter!.future;
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }

    return {
      'id': kosId,
      'owner_id': 'owner-1',
      'name': 'Kos Anggrek Indah',
      'address': 'Jl. Udayana No. 10',
      'area': 'Banyuasri',
      'contact_number': '081234567890',
      'price_per_month': 800000,
      'description': 'Kos asri dan nyaman.',
      'available_rooms': newRooms,
      'has_wifi': true,
      'has_bathroom_inside': true,
      'has_parking': false,
      'created_at': '2026-11-17T08:00:00.000Z',
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

void main() {
  group('TASK-5.2: UpdateRoomsDialog Widget Tests', () {
    late FakeServiceForDialogTest fakeService;
    late KosRepository repository;
    late KosProvider provider;

    final sampleKos = KosModel(
      id: 'kos-test-001',
      ownerId: 'owner-1',
      name: 'Kos Anggrek Indah',
      address: 'Jl. Udayana No. 10',
      area: 'Banyuasri',
      contactNumber: '081234567890',
      pricePerMonth: 800000,
      description: 'Kos asri dan nyaman.',
      availableRooms: 5,
      hasWifi: true,
      hasBathroomInside: true,
      hasParking: false,
    );

    setUp(() {
      fakeService = FakeServiceForDialogTest();
      repository = KosRepository(kosService: fakeService);
      provider = KosProvider(repository: repository);
    });

    Widget createWidgetUnderTest(Widget child) {
      return ChangeNotifierProvider<KosProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('1. Dialog menampilkan nama kos, kamar saat ini, dan input awal', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(UpdateRoomsDialog(kos: sampleKos)),
      );

      expect(find.text('Perbarui Ketersediaan Kamar'), findsOneWidget);
      expect(find.text('Kos Anggrek Indah'), findsOneWidget);
      expect(find.text('Kamar saat ini: 5 kamar'), findsOneWidget);

      final inputFinder = find.byKey(const Key('update_rooms_input'));
      expect(inputFinder, findsOneWidget);

      final textField = tester.widget<TextFormField>(inputFinder);
      expect(textField.controller?.text, equals('5'));
    });

    testWidgets('2. Simpan nilai valid 2 berhasil memanggil provider dan menutup dialog', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => UpdateRoomsDialog(kos: sampleKos),
                  );
                },
                child: const Text('Buka Dialog'),
              );
            },
          ),
        ),
      );

      // Buka dialog
      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      // Ubah angka kamar menjadi 2
      final inputFinder = find.byKey(const Key('update_rooms_input'));
      await tester.enterText(inputFinder, '2');
      await tester.pumpAndSettle();

      // Tekan tombol Simpan
      await tester.tap(find.byKey(const Key('btn_save_update_rooms')));
      await tester.pumpAndSettle();

      // Pastikan service dipanggil dengan nilai 2
      expect(fakeService.updateCallCount, equals(1));
      expect(fakeService.lastNewRooms, equals(2));

      // Dialog harus tertutup
      expect(find.text('Perbarui Ketersediaan Kamar'), findsNothing);

      // SnackBar sukses tampil
      expect(find.text('Jumlah kamar berhasil diperbarui!'), findsOneWidget);
    });

    testWidgets('3. Simpan nilai 0 (Kamar Penuh) berhasil disimpan', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => UpdateRoomsDialog(kos: sampleKos),
                  );
                },
                child: const Text('Buka Dialog'),
              );
            },
          ),
        ),
      );

      // Buka dialog
      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      // Ubah angka kamar menjadi 0
      final inputFinder = find.byKey(const Key('update_rooms_input'));
      await tester.enterText(inputFinder, '0');
      await tester.pumpAndSettle();

      // Tekan tombol Simpan
      await tester.tap(find.byKey(const Key('btn_save_update_rooms')));
      await tester.pumpAndSettle();

      expect(fakeService.updateCallCount, equals(1));
      expect(fakeService.lastNewRooms, equals(0));
      expect(find.text('Jumlah kamar berhasil diperbarui!'), findsOneWidget);
    });

    testWidgets('4. Tombol Batal menutup dialog tanpa memanggil service', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => UpdateRoomsDialog(kos: sampleKos),
                  );
                },
                child: const Text('Buka Dialog'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      // Tekan Batal
      await tester.tap(find.byKey(const Key('btn_cancel_update_rooms')));
      await tester.pumpAndSettle();

      expect(fakeService.updateCallCount, equals(0));
      expect(find.text('Perbarui Ketersediaan Kamar'), findsNothing);
    });

    testWidgets('5. Input kosong ditolak dengan pesan validasi', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(UpdateRoomsDialog(kos: sampleKos)),
      );

      final inputFinder = find.byKey(const Key('update_rooms_input'));
      await tester.enterText(inputFinder, '');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_save_update_rooms')));
      await tester.pumpAndSettle();

      expect(find.text('Jumlah kamar tidak boleh kosong.'), findsOneWidget);
      expect(fakeService.updateCallCount, equals(0));
    });

    testWidgets('6. Loading indicator muncul saat proses dan mencegah double submit', (
      tester,
    ) async {
      fakeService.asyncCompleter = Completer<Map<String, dynamic>>();

      await tester.pumpWidget(
        createWidgetUnderTest(UpdateRoomsDialog(kos: sampleKos)),
      );

      final inputFinder = find.byKey(const Key('update_rooms_input'));
      await tester.enterText(inputFinder, '3');
      await tester.pumpAndSettle();

      // Tap Simpan pertama kali
      await tester.tap(find.byKey(const Key('btn_save_update_rooms')));
      await tester.pump();

      // Loading indicator harus muncul
      expect(find.byKey(const Key('update_rooms_loading_indicator')), findsOneWidget);

      // Tap lagi saat proses loading berlangsung (harus diabaikan)
      await tester.tap(find.byKey(const Key('btn_save_update_rooms')));
      await tester.pump();
      expect(fakeService.updateCallCount, equals(1));

      // Selesaikan proses async
      fakeService.asyncCompleter!.complete({
        'id': sampleKos.id,
        'owner_id': sampleKos.ownerId,
        'name': sampleKos.name,
        'address': sampleKos.address,
        'area': sampleKos.area,
        'contact_number': sampleKos.contactNumber,
        'price_per_month': sampleKos.pricePerMonth,
        'description': sampleKos.description,
        'available_rooms': 3,
        'has_wifi': true,
        'has_bathroom_inside': true,
        'has_parking': false,
        'created_at': '2026-11-17T08:00:00.000Z',
        'updated_at': DateTime.now().toIso8601String(),
      });
      await tester.pumpAndSettle();
    });

    testWidgets('7. Kesalahan jaringan mempertahankan input pengguna dan menampilkan pesan error', (
      tester,
    ) async {
      fakeService.errorToThrow = const SocketException('Tidak ada koneksi internet');

      await tester.pumpWidget(
        createWidgetUnderTest(UpdateRoomsDialog(kos: sampleKos)),
      );

      final inputFinder = find.byKey(const Key('update_rooms_input'));
      await tester.enterText(inputFinder, '4');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_save_update_rooms')));
      await tester.pumpAndSettle();

      // Input harus tetap bernilai '4'
      final textField = tester.widget<TextFormField>(inputFinder);
      expect(textField.controller?.text, equals('4'));

      // Pesan error harus ditampilkan
      expect(find.textContaining('koneksi internet'), findsOneWidget);
    });

    testWidgets('8. Tombol Update Kamar pada OwnerKosCardWidget membuka dialog', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          OwnerKosCardWidget(kos: sampleKos),
        ),
      );

      final btnUpdateFinder = find.byKey(Key('btn_update_rooms_${sampleKos.id}'));
      expect(btnUpdateFinder, findsOneWidget);

      await tester.tap(btnUpdateFinder);
      await tester.pumpAndSettle();

      expect(find.text('Perbarui Ketersediaan Kamar'), findsOneWidget);
    });
  });
}
