import 'package:cloud_firestore/cloud_firestore.dart';

class TenantService {
  static Future<String> createTenant({
    required String tenantName,
    required String ownerUid,
    required String ownerEmail,
  }) async {
    final firestore = FirebaseFirestore.instance;

    final tenantRef = firestore.collection('tenants').doc();

    final batch = firestore.batch();

    // Tenant
    batch.set(tenantRef, {
      'name': tenantName,
      'ownerUid': ownerUid,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'active',
    });

    // Member (WAJIB sesuai rules)
    batch.set(
      tenantRef.collection('members').doc(ownerUid),
      {
        'role': 'owner',
        'email': ownerEmail,
        'joinedAt': FieldValue.serverTimestamp(),
      },
    );

    // User global
    batch.set(
      firestore.collection('users').doc(ownerUid),
      {
        'tenantId': tenantRef.id,
        'role': 'owner',
        'email': ownerEmail,
      },
    );

    await batch.commit();

    return tenantRef.id;
  }
}