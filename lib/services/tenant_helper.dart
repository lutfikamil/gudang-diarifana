import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

class TenantHelper {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String get tenantId {
    final id = AuthService.tenantId;
    if (id == null || id.isEmpty) {
      throw Exception('Tenant ID tidak tersedia. Pastikan user sudah login.');
    }
    return id;
  }

  static CollectionReference<Map<String, dynamic>> collection(
    String collectionName,
  ) {
    return _db.collection('tenants').doc(tenantId).collection(collectionName);
  }

  static DocumentReference<Map<String, dynamic>> doc(
    String collectionName,
    String docId,
  ) {
    return collection(collectionName).doc(docId);
  }

  static WriteBatch batch() {
    return _db.batch();
  }

  static bool get isReady => AuthService.tenantId != null;
}
