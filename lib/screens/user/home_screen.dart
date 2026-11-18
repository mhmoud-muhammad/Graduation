import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/app_theme.dart';
import '../../models/app_user.dart';
import '../../services/services.dart';
import '../../widgets/common.dart';
import '../../widgets/menu_card.dart';
import 'image_search_screen.dart';
import 'text_search_screen.dart';

/// الواجهة الرئيسية للمستخدم العادي.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sky,
      appBar: AppBar(
        centerTitle: false,
        title: const Text(
          AppConfig.appName,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
      ),
      drawer: _UserDrawer(user: user),
      body: WaveBackground(
        top: false,
        color: AppColors.sky,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 140),
          children: [
            Text(
              'مرحباً ${user.name.split(' ').first}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const Text(
              'ابحث عن الدواء بالطريقة التي تناسبك',
              style: TextStyle(fontSize: 17, color: AppColors.navy),
            ),
            const SizedBox(height: 28),
            MenuCard(
              icon: Icons.keyboard_alt_outlined,
              title: 'البحث بالكتابة',
              subtitle: 'بالاسم التجاري أو العلمي',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TextSearchScreen()),
              ),
            ),
            const SizedBox(height: 18),
            MenuCard(
              icon: Icons.photo_camera_outlined,
              title: 'البحث بالصورة',
              subtitle: 'صورة العبوة أو الروشتة',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ImageSearchScreen()),
              ),
            ),
            const SizedBox(height: 36),
            const Icon(
              Icons.medication_liquid,
              size: 110,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _UserDrawer extends StatelessWidget {
  const _UserDrawer({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: AppColors.primary, size: 40),
            ),
            accountName: Text(
              user.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            accountEmail: Text(user.email),
          ),
          if (user.phone != null)
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: Text(user.phone!),
            ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('عن التطبيق'),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: AppConfig.appName,
              applicationVersion: '1.0.0',
              applicationIcon: const AppLogo(size: 48),
              children: const [
                Text(
                  'تطبيق للبحث عن الأدوية في الصيدليات بالاسم أو بالصورة، '
                  'وعرض الصيدليات المتوفر فيها الدواء مرتبة حسب القرب.',
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.danger),
            title: const Text('تسجيل الخروج'),
            onTap: () async {
              Navigator.pop(context);
              await Services.I.auth.signOut();
            },
          ),
        ],
      ),
    );
  }
}
