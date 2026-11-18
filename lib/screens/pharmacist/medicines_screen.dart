import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/text_utils.dart';
import '../../models/availability.dart';
import '../../models/medicine.dart';
import '../../models/pharmacy.dart';
import '../../services/services.dart';
import '../../widgets/common.dart';
import 'add_medicine_screen.dart';
import 'edit_medicine_screen.dart';

/// سجل في قائمة أدوية الصيدلية (الدواء + السعر والكمية).
class StockItem {
  const StockItem(this.medicine, this.availability);
  final Medicine medicine;
  final Availability availability;
}

/// واجهة إدارة الأدوية: عرض أدوية الصيدلية والبحث فيها والإضافة والتعديل.
class MedicinesScreen extends StatefulWidget {
  const MedicinesScreen({super.key, required this.pharmacy});
  final Pharmacy pharmacy;

  @override
  State<MedicinesScreen> createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends State<MedicinesScreen> {
  final _filter = TextEditingController();
  final Map<String, Medicine> _cache = {};
  late final Stream<List<Availability>> _stream = Services.I.medicines
      .watchPharmacyStock(widget.pharmacy.pharmacyId);

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  Future<List<StockItem>> _resolve(List<Availability> stock) async {
    final missing = stock
        .map((a) => a.medicineId)
        .where((id) => !_cache.containsKey(id));
    if (missing.isNotEmpty) {
      _cache.addAll(await Services.I.medicines.getByIds(missing));
    }
    final items =
        [
          for (final a in stock)
            if (_cache[a.medicineId] case final m?) StockItem(m, a),
        ]..sort(
          (a, b) => a.medicine.tradeName.toLowerCase().compareTo(
            b.medicine.tradeName.toLowerCase(),
          ),
        );
    return items;
  }

  List<StockItem> _applyFilter(List<StockItem> items) {
    final q = TextUtils.normalize(_filter.text);
    if (q.isEmpty) return items;
    return items.where((i) {
      final m = i.medicine;
      return TextUtils.normalize(m.tradeName).contains(q) ||
          TextUtils.normalize(m.scientificName).contains(q) ||
          (m.barcode ?? '').contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الأدوية')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('إضافة دواء'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddMedicineScreen(pharmacy: widget.pharmacy),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
            child: TextField(
              controller: _filter,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'ابحث عن اسم الدواء الذي تريد تعديله...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Availability>>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return EmptyState(
                    icon: Icons.error_outline,
                    title: 'تعذر تحميل الأدوية',
                    message: snap.error.toString(),
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return FutureBuilder<List<StockItem>>(
                  future: _resolve(snap.data!),
                  builder: (context, itemsSnap) {
                    if (!itemsSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final all = itemsSnap.data!;
                    if (all.isEmpty) {
                      return const EmptyState(
                        icon: Icons.medication_outlined,
                        title: 'لا توجد أدوية بعد',
                        message: 'اضغط "إضافة دواء" لإضافة أول دواء متوفر في صيدليتك.',
                      );
                    }
                    final items = _applyFilter(all);
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 100),
                      itemCount: items.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return Text(
                            'عدد الأدوية: ${all.length}'
                            '${items.length != all.length ? ' • المطابقة: ${items.length}' : ''}',
                            style: const TextStyle(color: AppColors.muted),
                          );
                        }
                        return _StockTile(item: items[i - 1]);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StockTile extends StatelessWidget {
  const _StockTile({required this.item});
  final StockItem item;

  @override
  Widget build(BuildContext context) {
    final m = item.medicine;
    final a = item.availability;
    final out = a.quantity == 0;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: AppColors.sky,
          child: Icon(
            Icons.medication,
            color: out ? AppColors.danger : AppColors.primary,
          ),
        ),
        title: Text(
          m.tradeName,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        subtitle: Text(
          [m.scientificName, if (m.form != null) m.form!].join(' • '),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Fmt.price(a.price),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
            Text(
              out ? 'نفدت الكمية' : 'الكمية: ${a.quantity}',
              style: TextStyle(
                color: out ? AppColors.danger : AppColors.muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => EditMedicineScreen(item: item)),
        ),
      ),
    );
  }
}
