import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/text_utils.dart';
import '../../models/availability.dart';
import '../../models/medicine.dart';
import '../../models/pharmacy.dart';
import '../../models/search_models.dart';
import '../../services/services.dart';
import '../../widgets/common.dart';
import 'update_medicine_screen.dart';

/// واجهة أدوية صيدليتي (FR-12): الأدوية المتوفرة في الصيدلية باسمها التجاري
/// والعلمي وأسعارها وكمياتها وأشكالها الصيدلانية.
class MyMedicinesScreen extends StatefulWidget {
  const MyMedicinesScreen({super.key, required this.pharmacy});
  final Pharmacy pharmacy;

  @override
  State<MyMedicinesScreen> createState() => _MyMedicinesScreenState();
}

class _MyMedicinesScreenState extends State<MyMedicinesScreen> {
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
    return [
      for (final a in stock)
        if (_cache[a.medicineId] case final m?) StockItem(m, a),
    ]..sort(
      (a, b) => a.medicine.tradeName.toLowerCase().compareTo(
        b.medicine.tradeName.toLowerCase(),
      ),
    );
  }

  List<StockItem> _applyFilter(List<StockItem> items) {
    final q = TextUtils.normalize(_filter.text);
    if (q.isEmpty) return items;
    return items.where((i) {
      final m = i.medicine;
      return TextUtils.normalize(m.tradeName).contains(q) ||
          TextUtils.normalize(m.scientificName).contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFB),
      body: Column(
        children: [
          TealHeader(
            title: 'أدوية صيدليتي',
            subtitle: widget.pharmacy.pharmacyName,
            backStyle: BackStyle.circle,
            titleSize: 30,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
            child: TextField(
              controller: _filter,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'ابحث في أدوية الصيدلية...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Availability>>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return const EmptyState(
                    icon: Icons.wifi_off,
                    title: 'تعذر تحميل الأدوية',
                    message: 'تحقق من الاتصال بالإنترنت ثم أعد فتح الشاشة.',
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
                        message: 'أضف الأدوية من "إضافة دواء" في لوحة الصيدلي.',
                      );
                    }
                    final items = _applyFilter(all);
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
                      itemCount: items.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return Text(
                            'عدد الأدوية: ${all.length}',
                            style: const TextStyle(color: AppColors.muted),
                          );
                        }
                        final item = items[i - 1];
                        return _StockCard(
                          item: item,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => UpdateMedicineScreen(
                                pharmacy: widget.pharmacy,
                                initial: item,
                              ),
                            ),
                          ),
                        );
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

class _StockCard extends StatelessWidget {
  const _StockCard({required this.item, required this.onTap});
  final StockItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = item.medicine;
    final a = item.availability;
    Widget row(IconData icon, String label, String value, {bool big = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: big ? 22 : 19, color: AppColors.header),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '$label: $value',
                  style: TextStyle(
                    fontSize: big ? 20 : 17,
                    fontWeight: big ? FontWeight.w800 : FontWeight.w600,
                    color: const Color(0xFF1A1F36),
                  ),
                ),
              ),
            ],
          ),
        );
    return Material(
      color: AppColors.mintCard,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Column(
            children: [
              row(
                Icons.payments_outlined,
                'الاسم التجاري',
                m.tradeName,
                big: true,
              ),
              row(Icons.description_outlined, 'الاسم العلمي', m.scientificName),
              row(Icons.inventory_2_outlined, 'السعر', Fmt.price(a.price)),
              row(
                Icons.inventory_2_outlined,
                'الكمية',
                a.quantity == 0 ? '0 (نفدت الكمية)' : '${a.quantity}',
              ),
              row(
                Icons.medication_outlined,
                'الشكل الصيدلاني',
                m.pharmaceuticalForm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
