import 'package:cloud_firestore/cloud_firestore.dart';
//import 'auth_service.dart';

class TenantService {
  static Future<String> createTenant({
    required String tenantName,
    required String ownerUid,
    required String ownerEmail,
  }) async {
    final firestore = FirebaseFirestore.instance;

    final tenantRef = firestore.collection('tenants').doc();

    await tenantRef.set({
      'name': tenantName,
      'ownerUid': ownerUid,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'active',
    });

    await tenantRef.collection('users').doc(ownerUid).set({
      'role': 'owner',
      'email': ownerEmail,
      'joinedAt': FieldValue.serverTimestamp(),
    });

    await firestore.collection('users').doc(ownerUid).set({
      'tenantId': tenantRef.id,
      'role': 'owner',
      'email': ownerEmail,
    });

    return tenantRef.id;
  }
}
