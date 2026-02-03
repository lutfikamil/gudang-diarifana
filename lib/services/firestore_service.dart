import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:excel/excel.dart';

import 'tenant_helper.dart';

class FirestoreService {
  /// ================= BARANG =================

  static Stream<QuerySnapshot<Map<String, dynamic>>> getBarang() {
    return TenantHelper.collection(
      'barang',
    ).orderBy('createdAt', descending: true).snapshots();
  }

  static Future<void> tambahBarang({
    required String nama,
    required int stok,
    required String satuan,
    required String kategori,
  }) async {
    await TenantHelper.collection('barang').add({
      'nama': nama,
      'stok': stok,
      'satuan': satuan,
      'kategori': kategori,
      'tenantId': TenantHelper.tenantId,
      'createdAt': Timestamp.now(),
    });
  }

  static Future<void> updateStokBarang(String barangId, int perubahan) async {
    await TenantHelper.doc('barang', barangId).update({
      'stok': FieldValue.increment(perubahan),
      'tenantId': TenantHelper.tenantId,
    });
  }

  static Future<void> hapusBarang(String barangId) async {
    await TenantHelper.doc('barang', barangId).delete();
  }

  /// ================= BARANG MASUK =================
  static Future<void> barangMasuk({
    required String barangId,
    required int jumlah,
    required String namaBarang,
    required String satuan,
    required String keterangan,
    required DateTime waktu,
  }) async {
    final user = FirebaseAuth.instance.currentUser!;
    final barangRef = TenantHelper.doc('barang', barangId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(barangRef);
      if (!snap.exists) throw Exception('Barang tidak ditemukan');

      // Update stok SAJA
      tx.update(barangRef, {
        'stok': FieldValue.increment(jumlah),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log barang masuk
      tx.set(TenantHelper.collection('barang_masuk').doc(), {
        'barangId': barangId,
        'namaBarang': namaBarang,
        'jumlah': jumlah,
        'satuan': satuan,
        'keterangan': keterangan,
        'uid': user.uid,
        'email': user.email,
        'user': user.email ?? user.uid,
        'waktu': Timestamp.fromDate(waktu),
        'tenantId': TenantHelper.tenantId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// ================= PESANAN =================

  static Stream<QuerySnapshot<Map<String, dynamic>>> getPesanan() {
    return TenantHelper.collection(
      'pesanan',
    ).orderBy('tanggalPesanan', descending: false).snapshots();
  }

  static Future<void> buatPesanan({
    required String barangId,
    required String namaBarang,
    required int jumlahPesanan,
    required String satuan,
    required DateTime? tanggalPesanan,
  }) async {
    await TenantHelper.collection('pesanan').add({
      'barangId': barangId,
      'namaBarang': namaBarang,
      'jumlahPesan': jumlahPesanan,
      'jumlahDiterima': 0,
      'satuan': satuan,
      'tanggalPesanan': Timestamp.fromDate(tanggalPesanan ?? DateTime.now()),
      'status': 'DIPESAN',
      'tenantId': TenantHelper.tenantId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> terimaPesanan({
    required String pesananId,
    required int jumlahTerima,
    required String keterangan,
  }) async {
    final pesananRef = TenantHelper.doc('pesanan', pesananId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final pesananSnap = await tx.get(pesananRef);
      if (!pesananSnap.exists) {
        throw Exception('Pesanan tidak ditemukan');
      }

      final data = pesananSnap.data()!;

      final String barangId = data['barangId'];
      final int jumlahPesan = data['jumlahPesan'] ?? 0;
      final int sudahDiterima = data['jumlahDiterima'] ?? 0;

      final int sisa = jumlahPesan - sudahDiterima;
      if (jumlahTerima <= 0 || jumlahTerima > sisa) {
        throw Exception('Jumlah diterima tidak valid');
      }

      final barangRef = TenantHelper.doc('barang', barangId);

      // Kurangi stok barang
      tx.update(barangRef, {
        'stok': FieldValue.increment(-jumlahTerima),
        'tenantId': TenantHelper.tenantId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final totalDiterimaBaru = sudahDiterima + jumlahTerima;

      String statusBaru = 'DIPESAN';
      if (totalDiterimaBaru >= jumlahPesan) {
        statusBaru = 'LENGKAP';
      } else if (totalDiterimaBaru > 0) {
        statusBaru = 'SEBAGIAN';
      }

      // Update pesanan
      tx.update(pesananRef, {
        'jumlahDiterima': totalDiterimaBaru,
        'status': statusBaru,
        'tenantId': TenantHelper.tenantId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 🔁 Jika pesanan ini bagian dari MENU → update status MENU
      if (data['menuPesananId'] != null) {
        await updateMenuPesananStatus(menuPesananId: data['menuPesananId']);
      }
    });
  }

  /// ================= LAPORAN =================

  static Stream<QuerySnapshot<Map<String, dynamic>>> laporanBarangMasuk(
    String tenantId,
    DateTime start,
    DateTime end,
  ) {
    return FirebaseFirestore.instance
        .collection('tenants')
        .doc(tenantId)
        .collection('barang_masuk')
        .where('waktu', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('waktu', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .snapshots();
  }

  //=========== LAPORAN =================
  static Stream<QuerySnapshot> getLaporan(
    String tenantId,
    DateTime dari,
    DateTime sampai,
  ) {
    final start = Timestamp.fromDate(DateTime(dari.year, dari.month, dari.day));

    final end = Timestamp.fromDate(
      DateTime(sampai.year, sampai.month, sampai.day, 23, 59, 59),
    );

    return FirebaseFirestore.instance
        .collection('tenants')
        .doc(tenantId)
        .collection('barang_masuk')
        .where('waktu', isGreaterThanOrEqualTo: start)
        .where('waktu', isLessThanOrEqualTo: end)
        .snapshots();
  }

  // ================= UPDATE STATUS MENU BERDASARKAN INGREDIENTS =================
  /// Hitung dan update status pesanan MENU berdasarkan status ingredients-nya
  /// Status MENU akan berubah ke LENGKAP jika semua ingredients LENGKAP
  /// Status MENU akan berubah ke SEBAGIAN jika ada ingredients yang sudah diterima
  static Future<void> updateMenuPesananStatus({
    required String menuPesananId,
  }) async {
    final menuRef = TenantHelper.collection('pesanan').doc(menuPesananId);
    final menuSnap = await menuRef.get();

    if (!menuSnap.exists) throw Exception('Menu pesanan tidak ditemukan');

    final menuData = menuSnap.data() as Map<String, dynamic>;
    final ingredients = List<Map<String, dynamic>>.from(
      (menuData['ingredients'] as List? ?? []).map(
        (e) => Map<String, dynamic>.from(e),
      ),
    );

    if (ingredients.isEmpty) return;

    // Hitung status berdasarkan setiap ingredient
    int allComplete = 0;
    int anyPartial = 0;

    for (final ing in ingredients) {
      final jumlahPesanan = ing['jumlah'] as int? ?? 0;
      final jumlahDiterima = ing['jumlahDiterima'] as int? ?? 0;

      if (jumlahDiterima >= jumlahPesanan) {
        allComplete++;
      } else if (jumlahDiterima > 0) {
        anyPartial = 1;
      }
    }

    String newStatus = 'DIPESAN';
    if (allComplete == ingredients.length) {
      // Semua ingredients lengkap
      newStatus = 'LENGKAP';
    } else if (allComplete > 0 || anyPartial == 1) {
      // Ada yang sudah diterima sebagian atau beberapa complete
      newStatus = 'SEBAGIAN';
    }

    // Update status menu
    await menuRef.update({
      'status': newStatus,
      'tenantId': TenantHelper.tenantId,
    });
  }

  //=========== BATALKAN PESANAN =================
  static Future<void> batalkanPesanan({required String pesananId}) async {
    await TenantHelper.collection('pesanan').doc(pesananId).update({
      'status': 'BATAL',
      'tenantId': TenantHelper.tenantId,
    });
  }

  //=========== HAPUS PESANAN SELESAI =================
  static Future<void> hapusPesanan({required String pesananId}) async {
    await TenantHelper.collection('pesanan').doc(pesananId).delete();
  }

  // ================= MENU KOMBINASI =================
  static Stream<QuerySnapshot> getMenuKombinasi() {
    return TenantHelper.collection(
      'menu_kombinasi',
    ).orderBy('createdAt', descending: true).snapshots();
  }

  // ================= KATEGORI MENU KOMBINASI =================
  static Stream<QuerySnapshot> getKategoriMenuKombinasi() {
    return TenantHelper.collection(
      'kategori_menu_kombinasi',
    ).orderBy('urutan', descending: false).snapshots();
  }

  static Future<void> tambahKategoriMenuKombinasi({
    required String nama,
    required List<String> pilihan,
    required int urutan,
  }) async {
    await TenantHelper.collection('kategori_menu_kombinasi').add({
      'nama': nama,
      'pilihan': pilihan,
      'urutan': urutan,
      'tenantId': TenantHelper.tenantId,
      'createdAt': Timestamp.now(),
    });
  }

  static Future<void> updateKategoriMenuKombinasi({
    required String kategoriId,
    required String nama,
    required List<String> pilihan,
    required int urutan,
  }) async {
    await TenantHelper.collection(
      'kategori_menu_kombinasi',
    ).doc(kategoriId).update({
      'nama': nama,
      'pilihan': pilihan,
      'urutan': urutan,
      'tenantId': TenantHelper.tenantId,
    });
  }

  static Future<void> hapusKategoriMenuKombinasi({
    required String kategoriId,
  }) async {
    await TenantHelper.collection(
      'kategori_menu_kombinasi',
    ).doc(kategoriId).delete();
  }

  // ================= MENU KOMBINASI =================
  static Future<void> tambahMenuKombinasi({
    required String nama,
    required String deskripsi,
    required List<Map<String, dynamic>> ingredients,
    required Map<String, String> kolom,
  }) async {
    await TenantHelper.collection('menu_kombinasi').add({
      'nama': nama,
      'deskripsi': deskripsi,
      'ingredients': ingredients,
      'kolom': kolom,
      'tenantId': TenantHelper.tenantId,
      'createdAt': Timestamp.now(),
    });
  }

  static Future<void> updateMenuKombinasi({
    required String menuId,
    required String nama,
    required String deskripsi,
    required List<Map<String, dynamic>> ingredients,
    required Map<String, String> kolom,
  }) async {
    await TenantHelper.collection('menu_kombinasi').doc(menuId).update({
      'nama': nama,
      'deskripsi': deskripsi,
      'ingredients': ingredients,
      'kolom': kolom,
      'tenantId': TenantHelper.tenantId,
    });
  }

  static Future<void> hapusMenuKombinasi({required String menuId}) async {
    await TenantHelper.collection('menu_kombinasi').doc(menuId).delete();
  }

  // Buat pesanan dari menu kombinasi (otomatis menambah semua ingredients)
  static Future<void> buatPesananDariMenu({
    required String menuId,
    required String namaMenu,
    required List<Map<String, dynamic>> ingredients,
    required int jumlahPorsi,
    DateTime? tanggalPesanan,
  }) async {
    final tglPesan = tanggalPesanan ?? DateTime.now();
    // Buat dokumen pesanan menu, lalu buat juga pesanan terpisah untuk
    // setiap ingredient agar muncul di daftar pesanan (tipe BARANG).
    final menuRef = TenantHelper.collection('pesanan').doc();
    final batch = TenantHelper.batch();

    batch.set(menuRef, {
      'menuId': menuId,
      'namaMenu': namaMenu,
      'jumlahPorsi': jumlahPorsi,
      'ingredients':
          ingredients.map((ing) {
            return {
              'barangId': ing['barangId'],
              'namaBarang': ing['namaBarang'],
              'jumlah': (ing['jumlah'] as int) * jumlahPorsi,
              'satuan': ing['satuan'],
              'jumlahDiterima': 0,
              'status': 'DIPESAN',
            };
          }).toList(),
      'status': 'DIPESAN',
      'tipeOrder': 'MENU', // untuk membedakan dari order normal
      'tanggalPesanan': Timestamp.fromDate(tglPesan),
      'tenantId': TenantHelper.tenantId,
      'createdAt': Timestamp.now(),
    });

    // Untuk setiap ingredient, buat juga pesanan BARANG yang terhubung ke menu
    for (final ing in ingredients) {
      final ingJumlah = (ing['jumlah'] as int) * jumlahPorsi;
      final ingRef = TenantHelper.collection('pesanan').doc();
      batch.set(ingRef, {
        'barangId': ing['barangId'],
        'namaBarang': ing['namaBarang'],
        'jumlahPesan': ingJumlah,
        'jumlahDiterima': 0,
        'satuan': ing['satuan'],
        'status': 'DIPESAN',
        'tipeOrder': 'BARANG',
        'menuPesananId': menuRef.id,
        'namaMenu': namaMenu,
        'tanggalPesanan': Timestamp.fromDate(tglPesan),
        'tenantId': TenantHelper.tenantId,
        'createdAt': Timestamp.now(),
      });
    }

    await batch.commit();
  }

  /// ================= IMPORT EXCEL =================

  static Future<Map<String, dynamic>> importStokDariExcel(
    Uint8List bytes,
  ) async {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      throw Exception('Sheet Excel kosong');
    }
    final sheet = excel.tables.values.first;

    final barangCol = TenantHelper.collection('barang');
    final batch = TenantHelper.batch();

    final snapshot = await barangCol.get();
    final Map<String, DocumentSnapshot> existing = {
      for (var d in snapshot.docs) d['nama'].toString().toLowerCase(): d,
    };

    int berhasil = 0;
    int gagal = 0;
    final List<String> errors = [];

    for (int i = 1; i < sheet.rows.length; i++) {
      try {
        final row = sheet.rows[i];

        final nama = row[0]?.value?.toString().trim();
        final stok = int.tryParse(row[1]?.value?.toString() ?? '');
        final satuan = row[2]?.value?.toString() ?? 'pcs';
        final kategori = row[3]?.value?.toString() ?? 'Lainnya';

        if (nama == null || stok == null) {
          throw Exception('Data tidak valid');
        }

        final key = nama.toLowerCase();

        if (existing.containsKey(key)) {
          batch.update(existing[key]!.reference, {
            'stok': stok,
            'satuan': satuan,
            'kategori': kategori,
            'tenantId': TenantHelper.tenantId,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          batch.set(barangCol.doc(), {
            'nama': nama,
            'stok': stok,
            'satuan': satuan,
            'kategori': kategori,
            'tenantId': TenantHelper.tenantId,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        berhasil++;
      } catch (e) {
        gagal++;
        errors.add('Baris ${i + 1}: $e');
      }
    }

    await batch.commit();

    return {'berhasil': berhasil, 'gagal': gagal, 'errors': errors};
  }

  static Future<void> updateBarangKategori(
    String barangId,
    String kategoriBaru,
  ) async {
    await TenantHelper.doc('barang', barangId).update({
      'kategori': kategoriBaru,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// ================= SYNC MENU INGREDIENTS =================
  /// Menyalin ingredients MENU ke daftar pesanan BARANG
  static Future<void> syncMenuIngredientsToPesanan({
    required String menuPesananId,
  }) async {
    final menuRef = TenantHelper.collection('pesanan').doc(menuPesananId);
    final menuSnap = await menuRef.get();

    if (!menuSnap.exists) {
      throw Exception('Pesanan menu tidak ditemukan');
    }

    final menuData = menuSnap.data() as Map<String, dynamic>;
    final ingredients =
        (menuData['ingredients'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    if (ingredients.isEmpty) {
      throw Exception('Tidak ada ingredients untuk disinkronkan');
    }

    final batch = TenantHelper.batch();

    for (final ing in ingredients) {
      final ingRef = TenantHelper.collection('pesanan').doc();

      batch.set(ingRef, {
        'barangId': ing['barangId'],
        'namaBarang': ing['namaBarang'],
        'jumlahPesan': ing['jumlah'],
        'jumlahDiterima': ing['jumlahDiterima'] ?? 0,
        'satuan': ing['satuan'],
        'status': ing['status'] ?? 'DIPESAN',
        'tipeOrder': 'BARANG',
        'menuPesananId': menuPesananId,
        'namaMenu': menuData['namaMenu'],
        'tanggalPesanan': menuData['tanggalPesanan'],
        'tenantId': TenantHelper.tenantId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// ================= BARANG KELUAR =================
  /// Mengurangi stok dan mencatat log barang keluar
  static Future<void> barangKeluar({
    required String barangId,
    required String namaBarang,
    required int jumlah,
    required String satuan,
    required String keterangan,
    required Timestamp waktu,
  }) async {
    final barangRef = TenantHelper.doc('barang', barangId);
    final keluarRef = TenantHelper.collection('barang_keluar').doc();

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(barangRef);
      if (!snap.exists) {
        throw Exception('Barang tidak ditemukan');
      }

      final stokSaatIni = snap['stok'] ?? 0;
      if (stokSaatIni < jumlah) {
        throw Exception('Stok tidak cukup');
      }

      // Kurangi stok
      tx.update(barangRef, {
        'stok': FieldValue.increment(-jumlah),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Catat barang keluar
      tx.set(keluarRef, {
        'barangId': barangId,
        'namaBarang': namaBarang,
        'jumlah': jumlah,
        'satuan': satuan,
        'keterangan': keterangan,
        'user': FirebaseAuth.instance.currentUser?.email ?? 'unknown',
        'waktu': waktu,
        'tenantId': TenantHelper.tenantId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
