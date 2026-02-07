import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ================= SESSION STATE =================
  static String? _tenantId;
  static String? _role;

  static String? get tenantId => _tenantId;
  static String? get role => _role;

  static User? get currentUser => _auth.currentUser;

  // ================= REGISTER USER (AUTH ONLY) =================
  static Future<UserCredential> registerAuth({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ================= LOGIN =================
  static Future<void> login({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);

    await _loadTenantSession();
  }

  // ================= LOGIN WITH TENANT ID (FOR MEMBER ACCOUNTS) =================
  /// Sign in and verify the signed-in user belongs to the provided tenantId.
  static Future<void> loginWithTenant({
    required String email,
    required String password,
    required String tenantId,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user;
    if (user == null) throw Exception('User belum login');

    // load user's profile doc and check tenant
    final uid = user.uid;
    final userDoc = await _db.collection('users').doc(uid).get();
    if (!userDoc.exists) {
      await _auth.signOut();
      throw Exception('Data user tidak ditemukan');
    }

    final userTenant = userDoc.data()?['tenantId'];
    if (userTenant != tenantId) {
      await _auth.signOut();
      throw Exception('Tenant ID tidak cocok');
    }

    // ensure member exists in tenant
    final memberDoc =
        await _db
            .collection('tenants')
            .doc(tenantId)
            .collection('members')
            .doc(uid)
            .get();
    if (!memberDoc.exists) {
      await _auth.signOut();
      throw Exception('User bukan member tenant');
    }

    // set session
    _tenantId = tenantId;
    _role = memberDoc.data()?['role'];
  }

  // ================= LOAD TENANT SESSION =================
  static Future<void> restoreSession() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _loadTenantSession();
  }

  static Future<void> _loadTenantSession() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User belum login');

    final uid = user.uid;

    // Ambil data user
    final userDoc = await _db.collection('users').doc(uid).get();
    if (!userDoc.exists) {
      throw Exception('Data user tidak ditemukan');
    }

    _tenantId = userDoc['tenantId'];

    // Ambil role dari tenant
    final memberDoc =
        await _db
            .collection('tenants')
            .doc(_tenantId)
            .collection('members')
            .doc(uid)
            .get();

    if (!memberDoc.exists) {
      throw Exception('User bukan member tenant');
    }

    _role = memberDoc['role'];
  }

  // ================= SET SESSION (SETELAH REGISTER TENANT) =================
  static void setSession({required String tenantId, required String role}) {
    _tenantId = tenantId;
    _role = role;
  }

  // ================= CREATE TENANT (CLIENT TRANSACTION) =================
  /// Creates a tenant and links the current user as member with given [role].
  /// This uses a Firestore transaction to ensure atomicity.
  /// Requires the user to be logged in and email verified.
  static Future<String> createTenantForCurrentUser({
    required String tenantName,
    String role = 'owner',
    bool useUidAsTenantId = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User belum login');
    if (!user.emailVerified) throw Exception('Email belum terverifikasi');

    final uid = user.uid;

    final tenantRef =
        useUidAsTenantId
            ? _db.collection('tenants').doc(uid)
            : _db.collection('tenants').doc();

    final userRef = _db.collection('users').doc(uid);
    final memberRef = tenantRef.collection('members').doc(uid);

    await _db.runTransaction((tx) async {
      final tenantSnap = await tx.get(tenantRef);
      if (tenantSnap.exists) {
        // If tenant doc already exists and is owned by someone else, abort
        final existingOwner = tenantSnap.data()?['ownerUid'];
        if (existingOwner != null && existingOwner != uid) {
          throw Exception('Tenant sudah ada dan tidak dapat dibuat ulang');
        }
      }

      tx.set(tenantRef, {
        'name': tenantName,
        'ownerUid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.set(userRef, {
        'name': user.displayName ?? '',
        'email': user.email,
        'tenantId': tenantRef.id,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      tx.set(memberRef, {
        'role': role,
        'joinedAt': FieldValue.serverTimestamp(),
      });
    });

    // update local session
    setSession(tenantId: tenantRef.id, role: role);

    return tenantRef.id;
  }

  // ================= CHECK ROLE =================
  static bool isOwner() {
    return _role == 'owner' || _role == 'admin';
  }

  static bool isAdmin() {
    return _role == 'admin';
  }

  static bool isStaff() {
    return _role == 'staff';
  }

  static bool isUser() {
    return _role == 'user';
  }

  static bool isCustomservices() {
    return _role == 'customservices';
  }

  static bool isSuplayer() {
    return _role == 'suplayer';
  }

  // ================= LOGOUT =================
  static Future<void> logout() async {
    await _auth.signOut();
    _tenantId = null;
    _role = null;
  }
}
