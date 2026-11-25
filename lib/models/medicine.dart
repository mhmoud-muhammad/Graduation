import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/text_utils.dart';

/// كيان الأدوية (Medicines) — مجموعة `medicines/{medicineId}`.
///
/// الحقول حسب قاموس البيانات: medicineId, tradeName, scientificName,
/// pharmaceuticalForm. ويُضاف حقلان تقنيان للبحث فقط:
/// `searchKeys` (بادئات الاسمين لتسريع البحث) و `identityKey` (منع التكرار).
class Medicine {
  const Medicine({
    required this.medicineId,
    required this.scientificName,
    required this.tradeName,
    required this.pharmaceuticalForm,
  });

  final String medicineId;
  final String scientificName;
  final String tradeName;
  final String pharmaceuticalForm;

  /// يميّز الدواء: الاسم التجاري + العلمي + الشكل الصيدلاني بعد التطبيع.
  static String identityKey(String trade, String scientific, String form) =>
      '${TextUtils.normalize(trade)}|${TextUtils.normalize(scientific)}|'
      '${TextUtils.normalize(form)}';

  factory Medicine.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Medicine(
      medicineId: doc.id,
      scientificName: (d['scientificName'] as String?) ?? '',
      tradeName: (d['tradeName'] as String?) ?? '',
      pharmaceuticalForm:
          (d['pharmaceuticalForm'] as String?) ?? (d['form'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toCreateMap() => {
    'medicineId': medicineId,
    'tradeName': tradeName.trim(),
    'scientificName': scientificName.trim(),
    'pharmaceuticalForm': pharmaceuticalForm.trim(),
    'identityKey': identityKey(tradeName, scientificName, pharmaceuticalForm),
    'searchKeys': TextUtils.buildSearchKeys([tradeName, scientificName]),
  };
}
