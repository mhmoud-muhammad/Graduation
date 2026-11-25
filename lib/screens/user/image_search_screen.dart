import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_theme.dart';
import '../../core/messages.dart';
import '../../models/search_models.dart';
import '../../services/search_service.dart';
import '../../services/services.dart';
import '../../widgets/common.dart';
import 'search_flow.dart';
import 'text_search_screen.dart';

/// واجهة البحث بالصورة (FR-05, FR-06, FR-07, FR-13).
///
/// الصورة تُرسل لخدمة Gemini للتحليل فقط ولا تُحفظ.
class ImageSearchScreen extends StatefulWidget {
  const ImageSearchScreen({super.key});

  @override
  State<ImageSearchScreen> createState() => _ImageSearchScreenState();
}

class _ImageSearchScreenState extends State<ImageSearchScreen> {
  final _picker = ImagePicker();
  ImageKind _kind = ImageKind.package;
  Uint8List? _bytes;
  String _mime = 'image/jpeg';
  bool _loading = false;
  String _status = '';
  ImageAnalysis? _analysis;
  bool _notAvailable = false;

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _bytes = bytes;
        _mime =
            file.mimeType ??
            (file.path.toLowerCase().endsWith('.png')
                ? 'image/png'
                : 'image/jpeg');
        _analysis = null;
        _notAvailable = false;
      });
      await _analyze();
    } catch (_) {
      if (mounted) {
        showSnack(
          context,
          'تعذر الوصول إلى الصورة، تحقق من الأذونات',
          error: true,
        );
      }
    }
  }

  /// تسلسل البحث بالصورة: رفع صورة الدواء أو الروشتة من المعرض أو تصويرها
  /// بالكاميرا ←
  /// - ضعف الإنترنت: "تعثرت العملية بسبب ضعف الإنترنت، الرجاء المحاولة"
  /// - إرسال الصورة إلى Gemini: غير واضحة ← "الصورة غير واضحة، قم بتحميل
  ///   صورة أوضح"
  /// - إرجاع معلومات الدواء والشكل الصيدلاني ← البحث في medicines:
  ///   غير موجود ← "الدواء غير متوفر"
  /// - موجود ← الاستعلام عن التوفر في availability ← طلب إذن الموقع ← العرض.
  Future<void> _analyze() async {
    final bytes = _bytes;
    if (bytes == null) return;
    setState(() {
      _loading = true;
      _status = 'جاري تحليل الصورة...';
    });
    ImageAnalysis? analysis;
    RawSearch? raw;
    await runWithRetry(
      context,
      () async {
        analysis = await Services.I.gemini.analyze(
          bytes,
          kind: _kind,
          mimeType: _mime,
        );
        if (!analysis!.readable || analysis!.isEmpty) return;
        if (mounted) setState(() => _status = 'جاري البحث عن الدواء...');
        raw = await Services.I.search.findByAnalysis(analysis!);
      },
      networkMessage: Msg.imageNetwork,
      errorTitle: 'تعذر تحليل الصورة',
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _analysis = analysis;
      _notAvailable = raw != null && raw!.isEmpty;
    });
    final r = raw;
    if (r == null || r.isEmpty) return;
    await showSearchResults(context, r, query: analysis!.allNames.join('، '));
  }

  void _searchByName(String name) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TextSearchScreen(initialQuery: name)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = _analysis;
    return Scaffold(
      backgroundColor: const Color(0xFFEEF7FF),
      appBar: AppBar(
        toolbarHeight: 72,
        backgroundColor: const Color(0xFFE3EAF2),
        title: const Text(
          'البحث بالصورة',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          color: AppColors.navy,
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: WaveBackground(
        top: false,
        color: const Color(0xFFEEF7FF),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(26, 16, 26, 140),
          children: [
            // FR-05 / FR-06: نوع الصورة (عبوة دواء أو روشتة طبية).
            SegmentedButton<ImageKind>(
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppColors.primary,
                selectedForegroundColor: Colors.white,
                backgroundColor: Colors.white,
              ),
              segments: [
                for (final k in ImageKind.values)
                  ButtonSegment(value: k, label: Text(k.label)),
              ],
              selected: {_kind},
              onSelectionChanged: _loading
                  ? null
                  : (s) => setState(() => _kind = s.first),
            ),
            const SizedBox(height: 14),
            _PreviewBox(bytes: _bytes, kind: _kind, loading: _loading),
            const SizedBox(height: 14),
            Text(
              _loading
                  ? _status
                  : 'ستقوم بتحديد الدواء وعرض التفاصيل والأسعار المتاحة',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF4A5568), fontSize: 15),
            ),
            if (a != null && !_loading) ...[
              const SizedBox(height: 12),
              _AnalysisCard(
                analysis: a,
                notAvailable: _notAvailable,
                onSearchName: _searchByName,
              ),
            ],
            const SizedBox(height: 20),
            _pickButton(
              Icons.image_outlined,
              'اختيار صورة من المعرض',
              ImageSource.gallery,
            ),
            const SizedBox(height: 14),
            _pickButton(
              Icons.photo_camera_outlined,
              'التقاط صورة بالكاميرا',
              ImageSource.camera,
            ),
            if (_bytes != null && !_loading) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text(Msg.retry),
                onPressed: _analyze,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pickButton(IconData icon, String label, ImageSource source) =>
      FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF078E98),
          minimumSize: const Size.fromHeight(60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        onPressed: _loading ? null : () => _pick(source),
        child: Row(
          children: [
            Icon(icon, size: 32),
            Expanded(child: Text(label, textAlign: TextAlign.center)),
            const SizedBox(width: 32),
          ],
        ),
      );
}

class _PreviewBox extends StatelessWidget {
  const _PreviewBox({
    required this.bytes,
    required this.kind,
    required this.loading,
  });

  final Uint8List? bytes;
  final ImageKind kind;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorder(),
      child: SizedBox(
        height: 300,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                children: [
                  const Icon(
                    Icons.photo_camera_outlined,
                    size: 36,
                    color: AppColors.primary,
                  ),
                  Expanded(
                    child: bytes != null
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(bytes!, fit: BoxFit.contain),
                            ),
                          )
                        : const Icon(
                            Icons.medication_outlined,
                            size: 90,
                            color: Color(0xFFB5CCE0),
                          ),
                  ),
                  Text(
                    kind == ImageKind.package
                        ? 'ضع صورة علبة الدواء أو الشريط هنا للبحث'
                        : 'ضع صورة الروشتة هنا للبحث',
                    style: const TextStyle(
                      color: Color(0xFF1A1F36),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            if (loading)
              const ColoredBox(
                color: Color(0x88FFFFFF),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// إطار متقطع فيروزي حول مكان الصورة (كما في التصميم).
class _DashedBorder extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(22),
    );
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 10), paint);
        d += 18;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({
    required this.analysis,
    required this.notAvailable,
    required this.onSearchName,
  });

  final ImageAnalysis analysis;
  final bool notAvailable;
  final ValueChanged<String> onSearchName;

  @override
  Widget build(BuildContext context) {
    if (!analysis.readable || analysis.isEmpty) {
      return Card(
        color: const Color(0xFFFFF4E5),
        child: ListTile(
          leading: const Icon(Icons.blur_on, color: Colors.orange),
          title: const Text(Msg.imageUnclear),
          subtitle: analysis.note == null ? null : Text(analysis.note!),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notAvailable
                  ? Msg.medicineNotAvailable
                  : 'المعلومات المستخرجة من الصورة',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: notAvailable ? AppColors.danger : AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final n in analysis.allNames)
                  ActionChip(
                    avatar: const Icon(Icons.search, size: 18),
                    label: Text(n),
                    onPressed: () => onSearchName(n),
                  ),
                for (final f in analysis.forms)
                  Chip(
                    avatar: const Icon(Icons.category_outlined, size: 18),
                    label: Text(f),
                  ),
              ],
            ),
            if (notAvailable)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'اضغط على أي اسم لتعديله والبحث عنه بالكتابة.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
