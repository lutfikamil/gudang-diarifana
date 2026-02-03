import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LaporanService {
  final _db = FirebaseFirestore.instance;

  // ================= HELPER =================
  Future<String> _getTenantId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('User belum login');
    }

    final userSnap = await _db.collection('users').doc(uid).get();
    if (!userSnap.exists) {
      throw Exception('User document tidak ditemukan');
    }

    return userSnap.data()!['tenantId'];
  }

  // ================= BARANG MASUK =================
  Future<List<Map<String, dynamic>>> getLaporanMasuk(
    Timestamp startTs,
    Timestamp endTs,
  ) async {
    final tenantId = await _getTenantId();
    final List<Map<String, dynamic>> result = [];

    // 1️⃣ BARANG MASUK MANUAL (FIX: scoped ke tenant)
    final snapMasuk =
        await _db
            .collection('tenants')
            .doc(tenantId)
            .collection('barang_masuk')
            .where('waktu', isGreaterThanOrEqualTo: startTs)
            .where('waktu', isLessThanOrEqualTo: endTs)
            .orderBy('waktu')
            .get();

    for (var d in snapMasuk.docs) {
      final data = d.data();
      result.add({
        'namaBarang': data['namaBarang'] ?? '-',
        'jumlah': data['jumlah'] ?? 0,
        'satuan': data['satuan'] ?? '-',
        'user': data['email'] ?? '-',
        'waktu': (data['waktu'] as Timestamp).toDate(),
        'tipe': 'Manual',
      });
    }

    // 2️⃣ BARANG MASUK DARI PESANAN (FIX: scoped ke tenant)
    final snapPesanan =
        await _db
            .collection('tenants')
            .doc(tenantId)
            .collection('pesanan')
            .where('jumlahDiterima', isGreaterThan: 0)
            .get();

    for (var d in snapPesanan.docs) {
      final data = d.data();
      final tanggalPesanan =
          (data['tanggalPesanan'] as Timestamp?)?.toDate() ??
          (data['createdAt'] as Timestamp).toDate();

      if (!tanggalPesanan.isBefore(startTs.toDate()) &&
          !tanggalPesanan.isAfter(endTs.toDate())) {
        result.add({
          'namaBarang': data['namaBarang'] ?? '-',
          'jumlah': data['jumlahDiterima'] ?? 0,
          'satuan': data['satuan'] ?? '-',
          'user': data['email'] ?? '-',
          'waktu': tanggalPesanan,
          'tipe': 'Pesanan',
        });
      }
    }

    result.sort((a, b) => (a['waktu'] as DateTime).compareTo(b['waktu']));

    return result;
  }

  // ================= BARANG KELUAR =================
  Future<List<Map<String, dynamic>>> getLaporanKeluar(
    Timestamp startTs,
    Timestamp endTs,
  ) async {
    final tenantId = await _getTenantId();

    final snap =
        await _db
            .collection('tenants')
            .doc(tenantId)
            .collection('barang_keluar')
            .where('waktu', isGreaterThanOrEqualTo: startTs)
            .where('waktu', isLessThanOrEqualTo: endTs)
            .orderBy('waktu')
            .get();

    return snap.docs.map((d) {
      final data = d.data();
      return {
        'namaBarang': data['namaBarang'] ?? '-',
        'jumlah': data['jumlah'] ?? 0,
        'satuan': data['satuan'] ?? '-',
        'user': data['email'] ?? '-',
        'waktu': (data['waktu'] as Timestamp).toDate(),
        'tipe': 'Keluar',
      };
    }).toList();
  }
}
