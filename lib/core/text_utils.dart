/// أدوات تطبيع النص العربي/الإنجليزي وتوليد مفاتيح البحث.
///
/// تُحفظ مفاتيح البحث (searchKeys) في وثيقة الدواء، وهي بادئات (prefixes)
/// للاسم العلمي والتجاري ولكل كلمة فيهما بأحرف صغيرة وبعد التطبيع، حتى
/// يمكن البحث في Firestore بعامل `array-contains` بأي جزء من بداية الاسم.
abstract final class TextUtils {
  static final RegExp _tashkeel = RegExp('[ً-ْـ]');
  static final RegExp _spaces = RegExp(r'\s+');
  static final RegExp _punct = RegExp(r'[^\p{L}\p{N}\s]', unicode: true);

  static const int minKeyLength = 2;
  static const int maxKeyLength = 40;

  /// يحوّل النص إلى صيغة موحدة للمقارنة والبحث.
  static String normalize(String input) {
    var s = input.trim().toLowerCase();
    s = s.replaceAll(_tashkeel, '');
    s = s
        .replaceAll(RegExp('[أإآٱ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي');
    s = _toLatinDigits(s);
    s = s.replaceAll(_punct, ' ');
    return s.replaceAll(_spaces, ' ').trim();
  }

  static String _toLatinDigits(String s) {
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    final b = StringBuffer();
    for (final ch in s.split('')) {
      final a = arabic.indexOf(ch);
      final p = persian.indexOf(ch);
      if (a >= 0) {
        b.write(a);
      } else if (p >= 0) {
        b.write(p);
      } else {
        b.write(ch);
      }
    }
    return b.toString();
  }

  /// بادئات نص واحد بطول من [minKeyLength] إلى [maxKeyLength].
  static Iterable<String> _prefixes(String s) sync* {
    final end = s.length < maxKeyLength ? s.length : maxKeyLength;
    for (var i = minKeyLength; i <= end; i++) {
      yield s.substring(0, i);
    }
  }

  /// يولّد مفاتيح البحث لمجموعة أسماء (الاسم العلمي والتجاري).
  static List<String> buildSearchKeys(Iterable<String> names) {
    final keys = <String>{};
    for (final raw in names) {
      final name = normalize(raw);
      if (name.isEmpty) continue;
      keys.addAll(_prefixes(name));
      // الاسم بدون مسافات (مثلاً "panadol extra" -> "panadolextra")
      final compact = name.replaceAll(' ', '');
      keys.addAll(_prefixes(compact));
      for (final word in name.split(' ')) {
        keys.addAll(_prefixes(word));
      }
    }
    return keys.toList()..sort();
  }

  /// يحوّل نص الاستعلام إلى مفتاح يطابق أحد [buildSearchKeys].
  static String queryKey(String query) {
    final q = normalize(query);
    return q.length > maxKeyLength ? q.substring(0, maxKeyLength) : q;
  }

  /// باركود: أرقام فقط.
  static String normalizeBarcode(String input) =>
      _toLatinDigits(input).replaceAll(RegExp(r'[^0-9]'), '');

  static bool looksLikeBarcode(String input) {
    final digits = normalizeBarcode(input);
    return digits.length >= 6 && digits.length == input.trim().length;
  }
}
