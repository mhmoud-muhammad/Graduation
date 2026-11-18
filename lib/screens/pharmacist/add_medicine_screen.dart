import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/firebase_errors.dart';
import '../../core/messages.dart';
import '../../core/validators.dart';
import '../../models/pharmacy.dart';
import '../../services/services.dart';
import '../../widgets/common.dart';

/// واجهة إضافة دواء (FR-09).
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
  final _barcode = TextEditingController();
  final _price = TextEditingController();
  final _quantity = TextEditingController();
  String? _medForm;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_trade, _scientific, _barcode, _price, _quantity]) {
      c.dispose();
    }
    super.dispose();
  }

  /// مخطط تسلسل الصيدلي (2): إدخال بيانات الدواء ← إرسال بيانات الدواء
  /// ← البحث عن الدواء في medicines ← (غير موجود: إنشاء دواء جديد وحفظه)
  /// ← حفظ سجل التوفر في availability ← "تمت إضافة الدواء بنجاح".
  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await Services.I.medicines.addToPharmacy(
        pharmacyId: widget.pharmacy.pharmacyId,
        tradeName: _trade.text,
        scientificName: _scientific.text,
        barcode: _barcode.text,
        form: _medForm,
        price: double.parse(_price.text.trim()),
        quantity: int.parse(_quantity.text.trim()),
      );
      if (!mounted) return;
      showSnack(context, Msg.medicineAdded);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
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
                  hintText: 'الاسم العلمي (المادة الفعالة)',
                  prefixIcon: Icon(Icons.science_outlined),
                ),
                validator: (v) => Validators.required(v, 'الاسم العلمي'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _barcode,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'الباركود (اختياري)',
                  prefixIcon: Icon(Icons.qr_code_2),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _medForm,
                decoration: const InputDecoration(
                  hintText: 'الشكل الدوائي (اختياري)',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  for (final f in AppConfig.medicineForms)
                    DropdownMenuItem(value: f, child: Text(f)),
                ],
                onChanged: (v) => setState(() => _medForm = v),
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
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                validator: Validators.quantity,
              ),
              const SizedBox(height: 24),
              LoadingButton(
                icon: Icons.save_outlined,
                label: 'حفظ',
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
