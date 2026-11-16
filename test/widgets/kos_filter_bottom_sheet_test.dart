import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos_model.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/repositories/kos_repository.dart';
import 'package:kosfinder/screens/kos_list_screen.dart';
import 'package:kosfinder/widgets/kos_filter_bottom_sheet.dart';
import 'package:provider/provider.dart';

class MockFilterKosRepository extends KosRepository {
  List<KosModel> allKos = [];
  int? lastMaxPrice;
  bool lastWifi = false;
  bool lastBathroom = false;
  bool lastParking = false;
  String lastKeyword = '';
  int getKosListFilteredCallCount = 0;

  @override
  Future<List<KosModel>> getKosList() async => allKos;

  @override
  Future<List<KosModel>> getKosListFiltered({
    String keyword = '',
    int? maxPrice,
    bool mustHaveWifi = false,
    bool mustHaveBathroom = false,
    bool mustHaveParking = false,
  }) async {
    getKosListFilteredCallCount++;
    lastKeyword = keyword;
    lastMaxPrice = maxPrice;
    lastWifi = mustHaveWifi;
    lastBathroom = mustHaveBathroom;
    lastParking = mustHaveParking;

    return allKos.where((kos) {
      if (maxPrice != null && kos.pricePerMonth > maxPrice) return false;
      if (mustHaveWifi && !kos.hasWifi) return false;
      if (mustHaveBathroom && !kos.hasBathroomInside) return false;
      if (mustHaveParking && !kos.hasParking) return false;
      if (keyword.isNotEmpty) {
        final kw = keyword.toLowerCase();
        final matchName = kos.name.toLowerCase().contains(kw);
        final matchArea = kos.area.toLowerCase().contains(kw);
        final matchAddress = kos.address.toLowerCase().contains(kw);
        if (!matchName && !matchArea && !matchAddress) return false;
      }
      return true;
    }).toList();
  }
}

void main() {
  final sampleKosList = [
    KosModel(
      id: '11111111-1111-1111-1111-111111111111',
      ownerId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      name: 'Kos Melati Singaraja',
      address: 'Jl. Udayana No. 11',
      area: 'Banyuasri',
      contactNumber: '081234567890',
      pricePerMonth: 850000,
      description: 'Kos nyaman dan bersih.',
      availableRooms: 3,
      hasWifi: true,
      hasBathroomInside: true,
      hasParking: false,
    ),
    KosModel(
      id: '22222222-2222-2222-2222-222222222222',
      ownerId: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
      name: 'Kos Kenanga Undiksha',
      address: 'Jl. Sudirman No. 45',
      area: 'Kaliuntu',
      contactNumber: '081987654321',
      pricePerMonth: 1500000,
      description: 'Fasilitas lengkap dekat kampus.',
      availableRooms: 2,
      hasWifi: true,
      hasBathroomInside: true,
      hasParking: true,
    ),
    KosModel(
      id: '33333333-3333-3333-3333-333333333333',
      ownerId: 'cccccccc-cccc-cccc-cccc-cccccccccccc',
      name: 'Kos Mawar Murah',
      address: 'Jl. Pramuka No. 3',
      area: 'Banyuning',
      contactNumber: '081333444555',
      pricePerMonth: 500000,
      description: 'Kos murah meriah.',
      availableRooms: 1,
      hasWifi: false,
      hasBathroomInside: false,
      hasParking: true,
    ),
  ];

  group('KosFilterBottomSheet Widget Unit Tests', () {
    testWidgets(
      'menampilkan komponen filter lengkap (judul, input harga, 3 checkbox, tombol)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: KosFilterBottomSheet(
                onApply: ({
                  int? maxPrice,
                  required bool mustHaveWifi,
                  required bool mustHaveBathroom,
                  required bool mustHaveParking,
                }) {},
              ),
            ),
          ),
        );

        // Verifikasi judul modal
        expect(find.text('Filter Kos'), findsOneWidget);
        expect(find.text('Reset'), findsOneWidget);

        // Verifikasi input harga
        expect(find.byKey(const Key('filter_max_price_input')), findsOneWidget);
        expect(find.text('Harga Maksimum per Bulan'), findsOneWidget);
        expect(find.text('Rp '), findsOneWidget);

        // Verifikasi 3 checkbox fasilitas
        expect(find.byKey(const Key('filter_checkbox_wifi')), findsOneWidget);
        expect(
          find.byKey(const Key('filter_checkbox_bathroom')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('filter_checkbox_parking')),
          findsOneWidget,
        );
        expect(find.text('WiFi'), findsOneWidget);
        expect(find.text('Kamar Mandi Dalam'), findsOneWidget);
        expect(find.text('Parkir'), findsOneWidget);

        // Verifikasi tombol Terapkan Filter
        expect(find.byKey(const Key('btn_apply_filter')), findsOneWidget);
        expect(find.text('Terapkan Filter'), findsOneWidget);
      },
    );

    testWidgets(
      'menampilkan nilai awal filter (initial values) jika disediakan',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: KosFilterBottomSheet(
                initialMaxPrice: 1500000,
                initialWifi: true,
                initialBathroom: true,
                initialParking: false,
                onApply: ({
                  int? maxPrice,
                  required bool mustHaveWifi,
                  required bool mustHaveBathroom,
                  required bool mustHaveParking,
                }) {},
              ),
            ),
          ),
        );

        final priceField = tester.widget<TextField>(
          find.byKey(const Key('filter_max_price_input')),
        );
        expect(priceField.controller!.text, '1500000');

        final wifiCheckbox = tester.widget<CheckboxListTile>(
          find.byKey(const Key('filter_checkbox_wifi')),
        );
        expect(wifiCheckbox.value, isTrue);

        final bathroomCheckbox = tester.widget<CheckboxListTile>(
          find.byKey(const Key('filter_checkbox_bathroom')),
        );
        expect(bathroomCheckbox.value, isTrue);

        final parkingCheckbox = tester.widget<CheckboxListTile>(
          find.byKey(const Key('filter_checkbox_parking')),
        );
        expect(parkingCheckbox.value, isFalse);
      },
    );

    testWidgets(
      'menekan Terapkan Filter memicu callback onApply dengan parameter yang sesuai',
      (tester) async {
        int? appliedMaxPrice;
        bool? appliedWifi;
        bool? appliedBathroom;
        bool? appliedParking;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: KosFilterBottomSheet(
                onApply:
                    ({
                      int? maxPrice,
                      required bool mustHaveWifi,
                      required bool mustHaveBathroom,
                      required bool mustHaveParking,
                    }) {
                      appliedMaxPrice = maxPrice;
                      appliedWifi = mustHaveWifi;
                      appliedBathroom = mustHaveBathroom;
                      appliedParking = mustHaveParking;
                    },
              ),
            ),
          ),
        );

        // Masukkan harga 1500000
        await tester.enterText(
          find.byKey(const Key('filter_max_price_input')),
          '1500000',
        );

        // Centang WiFi dan Parkir
        await tester.tap(find.byKey(const Key('filter_checkbox_wifi')));
        await tester.tap(find.byKey(const Key('filter_checkbox_parking')));
        await tester.pump();

        // Tekan Terapkan Filter
        await tester.tap(find.byKey(const Key('btn_apply_filter')));
        await tester.pump();

        expect(appliedMaxPrice, 1500000);
        expect(appliedWifi, isTrue);
        expect(appliedBathroom, isFalse);
        expect(appliedParking, isTrue);
      },
    );

    testWidgets('input harga kosong dianggap tanpa batasan (maxPrice = null)', (
      tester,
    ) async {
      int? appliedMaxPrice = 999;
      bool callbackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KosFilterBottomSheet(
              onApply:
                  ({
                    int? maxPrice,
                    required bool mustHaveWifi,
                    required bool mustHaveBathroom,
                    required bool mustHaveParking,
                  }) {
                    callbackCalled = true;
                    appliedMaxPrice = maxPrice;
                  },
            ),
          ),
        ),
      );

      // Kosongkan input harga
      await tester.enterText(
        find.byKey(const Key('filter_max_price_input')),
        '',
      );
      await tester.tap(find.byKey(const Key('btn_apply_filter')));
      await tester.pump();

      expect(callbackCalled, isTrue);
      expect(appliedMaxPrice, isNull);
    });

    testWidgets(
      'input harga negatif menampilkan pesan error dan tidak memanggil onApply',
      (tester) async {
        bool callbackCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: KosFilterBottomSheet(
                onApply:
                    ({
                      int? maxPrice,
                      required bool mustHaveWifi,
                      required bool mustHaveBathroom,
                      required bool mustHaveParking,
                    }) {
                      callbackCalled = true;
                    },
              ),
            ),
          ),
        );

        await tester.enterText(
          find.byKey(const Key('filter_max_price_input')),
          '-500000',
        );
        await tester.tap(find.byKey(const Key('btn_apply_filter')));
        await tester.pump();

        expect(find.text('Harga tidak boleh negatif'), findsOneWidget);
        expect(callbackCalled, isFalse);
      },
    );

    testWidgets('tombol Reset mengosongkan seluruh isian dan checkbox', (
      tester,
    ) async {
      bool resetCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KosFilterBottomSheet(
              initialMaxPrice: 1000000,
              initialWifi: true,
              initialBathroom: true,
              initialParking: true,
              onApply: ({
                int? maxPrice,
                required bool mustHaveWifi,
                required bool mustHaveBathroom,
                required bool mustHaveParking,
              }) {},
              onReset: () {
                resetCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Reset'));
      await tester.pump();

      expect(resetCalled, isTrue);

      final priceField = tester.widget<TextField>(
        find.byKey(const Key('filter_max_price_input')),
      );
      expect(priceField.controller!.text, '');

      final wifi = tester.widget<CheckboxListTile>(
        find.byKey(const Key('filter_checkbox_wifi')),
      );
      expect(wifi.value, isFalse);

      final bathroom = tester.widget<CheckboxListTile>(
        find.byKey(const Key('filter_checkbox_bathroom')),
      );
      expect(bathroom.value, isFalse);

      final parking = tester.widget<CheckboxListTile>(
        find.byKey(const Key('filter_checkbox_parking')),
      );
      expect(parking.value, isFalse);
    });
  });

  group('KosListScreen Filter Integration Tests', () {
    late MockFilterKosRepository repository;
    late KosProvider provider;

    setUp(() {
      repository = MockFilterKosRepository()..allKos = sampleKosList;
      provider = KosProvider(repository: repository);
    });

    Widget createScreenUnderTest() {
      return ChangeNotifierProvider<KosProvider>.value(
        value: provider,
        child: const MaterialApp(home: KosListScreen()),
      );
    }

    testWidgets(
      '1. Ketuk tombol filter di halaman utama, pastikan KosFilterBottomSheet terbuka',
      (tester) async {
        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        // Tombol filter ada di halaman
        expect(find.byKey(const Key('btn_open_filter')), findsOneWidget);

        // Ketuk tombol filter
        await tester.tap(find.byKey(const Key('btn_open_filter')));
        await tester.pumpAndSettle();

        // Pastikan modal bottom sheet terbuka
        expect(find.byType(KosFilterBottomSheet), findsOneWidget);
        expect(find.text('Filter Kos'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Isi batas harga Rp 1.500.000 dan centang WiFi, lalu tekan Terapkan Filter',
      (tester) async {
        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        // Awalnya 3 kos tampil
        expect(find.text('Kos Melati Singaraja'), findsOneWidget);
        expect(find.text('Kos Kenanga Undiksha'), findsOneWidget);
        expect(find.text('Kos Mawar Murah'), findsOneWidget);

        // Buka bottom sheet
        await tester.tap(find.byKey(const Key('btn_open_filter')));
        await tester.pumpAndSettle();

        // Isi harga 1500000
        await tester.enterText(
          find.byKey(const Key('filter_max_price_input')),
          '1500000',
        );

        // Centang WiFi
        await tester.tap(find.byKey(const Key('filter_checkbox_wifi')));
        await tester.pump();

        // Tekan Terapkan Filter
        await tester.tap(find.byKey(const Key('btn_apply_filter')));
        await tester.pumpAndSettle();

        // Modal tertutup
        expect(find.byType(KosFilterBottomSheet), findsNothing);

        // Kos Mawar Murah (tidak punya WiFi) tersaring keluar
        expect(find.text('Kos Melati Singaraja'), findsOneWidget);
        expect(find.text('Kos Kenanga Undiksha'), findsOneWidget);
        expect(find.text('Kos Mawar Murah'), findsNothing);
      },
    );

    testWidgets(
      '3. Uji filter dengan kriteria mustahil (harga Rp 10.000): tampilkan pesan informatif AC03-2',
      (tester) async {
        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        // Buka filter
        await tester.tap(find.byKey(const Key('btn_open_filter')));
        await tester.pumpAndSettle();

        // Isi harga 10000 (tidak ada kos semurah ini)
        await tester.enterText(
          find.byKey(const Key('filter_max_price_input')),
          '10000',
        );

        // Terapkan Filter
        await tester.tap(find.byKey(const Key('btn_apply_filter')));
        await tester.pumpAndSettle();

        // Verifikasi pesan empty state informatif AC03-2
        expect(
          find.text('Tidak ada kos yang cocok dengan kriteria filter tersebut'),
          findsOneWidget,
        );
        expect(find.text('Kos Tidak Ditemukan'), findsOneWidget);
        expect(find.text('Reset Filter'), findsOneWidget);

        // Tekan Reset Filter mengembalikan seluruh daftar kos
        await tester.tap(find.text('Reset Filter'));
        await tester.pumpAndSettle();

        expect(find.text('Kos Melati Singaraja'), findsOneWidget);
        expect(find.text('Kos Kenanga Undiksha'), findsOneWidget);
        expect(find.text('Kos Mawar Murah'), findsOneWidget);
      },
    );

    testWidgets(
      '4. Menutup modal filter tanpa menekan Terapkan Filter tidak mengubah filter',
      (tester) async {
        await tester.pumpWidget(createScreenUnderTest());
        await tester.pumpAndSettle();

        // Buka filter
        await tester.tap(find.byKey(const Key('btn_open_filter')));
        await tester.pumpAndSettle();

        expect(find.byType(KosFilterBottomSheet), findsOneWidget);

        // Ketuk di luar modal (barrier) untuk menutup
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(find.byType(KosFilterBottomSheet), findsNothing);
        // Data tetap utuh
        expect(find.text('Kos Melati Singaraja'), findsOneWidget);
        expect(find.text('Kos Kenanga Undiksha'), findsOneWidget);
        expect(find.text('Kos Mawar Murah'), findsOneWidget);
      },
    );
  });
}
