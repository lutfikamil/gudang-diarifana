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

  // ================= LOAD TENANT SESSION =================
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
