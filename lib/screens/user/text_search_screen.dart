import 'package:material_ui/material_ui.dart';

import '../../core/app_theme.dart';
import '../../core/firebase_errors.dart';
import '../../services/services.dart';
import '../../widgets/common.dart';
import 'image_search_screen.dart';
import 'search_results_screen.dart';

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
    try {
      final results = await Services.I.search.searchText(q);
      if (!mounted) return;
      if (results.isEmpty) {
        setState(() => _notFoundFor = q);
      } else {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SearchResultsScreen(results: results, query: q),
          ),
        );
      }
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('البحث بالكتابة')),
      body: WaveBackground(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 140),
          children: [
            TextField(
              controller: _query,
              autofocus: (widget.initialQuery ?? '').isEmpty,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: const InputDecoration(
                hintText: 'اسم الدواء (الاسم التجاري أو العلمي)',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            LoadingButton(label: 'بحث', loading: _loading, onPressed: _search),
            const SizedBox(height: 12),
            const Text(
              'يمكنك كتابة جزء من الاسم مثل: "بارا" أو "panadol" أو رقم الباركود.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
            if (_notFoundFor != null)
              EmptyState(
                icon: Icons.search_off,
                title: 'لم يتم العثور على "$_notFoundFor"',
                message: 'تأكد من كتابة الاسم بشكل صحيح، أو جرّب البحث بصورة العبوة.',
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
                padding: EdgeInsets.only(top: 40),
                child: Icon(
                  Icons.medication,
                  size: 120,
                  color: AppColors.skyDeep,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
