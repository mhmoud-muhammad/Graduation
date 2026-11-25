import 'package:geolocator/geolocator.dart';

/// موقع المستخدم وحساب المسافات (Geolocator).
///
/// يُستخدم الموقع وقت البحث فقط لحساب المسافة ولا يُخزَّن (NFR-07).
class LocationService {
  Position? _last;
  Position? get lastKnown => _last;

  /// هل سبق أن منح المستخدم إذن الموقع؟
  Future<bool> hasPermission() async {
    final p = await Geolocator.checkPermission();
    return p == LocationPermission.always || p == LocationPermission.whileInUse;
  }

  /// يطلب إذن النظام ثم يعيد الموقع، أو null عند الرفض أو إغلاق الخدمة.
  Future<Position?> requestAndGet() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }
      _last = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return _last;
    } catch (_) {
      return await Geolocator.getLastKnownPosition();
    }
  }

  static double distanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) => Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000;

  Future<bool> openSettings() => Geolocator.openLocationSettings();
}
