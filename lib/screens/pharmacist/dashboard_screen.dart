import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../models/app_user.dart';
import '../../models/pharmacy.dart';
import '../../services/services.dart';
import '../../widgets/common.dart';
import '../../widgets/menu_card.dart';
import 'medicines_screen.dart';
import 'pharmacy_info_screen.dart';

/// لوحة الصيدلي: الدخول إلى بيانات الصيدلية أو إدارة الأدوية.
class PharmacistDashboard extends StatelessWidget {
  const PharmacistDashboard({super.key, required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Pharmacy?>(
      stream: Services.I.pharmacies.watchByOwner(user.userId),
      builder: (context, snap) {
        final pharmacy = snap.data;
        final loading = snap.connectionState == ConnectionState.waiting;
        return Scaffold(
          body: Column(
            children: [
              _Header(user: user, pharmacy: pharmacy),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                  children: [
                    if (!loading && pharmacy == null)
                      Card(
                        color: const Color(0xFFFFF4E5),
                        child: ListTile(
                          leading: const Icon(
                            Icons.info_outline,
                            color: Colors.orange,
                          ),
                          title: const Text('أكمل بيانات صيدليتك'),
                          subtitle: const Text(
                            'سجّل اسم الصيدلية وموقعها حتى تظهر أدويتك في نتائج البحث.',
                          ),
                          onTap: () => _openInfo(context, null),
                        ),
                      ),
                    const SizedBox(height: 14),
                    MenuCard(
                      tinted: true,
                      icon: Icons.storefront_outlined,
                      title: 'بيانات الصيدلية',
                      subtitle: 'الاسم، العنوان، الهاتف، الموقع',
                      onTap: () => _openInfo(context, pharmacy),
                    ),
                    const SizedBox(height: 18),
                    MenuCard(
                      tinted: true,
                      icon: Icons.medication_outlined,
                      title: 'إدارة الأدوية',
                      subtitle: 'إضافة وتعديل وحذف الأدوية',
                      onTap: () {
                        if (pharmacy == null) {
                          showSnack(
                            context,
                            'سجّل بيانات الصيدلية أولاً',
                            error: true,
                          );
                          _openInfo(context, null);
                          return;
                        }
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MedicinesScreen(pharmacy: pharmacy),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(160, 44),
                        ),
                        icon: const Icon(Icons.logout),
                        label: const Text('تسجيل الخروج'),
                        onPressed: () async {
                          final ok = await confirmDialog(
                            context,
                            title: 'تسجيل الخروج',
                            message: 'هل تريد تسجيل الخروج من حسابك؟',
                          );
                          if (ok) await Services.I.auth.signOut();
                        },
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

  void _openInfo(BuildContext context, Pharmacy? pharmacy) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PharmacyInfoScreen(owner: user, pharmacy: pharmacy),
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipPath(
          clipper: _CurveClipper(),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(context).top + 18,
              bottom: 70,
            ),
            color: AppColors.primary,
            child: Column(
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
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: -46,
          left: 0,
          right: 0,
          child: Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 46,
                backgroundColor: AppColors.sky,
                child: Text(
                  user.name.isEmpty ? '؟' : user.name.characters.first,
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    )._withBottomSpace(54);
  }
}

extension on Widget {
  Widget _withBottomSpace(double h) => Padding(
    padding: EdgeInsets.only(bottom: h),
    child: this,
  );
}

class _CurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..lineTo(0, size.height - 40)
    ..quadraticBezierTo(
      size.width / 2,
      size.height + 20,
      size.width,
      size.height - 40,
    )
    ..lineTo(size.width, 0)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
