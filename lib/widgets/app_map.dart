import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// بديل لعرض الخريطة في المعاينات والاختبارات فقط، حيث لا تعمل خرائط
/// Google خارج الجهاز. في التطبيق الحقيقي تبقى null فتظهر GoogleMap.
@visibleForTesting
Widget Function(Set<Marker> markers)? debugMapPreview;

/// يعرض [map] أو بديل المعاينة إن وُجد.
Widget appMap(Set<Marker> markers, Widget Function() map) =>
    debugMapPreview?.call(markers) ?? map();
