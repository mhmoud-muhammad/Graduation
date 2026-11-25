import 'package:flutter/material.dart';

import '../../core/app_config.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة دواء')),
      body: WaveBackground(
        top: false,
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 140),
            children: [
              Text(
                widget.pharmacy.pharmacyName,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _trade,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'الاسم التجاري',
                  prefixIcon: Icon(Icons.medication_outlined),
                ),
                validator: (v) => Validators.required(v, 'الاسم التجاري'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _scientific,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'الاسم العلمي',
                  prefixIcon: Icon(Icons.science_outlined),
                ),
                validator: (v) => Validators.required(v, 'الاسم العلمي'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'السعر',
                  prefixIcon: Icon(Icons.payments_outlined),
                  suffixText: AppConfig.currency,
                ),
                validator: Validators.price,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantity,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'الكمية',
                  prefixIcon: Icon(Icons.numbers),
                ),
                validator: Validators.quantity,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _pharmForm,
                decoration: const InputDecoration(
                  hintText: 'الشكل الصيدلاني',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  for (final f in AppConfig.pharmaceuticalForms)
                    DropdownMenuItem(value: f, child: Text(f)),
                ],
                onChanged: (v) => setState(() => _pharmForm = v),
                validator: (v) => v == null ? 'اختر الشكل الصيدلاني' : null,
              ),
              const SizedBox(height: 24),
              LoadingButton(
                icon: Icons.add,
                label: 'إضافة دواء',
                loading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
