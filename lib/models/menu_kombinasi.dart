import 'package:cloud_firestore/cloud_firestore.dart';

class MenuKombinasi {
  String id;
  String nama;
  String deskripsi;
  List<IngredientItem> ingredients;
  Map<String, String>
  kolom; // Pilihan untuk setiap kategori (kategoriId -> pilihanValue)
  DateTime createdAt;

  MenuKombinasi({
    required this.id,
    required this.nama,
    required this.deskripsi,
    required this.ingredients,
    required this.kolom,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'deskripsi': deskripsi,
      'ingredients': ingredients.map((ing) => ing.toMap()).toList(),
      'kolom': kolom,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory MenuKombinasi.fromMap(String id, Map<String, dynamic> data) {
    // Defensive parsing for ingredients and kolom to handle varied Firestore shapes
    final rawIngredients = data['ingredients'];
    List<IngredientItem> parsedIngredients = [];

    if (rawIngredients is List) {
      parsedIngredients =
          rawIngredients
              .map(
                (item) => IngredientItem.fromMap(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList();
    } else if (rawIngredients is Map) {
      parsedIngredients =
          rawIngredients.values
              .map(
                (item) => IngredientItem.fromMap(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList();
    }

    final rawKolom = data['kolom'];
    Map<String, String> parsedKolom = {};
    if (rawKolom is Map) {
      parsedKolom = rawKolom.map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      );
    }

    return MenuKombinasi(
      id: id,
      nama: data['nama'] ?? '',
      deskripsi: data['deskripsi'] ?? '',
      ingredients: parsedIngredients,
      kolom: parsedKolom,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class IngredientItem {
  String barangId;
  String namaBarang;
  int jumlah;
  String satuan;

  IngredientItem({
    required this.barangId,
    required this.namaBarang,
    required this.jumlah,
    required this.satuan,
  });

  Map<String, dynamic> toMap() {
    return {
      'barangId': barangId,
      'namaBarang': namaBarang,
      'jumlah': jumlah,
      'satuan': satuan,
    };
  }

  factory IngredientItem.fromMap(Map<String, dynamic> data) {
    return IngredientItem(
      barangId: data['barangId'] ?? '',
      namaBarang: data['namaBarang'] ?? '',
      jumlah: data['jumlah'] ?? 0,
      satuan: data['satuan'] ?? 'pcs',
    );
  }
}
