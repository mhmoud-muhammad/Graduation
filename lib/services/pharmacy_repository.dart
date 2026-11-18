import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/pharmacy.dart';
import 'firestore_utils.dart';

/// بيانات الصيدليات (FR-08).
class PharmacyRepository {
  PharmacyRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('pharmacies');

  Future<Pharmacy?> getByOwner(String ownerId) async {
    final doc = await _col.doc(ownerId).get();
    return doc.exists ? Pharmacy.fromDoc(doc) : null;
  }

  Stream<Pharmacy?> watchByOwner(String ownerId) => _col
      .doc(ownerId)
      .snapshots()
      .map((s) => s.exists ? Pharmacy.fromDoc(s) : null);

  Future<void> save(Pharmacy pharmacy) =>
      _col.doc(pharmacy.pharmacyId).set(pharmacy.toMap());

  Future<Map<String, Pharmacy>> getByIds(Iterable<String> ids) async {
    final docs = await fetchByIds(_col, ids);
    return {for (final d in docs) d.id: Pharmacy.fromDoc(d)};
  }
}
