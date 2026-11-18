import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

class UserRepository {
  UserRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('users');

  Future<void> create(AppUser user) =>
      _col.doc(user.userId).set(user.toCreateMap());

  Stream<AppUser?> watch(String uid) => _col
      .doc(uid)
      .snapshots()
      .map((s) => s.exists ? AppUser.fromDoc(s) : null);
}
