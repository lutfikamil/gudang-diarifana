class Barang {
  String id;
  String nama;
  int stok;

  Barang({required this.id, required this.nama, required this.stok});

  Map<String, dynamic> toMap() {
    return {'nama': nama, 'stok': stok};
  }
}
