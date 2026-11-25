import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/app_theme.dart';
import '../../models/app_user.dart';
import '../../widgets/common.dart';
import '../../widgets/menu_card.dart';
import '../auth/logout.dart';
import 'image_search_screen.dart';
import 'text_search_screen.dart';

/// الواجهة الرئيسية للمستخدم: البحث بالكتابة أو بالصورة وتسجيل الخروج.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBg,
      appBar: AppBar(
        backgroundColor: AppColors.homeBar,
        toolbarHeight: 76,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: const Text(
          AppConfig.appName,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 38,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu, size: 34),
              color: AppColors.logoutBlue,
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _UserDrawer(user: user),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
        children: [
          const Text(
            'مرحباً بك',
            style: TextStyle(
              fontSize: 46,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1530A0),
            ),
          ),
          const Text(
            'ابحث عن الدواء بالطريقة التي تناسبك',
            style: TextStyle(fontSize: 18, color: AppColors.navy),
          ),
          const SizedBox(height: 26),
          MenuCard(
            icon: Icons.keyboard_alt_outlined,
            title: 'البحث بالكتابة',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const TextSearchScreen())),
          ),
          const SizedBox(height: 18),
          MenuCard(
            icon: Icons.photo_camera_outlined,
            title: 'البحث بالصورة',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ImageSearchScreen()),
            ),
          ),
          const SizedBox(height: 20),
          const Illustration('home_bottles', height: 190),
          const SizedBox(height: 18),
          // تسجيل الخروج أسفل خياري البحث (وصف حالة الاستخدام).
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.logoutBlue,
              minimumSize: const Size.fromHeight(62),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            icon: const Icon(Icons.logout, size: 28),
            label: const Text('تسجيل الخروج'),
            onPressed: () => confirmAndSignOut(context),
          ),
        ],
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
        ],
      ),
    );
  }
}
