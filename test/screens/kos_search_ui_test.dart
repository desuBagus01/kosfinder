import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos_model.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/repositories/kos_repository.dart';
import 'package:kosfinder/screens/kos_list_screen.dart';
import 'package:provider/provider.dart';

class MockSearchKosRepository extends KosRepository {
  List<KosModel> kosList = [];
  Exception? errorToThrow;
  final List<String> searchedKeywords = [];
  Completer<List<KosModel>>? searchCompleter;

  @override
  Future<List<KosModel>> getKosList() async => kosList;

  @override
  Future<List<KosModel>> getKosListFiltered({
    String keyword = '',
    int? maxPrice,
    bool mustHaveWifi = false,
    bool mustHaveBathroom = false,
    bool mustHaveParking = false,
  }) async {
    searchedKeywords.add(keyword);
    if (searchCompleter != null) {
      return searchCompleter!.future;
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    if (keyword == 'AreaTidakAda') {
      return [];
    }
    return kosList;
  }
}

void main() {
  final sampleKos = KosModel(
    id: '11111111-1111-1111-1111-111111111111',
    ownerId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    name: 'Kos Area Udayana',
    address: 'Jl. Udayana No. 11',
    area: 'Singaraja',
    contactNumber: '081234567890',
    pricePerMonth: 850000,
    description: 'Kos nyaman dan bersih.',
    availableRooms: 3,
  );

  late MockSearchKosRepository repository;
  late KosProvider provider;

  setUp(() {
    repository = MockSearchKosRepository()..kosList = [sampleKos];
    provider = KosProvider(repository: repository);
  });

  Widget createWidgetUnderTest() {
    return ChangeNotifierProvider<KosProvider>.value(
      value: provider,
      child: const MaterialApp(home: KosListScreen()),
    );
  }

  Future<void> loadScreen(WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();
  }

  testWidgets('kolom pencarian tampil pada halaman utama', (tester) async {
    await loadScreen(tester);

    expect(find.byKey(const ValueKey('kos-search-field')), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
  });

  testWidgets('menekan Enter menjalankan pencarian dan menampilkan hasil', (
    tester,
  ) async {
    await loadScreen(tester);

    await tester.enterText(
      find.byKey(const ValueKey('kos-search-field')),
      'Singaraja',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(repository.searchedKeywords, contains('Singaraja'));
    expect(find.text('Kos Area Udayana'), findsOneWidget);
  });

  testWidgets('menekan tombol Cari menjalankan pencarian', (tester) async {
    await loadScreen(tester);

    await tester.enterText(
      find.byKey(const ValueKey('kos-search-field')),
      'Udayana',
    );
    await tester.tap(find.byTooltip('Cari'));
    await tester.pumpAndSettle();

    expect(repository.searchedKeywords, contains('Udayana'));
    expect(find.text('Kos Area Udayana'), findsOneWidget);
  });

  testWidgets('menampilkan pesan saat hasil pencarian kosong', (tester) async {
    await loadScreen(tester);

    await tester.enterText(
      find.byKey(const ValueKey('kos-search-field')),
      'AreaTidakAda',
    );
    await tester.tap(find.byTooltip('Cari'));
    await tester.pumpAndSettle();

    expect(
      find.text("Tidak ditemukan kos di area 'AreaTidakAda'"),
      findsOneWidget,
    );
  });

  testWidgets('mempertahankan teks pencarian saat terjadi error jaringan', (
    tester,
  ) async {
    await loadScreen(tester);
    repository.errorToThrow = const KosException('Koneksi terputus');

    await tester.enterText(
      find.byKey(const ValueKey('kos-search-field')),
      'Singaraja',
    );
    await tester.tap(find.byTooltip('Cari'));
    await tester.pumpAndSettle();

    final searchField = tester.widget<TextField>(
      find.byKey(const ValueKey('kos-search-field')),
    );
    expect(searchField.controller!.text, 'Singaraja');
    expect(find.widgetWithText(ElevatedButton, 'Coba Lagi'), findsOneWidget);
  });

  testWidgets(
    'Retry menjalankan kembali pencarian dengan kata kunci yang sama',
    (tester) async {
      await loadScreen(tester);
      repository.errorToThrow = const KosException('Koneksi terputus');

      await tester.enterText(
        find.byKey(const ValueKey('kos-search-field')),
        'Singaraja',
      );
      await tester.tap(find.byTooltip('Cari'));
      await tester.pumpAndSettle();

      repository.errorToThrow = null;
      await tester.tap(find.widgetWithText(ElevatedButton, 'Coba Lagi'));
      await tester.pumpAndSettle();

      expect(repository.searchedKeywords, ['Singaraja', 'Singaraja']);
      expect(find.text('Kos Area Udayana'), findsOneWidget);
    },
  );
}
