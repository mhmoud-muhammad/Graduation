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
  const PharmacistDashboard({super.key, required this.user});
  final AppUser user;

  @override
  State<PharmacistDashboard> createState() => _PharmacistDashboardState();
}

class _PharmacistDashboardState extends State<PharmacistDashboard> {
  late final Stream<List<Pharmacy>> _stream = Services.I.pharmacies
      .watchByOwner(widget.user.userId);
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
        final loading = snap.connectionState == ConnectionState.waiting;
        return Scaffold(
          body: Column(
            children: [
              _Header(user: widget.user, pharmacy: current),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
                  children: [
                    if (list.length > 1)
                      _PharmacySwitcher(
                        key: ValueKey(current!.pharmacyId),
                        pharmacies: list,
                        current: current,
                        onChanged: (id) => setState(() => _currentId = id),
                      ),
                    if (!loading && list.isEmpty)
                      Card(
                        color: const Color(0xFFFFF4E5),
                        child: ListTile(
                          leading: const Icon(
                            Icons.info_outline,
                            color: Colors.orange,
                          ),
                          title: const Text('سجّل بيانات صيدليتك'),
                          subtitle: const Text(
                            'أدخل اسم الصيدلية وموقعها حتى تظهر أدويتك في '
                            'نتائج البحث.',
                          ),
                          onTap: () => _openInfo(null),
                        ),
                      ),
                    const SizedBox(height: 10),
                    MenuCard(
                      tinted: true,
                      icon: Icons.local_hospital_outlined,
                      title: 'بيانات الصيدلية',
                      subtitle: 'تسجيل صيدلية أو تعديل بياناتها',
                      onTap: () => _openInfo(current),
                    ),
                    const SizedBox(height: 14),
                    MenuCard(
                      tinted: true,
                      icon: Icons.add_circle_outline,
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
                      subtitle: 'تعديل السعر والكمية أو حذف دواء',
                      onTap: () => _requirePharmacy(
                        current,
                        (p) => UpdateMedicineScreen(pharmacy: p),
                      ),
                    ),
                    const SizedBox(height: 14),
                    MenuCard(
                      tinted: true,
                      icon: Icons.assignment_outlined,
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
                          minimumSize: const Size(180, 46),
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

class _Header extends StatelessWidget {
  const _Header({required this.user, required this.pharmacy});
  final AppUser user;
  final Pharmacy? pharmacy;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _CurveClipper(),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          22,
          MediaQuery.paddingOf(context).top + 18,
          22,
          56,
        ),
        color: AppColors.primary,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'لوحة الصيدلي',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    pharmacy?.pharmacyName ?? user.name,
                    style: const TextStyle(color: Colors.white, fontSize: 17),
                  ),
                ],
              ),
            ),
            CircleAvatar(
              radius: 36,
              backgroundColor: Colors.white,
              child: Text(
                user.name.isEmpty ? '؟' : user.name.characters.first,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..lineTo(0, size.height - 30)
    ..quadraticBezierTo(
      size.width / 2,
      size.height + 20,
      size.width,
      size.height - 30,
    )
    ..lineTo(size.width, 0)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
