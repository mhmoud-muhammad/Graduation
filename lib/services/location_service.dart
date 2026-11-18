import 'package:geolocator/geolocator.dart';

/// الحصول على موقع المستخدم وحساب المسافات (Geolocator).
class LocationService {
  Position? _last;

  Position? get lastKnown => _last;

  /// يعيد الموقع الحالي أو null إذا رفض المستخدم الإذن أو كانت الخدمة مغلقة.
  Future<Position?> current({bool requestPermission = true}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return _last;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied && requestPermission) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return _last;
      }
      _last = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return _last;
    } catch (_) {
      return _last ?? await Geolocator.getLastKnownPosition();
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
