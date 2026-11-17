import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos_model.dart';

void main() {
  group('KosModel Unit Tests', () {
    final validJson = <String, dynamic>{
      'id': 'b1c3a647-7590-482a-a92c-e58f00000001',
      'owner_id': 'd2d3a647-7590-482a-a92c-e58f00000002',
      'name': 'Kos Melati Singaraja',
      'address': 'Jl. Udayana No. 11, Singaraja',
      'area': 'Banyuasri',
      'contact_number': '081234567890',
      'price_per_month': 850000,
      'description': 'Kos nyaman, bersih, dan dekat kampus Undiksha.',
      'available_rooms': 3,
      'has_wifi': true,
      'has_bathroom_inside': true,
      'has_parking': false,
      'created_at': '2026-11-15T10:00:00.000Z',
      'updated_at': '2026-11-15T12:00:00.000Z',
    };

    test('1. Parsing dan serialisasi JSON normal berhasil dengan akurat', () {
      final model = KosModel.fromJson(validJson);

      expect(model.id, 'b1c3a647-7590-482a-a92c-e58f00000001');
      expect(model.ownerId, 'd2d3a647-7590-482a-a92c-e58f00000002');
      expect(model.name, 'Kos Melati Singaraja');
      expect(model.address, 'Jl. Udayana No. 11, Singaraja');
      expect(model.area, 'Banyuasri');
      expect(model.contactNumber, '081234567890');
      expect(model.pricePerMonth, 850000);
      expect(
        model.description,
        'Kos nyaman, bersih, dan dekat kampus Undiksha.',
      );
      expect(model.availableRooms, 3);
      expect(model.hasWifi, isTrue);
      expect(model.hasBathroomInside, isTrue);
      expect(model.hasParking, isFalse);
      expect(model.createdAt, DateTime.parse('2026-11-15T10:00:00.000Z'));
      expect(model.updatedAt, DateTime.parse('2026-11-15T12:00:00.000Z'));

      final jsonOutput = model.toJson();
      expect(jsonOutput['id'], model.id);
      expect(jsonOutput['owner_id'], model.ownerId);
      expect(jsonOutput['name'], model.name);
      expect(jsonOutput['address'], model.address);
      expect(jsonOutput['area'], model.area);
      expect(jsonOutput['contact_number'], model.contactNumber);
      expect(jsonOutput['price_per_month'], model.pricePerMonth);
      expect(jsonOutput['description'], model.description);
      expect(jsonOutput['available_rooms'], model.availableRooms);
      expect(jsonOutput['has_wifi'], isTrue);
      expect(jsonOutput['has_bathroom_inside'], isTrue);
      expect(jsonOutput['has_parking'], isFalse);
    });

    test('2. Field wajib yang hilang atau null melempar FormatException', () {
      // Helper untuk membuat map salinan dengan modifikasi
      Map<String, dynamic> makeInvalid(String key, dynamic invalidValue) {
        final map = Map<String, dynamic>.from(validJson);
        if (invalidValue == null) {
          map.remove(key);
        } else {
          map[key] = invalidValue;
        }
        return map;
      }

      // id
      expect(
        () => KosModel.fromJson(makeInvalid('id', null)),
        throwsFormatException,
      );
      expect(
        () => KosModel.fromJson(makeInvalid('id', '   ')),
        throwsFormatException,
      );

      // owner_id
      expect(
        () => KosModel.fromJson(makeInvalid('owner_id', null)),
        throwsFormatException,
      );
      expect(
        () => KosModel.fromJson(makeInvalid('owner_id', '')),
        throwsFormatException,
      );

      // name
      expect(
        () => KosModel.fromJson(makeInvalid('name', null)),
        throwsFormatException,
      );
      expect(
        () => KosModel.fromJson(makeInvalid('name', '   ')),
        throwsFormatException,
      );

      // address
      expect(
        () => KosModel.fromJson(makeInvalid('address', null)),
        throwsFormatException,
      );
      expect(
        () => KosModel.fromJson(makeInvalid('address', '')),
        throwsFormatException,
      );

      // area
      expect(
        () => KosModel.fromJson(makeInvalid('area', null)),
        throwsFormatException,
      );
      expect(
        () => KosModel.fromJson(makeInvalid('area', ' ')),
        throwsFormatException,
      );

      // contact_number
      expect(
        () => KosModel.fromJson(makeInvalid('contact_number', null)),
        throwsFormatException,
      );
      expect(
        () => KosModel.fromJson(makeInvalid('contact_number', '12345')),
        throwsFormatException,
      ); // < 8 char

      // price_per_month
      expect(
        () => KosModel.fromJson(makeInvalid('price_per_month', null)),
        throwsFormatException,
      );

      // description
      expect(
        () => KosModel.fromJson(makeInvalid('description', null)),
        throwsFormatException,
      );
      expect(
        () => KosModel.fromJson(makeInvalid('description', '')),
        throwsFormatException,
      );
    });

    test('3. Nilai harga desimal/pecahan dan negatif yang tidak valid melempar FormatException', () {
      final invalidPrices = [
        850000.50, // Double dengan bagian pecahan
        1200000.99,
        '850000.75', // String desimal berpecahan
        '950000.1',
        -500000, // Nilai negatif
        '-500000',
        'delapan ratus ribu', // Bukan angka
      ];

      for (final invalidPrice in invalidPrices) {
        final map = Map<String, dynamic>.from(validJson)
          ..['price_per_month'] = invalidPrice;
        expect(
          () => KosModel.fromJson(map),
          throwsFormatException,
          reason:
              'Harga $invalidPrice seharusnya ditolak sebagai FormatException',
        );
      }

      // Nilai integer valid (termasuk integer dalam string) harus berhasil
      final validPriceMap1 = Map<String, dynamic>.from(validJson)
        ..['price_per_month'] = 1500000;
      expect(KosModel.fromJson(validPriceMap1).pricePerMonth, 1500000);

      final validPriceMap2 = Map<String, dynamic>.from(validJson)
        ..['price_per_month'] = '1500000';
      expect(KosModel.fromJson(validPriceMap2).pricePerMonth, 1500000);
    });

    test('4. Nilai jumlah kamar desimal/pecahan dan negatif yang tidak valid melempar FormatException', () {
      final invalidRooms = [
        3.5, // Double dengan pecahan
        '2.75', // String desimal berpecahan
        -1, // Negatif
        '-3',
        'tiga kamar', // Bukan angka
      ];

      for (final invalidRoom in invalidRooms) {
        final map = Map<String, dynamic>.from(validJson)
          ..['available_rooms'] = invalidRoom;
        expect(
          () => KosModel.fromJson(map),
          throwsFormatException,
          reason:
              'Jumlah kamar $invalidRoom seharusnya ditolak sebagai FormatException',
        );
      }

      // available_rooms null harus default ke 0
      final nullRoomMap = Map<String, dynamic>.from(validJson)
        ..remove('available_rooms');
      expect(KosModel.fromJson(nullRoomMap).availableRooms, 0);

      // Bilangan bulat valid
      final validRoomMap = Map<String, dynamic>.from(validJson)
        ..['available_rooms'] = 5;
      expect(KosModel.fromJson(validRoomMap).availableRooms, 5);

      final validRoomStringMap = Map<String, dynamic>.from(validJson)
        ..['available_rooms'] = '4';
      expect(KosModel.fromJson(validRoomStringMap).availableRooms, 4);
    });

    test(
      '5. Penanganan nilai boolean konsisten dan menolak nilai tidak valid',
      () {
        // Nilai boolean asli
        final boolMap = Map<String, dynamic>.from(validJson)
          ..['has_wifi'] = true
          ..['has_bathroom_inside'] = false
          ..['has_parking'] = true;
        final model1 = KosModel.fromJson(boolMap);
        expect(model1.hasWifi, isTrue);
        expect(model1.hasBathroomInside, isFalse);
        expect(model1.hasParking, isTrue);

        // Nilai boolean dalam bentuk string valid ('true', 'false')
        final stringBoolMap = Map<String, dynamic>.from(validJson)
          ..['has_wifi'] = 'true'
          ..['has_bathroom_inside'] = 'false'
          ..['has_parking'] = 'TRUE';
        final model2 = KosModel.fromJson(stringBoolMap);
        expect(model2.hasWifi, isTrue);
        expect(model2.hasBathroomInside, isFalse);
        expect(model2.hasParking, isTrue);

        // Nilai null harus default ke false (selaras dengan database DEFAULT FALSE)
        final nullBoolMap = Map<String, dynamic>.from(validJson)
          ..remove('has_wifi')
          ..remove('has_bathroom_inside')
          ..remove('has_parking');
        final model3 = KosModel.fromJson(nullBoolMap);
        expect(model3.hasWifi, isFalse);
        expect(model3.hasBathroomInside, isFalse);
        expect(model3.hasParking, isFalse);

        // Nilai non-boolean tidak valid harus melempar FormatException
        final invalidBoolMap = Map<String, dynamic>.from(validJson)
          ..['has_wifi'] = 'bukan_bool';
        expect(() => KosModel.fromJson(invalidBoolMap), throwsFormatException);

        final invalidNumberBoolMap = Map<String, dynamic>.from(validJson)
          ..['has_parking'] = 99;
        expect(
          () => KosModel.fromJson(invalidNumberBoolMap),
          throwsFormatException,
        );
      },
    );

    test('6. Validasi pada Constructor KosModel melempar ArgumentError jika data tidak valid', () {
      expect(
        () => KosModel(
          id: '',
          ownerId: 'owner-1',
          name: 'Kos A',
          address: 'Alamat',
          area: 'Area',
          contactNumber: '0812345678',
          pricePerMonth: 500000,
          description: 'Desc',
        ),
        throwsArgumentError,
      );

      expect(
        () => KosModel(
          id: 'id-1',
          ownerId: 'owner-1',
          name: 'Kos A',
          address: 'Alamat',
          area: 'Area',
          contactNumber: '123', // < 8 char
          pricePerMonth: 500000,
          description: 'Desc',
        ),
        throwsArgumentError,
      );

      expect(
        () => KosModel(
          id: 'id-1',
          ownerId: 'owner-1',
          name: 'Kos A',
          address: 'Alamat',
          area: 'Area',
          contactNumber: '0812345678',
          pricePerMonth: -100, // negatif
          description: 'Desc',
        ),
        throwsArgumentError,
      );
    });

    test('7. Pengujian copyWith dan kesamaan objek (equality & hashCode)', () {
      final model1 = KosModel.fromJson(validJson);
      final model2 = KosModel.fromJson(validJson);

      expect(model1, equals(model2));
      expect(model1.hashCode, equals(model2.hashCode));

      final updatedModel = model1.copyWith(
        name: 'Kos Melati Baru',
        pricePerMonth: 900000,
        availableRooms: 1,
      );

      expect(updatedModel.name, 'Kos Melati Baru');
      expect(updatedModel.pricePerMonth, 900000);
      expect(updatedModel.availableRooms, 1);
      expect(updatedModel.id, model1.id);
      expect(updatedModel == model1, isFalse);
    });
  });
}
