import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:habitos_app/config/helpers/seed_helper.dart';
import 'package:habitos_app/config/helpers/firebase_error_helper.dart';
import 'package:habitos_app/domain/datasources/auth_datasource.dart';
import 'package:habitos_app/domain/entities/user_entity.dart';
import 'package:habitos_app/infrastructure/models/user_model.dart';

class AuthFirebaseDatasource implements AuthDatasource {
  final fa.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthFirebaseDatasource({
    fa.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? fa.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<UserEntity> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = await _getUserFromFirestore(cred.user!.uid);
      if (user == null) {
        throw Exception('Usuario no encontrado');
      }
      await SeedHelper.seedStepHabitForUser(user.id);
      return user;
    } catch (e) {
      throw Exception(FirebaseErrorHelper.translate(e));
    }
  }

  @override
  Future<UserEntity> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = cred.user!.uid;

      final user = UserEntity(
        id: uid,
        name: name.trim(),
        email: email.trim(),
        password: password,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(uid)
          .set(UserModel.fromEntity(user).toMap());

      await SeedHelper.seedStepHabitForUser(uid);

      await _auth.signOut();

      return user;
    } catch (e) {
      throw Exception(FirebaseErrorHelper.translate(e));
    }
  }

  @override
  Future<UserEntity> updateUser(UserEntity user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .set(UserModel.fromEntity(user).toMap(), SetOptions(merge: true));

      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        if (currentUser.displayName != user.name) {
          await currentUser.updateDisplayName(user.name);
        }
        final password = user.password;
        if (password != null && password.isNotEmpty) {
          await currentUser.updatePassword(password);
        }
      }
      return user;
    } catch (e) {
      throw Exception(FirebaseErrorHelper.translate(e));
    }
  }

  @override
  Future<void> saveSession(String token, UserEntity user) async {
    // Firebase Auth gestiona la sesión automáticamente.
  }

  @override
  Future<String?> getToken() async {
    return _auth.currentUser?.getIdToken();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _getUserFromFirestore(uid);
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
  }

  @override
  Future<bool> isAuthenticated() async {
    return _auth.currentUser != null;
  }

  Future<UserEntity?> _getUserFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!).toEntity();
    } catch (e) {
      throw Exception(FirebaseErrorHelper.translate(e));
    }
  }
}