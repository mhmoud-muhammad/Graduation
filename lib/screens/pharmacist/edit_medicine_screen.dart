import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/app_theme.dart';
import '../../core/firebase_errors.dart';
import '../../core/formatters.dart';
import '../../core/validators.dart';
import '../../services/services.dart';
import '../../widgets/common.dart';
import 'medicines_screen.dart';

/// واجهة تحديث الدواء (FR-10): تعديل السعر والكمية أو حذف الدواء.
class EditMedicineScreen extends StatefulWidget {
  const EditMedicineScreen({super.key, required this.item});
  final StockItem item;

  @override
  State<EditMedicineScreen> createState() => _EditMedicineScreenState();
}

class _EditMedicineScreenState extends State<EditMedicineScreen> {
  final _form = GlobalKey<FormState>();
  late final _price = TextEditingController(
    text: _trim(widget.item.availability.price),
  );
  late final _quantity = TextEditingController(
    text: widget.item.availability.quantity.toString(),
  );
  bool _saving = false;
  bool _deleting = false;

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _price.dispose();
    _quantity.dispose();
    super.dispose();
  }

  void _step(int delta) {
    final q = int.tryParse(_quantity.text.trim()) ?? 0;
    final next = (q + delta).clamp(0, 1000000);
    setState(() => _quantity.text = next.toString());
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await Services.I.medicines.updateStock(
        availabilityId: widget.item.availability.availabilityId,
        price: double.parse(_price.text.trim()),
        quantity: int.parse(_quantity.text.trim()),
      );
      if (!mounted) return;
      showSnack(context, 'تم حفظ التعديلات');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(
      context,
      title: 'حذف الدواء',
      message:
          'هل تريد حذف "${widget.item.medicine.tradeName}" من قائمة '
          'الصيدلية؟ لن يظهر في نتائج البحث بعد الآن.',
      confirmLabel: 'حذف',
      destructive: true,
    );
    if (!ok) return;
    setState(() => _deleting = true);
    try {
      await Services.I.medicines.removeFromPharmacy(
        widget.item.availability.availabilityId,
      );
      if (!mounted) return;
      showSnack(context, 'تم حذف الدواء');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.item.medicine;
    final a = widget.item.availability;
    return Scaffold(
      appBar: AppBar(title: const Text('تحديث الدواء')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                leading: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.sky,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.medication,
                    color: AppColors.primary,
                    size: 32,
                  ),
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
                    if (m.barcode != null) 'الرمز: ${m.barcode}',
                    if (a.updatedAt != null)
                      'آخر تحديث: ${Fmt.date(a.updatedAt)}',
                  ].join('\n'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              icon: Icons.sell_outlined,
              title: 'تعديل السعر',
              child: TextFormField(
                controller: _price,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  suffixText: AppConfig.currency,
                ),
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
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(52, 52),
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
                      side: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    color: AppColors.primary,
                    icon: const Icon(Icons.remove),
                    onPressed: () => _step(-1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            LoadingButton(
              icon: Icons.delete_outline,
              label: 'حذف الدواء',
              loading: _deleting,
              color: AppColors.danger,
              onPressed: _saving ? null : _delete,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: LoadingButton(
                    label: 'حفظ التعديلات',
                    loading: _saving,
                    onPressed: _deleting ? null : _save,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                ),
              ],
            ),
          ],
        ),
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
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
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
