import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/messages.dart';
import '../../services/search_service.dart';
import '../../services/services.dart';
import '../../widgets/common.dart';
import 'image_search_screen.dart';
import 'search_flow.dart';

/// واجهة البحث بالكتابة (FR-04).
class TextSearchScreen extends StatefulWidget {
  const TextSearchScreen({super.key, this.initialQuery});
  final String? initialQuery;

  @override
  State<TextSearchScreen> createState() => _TextSearchScreenState();
}

class _TextSearchScreenState extends State<TextSearchScreen> {
  late final TextEditingController _query = TextEditingController(
    text: widget.initialQuery,
  );
  bool _loading = false;
  String? _notFoundFor;

  @override
  void initState() {
    super.initState();
    if ((widget.initialQuery ?? '').trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _search());
    }
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  /// تسلسل البحث بالكتابة: إدخال الاسم التجاري أو العلمي والضغط على بحث ←
  /// إرسال اسم الدواء للتحقق منه في قاعدة البيانات:
  /// - ضعف الإنترنت: "تعثرت العملية، الرجاء إعادة المحاولة عند توفر الاتصال"
  /// - غير موجود في medicines: "الدواء غير متوفر"
  /// - موجود: البحث عنه في availability ← بيانات الصيدليات مع السعر والكمية
  ///   والموقع والشكل الصيدلاني ← طلب إذن الموقع ← العرض.
  Future<void> _search() async {
    final q = _query.text.trim();
    if (q.length < 2) {
      showSnack(context, 'اكتب حرفين على الأقل من اسم الدواء', error: true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _notFoundFor = null;
    });
    RawSearch? raw;
    await runWithRetry(
      context,
      () async => raw = await Services.I.search.findByText(q),
      networkMessage: Msg.searchNetwork,
      errorTitle: 'تعذر البحث',
    );
    if (!mounted) return;
    setState(() => _loading = false);
    final r = raw;
    if (r == null) return;
    if (r.isEmpty) {
      setState(() => _notFoundFor = q);
      return;
    }
    await showSearchResults(context, r, query: q);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      appBar: AppBar(
        toolbarHeight: 72,
        title: const Text(
          'البحث بالكتابة',
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
        color: const Color(0xFFF0F7FF),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 140),
          children: [
            TextField(
              controller: _query,
              autofocus: (widget.initialQuery ?? '').isEmpty,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: const InputDecoration(
                hintText: 'اسم الدواء (الاسم التجاري أو العلمي)',
                prefixIcon: Icon(
                  Icons.search,
                  size: 28,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF12A7AE),
                minimumSize: const Size.fromHeight(60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              onPressed: _loading ? null : _search,
              child: _loading
                  ? const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        color: Colors.white,
                      ),
                    )
                  : const Text('بحث'),
            ),
            if (_notFoundFor != null)
              EmptyState(
                icon: Icons.search_off,
                title: Msg.medicineNotAvailable,
                message:
                    'لم يتم العثور على "$_notFoundFor". تأكد من كتابة الاسم '
                    'أو جرّب البحث بالصورة.',
                action: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('البحث بالصورة'),
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const ImageSearchScreen(),
                    ),
                  ),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.only(top: 70),
                child: Illustration('pills', height: 170),
              ),
          ],
        ),
      ),
    );
  }
}
