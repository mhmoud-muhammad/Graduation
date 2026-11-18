import 'package:intl/intl.dart';

import 'app_config.dart';

abstract final class Fmt {
  static final NumberFormat _price = NumberFormat('#,##0.##', 'en');

  static String price(double v) => '${_price.format(v)} ${AppConfig.currency}';

  static String distance(double? km) {
    if (km == null) return '';
    if (km < 1) return '${(km * 1000).round()} م';
    return '${km.toStringAsFixed(1)} كم';
  }

  static String date(DateTime? d) =>
      d == null ? '' : DateFormat('yyyy/MM/dd – HH:mm', 'en').format(d);
}
