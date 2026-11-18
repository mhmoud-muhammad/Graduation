import 'package:url_launcher/url_launcher.dart';

/// فتح الاتصال الهاتفي.
Future<bool> callPhone(String phone) =>
    launchUrl(Uri(scheme: 'tel', path: phone.replaceAll(' ', '')));

/// فتح الاتجاهات إلى موقع في تطبيق خرائط Google.
Future<bool> openDirections(double lat, double lng) => launchUrl(
  Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'),
  mode: LaunchMode.externalApplication,
);
