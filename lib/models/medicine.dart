import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/text_utils.dart';

/// كيان الأدوية (Medicines) — مجموعة `medicines/{medicineId}`.
class Medicine {
  const Medicine({
    required this.medicineId,
    required this.scientificName,
    required this.tradeName,
    this.barcode,
    this.form,
  });

  final String medicineId;
  final String scientificName;
  final String tradeName;
  final String? barcode;
  final String? form;

  /// مفتاح يميّز الدواء لمنع التكرار: الاسم التجاري + العلمي بعد التطبيع.
  static String identityKey(String tradeName, String scientificName) =>
      '${TextUtils.normalize(tradeName)}|${TextUtils.normalize(scientificName)}';

  factory Medicine.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Medicine(
      medicineId: doc.id,
      scientificName: (d['scientificName'] as String?) ?? '',
      tradeName: (d['tradeName'] as String?) ?? '',
      barcode: d['barcode'] as String?,
      form: d['form'] as String?,
    );
  }

  Map<String, dynamic> toCreateMap() => {
    'medicineId': medicineId,
    'scientificName': scientificName.trim(),
    'tradeName': tradeName.trim(),
    'barcode': (barcode == null || barcode!.isEmpty) ? null : barcode,
    'form': (form == null || form!.isEmpty) ? null : form,
    'identityKey': identityKey(tradeName, scientificName),
    'searchKeys': TextUtils.buildSearchKeys([tradeName, scientificName]),
    'createdAt': FieldValue.serverTimestamp(),
  };
}
