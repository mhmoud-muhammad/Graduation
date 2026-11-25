import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/text_utils.dart';
import '../models/availability.dart';
import '../models/medicine.dart';
import '../models/search_models.dart';
import 'firestore_utils.dart';
import 'network_service.dart';

/// بيانات الأدوية وتوفرها في الصيدليات.
class MedicineRepository {
  MedicineRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _medicines =>
      _db.collection('medicines');
  CollectionReference<Map<String, dynamic>> get _availability =>
      _db.collection('availability');

  // ------------------------------------------------------------------ البحث

  /// البحث في medicines بالاسم العلمي أو التجاري (أو بداية أي منهما).
  Future<List<Medicine>> searchByText(String query, {int limit = 20}) async {
    final key = TextUtils.queryKey(query);
    if (key.length < TextUtils.minKeyLength) return const [];
    final snap = await _medicines
        .where('searchKeys', arrayContains: key)
        .limit(limit)
        .get(serverOnly);
    return snap.docs.map(Medicine.fromDoc).toList();
  }

  Future<Map<String, Medicine>> getByIds(Iterable<String> ids) async {
    final docs = await fetchByIds(_medicines, ids);
    return {for (final d in docs) d.id: Medicine.fromDoc(d)};
  }

  /// الاستعلام عن التوفر في availability لمجموعة أدوية.
  Future<List<Availability>> availabilityForMedicines(
    Iterable<String> medicineIds,
  ) async {
    final ids = medicineIds.toSet().toList();
    if (ids.isEmpty) return const [];
    final snaps = await Future.wait(
      chunked(ids).map(
        (part) =>
            _availability.where('medicineId', whereIn: part).get(serverOnly),
      ),
    );
    return [for (final s in snaps) ...s.docs.map(Availability.fromDoc)];
  }

  // ------------------------------------------------- أدوية الصيدلية (FR-12)

  Stream<List<Availability>> watchPharmacyStock(String pharmacyId) =>
      _availability
          .where('pharmacyId', isEqualTo: pharmacyId)
          .snapshots()
          .map((s) => s.docs.map(Availability.fromDoc).toList());

  /// تسلسل إضافة دواء: التحقق من البيانات ← يبحث النظام عن الدواء في
  /// medicines وينشئ سجلاً جديداً إن لم يجده ← حفظ سجل توفر الدواء في
  /// availability ← "تمت الإضافة بنجاح".
  Future<Medicine> addToPharmacy({
    required String pharmacyId,
    required String tradeName,
    required String scientificName,
    required String pharmaceuticalForm,
    required double price,
    required int quantity,
  }) => Net.guard(() async {
    final medicine = await _findOrCreate(
      tradeName: tradeName,
      scientificName: scientificName,
      form: pharmaceuticalForm,
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
  });

  Future<Medicine> _findOrCreate({
    required String tradeName,
    required String scientificName,
    required String form,
  }) async {
    final identity = Medicine.identityKey(tradeName, scientificName, form);
    final existing = await _medicines
        .where('identityKey', isEqualTo: identity)
        .limit(1)
        .get(serverOnly);
    if (existing.docs.isNotEmpty) return Medicine.fromDoc(existing.docs.first);
    final ref = _medicines.doc();
    final medicine = Medicine(
      medicineId: ref.id,
      scientificName: scientificName,
      tradeName: tradeName,
      pharmaceuticalForm: form,
    );
    await ref.set(medicine.toCreateMap());
    return medicine;
  }

  /// تحديث/حذف دواء: "إدخال اسم الدواء" ← يتحقق النظام من وجوده في قائمة
  /// هذه الصيدلية. تعيد القائمة فارغة إذا لم يكن الدواء موجوداً.
  Future<List<StockItem>> findInPharmacy(String pharmacyId, String name) =>
      Net.guard(() async {
        final meds = await searchByText(name, limit: 30);
        if (meds.isEmpty) return const <StockItem>[];
        final snaps = await Future.wait(
          meds.map(
            (m) => _availability
                .doc(Availability.idFor(pharmacyId, m.medicineId))
                .get(serverOnly),
          ),
        );
        return [
          for (var i = 0; i < meds.length; i++)
            if (snaps[i].exists)
              StockItem(meds[i], Availability.fromDoc(snaps[i])),
        ];
      });

  /// تسلسل تعديل دواء: تعديل السعر والكمية وحفظ سجل التوفر في availability.
  Future<void> updateStock({
    required String availabilityId,
    required double price,
    required int quantity,
  }) => Net.guard(
    () => _availability.doc(availabilityId).update({
      'price': price,
      'quantity': quantity,
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  /// تسلسل حذف دواء: حذف سجل توفر الدواء المرتبط بالصيدلية من availability
  /// (يبقى سجل الدواء العام في medicines لأنه قد يكون لدى صيدليات أخرى).
  Future<void> removeFromPharmacy(String availabilityId) =>
      Net.guard(() => _availability.doc(availabilityId).delete());
}
