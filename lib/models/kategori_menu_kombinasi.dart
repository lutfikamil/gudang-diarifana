import 'package:cloud_firestore/cloud_firestore.dart';

class KategoriMenuKombinasi {
  String id;
  String nama; // Contoh: "Nasi", "Lauk", "Sambal", dll
  List<String> pilihan; // Contoh: ["Nasi Putih", "Nasi Kuning", "Mie"]
  int urutan; // Urutan kolom (1-5)
  DateTime createdAt;

  KategoriMenuKombinasi({
    required this.id,
    required this.nama,
    required this.pilihan,
    required this.urutan,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'pilihan': pilihan,
      'urutan': urutan,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory KategoriMenuKombinasi.fromMap(String id, Map<String, dynamic> data) {
    // Defensive parsing: Firestore data might be stored as List or Map
    final rawPilihan = data['pilihan'];
    List<String> parsedPilihan;

    if (rawPilihan is List) {
      parsedPilihan = rawPilihan.map((e) => e.toString()).toList();
    } else if (rawPilihan is Map) {
      parsedPilihan = rawPilihan.values.map((e) => e.toString()).toList();
    } else {
      parsedPilihan = <String>[];
    }

    return KategoriMenuKombinasi(
      id: id,
      nama: data['nama'] ?? '',
      pilihan: parsedPilihan,
      urutan: data['urutan'] ?? 1,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
