import 'package:dawai/core/text_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TextUtils.normalize', () {
    test('توحيد الحروف العربية وإزالة التشكيل', () {
      expect(TextUtils.normalize('  بَارَاسِيتَامُول  '), 'باراسيتامول');
      expect(TextUtils.normalize('أموكسيسيلين'), 'اموكسيسيلين');
      expect(TextUtils.normalize('إبوبروفين'), 'ابوبروفين');
      expect(TextUtils.normalize('حبة'), 'حبه');
      expect(TextUtils.normalize('Panadol   EXTRA'), 'panadol extra');
    });

    test('تحويل الأرقام العربية وإزالة الرموز', () {
      expect(TextUtils.normalize('بنادول ٥٠٠mg'), 'بنادول 500mg');
      expect(TextUtils.normalize('Augmentin-1g'), 'augmentin 1g');
    });
  });

  group('TextUtils.buildSearchKeys', () {
    final keys = TextUtils.buildSearchKeys(['Panadol Extra', 'Paracetamol']);

    test('يحتوي بادئات الاسم الكامل ولكل كلمة', () {
      expect(keys, containsAll(['pa', 'pan', 'panadol', 'panadol extra']));
      expect(keys, containsAll(['ex', 'extra', 'para', 'paracetamol']));
      expect(keys, contains('panadolextra'));
    });

    test('لا يحتوي مفاتيح بحرف واحد ولا تكرار', () {
      expect(keys.where((k) => k.length < 2), isEmpty);
      expect(keys.toSet().length, keys.length);
    });

    test('مفتاح الاستعلام يطابق المفاتيح المحفوظة', () {
      expect(keys, contains(TextUtils.queryKey('  PANA ')));
      expect(keys, contains(TextUtils.queryKey('paracet')));
    });

    test('البحث العربي يتجاهل الهمزات', () {
      final ar = TextUtils.buildSearchKeys(['أموكسيل']);
      expect(ar, contains(TextUtils.queryKey('اموك')));
    });
  });

  group('barcode', () {
    test('تمييز الباركود', () {
      expect(TextUtils.looksLikeBarcode('6281012345678'), isTrue);
      expect(TextUtils.looksLikeBarcode('panadol'), isFalse);
      expect(TextUtils.normalizeBarcode('٦٢٨١٠١٢'), '6281012');
    });
  });
}
