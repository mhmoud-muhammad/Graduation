import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';

import '../core/app_config.dart';
import '../core/firebase_errors.dart';
import '../models/search_models.dart';

/// تحليل صورة العبوة أو الروشتة باستخدام Gemini عبر Firebase AI Logic.
///
/// الصورة تُرسل للتحليل فقط ولا تُحفظ في أي مكان.
class GeminiService {
  GenerativeModel? _model;

  GenerativeModel get _m => _model ??= FirebaseAI.googleAI().generativeModel(
    model: AppConfig.geminiModel,
    generationConfig: GenerationConfig(
      temperature: 0,
      responseMimeType: 'application/json',
    ),
  );

  static const String _schema = '''
أعد JSON فقط بهذا الشكل بدون أي نص إضافي:
{
  "readable": true|false,
  "tradeNames": ["..."],
  "scientificNames": ["..."],
  "barcodes": ["..."],
  "note": "ملاحظة قصيرة بالعربية"
}
- tradeNames: الأسماء التجارية كما تظهر (بالإنجليزية إن كانت مكتوبة بها).
- scientificNames: المادة/المواد الفعالة (الاسم العلمي) بالإنجليزية.
- barcodes: أرقام الباركود المقروءة فقط (أرقام بدون مسافات).
- اجعل readable=false إذا كانت الصورة غير واضحة أو لا تحتوي على دواء.
- لا تخمّن أسماء غير ظاهرة في الصورة.''';

  static String _prompt(ImageKind kind) => switch (kind) {
    ImageKind.package =>
      'هذه صورة لعبوة أو شريط دواء. استخرج اسم الدواء التجاري والاسم '
          'العلمي (المادة الفعالة) والباركود إن ظهر.\n$_schema',
    ImageKind.prescription =>
      'هذه صورة لروشتة (وصفة طبية) قد تكون بخط اليد. استخرج أسماء كل '
          'الأدوية المكتوبة فيها (التجارية والعلمية) بأفضل قراءة ممكنة.\n'
          '$_schema',
  };

  Future<ImageAnalysis> analyze(
    Uint8List bytes, {
    required ImageKind kind,
    String mimeType = 'image/jpeg',
  }) async {
    final GenerateContentResponse response;
    try {
      response = await _m.generateContent([
        Content.multi([
          TextPart(_prompt(kind)),
          InlineDataPart(mimeType, bytes),
        ]),
      ]);
    } on FirebaseAIException catch (e) {
      throw AppException('تعذر تحليل الصورة: ${e.message}');
    } catch (_) {
      throw AppException('تعذر الاتصال بخدمة تحليل الصور، تحقق من الإنترنت');
    }
    return parse(response.text);
  }

  /// تحويل رد النموذج إلى [ImageAnalysis] (يتحمّل وجود ```json حول الرد).
  static ImageAnalysis parse(String? text) {
    if (text == null || text.trim().isEmpty) {
      return const ImageAnalysis(readable: false);
    }
    var t = text.trim();
    final start = t.indexOf('{');
    final end = t.lastIndexOf('}');
    if (start < 0 || end <= start) return const ImageAnalysis(readable: false);
    t = t.substring(start, end + 1);
    try {
      final j = jsonDecode(t);
      if (j is! Map<String, dynamic>) {
        return const ImageAnalysis(readable: false);
      }
      return ImageAnalysis.fromJson(j);
    } on FormatException {
      return const ImageAnalysis(readable: false);
    }
  }
}
