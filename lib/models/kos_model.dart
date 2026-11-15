/// Model data untuk entitas Kos yang selaras dengan tabel `public.kos` di Supabase.
/// Berkas skema acuan: `supabase/schema.sql`.
class KosModel {
  final String id;
  final String ownerId;
  final String name;
  final String address;
  final String area;
  final String contactNumber;
  final int pricePerMonth;
  final String description;
  final int availableRooms;
  final bool hasWifi;
  final bool hasBathroomInside;
  final bool hasParking;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  KosModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.address,
    required this.area,
    required this.contactNumber,
    required this.pricePerMonth,
    required this.description,
    this.availableRooms = 0,
    this.hasWifi = false,
    this.hasBathroomInside = false,
    this.hasParking = false,
    this.createdAt,
    this.updatedAt,
  }) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'id tidak boleh kosong.');
    }
    if (ownerId.trim().isEmpty) {
      throw ArgumentError.value(ownerId, 'ownerId', 'ownerId tidak boleh kosong.');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'name tidak boleh kosong.');
    }
    if (address.trim().isEmpty) {
      throw ArgumentError.value(address, 'address', 'address tidak boleh kosong.');
    }
    if (area.trim().isEmpty) {
      throw ArgumentError.value(area, 'area', 'area tidak boleh kosong.');
    }
    if (contactNumber.trim().length < 8) {
      throw ArgumentError.value(
        contactNumber,
        'contactNumber',
        'contactNumber harus minimal 8 karakter.',
      );
    }
    if (pricePerMonth < 0) {
      throw ArgumentError.value(
        pricePerMonth,
        'pricePerMonth',
        'pricePerMonth tidak boleh bernilai negatif.',
      );
    }
    if (description.trim().isEmpty) {
      throw ArgumentError.value(description, 'description', 'description tidak boleh kosong.');
    }
    if (availableRooms < 0) {
      throw ArgumentError.value(
        availableRooms,
        'availableRooms',
        'availableRooms tidak boleh bernilai negatif.',
      );
    }
  }

  /// Membuat instance [KosModel] dari Map JSON yang diterima dari Supabase.
  /// Melakukan validasi ketat terhadap field wajib, tipe data integer bulat, dan boolean.
  factory KosModel.fromJson(Map<String, dynamic> json) {
    return KosModel(
      id: _parseRequiredString(json['id'], fieldName: 'id'),
      ownerId: _parseRequiredString(json['owner_id'], fieldName: 'owner_id'),
      name: _parseRequiredString(json['name'], fieldName: 'name'),
      address: _parseRequiredString(json['address'], fieldName: 'address'),
      area: _parseRequiredString(json['area'], fieldName: 'area'),
      contactNumber: _parseRequiredString(
        json['contact_number'],
        fieldName: 'contact_number',
        minLength: 8,
      ),
      pricePerMonth: _parseStrictInteger(
        json['price_per_month'],
        fieldName: 'price_per_month',
        isRequired: true,
      ),
      description: _parseRequiredString(json['description'], fieldName: 'description'),
      availableRooms: _parseStrictInteger(
        json['available_rooms'],
        fieldName: 'available_rooms',
        isRequired: false,
        defaultValue: 0,
      ),
      hasWifi: _parseStrictBool(json['has_wifi'], fieldName: 'has_wifi'),
      hasBathroomInside: _parseStrictBool(
        json['has_bathroom_inside'],
        fieldName: 'has_bathroom_inside',
      ),
      hasParking: _parseStrictBool(json['has_parking'], fieldName: 'has_parking'),
      createdAt: _parseDateTime(json['created_at'], fieldName: 'created_at'),
      updatedAt: _parseDateTime(json['updated_at'], fieldName: 'updated_at'),
    );
  }

  /// Memvalidasi dan mengekstrak field string wajib.
  static String _parseRequiredString(
    dynamic value, {
    required String fieldName,
    int minLength = 1,
  }) {
    if (value == null) {
      throw FormatException('Field $fieldName wajib diisi dan tidak boleh null.');
    }
    if (value is! String) {
      throw FormatException('Field $fieldName harus berupa string teks yang valid.');
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw FormatException('Field $fieldName tidak boleh berupa string kosong.');
    }
    if (trimmed.length < minLength) {
      throw FormatException(
        'Field $fieldName tidak valid (minimal $minLength karakter).',
      );
    }
    return trimmed;
  }

  /// Memvalidasi dan mengekstrak bilangan bulat (integer).
  /// Menolak nilai desimal/pecahan dan angka negatif.
  static int _parseStrictInteger(
    dynamic value, {
    required String fieldName,
    bool isRequired = false,
    int defaultValue = 0,
  }) {
    if (value == null) {
      if (isRequired) {
        throw FormatException('Field $fieldName wajib diisi dan tidak boleh null.');
      }
      return defaultValue;
    }

    if (value is int) {
      if (value < 0) {
        throw FormatException('Field $fieldName tidak boleh bernilai negatif ($value).');
      }
      return value;
    }

    if (value is double) {
      if (value.isNaN || value.isInfinite || value % 1 != 0) {
        throw FormatException(
          'Field $fieldName harus berupa bilangan bulat dan tidak boleh bernilai pecahan desimal ($value).',
        );
      }
      final intValue = value.toInt();
      if (intValue < 0) {
        throw FormatException('Field $fieldName tidak boleh bernilai negatif ($intValue).');
      }
      return intValue;
    }

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        if (isRequired) {
          throw FormatException('Field $fieldName wajib diisi dan tidak boleh kosong.');
        }
        return defaultValue;
      }
      // Deteksi jika format string berisi tanda titik desimal yang bukan integer
      if (trimmed.contains('.')) {
        final doubleVal = double.tryParse(trimmed);
        if (doubleVal != null) {
          if (doubleVal.isNaN || doubleVal.isInfinite || doubleVal % 1 != 0) {
            throw FormatException(
              'Field $fieldName harus berupa bilangan bulat dan tidak boleh bernilai pecahan desimal ($trimmed).',
            );
          }
          final intVal = doubleVal.toInt();
          if (intVal < 0) {
            throw FormatException('Field $fieldName tidak boleh bernilai negatif ($intVal).');
          }
          return intVal;
        }
      }

      final parsed = int.tryParse(trimmed);
      if (parsed == null) {
        throw FormatException('Field $fieldName harus berupa bilangan bulat yang valid.');
      }
      if (parsed < 0) {
        throw FormatException('Field $fieldName tidak boleh bernilai negatif ($parsed).');
      }
      return parsed;
    }

    throw FormatException(
      'Field $fieldName memiliki tipe data tidak valid: ${value.runtimeType}.',
    );
  }

  /// Memvalidasi dan mengekstrak tipe boolean secara konsisten dengan database.
  static bool _parseStrictBool(dynamic value, {required String fieldName}) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      final lower = value.trim().toLowerCase();
      if (lower == 'true' || lower == 't') return true;
      if (lower == 'false' || lower == 'f') return false;
    }
    throw FormatException(
      'Field $fieldName harus bertipe boolean (true/false), ditemukan: $value.',
    );
  }

  /// Memparsing field tanggal opsional.
  static DateTime? _parseDateTime(dynamic value, {required String fieldName}) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed == null) {
        throw FormatException('Format tanggal pada field $fieldName tidak valid: $value.');
      }
      return parsed;
    }
    throw FormatException('Field $fieldName harus berupa string tanggal ISO 8601.');
  }

  /// Mengonversi instance [KosModel] menjadi Map JSON untuk penyimpanan ke database Supabase.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'address': address,
      'area': area,
      'contact_number': contactNumber,
      'price_per_month': pricePerMonth,
      'description': description,
      'available_rooms': availableRooms,
      'has_wifi': hasWifi,
      'has_bathroom_inside': hasBathroomInside,
      'has_parking': hasParking,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Membuat salinan objek dengan modifikasi atribut tertentu.
  KosModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? address,
    String? area,
    String? contactNumber,
    int? pricePerMonth,
    String? description,
    int? availableRooms,
    bool? hasWifi,
    bool? hasBathroomInside,
    bool? hasParking,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KosModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      address: address ?? this.address,
      area: area ?? this.area,
      contactNumber: contactNumber ?? this.contactNumber,
      pricePerMonth: pricePerMonth ?? this.pricePerMonth,
      description: description ?? this.description,
      availableRooms: availableRooms ?? this.availableRooms,
      hasWifi: hasWifi ?? this.hasWifi,
      hasBathroomInside: hasBathroomInside ?? this.hasBathroomInside,
      hasParking: hasParking ?? this.hasParking,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KosModel &&
        other.id == id &&
        other.ownerId == ownerId &&
        other.name == name &&
        other.address == address &&
        other.area == area &&
        other.contactNumber == contactNumber &&
        other.pricePerMonth == pricePerMonth &&
        other.description == description &&
        other.availableRooms == availableRooms &&
        other.hasWifi == hasWifi &&
        other.hasBathroomInside == hasBathroomInside &&
        other.hasParking == hasParking &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      ownerId,
      name,
      address,
      area,
      contactNumber,
      pricePerMonth,
      description,
      availableRooms,
      hasWifi,
      hasBathroomInside,
      hasParking,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'KosModel(id: $id, name: $name, area: $area, pricePerMonth: $pricePerMonth, availableRooms: $availableRooms)';
  }
}
