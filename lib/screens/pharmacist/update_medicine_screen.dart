import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/messages.dart';
import '../../core/validators.dart';
import '../../models/pharmacy.dart';
import '../../models/search_models.dart';
import '../../services/services.dart';
import '../../widgets/common.dart';

/// واجهة تحديث بيانات الأدوية (FR-10, FR-11): يُدخل الصيدلي اسم الدواء
/// فيتحقق النظام من وجوده في قائمة الصيدلية، ثم يعدّل السعر والكمية أو يحذفه.
class UpdateMedicineScreen extends StatefulWidget {
  const UpdateMedicineScreen({super.key, required this.pharmacy, this.initial});

  final Pharmacy pharmacy;

  /// دواء محدد مسبقاً (عند الفتح من "أدوية صيدليتي").
  final StockItem? initial;

  @override
  State<UpdateMedicineScreen> createState() => _UpdateMedicineScreenState();
}

class _UpdateMedicineScreenState extends State<UpdateMedicineScreen> {
  final _query = TextEditingController();
  final _form = GlobalKey<FormState>();
  final _price = TextEditingController();
  final _quantity = TextEditingController();
  List<StockItem> _matches = const [];
  StockItem? _item;
  bool _searching = false;
  bool _saving = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) _select(widget.initial!);
  }

  @override
  void dispose() {
    for (final c in [_query, _price, _quantity]) {
      c.dispose();
    }
    super.dispose();
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  void _select(StockItem item) {
    setState(() {
      _item = item;
      _matches = const [];
      _price.text = _trim(item.availability.price);
      _quantity.text = item.availability.quantity.toString();
    });
  }

  /// "إدخال اسم الدواء المراد تعديله/حذفه" ← إرسال الاسم للتحقق من وجوده:
  /// - ضعف الإنترنت: "تعذرت العملية، الرجاء إعادة المحاولة عند توفر اتصال"
  /// - غير موجود: "... غير موجود لذا لا يمكن تعديله أو حذفه"
  /// - موجود: عرض بيانات الدواء (الاسم والسعر والكمية).
  Future<void> _find() async {
    final q = _query.text.trim();
    if (q.length < 2) {
      showSnack(context, 'اكتب حرفين على الأقل من اسم الدواء', error: true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _searching = true;
      _item = null;
      _matches = const [];
    });
    List<StockItem>? found;
    await runWithRetry(
      context,
      () async => found = await Services.I.medicines.findInPharmacy(
        widget.pharmacy.pharmacyId,
        q,
      ),
      networkMessage: Msg.operationNetwork,
      errorTitle: 'تعذر البحث عن الدواء',
    );
    if (!mounted) return;
    setState(() => _searching = false);
    final list = found;
    if (list == null) return;
    if (list.isEmpty) {
      await showErrorDialog(context, title: Msg.notInPharmacy);
      return;
    }
    if (list.length == 1) {
      _select(list.first);
    } else {
      setState(() => _matches = list);
    }
  }

  /// تسلسل تعديل دواء: تعديل السعر أو الكمية ← "حفظ التعديلات":
  /// - قيم سالبة أو خاطئة: "البيانات غير صحيحة، الرجاء مراجعة المدخلات..."
  /// - صحيحة: تحديث سجل التوفر في availability ← "تم تعديل السعر أو الكمية
  ///   في قائمة الأدوية".
  Future<void> _save() async {
    final item = _item!;
    if (!_form.currentState!.validate()) {
      await showErrorDialog(context, title: Msg.updateInvalid);
      return;
    }
    setState(() => _saving = true);
    final price = double.parse(_price.text.trim());
    final qty = int.parse(_quantity.text.trim());
    final ok = await runWithRetry(
      context,
      () => Services.I.medicines.updateStock(
        availabilityId: item.availability.availabilityId,
        price: price,
        quantity: qty,
      ),
      networkMessage: Msg.operationNetwork,
      errorTitle: Msg.updateInvalid,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      showSnack(context, Msg.updateSuccess);
      Navigator.pop(context);
    }
  }

  /// تسلسل حذف دواء: الضغط على حذف ← تأكيد العملية (FR-11) ← حذف سجل التوفر
  /// من availability ← "تم حذف الدواء من قائمة الأدوية".
  Future<void> _delete() async {
    final item = _item!;
    final confirmed = await confirmDialog(
      context,
      title: 'حذف ${item.medicine.tradeName}',
      message: Msg.deleteConfirm,
      confirmLabel: 'حذف',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _deleting = true);
    final ok = await runWithRetry(
      context,
      () => Services.I.medicines.removeFromPharmacy(
        item.availability.availabilityId,
      ),
      networkMessage: Msg.operationNetwork,
      errorTitle: 'تعذر حذف الدواء',
    );
    if (!mounted) return;
    setState(() => _deleting = false);
    if (ok) {
      showSnack(context, Msg.deleteSuccess);
      Navigator.pop(context);
    }
  }

  void _step(int delta) {
    final q = int.tryParse(_quantity.text.trim()) ?? 0;
    setState(() => _quantity.text = (q + delta).clamp(0, 1000000).toString());
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    return Scaffold(
      backgroundColor: AppColors.beige,
      body: Column(
        children: [
          TealHeader(
            title: 'تحديث الدواء',
            subtitle: item == null
                ? widget.pharmacy.pharmacyName
                : '${item.medicine.tradeName} - ${item.medicine.scientificName}',
            titleSize: 30,
            curve: 14,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                TextField(
                  controller: _query,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _find(),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن اسم الدواء الذي تريد تعديله...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: _find,
                          ),
                  ),
                ),
                if (_matches.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'اختر الدواء:',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  for (final m in _matches)
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.medication,
                          color: AppColors.primary,
                        ),
                        title: Text(m.medicine.tradeName),
                        subtitle: Text(
                          '${m.medicine.scientificName} • ${m.medicine.pharmaceuticalForm}',
                        ),
                        trailing: Text(Fmt.price(m.availability.price)),
                        onTap: () => _select(m),
                      ),
                    ),
                ],
                if (item == null && _matches.isEmpty)
                  const EmptyState(
                    icon: Icons.edit_note,
                    title: 'أدخل اسم الدواء',
                    message:
                        'اكتب الاسم التجاري أو العلمي للدواء المراد تعديله أو '
                        'حذفه ثم اضغط بحث.',
                  ),
                if (item != null) _editor(item),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _editor(StockItem item) {
    final m = item.medicine;
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: const Illustration(
                'medicine_thumb',
                height: 76,
                radius: 12,
              ),
              title: Text(
                m.tradeName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              subtitle: Text(
                [
                  m.scientificName,
                  'الشكل الصيدلاني: ${m.pharmaceuticalForm}',
                ].join('\n'),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _Section(
            icon: Icons.sell_outlined,
            title: 'تعديل السعر',
            child: TextFormField(
              controller: _price,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(suffixText: AppConfig.currency),
              validator: Validators.price,
            ),
          ),
          const SizedBox(height: 14),
          _Section(
            icon: Icons.inventory_2_outlined,
            title: 'تعديل الكمية',
            child: Row(
              children: [
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF179C91),
                    minimumSize: const Size(56, 56),
                  ),
                  icon: const Icon(Icons.add),
                  onPressed: () => _step(1),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _quantity,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                    validator: Validators.quantity,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.outlined(
                  style: IconButton.styleFrom(
                    minimumSize: const Size(52, 52),
                    side: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  color: AppColors.primary,
                  icon: const Icon(Icons.remove),
                  onPressed: () => _step(-1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFD93A36), AppColors.dangerDark],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.danger.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                minimumSize: const Size.fromHeight(62),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              icon: _deleting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.delete_outline, size: 30),
              label: const Text('حذف الدواء'),
              onPressed: _saving || _deleting ? null : _delete,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0E8E86),
                    minimumSize: const Size.fromHeight(56),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onPressed: _saving || _deleting ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const FittedBox(child: Text('حفظ التعديلات')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(Msg.cancel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
  });
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF179C91), size: 30),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1F36),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
