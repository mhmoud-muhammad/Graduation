import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/firebase_errors.dart';
import '../../core/messages.dart';
import '../../models/search_models.dart';
import '../../services/services.dart';
import '../../widgets/common.dart';
import 'search_results_screen.dart';
import 'text_search_screen.dart';

/// واجهة البحث بالصورة (FR-05, FR-06, FR-07).
///
/// يختار المستخدم صورة عبوة أو روشتة من المعرض أو يلتقط صورة بالكاميرا،
/// فتُرسل إلى Gemini لاستخراج الأسماء/الباركود ثم يتم البحث في قاعدة البيانات.
/// لا يتم حفظ الصورة.
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
  bool _noMatch = false;

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
        _noMatch = false;
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

  /// مخطط تسلسل البحث بالصورة: اختيار صورة الدواء من المعرض أو التقاطها
  /// بالكاميرا ← إرسال الصورة للتحليل ← (تحليل بيانات الصورة: Gemini) معالجة
  /// الصورة واستخراج اسم الدواء ← البحث عن الدواء بالاسم المستخرج
  /// ← إرجاع بيانات الدواء ← عرض نتائج البحث والصيدليات المتوفر فيها
  /// وموقعها والسعر والكمية.
  Future<void> _analyze() async {
    final bytes = _bytes;
    if (bytes == null) return;
    setState(() {
      _loading = true;
      _status = 'جاري تحليل الصورة...';
    });
    try {
      final analysis = await Services.I.gemini.analyze(
        bytes,
        kind: _kind,
        mimeType: _mime,
      );
      if (!mounted) return;
      setState(() => _analysis = analysis);
      if (!analysis.readable || analysis.isEmpty) return;

      setState(() => _status = 'جاري البحث عن الدواء...');
      final results = await Services.I.search.searchAnalysis(analysis);
      if (!mounted) return;
      if (results.isEmpty) {
        setState(() => _noMatch = true);
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SearchResultsScreen(
            results: results,
            query: analysis.allNames.join('، '),
          ),
        ),
      );
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
      appBar: AppBar(title: const Text('البحث بالصورة')),
      body: WaveBackground(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 140),
          children: [
            SegmentedButton<ImageKind>(
              segments: [
                for (final k in ImageKind.values)
                  ButtonSegment(
                    value: k,
                    label: Text(k.label),
                    icon: Icon(
                      k == ImageKind.package
                          ? Icons.medication_outlined
                          : Icons.receipt_long_outlined,
                    ),
                  ),
              ],
              selected: {_kind},
              onSelectionChanged: _loading
                  ? null
                  : (s) => setState(() => _kind = s.first),
            ),
            const SizedBox(height: 16),
            _PreviewBox(bytes: _bytes, kind: _kind, loading: _loading),
            const SizedBox(height: 10),
            Text(
              _loading
                  ? _status
                  : 'سنقوم بتحديد الدواء وعرض الصيدليات والأسعار المتاحة',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            if (a != null && !_loading) ...[
              const SizedBox(height: 12),
              _AnalysisCard(
                analysis: a,
                noMatch: _noMatch,
                onSearchName: _searchByName,
              ),
            ],
            const SizedBox(height: 18),
            LoadingButton(
              icon: Icons.photo_library_outlined,
              label: 'اختيار صورة من المعرض',
              loading: false,
              onPressed: _loading ? null : () => _pick(ImageSource.gallery),
            ),
            const SizedBox(height: 12),
            LoadingButton(
              icon: Icons.photo_camera_outlined,
              label: 'التقاط صورة بالكاميرا',
              loading: false,
              onPressed: _loading ? null : () => _pick(ImageSource.camera),
            ),
            if (_bytes != null && !_loading) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة التحليل'),
                onPressed: _analyze,
              ),
            ],
          ],
        ),
      ),
    );
  }
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
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary, width: 1.6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (bytes != null)
            Image.memory(bytes!, fit: BoxFit.contain)
          else
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add_a_photo_outlined,
                  size: 54,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  kind == ImageKind.package
                      ? 'ضع صورة علبة الدواء أو الشريط هنا للبحث'
                      : 'ضع صورة الروشتة هنا للبحث',
                  style: const TextStyle(color: AppColors.navy),
                ),
              ],
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
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({
    required this.analysis,
    required this.noMatch,
    required this.onSearchName,
  });

  final ImageAnalysis analysis;
  final bool noMatch;
  final ValueChanged<String> onSearchName;

  @override
  Widget build(BuildContext context) {
    if (!analysis.readable || analysis.isEmpty) {
      return Card(
        color: const Color(0xFFFFF4E5),
        child: ListTile(
          leading: const Icon(Icons.blur_on, color: Colors.orange),
          title: const Text('الصورة غير واضحة'),
          subtitle: Text(analysis.note ?? Msg.imageNotRecognized),
          trailing: IconButton(
            icon: const Icon(Icons.keyboard_alt_outlined),
            tooltip: 'البحث بالكتابة',
            onPressed: () => onSearchName(''),
          ),
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
              noMatch
                  ? 'تم التعرف على الصورة لكن الدواء غير مسجل في أي صيدلية'
                  : 'المعلومات المستخرجة من الصورة',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
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
                for (final b in analysis.barcodes)
                  Chip(
                    avatar: const Icon(Icons.qr_code, size: 18),
                    label: Text(b),
                  ),
              ],
            ),
            if (noMatch)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'اضغط على أي اسم لتعديله والبحث عنه يدوياً.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
