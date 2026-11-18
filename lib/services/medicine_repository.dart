import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/text_utils.dart';
import '../models/availability.dart';
import '../models/medicine.dart';
import 'firestore_utils.dart';

/// بيانات الأدوية وتوفرها في الصيدليات (FR-04, FR-09, FR-10).
class MedicineRepository {
  MedicineRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _medicines =>
      _db.collection('medicines');
  CollectionReference<Map<String, dynamic>> get _availability =>
      _db.collection('availability');

  // ---------------------------------------------------------------- البحث

  /// البحث بالاسم العلمي أو التجاري (أو جزء من بدايته) أو بالباركود.
  Future<List<Medicine>> searchByText(String query, {int limit = 20}) async {
    final results = <String, Medicine>{};
    if (TextUtils.looksLikeBarcode(query)) {
      for (final m in await findByBarcode(TextUtils.normalizeBarcode(query))) {
        results[m.medicineId] = m;
      }
    }
    final key = TextUtils.queryKey(query);
    if (key.length >= TextUtils.minKeyLength) {
      final snap = await _medicines
          .where('searchKeys', arrayContains: key)
          .limit(limit)
          .get();
      for (final d in snap.docs) {
        results[d.id] = Medicine.fromDoc(d);
      }
    }
    return results.values.toList();
  }

  Future<List<Medicine>> findByBarcode(String barcode) async {
    if (barcode.isEmpty) return const [];
    final snap = await _medicines
        .where('barcode', isEqualTo: barcode)
        .limit(5)
        .get();
    return snap.docs.map(Medicine.fromDoc).toList();
  }

  Future<Map<String, Medicine>> getByIds(Iterable<String> ids) async {
    final docs = await fetchByIds(_medicines, ids);
    return {for (final d in docs) d.id: Medicine.fromDoc(d)};
  }

  /// سجلات التوفر لمجموعة أدوية في كل الصيدليات.
  Future<List<Availability>> availabilityForMedicines(
    Iterable<String> medicineIds,
  ) async {
    final ids = medicineIds.toSet().toList();
    if (ids.isEmpty) return const [];
    final snaps = await Future.wait(
      chunked(
        ids,
      ).map((part) => _availability.where('medicineId', whereIn: part).get()),
    );
    return [for (final s in snaps) ...s.docs.map(Availability.fromDoc)];
  }

  // ---------------------------------------------------- إدارة أدوية الصيدلية

  /// أدوية صيدلية محددة (لواجهة إدارة الأدوية لدى الصيدلي).
  Stream<List<Availability>> watchPharmacyStock(String pharmacyId) =>
      _availability
          .where('pharmacyId', isEqualTo: pharmacyId)
          .snapshots()
          .map((s) => s.docs.map(Availability.fromDoc).toList());

  /// يبحث عن الدواء في medicines (بالباركود ثم بالاسمين) وينشئه إن لم يكن
  /// موجوداً، ثم يحفظ سجل التوفر في availability.
  Future<Medicine> addToPharmacy({
    required String pharmacyId,
    required String tradeName,
    required String scientificName,
    String? barcode,
    String? form,
    required double price,
    required int quantity,
  }) async {
    final cleanBarcode = barcode == null
        ? null
        : TextUtils.normalizeBarcode(barcode);
    final medicine = await _findOrCreate(
      tradeName: tradeName,
      scientificName: scientificName,
      barcode: (cleanBarcode?.isEmpty ?? true) ? null : cleanBarcode,
      form: form,
    );
    final id = Availability.idFor(pharmacyId, medicine.medicineId);
    await _availability
        .doc(id)
        .set(
          Availability(
            availabilityId: id,
            medicineId: medicine.medicineId,
            pharmacyId: pharmacyId,
            price: price,
            quantity: quantity,
          ).toMap(),
        );
    return medicine;
  }

  Future<Medicine> _findOrCreate({
    required String tradeName,
    required String scientificName,
    String? barcode,
    String? form,
  }) async {
    if (barcode != null) {
      final byBarcode = await findByBarcode(barcode);
      if (byBarcode.isNotEmpty) return byBarcode.first;
    }
    final identity = Medicine.identityKey(tradeName, scientificName);
    final existing = await _medicines
        .where('identityKey', isEqualTo: identity)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      final m = Medicine.fromDoc(existing.docs.first);
      // إكمال الباركود أو الشكل إن كانا ناقصين في السجل الموجود.
      final patch = <String, dynamic>{
        if (m.barcode == null && barcode != null) 'barcode': barcode,
        if (m.form == null && form != null && form.isNotEmpty) 'form': form,
      };
      if (patch.isNotEmpty) await existing.docs.first.reference.update(patch);
      return m;
    }
    final ref = _medicines.doc();
    final medicine = Medicine(
      medicineId: ref.id,
      scientificName: scientificName,
      tradeName: tradeName,
      barcode: barcode,
      form: form,
    );
    await ref.set(medicine.toCreateMap());
    return medicine;
  }

  Future<void> updateStock({
    required String availabilityId,
    required double price,
    required int quantity,
  }) => _availability.doc(availabilityId).update({
    'price': price,
    'quantity': quantity,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> removeFromPharmacy(String availabilityId) =>
      _availability.doc(availabilityId).delete();
}
