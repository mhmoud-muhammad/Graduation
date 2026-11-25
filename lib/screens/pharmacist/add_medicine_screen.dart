import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/app_theme.dart';
import '../../core/messages.dart';
import '../../core/validators.dart';
import '../../models/pharmacy.dart';
import '../../services/services.dart';
import '../../widgets/common.dart';

/// واجهة إضافة دواء (FR-09): الاسم التجاري والعلمي والسعر والكمية واختيار
/// الشكل الصيدلاني.
class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key, required this.pharmacy});
  final Pharmacy pharmacy;

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _form = GlobalKey<FormState>();
  final _trade = TextEditingController();
  final _scientific = TextEditingController();
  final _price = TextEditingController();
  final _quantity = TextEditingController();
  String? _pharmForm;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_trade, _scientific, _price, _quantity]) {
      c.dispose();
    }
    super.dispose();
  }

  /// تسلسل إضافة دواء: إدخال البيانات واختيار الشكل الصيدلاني ← الضغط على
  /// "إضافة دواء" ← التحقق:
  /// - ضعف الإنترنت: "تعذرت العملية، الرجاء إعادة المحاولة عند توفر اتصال"
  /// - اسم أو شكل فارغ أو سعر/كمية سالبة: "البيانات غير صحيحة أو غير
  ///   مكتملة، الرجاء تصحيح البيانات"
  /// - صحيحة: البحث عن الدواء في medicines وإنشاؤه إن لم يوجد ← حفظ سجل
  ///   التوفر في availability ← "تمت الإضافة بنجاح".
  Future<void> _save() async {
    if (!_form.currentState!.validate()) {
      await showErrorDialog(context, title: Msg.invalidOrIncomplete);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final ok = await runWithRetry(
      context,
      () => Services.I.medicines.addToPharmacy(
        pharmacyId: widget.pharmacy.pharmacyId,
        tradeName: _trade.text.trim(),
        scientificName: _scientific.text.trim(),
        pharmaceuticalForm: _pharmForm!,
        price: double.parse(_price.text.trim()),
        quantity: int.parse(_quantity.text.trim()),
      ),
      networkMessage: Msg.operationNetwork,
      errorTitle: Msg.invalidOrIncomplete,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      showSnack(context, Msg.addSuccess);
      Navigator.pop(context);
    }
  }

  InputDecoration _field(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    suffixIcon: Icon(icon, color: const Color(0xFF6B7280)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBF3FC),
      appBar: AppBar(
        toolbarHeight: 76,
        backgroundColor: const Color(0xFFE6EEF7),
        title: const Text(
          'إضافة دواء',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          color: AppColors.navy,
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: WaveBackground(
        top: false,
        color: const Color(0xFFEBF3FC),
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(26, 14, 26, 150),
            children: [
              Text(
                widget.pharmacy.pharmacyName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _trade,
                textInputAction: TextInputAction.next,
                decoration: _field('الاسم التجاري', Icons.medication_outlined),
                validator: (v) => Validators.required(v, 'الاسم التجاري'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _scientific,
                textInputAction: TextInputAction.next,
                decoration: _field('الاسم العلمي', Icons.medication_outlined),
                validator: (v) => Validators.required(v, 'الاسم العلمي'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                decoration: _field(
                  'السعر (${AppConfig.currency})',
                  Icons.attach_money,
                ),
                validator: Validators.price,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantity,
                keyboardType: TextInputType.number,
                decoration: _field('الكمية', Icons.tag),
                validator: Validators.quantity,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _pharmForm,
                decoration: _field(
                  'الشكل الصيدلاني',
                  Icons.inventory_2_outlined,
                ),
                borderRadius: BorderRadius.circular(12),
                items: [
                  for (final f in AppConfig.pharmaceuticalForms)
                    DropdownMenuItem(value: f, child: Text(f)),
                ],
                onChanged: (v) => setState(() => _pharmForm = v),
                validator: (v) => v == null ? 'اختر الشكل الصيدلاني' : null,
              ),
              const SizedBox(height: 26),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2CA6B0),
                  minimumSize: const Size.fromHeight(62),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          color: Colors.white,
                        ),
                      )
                    : const Text('إضافة دواء'),
              ),
              const SizedBox(height: 18),
              const Illustration('bottles_cutout', height: 130),
            ],
          ),
        ),
      ),
    );
  }
}
