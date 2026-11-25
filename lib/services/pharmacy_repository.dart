import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/pharmacy.dart';
import 'firestore_utils.dart';
import 'network_service.dart';

/// بيانات الصيدليات (FR-08): تسجيل صيدلية جديدة وتعديل بياناتها.
class PharmacyRepository {
  PharmacyRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('pharmacies');

  /// صيدليات الصيدلي (علاقة «يدير» واحد إلى متعدد).
  Stream<List<Pharmacy>> watchByOwner(String ownerId) => _col
      .where('ownerId', isEqualTo: ownerId)
      .snapshots()
      .map(
        (s) =>
            s.docs.map(Pharmacy.fromDoc).toList()
              ..sort((a, b) => a.pharmacyName.compareTo(b.pharmacyName)),
      );

  /// زر "تسجيل": حفظ صيدلية جديدة في مجموعة pharmacies.
  Future<Pharmacy> create(Pharmacy pharmacy) => Net.guard(() async {
    final ref = _col.doc();
    final saved = pharmacy.copyWith(pharmacyId: ref.id);
    await ref.set(saved.toMap());
    return saved;
  });

  /// زر "تعديل": حفظ بيانات الصيدلية المعدلة.
  Future<void> update(Pharmacy pharmacy) =>
      Net.guard(() => _col.doc(pharmacy.pharmacyId).set(pharmacy.toMap()));

  Future<Map<String, Pharmacy>> getByIds(Iterable<String> ids) async {
    final docs = await fetchByIds(_col, ids);
    return {for (final d in docs) d.id: Pharmacy.fromDoc(d)};
  }
}
