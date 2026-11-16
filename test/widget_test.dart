import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/main.dart';
import 'package:kosfinder/screens/kos_list_screen.dart';

void main() {
  testWidgets('Smoke test: KosFinder root app renders KosListScreen without errors', (WidgetTester tester) async {
    // Build root app dan trigger frame
    await tester.pumpWidget(const MyApp());

    // Verifikasi bahwa halaman KosListScreen dimuat
    expect(find.byType(KosListScreen), findsOneWidget);

    // Verifikasi judul AppBar utama
    expect(find.text('KosFinder'), findsOneWidget);

    // Verifikasi ikon info About tersedia di AppBar
    expect(find.byIcon(Icons.info_outline), findsOneWidget);

    // Verifikasi tidak ada dialog login atau pembatasan autentikasi yang memblokir pengguna
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('Navigates to About page via named route and displays student identity', (WidgetTester tester) async {
    // Build root app dan trigger frame
    await tester.pumpWidget(const MyApp());

    // Verifikasi info icon ada di AppBar
    expect(find.byIcon(Icons.info_outline), findsOneWidget);

    // Ketuk tombol info dan picu navigasi ke named route '/about'
    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();

    // Verifikasi halaman About terbuka dan menampilkan identitas baku pengembang
    expect(find.byType(AboutPage), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('2415051014 - Gede Supadma'), findsOneWidget);
  });
}
