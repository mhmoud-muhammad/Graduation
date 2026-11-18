import 'package:cloud_firestore/cloud_firestore.dart';

/// الحد الأقصى لعناصر عامل whereIn في Firestore.
const int whereInLimit = 30;

Iterable<List<T>> chunked<T>(List<T> items, [int size = whereInLimit]) sync* {
  for (var i = 0; i < items.length; i += size) {
    yield items.sublist(i, i + size > items.length ? items.length : i + size);
  }
}

/// جلب وثائق بمعرّفاتها على دفعات.
Future<List<DocumentSnapshot<Map<String, dynamic>>>> fetchByIds(
  CollectionReference<Map<String, dynamic>> col,
  Iterable<String> ids,
) async {
  final unique = ids.toSet().toList();
  if (unique.isEmpty) return const [];
  final snaps = await Future.wait(
    chunked(
      unique,
    ).map((part) => col.where(FieldPath.documentId, whereIn: part).get()),
  );
  return [for (final s in snaps) ...s.docs];
}
