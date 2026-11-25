import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/messages.dart';
import '../../models/app_user.dart';
import '../../models/pharmacy.dart';
import '../../services/services.dart';
import '../../widgets/common.dart';
import '../../widgets/menu_card.dart';
import '../auth/logout.dart';
import 'add_medicine_screen.dart';
import 'my_medicines_screen.dart';
import 'pharmacy_info_screen.dart';
import 'update_medicine_screen.dart';

/// لوحة الصيدلي: بيانات الصيدلية، إضافة دواء، تحديث بيانات الأدوية،
/// أدوية صيدليتي، وتسجيل الخروج (الفصل الرابع).
///
/// الصيدلي قد يدير أكثر من صيدلية (علاقة «يدير» واحد إلى متعدد)، فتعمل
/// اللوحة على "الصيدلية الحالية" مع إمكانية التبديل بينها.
class PharmacistDashboard extends StatefulWidget {
  const PharmacistDashboard({
    super.key,
    required this.user,
    this.pharmaciesSource,
  });
  final AppUser user;

  /// مصدر بديل لقائمة الصيدليات (للمعاينة والاختبار فقط).
  @visibleForTesting
  final Stream<List<Pharmacy>>? pharmaciesSource;

  @override
  State<PharmacistDashboard> createState() => _PharmacistDashboardState();
}

class _PharmacistDashboardState extends State<PharmacistDashboard> {
  late final Stream<List<Pharmacy>> _stream =
      widget.pharmaciesSource ??
      Services.I.pharmacies.watchByOwner(widget.user.userId);
  String? _currentId;

  Pharmacy? _current(List<Pharmacy> list) {
    if (list.isEmpty) return null;
    return list.firstWhere(
      (p) => p.pharmacyId == _currentId,
      orElse: () => list.first,
    );
  }

  Future<void> _openInfo(Pharmacy? pharmacy) async {
    final saved = await Navigator.of(context).push<Pharmacy>(
      MaterialPageRoute(
        builder: (_) =>
            PharmacyInfoScreen(owner: widget.user, pharmacy: pharmacy),
      ),
    );
    if (saved != null && mounted) {
      setState(() => _currentId = saved.pharmacyId);
    }
  }

  void _requirePharmacy(Pharmacy? p, Widget Function(Pharmacy) page) {
    if (p == null) {
      showSnack(context, Msg.needPharmacy, error: true);
      _openInfo(null);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page(p)));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Pharmacy>>(
      stream: _stream,
      builder: (context, snap) {
        final list = snap.data ?? const <Pharmacy>[];
        final current = _current(list);
        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              TealHeader(
                title: 'لوحة الصيدلي',
                subtitle: current?.pharmacyName ?? widget.user.name,
                titleSize: 32,
                alignStart: true,
                showBack: false,
                curve: 40,
                endWidget: Container(
                  width: 92,
                  height: 92,
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/pharmacist_avatar.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(26, 4, 26, 24),
                  children: [
                    if (list.length > 1)
                      _PharmacySwitcher(
                        key: ValueKey(current!.pharmacyId),
                        pharmacies: list,
                        current: current,
                        onChanged: (id) => setState(() => _currentId = id),
                      ),
                    const SizedBox(height: 10),
                    MenuCard(
                      tinted: true,
                      icon: Icons.location_city,
                      title: 'بيانات الصيدلية',
                      onTap: () => _openInfo(current),
                    ),
                    const SizedBox(height: 14),
                    MenuCard(
                      tinted: true,
                      icon: Icons.medication_liquid_outlined,
                      title: 'إضافة دواء',
                      onTap: () => _requirePharmacy(
                        current,
                        (p) => AddMedicineScreen(pharmacy: p),
                      ),
                    ),
                    const SizedBox(height: 14),
                    MenuCard(
                      tinted: true,
                      icon: Icons.edit_outlined,
                      title: 'تحديث بيانات الأدوية',
                      onTap: () => _requirePharmacy(
                        current,
                        (p) => UpdateMedicineScreen(pharmacy: p),
                      ),
                    ),
                    const SizedBox(height: 14),
                    MenuCard(
                      tinted: true,
                      icon: Icons.fact_check_outlined,
                      title: 'أدوية صيدليتي',
                      onTap: () => _requirePharmacy(
                        current,
                        (p) => MyMedicinesScreen(pharmacy: p),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Center(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(190, 52),
                          side: const BorderSide(
                            color: AppColors.header,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        icon: const Icon(Icons.logout),
                        label: const Text('تسجيل الخروج'),
                        onPressed: () => confirmAndSignOut(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PharmacySwitcher extends StatelessWidget {
  const _PharmacySwitcher({
    super.key,
    required this.pharmacies,
    required this.current,
    required this.onChanged,
  });

  final List<Pharmacy> pharmacies;
  final Pharmacy current;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: DropdownButtonFormField<String>(
        initialValue: current.pharmacyId,
        decoration: const InputDecoration(
          labelText: 'الصيدلية الحالية',
          prefixIcon: Icon(Icons.store_mall_directory_outlined),
        ),
        items: [
          for (final p in pharmacies)
            DropdownMenuItem(value: p.pharmacyId, child: Text(p.pharmacyName)),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}
